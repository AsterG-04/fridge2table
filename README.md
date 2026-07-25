# Fridge2Table (F2T)

An AI-powered mobile app that helps households reduce food waste through smart pantry inventory management, expiry tracking, camera-based ingredient recognition, and recipe recommendations built from what's actually in stock.

Final Year University Project (FYP). Timeline: 2026-02-09 → 2026-08-07. All 13 planned development phases are complete.

## Features

- **Pantry inventory** — add/edit/delete ingredients manually or via AI camera scan, categorized and quantity-tracked
- **AI ingredient recognition** — on-device MobileNetV2 classifier (68 classes — see [AI Model](#ai-model) below), no photo ever leaves the device
- **Expiry monitoring** — items grouped by expired/today/soon/fresh, with local push notifications
- **Recipe matching** — 121 recipes matched against your pantry by shared ingredients, filtered to genuinely relevant matches (minimum match score + minimum shared-ingredient count), with an optional LLM-assisted "best pick" via OpenRouter
- **Cooking flow** — Cook Now walks through recipe steps, then deducts real quantities from the pantry (by measurement or by estimate) and logs to cooked history
- **Statistics** — real food-saved/CO₂/points figures computed from actual cooked history, not placeholder numbers
- **Waste Control** — hand-written regrow-from-scraps guides, scrap recipes, and compost tips
- **Diet & allergy preferences** — recipes flagged with allergy and diet-conflict warnings before cooking
- **Accounts & cloud sync** — Supabase email/password and Google OAuth sign-in, with two-way pantry sync across devices
- **Standalone operation** — the app works fully unplugged after install; no USB/dev-machine tether required (see [Deployment](#deployment))

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart), Material widgets, `http` for REST calls |
| Backend | FastAPI (Python), Uvicorn |
| Database | Postgres (Supabase) in production, SQLite for local dev — selected via `DATABASE_URL` env var |
| Auth & cloud sync | Supabase Auth (email/password + Google OAuth) and Supabase Postgres (`ingredients` table, RLS-scoped per user) |
| AI ingredient recognition | MobileNetV2 transfer learning (TensorFlow → TFLite), runs fully on-device |
| AI recipe pick (optional) | OpenRouter (`meta-llama/llama-3.3-70b-instruct:free`) — app works fine without a key, falls back to the top match |
| Camera | `camera` + `image_picker` packages |
| Notifications | `flutter_local_notifications` |
| Recipe matching | Pre-indexed lookup over a hand-authored 121-recipe dataset (`backend/data/recipes_full.json`) |
| Backend hosting | Render (free tier) |
| Design | Figma (`naaKMnLlp5usmlvppkaiMY`) |

See [docs/PROJECT_FLOW.md](docs/PROJECT_FLOW.md) for how the pieces fit together and [docs/UI.md](docs/UI.md) for the design system.

## Folder Structure

```
fridge2table/
├── backend/
│   ├── app/
│   │   ├── main.py              # FastAPI entry point, CORS
│   │   ├── database.py          # SQLAlchemy engine (Postgres in prod, SQLite in dev)
│   │   ├── config.py            # env-loaded settings (OPENROUTER_API_KEY, etc.)
│   │   ├── models.py            # SQLAlchemy ORM models
│   │   ├── schemas.py           # Pydantic request/response schemas
│   │   ├── crud.py              # DB operations
│   │   └── routes/
│   │       └── inventory.py     # All API endpoints
│   ├── data/recipes_full.json   # Recipe dataset (source: scripts/generate_recipes.py)
│   ├── scripts/                 # generate_recipes.py, migrate_add_user_id.py
│   └── venv/                    # Python virtual environment (not tracked)
│
├── frontend/fridge2table_app/
│   └── lib/
│       ├── main.dart            # App root, auth listener, bottom-nav shell
│       ├── config/               # api_config.dart, supabase_config.dart
│       ├── constants/            # colors.dart
│       ├── models/               # Ingredient, RecipeDetail, CookedHistoryEntry, etc.
│       ├── screens/              # 25 screens — see docs/UI.md
│       └── services/             # api_service, auth_service, supabase_service,
│                                  # ingredient_classifier_service, recipe_cooking_service, etc.
│
├── ai_models/
│   ├── scripts/                 # build_dataset_v*.py, train_v*.py, export_tflite.py
│   ├── model/                   # trained checkpoints (not tracked — regenerate via scripts)
│   └── dataset_v*/              # training images (not tracked — regenerate via build_dataset_v*.py)
│
├── docs/                        # PROJECT_FLOW.md, UI.md
├── render.yaml                  # Render Blueprint for backend deployment
├── start_app.ps1                # Local dev convenience script (starts backend + frontend together)
└── supabase_schema.sql          # Supabase `ingredients` table + RLS policy
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

- Backend: `render.yaml` at the repo root defines the Render Blueprint (`rootDir: backend`, `DATABASE_URL` and `OPENROUTER_API_KEY` set as Render env vars, `DATABASE_URL` pointed at Supabase's **Session Pooler** connection string).
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

## API Endpoints

All defined in `backend/app/routes/inventory.py`. Every request is scoped by a `user_id` query param (the signed-in Supabase user's id).

| Method | Path | Description |
|---|---|---|
| GET | `/` | Health check |
| GET | `/inventory` | List all ingredients for `user_id` |
| POST | `/ingredient` | Add an ingredient |
| PUT | `/ingredient/{id}` | Edit an ingredient |
| DELETE | `/ingredient/{id}` | Delete an ingredient (frontend also deletes the matching Supabase cloud row) |
| GET | `/expiry-status` | Ingredients tagged `expired` / `today` / `soon` / `fresh` / `unknown` |
| GET | `/recipes` | Up to 25 recipe matches (name, match_score, matched_ingredients), filtered to ≥20% match score and ≥2 shared ingredients |
| GET | `/ai-recommendation` | LLM-picked best recipe from the top matches (falls back to the top match if `OPENROUTER_API_KEY` is unset) |

## Database Schema

`ingredients` table (`backend/app/models.py`):

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

The same shape (minus `user_id`/`updated_at`) is mirrored in Supabase's `ingredients` table for cloud sync — see `supabase_schema.sql`.

## Known Issues

**`ModuleNotFoundError: No module named 'app'`**
Run Uvicorn from `backend/`, not from `backend/app/`.

**Recipe names occasionally feel generic**
The recipe dataset is hand-authored (`backend/scripts/generate_recipes.py`), not scraped — if a specific pantry ingredient has no good match, that's a dataset-coverage gap rather than a bug. See `docs/PROJECT_FLOW.md` for how matching works.

**Render free-tier cold starts**
The deployed backend sleeps after ~15 minutes of inactivity and takes about a minute to wake up on the next request — expected free-tier behavior, not a bug.
