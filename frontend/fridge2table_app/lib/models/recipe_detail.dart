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
  final String name;
  final String tags;
  final String time;
  final int calories;
  final String difficulty;
  final int matchPercent;
  final String description;
  final List<RecipeIngredientDetail> ingredients;
  final NutritionInfo nutrition;
  final List<CookingStep> steps;

  const RecipeDetail({
    required this.name,
    required this.tags,
    required this.time,
    required this.calories,
    required this.difficulty,
    required this.matchPercent,
    required this.description,
    required this.ingredients,
    required this.nutrition,
    required this.steps,
  });

  static final Map<String, RecipeDetail> _library = {
    "spinach & egg omelette": const RecipeDetail(
      name: "Spinach & Egg Omelette",
      tags: "Vegetarian · Halal · Quick",
      time: "15 min",
      calories: 280,
      difficulty: "Easy",
      matchPercent: 94,
      description: "A quick, protein-rich omelette with fresh spinach.",
      ingredients: [
        RecipeIngredientDetail(name: "Spinach", initials: "SP", quantity: "150 g"),
        RecipeIngredientDetail(name: "Eggs", initials: "EG", quantity: "3 pcs"),
        RecipeIngredientDetail(name: "Olive Oil", initials: "OL", quantity: "2 tbsp"),
        RecipeIngredientDetail(name: "Garlic", initials: "GA", quantity: "2 cloves", missing: true),
        RecipeIngredientDetail(name: "Salt", initials: "SA", quantity: "to taste"),
      ],
      nutrition: NutritionInfo(calories: 280, protein: "22 g", carbs: "8 g", fat: "18 g"),
      steps: [
        CookingStep(title: "Prep eggs", instructions: "Crack 3 eggs into a bowl. Add a pinch of salt and whisk until smooth."),
        CookingStep(title: "Wash spinach", instructions: "Rinse the spinach and roughly chop it."),
        CookingStep(title: "Sauté garlic", instructions: "Heat olive oil and sauté garlic until fragrant."),
        CookingStep(title: "Wilt spinach", instructions: "Add spinach to the pan and cook until wilted."),
        CookingStep(title: "Cook the omelette", instructions: "Pour the eggs over the spinach and cook on low heat until set."),
        CookingStep(title: "Serve", instructions: "Fold the omelette in half and serve warm."),
      ],
    ),
    "tomato basil pasta": const RecipeDetail(
      name: "Tomato Basil Pasta",
      tags: "Vegan · Quick",
      time: "25 min",
      calories: 410,
      difficulty: "Medium",
      matchPercent: 87,
      description: "A simple pasta tossed in a fresh tomato and basil sauce.",
      ingredients: [
        RecipeIngredientDetail(name: "Tomatoes", initials: "TO", quantity: "4 pcs"),
        RecipeIngredientDetail(name: "Pasta", initials: "PA", quantity: "200 g"),
        RecipeIngredientDetail(name: "Basil", initials: "BA", quantity: "a handful"),
        RecipeIngredientDetail(name: "Garlic", initials: "GA", quantity: "2 cloves"),
        RecipeIngredientDetail(name: "Olive Oil", initials: "OL", quantity: "2 tbsp"),
      ],
      nutrition: NutritionInfo(calories: 410, protein: "12 g", carbs: "68 g", fat: "10 g"),
      steps: [
        CookingStep(title: "Boil pasta", instructions: "Cook pasta in salted boiling water until al dente."),
        CookingStep(title: "Make the sauce", instructions: "Sauté garlic, then add chopped tomatoes and simmer."),
        CookingStep(title: "Combine", instructions: "Toss the drained pasta into the sauce."),
        CookingStep(title: "Add basil", instructions: "Stir in fresh basil leaves off the heat."),
        CookingStep(title: "Serve", instructions: "Plate and drizzle with olive oil."),
      ],
    ),
    "chicken stir fry": const RecipeDetail(
      name: "Chicken Stir Fry",
      tags: "Halal · High Protein",
      time: "20 min",
      calories: 390,
      difficulty: "Medium",
      matchPercent: 82,
      description: "A fast weeknight stir fry with chicken and vegetables.",
      ingredients: [
        RecipeIngredientDetail(name: "Chicken Breast", initials: "CH", quantity: "300 g"),
        RecipeIngredientDetail(name: "Bell Pepper", initials: "BE", quantity: "1 pc"),
        RecipeIngredientDetail(name: "Soy Sauce", initials: "SO", quantity: "2 tbsp"),
        RecipeIngredientDetail(name: "Garlic", initials: "GA", quantity: "2 cloves"),
      ],
      nutrition: NutritionInfo(calories: 390, protein: "34 g", carbs: "18 g", fat: "16 g"),
      steps: [
        CookingStep(title: "Slice chicken", instructions: "Cut chicken breast into thin strips."),
        CookingStep(title: "Sear chicken", instructions: "Stir-fry chicken over high heat until browned."),
        CookingStep(title: "Add vegetables", instructions: "Add bell pepper and garlic, stir-fry for 2 minutes."),
        CookingStep(title: "Season", instructions: "Pour in soy sauce and toss to coat."),
        CookingStep(title: "Serve", instructions: "Serve hot over rice."),
      ],
    ),
    "green smoothie bowl": const RecipeDetail(
      name: "Green Smoothie Bowl",
      tags: "Vegan · No Cook",
      time: "10 min",
      calories: 240,
      difficulty: "Easy",
      matchPercent: 76,
      description: "A refreshing no-cook smoothie bowl topped with fruit.",
      ingredients: [
        RecipeIngredientDetail(name: "Spinach", initials: "SP", quantity: "50 g"),
        RecipeIngredientDetail(name: "Banana", initials: "BA", quantity: "1 pc"),
        RecipeIngredientDetail(name: "Milk", initials: "MI", quantity: "200 ml"),
      ],
      nutrition: NutritionInfo(calories: 240, protein: "6 g", carbs: "45 g", fat: "3 g"),
      steps: [
        CookingStep(title: "Blend", instructions: "Blend spinach, banana, and milk until smooth."),
        CookingStep(title: "Pour", instructions: "Pour into a bowl."),
        CookingStep(title: "Top", instructions: "Add your favourite toppings and serve."),
      ],
    ),
  };

  factory RecipeDetail.forName(String name, {int matchPercent = 80}) {
    final found = _library[name.trim().toLowerCase()];
    if (found != null) return found;

    return RecipeDetail(
      name: name,
      tags: "Suggested recipe",
      time: "20 min",
      calories: 350,
      difficulty: "Medium",
      matchPercent: matchPercent,
      description: "A recipe suggested from your pantry ingredients.",
      ingredients: const [
        RecipeIngredientDetail(name: "Main ingredient", initials: "MI", quantity: "as needed"),
      ],
      nutrition: const NutritionInfo(calories: 350, protein: "15 g", carbs: "40 g", fat: "12 g"),
      steps: const [
        CookingStep(title: "Prep ingredients", instructions: "Gather and prepare all ingredients."),
        CookingStep(title: "Cook", instructions: "Cook following your usual method."),
        CookingStep(title: "Serve", instructions: "Plate and serve warm."),
      ],
    );
  }
}
