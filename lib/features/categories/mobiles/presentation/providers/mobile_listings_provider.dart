import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../features/listings/data/models/mobile_listing_model.dart';
import '../../../../admin/presentation/providers/admin_dynamic_provider.dart';

String _slugForMobileBrand(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

bool _matchesMobileBrand(MobileListingModel listing, String brand) {
  final brandKey = brand.trim().toLowerCase();
  final brandSlug = _slugForMobileBrand(brand);
  if (brandKey.isEmpty || brandKey == 'all') return true;

  return listing.brand.toLowerCase() == brandKey ||
      listing.subcategory.toLowerCase() == brandSlug;
}

Future<List<String>> _distinctMobileCategoryDataValues(String key) async {
  final response = await Supabase.instance.client
      .from('listings')
      .select('category_data')
      .eq('category', 'mobiles')
      .eq('is_active', true);

  final values = (response as List<dynamic>)
      .map((e) {
        final cd = (e as Map<String, dynamic>)['category_data']
                as Map<String, dynamic>? ??
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
      .eq('is_active', true)
      .order('created_at', ascending: false);

  return (response as List<dynamic>)
      .map((e) => MobileListingModel.fromMap(e as Map<String, dynamic>))
      .toList();
});

/// Mobile listings filtered by brand
final mobileListingsByBrandProvider = FutureProvider.autoDispose
    .family<List<MobileListingModel>, String>((ref, brand) async {
  final response = await Supabase.instance.client
      .from('listings')
      .select()
      .eq('category', 'mobiles')
      .eq('is_active', true)
      .order('created_at', ascending: false);

  final all = (response as List<dynamic>)
      .map((e) => MobileListingModel.fromMap(e as Map<String, dynamic>))
      .toList();

  if (brand.isEmpty || brand == 'All') return all;
  return all.where((m) => _matchesMobileBrand(m, brand)).toList();
});

/// Distinct models for a given brand from mobile listings
final mobileModelsByBrandProvider =
    FutureProvider.autoDispose.family<List<String>, String>((ref, brand) async {
  final response = await Supabase.instance.client
      .from('listings')
      .select('category_data')
      .eq('category', 'mobiles')
      .eq('is_active', true);

  final models = (response as List<dynamic>)
      .map((e) {
        final cd = (e as Map<String, dynamic>)['category_data']
                as Map<String, dynamic>? ??
            {};
        return (
          brand: cd['brand']?.toString().trim() ?? '',
          model: cd['model']?.toString().trim() ?? '',
        );
      })
      .where((r) =>
          r.brand.toLowerCase() == brand.toLowerCase() && r.model.isNotEmpty)
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
  final admin = await fetchAdminFilterOptions('mobiles', 'condition');
  if (admin.isNotEmpty) return admin;
  final fromListings = await _distinctMobileCategoryDataValues('condition');
  if (fromListings.isNotEmpty) return fromListings;
  return const ['Flawless', 'Excellent', 'Good', 'Average', 'Poor'];
});

/// Distinct seller types from mobile listings
final mobileSellerTypesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final admin = await fetchAdminFilterOptions('mobiles', 'seller_type');
  if (admin.isNotEmpty) return admin;
  final fromListings = await _distinctMobileCategoryDataValues('seller_type');
  if (fromListings.isNotEmpty) return fromListings;
  return const ['All Sellers', 'Individuals', 'Businesses'];
});

/// Distinct ages from mobile listings
final mobileAgesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final admin = await fetchAdminFilterOptions('mobiles', 'age');
  if (admin.isNotEmpty) return admin;
  final fromListings = await _distinctMobileCategoryDataValues('age');
  if (fromListings.isNotEmpty) return fromListings;
  return const [
    'Brand New',
    '0-1 month',
    '1-6 months',
    '6-12 months',
    '1-2 years',
    '2-5 years',
    '5-10 years',
    '10+ years',
  ];
});

/// Distinct warranties from mobile listings
final mobileWarrantiesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final admin = await fetchAdminFilterOptions('mobiles', 'warranty');
  if (admin.isNotEmpty) return admin;
  final fromListings = await _distinctMobileCategoryDataValues('warranty');
  if (fromListings.isNotEmpty) return fromListings;
  return const ['Yes', 'No', 'Does not apply'];
});

/// Distinct screen sizes from mobile listings
final mobileScreenSizesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final admin = await fetchAdminFilterOptions('mobiles', 'screen_size');
  if (admin.isNotEmpty) return admin;
  return _distinctMobileCategoryDataValues('screen_size');
});

/// Distinct damage details from mobile listings
final mobileDamageDetailsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final admin = await fetchAdminFilterOptions('mobiles', 'damage_details');
  if (admin.isNotEmpty) return admin;
  return _distinctMobileCategoryDataValues('damage_details');
});

/// Distinct battery health values from mobile listings
final mobileBatteryHealthsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final admin = await fetchAdminFilterOptions('mobiles', 'battery_health');
  if (admin.isNotEmpty) return admin;
  return _distinctMobileCategoryDataValues('battery_health');
});

/// Distinct versions from mobile listings
final mobileVersionsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final admin = await fetchAdminFilterOptions('mobiles', 'version');
  if (admin.isNotEmpty) return admin;
  return _distinctMobileCategoryDataValues('version');
});

/// Distinct storage values from mobile listings
final mobileStoragesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final admin = await fetchAdminFilterOptions('mobiles', 'storage');
  if (admin.isNotEmpty) return admin;
  final fromListings = await _distinctMobileCategoryDataValues('storage');
  if (fromListings.isNotEmpty) return fromListings;
  return const ['16GB', '32GB', '64GB', '128GB', '256GB', '512GB', '1TB'];
});

/// Distinct colors from mobile listings
final mobileColorsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final admin = await fetchAdminFilterOptions('mobiles', 'color');
  if (admin.isNotEmpty) return admin;
  return _distinctMobileCategoryDataValues('color');
});

/// Distinct cities from mobile listings
final mobileCitiesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final response = await Supabase.instance.client
      .from('listings')
      .select('city')
      .eq('category', 'mobiles')
      .eq('is_active', true);

  final cities = (response as List<dynamic>)
      .map((e) => (e as Map<String, dynamic>)['city']?.toString().trim() ?? '')
      .where((c) => c.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return cities;
});
