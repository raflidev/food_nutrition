class MealInfo {
  final String name;
  final String? thumbUrl;
  final String? instructions;
  final List<String> ingredients;
  final List<String> measures;

  const MealInfo({
    required this.name,
    this.thumbUrl,
    this.instructions,
    this.ingredients = const [],
    this.measures = const [],
  });

  factory MealInfo.fromJson(Map<String, dynamic> json) {
    List<String> foundIngredients = [];
    List<String> foundMeasures = [];

    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i'];
      final measure = json['strMeasure$i'];

      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        foundIngredients.add(ingredient);
        if (measure != null && measure.toString().trim().isNotEmpty) {
          foundMeasures.add(measure);
        } else {
          foundMeasures.add("");
        }
      }
    }

    return MealInfo(
      name: json['strMeal'] ?? 'Unknown',
      thumbUrl: json['strMealThumb'],
      instructions: json['strInstructions'],
      ingredients: foundIngredients,
      measures: foundMeasures,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'thumbUrl': thumbUrl,
    'instructions': instructions,
    'ingredients': ingredients,
    'measures': measures,
  };

  factory MealInfo.fromMap(Map<String, dynamic> map) => MealInfo(
    name: map['name'] as String? ?? 'Unknown',
    thumbUrl: map['thumbUrl'] as String?,
    instructions: map['instructions'] as String?,
    ingredients: List<String>.from(map['ingredients'] as List? ?? []),
    measures: List<String>.from(map['measures'] as List? ?? []),
  );
}
