import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../features/listings/data/models/electronics_listing_model.dart';

class ElectronicsFilter {
  final List<String> brands;
  final List<String> models;
  final List<String> conditions;
  final List<String> ages;
  final List<String> warranties;
  final List<String> sellerTypes;
  final double? minPrice;
  final double? maxPrice;
  final String region;
  final String sortBy;

  const ElectronicsFilter({
    this.brands = const [],
    this.models = const [],
    this.conditions = const [],
    this.ages = const [],
    this.warranties = const [],
    this.sellerTypes = const [],
    this.minPrice,
    this.maxPrice,
    this.region = '',
    this.sortBy = 'newest',
  });

  ElectronicsFilter copyWith({
    List<String>? brands,
    List<String>? models,
    List<String>? conditions,
    List<String>? ages,
    List<String>? warranties,
    List<String>? sellerTypes,
    double? minPrice,
    double? maxPrice,
    String? region,
    String? sortBy,
  }) =>
      ElectronicsFilter(
        brands: brands ?? this.brands,
        models: models ?? this.models,
        conditions: conditions ?? this.conditions,
        ages: ages ?? this.ages,
        warranties: warranties ?? this.warranties,
        sellerTypes: sellerTypes ?? this.sellerTypes,
        minPrice: minPrice ?? this.minPrice,
        maxPrice: maxPrice ?? this.maxPrice,
        region: region ?? this.region,
        sortBy: sortBy ?? this.sortBy,
      );

  bool get isEmpty =>
      brands.isEmpty &&
      models.isEmpty &&
      conditions.isEmpty &&
      ages.isEmpty &&
      warranties.isEmpty &&
      sellerTypes.isEmpty &&
      minPrice == null &&
      maxPrice == null &&
      region.isEmpty;
}

final electronicsFilterProvider =
    StateProvider.autoDispose<ElectronicsFilter>((ref) => const ElectronicsFilter());

Future<List<ElectronicsListingModel>> _fetchElectronics({String subcategory = ''}) async {
  var query = Supabase.instance.client
      .from('listings')
      .select()
      .eq('category', 'electronics')
      .eq('is_active', true);

  if (subcategory.isNotEmpty) {
    query = query.eq('subcategory', subcategory);
  }

  final response = await query.order('created_at', ascending: false);
  return (response as List<dynamic>)
      .map((e) => ElectronicsListingModel.fromMap(e as Map<String, dynamic>))
      .toList();
}

/// All electronics listings
final electronicsListingsProvider =
    FutureProvider.autoDispose<List<ElectronicsListingModel>>((ref) async {
  return _fetchElectronics();
});

/// Electronics by subcategory
final electronicsBySubcategoryProvider =
    FutureProvider.autoDispose.family<List<ElectronicsListingModel>, String>(
        (ref, subcategory) async {
  return _fetchElectronics(subcategory: subcategory);
});

