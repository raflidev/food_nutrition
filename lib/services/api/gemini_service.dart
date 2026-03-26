import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../features/analysis/domain/models/nutrition_info.dart';

class GeminiService {
  final GenerativeModel _model;

  GeminiService(String apiKey) 
      : _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

  Future<NutritionInfo?> getNutritionInfo(String foodName) async {
    final prompt = '''
Berikan informasi nutrisi estimasi untuk 1 porsi "$foodName" dalam format JSON statis.
KEMBALIKAN HANYA OBJEK JSON MURNI. Tanpa tag markdown, tanpa teks pembuka/penutup.
Gunakan struktur key berikut (value berupa string berakhiran unit, misal "g" atau "kcal"):
{
  "kalori": "250 kcal",
  "karbohidrat": "30g",
  "lemak": "10g",
  "serat": "5g",
  "protein": "15g"
}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;
      
      if (text != null) {
        // Membersihkan markdown fences apabila Gemini tetap merespons dengan format tersebut
        var cleanText = text.trim();
        if (cleanText.startsWith('```json')) {
          cleanText = cleanText.substring(7);
        } else if (cleanText.startsWith('```')) {
          cleanText = cleanText.substring(3);
        }
        if (cleanText.endsWith('```')) {
          cleanText = cleanText.substring(0, cleanText.length - 3);
        }
        
        final jsonMap = json.decode(cleanText.trim()) as Map<String, dynamic>;
        return NutritionInfo.fromJson(jsonMap);
      }
    } catch (e) {
      debugPrint("Gemini API Error: $e");
    }
    return null;
  }
}
