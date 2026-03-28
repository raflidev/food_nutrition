import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

enum GeminiStatus { loading, ready, invalidKey, noKey, networkError, unknownError }

class GeminiStatusInfo {
  final GeminiStatus status;
  final String message;

  const GeminiStatusInfo(this.status, this.message);
}

final geminiStatusProvider = FutureProvider<GeminiStatusInfo>((ref) async {
  const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  if (apiKey.isEmpty) {
    return const GeminiStatusInfo(
      GeminiStatus.noKey,
      'Gemini API Key belum dikonfigurasi',
    );
  }

  try {
    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
    await model.generateContent([Content.text('Reply with just: ok')]);
    return const GeminiStatusInfo(GeminiStatus.ready, 'Gemini AI siap digunakan');
  } on SocketException {
    return const GeminiStatusInfo(
      GeminiStatus.networkError,
      'Tidak ada koneksi internet',
    );
  } on GenerativeAIException catch (e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('api_key_invalid') ||
        msg.contains('api key') ||
        msg.contains('unauthenticated') ||
        msg.contains('invalid_argument')) {
      return const GeminiStatusInfo(
        GeminiStatus.invalidKey,
        'API Key Gemini tidak valid',
      );
    }
    if (msg.contains('quota') || msg.contains('resource_exhausted')) {
      return const GeminiStatusInfo(
        GeminiStatus.ready,
        'Gemini siap (kuota terbatas)',
      );
    }
    return GeminiStatusInfo(GeminiStatus.unknownError, 'Gemini error: ${e.toString()}');
  } catch (e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('socketexception') || msg.contains('network') || msg.contains('connection')) {
      return const GeminiStatusInfo(GeminiStatus.networkError, 'Tidak ada koneksi internet');
    }
    if (msg.contains('api_key') || msg.contains('unauthenticated')) {
      return const GeminiStatusInfo(GeminiStatus.invalidKey, 'API Key Gemini tidak valid');
    }
    return GeminiStatusInfo(GeminiStatus.unknownError, 'Gemini tidak tersedia');
  }
});
