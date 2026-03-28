import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../features/analysis/domain/models/meal_info.dart';

class MealDbApi {
  final Dio _dio = Dio();

  Future<MealInfo?> searchMeal(String foodName) async {
    // Coba beberapa strategi pencarian agar lebih banyak hasil yang cocok
    final queries = _buildSearchQueries(foodName);

    for (final query in queries) {
      try {
        final response = await _dio.get(
          'https://www.themealdb.com/api/json/v1/1/search.php',
          queryParameters: {'s': query},
        );
        if (response.statusCode == 200 && response.data != null) {
          final meals = response.data['meals'];
          if (meals != null && meals is List && meals.isNotEmpty) {
            debugPrint("MealDB found result for query: '$query'");
            return MealInfo.fromJson(meals.first);
          }
        }
      } catch (e) {
        debugPrint("MealDB API Error for query '$query': $e");
      }
    }
    debugPrint("MealDB: no result found for '$foodName'");
    return null;
  }

  List<String> _buildSearchQueries(String foodName) {
    final queries = <String>[];
    // 1. Nama asli
    queries.add(foodName);
    // 2. Kata pertama saja (misal "Ayam masak merah" → "Ayam")
    final words = foodName.trim().split(' ');
    if (words.length > 1) queries.add(words.first);
    // 3. Dua kata pertama
    if (words.length > 2) queries.add('${words[0]} ${words[1]}');
    // 4. Kata terakhir (misal "Chicken Tikka Masala" → "Masala")
    if (words.length > 1) queries.add(words.last);
    return queries.toSet().toList(); // deduplicate
  }
}
