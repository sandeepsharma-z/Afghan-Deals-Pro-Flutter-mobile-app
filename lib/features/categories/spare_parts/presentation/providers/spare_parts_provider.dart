import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SparePartBrand {
  final String name;
  final String slug;
  final String? logoUrl;
  final int sortOrder;

  const SparePartBrand({
    required this.name,
    required this.slug,
    this.logoUrl,
    required this.sortOrder,
  });

  factory SparePartBrand.fromMap(Map<String, dynamic> map) {
    return SparePartBrand(
      name: map['name']?.toString().trim() ?? '',
      slug: map['slug']?.toString().trim() ?? '',
      logoUrl: map['logo_url']?.toString(),
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class SparePartWorkingHour {
  final String day;
  final String morning;
  final String evening;

  const SparePartWorkingHour({
    required this.day,
    required this.morning,
    required this.evening,
  });
}

class SparePartListing {
  final String id;
  final String title;
  final String description;
  final String sellerId;
  final String sellerName;
  final String currency;
  final double? price;
  final List<String> images;
  final String? city;
  final String? region;
  final DateTime createdAt;
  final Map<String, dynamic> categoryData;
  final String subcategory;

  const SparePartListing({
    required this.id,
    required this.title,
    required this.description,
    required this.sellerId,
    required this.sellerName,
    required this.currency,
    required this.price,
    required this.images,
    required this.city,
    required this.region,
    required this.createdAt,
    required this.categoryData,
    this.subcategory = '',
  });

  factory SparePartListing.fromMap(Map<String, dynamic> map) {
    final rawCategoryData = map['category_data'];
    final categoryData = rawCategoryData is Map<String, dynamic>
        ? rawCategoryData
        : <String, dynamic>{};

    final rawImages = map['images'];
    final images = rawImages is List
        ? rawImages
            .whereType<String>()
            .where((e) => e.trim().isNotEmpty)
            .toList()
        : <String>[];

    return SparePartListing(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Untitled',
      description: map['description']?.toString() ?? '',
      sellerId: map['seller_id']?.toString() ?? '',
      sellerName: map['seller_name']?.toString() ?? '',
      currency: map['currency']?.toString() ?? 'AFN',
      price: (map['price'] as num?)?.toDouble(),
      images: images,
      city: map['city']?.toString(),
      region: map['region']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      categoryData: categoryData,
      subcategory: map['subcategory']?.toString() ?? '',
    );
  }

  String _field(List<String> keys) {
    for (final key in keys) {
      final value = categoryData[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  String get make => _field(const ['make', 'brand']);

  String get model => _field(const ['model', 'part_model', 'item_model']);

  String get year => _field(const ['year', 'manufacture_year']);

  String get mileage => _field(const ['mileage', 'km', 'kilometers']);

  String get address => _field(const ['address', 'location', 'map_address']);

  String get phone => _field(
        const ['phone', 'seller_phone', 'contact_number', 'mobile', 'whatsapp'],
      );

  String get mapUrl => _field(const ['map_url', 'google_map_url', 'maps_link']);

  String get location {
    final value = <String>[];
    if (city != null && city!.trim().isNotEmpty) value.add(city!.trim());
    if (region != null && region!.trim().isNotEmpty) value.add(region!.trim());
    if (address.trim().isNotEmpty) value.add(address.trim());
    if (value.isEmpty) return 'UAE';
    return value.join(', ');
  }

  String get subtitle {
    if (model.isNotEmpty) return model;
    if (make.isNotEmpty) return make;
    return description;
  }

  String get yearMileageLine {
    final y = year;
    final m = mileage;
    if (y.isEmpty && m.isEmpty) return '';
    if (y.isEmpty) return 'Mileage: $m';
    if (m.isEmpty) return 'Year: $y';
    return 'Year: $y  Mileage: $m';
  }

  String get formattedPrice {
    if (price == null) return 'Price on request';
    final formatted = NumberFormat('#,##0', 'en_US').format(price!.round());
    return '$currency $formatted';
  }

  List<SparePartWorkingHour> get workingHours {
    final rows = <SparePartWorkingHour>[];

    final fromMap = categoryData['working_hours'];
    if (fromMap is Map) {
      for (final entry in fromMap.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is Map) {
          final morning = value['morning']?.toString() ?? '-';
          final evening = value['evening']?.toString() ?? '-';
          rows.add(
            SparePartWorkingHour(
                day: _toTitle(key), morning: morning, evening: evening),
          );
        }
      }
    }

    if (rows.isNotEmpty) return rows;

    return const [
      SparePartWorkingHour(
          day: 'Saturday', morning: '9 AM - 1 PM', evening: '4 PM - 10 PM'),
      SparePartWorkingHour(
          day: 'Sunday', morning: '9 AM - 1 PM', evening: '4 PM - 10 PM'),
      SparePartWorkingHour(
          day: 'Monday', morning: '9 AM - 1 PM', evening: '4 PM - 10 PM'),
    ];
  }

  static String _toTitle(String input) {
    return input
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}

class SparePartFilter {
  final String? make;
  final String? model;
  final int? fromYear;
  final int? toYear;
  final String? search;
  final String? region;

  const SparePartFilter({
    this.make,
    this.model,
    this.fromYear,
    this.toYear,
    this.search,
    this.region,
  });

  @override
  bool operator ==(Object other) {
    return other is SparePartFilter &&
        other.make == make &&
        other.model == model &&
        other.fromYear == fromYear &&
        other.toYear == toYear &&
        other.search == search &&
        other.region == region;
  }

  @override
  int get hashCode =>
      Object.hash(make, model, fromYear, toYear, search, region);
}

class SparePartModelOption {
  final String name;
  final String? iconUrl;
  final int? minYear;
  final int? maxYear;

  const SparePartModelOption({
    required this.name,
    this.iconUrl,
    this.minYear,
    this.maxYear,
  });
}

class SparePartBrandMeta {
  final List<SparePartModelOption> models;
  final int minYear;
  final int maxYear;

  const SparePartBrandMeta({
    required this.models,
    required this.minYear,
    required this.maxYear,
  });
}

class SparePartBrandMetaFilter {
  final String brandName;
  final String brandSlug;

  const SparePartBrandMetaFilter({
    required this.brandName,
    required this.brandSlug,
  });

  @override
  bool operator ==(Object other) {
    return other is SparePartBrandMetaFilter &&
        other.brandName == brandName &&
        other.brandSlug == brandSlug;
  }

  @override
  int get hashCode => Object.hash(brandName, brandSlug);
}

bool _contains(String source, String? query) {
  if (query == null || query.trim().isEmpty) return true;
  return source.toLowerCase().contains(query.trim().toLowerCase());
}

final sparePartBrandsProvider =
    FutureProvider.autoDispose<List<SparePartBrand>>((ref) async {
  // Primary source: subcategories under "spare-parts" (managed in admin page).
  final subcategoryResponse = await Supabase.instance.client
      .from('subcategories')
      .select('name, slug, icon_url, sort_order')
      .eq('category_slug', 'spare-parts')
      .eq('is_active', true)
      .order('sort_order', ascending: true)
      .order('name', ascending: true);

  var subcategoryRows = (subcategoryResponse as List<dynamic>);
  if (subcategoryRows.isEmpty) {
    final legacySubcategoryResponse = await Supabase.instance.client
        .from('subcategories')
        .select('name, slug, icon_url, sort_order')
        .eq('category_slug', 'spare_parts')
        .eq('is_active', true)
        .order('sort_order', ascending: true)
        .order('name', ascending: true);
    subcategoryRows = (legacySubcategoryResponse as List<dynamic>);
  }
  var rows = subcategoryRows
      .map((e) => Map<String, dynamic>.from(e as Map))
      .map((m) => <String, dynamic>{
            'name': m['name'],
            'slug': m['slug'],
            'logo_url': m['icon_url'],
            'sort_order': m['sort_order'],
          })
      .toList();

  // Fallback: legacy car_makes source.
  if (rows.isEmpty) {
    var response = await Supabase.instance.client
        .from('car_makes')
        .select('name, slug, logo_url, sort_order, subcategory_slug')
        .eq('is_active', true)
        .eq('subcategory_slug', 'spare-parts')
        .order('sort_order', ascending: true)
        .order('name', ascending: true);
    rows = (response as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  if (rows.isEmpty) {
    final response = await Supabase.instance.client
        .from('car_makes')
        .select('name, slug, logo_url, sort_order, subcategory_slug')
        .eq('is_active', true)
        .eq('subcategory_slug', 'spare_parts')
        .order('sort_order', ascending: true)
        .order('name', ascending: true);
    rows = (response as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  final seen = <String>{};
  final brands = <SparePartBrand>[];

  for (final row in rows) {
    final brand = SparePartBrand.fromMap(row);
    final key = brand.slug.trim().toLowerCase();
    if (key.isEmpty || seen.contains(key)) continue;
    seen.add(key);
    brands.add(brand);
  }

  if (brands.isNotEmpty) return brands;

  return const [
    SparePartBrand(name: 'Mercedes', slug: 'mercedes', sortOrder: 1),
    SparePartBrand(name: 'Tesla', slug: 'tesla', sortOrder: 2),
    SparePartBrand(name: 'BMW', slug: 'bmw', sortOrder: 3),
    SparePartBrand(name: 'Toyota', slug: 'toyota', sortOrder: 4),
    SparePartBrand(name: 'Volvo', slug: 'volvo', sortOrder: 5),
    SparePartBrand(name: 'Bugatti', slug: 'bugatti', sortOrder: 6),
    SparePartBrand(name: 'Honda', slug: 'honda', sortOrder: 7),
  ];
});

final sparePartBrandMetaProvider = FutureProvider.autoDispose
    .family<SparePartBrandMeta, SparePartBrandMetaFilter>((ref, filter) async {
  final modelNameByKey = <String, String>{};
  final modelIconByKey = <String, String?>{};
  final modelMinYearByKey = <String, int?>{};
  final modelMaxYearByKey = <String, int?>{};
  final allYears = <int>[];

  final brandLower = filter.brandName.trim().toLowerCase();
  final slugLower = filter.brandSlug.trim().toLowerCase();

  final listingResponse = await Supabase.instance.client
      .from('listings')
      .select('category_data, subcategory')
      .inFilter('category', const ['spare-parts', 'spare_parts']).eq(
          'is_active', true);

  final listingRows = (listingResponse as List<dynamic>)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();

  for (final row in listingRows) {
    final cd = row['category_data'];
    if (cd is! Map<String, dynamic>) continue;

    final make = (cd['make']?.toString() ?? cd['brand']?.toString() ?? '')
        .trim()
        .toLowerCase();

    // Also check subcategory field (admin saves subcategory = brand slug)
    final subcat = (row['subcategory']?.toString() ?? '').trim().toLowerCase();

    final isMatch = make == brandLower ||
        make == slugLower ||
        make.contains(brandLower) ||
        brandLower.contains(make) ||
        subcat == slugLower ||
        subcat.contains(slugLower);
    if (make.isEmpty && subcat.isEmpty) continue;
    if (!isMatch) continue;

    final model = (cd['model']?.toString() ??
            cd['part_model']?.toString() ??
            cd['item_model']?.toString() ??
            '')
        .trim();
    if (model.isNotEmpty) {
      final key = model.toLowerCase();
      modelNameByKey.putIfAbsent(key, () => model);
      final icon = (cd['model_icon_url']?.toString() ?? '').trim();
      if (icon.isNotEmpty && !(modelIconByKey[key]?.isNotEmpty ?? false)) {
        modelIconByKey[key] = icon;
      }
    }

    final year = int.tryParse(
      (cd['year']?.toString() ?? cd['manufacture_year']?.toString() ?? '')
          .trim(),
    );
    if (year != null) allYears.add(year);
  }

  // Fallback/override from car_models table (managed in admin "Manage Models")
  try {
    final modelsResponse = await Supabase.instance.client
        .from('car_models')
        .select('name, icon_url, min_year, max_year, sort_order')
        .eq('brand_slug', slugLower)
        .eq('is_active', true)
        .order('sort_order', ascending: true)
        .order('name', ascending: true);

    final modelRows = (modelsResponse as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    for (final m in modelRows) {
      final name = (m['name']?.toString() ?? '').trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();

      modelNameByKey.putIfAbsent(key, () => name);
      final icon = (m['icon_url']?.toString() ?? '').trim();
      if (icon.isNotEmpty) {
        modelIconByKey[key] = icon;
      }

      final minY = (m['min_year'] as num?)?.toInt();
      final maxY = (m['max_year'] as num?)?.toInt();
      if (minY != null) {
        modelMinYearByKey[key] = minY;
        allYears.add(minY);
      }
      if (maxY != null) {
        modelMaxYearByKey[key] = maxY;
        allYears.add(maxY);
      }
    }
  } catch (_) {
    // Keep listing-derived fallback if car_models is unavailable.
  }

  final currentYear = DateTime.now().year;
  final minYear = allYears.isEmpty
      ? (currentYear - 10)
      : allYears.reduce((a, b) => a < b ? a : b);
  final maxYear =
      allYears.isEmpty ? currentYear : allYears.reduce((a, b) => a > b ? a : b);

  final modelNames = modelNameByKey.values.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  final models = modelNames.map((name) {
    final key = name.toLowerCase();
    return SparePartModelOption(
      name: name,
      iconUrl: modelIconByKey[key],
      minYear: modelMinYearByKey[key],
      maxYear: modelMaxYearByKey[key],
    );
  }).toList();

  return SparePartBrandMeta(
    models: models,
    minYear: minYear,
    maxYear: maxYear,
  );
});

final sparePartListingsProvider = FutureProvider.autoDispose
    .family<List<SparePartListing>, SparePartFilter>((ref, filter) async {
  final response = await Supabase.instance.client
      .from('listings')
      .select(
        'id, title, description, seller_id, seller_name, price, currency, images, city, region, created_at, category_data, subcategory',
      )
      .inFilter('category', const ['spare-parts', 'spare_parts'])
      .eq('is_active', true)
      .order('created_at', ascending: false);

  final all = (response as List<dynamic>)
      .map((e) => SparePartListing.fromMap(Map<String, dynamic>.from(e)))
      .toList();

  return all.where((item) {
    // match by category_data.make OR subcategory slug OR title
    final makeMatch = _contains(item.make, filter.make) ||
        _contains(item.title, filter.make) ||
        _contains(item.subcategory, filter.make);
    if (!makeMatch) return false;

    if (filter.model != null && filter.model!.trim().isNotEmpty) {
      final modelMatch = _contains(item.model, filter.model) ||
          _contains(item.title, filter.model) ||
          _contains(item.description, filter.model);
      if (!modelMatch) return false;
    }

    final year = int.tryParse(item.year);
    if (filter.fromYear != null && year != null && year < filter.fromYear!) {
      return false;
    }
    if (filter.toYear != null && year != null && year > filter.toYear!) {
      return false;
    }

    final searchText =
        '${item.title} ${item.description} ${item.make} ${item.model}';
    final searchMatch = _contains(searchText, filter.search);
    if (!searchMatch) return false;

    final regionText =
        '${item.city ?? ''} ${item.region ?? ''} ${item.address}';
    final regionMatch = _contains(regionText, filter.region);
    return regionMatch;
  }).toList();
});

final sparePartRegionsProvider =
    FutureProvider.autoDispose.family<List<String>, String?>((ref, make) async {
  final list = await ref.watch(
    sparePartListingsProvider(SparePartFilter(make: make)).future,
  );

  final regions = <String>{};
  for (final item in list) {
    if (item.city != null && item.city!.trim().isNotEmpty) {
      regions.add(item.city!.trim());
    }
    if (item.region != null && item.region!.trim().isNotEmpty) {
      regions.add(item.region!.trim());
    }
    if (item.address.isNotEmpty) {
      regions.add(item.address);
    }
  }

  final sorted = regions.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return sorted;
});
