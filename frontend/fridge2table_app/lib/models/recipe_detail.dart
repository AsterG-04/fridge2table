class RecipeIngredientDetail {
  final String name;
  final String initials;
  final String quantity;
  final bool missing;

  const RecipeIngredientDetail({
    required this.name,
    required this.initials,
    required this.quantity,
    this.missing = false,
  });
}

class NutritionInfo {
  final int calories;
  final String protein;
  final String carbs;
  final String fat;

  const NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

class CookingStep {
  final String title;
  final String instructions;

  const CookingStep({required this.title, required this.instructions});
}

class RecipeDetail {
  final int? id;
  final String name;
  final String tags;
  final String time;
  final String cookTime;
  final int calories;
  final String difficulty;
  final int matchPercent;
  final String sustainabilityTip;
  final String cuisine;
  final List<RecipeIngredientDetail> ingredients;
  final NutritionInfo nutrition;
  final List<CookingStep> steps;

  /// Names of this recipe's matched ingredients that are currently expired
  /// / expiring today-or-soon in the user's pantry (from the backend's
  /// /recipes response) — recipe matching itself already considers every
  /// pantry item regardless of freshness, these are purely for the warning
  /// banner/icon so a stale ingredient doesn't get used unnoticed.
  final List<String> expiredIngredients;
  final List<String> expiringIngredients;

  const RecipeDetail({
    this.id,
    required this.name,
    required this.tags,
    required this.time,
    required this.cookTime,
    required this.calories,
    required this.difficulty,
    required this.matchPercent,
    required this.sustainabilityTip,
    required this.cuisine,
    required this.ingredients,
    required this.nutrition,
    required this.steps,
    this.expiredIngredients = const [],
    this.expiringIngredients = const [],
  });

  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s
        .split(RegExp(r"\s+"))
        .map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1);
        })
        .join(" ");
  }

  static String _initialsFor(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return "?";
    final words = trimmed.split(RegExp(r"\s+"));
    if (words.length == 1) {
      return words[0].substring(0, words[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  /// Builds a recipe detail directly from the backend's /recipes response,
  /// which already includes the full recipe (steps, nutrition, cook_time,
  /// sustainability_tip, cuisine) merged with match_score/matched_ingredients
  /// for the current pantry.
  factory RecipeDetail.fromJson(Map<String, dynamic> json) {
    final ingredientNames = (json["ingredients"] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    final matched = (json["matched_ingredients"] as List? ?? [])
        .map((e) => e.toString().toLowerCase())
        .toSet();
    final dietTags = (json["diet_tags"] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    final stepsList = (json["steps"] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    final nutritionJson = json["nutrition"] as Map<String, dynamic>? ?? {};
    final cuisine = json["cuisine"]?.toString() ?? "";

    return RecipeDetail(
      id: json["id"] is int ? json["id"] as int : null,
      name: json["name"]?.toString() ?? "",
      tags: dietTags.isNotEmpty
          ? dietTags.join(" · ")
          : (cuisine.isNotEmpty ? cuisine : "Recipe"),
      time: json["prep_time"]?.toString() ?? "20 min",
      cookTime: json["cook_time"]?.toString() ?? "—",
      calories: nutritionJson["calories"] is int
          ? nutritionJson["calories"] as int
          : 0,
      difficulty: json["difficulty"]?.toString() ?? "Easy",
      matchPercent: json["match_score"] is int ? json["match_score"] as int : 0,
      sustainabilityTip: json["sustainability_tip"]?.toString() ?? "",
      cuisine: cuisine,
      ingredients: [
        for (final ingredientName in ingredientNames)
          RecipeIngredientDetail(
            name: _titleCase(ingredientName),
            initials: _initialsFor(ingredientName),
            quantity: "as needed",
            missing: !matched.contains(ingredientName.toLowerCase()),
          ),
      ],
      nutrition: NutritionInfo(
        calories: nutritionJson["calories"] is int
            ? nutritionJson["calories"] as int
            : 0,
        protein: nutritionJson["protein"]?.toString() ?? "—",
        carbs: nutritionJson["carbs"]?.toString() ?? "—",
        fat: nutritionJson["fat"]?.toString() ?? "—",
      ),
      steps: [
        for (int i = 0; i < stepsList.length; i++)
          CookingStep(title: "Step ${i + 1}", instructions: stepsList[i]),
      ],
      expiredIngredients: (json["expired_ingredients"] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      expiringIngredients: (json["expiring_ingredients"] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  /// Fallback for places that only know a recipe's name (e.g. Cooked
  /// History's "Cook Again", where the original full recipe payload isn't
  /// retained) — not real recipe data, just enough to not crash the screen.
  factory RecipeDetail.forName(String name, {int matchPercent = 80}) {
    return RecipeDetail(
      name: name,
      tags: "Recipe",
      time: "20 min",
      cookTime: "—",
      calories: 0,
      difficulty: "Medium",
      matchPercent: matchPercent,
      sustainabilityTip: "",
      cuisine: "",
      ingredients: const [],
      nutrition: const NutritionInfo(
        calories: 0,
        protein: "—",
        carbs: "—",
        fat: "—",
      ),
      steps: const [
        CookingStep(
          title: "Step 1",
          instructions:
              "Full step-by-step data isn't available for this entry — cook using your usual method.",
        ),
      ],
    );
  }
}
