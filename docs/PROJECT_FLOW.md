# Project Flow

How data and the user move through Fridge2Table, as currently built. For color/typography/design tokens, see [UI.md](UI.md).

## System Architecture

```
┌───────────────────────────────┐        ┌───────────────────────────┐
│          Flutter App           │        │      Supabase (cloud)      │
│  screens/ → services/ → models/│───────▶│  Auth (email + Google)     │
│                                 │        │  Postgres `ingredients`    │
│  on-device MobileNetV2 (TFLite)│        │  table (RLS, per-user)     │
└───────────────┬─────────────────┘        └───────────────────────────┘
                │ HTTP (REST, JSON)
                │ ApiConfig.baseUrl
┌───────────────▼─────────────────┐
│         FastAPI Backend          │
│  routes/inventory.py → crud.py   │
│  (Render, free tier)             │
└───────────────┬─────────────────┘
                │ SQLAlchemy ORM
┌───────────────▼─────────────────┐
│  Postgres (prod, via Supabase)   │
│  SQLite (local dev)              │
│  selected via DATABASE_URL       │
└───────────────────────────────────┘
```

Every screen talks to the local/deployed backend exclusively through `lib/services/api_service.dart` — no screen calls `http` directly. Cloud sync (a separate concern from the pantry backend) goes through `lib/services/supabase_service.dart`. This is the pair of files to check whenever an endpoint or sync behavior changes.

**Why two databases talking to each other indirectly, not one:** the FastAPI backend is the pantry's source of truth (it's what the app actually reads/writes for day-to-day use), while Supabase's `ingredients` table is a sync/backup layer the frontend pushes to and pulls from independently. They're kept consistent by the frontend, not by the backend — `ApiService.deleteIngredient()` deletes from both; `SupabaseService.resolveConflicts()` does a two-way merge by `updated_at`.

## Auth & Startup Flow

```
main() → ApiConfig.initialize() → SupabaseService.initialize() → runApp() → NotificationService.initialize()
                                                                      │      (unawaited — fired after runApp(),
                     has a persisted Supabase session? ──────────────┤       not before it; nothing on the
                            │ yes                                    │ no    first screen needs it)
                            ▼                                        ▼
                       MainScreen                              SplashScreen (onboarding)
                                                                       │ Get Started
                                                                       ▼
                                                                  SignInScreen ⇄ CreateAccountScreen
                                                                       │ success
                                                                       ▼
                                                          DietPreferencesScreen (first-time only)
                                                                       │
                                                                       ▼
                                                                  MainScreen
```

Only `ApiConfig`/`SupabaseService` genuinely block the first frame — `Fridge2TableApp.build()` synchronously checks `Supabase.instance.client.auth.currentSession` to decide `MainScreen` vs. `SplashScreen`, so Supabase has to be ready by then. Notification-channel setup doesn't gate anything the user sees first, so it moved off that blocking chain (previously all three were sequentially `await`ed before `runApp()`, adding an extra platform-channel round trip to every cold start for no benefit).

`main.dart`'s root-level `onAuthStateChange` listener is what catches sign-in completing *asynchronously* — Google OAuth (browser redirect lands later) and email-confirmation links (opened from the inbox, possibly after the app was backgrounded) both fire this way, regardless of which screen originally triggered them. It branches on the session's `provider`:

- **OAuth (Google):** shows a "Continue as [email]?" confirmation, distinguishing new vs. returning accounts by comparing `createdAt`/`lastSignInAt` — Supabase's OAuth exchange already finds-or-creates the account server-side before this event ever fires, so this is a post-hoc confirmation, not a true pre-creation check. Declining signs back out.
- **Email link (not OAuth):** always signs back out and routes to `SignInScreen` — confirming an email shouldn't silently log the user in.
- **Stream errors** (e.g. an expired/already-used confirmation link) show a "Couldn't confirm email" dialog instead of silently doing nothing.

Password sign-in (`SignInScreen`/`CreateAccountScreen`) awaits its own result directly and sets `SupabaseService.suppressRootAuthListener` so it doesn't race the root listener for the same event.

## Screen Map (MainScreen bottom nav)

```
MainScreen (4-tab bottom nav + raised floating Scan button)
├── Tab 0: HomeScreen
│   ├── AI Insight banner ──────────► RecipeScreen (pre-filtered by the most urgent expiring ingredient)
│   ├── Quick actions ──────────────► AiCameraScreen / AddIngredientScreen / WasteControlScreen
│   └── Expiry alert ───────────────► ExpiryMonitorScreen
│
├── Tab 1: InventoryScreen ("Pantry")
│   ├── [+ FAB] ─────────────────────► AddIngredientScreen
│   ├── [camera icon] ───────────────► AiCameraScreen
│   └── [calendar icon] ─────────────► ExpiryMonitorScreen
│
├── Tab 2: RecipeScreen
│   └── recipe card ─────────────────► RecipeDetailScreen ── Cook Now ──► see Cooking Flow below
│
├── Tab 3: ProfileScreen
│   ├── Statistics ──────────────────► StatisticsScreen
│   ├── Waste Control ───────────────► WasteControlScreen
│   ├── Cloud Sync ──────────────────► CloudSyncScreen
│   ├── Settings ────────────────────► SettingsScreen ── Terms/Privacy ──► TermsScreen / PrivacyScreen
│   └── Diet Preferences (Edit) ─────► DietPreferencesScreen
│
└── [Scan FAB, any tab] ──────────────► AiCameraScreen
```

