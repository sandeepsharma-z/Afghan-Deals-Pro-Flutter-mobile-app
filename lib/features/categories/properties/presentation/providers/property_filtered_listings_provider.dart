import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/property_listing_model.dart';

class PropertyFilter {
  final String subcategorySlug;
  final String propertyType;

  const PropertyFilter({
    this.subcategorySlug = '',
    this.propertyType = '',
  });

  @override
  bool operator ==(Object other) =>
      other is PropertyFilter &&
      other.subcategorySlug == subcategorySlug &&
      other.propertyType == propertyType;

  @override
  int get hashCode => Object.hash(subcategorySlug, propertyType);
}

final propertyLocationsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final response = await Supabase.instance.client
      .from('listings')
      .select('city')
      .eq('category', 'properties')
      .eq('is_active', true);

  final cities = (response as List<dynamic>)
      .map((e) => (e as Map<String, dynamic>)['city']?.toString().trim() ?? '')
      .where((c) => c.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  return cities;
});

final propertyFilteredListingsProvider = FutureProvider.autoDispose
    .family<List<PropertyListingModel>, PropertyFilter>((ref, filter) async {
  var query = Supabase.instance.client
      .from('listings')
      .select(
          'id,seller_id,seller_name,title,description,price,currency,city,images,is_featured,created_at,subcategory,category_data')
      .eq('category', 'properties')
      .eq('is_active', true);

  if (filter.subcategorySlug.isNotEmpty) {
    query = query.eq('subcategory', filter.subcategorySlug);
  }

  if (filter.propertyType.isNotEmpty) {
    query = query.eq('category_data->>property_type', filter.propertyType);
  }

  final response = await query.order('created_at', ascending: false);

  return (response as List<dynamic>)
      .map((e) => PropertyListingModel.fromMap(e as Map<String, dynamic>))
      .toList();
});
