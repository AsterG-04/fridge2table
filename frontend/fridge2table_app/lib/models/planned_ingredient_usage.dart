import 'ingredient.dart';

/// A recipe ingredient matched against the real pantry, before anything is
/// deducted — the "by measurement" cooking flow shows one of these per
/// ingredient so the user can adjust the amount before confirming.
class PlannedIngredientUsage {
  final String name;
  final String initials;

  /// Null if this ingredient isn't in the pantry at all — nothing to
  /// deduct or adjust for it, it'll be recorded as a symbolic use instead.
  final Ingredient? pantryItem;

  /// The typical-usage estimate, in [pantryItem]'s unit — the starting
  /// value shown in the editable field, not a fixed amount.
  final double defaultAmount;

  const PlannedIngredientUsage({
    required this.name,
    required this.initials,
    required this.pantryItem,
    required this.defaultAmount,
  });
}
