import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../features/listings/data/models/classified_listing_model.dart';

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
      .map((e) => ClassifiedSubcategory.fromMap(Map<String, dynamic>.from(e as Map)))
      .where((s) => s.name.isNotEmpty && s.slug.isNotEmpty)
      .toList();

  if (rows.isNotEmpty) return rows;

  return const [
    // Fashion
    ClassifiedSubcategory(name: 'Men',                  slug: 'men',                 sortOrder: 1),
    ClassifiedSubcategory(name: 'Women',                slug: 'women',               sortOrder: 2),
    ClassifiedSubcategory(name: 'Kids Fashion',         slug: 'kids-fashion',        sortOrder: 3),
    ClassifiedSubcategory(name: 'Bags',                 slug: 'bags',                sortOrder: 4),
    ClassifiedSubcategory(name: 'Footwear',             slug: 'footwear',            sortOrder: 5),
    ClassifiedSubcategory(name: 'Jewelry',              slug: 'jewelry',             sortOrder: 6),
    ClassifiedSubcategory(name: 'Watches & Accessories',slug: 'watches-accessories', sortOrder: 7),
    // Books & Sports
    ClassifiedSubcategory(name: 'Academic Books',       slug: 'academic-books',      sortOrder: 8),
    ClassifiedSubcategory(name: 'Fiction Books',        slug: 'fiction-books',       sortOrder: 9),
    ClassifiedSubcategory(name: 'Kids Book',            slug: 'kids-book',           sortOrder: 10),
    ClassifiedSubcategory(name: 'Exam Preparation',     slug: 'exam-preparation',    sortOrder: 11),
    ClassifiedSubcategory(name: 'Sports Accessories',   slug: 'sports-accessories',  sortOrder: 12),
    ClassifiedSubcategory(name: 'Cricket Gear',         slug: 'cricket-gear',        sortOrder: 13),
    ClassifiedSubcategory(name: 'Fitness Equipment',    slug: 'fitness-equipment',   sortOrder: 14),
  ];
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
    double? minPrice,
    double? maxPrice,
    String? region,
    String? sortBy,
  }) =>
      ClassifiedsFilter(
        conditions: conditions ?? this.conditions,
        ages: ages ?? this.ages,
        sellerTypes: sellerTypes ?? this.sellerTypes,
        minPrice: minPrice ?? this.minPrice,
        maxPrice: maxPrice ?? this.maxPrice,
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

final classifiedsFilterProvider =
    StateProvider.autoDispose<ClassifiedsFilter>((ref) => const ClassifiedsFilter());

// ── Listings providers ─────────────────────────────────────────────────────
Future<List<ClassifiedListingModel>> _fetchClassifieds({String subcategory = ''}) async {
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

final classifiedsBySubcategoryProvider =
    FutureProvider.autoDispose.family<List<ClassifiedListingModel>, String>(
        (ref, subcategory) async {
  return _fetchClassifieds(subcategory: subcategory);
});

final classifiedsFilteredProvider =
    FutureProvider.autoDispose.family<List<ClassifiedListingModel>, String>(
        (ref, subcategory) async {
  final filter = ref.watch(classifiedsFilterProvider);
  final all = await ref.watch(classifiedsBySubcategoryProvider(subcategory).future);

  var result = all.where((item) {
    if (filter.conditions.isNotEmpty &&
        !filter.conditions.any((c) => c.toLowerCase() == item.condition.toLowerCase())) {
      return false;
    }
    if (filter.ages.isNotEmpty &&
        !filter.ages.any((a) => a.toLowerCase() == item.age.toLowerCase())) {
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
