class IngredientDeduction {
  final String name;
  final String initials;
  final String? beforeLabel;
  final String? afterLabel;
  final bool skipped;
  final bool usedSymbolic;

  const IngredientDeduction({
    required this.name,
    required this.initials,
    this.beforeLabel,
    this.afterLabel,
    this.skipped = false,
    this.usedSymbolic = false,
  });
}
