import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TranslationService {
  static const String _baseUrl = 'https://libretranslate.de/translate';

  static const Map<String, String> _languageCodes = {
    'en': 'en',
    'ps': 'ps',
    'fa': 'fa',
    'ur': 'ur',
  };

  static Future<String> translate(
    String text, {
    required String targetLanguage,
    String sourceLanguage = 'en',
  }) async {
    if (text.isEmpty) return text;
    if (targetLanguage == 'en') return text;

    try {
      final targetCode = _languageCodes[targetLanguage] ?? 'en';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'q': text,
          'source': sourceLanguage,
          'target': targetCode,
        }),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Translation timeout'),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['translatedText'] ?? text;
      }
    } catch (e) {
      debugPrint('Translation error: $e');
    }
    return text;
  }
}

final translationServiceProvider = Provider((ref) => TranslationService());
