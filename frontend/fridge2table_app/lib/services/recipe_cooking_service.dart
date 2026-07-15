import '../models/ingredient.dart';
import '../models/ingredient_deduction.dart';
import '../models/recipe_detail.dart';
import 'api_service.dart';

class RecipeCookingService {
  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  /// Deducts non-skipped ingredient quantities from the real pantry
  /// (best-effort — matched by name, failures are swallowed) and returns
  /// the before/after amounts for display on the completion screen.
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

      final amount = double.tryParse(RegExp(r'[\d.]+').stringMatch(ing.quantity) ?? '');
      if (amount == null) {
        result.add(IngredientDeduction(name: ing.name, initials: ing.initials, usedSymbolic: true));
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
      final after = (before - amount).clamp(0, double.infinity).toDouble();

      if (item.id != null) {
        try {
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
        } catch (_) {
          // Best-effort — completion screen still shows the intended change.
        }
      }

      result.add(IngredientDeduction(
        name: ing.name,
        initials: ing.initials,
        beforeLabel: "${_fmt(before)} ${item.unit}",
        afterLabel: "${_fmt(after)} ${item.unit}",
      ));
    }

    return result;
  }
}
