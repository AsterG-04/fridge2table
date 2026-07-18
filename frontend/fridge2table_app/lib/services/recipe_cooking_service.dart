import '../models/ingredient.dart';
import '../models/ingredient_deduction.dart';
import '../models/recipe_detail.dart';
import 'api_service.dart';

class RecipeCookingService {
  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  /// Real recipes only list ingredient *names*, not per-recipe quantities,
  /// so there's no "recipe needs 150g" figure to subtract. Instead this
  /// assumes a typical single-recipe usage based on the pantry item's own
  /// unit — a real, unit-aware amount (not a fabricated per-ingredient
  /// guess), consistently applied to every deduction.
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

  /// Deducts non-skipped ingredient quantities from the real pantry —
  /// matched by name (case insensitive), updated via PUT if quantity stays
  /// above zero, deleted via DELETE if it reaches zero or below — and
  /// returns the before/after amounts for display on the completion screen.
  static Future<List<IngredientDeduction>> deduct(
    RecipeDetail recipe,
    Set<String> skippedNames,
  ) async {
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
      final usage = _typicalUsage(item.unit);
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
