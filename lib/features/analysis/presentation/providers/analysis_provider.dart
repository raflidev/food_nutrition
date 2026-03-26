import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/meal_info.dart';
import '../../domain/models/nutrition_info.dart';
import '../../../../services/api/gemini_service.dart';
import '../../../../services/api/mealdb_api.dart';

class AnalysisState {
  final bool isLoading;
  final MealInfo? mealInfo;
  final NutritionInfo? nutritionInfo;
  final String? error;

  AnalysisState({
    this.isLoading = true, 
    this.mealInfo, 
    this.nutritionInfo, 
    this.error
  });
}

class AnalysisNotifier extends Notifier<AnalysisState> {
  @override
  AnalysisState build() => AnalysisState();

  Future<void> loadAnalysis(String foodName, String geminiApiKey) async {
    state = AnalysisState(isLoading: true);
    
    try {
      final mealApi = MealDbApi();
      final geminiApi = GeminiService(geminiApiKey);

      // Fetch parallel
      final results = await Future.wait([
        mealApi.searchMeal(foodName),
        geminiApi.getNutritionInfo(foodName),
      ]);

      state = AnalysisState(
        isLoading: false,
        mealInfo: results[0] as MealInfo?,
        nutritionInfo: results[1] as NutritionInfo?,
      );
    } catch (e) {
      state = AnalysisState(isLoading: false, error: e.toString());
    }
  }
}

final analysisProvider = NotifierProvider<AnalysisNotifier, AnalysisState>(() {
  return AnalysisNotifier();
});
