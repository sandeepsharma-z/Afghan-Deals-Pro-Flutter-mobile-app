import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../localization/app_language_provider.dart';
import '../services/translation_service.dart';

class TranslatedText extends ConsumerStatefulWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const TranslatedText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  ConsumerState<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends ConsumerState<TranslatedText> {
  late String _translatedText;
  late String _lastLanguage;

  @override
  void initState() {
    super.initState();
    _translatedText = widget.text;
    _lastLanguage = 'en';
    _updateTranslation();
  }

  void _updateTranslation() async {
    final currentLocale = ref.read(appLanguageProvider);
    final languageCode = currentLocale.languageCode;

    if (languageCode == 'en' || widget.text.isEmpty) {
      setState(() => _translatedText = widget.text);
      return;
    }

    if (languageCode == _lastLanguage) return;

    final translated = await TranslationService.translate(
      widget.text,
      targetLanguage: languageCode,
    );

    if (mounted) {
      setState(() {
        _translatedText = translated;
        _lastLanguage = languageCode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(appLanguageProvider);
    final languageCode = currentLocale.languageCode;

    if (languageCode != _lastLanguage) {
      _updateTranslation();
    }

    return Text(
      _translatedText,
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}
