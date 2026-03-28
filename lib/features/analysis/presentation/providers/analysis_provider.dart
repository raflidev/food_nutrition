import 'package:flutter/foundation.dart';
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
  final String? geminiError;

  AnalysisState({
    this.isLoading = true,
    this.mealInfo,
    this.nutritionInfo,
    this.error,
    this.geminiError,
  });
}

class AnalysisNotifier extends Notifier<AnalysisState> {
  @override
  AnalysisState build() => AnalysisState();

  Future<void> loadMealDbOnly(String foodName) async {
    state = AnalysisState(isLoading: true);
    MealInfo? mealResult;
    try {
      mealResult = await MealDbApi().searchMeal(foodName);
    } catch (e) {
      debugPrint('MealDB error: $e');
    }
    state = AnalysisState(isLoading: false, mealInfo: mealResult);
  }

  Future<void> loadAnalysis(String foodName, String geminiApiKey) async {
    state = AnalysisState(isLoading: true);

    final mealApi = MealDbApi();
    final geminiApi = GeminiService(geminiApiKey);

    MealInfo? mealResult;
    try {
      mealResult = await mealApi.searchMeal(foodName);
    } catch (e) {
      debugPrint('MealDB error: $e');
    }

    NutritionInfo? nutritionResult;
    String? geminiError;
    try {
      nutritionResult = await geminiApi.getNutritionInfo(foodName);
    } catch (e) {
      geminiError = e.toString();
    }

    state = AnalysisState(
      isLoading: false,
      mealInfo: mealResult,
      nutritionInfo: nutritionResult,
      geminiError: geminiError,
    );
  }
}

final analysisProvider = NotifierProvider<AnalysisNotifier, AnalysisState>(() {
  return AnalysisNotifier();
});
