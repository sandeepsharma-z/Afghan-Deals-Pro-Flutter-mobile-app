import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SellSubcategory {
  final String name;
  final String slug;

  const SellSubcategory({
    required this.name,
    required this.slug,
  });

  factory SellSubcategory.fromMap(Map<String, dynamic> map) {
    return SellSubcategory(
      name: (map['name'] ?? '').toString(),
      slug: (map['slug'] ?? '').toString(),
    );
  }
}

const _electronicsSubcategories = [
  SellSubcategory(name: 'TVs, Video-Audio', slug: 'tvs-video-audio'),
  SellSubcategory(
      name: 'Kitchen & Other Appliance', slug: 'kitchen-other-appliance'),
  SellSubcategory(name: 'Fridges', slug: 'fridges'),
  SellSubcategory(name: 'Cameras & Lenses', slug: 'cameras-lenses'),
  SellSubcategory(name: 'Washing Machines', slug: 'washing-machines'),
  SellSubcategory(name: 'ACs', slug: 'acs'),
  SellSubcategory(name: 'Games & Entertainment', slug: 'games-entertainment'),
];

const _furnitureSubcategories = [
  SellSubcategory(name: 'Sofas', slug: 'sofas'),
  SellSubcategory(name: 'Dining', slug: 'dining'),
  SellSubcategory(name: 'Kids Furniture', slug: 'kids-furniture'),
  SellSubcategory(name: 'Wardrobes', slug: 'wardrobes'),
  SellSubcategory(name: 'Home Decor & Garden', slug: 'home-decor-garden'),
  SellSubcategory(name: 'Beds', slug: 'beds'),
  SellSubcategory(name: 'Other Household Items', slug: 'other-household-items'),
];

const _sparePartsSubcategories = [
  SellSubcategory(name: 'Toyota', slug: 'toyota'),
  SellSubcategory(name: 'Nissan', slug: 'nissan'),
  SellSubcategory(name: 'Mercedes', slug: 'mercedes'),
  SellSubcategory(name: 'BMW', slug: 'bmw'),
  SellSubcategory(name: 'Hyundai', slug: 'hyundai'),
  SellSubcategory(name: 'Kia', slug: 'kia'),
  SellSubcategory(name: 'Honda', slug: 'honda'),
  SellSubcategory(name: 'Lexus', slug: 'lexus'),
  SellSubcategory(name: 'Ford', slug: 'ford'),
  SellSubcategory(name: 'Other', slug: 'other'),
];

const _mobileSubcategories = [
  SellSubcategory(name: 'iPhone', slug: 'iphone'),
  SellSubcategory(name: 'Samsung', slug: 'samsung'),
  SellSubcategory(name: 'Vivo', slug: 'vivo'),
  SellSubcategory(name: 'Oppo', slug: 'oppo'),
  SellSubcategory(name: 'OnePlus', slug: 'oneplus'),
  SellSubcategory(name: 'Google Pixel', slug: 'google-pixel'),
  SellSubcategory(name: 'Realme', slug: 'realme'),
  SellSubcategory(name: 'Xiaomi', slug: 'xiaomi'),
  SellSubcategory(name: 'Huawei', slug: 'huawei'),
  SellSubcategory(name: 'Sony', slug: 'sony'),
  SellSubcategory(name: 'Nokia', slug: 'nokia'),
  SellSubcategory(name: 'Motorola', slug: 'motorola'),
  SellSubcategory(name: 'LG', slug: 'lg'),
  SellSubcategory(name: 'HTC', slug: 'htc'),
  SellSubcategory(name: 'Other', slug: 'other'),
];

const _jobsSubcategories = [
  SellSubcategory(name: 'Sales & Marketing', slug: 'sales-and-marketing'),
  SellSubcategory(name: 'Teacher', slug: 'teacher'),
  SellSubcategory(name: 'Accountant', slug: 'accountant'),
  SellSubcategory(name: 'Designer', slug: 'designer'),
  SellSubcategory(name: 'Office Assistant', slug: 'office-assistant'),
  SellSubcategory(name: 'Driver', slug: 'driver'),
  SellSubcategory(
      name: 'IT Engineer & Developer', slug: 'it-engineer-developer'),
];

const _jobsMainSlugs = {
  'sales-and-marketing',
  'sales-marketing',
  'teacher',
  'accountant',
  'designer',
  'office-assistant',
  'driver',
  'it-engineer-developer',
  'it-engineer',
};

