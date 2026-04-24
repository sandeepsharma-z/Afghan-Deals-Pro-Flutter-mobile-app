import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Fetches all category_data maps for active car listings (cached, shared).
final _carCatDataProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final rows = await Supabase.instance.client
      .from('listings')
      .select('category_data')
      .eq('category', 'cars')
      .eq('is_active', true) as List<dynamic>;
  return rows
      .map((r) => (r['category_data'] as Map<String, dynamic>?) ?? <String, dynamic>{})
      .toList();
});

List<String> _distinct(List<Map<String, dynamic>> data, String key) {
  final set = <String>{};
  for (final cd in data) {
    final v = cd[key]?.toString().trim() ?? '';
    if (v.isNotEmpty) set.add(v);
  }
  return set.toList()..sort();
}

final carMakesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final data = await ref.watch(_carCatDataProvider.future);
  return _distinct(data, 'make');
});

final carModelsForMakeProvider =
    FutureProvider.autoDispose.family<List<String>, String>((ref, make) async {
  final data = await ref.watch(_carCatDataProvider.future);
  final filtered = make.isEmpty
      ? data
      : data
          .where((cd) =>
              (cd['make']?.toString() ?? '').toLowerCase() == make.toLowerCase())
          .toList();
  return _distinct(filtered, 'model');
});

final carSubModelsForMakeProvider =
    FutureProvider.autoDispose.family<List<String>, String>((ref, make) async {
  final data = await ref.watch(_carCatDataProvider.future);
  final filtered = make.isEmpty
      ? data
      : data
          .where((cd) =>
              (cd['make']?.toString() ?? '').toLowerCase() == make.toLowerCase())
          .toList();
  return _distinct(filtered, 'sub_model');
});

final carTransmissionsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final data = await ref.watch(_carCatDataProvider.future);
  return _distinct(data, 'transmission');
});

final carFuelTypesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final data = await ref.watch(_carCatDataProvider.future);
  return _distinct(data, 'fuel_type');
});

final carDealTypesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final data = await ref.watch(_carCatDataProvider.future);
  return _distinct(data, 'deal_type');
});

final carDrivelinesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final data = await ref.watch(_carCatDataProvider.future);
  return _distinct(data, 'driveline');
});

final carCylindersProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final data = await ref.watch(_carCatDataProvider.future);
  return _distinct(data, 'cylinders');
});

final carColorsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final data = await ref.watch(_carCatDataProvider.future);
  return _distinct(data, 'color');
});

final carSpecsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final data = await ref.watch(_carCatDataProvider.future);
  final fromSpecs = _distinct(data, 'specs');
  if (fromSpecs.isNotEmpty) return fromSpecs;
  return _distinct(data, 'regional_specs');
});
