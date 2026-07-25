# UI Design System

Source of truth: Figma file `naaKMnLlp5usmlvppkaiMY`. This doc tracks the design tokens actually pulled from Figma and used in code. For the screen navigation map (what links to what), see [PROJECT_FLOW.md](PROJECT_FLOW.md).

## Color Palette

Defined in `frontend/fridge2table_app/lib/constants/colors.dart` (`AppColors`):

| Token | Hex | Usage |
|---|---|---|
| `darkGreen` | `#1B4332` | Primary brand color — headers, buttons, active states |
| `deepGreen` | `#081C15` | Status bar / darkest accents |
| `lightGreen` | `#D8F3DC` | Info banners, subtle tinted backgrounds |
| `borderGreen` | `#E4EDE7` | Dividers, progress-bar tracks, inactive borders, subtle card borders |
| `background` | `#F5F8F6` | Screen background |
| `textGray` | `#6B7280` | Secondary text |
| `scanGreen` | `#52B788` | AI Camera scan overlay accents |
| `chipGreenBg` | `#DCFCE7` | Category chip background |
| `chipGreenText` | `#166534` | Category chip text |
| `textDark` | `#1A202C` | Primary text |

Category chip colors follow the same red/blue/orange/purple/gray pattern across every screen that shows ingredient category chips (Pantry, Home, Recipe Detail, Expiry Monitor) — Vegetables (green), Meat & Seafood (red), Dairy (blue), Fruits (orange), Grains & Bread (purple), uncategorized (gray).

Expiry status colors (`inventory_screen.dart`, `expiry_monitor_screen.dart`, `home_screen.dart`):

| Status | Color |
|---|---|
| Expired / Today | `#C0392B` |
| Soon (≤3 days) | `#D68910` |
| Fresh | `#1D6A3A` |
| No date set | `AppColors.textGray` |

Recipe card gradients (`home_screen.dart`, cycled by card index): `#7B341E→#C05621` (orange-red), `#713F12→#C6862A` (amber), `#3B0764→#7C3AED` (purple).

## Typography

Both fonts are bundled as variable fonts (`pubspec.yaml` → `flutter.fonts`, files in `assets/fonts/`):

- **DM Sans** (`assets/fonts/DMSans-Variable.ttf`) — body text, set as the app-wide default via `ThemeData(fontFamily: "DM Sans")` in `main.dart`
- **Outfit** (`assets/fonts/Outfit-Variable.ttf`) — headings/brand text, applied explicitly per-widget via `fontFamily: "Outfit"` with `FontWeight.w800`

## Screen Header Pattern

Nearly every screen uses the same shape — a `Container` (not an `AppBar`) with `AppColors.darkGreen` and rounded bottom corners, so it bleeds into the status bar area:

```dart
Container(
  decoration: const BoxDecoration(
    color: AppColors.darkGreen,
    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
  ),
  padding: const EdgeInsets.fromLTRB(12, 48, 12, 16),
  child: Row(...), // back button (optional) + title + optional right-side icon(s)
)
```

**Important gotcha:** if a screen stacks *another* same-color block directly below this header in a `Column` (e.g. a search bar), give that block a **light** background (`AppColors.background`), not `AppColors.darkGreen`. The header's rounded bottom corners reveal whatever sits behind/below them — a same-dark-color block underneath makes the rounding invisible (fine), but it also means the corner-reveal only looks clean if what's revealed is the page's actual light background. Stacking two dark blocks creates a visible notch at the seam. (Fixed in `inventory_screen.dart` and `waste_control_screen.dart` — search for this exact comment if it recurs elsewhere.)

`HomeScreen`, `ProfileScreen`, `SignInScreen`, and `CreateAccountScreen` use a taller variant of the same pattern (`padding` top ~52-60) as a hero header with user info / branding instead of just a title bar.

## Screen Inventory

25 screens in `lib/screens/`, grouped by area (see [PROJECT_FLOW.md](PROJECT_FLOW.md) for how they connect):

| Area | Screens |
|---|---|
| Onboarding & auth | `splash_screen`, `signin_screen`, `create_account_screen`, `diet_preferences_screen` |
| Legal | `terms_screen`, `privacy_screen` |
| Main tabs | `home_screen`, `inventory_screen` (Pantry), `recipe_screen`, `profile_screen` |
| AI scanning | `ai_camera_screen`, `ai_detection_screen`, `add_ingredient_screen` |
| Pantry management | `expiry_monitor_screen`, `notifications_screen` |
| Recipes & cooking | `recipe_detail_screen`, `cooking_mode_screen`, `cooking_confirm_screen`, `exclude_ingredients_screen`, `recipe_complete_screen`, `cooked_history_screen` |
| Account & data | `settings_screen`, `cloud_sync_screen`, `statistics_screen`, `waste_control_screen` |

## AI Camera Screen Detail

- Top bar: X (close) button, pill badge with pulsing green dot + "AI Active" text, sparkle/settings button — all `rgba(0,0,0,0.4)` circular buttons over the live camera feed
- Center: 240×240 scan box, 4 corner brackets (`scanGreen`, 4px border, 16px corner radius), animated horizontal scan line with glow
- Hint text below the scan box: "Point at ingredients in good lighting" (white 70% opacity)
- Bottom bar: `#0D0D0D` background, gallery button (left), 80px white capture button with dark-green ring (center), flash toggle (right)
- Capture runs the on-device MobileNetV2 model (`ingredient_classifier_service.dart`) and routes straight to `AddIngredientScreen` with the top prediction pre-filled — no separate multi-item confidence-bar selection screen (`ai_detection_screen.dart` exists but isn't part of the main capture flow).

## Known Design Debt

- Recipe card gradient palette only has 3 entries cycled across however many recipes are shown — fine visually (colors repeat), just noting it's not a unique-per-card design
- `ai_detection_screen.dart` (multi-item confidence-bar selection UI from the original Figma set) exists but isn't wired into the main capture flow, which routes single-prediction captures straight to `AddIngredientScreen` instead
