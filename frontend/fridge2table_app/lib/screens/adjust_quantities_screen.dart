import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/planned_ingredient_usage.dart';
import '../models/recipe_detail.dart';
import '../services/recipe_cooking_service.dart';
import 'recipe_complete_screen.dart';

class AdjustQuantitiesScreen extends StatefulWidget {
  final RecipeDetail recipe;

  const AdjustQuantitiesScreen({super.key, required this.recipe});

  @override
  State<AdjustQuantitiesScreen> createState() => _AdjustQuantitiesScreenState();
}

class _AdjustQuantitiesScreenState extends State<AdjustQuantitiesScreen> {
  List<PlannedIngredientUsage>? _planned;
  final Map<String, TextEditingController> _controllers = {};
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
          _controllers[p.name] = TextEditingController(text: _fmt(p.defaultAmount));
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

  Future<void> _confirm() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final customAmounts = <String, double>{};
      for (final entry in _controllers.entries) {
        final parsed = double.tryParse(entry.value.text.trim());
        if (parsed != null && parsed > 0) {
          customAmounts[entry.key] = parsed;
        }
      }

      final deductions = await RecipeCookingService.deduct(
        widget.recipe,
        const {},
        customAmounts: customAmounts,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeCompleteScreen(
            recipe: widget.recipe,
            deductionSummary: "Cooked by measurement — amounts you set",
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
                            child: Center(child: CircularProgressIndicator(color: AppColors.darkGreen)),
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
          _buildFooter(),
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
              decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
              child: const Icon(Icons.chevron_left, color: AppColors.textDark, size: 20),
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
          const Text(
            "Adjust the amount for each ingredient — pre-filled with a typical estimate.",
            style: TextStyle(color: AppColors.textGray, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _ingredientRow(PlannedIngredientUsage p) {
    final item = p.pantryItem;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.chipGreenBg, borderRadius: BorderRadius.circular(18)),
            alignment: Alignment.center,
            child: Text(
              p.initials,
              style: const TextStyle(color: AppColors.chipGreenText, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  item == null ? "Not in your pantry — nothing to deduct" : "You have ${_fmt(item.quantity)} ${item.unit}",
                  style: const TextStyle(color: AppColors.textGray, fontSize: 12),
                ),
              ],
            ),
          ),
          if (item != null) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 72,
              child: TextField(
                controller: _controllers[p.name],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.darkGreen.withValues(alpha: 0.15)),
                  ),
                  suffixText: item.unit,
                  suffixStyle: const TextStyle(color: AppColors.textGray, fontSize: 11),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderGreen)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: (_submitting || _planned == null) ? null : _confirm,
          icon: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check, color: Colors.white, size: 16),
          label: Text(
            _submitting ? "Updating pantry..." : "Confirm & Update Pantry",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkGreen,
            disabledBackgroundColor: AppColors.darkGreen.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }
}
