# Dissertation Source Notes — Fridge2Table (F2T)

Plain descriptive extraction notes for dissertation writing. Not dissertation prose — use as raw material and cite file paths directly. Every claim below is traceable to a specific file, commit, or doc; where no evidence was found, this is stated explicitly rather than inferred.

Project identity (from `README.md`, `z_ALL_DOC.md`): University of Sunderland CET300 FYP, student Chaw Thiri Win (ID bj21de), supervisor Myo Myo Than Naing, client "Myanmar Food Waste Reduction NGO (Yangon Chapter)". Stated project timeline: 2026-02-09 → 2026-08-07.

---

## 1. System Architecture

### 1.1 High-level data flow (for a component diagram)

Camera capture → on-device classification → inventory update → recipe matching → optional LLM re-rank → UI, described stage by stage:

1. **Capture**: `AiCameraScreen` (`frontend/fridge2table_app/lib/screens/ai_camera_screen.dart`) opens the device's back camera via the `camera` package, shows a live preview with a scan-box overlay, and captures a single still frame on tap.
2. **On-device classification**: the captured JPEG is decoded and resized to 224×224 by `IngredientClassifierService` (`lib/services/ingredient_classifier_service.dart`), fed into a MobileNetV2 TFLite model bundled in the app (`assets/models/ingredient_classifier_v4.tflite` + `class_names_v4.json`), and the top-5 class scores are returned. No image or network call leaves the device at this stage — classification is 100% local.
3. **Routing to inventory**: the top prediction's label is passed straight into `AddIngredientScreen`, which pre-fills the ingredient name/category; the user confirms or edits before saving. There is no intermediate multi-item bounding-box selection screen in the live flow (see §2.3 for the deviation this represents).
4. **Inventory update**: `AddIngredientScreen` calls `ApiService.addIngredient()` → `POST /ingredient` on the FastAPI backend, which writes a row into the backend's own `pantry_items` table (SQLAlchemy) and, separately, the frontend also pushes/pulls a mirrored copy to Supabase's own `ingredients` table for cross-device cloud sync (a second, independent write path — see §1.3).
5. **Recipe matching**: any screen requesting recipes calls `GET /recipes`, which loads the user's full current inventory (every item, regardless of expiry status), normalizes ingredient names, looks them up against a pre-built in-memory keyword index over `backend/data/recipes_full.json` (172 hand-authored recipes), and scores/filters/sorts candidates (see §2.4 for the exact rules).
6. **Optional LLM re-rank**: `GET /ai-recommendation` takes the top 10 matched candidates and, only if `OPENROUTER_API_KEY` is set in the backend's environment, asks an LLM (`meta-llama/llama-3.3-70b-instruct:free` via OpenRouter) to pick the single best one given the user's exact pantry contents; without a key, or if the call fails, it silently falls back to the top deterministic match (`source: "fallback"` either way).
7. **UI**: results render as recipe cards (`RecipeScreen`) or a full detail view (`RecipeDetailScreen`), which also independently overlays allergy/diet-conflict warnings and (added in the most recent development batch) expired/expiring-ingredient warnings sourced from the same `/recipes` response.

### 1.2 Backend API endpoints

