import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/cooked_history_entry.dart';
import '../models/recipe_detail.dart';
import 'recipe_detail_screen.dart';

class CookedHistoryScreen extends StatefulWidget {
  const CookedHistoryScreen({super.key});

  @override
  State<CookedHistoryScreen> createState() => _CookedHistoryScreenState();
}

class _CookedHistoryScreenState extends State<CookedHistoryScreen> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await CookedHistoryStore.load();
    if (mounted) setState(() => _loaded = true);
  }

  void _openRecipe(BuildContext context, CookedHistoryEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipe: RecipeDetail.forName(entry.name)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.darkGreen)),
      );
    }

    final entries = CookedHistoryStore.entries;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _statsCard(),
                  const SizedBox(height: 16),
                  const Text(
                    "All cooked recipes — tap to view or cook again",
                    style: TextStyle(color: AppColors.textGray, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  if (entries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text("Nothing cooked yet", style: TextStyle(color: AppColors.textGray)),
                      ),
                    )
                  else
                    for (final entry in entries) ...[
                      _recipeCard(context, entry),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 48, 12, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
              child: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
            ),
          ),
          const Expanded(
            child: Text(
              "Cooked Recipes",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Outfit",
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _statsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.restaurant_menu, color: AppColors.darkGreen, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${CookedHistoryStore.totalMealsCooked}",
                  style: const TextStyle(fontFamily: "Outfit", fontWeight: FontWeight.w800, fontSize: 24, color: AppColors.textDark),
                ),
                const Text("Total meals cooked", style: TextStyle(color: AppColors.textGray, fontSize: 12)),
                Text(
                  "${CookedHistoryStore.uniqueRecipes} unique recipes",
                  style: const TextStyle(color: AppColors.textGray, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${CookedHistoryStore.totalCalories}",
                style: const TextStyle(fontFamily: "Outfit", fontWeight: FontWeight.w800, fontSize: 22, color: AppColors.textDark),
              ),
              const Text("total calories", style: TextStyle(color: AppColors.textGray, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recipeCard(BuildContext context, CookedHistoryEntry entry) {
    return GestureDetector(
      onTap: () => _openRecipe(context, entry),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: AppColors.chipGreenBg, borderRadius: BorderRadius.circular(999)),
                    alignment: Alignment.center,
                    child: Text(
                      "Cooked ${entry.timesCooked}×",
                      style: const TextStyle(color: AppColors.chipGreenText, fontSize: 9, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  const Spacer(),
                  Text(entry.lastCookedLabel, style: const TextStyle(color: AppColors.textGray, fontSize: 11)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.name, style: const TextStyle(color: AppColors.textDark, fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 10, color: AppColors.textGray),
                            const SizedBox(width: 4),
                            Text(entry.time, style: const TextStyle(color: AppColors.textGray, fontSize: 11)),
                            const SizedBox(width: 12),
                            Text("${entry.calories} cal", style: const TextStyle(color: AppColors.textGray, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(999)),
                    child: const Icon(Icons.restaurant, size: 14, color: AppColors.darkGreen),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.deductionSummary,
                      style: const TextStyle(color: AppColors.textGray, fontSize: 11),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openRecipe(context, entry),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.replay, size: 12, color: AppColors.darkGreen),
                        SizedBox(width: 4),
                        Text("Cook Again", style: TextStyle(color: AppColors.darkGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
