import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../features/listings/data/models/classified_listing_model.dart';

const _unset = Object();

// ── Subcategory model ──────────────────────────────────────────────────────
class ClassifiedSubcategory {
  final String name;
  final String slug;
  final String? iconUrl;
  final int sortOrder;

  const ClassifiedSubcategory({
    required this.name,
    required this.slug,
    this.iconUrl,
    required this.sortOrder,
  });

  factory ClassifiedSubcategory.fromMap(Map<String, dynamic> map) {
    return ClassifiedSubcategory(
      name: map['name']?.toString().trim() ?? '',
      slug: map['slug']?.toString().trim() ?? '',
      iconUrl: map['icon_url']?.toString(),
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

const _defaultClassifiedSubcategories = [
  ClassifiedSubcategory(name: 'Men', slug: 'men', sortOrder: 1),
  ClassifiedSubcategory(name: 'Women', slug: 'women', sortOrder: 2),
  ClassifiedSubcategory(
      name: 'Kids Fashion', slug: 'kids-fashion', sortOrder: 3),
  ClassifiedSubcategory(name: 'Bags', slug: 'bags', sortOrder: 4),
  ClassifiedSubcategory(name: 'Footwear', slug: 'footwear', sortOrder: 5),
  ClassifiedSubcategory(name: 'Jewellery', slug: 'jewellery', sortOrder: 6),
  ClassifiedSubcategory(
      name: 'Watches & Accessories', slug: 'watches-accessories', sortOrder: 7),
  ClassifiedSubcategory(
      name: 'Book & Sports', slug: 'books-sports', sortOrder: 8),
];

const _classifiedMainSlugs = {
  'men',
  'women',
  'kids-fashion',
  'bags',
  'footwear',
  'jewellery',
  'jewelry',
  'watches-accessories',
  'books-sports',
};

ClassifiedSubcategory _normalizeClassifiedMain(ClassifiedSubcategory item) {
  if (item.slug == 'jewelry') {
    return ClassifiedSubcategory(
      name: 'Jewellery',
      slug: 'jewellery',
      iconUrl: item.iconUrl,
      sortOrder: item.sortOrder,
    );
  }
  return item;
}

final classifiedsSubcategoriesProvider =
    FutureProvider.autoDispose<List<ClassifiedSubcategory>>((ref) async {
  final response = await Supabase.instance.client
      .from('subcategories')
      .select('name, slug, icon_url, sort_order')
      .eq('category_slug', 'classifieds')
      .eq('is_active', true)
      .order('sort_order', ascending: true)
      .order('name', ascending: true);

  final rows = (response as List<dynamic>)
      .map((e) =>
          ClassifiedSubcategory.fromMap(Map<String, dynamic>.from(e as Map)))
      .where((s) => s.name.isNotEmpty && s.slug.isNotEmpty)
      .toList();

  final bySlug = {
    for (final item in _defaultClassifiedSubcategories) item.slug: item,
    for (final item in rows)
      if (_classifiedMainSlugs.contains(item.slug))
        _normalizeClassifiedMain(item).slug: _normalizeClassifiedMain(item),
  };
  return bySlug.values.toList()
    ..sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      if (byOrder != 0) return byOrder;
      return a.name.compareTo(b.name);
    });
});

// ── Filter model ───────────────────────────────────────────────────────────
class ClassifiedsFilter {
  final List<String> conditions;
  final List<String> ages;
  final List<String> sellerTypes;
  final double? minPrice;
  final double? maxPrice;
  final String region;
  final String sortBy;

  const ClassifiedsFilter({
    this.conditions = const [],
    this.ages = const [],
    this.sellerTypes = const [],
    this.minPrice,
    this.maxPrice,
    this.region = '',
    this.sortBy = 'newest',
  });

  ClassifiedsFilter copyWith({
    List<String>? conditions,
    List<String>? ages,
    List<String>? sellerTypes,
    Object? minPrice = _unset,
    Object? maxPrice = _unset,
    String? region,
    String? sortBy,
  }) =>
      ClassifiedsFilter(
        conditions: conditions ?? this.conditions,
        ages: ages ?? this.ages,
        sellerTypes: sellerTypes ?? this.sellerTypes,
        minPrice:
            identical(minPrice, _unset) ? this.minPrice : minPrice as double?,
        maxPrice:
            identical(maxPrice, _unset) ? this.maxPrice : maxPrice as double?,
        region: region ?? this.region,
        sortBy: sortBy ?? this.sortBy,
      );

