# UI Design System

Source of truth: Figma file `naaKMnLlp5usmlvppkaiMY` (24 planned screens). This doc tracks the design tokens actually pulled from Figma and used in code, plus which screens are built vs. still just designs.

## Color Palette

Defined in `frontend/fridge2table_app/lib/constants/colors.dart` (`AppColors`):

| Token | Hex | Usage |
|---|---|---|
| `darkGreen` | `#1B4332` | Primary brand color — headers, buttons, active states |
| `deepGreen` | `#081C15` | Status bar / darkest accents |
| `lightGreen` | `#D8F3DC` | Info banners, subtle tinted backgrounds |
| `borderGreen` | `#E4EDE7` | Dividers, progress-bar tracks, inactive borders |
| `background` | `#F5F8F6` | Screen background |
| `textGray` | `#6B7280` | Secondary text |
| `scanGreen` | `#52B788` | AI Camera scan overlay accents |
| `chipGreenBg` | `#DCFCE7` | Category chip background (e.g. AI Detection ingredient chips) |
| `chipGreenText` | `#166534` | Category chip text |
| `textDark` | `#1A202C` | Primary text |

Expiry status colors (used in `expiry_monitor_screen.dart`, not yet added to `AppColors`):

| Status | Color |
|---|---|
| Expired | `Colors.red` |
| Today | `Colors.orange` |
| Soon | `#CA8A04` (amber) |
| Fresh | `Colors.green` |
| Unknown | `AppColors.textGray` |

Recipe card gradients (`recipe_screen.dart`, cycled by card index):

| Index | Gradient | Feel |
|---|---|---|
| 0, 3 | `#7B341E` → `#C05621` | orange-red |
| 1 | `#713F12` → `#C6862A` | amber |
| 2 | `#3B0764` → `#7C3AED` | purple |
| 4 | `#1A4731` → `#2D6A4F` | green |

## Typography

- Body: **DM Sans** (Regular/SemiBold/Bold/Black weights seen in Figma exports)
- Logo/brand: **Outfit Bold**
- Neither font is currently bundled as a custom font in `pubspec.yaml` — screens built so far use Flutter's default Material typeface. Worth revisiting when doing a full visual pass against Figma.

## Screen Header Pattern

Every built screen that has a colored header follows the same shape — a `Container` (not an `AppBar`) so it can bleed into the status bar area:

```dart
Container(
  color: AppColors.darkGreen,
  padding: const EdgeInsets.fromLTRB(20, 52, 20, 12),
  child: Row(...), // back button (optional) + title + optional right-side element
)
```

Used in `RecipeScreen` and `ExpiryMonitorScreen`. `InventoryScreen` still uses a plain Material `AppBar` (default light theme) — not yet restyled to match.

## Screens: Built vs. Figma-only

| Figma screen | Node | Status |
|---|---|---|
| Inventory | `4:xxx` (Core group) | ✅ Built — plain `AppBar`, not yet Figma-styled |
| Recipes | `6:3478` | ✅ Built — dark green header, gradient cards, filter chips, match % badges |
| AI Camera | `6:2516` | ✅ Built — live camera preview, corner-bracket scan overlay, capture/gallery/flash controls, matches Figma closely |
| AI Detection | `6:2704` | ⬜ Designed, not built — no AI model yet, so capture currently routes to a manual-entry form instead |
| Add Ingredient | — | ✅ Built (not in the original 24-screen Figma set; extended to show a captured-photo thumbnail) |
| Expiry Monitor | — | ✅ Built (not in the original 24-screen Figma set; dark-green-header style matches the app, not a specific Figma frame) |
| Splash, Sign In, Create Account, Diet Preferences, Allergy Setup | Auth group | ⬜ Designed, not built |
| Dashboard | Core group | ⬜ Designed, not built (`home_screen.dart` exists as an empty stub) |
| Waste Control | Sustainability group | ⬜ Designed, not built |
| Recipe Detail, Cooked History, Past Recipe, Cooking Mode, Cooking Confirm, Exclude Ingredients, Recipe Complete | Cooking group | ⬜ Designed, not built |
| Statistics | Insights group | ⬜ Designed, not built |
| Cloud Sync, Profile, Settings | Account group | ⬜ Designed, not built (`settings_screen.dart` exists as an empty stub) |

## Navigation

**Currently built:** 2-tab `BottomNavigationBar` in `main.dart` — Inventory (`Icons.kitchen`) and Recipes (`Icons.restaurant_menu`). AI Camera and Expiry Monitor are reached via icon buttons in the Inventory app bar, not the bottom nav.

**Figma plan (not yet built):** 5-tab nav — Home | Pantry | **Scan** (raised circular button, elevated above the bar, `#1B4332` background) | Recipes | Profile.

## AI Camera Screen Detail (fully matched to Figma `6:2516`)

- Top bar: X (close) button, pill badge with pulsing green dot + "AI Active" text, sparkle/settings button — all `rgba(0,0,0,0.4)` circular buttons over the live camera feed
- Center: 240×240 scan box, 4 corner brackets (`scanGreen`, 4px border, 16px corner radius), animated horizontal scan line with glow
- Hint text below the scan box: "Point at ingredients in good lighting" (white 70% opacity)
- Bottom bar: `#0D0D0D` background, gallery button (left), 80px white capture button with dark-green ring (center), flash toggle (right)

## Known Design Debt

- Inventory screen not yet restyled to the dark-green header pattern used elsewhere
- No custom fonts bundled (DM Sans / Outfit) — currently system default
- AI Detection screen (multi-item confidence-bar selection UI) not built, pending a trained model
- 5-tab nav with raised Scan button not built
