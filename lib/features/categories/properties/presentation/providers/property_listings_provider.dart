import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/property_listing_model.dart';
import '../../../../../features/home/presentation/providers/country_provider.dart';

final propertyListingsProvider =
    FutureProvider.autoDispose<List<PropertyListingModel>>((ref) async {
  final selectedCountry = ref.watch(selectedCountryProvider);

  var query = Supabase.instance.client
      .from('listings')
      .select(
          'id,seller_id,seller_name,title,description,price,currency,city,images,is_featured,created_at,subcategory,category_data')
      .eq('category', 'properties')
      .eq('is_active', true);

  if (selectedCountry.isNotEmpty) {
    query = query.ilike('country', selectedCountry);
  }

  final response = await query.order('created_at', ascending: false);

  return (response as List<dynamic>)
      .map((e) => PropertyListingModel.fromMap(e as Map<String, dynamic>))
      .toList();
});
