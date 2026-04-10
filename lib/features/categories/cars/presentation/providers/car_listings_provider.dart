import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../features/listings/data/models/car_sale_model.dart';

dynamic _applySubcategoryFilter(dynamic query, String rawSubcategory) {
  final key = rawSubcategory.trim().toLowerCase();
  if (key.contains('used')) {
    return query.or('subcategory.ilike.%used%');
  }
  if (key.contains('new')) {
    return query.or('subcategory.ilike.%new%');
  }
  if (key.contains('export')) {
    return query.or('subcategory.ilike.%export%');
  }
  if (key.contains('rental')) {
    return query.or('subcategory.ilike.%rental%');
  }
  return query.eq('subcategory', key);
}

// subcategory = 'used' | 'new' | 'export' | 'motorcycles' etc.
final carListingsProvider = FutureProvider.autoDispose
    .family<List<CarSaleModel>, String>((ref, subcategory) async {
  final key = subcategory.trim().toLowerCase();

  final baseQuery = Supabase.instance.client
      .from('listings')
      .select('id,seller_id,title,description,seller_name,price,currency,images,city,is_featured,created_at,category_data')
      .eq('category', 'cars')
      .eq('is_active', true);

  final query = _applySubcategoryFilter(baseQuery, key);

  var rows = (await query.order('created_at', ascending: false)) as List<dynamic>;

  // Safety fallback: if used-cars query returns nothing, show non-rental car listings.
  if (rows.isEmpty && key.contains('used')) {
    rows = (await baseQuery
        .neq('subcategory', 'rental-cars')
        .order('created_at', ascending: false)) as List<dynamic>;
  }

  return rows
      .map((e) => CarSaleModel.fromMap(e as Map<String, dynamic>))
      .toList();
});
