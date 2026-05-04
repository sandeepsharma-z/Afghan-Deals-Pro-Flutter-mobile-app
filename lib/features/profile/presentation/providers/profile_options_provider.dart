import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _fallbackCountries = [
  'Afghanistan',
  'Oman',
  'UAE',
  'Qatar',
  'KSA',
  'Syria',
];

const _fallbackLanguagesByCountry = {
  'Afghanistan': ['Pashto', 'Dari (Persian)', 'English'],
  'Oman': ['Arabic', 'English'],
  'UAE': ['Arabic', 'English', 'Hindi', 'Urdu'],
  'Qatar': ['Arabic', 'English'],
  'KSA': ['Arabic', 'English'],
  'Syria': ['Arabic', 'Kurdish', 'English'],
};

const _fallbackGenders = ['Male', 'Female'];

Future<List<String>> _profileFilterOptions(String type) async {
  try {
    final response = await Supabase.instance.client
        .from('filter_options')
        .select('value')
        .eq('category', 'profile')
        .eq('filter_type', type)
        .eq('is_active', true)
        .order('sort_order');

    return (response as List<dynamic>)
        .map((e) =>
            (e as Map<String, dynamic>)['value']?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  } catch (_) {
    return const [];
  }
}

Future<String?> _defaultCountryFromSettings() async {
  final client = Supabase.instance.client;
  try {
    final response = await client
        .from('app_settings')
        .select('default_country')
        .eq('id', 1)
        .maybeSingle();
    final value = response?['default_country']?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  } catch (_) {}

  try {
    final response = await client
        .from('app_settings')
        .select('setting_value')
        .eq('category', 'general')
        .eq('setting_key', 'default_country')
        .maybeSingle();
    final value = response?['setting_value']?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  } catch (_) {}

  return null;
}

final profileCountriesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final countries = <String>[];

  final defaultCountry = await _defaultCountryFromSettings();
  if (defaultCountry != null) countries.add(defaultCountry);

  try {
    final response = await Supabase.instance.client
        .from('regions')
        .select('country')
        .eq('is_active', true)
        .order('sort_order');
    countries.addAll((response as List<dynamic>)
        .map((e) =>
            (e as Map<String, dynamic>)['country']?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty));
  } catch (_) {}

  final adminOptions = await _profileFilterOptions('country');
  countries.addAll(adminOptions);
  countries.addAll(_fallbackCountries);

  return countries.toSet().toList();
});

final profileLanguagesProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, country) async {
  final adminOptions = await _profileFilterOptions('language');
  if (adminOptions.isNotEmpty) return adminOptions;
  return _fallbackLanguagesByCountry[country] ?? const ['English'];
});

final profileGendersProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final adminOptions = await _profileFilterOptions('gender');
  if (adminOptions.isNotEmpty) return adminOptions;
  return _fallbackGenders;
});

final profileNationalitiesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final adminOptions = await _profileFilterOptions('nationality');
  if (adminOptions.isNotEmpty) return adminOptions;
  return ref.watch(profileCountriesProvider.future);
});
