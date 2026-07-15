# Fridge2Table (F2T)

An AI-powered mobile app that helps households reduce food waste through smart pantry inventory management, expiry tracking, camera-based ingredient capture, and recipe recommendations built from what's actually in stock.

Final Year University Project (FYP). Timeline: 2026-02-09 → 2026-08-07.

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart), Material widgets, `http` for REST calls |
| Backend | FastAPI (Python), Uvicorn |
| Database | SQLite via SQLAlchemy |
| Camera | `camera` + `image_picker` packages |
| Notifications | `flutter_local_notifications` |
| Recipe matching | Pre-indexed JSON lookup over a 39,775-row cuisine dataset |
| Design | Figma (`naaKMnLlp5usmlvppkaiMY`) |

See [docs/PROJECT_FLOW.md](docs/PROJECT_FLOW.md) for how the pieces fit together and [docs/UI.md](docs/UI.md) for the design system.

## Folder Structure

```
E:\fridge2table\
├── backend\
│   ├── app\
│   │   ├── main.py              # FastAPI entry point
│   │   ├── database.py          # SQLAlchemy engine + session
│   │   ├── models.py            # SQLAlchemy ORM models
│   │   ├── schemas.py           # Pydantic request/response schemas
│   │   ├── crud.py              # DB operations
│   │   └── routes\
│   │       └── inventory.py     # All API endpoints
│   ├── cuisine_data.csv         # Raw recipe dataset
│   ├── recipes.json             # Flattened recipe list
│   ├── recipes_index.json       # Pre-built keyword → recipe index
│   ├── fridge2table.db          # SQLite database file
│   └── venv\                    # Python virtual environment
│
├── frontend\
│   └── fridge2table_app\
│       └── lib\
│           ├── main.dart
│           ├── constants\colors.dart
│           ├── models\ingredient.dart, recipe.dart
│           ├── screens\         # inventory, recipe, ai_camera, add_ingredient, expiry_monitor
│           └── services\        # api_service.dart, notification_service.dart
│
└── docs\                        # This documentation
```

## Running the Project

### Backend

```powershell
cd E:\fridge2table\backend
.\venv\Scripts\activate
uvicorn app.main:app --reload
```

Runs on `http://127.0.0.1:8000` by default (docs at `/docs`). To test from a **real device** instead of the emulator, the backend needs to accept connections from other machines on the network:

```powershell
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend

```powershell
cd E:\fridge2table\frontend\fridge2table_app
flutter run
```

**Important — `baseUrl` in `lib/services/api_service.dart` must match how you're testing:**
- Android **emulator** → `http://10.0.2.2:8000` (special alias to the host machine's localhost)
- Real **physical device** → your laptop's actual LAN IP (e.g. `http://192.168.1.116:8000`), with both devices on the same Wi-Fi, backend bound to `0.0.0.0`, and Windows Firewall allowing inbound TCP on port 8000

Both the backend and frontend must be running at the same time.

## API Endpoints

All defined in `backend/app/routes/inventory.py`.

| Method | Path | Description |
|---|---|---|
| GET | `/` | Health check |
| GET | `/inventory` | List all ingredients |
| POST | `/ingredient` | Add an ingredient |
| PUT | `/ingredient/{id}` | Edit an ingredient |
| DELETE | `/ingredient/{id}` | Delete an ingredient |
| GET | `/recipes` | Top 5 recipe matches for current inventory (name, match_score, matched_ingredients) |
| GET | `/expiry-status` | All ingredients tagged with expiry status: `expired` / `today` / `soon` / `fresh` / `unknown` |

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

Note: this is the actual current schema — it's simpler than some earlier planning docs assumed. There is no `location`, `notes`, `purchase_date`, or `image_path` column yet.

## Development Phases

| Phase | Description | Status |
|---|---|---|
| 1 | Backend CRUD | ✅ Done |
| 2 | Flutter project setup | ✅ Done |
| 3 | Flutter folder structure | ✅ Done |
| 4 | Flutter ↔ FastAPI integration | ✅ Done |
| 5 | Recipe engine (pre-indexed JSON) | ✅ Done |
| 6 | Camera integration (capture → manual confirm) | ✅ Done |
| 7 | AI detection (MobileNetV2 + LLM) | ⬜ Pending — no dataset chosen yet |
| 8 | Expiry monitoring | ✅ Done |
| 9 | Push notifications | 🔶 In progress |
| 10 | Cloud sync (PostgreSQL) | ⬜ Pending |
| 11 | Authentication | ⬜ Pending |
| 12 | Testing | ⬜ Pending |
| 13 | Deployment | ⬜ Pending |

## Known Issues & Fixes

**`ModuleNotFoundError: No module named 'app'`**
Run Uvicorn from `E:\fridge2table\backend`, not from `app\`.

**Recipe endpoint slow / ANR on emulator**
Fixed by pre-indexing recipes by ingredient keyword at startup instead of scanning all ~40k rows per request (see `recipes_index.json`).

**Recipe names are cuisine categories, not dish names**
`cuisine_data.csv`'s `cuisine` column is a category (e.g. "french", "spanish"), not a per-dish name. This is a dataset limitation, not a bug — worth remembering wherever recipe names are surfaced in the UI.

**Camera capture silently does nothing on the Android emulator**
The emulator's virtual camera pipeline (CameraX/CXCP) can take noticeably longer to finish starting its capture session than `controller.initialize()` completing would suggest — a tap right after opening the camera screen can silently no-op. This is an emulator artifact; real camera hardware is faster and more reliable.
