# Fridge2Table (F2T) — Project Overview

Final Year Project (FYP), University of Sunderland, CET300. Student: Chaw Thiri Win (ID bj21de). Supervisor: Myo Myo Than Naing. Client: Myanmar Food Waste Reduction NGO (Yangon Chapter).

---

## 1. Problem Statement

Documented in `z_ALL_DOC.md` (client meeting records, kept local-only, not in this repo's git history — see the root `.gitignore`):

- Myanmar households waste an estimated 25–30% of food.
- The client NGO's current process is entirely manual: 10-page paper checklists, staff photograph fridge contents, and expiry dates are estimated back at the office — roughly 2 hours per household.
- At that rate they can only audit ~50 households/month (1,200/year) against a country of ~7 million urban households.
- Manual expiry estimation has a reported ~40% error rate, and there is no personalized recipe guidance for what a household should cook with what it already has.
- Non-functional constraints from the client: the app should tolerate low connectivity, run on modest hardware, and (per early planning) ideally support Burmese language and local ingredients/cuisine — the last two were not carried into the shipped implementation (see §5, Known Limitations).

## 2. Solution

Fridge2Table is a mobile pantry-management app that:
1. Lets a user log what's in their kitchen — manually, or by pointing a camera at an ingredient for on-device AI identification.
2. Tracks expiry dates and surfaces what's expired / expiring soon.
3. Matches the current pantry against a curated recipe dataset, so suggestions are grounded in what's actually on hand rather than generic recipe browsing.
4. Walks the user through cooking a matched recipe and deducts real quantities from the pantry afterward.
5. Backs all of this up to the cloud (optional, requires an account) so it survives a reinstall or carries over to a second device.

## 3. Full Tech Stack

| Layer | Technology | Notes |
|---|---|---|
| Frontend framework | Flutter (Dart), Material widgets | Single codebase, targets Android (the only platform actually built/tested against — no iOS-specific work found in the repo) |
| Frontend HTTP client | `http` package (^1.5.0) | Original plan specified `dio`; the shipped app uses `http` instead — no documented reason for the change |
| Backend framework | FastAPI (Python), Uvicorn | `backend/app/main.py` |
| Backend ORM | SQLAlchemy 2.0.51 | `backend/app/models.py`, `crud.py` |
| Backend validation | Pydantic 2.13.4 | `backend/app/schemas.py` |
| Database (production) | Postgres via Supabase (Session Pooler connection string) | Selected automatically via the `DATABASE_URL` environment variable |
| Database (local dev) | SQLite (`backend/fridge2table.db`) | Used whenever `DATABASE_URL` is unset |
| Auth | Supabase Auth — email/password and Google OAuth | `supabase_flutter` package |
| Cloud sync target | A second, independent Supabase Postgres table (`public.ingredients`), accessed directly by the Flutter client via the Supabase SDK — **not** the same table the FastAPI backend uses | See `docs/DATABASE_SCHEMA.md` |
| On-device AI (ingredient recognition) | MobileNetV2 transfer learning, exported to TensorFlow Lite | `tflite_flutter` package, runs fully on-device, no image ever leaves the phone |
| Optional AI recipe re-rank | OpenRouter, model `meta-llama/llama-3.3-70b-instruct:free` | Backend-side only; the app works fully without an API key (falls back to the top deterministic match) |
| Camera / image picking | `camera` (^0.12.0+1), `image_picker` (^1.2.3) | |
| Local notifications library | `flutter_local_notifications` (^22.0.1) | Present and implemented (`NotificationService`) but **never invoked anywhere in the app** — see §5 |
| Local secure storage | `flutter_secure_storage` (^10.3.1) | Supabase session tokens, PKCE verifier, cached name/email |
| Local plain storage | `shared_preferences` (^2.5.5) | Diet/allergy prefs, cooked history, saved-recipe bookmarks, delete tombstones |
| Backend hosting | Render (free tier) | `render.yaml` |
| Recipe dataset | Hand-authored JSON (`backend/data/recipes_full.json`), 302 recipes | Generated via `backend/scripts/generate_recipes.py` |
| Design source | Figma (file key `naaKMnLlp5usmlvppkaiMY`) | See `docs/UI.md` |

## 4. Phase-by-Phase Development History

**Important caveat on this section:** the git history for this project is heavily squashed. The very first commit (`52ecf4f`, "Initial commit - Fridge2Table FYP phases 1-10") bundles everything built up through Phase 10 into one commit with no per-phase breakdown recoverable from git itself. Only Phases 10 and 11 are explicitly named in any commit message. Phases 12–13 (claimed complete in the root `README.md`) are **not** individually identified anywhere in the commit history either. Rather than inventing a clean 13-part narrative that isn't evidenced, this section reports what's actually verifiable: the two explicitly labeled phases, and the chronological commit history for everything else, described by what each commit actually changed.

| Commit | Date | What it establishes |
|---|---|---|
| `52ecf4f` | 2026-07-16 | **Initial commit — Phases 1–10.** Everything foundational: Flutter app shell, 4-tab bottom nav, FastAPI backend with SQLite, ingredient CRUD, camera capture + on-device MobileNetV2 classification (early model versions), recipe matching against an early dataset, expiry monitoring, the core screen set. No finer-grained phase breakdown is recoverable from this commit alone. |
| `1fa7161` | 2026-07-19 | Fix filter chips, Waste Control detail sheets, notifications screen. |
| `87f4d89` | 2026-07-20 | **"Phase 10 complete" (explicitly labeled)** — Supabase cloud sync working (this is when the shared, then-unscoped `public.ingredients` table was created — see `supabase_schema.sql`'s own history note). |
| `df0f48f` | 2026-07-20 | **"Phase 11 complete" (explicitly labeled)** — Supabase Auth (email/password + Google OAuth structure), real logout. |
| `e4db234` | 2026-07-25 | Standalone backend deployment (Render + Supabase Postgres via `DATABASE_URL`), first cloud-sync duplicate-row bugfix, recipe matching/AI model improvements (68-class model, 85.59% test accuracy), repo cleanup (stopped tracking datasets/venvs/build artifacts). |
| `db5943e` | 2026-07-26 | Quantity adjustment on cooking, allergy warning dialog, expiry-priority AI recommendations. |
| `04f13a0` | 2026-07-26 | Fixed ingredient save failing in production — root cause was the backend's own SQLAlchemy table sharing a name with Supabase's separate cloud-sync table; renamed to `pantry_items` (see `docs/DATABASE_SCHEMA.md`). |
| `f82f8ab` | 2026-07-27 | Fixed a follow-on cloud-sync RLS/constraint issue, unified the "by measurement"/"by estimate" cooking-quantity flow into one screen, added the allergy dialog. |
| `ab9b290` | 2026-07-27 | Quantity validation against real stock, delete confirmation dialogs, expired-item salvage routing to Waste Control, diet warnings for all diet types, more recipes, added the Storage Tips tab. |
| `75b2417` | 2026-07-28 | Fixed the delete-tombstone gap (deleted ingredients no longer resurrect via sync), added expired/expiring recipe annotations. |
| *(uncommitted at time of writing)* | 2026-07-29 | Small-pantry recipe matching fix, expanded recipe dataset to 302, diet/allergy preference-loading fix, split "Items Expired" into "Expiring Soon" + "Expired", pantry-screen urgency badges. |

## 5. Every Feature Currently Working

Verified directly against the current codebase (not inferred from docs or claims):

**Accounts & onboarding**
- 5-page onboarding carousel (`splash_screen.dart`)
- Email/password sign up and sign in, with a "check your email" flow when Supabase requires confirmation
- Google OAuth sign in/sign up (in-app WebView), with a "new account vs. returning" confirmation dialog
- Diet preference + allergy setup during onboarding, editable later from Profile — **correctly loads previously-saved selections now** (fixed this session; previously always opened blank)
- Real logout (clears cached identity, resets in-memory `CookedHistoryStore`/`SavedRecipesStore` caches)

**Pantry management**
- Manual add/edit ingredient (name, quantity, unit, category, storage location, expiry date)
- AI camera scan: capture or gallery-pick → on-device MobileNetV2 classification → top-3 candidates shown as selectable confidence chips (`AiDetectionScreen`) → chosen prediction pre-fills the Add Ingredient form
- Pantry list with search and category filter chips
- Per-item urgency badge on Pantry cards (red "Expired" / orange "Today" / yellow "Soon", nothing for fresh/unknown)
- Delete with confirmation dialog (single item); "Clear Data" (Settings) deletes everything, also confirmed
- Expiry Monitor screen: items grouped by expired/today/soon/fresh/unknown, "Delete All Expired" (confirmed), per-item delete (confirmed)
- Tapping an item in Expiry Monitor: non-expired items get a recipe-suggestion bottom sheet; **expired** items get a distinct "not safe to cook with, here's how to salvage it" sheet that routes into Waste Control instead

**Recipes**
- Matching against 302 hand-authored recipes, normalized-name matching (lowercasing, de-pluralizing, synonym mapping), percentage score + minimum-shared-ingredient-count filtering, with a relaxed threshold for small pantries (<5 items)
- Recipe screen filters: AI Picks / Quick / Healthy / Saved / Cooked, plus free-text search
- AI-picked "best recipe" banner, backed by an optional OpenRouter call with a deterministic fallback
- Recipe Detail: allergy-conflict banner, diet-conflict banner (all 9 diet types, including the rougher Keto/Low Sugar heuristics), expired/expiring-ingredient banner, and a **blocking** confirmation dialog (not a snackbar) before Cook Now if there's an allergy/diet conflict
- Save/bookmark a recipe

**Cooking flow**
- Cooking Mode: step-by-step instructions with a progress bar
- Cooking Confirm: "by measurement" vs. "by estimate" choice, both routing to the same Adjust Quantities screen
- Adjust Quantities: per-ingredient editable amount (pre-filled with a typical-usage default), per-ingredient skip toggle, and live validation blocking Confirm if an amount exceeds what's actually in stock
- Recipe Complete: real pantry deduction summary, estimated food-saved/CO₂/money/points figures
- Cooked History: persisted per-user list of everything cooked, with "Cook Again"

**Statistics & profile**
- Statistics: "Your Pantry Right Now" (Items in Pantry / Expiring Soon / Expired / Recipes Matched, 2×2 grid), "Cooking Impact" (Food Saved / Recipes Cooked), a 6-month trend bar chart, and a "Most Used Categories" donut chart — all computed from real backend/local-history data, no placeholder numbers
- Profile: Eco Score / Badges / Rescued stats, diet preference and allergy summary cards (with per-allergy severity), account navigation, Log Out

**Waste reduction**
- Waste Control: 4 tabs — Regrow (17 entries), Scrap Recipes (17 entries), Compost (10 entries + a composting-methods comparison), Storage Tips (8 entries) — search across all, tap-through detail sheets

**Cloud sync**
- Manual "Sync Now" (two-way conflict resolution by `updated_at`)
- Automatic best-effort sync on every app launch
- Delete-tombstone mechanism so a deleted ingredient doesn't get silently resurrected by the next sync

**In-app notifications**
- A dedicated Notifications screen (grouped expired/today/soon, live-computed from the same `/expiry-status` data) — this works. **This is distinct from OS-level push notifications, which do not currently fire — see §6.**

## 6. Known Limitations & Intentional Design Decisions

Listed plainly, distinguishing genuine gaps from deliberate scope decisions:

**Genuine gaps (not flagged as intentional anywhere in the code or docs):**
- **`NotificationService` (OS push notifications) is fully implemented but never called anywhere in the app.** Neither `NotificationService.initialize()` nor `.checkAndNotify()` appears in `main.dart`, any screen, or any service (confirmed via a repo-wide search). The `flutter_local_notifications` plugin is never initialized and no system notification is ever fired, despite this being described as a working feature in `README.md` and `docs/PROJECT_FLOW.md`. The in-app Notifications *screen* does work correctly (it computes live from `/expiry-status`) — only the OS-level push mechanism is disconnected.
- `models/recipe.dart` (the `Recipe` class) is dead code — nothing in the app imports or instantiates it. It was superseded by `RecipeDetail` (`models/recipe_detail.dart`).
- `docs/UI.md`'s "Known Design Debt" note claims `ai_detection_screen.dart` "isn't wired into the main capture flow." This is now **incorrect** based on the current code: `AiCameraScreen._goToAddIngredient()` routes every capture (camera or gallery) through `AiDetectionScreen` first, which shows the top-3 classification candidates as selectable confidence chips before the user proceeds to `AddIngredientScreen`. Whether this changed since that doc was written or the doc was simply wrong isn't determinable from git history.

**UI present but not functionally wired up (placeholders):**
- Cloud Sync screen's "Sync on WiFi" / "Mobile Data" / "Background Sync" toggles are local UI state only — they don't persist and have no effect on when sync actually runs (sync only happens via the manual "Sync Now" button and the one automatic call on app launch).
- Settings screen's "Push Notifications" / "Expiry Alerts" / "Recipe Suggestions" / "Dark Mode" toggles are the same — local state only, no backing behavior (Dark Mode explicitly shows a "coming soon" snackbar).
- Settings' "Language: English" row and "Forgot password?" on Sign In both show "coming soon" snackbars.
- Profile's "Help & Support" row shows a "coming soon" snackbar instead of opening a real screen.
- Cooking Mode's timer button shows a "coming soon" snackbar.
- Cloud Sync screen's "Local Database ... 2.4 MB" size figure is a hardcoded string, not a computed value (the item count next to it *is* live).

**Deliberate design decisions (documented reasoning found in code/commits):**
- The backend's own ingredient table is deliberately separate from the cloud-sync table (`pantry_items` vs. Supabase's `public.ingredients`) — see `docs/DATABASE_SCHEMA.md` for why.
- Cloud sync mirrors the local backend's own auto-increment id to the cloud rather than using an independent UUID scheme — acceptable for one local backend talking to one cloud project, explicitly documented in `supabase_service.dart` as *not* a strict arbitrary-multi-device-safe design.
- Legacy rows created before per-user scoping existed (both in the local backend and in Supabase) are permanently orphaned by design — never deleted, never shown to any user, since there's no reliable way to know which account they originally belonged to.
- Meat/protein *species* AI classification (chicken vs. beef vs. pork) was investigated and explicitly not added — no MIT/CC0-licensed dataset exists for this; what's publicly available is mostly freshness/spoilage binary classifiers, not species classifiers.
- No automated tests exist anywhere in the repo — `frontend/fridge2table_app/test/` is present but empty, and the backend has no test framework installed. This is a real gap for the Testing section of the FYP report to address honestly, not something to imply exists.

**Client-agreed scope reductions (evidenced in `z_ALL_DOC.md` meeting records, not silent drops):**
- No NGO-facing aggregate/anonymized waste-reporting dashboard, and no CSV export — the client explicitly accepted this being pushed to "post-project enhancement" (Client Meeting 5).
- No offline/no-connectivity mode, no Burmese language support, no explicit multi-user/shared-device mode — all discussed in early planning but not present in the shipped app, with no specific commit or doc explaining the drop (most plausibly a scope-vs-time-budget tradeoff for a solo FYP, though this reasoning is not documented anywhere and should not be presented as confirmed).
- The originally planned computer-vision approach was YOLOv8n object detection (multi-item, bounding boxes, chosen partly for low-end-hardware INT8 quantization). What shipped is MobileNetV2 image classification (one photo → ranked candidates, no bounding boxes). No commit or comment explains this specific pivot.

## 7. Deadline & Current Status

- Stated project timeline (`README.md`): **2026-02-09 → 2026-08-07**.
- `README.md` states all 13 planned phases are complete; as noted in §4, this claim is not independently verifiable phase-by-phase from git history — only Phases 10 and 11 are individually evidenced.
- As of the most recent development session (2026-07-29), the app is functionally complete for its core loop (add ingredients → track expiry → match recipes → cook → sync), with the gaps listed in §6 being the main things to caveat in a written report rather than present as fully working.
