import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/* ══════════════════════════════════════════════════════════════
   RUN THIS SQL IN SUPABASE → SQL EDITOR BEFORE USING ADMIN:

   CREATE TABLE IF NOT EXISTS filter_options (
     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
     category TEXT NOT NULL,
     filter_type TEXT NOT NULL,
     value TEXT NOT NULL,
     sort_order INTEGER DEFAULT 0,
     is_active BOOLEAN DEFAULT true,
     created_at TIMESTAMPTZ DEFAULT NOW()
   );

   CREATE TABLE IF NOT EXISTS regions (
     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
     country TEXT NOT NULL DEFAULT 'Afghanistan',
     region_name TEXT NOT NULL,
     cities TEXT[] DEFAULT '{}',
     is_active BOOLEAN DEFAULT true,
     sort_order INTEGER DEFAULT 0,
     created_at TIMESTAMPTZ DEFAULT NOW()
   );

   CREATE TABLE IF NOT EXISTS app_settings (
     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
     category TEXT NOT NULL,
     setting_key TEXT NOT NULL,
     setting_value TEXT NOT NULL,
     updated_at TIMESTAMPTZ DEFAULT NOW(),
     UNIQUE(category, setting_key)
   );

   ALTER TABLE filter_options ENABLE ROW LEVEL SECURITY;
   ALTER TABLE regions ENABLE ROW LEVEL SECURITY;
   ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

   CREATE POLICY "public_read_filter_options" ON filter_options FOR SELECT USING (true);
   CREATE POLICY "public_read_regions" ON regions FOR SELECT USING (true);
   CREATE POLICY "public_read_app_settings" ON app_settings FOR SELECT USING (true);
   ══════════════════════════════════════════════════════════════ */

// ── Models ─────────────────────────────────────────────────────────────────

class FilterOption {
  final String id;
  final String category;
  final String filterType;
  final String value;
  final int sortOrder;
  final bool isActive;

  const FilterOption({
    required this.id,
    required this.category,
    required this.filterType,
    required this.value,
    required this.sortOrder,
    required this.isActive,
  });

  factory FilterOption.fromMap(Map<String, dynamic> m) => FilterOption(
        id: m['id']?.toString() ?? '',
        category: m['category']?.toString() ?? '',
        filterType: m['filter_type']?.toString() ?? '',
        value: m['value']?.toString() ?? '',
        sortOrder: (m['sort_order'] as num?)?.toInt() ?? 0,
        isActive: m['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'category': category,
        'filter_type': filterType,
        'value': value,
        'sort_order': sortOrder,
        'is_active': isActive,
      };

  FilterOption copyWith({
    String? value,
    int? sortOrder,
    bool? isActive,
  }) =>
      FilterOption(
        id: id,
        category: category,
        filterType: filterType,
        value: value ?? this.value,
        sortOrder: sortOrder ?? this.sortOrder,
        isActive: isActive ?? this.isActive,
      );
}

class AppRegion {
  final String id;
  final String country;
  final String regionName;
  final List<String> cities;
  final bool isActive;
  final int sortOrder;

  const AppRegion({
    required this.id,
    required this.country,
    required this.regionName,
    required this.cities,
    required this.isActive,
    required this.sortOrder,
  });