`AiCameraScreen` capture → on-device classification → `AddIngredientScreen` (name/category pre-filled from the top prediction, user confirms/edits) → save → pops back through the chain, refreshing whichever list triggered it.

## Cooking Flow

```
RecipeDetailScreen ── Cook Now ──► CookingModeScreen (step-by-step instructions)
                                          │ Finish Cooking
                                          ▼
                                   CookingConfirmScreen (by measurement / by estimate)
                              ┌───────────┴───────────┐
                       by measurement           by estimate
                              │                       ▼
                              │              ExcludeIngredientsScreen (pick what to skip)
                              └───────────┬───────────┘
                                          ▼
                                RecipeCookingService.deduct()
                          (real pantry quantities subtracted; item
                           deleted from both local + Supabase if it
                           hits zero, updated otherwise)
                                          ▼
                                RecipeCompleteScreen
                        (records to CookedHistoryStore — feeds
                         Statistics' Food Saved / Recipes Cooked /
                         Most Used Categories, and Profile's
                         Eco Score / Badges / Rescued)
```

`CookedHistoryStore` (`lib/models/cooked_history_entry.dart`) is a single in-memory + `SharedPreferences`-backed store, scoped per-user via `UserScope`. Both `StatisticsScreen` and `ProfileScreen` read from it independently on their own `initState()` — there's no shared listener/stream between them, so each screen re-reads fresh whenever it's navigated to.

## Recipe Matching

On startup, `backend/app/routes/inventory.py` loads `backend/data/recipes_full.json` (302 hand-authored recipes, source: `backend/scripts/generate_recipes.py`) into memory and builds a keyword index over normalized ingredient names. `GET /recipes`:

1. Normalizes the user's pantry ingredient names (lowercase, de-pluralize, and map known spelling variants to one canonical form — e.g. `sweetpotato`→`sweet potato`, `capsicum`→`bell pepper` — since the AI classifier's class names don't always match the recipe dataset's spelling)
2. Looks each one up in the pre-built index to get candidate recipe ids (exact-string matching, not fuzzy/substring — "pea" cannot match inside "peanut")
3. Scores each candidate as `matched_ingredients / total_recipe_ingredients * 100`
4. Filters out anything below a 20% match score **or** fewer than 2 actually-shared ingredients (a single shared generic ingredient like garlic inflating a small recipe's score is exactly what this second condition catches)
5. Returns up to 25, sorted by score

`GET /ai-recommendation` takes the top 10 of those and, if `OPENROUTER_API_KEY` is set, asks an LLM to pick the single best one; otherwise it just returns the top match (`source: "fallback"` either way it fails).

## Expiry Monitoring & Notifications

`GET /expiry-status` re-derives a `status` label per ingredient on every call by comparing `expiry_date` to today's date server-side — the status is not stored, just computed on read. `ExpiryMonitorScreen` groups the response by status and only renders non-empty groups. `NotificationService.checkAndNotify()` calls the same endpoint and fires one local notification per ingredient whose status is `expired`, `today`, or `soon`, using the ingredient's own database `id` as the Android notification id — calling it again **replaces** the existing notification rather than stacking a duplicate.

Home screen's "AI Insight" banner uses the same expiry data: it picks the single most urgent expiring item, cross-references it against the currently-matched recipes to get a real rescue-recipe count, and shows nothing (not a stale placeholder) while that data is still loading.

## Offline Mode

The Pantry screen (view/add/edit/delete) and recipe matching (including the AI-pick fallback) both work with no network at all, sitting behind `ApiService`'s existing methods — no screen needed to change to gain either. Pantry: a local sqflite mirror (`LocalPantryStore`). Recipes: `LocalRecipeMatcher`, a Dart port of the backend's own matching algorithm run against a bundled copy of the recipe dataset, kept rule-for-rule identical so offline results genuinely match what the backend would return. An `OfflineBanner` shows above whichever tab is active whenever there's no connectivity at all; `RecipeScreen` additionally shows a small "showing matches from your last synced pantry" note; a `MainScreen`-level `connectivity_plus` listener pushes any queued offline pantry edits the moment the connection returns. The one thing still online-only is the OpenRouter LLM re-rank itself (falls back to the same deterministic top-match logic used when no API key is set — no local LLM to substitute). AI Camera scanning was already 100% on-device so needed no changes. Full mechanism: `docs/ARCHITECTURE.md` §7.

## Real-Device vs Emulator vs Release Build

`ApiConfig.initialize()` (`lib/config/api_config.dart`) picks the backend address once at startup, in priority order:

1. `--dart-define=API_BASE_URL=...` override, if passed (dev, testing a release build against a local backend)
2. Release build (`kReleaseMode`) → the deployed Render backend, always
3. Web / non-Android → `http://localhost:8000`
4. Android emulator → `http://10.0.2.2:8000`
5. Android physical device (`flutter run`, debug) → `http://localhost:8000` via `adb reverse tcp:8000 tcp:8000`

Forgetting `adb reverse` on a physical device during development is the most common cause of "Inventory/Recipes won't load" — `api_service.dart` detects this specific case (`ApiConfig.usingAdbReverse`) and surfaces the exact fix in the error message instead of a generic network error.
