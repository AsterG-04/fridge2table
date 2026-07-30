import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/cooked_history_entry.dart';
import '../models/ingredient_deduction.dart';
import '../models/recipe_detail.dart';
import 'cooked_history_screen.dart';

class RecipeCompleteScreen extends StatefulWidget {
  final RecipeDetail recipe;
  final String deductionSummary;
  final List<IngredientDeduction> deductions;

  const RecipeCompleteScreen({
    super.key,
    required this.recipe,
    required this.deductionSummary,
    required this.deductions,
  });

  @override
  State<RecipeCompleteScreen> createState() => _RecipeCompleteScreenState();
}

class _RecipeCompleteScreenState extends State<RecipeCompleteScreen> {
  @override
  void initState() {
    super.initState();
    // Not awaited here (initState can't be async), but errors are no longer
    // silently swallowed -- a failure that previously vanished with zero
    // trace now at least shows up in logs instead of just leaving
    // Statistics/Profile looking like nothing happened.
    unawaited(_recordCook());
  }

  Future<void> _recordCook() async {
    try {
      await CookedHistoryStore.recordCook(
        name: widget.recipe.name,
        time: widget.recipe.time,
        calories: widget.recipe.calories,
        deductionSummary: widget.deductionSummary,
        ingredientNames: widget.recipe.ingredients.map((i) => i.name).toList(),
      );
    } catch (error, stackTrace) {
      debugPrint(
        "[RecipeCompleteScreen] recordCook failed: $error\n$stackTrace",
      );
    }
  }

  (Color, Color) _catColors(String initials) {
    const palette = [
      (Color(0xFFDCFCE7), Color(0xFF166534)),
      (Color(0xFFFEE2E2), Color(0xFF991B1B)),
      (Color(0xFFDBEAFE), Color(0xFF1E40AF)),
      (Color(0xFFFFEDD5), Color(0xFF9A3412)),
      (Color(0xFFEDE9FE), Color(0xFF5B21B6)),
    ];
    return palette[initials.hashCode.abs() % palette.length];
  }

  int get _deductedCount => widget.deductions.where((d) => !d.skipped).length;

  /// Converts a pantry unit amount to an approximate gram equivalent, using
  /// the same unit-aware assumptions as RecipeCookingService's deduction
  /// math, so "grams saved" reflects what was actually subtracted from the
  /// pantry rather than a flat guess.
  double _toGrams(double amount, String unit) {
    switch (unit.toLowerCase()) {
      case "g":
        return amount;
      case "kg":
        return amount * 1000;
      case "ml":
        return amount;
      case "l":
        return amount * 1000;
      case "pcs":
        return amount * 50;
      case "cups":
        return amount * 240;
      case "tbsp":
        return amount * 15;
      case "tsp":
        return amount * 5;
      default:
        return amount * 50;
    }
  }

  double get _foodSavedGrams {
    var total = 0.0;
    for (final d in widget.deductions) {
      if (d.amountUsed != null && d.unit != null) {
        total += _toGrams(d.amountUsed!, d.unit!);
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final foodSavedGrams = _foodSavedGrams;
    final co2Saved = foodSavedGrams * 0.0025;
    final moneySaved = foodSavedGrams * 0.008;
    final points = _deductedCount * 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(recipe),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      children: [
                        _pantryUpdatedCard(),
                        const SizedBox(height: 16),
                        _sustainabilityCard(
                          foodSavedGrams,
                          co2Saved,
                          moneySaved,
                          points,
                        ),
                        const SizedBox(height: 16),
                        _scrapTipCard(),
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

  Widget _buildHero(RecipeDetail recipe) {
    return Container(
      width: double.infinity,
      color: AppColors.lightGreen,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: AppColors.darkGreen,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Meal Complete!",
            style: TextStyle(
              fontFamily: "Outfit",
              fontWeight: FontWeight.w600,
              fontSize: 22,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${recipe.name} cooked successfully",
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGray, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _heroStat(recipe.time),
              _heroStat("${recipe.calories} cal"),
              _heroStat("${recipe.matchPercent}% match"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.darkGreen,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _pantryUpdatedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 14,
                  color: AppColors.darkGreen,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Pantry Updated",
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.chipGreenBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  "$_deductedCount deducted",
                  style: const TextStyle(
                    color: AppColors.chipGreenText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final d in widget.deductions) ...[
            _deductionRow(d),
            const SizedBox(height: 10),
          ],
          const Divider(color: AppColors.borderGreen, height: 20),
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 14,
                color: AppColors.textGray,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "$_deductedCount ingredient${_deductedCount == 1 ? '' : 's'} deducted from your pantry",
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _deductionRow(IngredientDeduction d) {
    final (chipBg, chipText) = _catColors(d.initials);
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            d.initials,
            style: TextStyle(
              color: chipText,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            d.name,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (d.skipped || d.usedSymbolic)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              "Used",
              style: TextStyle(
                color: AppColors.textGray,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else
          Row(
            children: [
              Text(
                d.beforeLabel ?? "",
                style: const TextStyle(color: AppColors.textGray, fontSize: 11),
              ),
              const Icon(
                Icons.arrow_forward,
                size: 11,
                color: AppColors.textGray,
              ),
              Text(
                d.afterLabel ?? "",
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _sustainabilityCard(
    double foodSavedGrams,
    double co2Saved,
    double moneySaved,
    int points,
  ) {
    final foodSavedLabel = foodSavedGrams >= 1000
        ? "${(foodSavedGrams / 1000).toStringAsFixed(1)} kg"
        : "${foodSavedGrams.round()} g";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.eco_outlined,
                size: 16,
                color: AppColors.darkGreen,
              ),
              const SizedBox(width: 8),
              const Text(
                "Sustainability Impact",
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _impactStat(
                  Icons.savings_outlined,
                  foodSavedLabel,
                  "Food Saved",
                ),
              ),
              Expanded(
                child: _impactStat(
                  Icons.cloud_outlined,
                  "${co2Saved.toStringAsFixed(2)} kg",
                  "CO₂ Avoided",
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _impactStat(
                  Icons.attach_money,
                  "RM ${moneySaved.toStringAsFixed(2)}",
                  "Money Saved",
                ),
              ),
              Expanded(
                child: _impactStat(Icons.star_outline, "+$points", "Points"),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "You cooked ${widget.recipe.name.toLowerCase()} before it expired — preventing food waste and earning reward points.",
            style: const TextStyle(
              color: AppColors.textGray,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _impactStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.darkGreen),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.textGray, fontSize: 11),
        ),
      ],
    );
  }

  Widget _scrapTipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            size: 18,
            color: Color(0xFFD68910),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Scrap tip",
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Don't throw away vegetable scraps or eggshells — they're great for regrowing or composting. Check Waste Control for ideas.",
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
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
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CookedHistoryScreen()),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: AppColors.darkGreen.withValues(alpha: 0.11),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "View History",
                style: TextStyle(
                  color: AppColors.darkGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "Back to Home",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
