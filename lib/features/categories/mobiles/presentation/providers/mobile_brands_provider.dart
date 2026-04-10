import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MobileBrand {
  final int id;
  final String name;
  final String slug;
  final String? logoUrl;
  final bool isActive;
  final int sortOrder;

  const MobileBrand({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    required this.isActive,
    required this.sortOrder,
  });

  factory MobileBrand.fromMap(Map<String, dynamic> m) => MobileBrand(
        id: m['id'] as int,
        name: m['name'] as String,
        slug: m['slug'] as String,
        logoUrl: m['logo_url'] as String?,
        isActive: m['is_active'] as bool? ?? true,
        sortOrder: m['sort_order'] as int? ?? 0,
      );
}

final mobileBrandsProvider =
    FutureProvider.autoDispose<List<MobileBrand>>((ref) async {
  final response = await Supabase.instance.client
      .from('car_makes')
      .select('id, name, slug, logo_url, is_active, sort_order')
      .eq('is_active', true)
      .eq('subcategory_slug', 'mobile-brands')
      .order('sort_order', ascending: true);

  return (response as List<dynamic>)
      .map((e) => MobileBrand.fromMap(e as Map<String, dynamic>))
      .toList();
});
