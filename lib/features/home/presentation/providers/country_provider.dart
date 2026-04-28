import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final selectedCountryProvider = StateNotifierProvider<CountryNotifier, String>((ref) {
  return CountryNotifier();
});

class CountryNotifier extends StateNotifier<String> {
  static const _key = 'selected_country';

  CountryNotifier() : super('Afghanistan') {
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key) ?? 'Afghanistan';
      state = saved;
    } catch (_) {
      state = 'Afghanistan';
    }
  }

  Future<void> setCountry(String country) async {
    state = country;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, country);
    } catch (_) {}
  }
}
