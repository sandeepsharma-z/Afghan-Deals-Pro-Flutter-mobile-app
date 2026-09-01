import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/app_auth.dart';

const supportedAppLanguages = <AppLanguage>[
  AppLanguage(name: 'English', nativeName: 'English', code: 'en'),
  AppLanguage(name: 'Pashto', nativeName: 'پښتو', code: 'ps'),
  AppLanguage(name: 'Dari (Persian)', nativeName: 'دری', code: 'fa'),
  AppLanguage(name: 'Urdu', nativeName: 'اردو', code: 'ur'),
];

class AppLanguage {
  final String name;

  /// The language written in its own script, so a reader who knows no English
  /// can still recognise their language.
  final String nativeName;
  final String code;

  const AppLanguage({
    required this.name,
    required this.nativeName,
    required this.code,
  });

  Locale get locale => Locale(code);

  bool get isRtl => code != 'en';
}

class AppLanguageNotifier extends StateNotifier<Locale> {
  AppLanguageNotifier() : super(const Locale('en')) {
    _load();
  }

  // Device-level language preference (persists across logout)
  // This is NOT user-specific, so the selected language remains on device
  // even after logout. This is intentional - device preferences are independent
  // of user authentication state.
  static const _prefKey = 'app_language_code';

  /// True once the user has picked a language themselves. Used to show the
  /// language chooser on first launch, so someone who reads no English never
  /// has to hunt through settings.
  static Future<bool> hasChosenLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey) != null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_prefKey);
    final metaLanguage = AppAuth.currentUserMetadata['language'];
    final code = savedCode ?? codeFromLanguageName(metaLanguage?.toString());
    if (code != null && _isSupported(code)) {
      state = Locale(code);
    }
  }

  Future<void> setLanguageName(String languageName) async {
    final code = codeFromLanguageName(languageName) ?? 'en';
    debugPrint('🌍 Language changed to: $languageName (code: $code)');
    await setLocale(Locale(code));
  }

  Future<void> setLocale(Locale locale) async {
    final code = _isSupported(locale.languageCode) ? locale.languageCode : 'en';
    debugPrint('🌍 Setting locale to: $code');
    state = Locale(code);
    debugPrint('🌍 New locale state: ${state.languageCode}');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);
    debugPrint('🌍 Saved to SharedPreferences: $code');
  }

  static String? codeFromLanguageName(String? languageName) {
    if (languageName == null) return null;
    final normalized = languageName.trim().toLowerCase();
    for (final language in supportedAppLanguages) {
      if (language.name.toLowerCase() == normalized ||
          language.code.toLowerCase() == normalized) {
        return language.code;
      }
    }
    if (normalized.contains('pashto')) return 'ps';
    if (normalized.contains('dari') || normalized.contains('persian')) {
      return 'fa';
    }
    if (normalized.contains('urdu')) return 'ur';
    if (normalized.contains('english')) return 'en';
    return null;
  }

  static String nativeNameFromCode(String code) {
    return supportedAppLanguages
        .firstWhere(
          (language) => language.code == code,
          orElse: () => supportedAppLanguages.first,
        )
        .nativeName;
  }

  static String nameFromCode(String code) {
    return supportedAppLanguages
        .firstWhere(
          (language) => language.code == code,
          orElse: () => supportedAppLanguages.first,
        )
        .name;
  }

  static bool _isSupported(String code) {
    return supportedAppLanguages.any((language) => language.code == code);
  }
}

final appLanguageProvider =
    StateNotifierProvider<AppLanguageNotifier, Locale>((ref) {
  return AppLanguageNotifier();
});
