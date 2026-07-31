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
| Local notifications library | `flutter_local_notifications` (^22.0.1) | Implemented and wired up (`NotificationService.checkAndNotify()`, called from Home load and every app resume) — see §5 |
| Local secure storage | `flutter_secure_storage` (^10.3.1) | Supabase session tokens, PKCE verifier, cached name/email |
| Local plain storage | `shared_preferences` (^2.5.5) | Diet/allergy prefs, cooked history, saved-recipe bookmarks, delete tombstones |
| Offline pantry cache | `sqflite` (^2.4.3) | `LocalPantryStore` — local mirror + pending-write queue for offline pantry use, see `docs/ARCHITECTURE.md` §7 |
| Connectivity detection | `connectivity_plus` (^7.3.1) | Drives the offline banner, reconnect-triggered sync, and auto-backup WiFi/mobile-data gating |
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
| `1ab5dba` | 2026-07-31 | Offline mode: `LocalPantryStore` (sqflite) local pantry mirror + pending-write queue, offline-first add/edit/delete, reconnect-triggered sync, offline banner; recipes deliberately stay online-only. |
| *(this session, 2026-07-31)* | 2026-07-31 | Root-caused and fixed a real backup/restore duplication bug introduced by the offline-mode work above (see §6); Pantry "Select All" in multi-select delete; cooking-timer data-coverage backfill (4→93 recipes); Android adaptive launcher icon no longer clipped by circular launcher masks; startup no longer blocks on notification-channel setup; app-wide font switched DM Sans→Manrope; pending-sync indicator on Pantry cards; Home's insight banner is now expired/soon/fresh three-state instead of only expiring-soon/fresh; recipe matching (and the AI-pick fallback) now also works offline via `LocalRecipeMatcher`, a Dart port of the backend's matching algorithm. |
| *(this session, follow-up, 2026-07-31)* | 2026-07-31 | App-wide back-button audit (25 screens, one real navigation bug found and fixed — see §6); offline recipe matching cross-verified byte-identical against the backend's own algorithm via a new automated test (`test/local_recipe_matcher_test.dart`, the first real test in the repo), which surfaced and fixed a non-deterministic tie-break at the 25-result cutoff (now `(match_score desc, name asc)` on both backend and Dart); multi-select delete gained a progress dialog, auto-refresh, and a completion toast. |

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
- Delete with confirmation dialog (single item); multi-select delete with a "Select All"/"Deselect All" toggle scoped to the current search/filter, not the whole pantry, a progress dialog while the (sequential, per-item) bulk delete runs, an automatic list refresh once it's done, and a "N items deleted" confirmation; "Clear Data" (Settings) deletes everything, also confirmed
- Works offline: viewing, adding, editing, and deleting pantry items all work with no network, queueing locally and syncing automatically on reconnect (`LocalPantryStore`, see §6 below for what changed and `docs/ARCHITECTURE.md` §7 for the full mechanism) — a "Syncing…" badge on a Pantry card shows a pending offline edit hasn't reached the server yet
- Expiry Monitor screen: items grouped by expired/today/soon/fresh/unknown, "Delete All Expired" (confirmed), per-item delete (confirmed)
- Tapping an item in Expiry Monitor: non-expired items get a recipe-suggestion bottom sheet; **expired** items get a distinct "not safe to cook with, here's how to salvage it" sheet that routes into Waste Control instead

**Recipes**
- Matching against 302 hand-authored recipes, normalized-name matching (lowercasing, de-pluralizing, synonym mapping), percentage score + minimum-shared-ingredient-count filtering, with a relaxed threshold for small pantries (<5 items)
- **Works offline too** (added this session, after the initial offline-mode work above deliberately left recipes online-only): `LocalRecipeMatcher` is a rule-for-rule Dart port of the backend's matching algorithm, run against a bundled copy of the recipe dataset and the cached pantry — same scoring/thresholds, so offline results genuinely match what the backend would return for the same pantry, not a degraded approximation. `RecipeScreen` shows a small "showing matches from your last synced pantry" note instead of the earlier (now removed) "needs an internet connection" block. **Verified, not assumed:** a real automated test (`test/local_recipe_matcher_test.dart`) cross-checks this against the backend's own matching logic called directly, confirming byte-identical results (recipe names, scores, expiry annotations) for four real pantries — see §6 for the one real gap that comparison found and fixed.
- Recipe screen filters: AI Picks / Quick / Healthy / Saved / Cooked, plus free-text search
- AI-picked "best recipe" banner, backed by an optional OpenRouter call online, or the same deterministic top-match fallback offline that the backend itself uses when no OpenRouter key is configured (no local LLM)
- Recipe Detail: allergy-conflict banner, diet-conflict banner (all 9 diet types, including the rougher Keto/Low Sugar heuristics), expired/expiring-ingredient banner, and a **blocking** confirmation dialog (not a snackbar) before Cook Now if there's an allergy/diet conflict
- Save/bookmark a recipe

