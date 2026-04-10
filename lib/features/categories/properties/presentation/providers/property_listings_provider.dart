import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/property_listing_model.dart';

final propertyListingsProvider =
    FutureProvider.autoDispose<List<PropertyListingModel>>((ref) async {
  final response = await Supabase.instance.client
      .from('listings')
      .select(
          'id,seller_id,seller_name,title,description,price,currency,city,images,is_featured,created_at,subcategory,category_data')
      .eq('category', 'properties')
      .eq('is_active', true)
      .order('created_at', ascending: false);

  return (response as List<dynamic>)
      .map((e) => PropertyListingModel.fromMap(e as Map<String, dynamic>))
      .toList();
});