All defined in `backend/app/routes/inventory.py`, registered via `backend/app/main.py`. Every request other than the root health check is scoped by a `user_id` query parameter (the signed-in Supabase user's UUID).

| Method | Path | Purpose |
|---|---|---|
| GET | `/` | Health check — returns a static JSON message confirming the backend is running |
| GET | `/inventory` | Returns every ingredient row belonging to `user_id` |
| POST | `/ingredient` | Creates a new ingredient row for `user_id` |
| PUT | `/ingredient/{id}` | Updates an existing ingredient row (name/quantity/unit/expiry/category/location), scoped to `user_id` |
| DELETE | `/ingredient/{id}` | Deletes an ingredient row, scoped to `user_id` (frontend separately mirrors this delete to Supabase's cloud copy) |
| GET | `/expiry-status` | Recomputes and returns a `status` label (`expired`/`today`/`soon`/`fresh`/`unknown`) per ingredient, derived from `expiry_date` vs. the server's current date on every call — not stored |
| GET | `/recipes` | Returns up to 25 recipe matches (name, full recipe data, `match_score`, `matched_ingredients`, and — as of the latest development batch — `expired_ingredients`/`expiring_ingredients`), filtered to ≥20% match score and ≥2 actually-shared ingredients |
| GET | `/ai-recommendation` | Returns a single LLM-picked (or deterministic-fallback) best recipe name from the top matches, prioritizing recipes that use an ingredient expiring today/soon if any exist |

### 1.3 Database schema

Two physically separate databases exist, reconciled at the application layer (not by any database-level relationship) — see §1.4 for why.

**Backend's own database** (`backend/app/models.py`, table `pantry_items`, accessed via SQLAlchemy; Postgres via Supabase in production, SQLite locally, selected by the `DATABASE_URL` environment variable in `backend/app/database.py`):

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | Integer | Primary key | Auto-generated by the database |
| name | String | NOT NULL | |
| quantity | Float | NOT NULL | |
| unit | String | NOT NULL | |
| expiry_date | String | Nullable | `YYYY-MM-DD` format, stored as plain text not a native date type |
| category | String | Nullable | |
| location | String | Nullable | |
| user_id | String | Nullable, indexed | The Supabase user's UUID as text; nullable only because pre-auth legacy rows have no owner and are permanently treated as orphaned (never returned to any user, since every query filters by an exact match) |
| updated_at | DateTime (timezone-aware) | NOT NULL, auto-set on insert/update | Used only for cloud-sync conflict resolution (last-write-wins), not for anything on the backend itself |

No relationships/foreign keys are declared in this schema — it is a single flat table. `user_id` is a *logical* reference to Supabase's own `auth.users.id`, not an enforced database-level foreign key (the two live in different physical databases).

Note on naming: this table was originally simply named `ingredients` and was **renamed to `pantry_items`** partway through development (commit `04f13a0`) specifically to stop it colliding with Supabase's own, independently-evolved `ingredients` table (see §2.2/§3.4 for the bug this caused). `README.md`'s current "Database Schema" section still describes the table under its old name (`ingredients`) and has not been updated to reflect the rename — this is a real, currently-existing documentation/code mismatch worth flagging if citing the README directly.

**Supabase Postgres** (`supabase_schema.sql`, table `public.ingredients` — the cloud-sync mirror, entirely separate from the backend's own database and accessed only by the Flutter client directly via the Supabase SDK, never by the FastAPI backend):

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | integer | NOT NULL, no default | Always supplied explicitly by the client (mirrors the corresponding local `pantry_items.id`) — this table was never given its own auto-increment identity |
| name | text | | |
| quantity | numeric | | |
| unit | text | | |
| expiry_date | text | Nullable | |
| category | text | Nullable | |
| location | text | Nullable | |
| user_id | text | Nullable | Added by a later migration (`supabase_schema.sql`); rows from before this migration are NULL and permanently inaccessible under the current Row-Level-Security policy |
| updated_at | timestamptz | Default `now()` | Used for two-way sync conflict resolution |

Constraints/policies on this table: a composite **UNIQUE constraint on `(id, user_id)`** (added mid-project, replacing an original single-column primary key on `id` alone — see §3.4) is the current uniqueness rule, allowing two different accounts to each have their own row at the same `id`. Row-Level Security is enabled with one policy, "Users can only access their own ingredients" (`for all to authenticated using/with check (auth.uid()::text = user_id)`) — meaning a row is only ever readable/writable by the account whose id matches its own `user_id`, enforced by Postgres itself from the caller's verified JWT, not by client-trusted input.

**Supabase `auth.users`** (fully managed by Supabase Auth, not defined anywhere in this project's own schema files): holds each account's UUID, email, provider (email/Google), `created_at`/`last_sign_in_at`, etc. This is the identity table that every `user_id` column above logically points to.

### 1.4 Key design decisions and reasoning

**Two databases instead of one.** Documented directly in `docs/PROJECT_FLOW.md`: "the FastAPI backend is the pantry's source of truth... while Supabase's `ingredients` table is a sync/backup layer the frontend pushes to and pulls from independently. They're kept consistent by the frontend, not by the backend." This is an explicit, documented architectural choice, not an accident.

**Why MobileNetV2 (not a heavier model).** No comment or commit message in the repo explicitly states "we chose MobileNetV2 because X" — this reasoning is not documented in-repo. What *is* documented: the model runs fully on-device via TFLite (`README.md`, `ai_models/scripts/train_v4.py`), and the original project brief (`z_ALL_DOC.md`, Supervisory Meeting 3) explicitly targeted low-end Android hardware (Snapdragon 600-series, 4GB RAM) as a hard constraint, which favors a small mobile-optimized architecture in general. Treat "MobileNetV2 chosen for its size/latency tradeoff on low-end hardware" as a *reasonable inference consistent with the stated constraints*, not a documented fact.

**Why the hybrid JSON+LLM recipe engine (fixed dataset + optional LLM re-rank, not live LLM generation).** This one **is** directly documented in two places:
- `z_ALL_DOC.md`, Supervisory Meeting 2 (31 March 2026): the supervisor's recorded guidance was "Not over-relying on LLMs – the system must include deterministic logic (expiry prioritisation, scoring engine) to demonstrate genuine AI engineering."
- `backend/scripts/generate_recipes.py`'s own docstring: the current hand-authored `recipes_full.json` dataset explicitly "replace[s] the old cuisine classification dataset (`cuisine_data.csv` / `recipes_index.json`), which only had cuisine labels (\"french\", \"spanish\") as recipe names" — i.e. an earlier iteration used a bare ingredients→cuisine-label dataset with no real dish names/steps, which was abandoned in favor of a real, fully-authored recipe dataset matched deterministically.

**Why Supabase over Firebase.** The originally planned stack (`z_ALL_DOC.md`, Client Meeting 4 and Supervisory Meeting 2) explicitly named "Firebase Firestore (optional cloud sync)". No commit message, comment, or doc anywhere in the repo explains why the project ended up on Supabase instead. Per the task instructions, this should be noted as a mid-project architecture change with no documented reasoning found — do not invent a justification.

---

## 2. Development Narrative (per module)

### 2.1 Auth

**Built:** Supabase Auth, supporting email/password and Google OAuth. `lib/main.dart` holds a root-level `onAuthStateChange` listener that catches sign-in completing *asynchronously* (OAuth's browser redirect landing later, or an email-confirmation link opened from the inbox) regardless of which screen triggered it — branching differently for OAuth sign-ins (shows a "Continue as [email]?" confirmation, distinguishing new vs. returning accounts by comparing `createdAt`/`lastSignInAt`) versus email-confirmation links (always signs back out and routes to `SignInScreen`, since confirming an email should never silently log someone in).

**Key packages:** `supabase_flutter` (^2.16.0), `flutter_secure_storage` (^10.3.1, used to persist the session/PKCE verifier rather than the package's plain-SharedPreferences default, since a persisted session is a live credential).

**Notable challenges (evidenced):**
- The Google OAuth flow (`lib/screens/signin_screen.dart`, `_continueWithGoogle()`) uses `authScreenLaunchMode: LaunchMode.inAppWebView` and is wrapped in extensive `debugPrint("[GoogleAuth] ...")` logging at every step, and `main.dart`'s listener is similarly tagged `[AuthListener]`. This density of diagnostic logging around one specific flow is consistent with genuinely debugging a flaky OAuth return path (plausibly related to the "Google Sign-In black screen" issue), but no commit message names that bug explicitly, so this should be cited as circumstantial evidence, not a confirmed fix.
- Cloud sync (Phase 10, commit `87f4d892`, "Supabase cloud sync working") was built and shipped *before* real per-user auth scoping existed (Phase 11, commit `df0f48f`, "Supabase Auth, Google Sign In structure, real logout") — meaning the earliest synced rows have no owner at all. `backend/scripts/migrate_add_user_id.py` and `supabase_schema.sql` retrofit `user_id` scoping after the fact; rows predating the migration are permanently orphaned (`user_id IS NULL`) by design, not recovered.
- A much later, more serious bug (commit `04f13a0`, this development's own conversation history): the backend's SQLAlchemy model shared a Postgres table name (`ingredients`) with Supabase's own cloud-sync table. A direct SQLAlchemy connection carries no Supabase session, so Row-Level Security silently emptied every read and rejected every write. Root-caused via live production reproduction (curl against the deployed backend) plus a direct `information_schema.columns` query, then fixed by renaming the backend's table to `pantry_items` — see §1.3.

**Deviation from plan:** none specific to auth beyond the general Firebase→Supabase change already covered in §1.4.

### 2.2 Inventory CRUD

**Built:** `InventoryScreen` ("Pantry" tab) + `AddIngredientScreen` for manual add/edit, backed by the four `/ingredient*` REST endpoints and SQLAlchemy `crud.py` functions (`create_ingredient`, `get_ingredients`, `update_ingredient`, `delete_ingredient`).

**Key packages:** SQLAlchemy 2.0.51 + Pydantic 2.13.4 (backend, per `backend/requirements.txt`); the frontend uses the plain `http` package (^1.5.0) for REST calls — the originally planned package was `dio` (`z_ALL_DOC.md`, Supervisory Meeting 3: "Implement the Flutter frontend connecting to the backend via HTTP (dio package)"). No reasoning for the `dio` → `http` change is documented anywhere.

**Notable challenges (evidenced, chronological):**
1. No user scoping at all in the original schema (Phase 10) → user_id column added via a dedicated migration script once multi-account support was needed, orphaning legacy rows by design (see §2.1).
2. The `pantry_items`/`ingredients` table-name collision (§1.3, §2.1) — the core "ingredient save failing on deployed backend" bug, root-caused and fixed in commit `04f13a0`.
3. A follow-on RLS violation surfaced once cloud sync was tested again after that fix: pre-auth orphaned rows in Supabase's `ingredients` table collided by `id` with a freshly-syncing user's own new rows, since `id` alone was still the table's sole uniqueness constraint. Fixed (commit `f82f8ab`) with a composite `(id, user_id)` uniqueness constraint.
4. That fix then caused a *new* duplicate-key error on the next sync attempt, because removing the old primary key without replacing it left PostgREST with no default upsert-conflict target for any request that didn't explicitly specify one. Fixed by promoting `(id, user_id)` to an actual PRIMARY KEY (not just a UNIQUE constraint) and passing `onConflict` explicitly on every Supabase `.upsert()` call.
5. A delete-resurrection bug: `ApiService.deleteIngredient()`'s cloud-mirror delete is best-effort and silently swallows failure; with no way to distinguish "genuinely new cloud item" from "deleted locally, mirror never landed," the automatic resync that runs on every app launch (`MainScreen.initState()` → `SupabaseService.resolveConflicts()`) would resurrect a deleted ingredient. Fixed with a small persisted per-user tombstone set — new file `lib/services/delete_tombstones.dart`, consulted by `resolveConflicts()`/`syncFromCloud()` before treating a cloud-only row as new.

**Deviation:** the user-scoping retrofit described above (point 1) is the clearest example — the schema was designed single-tenant first and made multi-tenant later, rather than from the start.

### 2.3 Camera / classification pipeline

**Built:** `AiCameraScreen` (camera capture) → `IngredientClassifierService` (on-device MobileNetV2 TFLite inference, top-5 results) → `AddIngredientScreen` (top prediction pre-filled, user confirms). See §1.1 for the full flow.

**Key packages:** `camera` (^0.12.0+1), `image_picker` (^1.2.3), `tflite_flutter` (^0.12.1), `image` (^4.8.0, used for JPEG decode/resize to the model's 224×224 input).

**Model version history** (`ai_models/scripts/`, chronological — none of these overwrite the previous version's saved files, so each stayed available as a fallback):

| Version | Classes | Source dataset | Training recipe | Test accuracy recorded? |
|---|---|---|---|---|
| v1 (`train.py`, `download_dataset.py`) | 36 | Hugging Face `Nattakarn/fruit-and-vegetable-image-recognition` | Single-phase, 15 epochs, no fine-tuning | Not found anywhere in the repo |
| v2 (`train_v2.py`, `build_dataset_v2.py`) | 40 (36 + 4 dairy: milk, sour cream, sour milk, yoghurt) | MIT-licensed `marcusklasson/GroceryStoreDataset` (GitHub) | Two-phase (22 epochs head-only + 13 epochs fine-tune last 30 base layers) introduced here | Not found anywhere in the repo |
| v3 (`train_v3.py`, `build_dataset_v3.py`) | 56 (40 + 10 new fruit + 4 new vegetables + 2 dairy-alternative) | Same MIT-licensed `marcusklasson/GroceryStoreDataset` as v2. Docstring notes this source has no egg category at all — eggs were explicitly flagged as needing a different data source rather than silently skipped | Same two-phase recipe as v2 | Not found anywhere in the repo |
| v4 (`train_v4.py`, `build_dataset_v4.py`) — **current, shipped** | 68 (56 + 12 new) | MIT-licensed `marcusklasson/GroceryStoreDataset` + MIT-licensed Fruits-360 (`Horea94/Fruit-Images-Dataset`) | Same two-phase recipe; whichever phase (head-only vs. fine-tuned) scores higher on the held-out test set is kept | **85.59%** (`README.md`, `ai_models/scripts/train_v4.py` prints this at run time but no saved log file exists in the repo — the figure is only recorded in `README.md`'s prose) |

Note the licensing shift between versions: v1's source (`download_dataset.py`) was a Hugging Face dataset with no license explicitly recorded in that script, while v2 onward deliberately switched to sources whose MIT licensing is called out explicitly in-code (`build_dataset_v2.py`, `build_dataset_v3.py`, `build_dataset_v4.py` docstrings all name the license directly) — consistent with the project's own stated ethics/licensing concerns (`z_ALL_DOC.md`) but not explained as a reason anywhere in the commit history itself.

A specific, documented training bug (preserved as a code comment in both `train_v2.py` and `train_v3.py`): the `RandomBrightness` augmentation layer defaults to assuming `[0,255]`-range inputs, but training images were already rescaled to MobileNetV2's `[-1,1]` range by `preprocess_input` before reaching it — miscalibrating the brightness delta by roughly 128×. This silently wrecked an early run (training accuracy stuck around 18% while validation accuracy, which skips augmentation, still reached ~55%), diagnosed and fixed by passing an explicit `value_range=(-1,1)` argument.

Meat/protein species classification (chicken vs. beef vs. pork) was investigated and explicitly **not** added — no MIT/CC0-licensed dataset for raw-meat species classification was found; what exists publicly is mostly freshness/spoilage binary classifiers (documented in `ai_models/scripts/build_dataset_v4.py`'s docstring and `README.md`'s AI Model section).

**Deviation from plan — the largest one found in the whole project.** The originally planned computer-vision approach (`z_ALL_DOC.md`, multiple meeting records) was **YOLOv8n**, an object-*detection* model (bounding boxes, multiple items per frame), explicitly paired with TensorFlow Lite INT8 quantization (~6.3MB) for the NGO client's stated low-end-hardware constraint. What was actually shipped is **MobileNetV2 image classification** — one dominant ingredient per photo, ranked by confidence, no bounding boxes and no multi-item-per-frame detection. Supporting evidence this was a deliberate, if unexplained, pivot rather than an oversight: `docs/UI.md`'s "Known Design Debt" section notes that `ai_detection_screen.dart` — "a multi-item confidence-bar selection UI from the original Figma set" — still exists in the codebase but "isn't wired into the main capture flow," which instead routes single-prediction captures straight to `AddIngredientScreen`. In other words, the original *design* (Figma) still assumed multi-item detection matching the YOLO plan, but the shipped implementation only ever classifies one ingredient per photo. **No commit message or comment anywhere in the repo states why this change happened** — do not invent a reason (e.g. solo-developer time budget) without saying it is unconfirmed.

### 2.4 Recipe engine

**Built:** a pre-built in-memory keyword index over `backend/data/recipes_full.json` (172 hand-authored recipes as of this writing), built once at backend startup in `backend/app/routes/inventory.py`. Matching normalizes ingredient names (lowercase, de-pluralize, and map known spelling variants — e.g. `sweetpotato`→`sweet potato`, `capsicum`→`bell pepper` — to one canonical form, since the AI classifier's class names don't always match the recipe dataset's spelling), looks each up via exact-string index lookup (not fuzzy/substring matching — "pea" cannot match inside "peanut"), scores each candidate as `matched_ingredients / total_recipe_ingredients * 100`, and filters out anything scoring below 20% **or** sharing fewer than 2 actual ingredients (the second condition specifically catches a small recipe's score being inflated by one shared generic ingredient like garlic). `GET /ai-recommendation` optionally re-ranks the top 10 of those via an LLM call.

**Key packages:** no matching-specific library — pure Python/stdlib `json` for the dataset and index; `httpx` for the OpenRouter HTTP call.

**Original plan vs. actual (documented deviation, see §1.4 for the full reasoning citation):**

| | Originally planned | Actually built |
|---|---|---|
| Recipe source | Live LLM generation (Llama 3.2 via OpenRouter) | Fixed, hand-authored 172-recipe JSON dataset |
| Scoring | A weighted "hybrid AI scoring logic" — 0.5×Match Score + 0.3×Expiry Priority Score + 0.2×User Preference Score (worked example given in `z_ALL_DOC.md`, Supervisory Meeting 3) | A percentage match-score threshold plus a minimum-shared-ingredient-count filter; expiry urgency is handled as a *candidate-pool filter* in `/ai-recommendation` (prioritize recipes touching a today/soon-expiring ingredient, else fall back to the full pool), not a weighted score term |
| Offline behavior | An MD5-hash-based SQLite cache of the top 100 LLM-generated recipes, keyed by a hash of the sorted inventory list (`z_ALL_DOC.md`, Supervisory Meeting 3) | Not implemented — no hash-based cache exists anywhere in the repo. The dataset is already fully local/in-memory, so there is no "offline LLM" gap to cache around in the shipped design |

**Prior interim state (also a real, documented deviation):** before the current hand-authored dataset existed, the recipe "names" came from a cuisine-classification dataset (`cuisine_data.csv` / `recipes_index.json`) that only had cuisine labels ("french", "spanish") rather than real dish names — replaced by `backend/scripts/generate_recipes.py`, per that script's own docstring.

### 2.5 Notifications / expiry alerts

**Built:** `GET /expiry-status` recomputes a status label per ingredient on every call (not stored server-side) by comparing `expiry_date` against the server's current date. `NotificationService.checkAndNotify()` (`lib/services/notification_service.dart`) calls this endpoint and fires one local notification per ingredient whose status is `expired`, `today`, or `soon`, using the ingredient's own database `id` as the Android notification id — a deliberate de-duplication mechanism documented in `docs/PROJECT_FLOW.md`: calling it again *replaces* the existing notification rather than stacking a duplicate.

**Key packages:** `flutter_local_notifications` (^22.0.1).

**Deviation:** none specifically documented — this matches the general "alerts" functional requirement from the original planning documents (`z_ALL_DOC.md`'s FR list) without an identified scope change.

### 2.6 Statistics / waste dashboard

**Built:** `StatisticsScreen` (a "Pantry Right Now" snapshot pulling live totals/expired-count/recipes-matched from the backend, plus a "Cooking Impact" section — food-saved/recipes-cooked/monthly-trends/category-breakdown — computed entirely from `CookedHistoryStore`, a `SharedPreferences`-backed local store of what's actually been cooked) and `ProfileScreen` (Eco Score/Badges/Rescued, reading the same store independently). A separate, larger feature — **Waste Control** (`waste_control_screen.dart`: Regrow / Scrap Recipes / Compost tabs, plus a newly-added fourth "Storage Tips" tab) — is not a dashboard in the stats sense but is the app's other waste-reduction-education surface and was substantially expanded in the most recent development batch (new tab + more entries in each existing tab).

**Key packages:** no charting library — the category-breakdown donut chart is a hand-rolled `CustomPainter` (`_DonutPainter`); everything else is plain `shared_preferences` persistence.

**Deviation from plan, explicitly agreed with the client (not a silent scope drop):** the NGO client originally asked for "a dashboard that brings together information about the wastes anonymised for reporting to donors" (`z_ALL_DOC.md`, Client Meeting 1), and by the final client meeting this was explicitly reduced in scope: *"Daw Khin Than requested that the dashboard (NGO reporting) be included in the MVP – student clarified that this will be a simpler version (export to CSV) due to time constraints, but full dashboard may be a post-project enhancement. NGO accepted this."* (Client Meeting 5, 22 June 2026). What actually shipped is narrower still than even that reduced scope: a **personal, single-user** statistics screen, with **no anonymized/aggregate NGO-facing reporting and no CSV export found anywhere in the repo**. This should be reported as-is — the further reduction from "CSV export" to "no export at all" does not appear to be separately documented/agreed anywhere.

**Notable challenges (evidenced, both fixed):**
- "Stats not resetting for new accounts": `CookedHistoryStore`/`SavedRecipesStore` are correctly scoped per-user via `UserScope` (keyed by the Supabase user id, or a random per-install fallback id when signed out), but each also keeps an in-memory static cache for the running app process's lifetime. Without an explicit reset, a second account signing in within the same app session would still see the first account's cached figures until a full app restart. Fixed by calling `CookedHistoryStore.reset()` / `SavedRecipesStore.reset()` explicitly inside `ProfileScreen._performLogOut()`.
- "Items Expired" count on Statistics appearing not to decrease after deleting an expired item: investigated and traced this session — the Statistics screen itself was *not* the bug (it already re-fetches fresh on every visit, and the backend's delete/commit was already solid). The actual cause was the delete-resurrection bug described in §2.2: the visible symptom was on the Statistics screen, but the root cause was in cloud sync.

---

## 3. Testing

### 3.1 Automated / unit testing

**None exists.** `frontend/fridge2table_app/test/` is present but completely empty (confirmed directly — the directory contains no files, not even Flutter's default generated `widget_test.dart` template). `pubspec.yaml` lists `flutter_test` and `flutter_lints` (^6.0.0) as dev dependencies, but no test file was ever written to use them. The backend has no test directory, no test framework listed in `requirements.txt` (no `pytest`, etc.), and no test files anywhere under `backend/`.

The only "automated verification" evidenced anywhere in the repo is `flutter analyze` (Dart's static analyzer) being run as a gate after code changes — this checks for compile errors/lint issues, not behavior, and its results are not persisted anywhere (no CI config, no saved analyzer output committed to the repo).

### 3.2 Manual testing evidenced in the repository

- **Cross-environment networking setup**, documented in detail in `README.md` and `docs/PROJECT_FLOW.md`: Android emulator (auto-detected `10.0.2.2` address), physical device over USB (`adb reverse tcp:8000 tcp:8000`, with a specific troubleshooting checklist for the most common failure), physical device over Wi-Fi only (`--dart-define=API_BASE_URL=...` override), and the standalone release APK against the deployed Render backend. The specificity of this guidance (e.g. `ApiService` detecting the exact "forgot `adb reverse`" `SocketException` case and surfacing the precise fix) is strong indirect evidence of real manual testing across all of these configurations during development.
- **README "Known Issues" section**: three operational quirks recorded as manually discovered — running Uvicorn from the wrong directory, generic-feeling recipe names being a dataset-coverage gap rather than a bug, and Render's free-tier cold-start delay (~15 minutes idle before sleep, ~1 minute to wake on the next request).
- **Heuristic Evaluation** (`z_ALL_DOC.md`): a 10-item Nielsen heuristic walkthrough, but conducted by the student themselves on **wireframes**, before any code was written (dated 10 May 2026 meeting record) — this is an expert/self-evaluation of a design mockup, not user testing of the working app, and should not be conflated with the latter in the dissertation.

### 3.3 Manual testing performed during AI-assisted development sessions (not committed as repo artifacts)

Separately from anything findable in the repository's own files, the assistant-driven development sessions that produced several of the commits above included live, real testing against the actually-deployed system — for example, a full POST → GET → PUT → DELETE → GET reproduction cycle run directly against the live Render-deployed backend to both reproduce and then confirm the fix for the `pantry_items`/RLS bug (§2.1/§2.2), and a similar live local-server test (SQLite) for the expired/expiring recipe-annotation feature. **This testing is real but exists only in the development conversation history, not as a script, log, or file committed to the repository** — if citing it, distinguish it clearly from repo-evidenced testing.

### 3.4 Performance numbers

| Metric | Value | Source |
|---|---|---|
| AI model (v4) test accuracy | 85.59% | `README.md`; also printed at training time by `ai_models/scripts/train_v4.py`, but no run log is saved in the repo |
| AI model (v1–v3) test accuracy | **Not measured / not found anywhere in the repo** | — |
| On-device inference latency (ms per scan) | **Not measured** — no timing instrumentation exists in `ingredient_classifier_service.dart` or anywhere else | — |
| End-to-end scan-to-recipe latency | **Not measured** | — |
| Backend API response times | **Not measured** — no request-timing middleware or logging exists in `backend/app/main.py` | — |
| Render free-tier cold-start wake time | ~1 minute after ~15 minutes idle | `README.md`, "Known Issues" (an observed/reported figure, not a benchmarked one) |
| Recipe-matching computation time | **Not measured.** Given the dataset is loaded once into an in-memory index at backend startup (172 recipes), this is very likely sub-millisecond per request, but this is the notes author's inference from the implementation, not a measured figure — do not present it as measured. | — |

### 3.5 Known bug list, with status

| # | Bug | Status | Evidence |
|---|---|---|---|
| 1 | Google Sign-In black screen | **Presumed addressed — not explicitly confirmed.** No commit message or comment names this bug by name. | `signin_screen.dart`'s `_continueWithGoogle()` deliberately sets `authScreenLaunchMode: LaunchMode.inAppWebView` and is wrapped in dense `[GoogleAuth]`-tagged debug logging; `main.dart`'s auth listener has similarly dense `[AuthListener]` logging around the same OAuth-completion path. Consistent with, but not proof of, having debugged this exact symptom. |
| 2 | Save-ingredient timeout | **Fixed.** | `ApiService._send()` (`api_service.dart`) wraps every HTTP call in a 10-second timeout, distinguishing `TimeoutException` ("server didn't respond in time") from `SocketException` (including a specific detection of the "forgot `adb reverse`" case) with distinct, actionable messages instead of hanging indefinitely. |
| 3 | Empty-state spinners | **Fixed.** | Shared `AsyncStateBuilder<T>` widget (`lib/widgets/async_state.dart`) explicitly separates `ConnectionState.waiting` (spinner), `hasError` (retry button + message), genuinely-empty data (a dedicated "nothing here yet" empty state with configurable icon/title/subtitle), and real data — used across Inventory, Expiry Monitor, Recipe screens, etc. |
| 4 | Stats not resetting for new accounts | **Fixed.** | `ProfileScreen._performLogOut()` explicitly calls `CookedHistoryStore.reset()` and `SavedRecipesStore.reset()` before navigating to sign-in, clearing the in-memory caches on top of the existing per-user `UserScope` key scoping. |
| 5 | Ingredient save failing with HTTP 500 on the deployed backend | **Fixed** (commit `04f13a0`). | Root cause: backend's SQLAlchemy model shared a Postgres table name (`ingredients`) with Supabase's own cloud-sync table (RLS + auto-increment mismatch). Fixed via table rename to `pantry_items`. |
| 6 | Cloud sync "new row violates row-level security policy" | **Fixed** (commit `f82f8ab`). | Root cause: pre-auth orphaned rows (`user_id IS NULL`) collided by `id` with a newly-syncing user's own rows under the old single-column primary key. Fixed with a composite `(id, user_id)` uniqueness constraint. |
| 7 | Cloud sync duplicate-key violation (regression from fixing #6) | **Fixed.** | Root cause: removing the old primary key without replacing it left PostgREST with no default upsert-conflict target. Fixed by making `(id, user_id)` an actual primary key and passing `onConflict` explicitly on every Supabase upsert call. |
| 8 | Deleted ingredients silently reappearing (delete-resurrection) | **Fixed.** | Root cause: a silently-failed cloud mirror-delete had no tombstone, so the automatic resync run on every app launch treated the surviving cloud row as new and recreated the deleted ingredient locally. Fixed with a persisted per-user tombstone set (`lib/services/delete_tombstones.dart`). |

---

## 4. Evaluation Inputs

**No completed user-testing or questionnaire results data exists anywhere in this repository.** This is stated explicitly rather than inferred, after checking for CSV/spreadsheet files repo-wide (the only project CSV found is `backend/cuisine_data.csv`, an unrelated licensed ingredient/cuisine-label dataset used only as loose inspiration for recipe generation — see §2.4 — not test data of any kind), and after reading the full contents of `z_ALL_DOC.md`.

What **does** exist in `z_ALL_DOC.md` (a consolidated FYP documentation file at the repo root) is pre-testing paperwork, not results:
- A **Participant Information Sheet** describing a planned 15–20 minute usability test (scan a mock fridge, review/edit detected ingredients, generate a recipe recommendation, answer 5–6 short questions) for 5–7 participants.
- An **Ethics Supervisor Certification Record** and a **Consent Form**, the latter signed by 5 named participants (Emily Johnson, Michael Brown, Sarah Williams, David Jones, Emma Davies), dated 4–5 May 2026.
- A **Heuristic Evaluation** (Nielsen's 10 heuristics) conducted by the student on wireframes, dated around 10 May 2026 — an expert self-evaluation of a pre-development mockup, not user testing of the finished app.

Chronological note worth flagging: per the meeting records in the same file, recruiting the 5–7 test participants and running actual usability sessions was still described as a *future* step as of the last recorded client meeting (22 June 2026, Client Meeting 5) — "NGO agreed to recruit 5-7 test users for usability testing once a working prototype is ready" — which is after the consent form's dated signatures (4–5 May 2026). This is consistent with the consent form being **template/example documentation prepared for the ethics submission**, not a record of a completed testing session. No task-completion times, error counts, System Usability Scale or other questionnaire responses, or any other post-session data were found anywhere in the repository. If usability testing was in fact carried out later, its results are not captured in this repository and must be sourced separately.