**Cooking flow**
- Cooking Mode: step-by-step instructions with a progress bar; steps with an annotated duration (`step_timers`, 93/302 recipes as of this session — see `backend/scripts/backfill_step_timers.py`) show a countdown with Start/Pause/Reset that plays a system sound, vibrates, and shows a "Timer done" snackbar on reaching zero
- Cooking Confirm: "by measurement" vs. "by estimate" choice, both routing to the same Adjust Quantities screen
- Adjust Quantities: per-ingredient editable amount (pre-filled with a typical-usage default), per-ingredient skip toggle, and live validation blocking Confirm if an amount exceeds what's actually in stock
- Recipe Complete: real pantry deduction summary, estimated food-saved/CO₂/money/points figures
- Cooked History: persisted per-user list of everything cooked, with "Cook Again"

**Statistics & profile**
- Statistics: "Your Pantry Right Now" (Items in Pantry / Expiring Soon / Expired / Recipes Matched, 2×2 grid), "Cooking Impact" (Food Saved / Recipes Cooked), a 6-month trend bar chart, and a "Most Used Categories" donut chart — all computed from real backend/local-history data, no placeholder numbers
- Profile: Eco Score / Badges / Rescued stats, diet preference and allergy summary cards (with per-allergy severity), account navigation, Log Out

**Waste reduction**
- Waste Control: 4 tabs — Regrow (17 entries), Scrap Recipes (17 entries), Compost (10 entries + a composting-methods comparison), Storage Tips (8 entries) — search across all, tap-through detail sheets

**Backup & Restore (cloud sync to the secondary Supabase mirror table)**
- Manual "Back Up Now" (`resolveConflicts()`, two-way conflict resolution by `updated_at`) and "Restore" (`syncFromCloud()`, pull-only)
- Automatic best-effort backup, gated by working "Auto Backup on WiFi"/"Auto Backup on Mobile Data" toggles, plus a 15-minute background timer while "Background Backup" is on
- Delete-tombstone mechanism so a deleted ingredient doesn't get silently resurrected by the next sync
- A real duplication bug in this mechanism (introduced by, and root-caused/fixed this session) is documented in §6

**In-app + OS notifications**
- A dedicated Notifications screen (grouped expired/today/soon, live-computed from the same `/expiry-status` data)
- OS-level push notifications now fire too (`NotificationService.checkAndNotify()`, Home load + every app resume, capped at one per ingredient per calendar day)

## 6. Known Limitations & Intentional Design Decisions

Listed plainly, distinguishing genuine gaps from deliberate scope decisions:

