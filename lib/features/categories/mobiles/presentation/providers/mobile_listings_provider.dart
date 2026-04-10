import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../features/listings/data/models/mobile_listing_model.dart';

Future<List<String>> _distinctMobileCategoryDataValues(String key) async {
  final response = await Supabase.instance.client
      .from('listings')
      .select('category_data')
      .eq('category', 'mobiles')
      .eq('subcategory', 'mobile-phones')
      .eq('is_active', true);

  final values = (response as List<dynamic>)
      .map((e) {
        final cd =
            (e as Map<String, dynamic>)['category_data'] as Map<String, dynamic>? ??
                {};
        return cd[key]?.toString().trim() ?? '';
      })
      .where((v) => v.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  return values;
}

/// All mobile listings (category = 'mobiles')
final mobileListingsProvider =
    FutureProvider.autoDispose<List<MobileListingModel>>((ref) async {
  final response = await Supabase.instance.client
      .from('listings')
      .select()
      .eq('category', 'mobiles')
      .eq('subcategory', 'mobile-phones')
      .eq('is_active', true)
      .order('created_at', ascending: false);

  return (response as List<dynamic>)
      .map((e) => MobileListingModel.fromMap(e as Map<String, dynamic>))
      .toList();
});

/// Mobile listings filtered by brand
final mobileListingsByBrandProvider =
    FutureProvider.autoDispose.family<List<MobileListingModel>, String>(
        (ref, brand) async {
  final response = await Supabase.instance.client
      .from('listings')
      .select()
      .eq('category', 'mobiles')
      .eq('subcategory', 'mobile-phones')
      .eq('is_active', true)
      .order('created_at', ascending: false);

  final all = (response as List<dynamic>)
      .map((e) => MobileListingModel.fromMap(e as Map<String, dynamic>))
      .toList();

  if (brand.isEmpty || brand == 'All') return all;
  return all
      .where((m) => m.brand.toLowerCase() == brand.toLowerCase())
      .toList();
});

/// Distinct models for a given brand from mobile listings
final mobileModelsByBrandProvider =
    FutureProvider.autoDispose.family<List<String>, String>((ref, brand) async {
  final response = await Supabase.instance.client
      .from('listings')
      .select('category_data')
      .eq('category', 'mobiles')
      .eq('subcategory', 'mobile-phones')
      .eq('is_active', true);

  final models = (response as List<dynamic>)
      .map((e) {
        final cd = (e as Map<String, dynamic>)['category_data'] as Map<String, dynamic>? ?? {};
        return (
          brand: cd['brand']?.toString().trim() ?? '',
          model: cd['model']?.toString().trim() ?? '',
        );
      })
      .where((r) => r.brand.toLowerCase() == brand.toLowerCase() && r.model.isNotEmpty)
      .map((r) => r.model)
      .toSet()
      .toList()
    ..sort();
  return models;
});

/// Distinct brands from mobile listings
final mobileFilterBrandsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  return _distinctMobileCategoryDataValues('brand');
});

/// Distinct conditions from mobile listings
final mobileConditionsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final response = await Supabase.instance.client
      .from('listings')
      .select('category_data')
      .eq('category', 'mobiles')
      .eq('subcategory', 'mobile-phones')
      .eq('is_active', true);

  final conditions = (response as List<dynamic>)
      .map((e) {
        final cd = (e as Map<String, dynamic>)['category_data'] as Map<String, dynamic>? ?? {};
        return cd['condition']?.toString().trim() ?? '';
      })
      .where((c) => c.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return conditions;
});

/// Distinct seller types from mobile listings
final mobileSellerTypesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final response = await Supabase.instance.client
      .from('listings')
      .select('category_data')
      .eq('category', 'mobiles')
      .eq('subcategory', 'mobile-phones')
      .eq('is_active', true);

  final sellerTypes = (response as List<dynamic>)
      .map((e) {
        final cd =
            (e as Map<String, dynamic>)['category_data'] as Map<String, dynamic>? ??
                {};
        return cd['seller_type']?.toString().trim() ?? '';
      })
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return sellerTypes;
});

/// Distinct ages from mobile listings
final mobileAgesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  return _distinctMobileCategoryDataValues('age');
});

/// Distinct warranties from mobile listings
final mobileWarrantiesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final raw = await _distinctMobileCategoryDataValues('warranty');
  final normalized = <String>{};

  for (final item in raw) {
    final v = item.trim().toLowerCase();
    if (v.isEmpty) continue;

    if (v == 'yes' ||
        v == 'under warranty' ||
        v.contains('month') ||
        v.contains('year')) {
      normalized.add('Yes');
      continue;
    }

    if (v == 'no' || v == 'no warranty') {
      normalized.add('No');
      continue;
    }

    if (v == 'does not apply' || v == 'n/a' || v == 'na') {
      normalized.add('Does not apply');
      continue;
    }
  }

  if (normalized.isEmpty) {
    return const ['Yes', 'No', 'Does not apply'];
  }

  const ordered = ['Yes', 'No', 'Does not apply'];
  return ordered.where(normalized.contains).toList();
});

/// Distinct screen sizes from mobile listings
final mobileScreenSizesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  return _distinctMobileCategoryDataValues('screen_size');
});

/// Distinct damage details from mobile listings
final mobileDamageDetailsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  return _distinctMobileCategoryDataValues('damage_details');
});

/// Distinct battery health values from mobile listings
final mobileBatteryHealthsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  return _distinctMobileCategoryDataValues('battery_health');
});

/// Distinct versions from mobile listings
final mobileVersionsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  return _distinctMobileCategoryDataValues('version');
});

/// Distinct storage values from mobile listings
final mobileStoragesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  return _distinctMobileCategoryDataValues('storage');
});

/// Distinct colors from mobile listings
final mobileColorsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  return _distinctMobileCategoryDataValues('color');
});

/// Distinct cities from mobile listings
final mobileCitiesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final response = await Supabase.instance.client
      .from('listings')
      .select('city')
      .eq('category', 'mobiles')
      .eq('subcategory', 'mobile-phones')
      .eq('is_active', true);

  final cities = (response as List<dynamic>)
      .map((e) => (e as Map<String, dynamic>)['city']?.toString().trim() ?? '')
      .where((c) => c.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return cities;
});
