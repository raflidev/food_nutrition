import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/meal_log.dart';
import '../../../../services/storage/meal_storage.dart';
import '../../../../services/storage/meal_extras_storage.dart';

class HistoryNotifier extends AsyncNotifier<List<MealLog>> {
  final _service = MealStorageService();

  @override
  Future<List<MealLog>> build() async {
    return _service.getMeals();
  }

  Future<void> addMeal(MealLog meal) async {
    await _service.saveMeal(meal);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.getMeals());
  }

  Future<void> deleteMeal(String id) async {
    await _service.deleteMeal(id);
    await MealExtrasStorageService().deleteExtras(id);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.getMeals());
  }
}

final historyProvider = AsyncNotifierProvider<HistoryNotifier, List<MealLog>>(() {
  return HistoryNotifier();
});
