class NutritionInfo {
  final String calories;
  final String carbohydrates;
  final String fat;
  final String fiber;
  final String protein;

  const NutritionInfo({
    this.calories = '-',
    this.carbohydrates = '-',
    this.fat = '-',
    this.fiber = '-',
    this.protein = '-',
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      calories: json['kalori']?.toString() ?? '-',
      carbohydrates: json['karbohidrat']?.toString() ?? '-',
      fat: json['lemak']?.toString() ?? '-',
      fiber: json['serat']?.toString() ?? '-',
      protein: json['protein']?.toString() ?? '-',
    );
  }

  Map<String, dynamic> toJson() => {
    'kalori': calories,
    'karbohidrat': carbohydrates,
    'lemak': fat,
    'serat': fiber,
    'protein': protein,
  };
}
