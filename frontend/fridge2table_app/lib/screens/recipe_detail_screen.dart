import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/recipe_detail.dart';
import 'cooking_mode_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final RecipeDetail recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _saved = false;

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

  void _cookNow() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CookingModeScreen(recipe: widget.recipe)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;

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
                  _buildStatsBar(recipe),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.description,
                          style: const TextStyle(
                            color: AppColors.textGray,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _sectionCard(
                          title: "Ingredients",
                          child: Column(
                            children: [
                              for (final ing in recipe.ingredients) ...[
                                _ingredientRow(ing),
                                const SizedBox(height: 12),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _sectionCard(
                          title: "Nutrition per serving",
                          child: Row(
                            children: [
                              Expanded(child: _nutritionStat("${recipe.nutrition.calories}", "Calories")),
                              Expanded(child: _nutritionStat(recipe.nutrition.protein, "Protein")),
                              Expanded(child: _nutritionStat(recipe.nutrition.carbs, "Carbs")),
                              Expanded(child: _nutritionStat(recipe.nutrition.fat, "Fat")),
                            ],
                          ),
                        ),
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
      height: 208,
      color: AppColors.lightGreen,
      child: Stack(
        children: [
          Positioned(
            top: 20,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), shape: BoxShape.circle),
                child: const Icon(Icons.chevron_left, color: AppColors.darkGreen, size: 22),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: GestureDetector(
              onTap: () => setState(() => _saved = !_saved),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), shape: BoxShape.circle),
                child: Icon(
                  _saved ? Icons.bookmark : Icons.bookmark_outline,
                  color: AppColors.darkGreen,
                  size: 18,
                ),
              ),
            ),
          ),
          Positioned(
            top: 32,
            right: 24,
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.restaurant, color: AppColors.darkGreen, size: 28),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 24,
            right: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.tags,
                  style: const TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recipe.name,
                  style: const TextStyle(
                    fontFamily: "Outfit",
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(RecipeDetail recipe) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _statChip(Icons.access_time, recipe.time),
          const SizedBox(width: 16),
          _statChip(Icons.local_fire_department_outlined, "${recipe.calories} cal"),
          const SizedBox(width: 16),
          _statChip(Icons.bar_chart, recipe.difficulty),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.chipGreenBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              "${recipe.matchPercent}% match",
              style: const TextStyle(
                color: AppColors.chipGreenText,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textGray),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppColors.textGray, fontSize: 12)),
      ],
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _ingredientRow(RecipeIngredientDetail ing) {
    final (chipBg, chipText) = _catColors(ing.initials);
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center,
          child: Text(ing.initials, style: TextStyle(color: chipText, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            ing.name,
            style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        Text(ing.quantity, style: const TextStyle(color: AppColors.textGray, fontSize: 12)),
        const SizedBox(width: 8),
        if (ing.missing)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFFFDF2F0), borderRadius: BorderRadius.circular(999)),
            child: const Text("Missing", style: TextStyle(color: Color(0xFFC0392B), fontSize: 10, fontWeight: FontWeight.bold)),
          )
        else
          const Icon(Icons.check_circle, color: AppColors.chipGreenText, size: 16),
      ],
    );
  }

  Widget _nutritionStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textGray, fontSize: 11)),
      ],
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
              onPressed: () => setState(() => _saved = !_saved),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppColors.darkGreen.withValues(alpha: 0.11)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _saved ? "Saved" : "Save Recipe",
                style: const TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _cookNow,
              icon: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
              label: const Text("Cook Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
