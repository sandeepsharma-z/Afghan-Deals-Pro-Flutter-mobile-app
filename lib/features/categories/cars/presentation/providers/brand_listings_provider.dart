import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../features/listings/data/models/car_sale_model.dart';

dynamic _applySubcategoryFilter(dynamic query, String rawSubcategory) {
  final key = rawSubcategory.trim().toLowerCase();
  if (key.contains('used')) return query.or('subcategory.ilike.%used%');
  if (key.contains('new')) return query.or('subcategory.ilike.%new%');
  if (key.contains('export')) return query.or('subcategory.ilike.%export%');
  if (key.contains('rental')) return query.or('subcategory.ilike.%rental%');
  return query.eq('subcategory', key);
}

class BrandModelOption {
  final String name;
  final String? iconUrl;
  const BrandModelOption({required this.name, this.iconUrl});
}

class BrandMeta {
  final List<BrandModelOption> modelOptions;
  final int minYear;
  final int maxYear;
  const BrandMeta({
    required this.modelOptions,
    required this.minYear,
    required this.maxYear,
  });

  List<String> get models => modelOptions.map((m) => m.name).toList();

  String? iconForModel(String model) {
    for (final m in modelOptions) {
      if (m.name.toLowerCase() == model.toLowerCase()) return m.iconUrl;
    }
    return null;
  }
}

class BrandMetaFilter {
  final String brand;
  final String subcategory;

  const BrandMetaFilter({
    required this.brand,
    required this.subcategory,
  });

  @override
  bool operator ==(Object other) =>
      other is BrandMetaFilter &&
      other.brand == brand &&
      other.subcategory == subcategory;

  @override
  int get hashCode => Object.hash(brand, subcategory);
}

/// Fetches unique models + year range for a given brand from Supabase.
final brandMetaProvider = FutureProvider.autoDispose
    .family<BrandMeta, BrandMetaFilter>((ref, filter) async {
  final brandPattern = '%${filter.brand.trim()}%';
  // Derive models + year range directly from listings (make/model/year).
  var baseMetaQuery = Supabase.instance.client
      .from('listings')
      .select('category_data')
      .eq('category', 'cars')
      .eq('is_active', true);
  baseMetaQuery = _applySubcategoryFilter(baseMetaQuery, filter.subcategory);
  var response =
      await baseMetaQuery.filter('category_data->>make', 'ilike', brandPattern);

  var list = response as List<dynamic>;
  if (list.isEmpty) {
    // Safety fallback for inconsistent stored make values.
    var fallbackQuery = Supabase.instance.client
        .from('listings')
        .select('category_data')
        .eq('category', 'cars')
        .eq('is_active', true);
    fallbackQuery = _applySubcategoryFilter(fallbackQuery, filter.subcategory);
    final fallback = await fallbackQuery;
    final brandLower = filter.brand.trim().toLowerCase();
    list = (fallback as List<dynamic>).where((item) {
      final cd = (item['category_data'] as Map<String, dynamic>?) ?? {};
      final make = cd['make']?.toString().toLowerCase().trim() ?? '';
      return make.contains(brandLower);
    }).toList();
  }
  final modelDisplayByKey = <String, String>{};
  final modelIconByKey = <String, String?>{};
  final years = <int>[];

  for (final item in list) {
    final cd = (item['category_data'] as Map<String, dynamic>?) ?? {};
    final model = (cd['model']?.toString() ?? '').trim();
    if (model.isNotEmpty) {
      final key = model.toLowerCase();
      modelDisplayByKey.putIfAbsent(key, () => model);
      final icon = (cd['model_icon_url']?.toString() ?? '').trim();
      if (icon.isNotEmpty && !(modelIconByKey[key]?.isNotEmpty ?? false)) {
        modelIconByKey[key] = icon;
      }
    }
    final year = int.tryParse(cd['year']?.toString() ?? '');
    if (year != null) years.add(year);
  }

  final currentYear = DateTime.now().year;
  final minYear =
      years.isNotEmpty ? years.reduce((a, b) => a < b ? a : b) : 2000;
  final maxYear =
      years.isNotEmpty ? years.reduce((a, b) => a > b ? a : b) : currentYear;

  return BrandMeta(
    modelOptions: (modelDisplayByKey.values.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())))
        .map((m) =>
            BrandModelOption(name: m, iconUrl: modelIconByKey[m.toLowerCase()]))
        .toList(),
    minYear: minYear,
    maxYear: maxYear,
  );
});

class BrandFilter {
  final String subcategory;
  final String brand;
  final String? model;
  final int fromYear;
  final int toYear;

  const BrandFilter({
    required this.subcategory,
    required this.brand,
    this.model,
    required this.fromYear,
    required this.toYear,
  });

  @override
  bool operator ==(Object other) =>
      other is BrandFilter &&
      other.subcategory == subcategory &&
      other.brand == brand &&
      other.model == model &&
      other.fromYear == fromYear &&
      other.toYear == toYear;

  @override
  int get hashCode => Object.hash(subcategory, brand, model, fromYear, toYear);
}

/// Fetches listings filtered by brand + optional model + year range.
final brandListingsProvider = FutureProvider.autoDispose
    .family<List<CarSaleModel>, BrandFilter>((ref, filter) async {
  final brandPattern = '%${filter.brand.trim()}%';
  var query = Supabase.instance.client
      .from('listings')
      .select(
          'id,seller_id,title,description,seller_name,price,currency,images,city,region,is_featured,created_at,category_data')
      .eq('category', 'cars')
      .eq('is_active', true);
  query = _applySubcategoryFilter(query, filter.subcategory);
  query = query.filter('category_data->>make', 'ilike', brandPattern);

  if (filter.model != null && filter.model!.isNotEmpty) {
    query = query.filter(
      'category_data->>model',
      'ilike',
      '%${filter.model!.trim()}%',
    );
  }

  var response = await query.order('created_at', ascending: false);

  var all = (response as List<dynamic>)
      .map((e) => CarSaleModel.fromMap(e as Map<String, dynamic>))
      .toList();

  if (all.isEmpty) {
    // Safety fallback for exact-value mismatch in make/model text.
    var fallbackQuery = Supabase.instance.client
        .from('listings')
        .select(
            'id,seller_id,title,description,seller_name,price,currency,images,city,region,is_featured,created_at,category_data')
        .eq('category', 'cars')
        .eq('is_active', true);
    fallbackQuery = _applySubcategoryFilter(fallbackQuery, filter.subcategory);
    final fallback = await fallbackQuery.order('created_at', ascending: false);

    final brandLower = filter.brand.trim().toLowerCase();
    final modelLower = filter.model?.trim().toLowerCase();

    all = (fallback as List<dynamic>)
        .map((e) => CarSaleModel.fromMap(e as Map<String, dynamic>))
        .where((car) {
      final make = car.make.trim().toLowerCase();
      final model = car.model.trim().toLowerCase();
      if (!make.contains(brandLower)) return false;
      if (modelLower != null && modelLower.isNotEmpty) {
        return model.contains(modelLower);
      }
      return true;
    }).toList();
  }

  // Filter by year range in Dart (JSONB range queries are complex in Supabase)
  return all.where((car) {
    final year = int.tryParse(car.year) ?? 0;
    if (year == 0) return true;
    return year >= filter.fromYear && year <= filter.toYear;
  }).toList();
});
