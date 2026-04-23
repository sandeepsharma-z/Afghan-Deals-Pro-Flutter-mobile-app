import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../features/listings/data/models/electronics_listing_model.dart';

// ── Subcategory model (fetched from Supabase) ──────────────────────────────
class ElectronicsSubcategory {
  final String name;
  final String slug;
  final String? iconUrl;
  final int sortOrder;

  const ElectronicsSubcategory({
    required this.name,
    required this.slug,
    this.iconUrl,
    required this.sortOrder,
  });

  factory ElectronicsSubcategory.fromMap(Map<String, dynamic> map) {
    return ElectronicsSubcategory(
      name: map['name']?.toString().trim() ?? '',
      slug: map['slug']?.toString().trim() ?? '',
      iconUrl: map['icon_url']?.toString(),
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Fetches electronics subcategories from Supabase subcategories table
final electronicsSubcategoriesProvider =
    FutureProvider.autoDispose<List<ElectronicsSubcategory>>((ref) async {
  final response = await Supabase.instance.client
      .from('subcategories')
      .select('name, slug, icon_url, sort_order')
      .eq('category_slug', 'electronics')
      .eq('is_active', true)
      .order('sort_order', ascending: true)
      .order('name', ascending: true);

  final rows = (response as List<dynamic>)
      .map((e) => ElectronicsSubcategory.fromMap(Map<String, dynamic>.from(e as Map)))
      .where((s) => s.name.isNotEmpty && s.slug.isNotEmpty)
      .toList();

  if (rows.isNotEmpty) return rows;

  // Fallback static list if Supabase has no subcategories yet
  return const [
    ElectronicsSubcategory(name: 'TVs, Video-Audio',          slug: 'tvs-video-audio',           sortOrder: 1),
    ElectronicsSubcategory(name: 'Kitchen & Other Appliance', slug: 'kitchen-other-appliance',    sortOrder: 2),
    ElectronicsSubcategory(name: 'Fridges',                   slug: 'fridges',                   sortOrder: 3),
    ElectronicsSubcategory(name: 'Cameras & Lenses',          slug: 'cameras-lenses',            sortOrder: 4),
    ElectronicsSubcategory(name: 'Washing Machines',          slug: 'washing-machines',          sortOrder: 5),
    ElectronicsSubcategory(name: 'ACs',                       slug: 'acs',                       sortOrder: 6),
    ElectronicsSubcategory(name: 'Games & Entertainment',     slug: 'games-entertainment',       sortOrder: 7),
  ];
});

// ── Filter model ───────────────────────────────────────────────────────────
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

// ── Listings providers ─────────────────────────────────────────────────────
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

final electronicsListingsProvider =
    FutureProvider.autoDispose<List<ElectronicsListingModel>>((ref) async {
  return _fetchElectronics();
});

final electronicsBySubcategoryProvider =
    FutureProvider.autoDispose.family<List<ElectronicsListingModel>, String>(
        (ref, subcategory) async {
  return _fetchElectronics(subcategory: subcategory);
});

final electronicsFilteredProvider =
    FutureProvider.autoDispose.family<List<ElectronicsListingModel>, String>(
        (ref, subcategory) async {
  final filter = ref.watch(electronicsFilterProvider);
  final all = await ref.watch(electronicsBySubcategoryProvider(subcategory).future);

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
      result.sort((a, b) =>
          (double.tryParse(b.price) ?? 0).compareTo(double.tryParse(a.price) ?? 0));
    case 'price_low':
      result.sort((a, b) =>
          (double.tryParse(a.price) ?? 0).compareTo(double.tryParse(b.price) ?? 0));
    case 'oldest':
      result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    default:
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  return result;
});

// ── Filter option providers (dynamic from listings) ────────────────────────
Future<List<String>> _distinctField(String field, {String subcategory = ''}) async {
  var query = Supabase.instance.client
      .from('listings')
      .select('category_data')
      .eq('category', 'electronics')
      .eq('is_active', true);
  if (subcategory.isNotEmpty) { query = query.eq('subcategory', subcategory); }
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

/// Brands fetched from listings data (dynamic)
final electronicsBrandsProvider =
    FutureProvider.autoDispose<List<String>>((ref) => _distinctField('brand'));

/// Models per brand (dynamic from listings)
final electronicsModelsProvider =
    FutureProvider.autoDispose.family<List<String>, String>((ref, brand) async {
  final response = await Supabase.instance.client
      .from('listings')
      .select('category_data')
      .eq('category', 'electronics')
      .eq('is_active', true);
  return (response as List<dynamic>)
      .map((e) {
        final cd = (e as Map<String, dynamic>)['category_data'] as Map<String, dynamic>? ?? {};
        return (
          brand: cd['brand']?.toString().trim() ?? '',
          model: cd['model']?.toString().trim() ?? '',
        );
      })
      .where((r) {
        if (brand.isNotEmpty && r.brand.toLowerCase() != brand.toLowerCase()) {
          return false;
        }
        return r.model.isNotEmpty;
      })
      .map((r) => r.model)
      .toSet()
      .toList()
    ..sort();
});

/// Conditions from listings (with static fallback)
final electronicsConditionsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final dynamic = await _distinctField('condition');
  if (dynamic.isNotEmpty) return dynamic;
  return const ['Flawless', 'Excellent', 'Good', 'Average', 'Poor'];
});

/// Ages from listings (with static fallback)
final electronicsAgesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final dynamic = await _distinctField('age');
  if (dynamic.isNotEmpty) return dynamic;
  return const [
    'Brand New', '0-1 month', '1-6 months', '6-12 months',
    '1-2 years', '2-5 years', '5-10 years', '10+ years',
  ];
});

final electronicsWarrantiesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final dynamic = await _distinctField('warranty');
  if (dynamic.isNotEmpty) return dynamic;
  return const ['Yes', 'No', 'Does not apply'];
});

final electronicsSellerTypesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final dynamic = await _distinctField('seller_type');
  if (dynamic.isNotEmpty) return dynamic;
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
