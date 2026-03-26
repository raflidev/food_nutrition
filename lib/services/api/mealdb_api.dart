import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../features/analysis/domain/models/meal_info.dart';

class MealDbApi {
  final Dio _dio = Dio();

  Future<MealInfo?> searchMeal(String foodName) async {
    try {
      final response = await _dio.get(
        'https://www.themealdb.com/api/json/v1/1/search.php',
        queryParameters: {'s': foodName},
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final meals = response.data['meals'];
        if (meals != null && meals is List && meals.isNotEmpty) {
          return MealInfo.fromJson(meals.first);
        }
      }
    } catch (e) {
      debugPrint("MealDB API Error: $e");
    }
    return null;
  }
}
