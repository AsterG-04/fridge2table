class Recipe {

  final String name;

  Recipe({
    required this.name,
  });

  factory Recipe.fromJson(
      dynamic json) {

    return Recipe(
      name: json.toString(),
    );

  }

}