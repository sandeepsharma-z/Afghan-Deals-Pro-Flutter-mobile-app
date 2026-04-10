import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/subcategory_model.dart';

final subcategoriesProvider = FutureProvider.autoDispose
    .family<List<SubcategoryModel>, String>((ref, categorySlug) async {
  final client = Supabase.instance.client;
  final response = await client
      .from('subcategories')
      .select('id,category_slug,name,slug,icon_url,is_active,is_new,sort_order')
      .eq('category_slug', categorySlug)
      .eq('is_active', true)
      .order('sort_order', ascending: true);

  return (response as List<dynamic>)
      .map((item) => SubcategoryModel.fromMap(item as Map<String, dynamic>))
      .toList();
});
