import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../features/listings/data/models/rental_car_model.dart';

final rentalCarsProvider =
    FutureProvider.autoDispose<List<RentalCarModel>>((ref) async {
  final response = await Supabase.instance.client
      .from('listings')
      .select(
          'id,title,description,price,currency,images,city,category_data')
      .eq('category', 'cars')
      .eq('subcategory', 'rental')
      .eq('is_active', true)
      .order('created_at', ascending: false);

  return (response as List<dynamic>)
      .map((e) => RentalCarModel.fromMap(e as Map<String, dynamic>))
      .toList();
});
