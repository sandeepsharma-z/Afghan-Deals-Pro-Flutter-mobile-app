import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TranslationService {
  static const String _googleBaseUrl =
      'https://translate.googleapis.com/translate_a/single';
  static const String _libreBaseUrl = 'https://translate.argosopentech.com/translate';
  static final Map<String, String> _memoryCache = <String, String>{};

  static const Map<String, String> _languageCodes = {
    'en': 'en',
    'ps': 'ps',
    'fa': 'fa',
    'ur': 'ur',
  };

  static Future<String> translate(
    String text, {
    required String targetLanguage,
    String sourceLanguage = 'auto',
  }) async {
    final input = text.trim();
    if (input.isEmpty) return text;
    if (targetLanguage == 'en') return text;

    final targetCode = _languageCodes[targetLanguage] ?? 'en';
    final sourceCode = sourceLanguage == 'auto'
        ? 'auto'
        : (_languageCodes[sourceLanguage] ?? sourceLanguage);
    final cacheKey = '$sourceCode|$targetCode|$input';

    final cached = _memoryCache[cacheKey];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final prefs = await SharedPreferences.getInstance();
    final persisted = prefs.getString('translation::$cacheKey');
    if (persisted != null && persisted.isNotEmpty) {
      _memoryCache[cacheKey] = persisted;
      return persisted;
    }

    try {
      final googleUri = Uri.parse(_googleBaseUrl).replace(
        queryParameters: {
          'client': 'gtx',
          'sl': sourceCode,
          'tl': targetCode,
          'dt': 't',
          'q': input,
        },
      );
      final googleResponse = await http.get(googleUri).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw Exception('Google translation timeout'),
      );
      if (googleResponse.statusCode == 200) {
        final translated =
            _parseGoogleTranslation(utf8.decode(googleResponse.bodyBytes));
        if (translated.isNotEmpty) {
          _memoryCache[cacheKey] = translated;
          await prefs.setString('translation::$cacheKey', translated);
          return translated;
        }
      }
    } catch (e) {
      debugPrint('Google translation error: $e');
    }

    try {
      final libreResponse = await http.post(
        Uri.parse(_libreBaseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'q': input,
          'source': sourceCode == 'auto' ? 'en' : sourceCode,
          'target': targetCode,
          'format': 'text',
        }),
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw Exception('LibreTranslate timeout'),
      );

      if (libreResponse.statusCode == 200) {
        final result = jsonDecode(utf8.decode(libreResponse.bodyBytes));
        final translated = (result['translatedText'] ?? '').toString().trim();
        if (translated.isNotEmpty) {
          _memoryCache[cacheKey] = translated;
          await prefs.setString('translation::$cacheKey', translated);
          return translated;
        }
      }
    } catch (e) {
      debugPrint('LibreTranslate error: $e');
    }

    return text;
  }

  static String _parseGoogleTranslation(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! List || decoded.isEmpty || decoded.first is! List) {
      return '';
    }

    final buffer = StringBuffer();
    for (final chunk in decoded.first as List<dynamic>) {
      if (chunk is List && chunk.isNotEmpty && chunk.first is String) {
        buffer.write(chunk.first as String);
      }
    }
    return buffer.toString().trim();
  }
}

final translationServiceProvider = Provider((ref) => TranslationService());
