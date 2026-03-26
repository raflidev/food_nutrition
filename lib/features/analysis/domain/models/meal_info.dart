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

    // TheMealDB returns strIngredient1 to strIngredient20 
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
}
