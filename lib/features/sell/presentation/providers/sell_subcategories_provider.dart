import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SellSubcategory {
  final String name;
  final String slug;

  const SellSubcategory({
    required this.name,
    required this.slug,
  });

  factory SellSubcategory.fromMap(Map<String, dynamic> map) {
    return SellSubcategory(
      name: (map['name'] ?? '').toString(),
      slug: (map['slug'] ?? '').toString(),
    );
  }
}

String _normalizeCategorySlug(String slug) {
  final v = slug.trim().toLowerCase();
  if (v == 'spare_parts') return 'spare-parts';
  return v;
}

final sellSubcategoriesProvider = FutureProvider.autoDispose
    .family<List<SellSubcategory>, String>((ref, categorySlug) async {
  final client = Supabase.instance.client;
  final normalized = _normalizeCategorySlug(categorySlug);
  var query = client
      .from('subcategories')
      .select('name,slug,sort_order')
      .eq('category_slug', normalized)
      .eq('is_active', true);

  // Mobiles should expose only the phone subcategory.
  if (normalized == 'mobiles') {
    query = query.eq('slug', 'mobile-phones');
  }

  final response = await query
      .order('sort_order', ascending: true)
      .order('name', ascending: true);

  return (response as List<dynamic>)
      .map((e) => SellSubcategory.fromMap(e as Map<String, dynamic>))
      .where((e) => e.slug.isNotEmpty)
      .toList();
});