const _classifiedSubcategories = [
  SellSubcategory(name: 'Men', slug: 'men'),
  SellSubcategory(name: 'Women', slug: 'women'),
  SellSubcategory(name: 'Kids Fashion', slug: 'kids-fashion'),
  SellSubcategory(name: 'Bags', slug: 'bags'),
  SellSubcategory(name: 'Footwear', slug: 'footwear'),
  SellSubcategory(name: 'Jewellery', slug: 'jewellery'),
  SellSubcategory(name: 'Watches & Accessories', slug: 'watches-accessories'),
  SellSubcategory(name: 'Book & Sports', slug: 'books-sports'),
];

const _classifiedMainSlugs = {
  'men',
  'women',
  'kids-fashion',
  'bags',
  'footwear',
  'jewellery',
  'jewelry',
  'watches-accessories',
  'books-sports',
};

SellSubcategory _normalizeClassifiedMain(SellSubcategory item) {
  if (item.slug == 'jewelry') {
    return const SellSubcategory(name: 'Jewellery', slug: 'jewellery');
  }
  return item;
}

SellSubcategory _normalizeJobMain(SellSubcategory item) {
  if (item.slug == 'sales-marketing') {
    return const SellSubcategory(
        name: 'Sales & Marketing', slug: 'sales-and-marketing');
  }
  if (item.slug == 'it-engineer') {
    return const SellSubcategory(
        name: 'IT Engineer & Developer', slug: 'it-engineer-developer');
  }
  return item;
}

String _normalizeCategorySlug(String slug) {
  final v = slug.trim().toLowerCase();
  if (v == 'spare_parts') return 'spare-parts';
  return v;
}

final sellSubcategoriesProvider = FutureProvider.autoDispose
    .family<List<SellSubcategory>, String>((ref, categorySlug) async {
  final client = Supabase.instance.client;
  final normalized = _normalizeCategorySlug(categorySlug);
  var query = client
      .from('subcategories')
      .select('name,slug,sort_order')
      .eq('category_slug', normalized)
      .eq('is_active', true);

  final response = await query
      .order('sort_order', ascending: true)
      .order('name', ascending: true);

  final rows = (response as List<dynamic>)
      .map((e) => SellSubcategory.fromMap(e as Map<String, dynamic>))
      .where((e) => e.slug.isNotEmpty)
      .toList();

  if (normalized == 'mobiles') {
    final brandResponse = await client
        .from('car_makes')
        .select('name,slug,sort_order')
        .eq('subcategory_slug', 'mobile-brands')
        .eq('is_active', true)
        .order('sort_order', ascending: true)
        .order('name', ascending: true);

    final brandRows = (brandResponse as List<dynamic>)
        .map((e) => SellSubcategory.fromMap(e as Map<String, dynamic>))
        .where((e) => e.slug.isNotEmpty)
        .toList();

    final bySlug = {
      for (final item in _mobileSubcategories) item.slug: item,
      for (final item in rows)
        if (item.slug != 'mobile-phones') item.slug: item,
      for (final item in brandRows) item.slug: item,
    };
    return bySlug.values.toList();
  }

  if (normalized == 'electronics') {
    final bySlug = {
      for (final item in _electronicsSubcategories) item.slug: item,
      for (final item in rows)
        if (item.slug != 'sale' && item.slug != 'exchange') item.slug: item,
    };
    return bySlug.values.toList();
  }

  if (normalized == 'furniture') {
    final bySlug = {
      for (final item in _furnitureSubcategories) item.slug: item,
      for (final item in rows)
        if (item.slug != 'sale' && item.slug != 'exchange') item.slug: item,
    };
    return bySlug.values.toList();
  }

  if (normalized == 'spare-parts') {
    final bySlug = {
      for (final item in _sparePartsSubcategories) item.slug: item,
      for (final item in rows) item.slug: item,
    };
    return bySlug.values.toList();
  }

  if (normalized == 'jobs') {
    final bySlug = {
      for (final item in _jobsSubcategories) item.slug: item,
      for (final item in rows)
        if (_jobsMainSlugs.contains(item.slug))
          _normalizeJobMain(item).slug: _normalizeJobMain(item),
    };
    return bySlug.values.toList();
  }

  if (normalized == 'classifieds') {
    final bySlug = {
      for (final item in _classifiedSubcategories) item.slug: item,
      for (final item in rows)
        if (_classifiedMainSlugs.contains(item.slug))
          _normalizeClassifiedMain(item).slug: _normalizeClassifiedMain(item),
    };
    return bySlug.values.toList();
  }

  return rows;
});
