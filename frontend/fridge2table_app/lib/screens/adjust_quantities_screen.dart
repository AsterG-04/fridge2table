import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/planned_ingredient_usage.dart';
import '../models/recipe_detail.dart';
import '../services/recipe_cooking_service.dart';
import 'recipe_complete_screen.dart';

class AdjustQuantitiesScreen extends StatefulWidget {
  final RecipeDetail recipe;

  /// Whether the user said they cooked by estimate rather than by
  /// measurement — both flows land here now, this only adjusts copy/hints
  /// (by-feel ingredients like salt or garlic get a hint instead of "You
  /// have X unit") since an estimate cook is more likely to want to skip
  /// deduction for those than type a precise amount.
  final bool byEstimate;

  const AdjustQuantitiesScreen({
    super.key,
    required this.recipe,
    this.byEstimate = false,
  });

  @override
  State<AdjustQuantitiesScreen> createState() => _AdjustQuantitiesScreenState();
}

class _AdjustQuantitiesScreenState extends State<AdjustQuantitiesScreen> {
  List<PlannedIngredientUsage>? _planned;
  final Map<String, TextEditingController> _controllers = {};

  // Absorbed from the old ExcludeIngredientsScreen — ingredients commonly
  // used "by feel" rather than a measured amount, shown as a hint instead of
  // the usual "You have X unit" line so the skip toggle reads as the
  // obviously-right choice for them.
  static const Map<String, String> _hints = {
    "garlic": "Usually a pinch or a few cloves",
    "ginger": "Typically a small knob or scraping",
    "salt": "Always by feel, not measurement",
    "black pepper": "A few turns of the grinder",
    "olive oil": "A splash, hard to measure exactly",
    "butter": "A rough dollop or scrape",
    "onion": "Size varies, amount is approximate",
    "soy sauce": "Dashes added until it tastes right",
    "basil": "Leaves pulled without weighing",
  };

  final Set<String> _skipped = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final planned = await RecipeCookingService.planUsage(widget.recipe);
    if (!mounted) return;
    setState(() {
      _planned = planned;
      for (final p in planned) {
        if (p.pantryItem != null) {
          _controllers[p.name] = TextEditingController(
            text: _fmt(p.defaultAmount),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  String? _hintFor(String name) => _hints[name.toLowerCase()];

  void _toggleSkip(String name) {
    setState(() {
      if (_skipped.contains(name)) {
        _skipped.remove(name);
      } else {
        _skipped.add(name);
      }
    });
  }

  Future<void> _confirm() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final customAmounts = <String, double>{};
      for (final entry in _controllers.entries) {
        if (_skipped.contains(entry.key)) continue;
        final parsed = double.tryParse(entry.value.text.trim());
        if (parsed != null && parsed > 0) {
          customAmounts[entry.key] = parsed;
        }
      }

      final deductions = await RecipeCookingService.deduct(
        widget.recipe,
        _skipped,
        customAmounts: customAmounts,
      );

      if (!mounted) return;
      final skippedCount = _skipped.length;
      final base = widget.byEstimate
          ? "Cooked by estimate"
          : "Cooked by measurement";
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeCompleteScreen(
            recipe: widget.recipe,
            deductionSummary:
                "$base — amounts you set${skippedCount == 0 ? '' : ' · $skippedCount skipped'}",
            deductions: deductions,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final planned = _planned;
    final skippedCount = _skipped.length;
    final adjustableCount =
        planned?.where((p) => p.pantryItem != null).length ?? 0;
    final deductedCount = adjustableCount - skippedCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: planned == null
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.darkGreen,
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final p in planned) ...[
                                _ingredientRow(p),
                                const SizedBox(height: 8),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
          _buildFooter(skippedCount, deductedCount),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_left,
                color: AppColors.textDark,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "How much are you using?",
            style: TextStyle(
              fontFamily: "Outfit",
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.byEstimate
                ? "Adjust the amount for each ingredient, or skip ones you used by feel."
                : "Adjust the amount for each ingredient — pre-filled with a typical estimate.",
            style: const TextStyle(
              color: AppColors.textGray,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ingredientRow(PlannedIngredientUsage p) {
    final item = p.pantryItem;
    final isSkipped = _skipped.contains(p.name);
    final hint = _hintFor(p.name);

    String subtitle;
    if (item == null) {
      subtitle = "Not in your pantry — nothing to deduct";
    } else if (isSkipped) {
      subtitle = "Won't be deducted from your pantry";
    } else if (widget.byEstimate && hint != null) {
      subtitle = hint;
    } else {
      subtitle = "You have ${_fmt(item.quantity)} ${item.unit}";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.chipGreenBg,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Text(
              p.initials,
              style: const TextStyle(
                color: AppColors.chipGreenText,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (item != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _toggleSkip(p.name),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSkipped ? AppColors.darkGreen : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSkipped
                        ? AppColors.darkGreen
                        : AppColors.darkGreen.withValues(alpha: 0.11),
                  ),
                ),
                child: isSkipped
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 72,
              child: TextField(
                controller: _controllers[p.name],
                enabled: !isSkipped,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSkipped ? AppColors.textGray : AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.darkGreen.withValues(alpha: 0.15),
                    ),
                  ),
                  suffixText: item.unit,
                  suffixStyle: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(int skippedCount, int deductedCount) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderGreen)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_submitting || _planned == null) ? null : _confirm,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, color: Colors.white, size: 16),
              label: Text(
                _submitting ? "Updating pantry..." : "Confirm & Update Pantry",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen,
                disabledBackgroundColor: AppColors.darkGreen.withValues(
                  alpha: 0.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          if (_planned != null) ...[
            const SizedBox(height: 8),
            Text(
              "$skippedCount skipped · $deductedCount will be deducted from your inventory",
              style: const TextStyle(color: AppColors.textGray, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
