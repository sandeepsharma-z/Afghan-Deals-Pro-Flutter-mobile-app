import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../features/listings/data/models/rental_car_model.dart';

// Pass 'all' or a specific duration like 'Daily Rentals', 'Weekly Rentals', 'Monthly Rentals'
final rentalCarsProvider = FutureProvider.autoDispose
    .family<List<RentalCarModel>, String>((ref, duration) async {
  var query = Supabase.instance.client
      .from('listings')
      .select('id,seller_id,seller_name,title,description,price,currency,images,city,category_data')
      .eq('category', 'cars')
      .or('subcategory.ilike.%rental%')
      .eq('is_active', true);

  if (duration != 'all') {
    query = query.filter('category_data->>rental_duration', 'eq', duration);
  }

  final response = await query.order('created_at', ascending: false);

  return (response as List<dynamic>)
      .map((e) => RentalCarModel.fromMap(e as Map<String, dynamic>))
      .toList();
});
