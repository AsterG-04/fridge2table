class IngredientDeduction {
  final String name;
  final String initials;
  final String? beforeLabel;
  final String? afterLabel;
  final bool skipped;
  final bool usedSymbolic;

  /// The real amount actually subtracted from the pantry, in [unit] — used
  /// to compute the sustainability totals on Recipe Complete. Null for
  /// skipped/symbolic entries where nothing was really deducted.
  final double? amountUsed;
  final String? unit;

  const IngredientDeduction({
    required this.name,
    required this.initials,
    this.beforeLabel,
    this.afterLabel,
    this.skipped = false,
    this.usedSymbolic = false,
    this.amountUsed,
    this.unit,
  });
}
