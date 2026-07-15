# Project Flow

How data and the user move through Fridge2Table, as currently built.

## System Architecture

```
┌─────────────────────────────┐
│         Flutter App          │
│  screens/ → services/ → models/ │
└──────────────┬───────────────┘
               │ HTTP (REST, JSON)
               │ ApiService.baseUrl
┌──────────────▼───────────────┐
│        FastAPI Backend        │
│  routes/inventory.py → crud.py │
└──────────────┬───────────────┘
               │ SQLAlchemy ORM
┌──────────────▼───────────────┐
│         SQLite DB             │
│      fridge2table.db          │
└───────────────────────────────┘
```

Every screen talks to the backend exclusively through `lib/services/api_service.dart` — no screen calls `http` directly. This is the one file to check/update whenever an endpoint changes.

## Screen Map (as built today)

```
MainScreen (bottom nav, 2 tabs)
├── Tab 0: InventoryScreen
│   ├── [+ FAB] ─────────────► AddIngredientScreen ─── save ───► back to Inventory (refreshes)
│   ├── [camera icon] ───────► AiCameraScreen
│   │                              │ capture
│   │                              ▼
│   │                          AddIngredientScreen (photo thumbnail pre-filled)
│   │                              │ save
│   │                              ▼
│   │                          back to AiCameraScreen → pops itself → back to Inventory (refreshes)
│   └── [calendar icon] ─────► ExpiryMonitorScreen ─── back ───► Inventory
│
└── Tab 1: RecipeScreen
```

`home_screen.dart` and `settings_screen.dart` exist as empty stub files — not wired into navigation yet. The Figma design plans a 5-tab nav (Home / Pantry / Scan / Recipes / Profile) that hasn't been built; the app currently uses the original 2-tab nav.

## Key Flows

### Add ingredient (manual)
`InventoryScreen` FAB → `AddIngredientScreen` → `ApiService.addIngredient()` → `POST /ingredient` → `Navigator.pop(context, true)` → Inventory sees `true` and refetches via `ApiService.getInventory()`.

### Add ingredient (camera)
`InventoryScreen` camera icon → `AiCameraScreen` (live preview via the `camera` package) → capture → `Navigator.push` to `AddIngredientScreen` with `capturedImagePath` (shown as a thumbnail, **not persisted** — the `Ingredient` model has no `image_path` column) → user manually types name/quantity/unit (no AI model exists yet, so this is a deliberate manual-confirm step, not the full "AI Detection" screen from Figma) → save → `AiCameraScreen` pops itself too, propagating the result back to `Inventory` so the list refreshes.

This double-pop matters: an earlier version used `Navigator.pushReplacement`, which resolves the *original* caller's navigation future the instant the replacement happens — before the user even saves — so the list would never refresh after a scan. Current implementation uses `Navigator.push` + a conditional pop instead.

### Recipe matching
On startup, `backend/app/routes/inventory.py` loads `recipes_index.json` into memory (built once from `cuisine_data.csv` → `recipes.json` → `recipes_index.json`, see README). `GET /recipes` reads the user's current ingredient names, looks each one up in the pre-built keyword index to get candidate recipe IDs, scores each candidate as `matched_ingredients / total_ingredients * 100`, and returns the top 5. This avoids scanning all ~40k rows per request — the earlier row-by-row approach was too slow on the emulator.

### Expiry monitoring
`GET /expiry-status` re-derives a `status` label per ingredient on every call by comparing `expiry_date` to today's date server-side — the status is not stored, just computed on read. `ExpiryMonitorScreen` groups the response by status and only renders non-empty groups.

### Push notifications (Phase 9, in progress)
`NotificationService.checkAndNotify()` calls `GET /expiry-status` and fires one local notification per ingredient whose status is `expired`, `today`, or `soon`. The Android notification `id` used is the ingredient's own database `id` — calling `checkAndNotify()` again **replaces** the existing notification for that ingredient rather than stacking a duplicate, which is what satisfies "no spam per ingredient" without needing extra dedup bookkeeping.

## Data Flow Notes

- `Ingredient` (Dart model) ↔ `IngredientCreate`/`IngredientResponse` (Pydantic) ↔ `Ingredient` (SQLAlchemy) all mirror the same 5 fields: `name`, `quantity`, `unit`, `expiry_date`, `category`. Keep all three in sync when adding a field.
- Recipe results carry `name`, `match_score`, `matched_ingredients` — `name` is a cuisine category from the dataset (e.g. "french"), not a dish name.
- Expiry-status results carry the same shape as inventory items plus a computed `status` field.

## Real-Device vs Emulator

The single biggest gotcha when switching between the emulator and a physical phone is `ApiService.baseUrl`:

| Target | baseUrl |
|---|---|
| Android emulator | `http://10.0.2.2:8000` |
| Real phone (same Wi-Fi as the laptop) | `http://<laptop-LAN-IP>:8000` |

Forgetting to flip this is the most likely cause of "Inventory/Recipes won't load" when moving between the two.
