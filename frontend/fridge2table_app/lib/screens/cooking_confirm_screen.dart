import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/recipe_detail.dart';
import 'adjust_quantities_screen.dart';

class CookingConfirmScreen extends StatefulWidget {
  final RecipeDetail recipe;

  const CookingConfirmScreen({super.key, required this.recipe});

  @override
  State<CookingConfirmScreen> createState() => _CookingConfirmScreenState();
}

class _CookingConfirmScreenState extends State<CookingConfirmScreen> {
  int _selected = 0; // 0 = by measurement, 1 = by estimate

  void _confirm() {
    // Both options lead to the same adjustable-quantities step now — "by
    // estimate" just flags itself so that screen shows by-feel hints and
    // leans on its skip toggle instead of assuming a "By measurement" flow.
    // AdjustQuantitiesScreen handles its own loading state and calls
    // RecipeCookingService.deduct() once the user confirms.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AdjustQuantitiesScreen(
          recipe: widget.recipe,
          byEstimate: _selected == 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: Column(
                      children: [
                        _optionCard(
                          index: 0,
                          icon: Icons.straighten,
                          title: "By measurement",
                          badge: "Most accurate",
                          description:
                              "I followed the recipe amounts — weighed or used measuring cups/spoons.",
                        ),
                        const SizedBox(height: 16),
                        _optionCard(
                          index: 1,
                          icon: Icons.tune,
                          title: "By estimate",
                          badge: "Common approach",
                          description:
                              "I cooked by feel — rough handfuls, pinches, and splashes.",
                        ),
                        const SizedBox(height: 16),
                        _infoBanner(),
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
            "Before we update your pantry",
            style: TextStyle(
              fontFamily: "Outfit",
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "How did you measure your ingredients while cooking?",
            style: TextStyle(
              color: AppColors.textGray,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionCard({
    required int index,
    required IconData icon,
    required String title,
    required String badge,
    required String description,
  }) {
    final isSelected = _selected == index;
    return GestureDetector(
      onTap: () => setState(() => _selected = index),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.darkGreen
                : AppColors.darkGreen.withValues(alpha: 0.11),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.darkGreen, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.chipGreenBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: AppColors.chipGreenText,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.darkGreen : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.darkGreen
                      : AppColors.darkGreen.withValues(alpha: 0.11),
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBanner() {
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
          const Icon(Icons.info_outline, size: 16, color: AppColors.textGray),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "This helps us keep your pantry accurate. If you cooked by estimate, "
              "you'll get to pick which ingredients to skip deducting next.",
              style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 12,
                height: 1.4,
              ),
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
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _confirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkGreen,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            "Confirm & Update Pantry",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
