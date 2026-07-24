import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/recipe_detail.dart';
import '../services/recipe_cooking_service.dart';
import 'recipe_complete_screen.dart';

class ExcludeIngredientsScreen extends StatefulWidget {
  final RecipeDetail recipe;

  const ExcludeIngredientsScreen({super.key, required this.recipe});

  @override
  State<ExcludeIngredientsScreen> createState() => _ExcludeIngredientsScreenState();
}

class _ExcludeIngredientsScreenState extends State<ExcludeIngredientsScreen> {
  final Set<String> _skipped = {};
  bool _submitting = false;

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

  String _hintFor(String name) =>
      _hints[name.toLowerCase()] ?? "Amount may vary when cooked by feel";

  Future<void> _confirm() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final skippedCount = _skipped.length;
      final deductions = await RecipeCookingService.deduct(widget.recipe, _skipped);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeCompleteScreen(
            recipe: widget.recipe,
            deductionSummary: "Cooked by estimate · $skippedCount item${skippedCount == 1 ? '' : 's'} skipped",
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
    final ingredients = widget.recipe.ingredients;
    final skippedCount = _skipped.length;
    final deductedCount = ingredients.length - skippedCount;

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _summaryBanner(skippedCount, deductedCount),
                        const SizedBox(height: 20),
                        const Text(
                          "Tap to toggle — ticked = skip deduction",
                          style: TextStyle(color: AppColors.textGray, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        for (final ing in ingredients) ...[
                          _ingredientToggleRow(ing),
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
              decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
              child: const Icon(Icons.chevron_left, color: AppColors.textDark, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "What did you use by feel?",
            style: TextStyle(
              fontFamily: "Outfit",
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Ticked items will not be deducted from your pantry",
            style: TextStyle(color: AppColors.textGray, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _summaryBanner(int skippedCount, int deductedCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(999)),
            child: const Icon(Icons.info_outline, size: 16, color: AppColors.darkGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "$skippedCount item${skippedCount == 1 ? '' : 's'} will be skipped · $deductedCount will be deducted",
              style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ingredientToggleRow(RecipeIngredientDetail ing) {
    final isSkipped = _skipped.contains(ing.name);
    return GestureDetector(
      onTap: () => setState(() {
        if (isSkipped) {
          _skipped.remove(ing.name);
        } else {
          _skipped.add(ing.name);
        }
      }),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSkipped ? AppColors.darkGreen : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: isSkipped ? AppColors.darkGreen : AppColors.darkGreen.withValues(alpha: 0.11)),
              ),
              child: isSkipped ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ing.name, style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(_hintFor(ing.name), style: const TextStyle(color: AppColors.textGray, fontSize: 12)),
                ],
              ),
            ),
            if (isSkipped)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFFEF9E7), borderRadius: BorderRadius.circular(999)),
                child: const Text("Skip", style: TextStyle(color: Color(0xFFD68910), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
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
              onPressed: _submitting ? null : _confirm,
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
          const SizedBox(height: 8),
          Text(
            "$skippedCount skipped · $deductedCount will be deducted from your inventory",
            style: const TextStyle(color: AppColors.textGray, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