/// Filtered + sorted listings
final electronicsFilteredProvider =
    FutureProvider.autoDispose.family<List<ElectronicsListingModel>, String>(
        (ref, subcategory) async {
  final filter = ref.watch(electronicsFilterProvider);
  final all = await ref.watch(
      electronicsBySubcategoryProvider(subcategory).future);

  var result = all.where((item) {
    if (filter.brands.isNotEmpty &&
        !filter.brands.any((b) => b.toLowerCase() == item.brand.toLowerCase())) {
      return false;
    }
    if (filter.models.isNotEmpty &&
        !filter.models.any((m) => m.toLowerCase() == item.model.toLowerCase())) {
      return false;
    }
    if (filter.conditions.isNotEmpty &&
        !filter.conditions.any((c) => c.toLowerCase() == item.condition.toLowerCase())) {
      return false;
    }
    if (filter.ages.isNotEmpty &&
        !filter.ages.any((a) => a.toLowerCase() == item.age.toLowerCase())) {
      return false;
    }
    if (filter.warranties.isNotEmpty &&
        !filter.warranties.any((w) => w.toLowerCase() == item.warranty.toLowerCase())) {
      return false;
    }
    if (filter.sellerTypes.isNotEmpty &&
        !filter.sellerTypes.any((s) => s.toLowerCase() == item.sellerType.toLowerCase())) {
      return false;
    }
    final price = double.tryParse(item.price) ?? 0;
    if (filter.minPrice != null && price < filter.minPrice!) { return false; }
    if (filter.maxPrice != null && price > filter.maxPrice!) { return false; }
    if (filter.region.isNotEmpty &&
        !item.city.toLowerCase().contains(filter.region.toLowerCase())) {
      return false;
    }
    return true;
  }).toList();

  switch (filter.sortBy) {
    case 'price_high':
      result.sort((a, b) => (double.tryParse(b.price) ?? 0)
          .compareTo(double.tryParse(a.price) ?? 0));
    case 'price_low':
      result.sort((a, b) => (double.tryParse(a.price) ?? 0)
          .compareTo(double.tryParse(b.price) ?? 0));
    case 'oldest':
      result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    default:
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  return result;
});

Future<List<String>> _distinctField(String field, {String subcategory = ''}) async {
  var query = Supabase.instance.client
      .from('listings')
      .select('category_data')
      .eq('category', 'electronics')
      .eq('is_active', true);
  if (subcategory.isNotEmpty) query = query.eq('subcategory', subcategory);
  final response = await query;
  return (response as List<dynamic>)
      .map((e) {
        final cd = (e as Map<String, dynamic>)['category_data'] as Map<String, dynamic>? ?? {};
        return cd[field]?.toString().trim() ?? '';
      })
      .where((v) => v.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
}

final electronicsBrandsProvider =
    FutureProvider.autoDispose<List<String>>((ref) => _distinctField('brand'));

final electronicsModelsProvider =
    FutureProvider.autoDispose.family<List<String>, String>(
        (ref, brand) async {
  var query = Supabase.instance.client
      .from('listings')
      .select('category_data')
      .eq('category', 'electronics')
      .eq('is_active', true);
  final response = await query;
  final all = (response as List<dynamic>)
      .map((e) {
        final cd = (e as Map<String, dynamic>)['category_data'] as Map<String, dynamic>? ?? {};
        return (
          brand: cd['brand']?.toString().trim() ?? '',
          model: cd['model']?.toString().trim() ?? '',
        );
      })
      .where((r) {
        if (brand.isNotEmpty && r.brand.toLowerCase() != brand.toLowerCase()) return false;
        return r.model.isNotEmpty;
      })
      .map((r) => r.model)
      .toSet()
      .toList()
    ..sort();
  return all;
});

final electronicsConditionsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  const fixed = ['Flawless', 'Excellent', 'Good', 'Average', 'Poor'];
  return fixed;
});

final electronicsAgesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  const fixed = [
    'Brand New', '0-1 month', '1-6 months', '6-12 months',
    '1-2 years', '2-5 years', '5-10 years', '10+ years'
  ];
  return fixed;
});

final electronicsWarrantiesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  return const ['Yes', 'No', 'Does not apply'];
});

final electronicsSellerTypesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  return const ['All Sellers', 'Individuals', 'Businesses'];
});

final electronicsCitiesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final response = await Supabase.instance.client
      .from('listings')
      .select('city')
      .eq('category', 'electronics')
      .eq('is_active', true);
  return (response as List<dynamic>)
      .map((e) => (e as Map<String, dynamic>)['city']?.toString().trim() ?? '')
      .where((c) => c.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
});

/// Distinct models per subcategory (for the model grid inside a subcategory)
final electronicsSubcategoryModelsProvider =
    FutureProvider.autoDispose.family<List<String>, String>(
        (ref, subcategory) async {
  return _distinctField('model', subcategory: subcategory);
});
