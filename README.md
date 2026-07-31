# Fridge2Table (F2T)

An AI-powered mobile app that helps households reduce food waste through smart pantry inventory management, expiry tracking, camera-based ingredient recognition, and recipe recommendations built from what's actually in stock.

Final Year University Project (FYP), University of Sunderland, CET300. Timeline: 2026-02-09 → 2026-08-07.

**📚 Full technical documentation lives in [`docs/`](docs/README.md)** — architecture diagrams, database schema, use cases, API reference, a per-file codebase guide, and an honest data-persistence breakdown. This README is a quick-start/overview; `docs/` is where the detail is.

## Live Deployment

| What | Where |
|---|---|
| Backend API | [`https://fridge2table-backend.onrender.com`](https://fridge2table-backend.onrender.com) (Render, free tier — see [Cold starts](#known-issues)) |
| Backend health check | `GET https://fridge2table-backend.onrender.com/` → `{"message": "F2T Backend Running"}` |
| Interactive API docs | `https://fridge2table-backend.onrender.com/docs` (FastAPI's auto-generated Swagger UI) |
| Database + Auth | Supabase project `xdwlhmuhqsndkimejlvi` (`https://xdwlhmuhqsndkimejlvi.supabase.co`) — see `frontend/fridge2table_app/lib/config/supabase_config.dart`. The publishable (anon) key embedded there is meant to be public and is protected by Row-Level Security; nothing sensitive is exposed by it. |
| Release APK | Not published anywhere — build your own with `flutter build apk --release` (see [Quick Start](#quick-start)). |

## Quick Start

### If you just want to run the app (standalone, no dev setup)
1. Get a built `app-release.apk` (build it yourself — see the [Deployment](#deployment) section — there's no pre-built APK hosted anywhere).
2. Install it on an Android phone (`adb install app-release.apk`, or copy the file to the phone and tap it).
3. Open the app, create an account or sign in. It talks straight to the deployed Render backend — **no USB, no dev machine, no local setup needed** after install.

Packaged builds now use the Fridge2Table branding as the launcher icon, so the app shows the custom logo on the home screen and in installed-app listings after you build and install a release APK.

### If you're developing (backend + frontend together)
```powershell
# Backend
cd backend
.\venv\Scripts\activate
uvicorn app.main:app --reload
# -> http://127.0.0.1:8000, using local SQLite (no DATABASE_URL needed for dev)

# Frontend (separate terminal)
cd frontend\fridge2table_app
flutter run
```
Or use `start_app.ps1` from the repo root, which starts both together and auto-runs `adb reverse` if it detects a physical device. See [Running Locally](#running-locally-development) below for the full physical-device/emulator/Wi-Fi address-resolution details — this is the most common source of "can't reach server" confusion for a new contributor.

## Current Phase Status

All 13 planned development phases are reported complete. **Caveat worth knowing:** the git history for this project is heavily squashed — the very first commit bundles Phases 1–10 together with no individually recoverable breakdown, and only Phases 10 ("Supabase cloud sync working") and 11 ("Supabase Auth, Google Sign In, real logout") are explicitly labeled in any commit message. Phases 12–13 aren't individually identified in commit history either. See [`docs/PROJECT_OVERVIEW.md`](docs/PROJECT_OVERVIEW.md) §4 for the full, honest commit-by-commit history instead of a reconstructed phase narrative. As of the most recent development work, the core loop (add ingredients → track expiry → match recipes → cook → sync) is functionally complete; see [`docs/AUDIT_FIXES.md`](docs/AUDIT_FIXES.md) for what's been fixed since that doc's §6 was written (push notifications now fire, server-side auth is enforced, most placeholder toggles are wired up) and what's deliberately still left as-is.

## Features

- **Pantry inventory** — add/edit/delete ingredients manually or via AI camera scan, categorized, quantity-tracked, with a per-card expiry urgency badge (red "Expired" / orange "Today" / yellow "Soon"); multi-select delete with "Select All" scoped to the current search/filter, a progress dialog while the bulk delete runs, and an automatic refresh + confirmation toast when it's done
- **Offline mode** — the pantry (view/add/edit/delete) *and* recipe matching (including the AI-pick fallback) both work with no network at all: a local `sqflite` mirror + pending-write queue for the pantry, syncing automatically on reconnect; a Dart port of the backend's own matching algorithm run against a bundled recipe dataset for recipes, so offline results genuinely match what the backend would return, not a degraded approximation. An offline banner and a per-card "Syncing…" indicator make the state visible rather than silent. The one online-only piece left is the OpenRouter LLM re-rank itself (no local LLM) — see [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) §7
- **AI ingredient recognition** — on-device MobileNetV2 classifier (68 classes — see [AI Model](#ai-model) below), no photo ever leaves the device; top-3 candidates shown for the user to pick from
- **Expiry monitoring** — items grouped by expired/today/soon/fresh, with a dedicated in-app Notifications screen and OS-level push notifications (one per ingredient per day, fired on Home load, inventory refresh, and app resume)
- **Recipe matching** — 302 recipes matched against your pantry by shared ingredients (every pantry item, not just fresh ones), filtered to genuinely relevant matches with a relaxed threshold for small pantries, plus expired/expiring-ingredient warning banners, and an optional LLM-assisted "best pick" via OpenRouter (deterministic fallback offline or if no API key is set)
- **Cooking flow** — Cook Now walks through recipe steps, then a unified quantity-adjustment screen (editable amounts + skip toggles, validated against real stock) deducts real quantities from the pantry and logs to cooked history
- **Statistics** — real food-saved/CO₂/points figures computed from actual cooked history, not placeholder numbers
- **Waste Control** — 4 tabs of hand-written guides: regrow-from-scraps, scrap recipes, composting methods, and storage tips
- **Diet & allergy preferences** — recipes flagged with allergy and diet-conflict warnings (all 9 diet types) before cooking, with a blocking confirmation dialog on Cook Now if there's a conflict
- **Accounts & Backup & Restore** — Supabase email/password and Google OAuth sign-in. Note: the pantry itself is already centrally hosted (see [Database Schema](#database-schema)) and available on any signed-in device automatically; "Backup & Restore" refers to a secondary backup mirror table with its own two-way conflict resolution, delete-tombstone handling, and connectivity-aware auto-backup toggles — see [`docs/DATA_PERSISTENCE.md`](docs/DATA_PERSISTENCE.md) for the precise, sometimes-surprising details of what does and doesn't sync
- **Standalone operation** — the app works fully unplugged after install; no USB/dev-machine tether required (see [Deployment](#deployment))

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart), Material widgets, `http` for REST calls |
| Backend | FastAPI (Python), Uvicorn |
| Database | Postgres (Supabase) in production, SQLite for local dev — selected via `DATABASE_URL` env var |
| Auth & backup | Supabase Auth (email/password + Google OAuth, verified server-side via JWT — see [API Endpoints](#api-endpoints)) and a separate Supabase Postgres table (`public.ingredients`, RLS-scoped per user) used purely as a backup mirror |
| AI ingredient recognition | MobileNetV2 transfer learning (TensorFlow → TFLite), runs fully on-device |
| AI recipe pick (optional) | OpenRouter (`meta-llama/llama-3.3-70b-instruct:free`) — app works fine without a key, falls back to the top match |
| Camera | `camera` + `image_picker` packages |
| Notifications | `flutter_local_notifications` — wired up: fires on Home load, inventory refresh, and app resume, capped at one per ingredient per day |
| Connectivity detection | `connectivity_plus` — drives the WiFi/mobile-data-aware auto-backup toggles, the offline banner, and reconnect-triggered pantry sync |
| Offline pantry cache | `sqflite` — `LocalPantryStore`, local mirror + pending-write queue behind `ApiService`, see [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) §7 |
| Recipe matching | Pre-indexed lookup over a hand-authored 302-recipe dataset (`backend/data/recipes_full.json`) |
| Backend hosting | Render (free tier) |
| Design | Figma (`naaKMnLlp5usmlvppkaiMY`) |

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for diagrams of how these pieces actually talk to each other, and [`docs/PROJECT_FLOW.md`](docs/PROJECT_FLOW.md) / [`docs/UI.md`](docs/UI.md) for the earlier narrative walkthrough and the design system respectively.

## Documentation

Everything beyond this README lives in [`docs/`](docs/README.md):

- [`PROJECT_OVERVIEW.md`](docs/PROJECT_OVERVIEW.md) — problem statement, full feature list, and an honest known-limitations section
- [`ARCHITECTURE.md`](docs/ARCHITECTURE.md) — system + data-flow diagrams, service-by-service reference
- [`DATABASE_SCHEMA.md`](docs/DATABASE_SCHEMA.md) — every table, every local-storage key, an ER diagram
- [`USE_CASES.md`](docs/USE_CASES.md) — 19 full use case write-ups with a use case diagram
- [`API_REFERENCE.md`](docs/API_REFERENCE.md) — every endpoint, with request/response examples
- [`CODEBASE_GUIDE.md`](docs/CODEBASE_GUIDE.md) — every source file, what it does, how it connects
- [`DATA_PERSISTENCE.md`](docs/DATA_PERSISTENCE.md) — what survives logout/reinstall/a second device, per data type
- [`AUDIT_FIXES.md`](docs/AUDIT_FIXES.md) — what was fixed after a documentation audit surfaced real gaps (disconnected notifications, dead code, misleading Privacy Policy/Cloud Sync wording, missing server-side auth, UI-only placeholders), and the one manual setup step still required

## Folder Structure

```
fridge2table/
├── backend/
│   ├── app/
│   │   ├── main.py              # FastAPI entry point, CORS
│   │   ├── database.py          # SQLAlchemy engine (Postgres in prod, SQLite in dev)
│   │   ├── config.py            # env-loaded settings (OPENROUTER_API_KEY, etc.)
│   │   ├── models.py            # SQLAlchemy ORM model (Ingredient -> "pantry_items" table)
│   │   ├── schemas.py           # Pydantic request/response schemas
│   │   ├── crud.py              # DB operations
│   │   └── routes/
│   │       └── inventory.py     # All API endpoints
│   ├── data/recipes_full.json   # Recipe dataset (source: scripts/generate_recipes.py)
│   ├── scripts/                 # generate_recipes.py, migrate_add_user_id.py, backfill_step_timers.py
│   └── venv/                    # Python virtual environment (not tracked)
│
├── frontend/fridge2table_app/
│   ├── tool/                    # pad_adaptive_icon.dart (regenerates the launcher icon's safe-zone-padded source)
│   └── lib/
│       ├── main.dart            # App root, auth listener, bottom-nav shell, reconnect-sync listener
│       ├── config/               # api_config.dart, supabase_config.dart
│       ├── constants/            # colors.dart
│       ├── data/                 # allergy_severities.dart
│       ├── models/               # Ingredient, RecipeDetail, CookedHistoryEntry, etc.
│       ├── screens/              # screens — see docs/UI.md
│       ├── services/             # api_service, auth_service, supabase_service, local_pantry_store,
│       │                          # local_recipe_matcher, ingredient_classifier_service, recipe_cooking_service, etc.
│       └── widgets/              # async_state.dart, offline_banner.dart
│
├── ai_models/
│   ├── scripts/                 # build_dataset_v*.py, train_v*.py, export_tflite.py
│   ├── model/                   # trained checkpoints (not tracked — regenerate via scripts)
│   └── dataset_v*/              # training images (not tracked — regenerate via build_dataset_v*.py)
│
├── docs/                        # Full documentation set — see docs/README.md for the index
├── render.yaml                  # Render Blueprint for backend deployment
├── start_app.ps1                # Local dev convenience script (starts backend + frontend together)
└── supabase_schema.sql          # Supabase `ingredients` sync-table schema + RLS policy
```

## Running Locally (Development)

### Backend

```powershell
cd backend
.\venv\Scripts\activate
uvicorn app.main:app --reload
```

Runs on `http://127.0.0.1:8000` by default (docs at `/docs`), using the local SQLite file. No `DATABASE_URL` env var is needed for local dev.

### Frontend

```powershell
cd frontend\fridge2table_app
flutter run
```

`lib/config/api_config.dart` auto-detects at startup whether it's running on the Android emulator or real hardware and picks the right backend address automatically:

| Target | Backend address |
|---|---|
| Android emulator | `http://10.0.2.2:8000` (automatic) |
| Real phone, USB | `http://localhost:8000` via `adb reverse tcp:8000 tcp:8000` (see checklist below) |
| Real phone, Wi-Fi only | `flutter run --dart-define=API_BASE_URL=http://<your-LAN-IP>:8000` |
| Release build (`flutter build apk --release`) | The deployed Render backend, automatically — see [Deployment](#deployment) |

`start_app.ps1` starts backend + frontend together for local dev, and auto-runs `adb reverse` if it detects a physical device connected.

**Physical device via USB checklist** (the most common "can't reach server" cause is skipping step 2):
1. `adb devices` — confirm your phone shows up as `device` (not `unauthorized`)
2. `adb reverse tcp:8000 tcp:8000` — run this every time you reconnect the phone or restart adb
3. `flutter run` (or use `start_app.ps1`, which does step 2 for you)

## Deployment

The backend is deployed to **Render** (free tier) with a **Supabase Postgres** database — not SQLite, because Render's free tier wipes the local filesystem on every idle-restart (every ~15 minutes of inactivity), which would otherwise mean losing all pantry data constantly.

- Backend: `render.yaml` at the repo root defines the Render Blueprint (`rootDir: backend`, `DATABASE_URL` and `OPENROUTER_API_KEY` set as Render env vars, `DATABASE_URL` pointed at Supabase's **Session Pooler** connection string). Request-JWT verification (see below) needs no Render env var at all — it verifies against Supabase's public JWKS endpoint, not a shared secret.
- Frontend: release builds (`flutter build apk --release`) automatically point at the deployed backend URL (`ApiConfig._productionUrl` in `lib/config/api_config.dart`) — no manual config needed. Local dev (`flutter run`) is unaffected and keeps using the emulator/USB/LAN-IP logic above.

To build an installable release APK:
```powershell
cd frontend\fridge2table_app
flutter build apk --release
```
Output: `build\app\outputs\flutter-apk\app-release.apk`. Install via `adb install build\app\outputs\flutter-apk\app-release.apk` (phone connected via USB for this one install step only), or copy the APK to the phone and install manually. After install, the app works fully unplugged — no USB, no dev machine, no `adb reverse`.

## AI Model

Current model: **v4**, 68 ingredient classes, **85.59% test accuracy**. Trained with MobileNetV2 transfer learning (two-phase: frozen-base head training, then fine-tuning the last 30 base layers), keeping whichever phase scores higher on a held-out test set.

- Training data: MIT-licensed `marcusklasson/GroceryStoreDataset` (produce + dairy) and MIT-licensed Fruits-360 (`Horea94/Fruit-Images-Dataset`), both regenerated via `ai_models/scripts/build_dataset_v4.py` — not committed to the repo (large, regenerable).
- To retrain: `ai_models/scripts/build_dataset_v4.py` then `train_v4.py`, both run from `ai_models/` with the venv activated.
- Deployed model lives in `frontend/fridge2table_app/assets/models/` (`ingredient_classifier_v4.tflite`, `class_names_v4.json`) — these **are** tracked, since the app ships them directly.
- Meat/protein classes were investigated but not added — no MIT/CC0-licensed dataset for raw meat *species* classification (chicken vs. beef vs. pork) was found; what exists is mostly freshness/spoilage binary classifiers.
- Only the current (v4) model's accuracy is recorded anywhere — v1/v2/v3's figures were never saved to a log file. See `docs/PROJECT_OVERVIEW.md` for the version history that *is* recoverable (class counts, dataset sources, a documented augmentation bug and its fix).

## API Endpoints

All defined in `backend/app/routes/inventory.py`. Every request (except the health check) must carry a valid `Authorization: Bearer <supabase-jwt>` header — the backend verifies its ES256 signature against Supabase's public JWKS endpoint and derives the user id from the token's `sub` claim (`backend/app/auth.py`); any `user_id` query parameter a client sends is ignored entirely. Requests without a valid token get `401`. See [`docs/API_REFERENCE.md`](docs/API_REFERENCE.md) for every endpoint's full request/response schema with worked examples, and [`docs/AUDIT_FIXES.md`](docs/AUDIT_FIXES.md) for the JWT verification history.

| Method | Path | Description |
|---|---|---|
| GET | `/` | Health check |
| GET | `/inventory` | List all ingredients for `user_id` |
| POST | `/ingredient` | Add an ingredient |
| PUT | `/ingredient/{id}` | Edit an ingredient |
| DELETE | `/ingredient/{id}` | Delete an ingredient (frontend also mirrors the delete to Supabase's cloud sync table, with a tombstone fallback if that mirror call fails) |
| GET | `/expiry-status` | Ingredients tagged `expired` / `today` / `soon` / `fresh` / `unknown` |
| GET | `/recipes` | Up to 25 recipe matches (name, `match_score`, `matched_ingredients`, `expired_ingredients`, `expiring_ingredients`), filtered to ≥20% match score and a shared-ingredient-count minimum (relaxed to 1 for pantries under 5 items) |
| GET | `/ai-recommendation` | LLM-picked best recipe from the top matches (falls back to the top match if `OPENROUTER_API_KEY` is unset) |

## Database Schema

The backend's own table is `pantry_items` (`backend/app/models.py`) — **not** named `ingredients`, deliberately, because that name collides with Supabase's separate cloud-sync table of the same name (see `docs/DATABASE_SCHEMA.md` for the production bug this caused and how it was fixed).

| Column | Type | Notes |
|---|---|---|
| id | Integer | Primary key |
| name | String | Required |
| quantity | Float | Required |
| unit | String | Required |
| expiry_date | String | `YYYY-MM-DD`, optional |
| category | String | Optional |
| location | String | Optional |
| user_id | String | Supabase user id; nullable only for legacy pre-auth rows, which are treated as orphaned |
| updated_at | DateTime | Auto-set on insert/update; used for cloud-sync conflict resolution |

A structurally similar but **separate** table, `public.ingredients`, exists in the same Supabase project purely as the cloud-sync mirror (see `supabase_schema.sql` and `docs/DATABASE_SCHEMA.md` for its exact schema, RLS policy, and the composite `(id, user_id)` uniqueness constraint it uses).

## Known Issues

**`ModuleNotFoundError: No module named 'app'`**
Run Uvicorn from `backend/`, not from `backend/app/`.

**Recipe names occasionally feel generic**
The recipe dataset is hand-authored (`backend/scripts/generate_recipes.py`), not scraped — if a specific pantry ingredient has no good match, that's a dataset-coverage gap rather than a bug. See `docs/ARCHITECTURE.md` for how matching works.

**Render free-tier cold starts**
The deployed backend sleeps after ~15 minutes of inactivity and takes about a minute to wake up on the next request — expected free-tier behavior, not a bug.

**A few Settings toggles are still UI-only**
Settings' "Expiry Alerts" toggle and the "Language: English" row remain local UI state with no backing behavior. Push Notifications, Recipe Suggestions, Dark Mode (shows "coming soon"), Forgot Password, Help & Support, the Backup & Restore toggles, and the Cooking Mode timer are all real now — see [`docs/AUDIT_FIXES.md`](docs/AUDIT_FIXES.md) for what changed.

**Backup/Restore duplication bug (fixed)**
Offline mode's rewrite of `ApiService.addIngredient()` briefly broke Backup & Restore's idempotency — every cloud-only row got a new id on every sync instead of reusing the one it already had, so repeated Backup/Restore taps kept duplicating the pantry (a real case went 15→36→51 items across one Backup then one Restore). Root-caused and fixed, confirmed stable across four consecutive real Backup/Restore taps with logged before/after row counts — see [`docs/PROJECT_OVERVIEW.md`](docs/PROJECT_OVERVIEW.md) §6.

**Diet Preferences back-stack bug (fixed)**
Found during an app-wide back-button audit (all 25 screens checked, this was the one real bug): finishing Diet Preferences always replaced itself with a fresh `MainScreen` regardless of context, which for onboarding left the sign-up screens still reachable via system back after a user was already signed in, and for editing from Profile stacked a *second* `MainScreen` instead of returning to the existing one. Fixed with a required `isOnboarding` flag; editing also gained a real back/cancel button it didn't have before. See [`docs/CODEBASE_GUIDE.md`](docs/CODEBASE_GUIDE.md)'s `diet_preferences_screen.dart` entry.

**Offline recipe matching, cross-verified**
`test/local_recipe_matcher_test.dart` (the first automated test in the repo) confirms the offline matcher returns byte-identical results to the backend's own algorithm — not just similar — for real test pantries, including expiry annotations. That comparison also caught and fixed a non-deterministic tie-break at the 25-result cutoff, present in the *original* backend algorithm too (now fixed on both sides).

**App icon previously clipped on circular-mask launchers**
Android adaptive icons are masked to a circle on many launchers, which only guarantees the inner ~66% of the icon canvas stays visible — the source logo's content reached ~80%, so it was genuinely getting clipped. Fixed via `tool/pad_adaptive_icon.dart` (regenerates a properly safe-zone-padded foreground layer) — see [`docs/UI.md`](docs/UI.md)'s "App Icon / Logo Safe Zone" section before changing the logo again.

**Cooking timer had almost no data**
The countdown UI was always correct; only 4/302 recipes had any `step_timers` data for it to show. `backend/scripts/backfill_step_timers.py` mines each recipe's own step text for explicit durations, taking coverage to 93/302.
