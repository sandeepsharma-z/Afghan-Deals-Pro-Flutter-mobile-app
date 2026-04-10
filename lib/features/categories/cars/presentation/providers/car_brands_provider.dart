import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CarBrand {
  final int id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String? subcategorySlug;
  final bool isActive;
  final int sortOrder;

  const CarBrand({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.subcategorySlug,
    required this.isActive,
    required this.sortOrder,
  });

  factory CarBrand.fromMap(Map<String, dynamic> m) => CarBrand(
        id: m['id'] as int,
        name: m['name'] as String,
        slug: m['slug'] as String,
        logoUrl: m['logo_url'] as String?,
        subcategorySlug: m['subcategory_slug'] as String?,
        isActive: m['is_active'] as bool? ?? true,
        sortOrder: m['sort_order'] as int? ?? 0,
      );
}

final carBrandsBySubcategoryProvider =
    FutureProvider.autoDispose.family<List<CarBrand>, String>((ref, subcategorySlug) async {
  final response = await Supabase.instance.client
      .from('car_makes')
      .select('id, name, slug, logo_url, subcategory_slug, is_active, sort_order')
      .eq('is_active', true)
      .eq('subcategory_slug', subcategorySlug)
      .order('sort_order', ascending: true);

  return (response as List<dynamic>)
      .map((e) => CarBrand.fromMap(e as Map<String, dynamic>))
      .toList();
});

// Backward-compatible provider (legacy call sites may still read this).
final carBrandsProvider = FutureProvider.autoDispose<List<CarBrand>>((ref) async {
  return ref.watch(carBrandsBySubcategoryProvider('used-cars').future);
});
