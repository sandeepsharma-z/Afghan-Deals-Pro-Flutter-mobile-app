import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/translation_service.dart';

final translationCacheProvider = FutureProvider.family<String, _TranslationParams>((ref, params) async {
  if (params.text.isEmpty || params.targetLanguage == 'en') {
    return params.text;
  }

  return await TranslationService.translate(
    params.text,
    targetLanguage: params.targetLanguage,
    sourceLanguage: params.sourceLanguage,
  );
});

class _TranslationParams {
  final String text;
  final String targetLanguage;
  final String sourceLanguage;

  _TranslationParams({
    required this.text,
    required this.targetLanguage,
    this.sourceLanguage = 'en',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TranslationParams &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          targetLanguage == other.targetLanguage &&
          sourceLanguage == other.sourceLanguage;

  @override
  int get hashCode => text.hashCode ^ targetLanguage.hashCode ^ sourceLanguage.hashCode;
}