**Fixed this session — backup/restore duplication bug (data integrity, worth flagging prominently for the report):** offline mode's `ApiService.addIngredient()` was rewritten to strip the id off every create, so a brand-new locally-created item never sent its (nonexistent) id to the backend — correct for that case. But `SupabaseService.resolveConflicts()`/`syncFromCloud()` also call `addIngredient(cloudItem)` for every cloud-only row *specifically relying on the id being preserved*, so the resulting local row lands on the backend with the same id the cloud copy already has — that's what makes a repeated backup/restore idempotent (the backend upserts-by-id instead of inserting a fresh row). Stripping the id unconditionally broke that: every cloud-only row got a brand-new id on every single sync, so it could never be recognized as "already pulled in" and kept getting duplicated — a real user-reported case went 15 items → 36 → 51 across one Backup then one Restore tap. Root-caused (not just patched) and fixed in `ApiService._createIngredientOnServer()` (id is preserved when positive, stripped only when null or the offline-queue's negative local sentinel), and confirmed with real logged before/after row counts across four consecutive Backup/Restore taps (stable at the same count, zero spurious changes, each time) — see `docs/ARCHITECTURE.md` §6.

**Fixed this session — app-wide back-button audit turned up one real navigation bug:** every screen with a back button was individually checked (correct target, no crash/stuck state, consistently wired) — 25 screens total, all confirmed correctly wired or deliberately without one (root tab screens, auth screens always reached with a clean stack, the post-cooking completion screen which shouldn't allow backing into an already-applied deduction). The one genuine bug: `DietPreferencesScreen._finish()` always did `Navigator.pushReplacement(MainScreen)` regardless of how the screen was reached, which was wrong in both of its two contexts — for first-time onboarding it left SignInScreen/CreateAccountScreen still reachable via system back from a newly-registered, already-signed-in user's Home tab (only the immediate screen gets replaced, not the whole stack); for editing from Profile it pushed a *second* MainScreen on top of Profile instead of returning to the one already there, and Profile's edit link had no way to cancel out on step 1 at all (the only back control was the internal step-2→step-1 wizard chevron). Fixed with a required `isOnboarding` flag distinguishing the two call sites, `pushAndRemoveUntil` for onboarding, a plain `pop` for editing, and a real header back button now shown on both steps when editing. Full detail: `docs/CODEBASE_GUIDE.md`'s `diet_preferences_screen.dart` entry.

**Genuine gaps (not flagged as intentional anywhere in the code or docs):**
- `models/recipe.dart` (the `Recipe` class) is dead code — nothing in the app imports or instantiates it. It was superseded by `RecipeDetail` (`models/recipe_detail.dart`).
- `docs/UI.md`'s "Known Design Debt" note claims `ai_detection_screen.dart` "isn't wired into the main capture flow." This is now **incorrect** based on the current code: `AiCameraScreen._goToAddIngredient()` routes every capture (camera or gallery) through `AiDetectionScreen` first, which shows the top-3 classification candidates as selectable confidence chips before the user proceeds to `AddIngredientScreen`. Whether this changed since that doc was written or the doc was simply wrong isn't determinable from git history.
- The native Android launch screen (shown before the Flutter engine draws its first frame — `android/app/src/main/res/drawable/launch_background.xml`) is a plain white background with no branding, and doesn't use the modern Android 12+ splash screen API. Not fixed this session (bigger scope: a new plugin dependency plus native Android *and* iOS config regeneration) — flagged here as a real, easy-to-greenlight follow-up if a more polished cold-start is wanted; what *was* fixed this session was app-code-level startup latency: `main()` previously `await`ed three sequential platform-channel calls before `runApp()` (device-info lookup, Supabase init, notification-channel setup); notification-channel setup is now fired unawaited *after* `runApp()` instead, since nothing on the first screen needs it (see `docs/CODEBASE_GUIDE.md`'s `main.dart` entry).

**UI present but not functionally wired up (placeholders):**
- Settings screen's "Expiry Alerts" / "Language: English" row and Dark Mode toggle remain local-state-only placeholders (Dark Mode explicitly shows a "coming soon" snackbar); "Push Notifications" and "Recipe Suggestions" are now real, persisted, backing-behavior toggles (`AppSettingsService`).
- Profile's "Help & Support" row shows a real dialog with a contact email + copy button (see `docs/AUDIT_FIXES.md` #5), not a "coming soon" snackbar anymore.

**Deliberate design decisions (documented reasoning found in code/commits):**
- The backend's own ingredient table is deliberately separate from the cloud-sync table (`pantry_items` vs. Supabase's `public.ingredients`) — see `docs/DATABASE_SCHEMA.md` for why.
- Cloud sync mirrors the local backend's own auto-increment id to the cloud rather than using an independent UUID scheme — acceptable for one local backend talking to one cloud project, explicitly documented in `supabase_service.dart` as *not* a strict arbitrary-multi-device-safe design.
- Legacy rows created before per-user scoping existed (both in the local backend and in Supabase) are permanently orphaned by design — never deleted, never shown to any user, since there's no reliable way to know which account they originally belonged to.
- Meat/protein *species* AI classification (chicken vs. beef vs. pork) was investigated and explicitly not added — no MIT/CC0-licensed dataset exists for this; what's publicly available is mostly freshness/spoilage binary classifiers, not species classifiers.
- Automated test coverage is minimal, not absent: `frontend/fridge2table_app/test/local_recipe_matcher_test.dart` (added this session) is the one real automated test in the repo — it verifies `LocalRecipeMatcher`'s offline matching against the backend's own algorithm (see `docs/CODEBASE_GUIDE.md`'s "Frontend Tests" section). Nothing else is covered: no widget tests, no other unit tests, and the backend has no test framework installed at all. Still a real gap for the Testing section of the FYP report to address honestly, just not a total absence anymore.

**Client-agreed scope reductions (evidenced in `z_ALL_DOC.md` meeting records, not silent drops):**
- No NGO-facing aggregate/anonymized waste-reporting dashboard, and no CSV export — the client explicitly accepted this being pushed to "post-project enhancement" (Client Meeting 5).
- No Burmese language support, no explicit multi-user/shared-device mode — discussed in early planning but not present in the shipped app, with no specific commit or doc explaining the drop (most plausibly a scope-vs-time-budget tradeoff for a solo FYP, though this reasoning is not documented anywhere and should not be presented as confirmed). **Offline/no-connectivity tolerance, by contrast, is no longer a scope reduction at all** — the pantry shipped offline-capable first (`LocalPantryStore`), and recipe matching followed in a same-project follow-up (`LocalRecipeMatcher`), directly answering the client's original non-functional requirement (§1) that the app tolerate low connectivity, for the app's two core data-driven features. The one remaining online-only piece is the OpenRouter LLM re-rank specifically (falls back to the same deterministic top-match logic used when no API key is configured at all) — there's no local LLM to substitute, which is a real hardware/scope constraint, not an oversight.
- The originally planned computer-vision approach was YOLOv8n object detection (multi-item, bounding boxes, chosen partly for low-end-hardware INT8 quantization). What shipped is MobileNetV2 image classification (one photo → ranked candidates, no bounding boxes). No commit or comment explains this specific pivot.

## 7. Deadline & Current Status

- Stated project timeline (`README.md`): **2026-02-09 → 2026-08-07**.
- `README.md` states all 13 planned phases are complete; as noted in §4, this claim is not independently verifiable phase-by-phase from git history — only Phases 10 and 11 are individually evidenced.
- As of the most recent development session (2026-07-31), the app is functionally complete for its core loop (add ingredients → track expiry → match recipes → cook → sync) **and now works offline for the pantry itself** (add/edit/delete/view all work with no network, syncing automatically on reconnect), with the gaps listed in §6 being the main things to caveat in a written report rather than present as fully working.
