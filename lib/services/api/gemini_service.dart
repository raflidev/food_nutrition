import 'dart:convert';
import 'dart:io';
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
      return null;
    } on SocketException {
      debugPrint("Gemini: no internet connection");
      throw GeminiException('Tidak ada koneksi internet. Periksa jaringan Anda.');
    } on GenerativeAIException catch (e) {
      debugPrint("Gemini GenerativeAIException: $e");
      throw GeminiException(_parseGeminiError(e.toString()));
    } catch (e) {
      debugPrint("Gemini unknown error: $e");
      final msg = e.toString().toLowerCase();
      if (msg.contains('socketexception') || msg.contains('connection') || msg.contains('network')) {
        throw GeminiException('Tidak ada koneksi internet. Periksa jaringan Anda.');
      }
      if (msg.contains('api_key') || msg.contains('api key') || msg.contains('invalid_argument') || msg.contains('unauthenticated')) {
        throw GeminiException('API Key Gemini tidak valid. Periksa kembali API Key Anda.');
      }
      throw GeminiException('Gemini gagal: ${e.toString()}');
    }
  }

  String _parseGeminiError(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('api_key_invalid') ||
        lower.contains('api key') ||
        lower.contains('unauthenticated') ||
        lower.contains('invalid_argument')) {
      return 'API Key Gemini tidak valid. Periksa kembali API Key Anda.';
    }
    if (lower.contains('quota') || lower.contains('resource_exhausted')) {
      return 'Kuota Gemini API habis. Coba lagi nanti.';
    }
    if (lower.contains('permission_denied')) {
      return 'Akses Gemini API ditolak. Pastikan API Key memiliki izin yang benar.';
    }
    if (lower.contains('not_found') || lower.contains('model')) {
      return 'Model Gemini tidak ditemukan. Hubungi pengembang.';
    }
    if (lower.contains('deadline_exceeded') || lower.contains('timeout')) {
      return 'Permintaan ke Gemini timeout. Coba lagi.';
    }
    if (lower.contains('unavailable') || lower.contains('internal')) {
      return 'Server Gemini sedang bermasalah. Coba lagi nanti.';
    }
    return 'Gemini error: $error';
  }
}

class GeminiException implements Exception {
  final String message;
  const GeminiException(this.message);

  @override
  String toString() => message;
}
