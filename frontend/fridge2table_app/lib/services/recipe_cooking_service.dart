import '../models/ingredient.dart';
import '../models/ingredient_deduction.dart';
import '../models/planned_ingredient_usage.dart';
import '../models/recipe_detail.dart';
import 'api_service.dart';

class RecipeCookingService {
  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  /// Real recipes only list ingredient *names*, not per-recipe quantities,
  /// so there's no "recipe needs 150g" figure to subtract. Instead this
  /// assumes a typical single-recipe usage based on the pantry item's own
  /// unit — a real, unit-aware amount (not a fabricated per-ingredient
  /// guess), consistently applied to every deduction, and used as the
  /// starting default whenever the user is asked to adjust it themselves.
  static double _typicalUsage(String unit) {
    switch (unit.toLowerCase()) {
      case "g":
        return 100;
      case "kg":
        return 0.2;
      case "ml":
        return 100;
      case "l":
        return 0.1;
      case "pcs":
        return 2;
      case "cups":
        return 0.5;
      case "tbsp":
        return 2;
      case "tsp":
        return 2;
      default:
        return 1;
    }
  }

  /// Matches each recipe ingredient against the real pantry without
  /// deducting anything yet — used by the "by measurement" flow to show
  /// the user what's about to be used and let them adjust the amount
  /// before anything is actually subtracted.
  static Future<List<PlannedIngredientUsage>> planUsage(RecipeDetail recipe) async {
    List<Ingredient> inventory = [];
    try {
      inventory = await ApiService.getInventory();
    } catch (_) {
      // Pantry unreachable — every ingredient below falls through as
      // "not in pantry", matching deduct()'s own fallback behavior.
    }

    return [
      for (final ing in recipe.ingredients)
        () {
          final matches = inventory.where(
            (item) => item.name.toLowerCase() == ing.name.toLowerCase(),
          );
          final item = matches.isEmpty ? null : matches.first;
          return PlannedIngredientUsage(
            name: ing.name,
            initials: ing.initials,
            pantryItem: item,
            defaultAmount: item == null ? 0 : _typicalUsage(item.unit),
          );
        }(),
    ];
  }

  /// Deducts non-skipped ingredient quantities from the real pantry —
  /// matched by name (case insensitive), updated via PUT if quantity stays
  /// above zero, deleted via DELETE if it reaches zero or below — and
  /// returns the before/after amounts for display on the completion screen.
  ///
  /// [customAmounts] (ingredient name -> amount, in the pantry item's own
  /// unit) overrides the typical-usage default for that ingredient, used by
  /// the "by measurement" flow once the user has confirmed their own
  /// amounts. Ingredients not present in the map fall back to the typical
  /// usage estimate as before.
  static Future<List<IngredientDeduction>> deduct(
    RecipeDetail recipe,
    Set<String> skippedNames, {
    Map<String, double>? customAmounts,
  }) async {
    final result = <IngredientDeduction>[];

    List<Ingredient> inventory = [];
    try {
      inventory = await ApiService.getInventory();
    } catch (_) {
      // Pantry unreachable — fall through with symbolic entries only.
    }

    for (final ing in recipe.ingredients) {
      if (skippedNames.contains(ing.name)) {
        result.add(IngredientDeduction(name: ing.name, initials: ing.initials, skipped: true));
        continue;
      }

      final matches = inventory.where(
        (item) => item.name.toLowerCase() == ing.name.toLowerCase(),
      );
      if (matches.isEmpty) {
        result.add(IngredientDeduction(
          name: ing.name,
          initials: ing.initials,
          usedSymbolic: true,
        ));
        continue;
      }

      final item = matches.first;
      final before = item.quantity;
      final usage = customAmounts?[ing.name] ?? _typicalUsage(item.unit);
      final after = (before - usage).clamp(0, double.infinity).toDouble();

      if (item.id != null) {
        try {
          if (after <= 0) {
            await ApiService.deleteIngredient(item.id!);
          } else {
            await ApiService.updateIngredient(
              item.id!,
              Ingredient(
                id: item.id,
                name: item.name,
                quantity: after,
                unit: item.unit,
                category: item.category,
                location: item.location,
                expiryDate: item.expiryDate,
              ),
            );
          }
        } catch (_) {
          // Best-effort — completion screen still shows the intended change.
        }
      }

      result.add(IngredientDeduction(
        name: ing.name,
        initials: ing.initials,
        beforeLabel: "${_fmt(before)} ${item.unit}",
        afterLabel: after <= 0 ? "Used up" : "${_fmt(after)} ${item.unit}",
        amountUsed: before - after,
        unit: item.unit,
      ));
    }

    return result;
  }
}
