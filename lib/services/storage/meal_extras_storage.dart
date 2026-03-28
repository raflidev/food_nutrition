import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/analysis/domain/models/nutrition_info.dart';
import '../../features/analysis/domain/models/meal_info.dart';

class MealExtrasStorageService {
  static const String _boxName = 'meal_extras';
  static bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    await Hive.openBox<String>(_boxName);
    _isInitialized = true;
  }

  Future<void> saveExtras(
    String mealId,
    NutritionInfo? nutrition,
    MealInfo? meal,
  ) async {
    if (!_isInitialized) await init();
    final box = Hive.box<String>(_boxName);
    final map = <String, dynamic>{};
    if (nutrition != null) map['nutrition'] = nutrition.toJson();
    if (meal != null) map['meal'] = meal.toJson();
    if (map.isNotEmpty) await box.put(mealId, jsonEncode(map));
  }

  ({NutritionInfo? nutrition, MealInfo? meal}) loadExtras(String mealId) {
    if (!_isInitialized) return (nutrition: null, meal: null);
    final box = Hive.box<String>(_boxName);
    final raw = box.get(mealId);
    if (raw == null) return (nutrition: null, meal: null);
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final nutrition = map['nutrition'] != null
          ? NutritionInfo.fromJson(map['nutrition'] as Map<String, dynamic>)
          : null;
      final meal = map['meal'] != null
          ? MealInfo.fromMap(map['meal'] as Map<String, dynamic>)
          : null;
      return (nutrition: nutrition, meal: meal);
    } catch (_) {
      return (nutrition: null, meal: null);
    }
  }

  Future<void> deleteExtras(String mealId) async {
    if (!_isInitialized) await init();
    final box = Hive.box<String>(_boxName);
    await box.delete(mealId);
  }
}
