# Fridge2Table — Data Persistence: What Survives What

A direct, honest answer for each data type: where it lives, whether it survives logout/login, whether it survives an uninstall/reinstall, whether it reaches a second device, and what actually triggers a sync. Verified against the current code, not assumed from feature descriptions elsewhere.

**Read this first — the single most important, least obvious fact in this whole document:** in the deployed, standalone app (what a real user installs — a release APK), the pantry backend is **never actually local to the phone**. `ApiService` makes a real network call to `https://fridge2table-backend.onrender.com` for every single pantry read/write; there is no on-device pantry database at all in production. This directly contradicts the current `Privacy Policy` screen's own wording ("Your pantry data lives in a local database on your own device by default... it can optionally sync to a cloud database") — that description does not match the shipped app's actual behavior. It's most plausibly leftover wording from an earlier point in the project (before the Render + Supabase Postgres standalone deployment existed, when a local backend really would have meant "on the dev machine"), never updated after the architecture changed. This matters a lot for how "cloud sync" should be understood below.

---

## Pantry Ingredients

| Question | Answer |
|---|---|
| **Where stored** | Primary: the FastAPI backend's `pantry_items` table. In production this is a Supabase Postgres table — already cloud-hosted, reached identically by every device via the same REST API. (Only in *local development*, with no `DATABASE_URL` set, is this a SQLite file — and even then, it's local to the *developer's machine*, not the phone.) Secondary/backup: a separate Supabase table, `public.ingredients`, written to directly by the Flutter app via the Supabase SDK. |
| **Survives logout/login (same device)** | Yes. Pantry data was never tied to a local app session — `GET /inventory` returns the same rows for the same account regardless of how many times you've logged in and out. |
| **Survives uninstall/reinstall** | Yes, in the deployed app — because the data was never on the device to begin with. Reinstalling and signing back into the same account immediately shows the full pantry via the API. This holds with **zero dependency** on the separate `SupabaseService` sync mechanism below. |
| **Syncs across devices** | Yes, automatically and immediately, for the same reason — every device's app talks to the identical central backend. A second device signing into the same account sees the same pantry the moment it calls `GET /inventory`, without needing to press "Sync Now" or wait for any background sync. |
| **What triggers a "sync"** | The word "sync" in this app specifically refers to the *secondary* mechanism: `SupabaseService.resolveConflicts()`, reconciling the backend's `pantry_items` against the separate `public.ingredients` mirror table. This runs automatically (silently, best-effort) on every app launch, and manually via the Cloud Sync screen's "Sync Now" button. **This secondary sync is not what makes multi-device pantry access work** — it's an additional, largely redundant backup layer in a second table, most plausibly a holdover from Phase 10 (built before the backend itself was centrally hosted). |

## User Account (email, password, name)