  factory AppRegion.fromMap(Map<String, dynamic> m) => AppRegion(
        id: m['id']?.toString() ?? '',
        country: m['country']?.toString() ?? 'Afghanistan',
        regionName: m['region_name']?.toString() ?? '',
        cities: (m['cities'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        isActive: m['is_active'] as bool? ?? true,
        sortOrder: (m['sort_order'] as num?)?.toInt() ?? 0,
      );
}

class AppSetting {
  final String id;
  final String category;
  final String settingKey;
  final String settingValue;

  const AppSetting({
    required this.id,
    required this.category,
    required this.settingKey,
    required this.settingValue,
  });

  factory AppSetting.fromMap(Map<String, dynamic> m) => AppSetting(
        id: m['id']?.toString() ?? '',
        category: m['category']?.toString() ?? '',
        settingKey: m['setting_key']?.toString() ?? '',
        settingValue: m['setting_value']?.toString() ?? '',
      );
}

class AdminStats {
  final int totalListings;
  final int activeListings;
  final int filterOptions;
  final int regions;

  const AdminStats({
    required this.totalListings,
    required this.activeListings,
    required this.filterOptions,
    required this.regions,
  });
}

// ── Helper ─────────────────────────────────────────────────────────────────

/// Fetch admin-managed filter values. Returns [] if table missing / no data.
Future<List<String>> fetchAdminFilterOptions(
    String category, String filterType) async {
  try {
    final res = await Supabase.instance.client
        .from('filter_options')
        .select('value')
        .eq('category', category)
        .eq('filter_type', filterType)
        .eq('is_active', true)
        .order('sort_order');
    return (res as List).map((e) => e['value'].toString()).toList();
  } catch (_) {
    return [];
  }
}

/// Fetch all region names as a flat list. Returns [] if table missing.
Future<List<String>> fetchAdminRegionNames() async {
  try {
    final res = await Supabase.instance.client
        .from('regions')
        .select('region_name')
        .eq('is_active', true)
        .order('sort_order');
    return (res as List).map((e) => e['region_name'].toString()).toList();
  } catch (_) {
    return [];
  }
}

/// Fetch all cities across all regions. Returns [] if table missing.
Future<List<String>> fetchAdminAllCities() async {
  try {
    final res = await Supabase.instance.client
        .from('regions')
        .select('cities')
        .eq('is_active', true)
        .order('sort_order');
    final cities = (res as List)
        .expand((e) => (e['cities'] as List<dynamic>? ?? []).map((c) => c.toString()))
        .toSet()
        .toList()
      ..sort();
    return cities;
  } catch (_) {
    return [];
  }
}

/// Fetch a single app_setting value; returns fallback if missing.
Future<String> fetchSetting(String category, String key, String fallback) async {
  try {
    final res = await Supabase.instance.client
        .from('app_settings')
        .select('setting_value')
        .eq('category', category)
        .eq('setting_key', key)
        .maybeSingle();
    if (res != null) return res['setting_value'].toString();
  } catch (_) {}
  return fallback;
}

// ── Providers ───────────────────────────────────────────────────────────────

final allFilterOptionsProvider =
    FutureProvider.autoDispose<List<FilterOption>>((ref) async {
  try {
    final res = await Supabase.instance.client
        .from('filter_options')
        .select()
        .order('category')
        .order('filter_type')
        .order('sort_order');
    return (res as List).map((e) => FilterOption.fromMap(e)).toList();
  } catch (_) {
    return [];
  }
});

final allRegionsProvider =
    FutureProvider.autoDispose<List<AppRegion>>((ref) async {
  try {
    final res = await Supabase.instance.client
        .from('regions')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return (res as List).map((e) => AppRegion.fromMap(e)).toList();
  } catch (_) {
    return [];
  }
});

final allRegionsAdminProvider =
    FutureProvider.autoDispose<List<AppRegion>>((ref) async {
  try {
    final res = await Supabase.instance.client
        .from('regions')
        .select()
        .order('sort_order');
    return (res as List).map((e) => AppRegion.fromMap(e)).toList();
  } catch (_) {
    return [];
  }
});

final allAppSettingsProvider =
    FutureProvider.autoDispose<List<AppSetting>>((ref) async {
  try {
    final res = await Supabase.instance.client
        .from('app_settings')
        .select()
        .order('category');
    return (res as List).map((e) => AppSetting.fromMap(e)).toList();
  } catch (_) {
    return [];
  }
});

final adminStatsProvider =
    FutureProvider.autoDispose<AdminStats>((ref) async {
  try {
    final listRes = await Supabase.instance.client
        .from('listings')
        .select('is_active');
    final all = listRes as List;
    final active = all.where((l) => l['is_active'] == true).length;

    int filterCount = 0;
    int regionCount = 0;
    try {
      final fr = await Supabase.instance.client.from('filter_options').select('id');
      filterCount = (fr as List).length;
    } catch (_) {}
    try {
      final rr = await Supabase.instance.client.from('regions').select('id');
      regionCount = (rr as List).length;
    } catch (_) {}

    return AdminStats(
      totalListings: all.length,
      activeListings: active,
      filterOptions: filterCount,
      regions: regionCount,
    );
  } catch (_) {
    return const AdminStats(
        totalListings: 0, activeListings: 0, filterOptions: 0, regions: 0);
  }
});

// ── Repository ──────────────────────────────────────────────────────────────

class AdminRepository {
  final _db = Supabase.instance.client;

  // ── Filter Options ──────────────────────────────────────────────────────
  Future<void> addFilterOption(
      String category, String filterType, String value, int sortOrder) async {
    await _db.from('filter_options').insert({
      'category': category,
      'filter_type': filterType,
      'value': value,
      'sort_order': sortOrder,
      'is_active': true,
    });
  }

  Future<void> updateFilterOption(
      String id, String value, bool isActive) async {
    await _db.from('filter_options').update({
      'value': value,
      'is_active': isActive,
    }).eq('id', id);
  }

  Future<void> deleteFilterOption(String id) async {
    await _db.from('filter_options').delete().eq('id', id);
  }

  Future<void> reorderFilterOption(String id, int newOrder) async {
    await _db
        .from('filter_options')
        .update({'sort_order': newOrder}).eq('id', id);
  }

  // ── Regions ─────────────────────────────────────────────────────────────
  Future<void> addRegion(String regionName, String country, int sortOrder) async {
    await _db.from('regions').insert({
      'region_name': regionName,
      'country': country,
      'cities': <String>[],
      'is_active': true,
      'sort_order': sortOrder,
    });
  }

  Future<void> updateRegion(
      String id, String regionName, bool isActive) async {
    await _db.from('regions').update({
      'region_name': regionName,
      'is_active': isActive,
    }).eq('id', id);
  }

  Future<void> updateRegionCities(String id, List<String> cities) async {
    await _db.from('regions').update({'cities': cities}).eq('id', id);
  }

  Future<void> deleteRegion(String id) async {
    await _db.from('regions').delete().eq('id', id);
  }

  // ── App Settings ────────────────────────────────────────────────────────
  Future<void> upsertSetting(
      String category, String key, String value) async {
    await _db.from('app_settings').upsert({
      'category': category,
      'setting_key': key,
      'setting_value': value,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'category,setting_key');
  }

  Future<void> deleteSetting(String id) async {
    await _db.from('app_settings').delete().eq('id', id);
  }
}

final adminRepositoryProvider =
    Provider<AdminRepository>((ref) => AdminRepository());

// ── Category & FilterType constants ────────────────────────────────────────

const kFilterCategories = [
  'cars',
  'mobiles',
  'electronics',
  'furniture',
  'jobs',
  'properties',
  'spare_parts',
  'classifieds',
  'global',
];

const kFilterTypesByCategory = <String, List<String>>{
  'cars': [
    'transmission',
    'fuel_type',
    'body_type',
    'driveline',
    'specs',
    'exterior_color',
    'interior_color',
    'seller_type',
  ],
  'mobiles': [
    'condition',
    'age',
    'warranty',
    'seller_type',
    'screen_size',
    'storage',
    'color',
    'damage_details',
    'battery_health',
    'version',
  ],
  'electronics': [
    'condition',
    'age',
    'warranty',
    'seller_type',
  ],
  'furniture': [
    'condition',
    'age',
    'seller_type',
    'usage',
    'room_type',
    'material',
    'color',
    'shape',
    'type',
    'fill_material',
  ],
  'jobs': [
    'job_type',
    'experience',
    'industry',
    'education',
    'seller_type',
  ],
  'properties': [
    'property_type',
    'purpose',
    'furnishing',
    'seller_type',
  ],
  'spare_parts': [
    'condition',
    'seller_type',
  ],
  'classifieds': [
    'condition',
    'age',
    'seller_type',
  ],
  'global': [
    'condition',
    'age',
    'warranty',
    'seller_type',
  ],
};

const kPriceCategories = [
  'cars',
  'mobiles',
  'electronics',
  'furniture',
  'jobs',
  'properties',
  'spare_parts',
  'classifieds',
];

const kDefaultMaxPrices = <String, String>{
  'cars': '500000',
  'mobiles': '150000',
  'electronics': '500000',
  'furniture': '200000',
  'jobs': '100000',
  'properties': '5000000',
  'spare_parts': '200000',
  'classifieds': '100000',
};
