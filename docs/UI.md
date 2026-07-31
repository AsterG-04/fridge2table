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

Two font families, both bundled locally (`pubspec.yaml` → `flutter.fonts`, files in `assets/fonts/`) rather than fetched at runtime (`google_fonts` was deliberately not used, to avoid adding a network dependency to app startup — see `docs/ARCHITECTURE.md`'s startup notes):

- **Manrope** (`assets/fonts/Manrope-{Regular,Medium,SemiBold,Bold,ExtraBold}.ttf`, weights 400/500/600/700/800) — body text, set as the app-wide default via `ThemeData(fontFamily: "Manrope")` in `main.dart`. Replaced DM Sans (removed) this session, per direct request — no other reason, both are competent neutral UI fonts.
- **Outfit** (`assets/fonts/Outfit-Variable.ttf`) — headings/brand text, applied explicitly per-widget via `fontFamily: "Outfit"`, weights 400/700/800. Untouched by the Manrope switch — this is a deliberate two-font system (Outfit for display headlines/large stat numbers, Manrope for everything else), not an oversight.

**Weight discipline (audited and corrected twice this project):** headers/titles/section labels max out at `w600` (SemiBold); plain body text and list-row primary labels (ingredient/recipe names in a list, item counts) are `w400`–`w500`; true `FontWeight.bold`/`w700`+ is reserved for large stat numbers (Home's stat cards, always Outfit) and full-width primary CTA buttons ("Cook Now", "Got it!") — small pills/badges/secondary buttons that had crept up to `w700` (match-percentage badges, the AI Insight "Rescue" button) were brought back down to `w600`. Visual hierarchy should come from color contrast (dark vs. gray) and size, not from stacking heavier weights on top of already-heavy ones.

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

**Back button audit (all 25 screens checked):** every `chevron_left`/`arrow_back` back button in the app is a `GestureDetector`/`IconButton` wrapping `Navigator.pop`/`maybePop`, consistently wired — no dead/decorative back icons found. `CookingModeScreen` uses a text "Exit" button instead of the usual icon-in-circle (a deliberate, pre-existing style difference for the cooking-flow screens, not a bug). Screens with no back button are all deliberate: the four bottom-tab roots (`HomeScreen`, `InventoryScreen`, `RecipeScreen`, `ProfileScreen` when shown as a tab, not pushed), `SplashScreen` and `SignInScreen` (always reached with an empty stack beneath them — confirmed by tracing every navigation path into them), and `RecipeCompleteScreen` (deliberately can't navigate backward into an already-applied pantry deduction; it has a forward-only "Done" that pops to the root instead). One real bug *was* found and fixed here, not a UI issue but a back-stack correctness one: see `docs/PROJECT_OVERVIEW.md` §6 and `docs/CODEBASE_GUIDE.md`'s `diet_preferences_screen.dart` entry.

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

## App Icon / Logo Safe Zone

`assets/images/f2t_logo.png` is the single source logo, used three places: `pubspec.yaml`'s `flutter_launcher_icons` config (app icon), `splash_screen.dart`'s brand page, `home_screen.dart`'s header badge. The launcher icon is the one place this bites: Android adaptive icons are masked to a **circle** on many launchers (stock Android/Pixel included), which only guarantees the inner ~66% "safe zone" of the icon canvas stays visible — the original logo's visible content reached ~80% of its canvas, so it was genuinely getting clipped by that circular mask (confirmed visually on-device, not just in theory). The in-app rounded-square usages (Splash, Home badge) were never actually affected — `BoxFit.cover` on a square source in a square-aspect container doesn't crop anything, since the aspect ratios already match.

**The fix:** `tool/pad_adaptive_icon.dart` (run via `dart run tool/pad_adaptive_icon.dart`) generates `assets/images/f2t_logo_adaptive.png` — the same logo shrunk to ~62% of a new, larger transparent canvas, comfortably inside the safe zone regardless of mask shape. `adaptive_icon_background` (`pubspec.yaml`) is set to `#FCF3E0`, sampled from the logo's own card color, so the transparent padding is invisible rather than a visible seam. After changing the source logo, re-run the tool script *then* `dart run flutter_launcher_icons` to regenerate the actual icon files — running only the icon generator against the raw source will reintroduce the crop.

## Known Design Debt

- Recipe card gradient palette only has 3 entries cycled across however many recipes are shown — fine visually (colors repeat), just noting it's not a unique-per-card design
- `ai_detection_screen.dart` (multi-item confidence-bar selection UI from the original Figma set) exists but isn't wired into the main capture flow, which routes single-prediction captures straight to `AddIngredientScreen` instead