| Question | Answer |
|---|---|
| **Where stored** | Supabase Auth's own `auth.users` table (fully cloud-managed). The app additionally caches a *display* copy of name/email locally in `flutter_secure_storage` (`auth_name`, `auth_email`, `auth_created_at`) so Profile/Statistics can show something even if a network call is slow — this cache is not the source of truth. |
| **Survives logout/login (same device)** | Yes for the account itself. The local secure-storage cache is explicitly cleared on logout (`AuthService.clearSession()`) and re-populated fresh on the next successful sign-in from the account's own metadata. |
| **Survives uninstall/reinstall** | The account: yes (cloud-side). The local secure-storage cache: no (cleared with the rest of the app's data on uninstall, standard Android behavior — no backup is configured) — but it's automatically rebuilt the next time the user signs in. |
| **Syncs across devices** | The account is inherently shared (it's the same cloud account). Each device independently caches its own local copy of the display name/email after signing in — not "synced" between devices in the two-way sense, just independently sourced from the same place. |

## Diet Preferences

| Question | Answer |
|---|---|
| **Where stored** | `SharedPreferences`, key `auth_diet_preferences_<uid>` (per-user scoped via `UserScope`). |
| **Survives logout/login (same device)** | **Yes — confirmed, and this is the specific thing that was fixed this session.** The data was actually already persisting correctly the whole time; the bug was that `DietPreferencesScreen` never *loaded* the saved selections back into the UI when reopened, making it look like they'd vanished. Both the underlying storage and the screen's display now work correctly. |
| **Survives uninstall/reinstall** | **No.** `SharedPreferences` is local device storage, cleared on uninstall. A reinstall means re-doing diet preference setup from scratch, even though the pantry itself (above) would come right back. |
| **Syncs across devices** | **No.** This is local-only, per device. Signing into the same account on a second phone will **not** show the diet preferences set on the first — they'd need to be entered again on that device. |
| **What triggers a save** | `AuthService.saveDietPreferences()`, called only from `DietPreferencesScreen._finish()` (both the first-time onboarding path and the "Edit" path from Profile). |

## Allergies

Identical in every respect to Diet Preferences above — same storage mechanism (`auth_allergies_<uid>`), same answers to all four questions. Not sensitive data by the app's own classification (see `secure_storage_service.dart`'s comment), which is why it's on `SharedPreferences` rather than secure storage.

## Cooked History

| Question | Answer |
|---|---|
| **Where stored** | `SharedPreferences`, key `cooked_history_entries_<uid>` (per-user scoped), plus an in-memory cache for the running app session. |
| **Survives logout/login (same device)** | Yes. `CookedHistoryStore.reset()` clears only the *in-memory* cache on logout (so a different account signing in next doesn't see stale data mid-session) — the underlying persisted data for the original user is untouched and reloads correctly if they sign back in. |
| **Survives uninstall/reinstall** | **No.** Device-local only. |
| **Syncs across devices** | **No.** Cooking a recipe on your phone will not show up in Cooked History, Statistics, or Profile's Eco Score/Badges/Rescued figures on a different device signed into the same account. This is worth stating plainly for the report: **cooked history, and everything derived from it (Statistics' Cooking Impact section, Profile's Eco Score/Badges/Rescued), is entirely device-local.** Only the pantry-quantity *effects* of cooking (the actual deductions) are visible cross-device — the historical record of having cooked is not. |

## Saved Recipe Bookmarks

Same storage pattern as Cooked History (`saved_recipe_names_<uid>`), same answers: survives logout/login, does **not** survive reinstall, does **not** sync across devices.

## Delete Tombstones

| Question | Answer |
|---|---|
| **Where stored** | `SharedPreferences`, key `deleted_ingredient_ids_<uid>` (per-user scoped). |
| **What it's for** | Not user-facing data — an internal bookkeeping mechanism. See `docs/ARCHITECTURE.md` §6. |
| **Survives logout/login (same device)** | Yes (no explicit reset on logout for this store). |
| **Survives uninstall/reinstall** | No. |
| **Syncs across devices** | No — and this is fine by design, since a tombstone only ever needs to matter to the device that performed the original delete and whose mirror-delete attempt might have failed. Losing it in the worst case just means a stale cloud row could resurrect once, needing to be deleted again manually. |

## Onboarding Completion State

There is **no explicit persisted flag** for "has this user finished onboarding." `DietPreferencesScreen` is reached exactly once automatically, right after a successful sign-up with an active session (`CreateAccountScreen`'s success path) — it is never shown again automatically afterward. Returning users (`SignInScreen`'s success path) always go straight to `MainScreen`. The only other way to reach `DietPreferencesScreen` is manually, via Profile's "Edit" link. Since there's no stored boolean, there's nothing to "survive" in the usual sense — it's a one-time navigational branch, not a piece of state.

## Quick-Reference Table

| Data type | Local-only or cloud-backed? | Survives logout/login | Survives uninstall | Syncs across devices |
|---|---|---|---|---|
| Pantry ingredients | Cloud-backed (always, via the backend) | ✅ | ✅ | ✅ (automatic, no "sync" needed) |
| User account (email/name/password) | Cloud-backed (Supabase Auth) | ✅ | ✅ | ✅ |
| Diet preferences | **Local-only** | ✅ | ❌ | ❌ |
| Allergies | **Local-only** | ✅ | ❌ | ❌ |
| Cooked history | **Local-only** | ✅ | ❌ | ❌ |
| Saved recipe bookmarks | **Local-only** | ✅ | ❌ | ❌ |
| Delete tombstones (internal) | **Local-only** | ✅ | ❌ | ❌ (by design) |
| Cached identity (name/email display copy) | Local cache of cloud data | ✅ (rebuilt) | ❌ (rebuilt on next sign-in) | N/A |