  bool get isEmpty =>
      conditions.isEmpty &&
      ages.isEmpty &&
      sellerTypes.isEmpty &&
      minPrice == null &&
      maxPrice == null &&
      region.isEmpty;
}

final classifiedsFilterProvider = StateProvider.autoDispose<ClassifiedsFilter>(
    (ref) => const ClassifiedsFilter());

// ── Listings providers ─────────────────────────────────────────────────────
Future<List<ClassifiedListingModel>> _fetchClassifieds(
    {String subcategory = ''}) async {
  var query = Supabase.instance.client
      .from('listings')
      .select()
      .eq('category', 'classifieds')
      .eq('is_active', true);
  if (subcategory.isNotEmpty) {
    query = query.eq('subcategory', subcategory);
  }
  final response = await query.order('created_at', ascending: false);
  return (response as List<dynamic>)
      .map((e) => ClassifiedListingModel.fromMap(e as Map<String, dynamic>))
      .toList();
}

final classifiedsListingsProvider =
    FutureProvider.autoDispose<List<ClassifiedListingModel>>((ref) async {
  return _fetchClassifieds();
});

final classifiedsBySubcategoryProvider = FutureProvider.autoDispose
    .family<List<ClassifiedListingModel>, String>((ref, subcategory) async {
  return _fetchClassifieds(subcategory: subcategory);
});

final classifiedsFilteredProvider = FutureProvider.autoDispose
    .family<List<ClassifiedListingModel>, String>((ref, subcategory) async {
  final filter = ref.watch(classifiedsFilterProvider);
  final all =
      await ref.watch(classifiedsBySubcategoryProvider(subcategory).future);

  var result = all.where((item) {
    if (filter.conditions.isNotEmpty &&
        !filter.conditions
            .any((c) => c.toLowerCase() == item.condition.toLowerCase())) {
      return false;
    }
    if (filter.ages.isNotEmpty &&
        !filter.ages.any((a) => a.toLowerCase() == item.age.toLowerCase())) {
      return false;
    }
    if (filter.sellerTypes.isNotEmpty &&
        !filter.sellerTypes
            .any((s) => s.toLowerCase() == item.sellerType.toLowerCase())) {
      return false;
    }
    final price = double.tryParse(item.price) ?? 0;
    if (filter.minPrice != null && price < filter.minPrice!) {
      return false;
    }
    if (filter.maxPrice != null && price > filter.maxPrice!) {
      return false;
    }
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

Future<List<String>> _distinctClassifiedField(String field,
    {String subcategory = ''}) async {
  var query = Supabase.instance.client
      .from('listings')
      .select('category_data')
      .eq('category', 'classifieds')
      .eq('is_active', true);
  if (subcategory.isNotEmpty) query = query.eq('subcategory', subcategory);
  final response = await query;
  return (response as List<dynamic>)
      .map((e) {
        final cd = (e as Map<String, dynamic>)['category_data']
                as Map<String, dynamic>? ??
            {};
        return cd[field]?.toString().trim() ?? '';
      })
      .where((v) => v.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
}

final classifiedsConditionsBySubcategoryProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, subcategory) async {
  final fromListings =
      await _distinctClassifiedField('condition', subcategory: subcategory);
  if (fromListings.isNotEmpty) return fromListings;
  return const ['Flawless', 'Excellent', 'Good', 'Average', 'Poor'];
});

final classifiedsSellerTypesBySubcategoryProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, subcategory) async {
  final fromListings =
      await _distinctClassifiedField('seller_type', subcategory: subcategory);
  if (fromListings.isNotEmpty) return fromListings;
  return const ['All Sellers', 'Individuals', 'Businesses'];
});

final classifiedsAgesBySubcategoryProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, subcategory) async {
  final fromListings =
      await _distinctClassifiedField('age', subcategory: subcategory);
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
