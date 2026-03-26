import 'package:hive_flutter/hive_flutter.dart';
import '../../features/history/domain/models/meal_log.dart';

class MealStorageService {
  static const String _boxName = 'meal_logs';
  static bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    // Asumsikan Hive.initFlutter() sudah dipanggil di main.dart
    Hive.registerAdapter(MealLogAdapter());
    await Hive.openBox<MealLog>(_boxName);
    _isInitialized = true;
  }

  Future<void> saveMeal(MealLog meal) async {
    if (!_isInitialized) await init();
    final box = Hive.box<MealLog>(_boxName);
    await box.put(meal.id, meal);
  }

  Future<List<MealLog>> getMeals() async {
    if (!_isInitialized) await init();
    final box = Hive.box<MealLog>(_boxName);
    // Sort descending by date
    final list = box.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> deleteMeal(String id) async {
    if (!_isInitialized) await init();
    final box = Hive.box<MealLog>(_boxName);
    await box.delete(id);
  }
}
