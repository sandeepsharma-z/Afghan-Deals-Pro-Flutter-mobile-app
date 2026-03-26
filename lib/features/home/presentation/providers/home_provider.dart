import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/home_category_model.dart';

final homeCategoriesProvider =
    FutureProvider<List<HomeCategoryModel>>((ref) async {
  final client = Supabase.instance.client;
  final response = await client
      .from('categories')
      .select('id,name,slug,image_url,is_active,sort_order')
      .eq('is_active', true)
      .order('sort_order', ascending: true)
      .order('name', ascending: true);

  return (response as List<dynamic>)
      .map((item) => HomeCategoryModel.fromMap(item as Map<String, dynamic>))
      .toList();
});
