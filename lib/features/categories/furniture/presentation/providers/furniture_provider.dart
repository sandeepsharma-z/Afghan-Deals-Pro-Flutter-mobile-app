import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../features/listings/data/models/furniture_listing_model.dart';
import '../../../../admin/presentation/providers/admin_dynamic_provider.dart';

const _unset = Object();

// ── Subcategory model ──────────────────────────────────────────────────────
class FurnitureSubcategory {
  final String name;
  final String slug;
  final String? iconUrl;
  final int sortOrder;

  const FurnitureSubcategory({
    required this.name,
    required this.slug,
    this.iconUrl,
    required this.sortOrder,
  });

  factory FurnitureSubcategory.fromMap(Map<String, dynamic> map) {
    return FurnitureSubcategory(
      name: map['name']?.toString().trim() ?? '',
      slug: map['slug']?.toString().trim() ?? '',
      iconUrl: map['icon_url']?.toString(),
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

const _defaultFurnitureSubcategories = [
  FurnitureSubcategory(name: 'Sofas', slug: 'sofas', sortOrder: 1),
  FurnitureSubcategory(name: 'Dining', slug: 'dining', sortOrder: 2),
  FurnitureSubcategory(
      name: 'Kids Furniture', slug: 'kids-furniture', sortOrder: 3),
  FurnitureSubcategory(name: 'Wardrobes', slug: 'wardrobes', sortOrder: 4),
  FurnitureSubcategory(
      name: 'Home Decor & Garden', slug: 'home-decor-garden', sortOrder: 5),
  FurnitureSubcategory(name: 'Beds', slug: 'beds', sortOrder: 6),
  FurnitureSubcategory(
      name: 'Other Household Items',
      slug: 'other-household-items',
      sortOrder: 7),
];

final furnitureSubcategoriesProvider =
    FutureProvider.autoDispose<List<FurnitureSubcategory>>((ref) async {
  final response = await Supabase.instance.client
      .from('subcategories')
      .select('name, slug, icon_url, sort_order')
      .eq('category_slug', 'furniture')
      .eq('is_active', true)
      .order('sort_order', ascending: true)
      .order('name', ascending: true);

  final rows = (response as List<dynamic>)
      .map((e) =>
          FurnitureSubcategory.fromMap(Map<String, dynamic>.from(e as Map)))
      .where((s) => s.name.isNotEmpty && s.slug.isNotEmpty)
      .toList();

  final bySlug = {
    for (final item in _defaultFurnitureSubcategories) item.slug: item,
    for (final item in rows) item.slug: item,
  };

  return bySlug.values.toList()
    ..sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      if (byOrder != 0) return byOrder;
      return a.name.compareTo(b.name);
    });
});

// ── Filter model ───────────────────────────────────────────────────────────
class FurnitureFilter {
  final List<String> subcategories;
  final List<String> brands;
  final List<String> conditions;
  final List<String> ages;
  final List<String> usages;
  final List<String> roomTypes;
  final List<String> itemShapes;
  final List<String> fillMaterials;
  final List<String> colors;
  final List<String> shapes;
  final List<String> types;
  final List<String> materials;
  final List<String> sellerTypes;
  final double? minPrice;
  final double? maxPrice;
  final String region;
  final String sortBy;

  const FurnitureFilter({
    this.subcategories = const [],
    this.brands = const [],
    this.conditions = const [],
    this.ages = const [],
    this.usages = const [],
    this.roomTypes = const [],
    this.itemShapes = const [],
    this.fillMaterials = const [],
    this.colors = const [],
    this.shapes = const [],
    this.types = const [],
    this.materials = const [],
    this.sellerTypes = const [],
    this.minPrice,
    this.maxPrice,
    this.region = '',
    this.sortBy = 'newest',
  });

  FurnitureFilter copyWith({
    List<String>? subcategories,
    List<String>? brands,
    List<String>? conditions,
    List<String>? ages,
    List<String>? usages,
    List<String>? roomTypes,
    List<String>? itemShapes,
    List<String>? fillMaterials,
    List<String>? colors,
    List<String>? shapes,
    List<String>? types,
    List<String>? materials,
    List<String>? sellerTypes,
    Object? minPrice = _unset,
    Object? maxPrice = _unset,
    String? region,
    String? sortBy,
  }) =>
      FurnitureFilter(
        subcategories: subcategories ?? this.subcategories,
        brands: brands ?? this.brands,
        conditions: conditions ?? this.conditions,
        ages: ages ?? this.ages,
        usages: usages ?? this.usages,
        roomTypes: roomTypes ?? this.roomTypes,
        itemShapes: itemShapes ?? this.itemShapes,
        fillMaterials: fillMaterials ?? this.fillMaterials,
        colors: colors ?? this.colors,
        shapes: shapes ?? this.shapes,
        types: types ?? this.types,
        materials: materials ?? this.materials,
        sellerTypes: sellerTypes ?? this.sellerTypes,
        minPrice:
            identical(minPrice, _unset) ? this.minPrice : minPrice as double?,
        maxPrice:
            identical(maxPrice, _unset) ? this.maxPrice : maxPrice as double?,
        region: region ?? this.region,
        sortBy: sortBy ?? this.sortBy,
      );

  bool get isEmpty =>
      subcategories.isEmpty &&
      brands.isEmpty &&
      conditions.isEmpty &&
      ages.isEmpty &&
      usages.isEmpty &&
      roomTypes.isEmpty &&
      itemShapes.isEmpty &&
      fillMaterials.isEmpty &&
      colors.isEmpty &&
      shapes.isEmpty &&
      types.isEmpty &&
      materials.isEmpty &&
      sellerTypes.isEmpty &&
      minPrice == null &&
      maxPrice == null &&
      region.isEmpty;
}

final furnitureFilterProvider = StateProvider.autoDispose<FurnitureFilter>(
    (ref) => const FurnitureFilter());

// ── Listings providers ─────────────────────────────────────────────────────
Future<List<FurnitureListingModel>> _fetchFurniture(
    {String subcategory = ''}) async {
  var query = Supabase.instance.client
      .from('listings')
      .select()
      .eq('category', 'furniture')
      .eq('is_active', true);
  if (subcategory.isNotEmpty) {
    query = query.eq('subcategory', subcategory);
  }
  final response = await query.order('created_at', ascending: false);
  return (response as List<dynamic>)
      .map((e) => FurnitureListingModel.fromMap(e as Map<String, dynamic>))
      .toList();
}

final furnitureListingsProvider =
    FutureProvider.autoDispose<List<FurnitureListingModel>>((ref) async {
  return _fetchFurniture();
});

final furnitureBySubcategoryProvider = FutureProvider.autoDispose
    .family<List<FurnitureListingModel>, String>((ref, subcategory) async {
  return _fetchFurniture(subcategory: subcategory);
});

final furnitureFilteredProvider = FutureProvider.autoDispose
    .family<List<FurnitureListingModel>, String>((ref, subcategory) async {
  final filter = ref.watch(furnitureFilterProvider);
  final all =
      await ref.watch(furnitureBySubcategoryProvider(subcategory).future);

  var result = all.where((item) {
    if (filter.subcategories.isNotEmpty &&
        !filter.subcategories.any((s) {
          final value = s.toLowerCase();
          return value == item.subcategory.toLowerCase() ||
              value == item.subcategoryLabel.toLowerCase();
        })) {
      return false;
    }
    if (filter.brands.isNotEmpty &&
        !filter.brands
            .any((b) => b.toLowerCase() == item.brand.toLowerCase())) {
      return false;
    }
    if (filter.conditions.isNotEmpty &&
        !filter.conditions
            .any((c) => c.toLowerCase() == item.condition.toLowerCase())) {
      return false;
    }
    if (filter.ages.isNotEmpty &&
        !filter.ages.any((a) => a.toLowerCase() == item.age.toLowerCase())) {
      return false;
    }
    if (filter.usages.isNotEmpty &&
        !filter.usages
            .any((u) => u.toLowerCase() == item.usage.toLowerCase())) {
      return false;
    }
    if (filter.roomTypes.isNotEmpty &&
        !filter.roomTypes
            .any((r) => r.toLowerCase() == item.roomType.toLowerCase())) {
      return false;
    }
    if (filter.itemShapes.isNotEmpty &&
        !filter.itemShapes
            .any((s) => s.toLowerCase() == item.itemShape.toLowerCase())) {
      return false;
    }
    if (filter.fillMaterials.isNotEmpty &&
        !filter.fillMaterials
            .any((f) => f.toLowerCase() == item.fillMaterial.toLowerCase())) {
      return false;
    }
    if (filter.colors.isNotEmpty &&
        !filter.colors
            .any((c) => c.toLowerCase() == item.color.toLowerCase())) {
      return false;
    }
    if (filter.shapes.isNotEmpty &&
        !filter.shapes
            .any((s) => s.toLowerCase() == item.shape.toLowerCase())) {
      return false;
    }
    if (filter.types.isNotEmpty &&
        !filter.types.any((t) => t.toLowerCase() == item.type.toLowerCase())) {
      return false;
    }
    if (filter.materials.isNotEmpty &&
        !filter.materials
            .any((m) => m.toLowerCase() == item.material.toLowerCase())) {
      return false;
    }
    if (filter.sellerTypes.isNotEmpty &&
        !filter.sellerTypes
            .any((s) => s.toLowerCase() == item.sellerType.toLowerCase())) {
      return false;
    }
    final price = double.tryParse(item.price) ?? 0;
    if (filter.minPrice != null && price < filter.minPrice!) {
      return false;
    }
    if (filter.maxPrice != null && price > filter.maxPrice!) {
      return false;
    }
    if (filter.region.isNotEmpty &&
        !item.city.toLowerCase().contains(filter.region.toLowerCase())) {
      return false;
    }
    return true;
  }).toList();

  switch (filter.sortBy) {
    case 'price_high':
      result.sort((a, b) => (double.tryParse(b.price) ?? 0)
          .compareTo(double.tryParse(a.price) ?? 0));
    case 'price_low':
      result.sort((a, b) => (double.tryParse(a.price) ?? 0)
          .compareTo(double.tryParse(b.price) ?? 0));
    case 'oldest':
      result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    default:
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  return result;
});

// ── Dynamic filter option providers ───────────────────────────────────────
Future<List<String>> _distinctFurnitureField(String field,
    {String subcategory = ''}) async {
  var query = Supabase.instance.client
      .from('listings')
      .select('category_data')
      .eq('category', 'furniture')
      .eq('is_active', true);
  if (subcategory.isNotEmpty) {
    query = query.eq('subcategory', subcategory);
  }
  final response = await query;
  return (response as List<dynamic>)
      .map((e) {
        final cd = (e as Map<String, dynamic>)['category_data']
                as Map<String, dynamic>? ??
            {};
        return cd[field]?.toString().trim() ?? '';
      })
      .where((v) => v.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
}

final furnitureBrandsProvider = FutureProvider.autoDispose<List<String>>(
    (ref) => _distinctFurnitureField('brand'));
final furnitureBrandsBySubcategoryProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, subcategory) =>
        _distinctFurnitureField('brand', subcategory: subcategory));

final furnitureConditionsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final admin = await fetchAdminFilterOptions('furniture', 'condition');
  if (admin.isNotEmpty) return admin;
  final fromListings = await _distinctFurnitureField('condition');
  if (fromListings.isNotEmpty) return fromListings;
  return const ['Flawless', 'Excellent', 'Good', 'Average', 'Poor'];
});
final furnitureConditionsBySubcategoryProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, subcategory) async {
  final fromListings =
      await _distinctFurnitureField('condition', subcategory: subcategory);
  if (fromListings.isNotEmpty) return fromListings;
  return ref.watch(furnitureConditionsProvider.future);
});

final furnitureAgesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final admin = await fetchAdminFilterOptions('furniture', 'age');
  if (admin.isNotEmpty) return admin;
  final fromListings = await _distinctFurnitureField('age');
  if (fromListings.isNotEmpty) return fromListings;
  return const [
    'Brand New',
    '0-1 month',
    '1-6 months',
    '6-12 months',
    '1-2 years',
    '2-5 years',
    '5-10 years',
    '10+ years',
  ];
});
final furnitureAgesBySubcategoryProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, subcategory) async {
  final fromListings =
      await _distinctFurnitureField('age', subcategory: subcategory);
  if (fromListings.isNotEmpty) return fromListings;
  return ref.watch(furnitureAgesProvider.future);
});

final furnitureUsagesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final admin = await fetchAdminFilterOptions('furniture', 'usage');
  if (admin.isNotEmpty) return admin;
  final fromListings = await _distinctFurnitureField('usage');
  if (fromListings.isNotEmpty) return fromListings;
  return const [
    'Never Used',
    'Used Once',
    'Light Usage',
    'Normal Usage',
    'Heavy Usage'
  ];
});
final furnitureUsagesBySubcategoryProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, subcategory) async {
  final fromListings =
      await _distinctFurnitureField('usage', subcategory: subcategory);
  if (fromListings.isNotEmpty) return fromListings;
  return ref.watch(furnitureUsagesProvider.future);
});

final furnitureRoomTypesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final admin = await fetchAdminFilterOptions('furniture', 'room_type');
  if (admin.isNotEmpty) return admin;
  final fromListings = await _distinctFurnitureField('room_type');
  if (fromListings.isNotEmpty) return fromListings;
  return const [
    'Living Room',
    'Bedroom',
    'Dining Room',
    'Kids Room',
    'Office',
    'Outdoor',
    'Private Room',
    'Bed Space'
  ];
});
final furnitureRoomTypesBySubcategoryProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, subcategory) async {
  final fromListings =
      await _distinctFurnitureField('room_type', subcategory: subcategory);
  if (fromListings.isNotEmpty) return fromListings;
  return ref.watch(furnitureRoomTypesProvider.future);
});

final furnitureItemShapesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final admin = await fetchAdminFilterOptions('furniture', 'item_shape');
  if (admin.isNotEmpty) return admin;
  final fromListings = await _distinctFurnitureField('item_shape');
  if (fromListings.isNotEmpty) return fromListings;
  return const [
    'A-Shape',
    'Conical',
    'Cubical',
    'Diamond',
    'Hexagonal',
    'L-Shape',
    'Oblong',
    'Octagonal',
    'Other',
    'Oval',
    'Pentagonal',
    'Quarter Round',
  ];
});
final furnitureItemShapesBySubcategoryProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, subcategory) async {
  final fromListings =
      await _distinctFurnitureField('item_shape', subcategory: subcategory);
  if (fromListings.isNotEmpty) return fromListings;
  return ref.watch(furnitureItemShapesProvider.future);
});

final furnitureFillMaterialsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final admin = await fetchAdminFilterOptions('furniture', 'fill_material');
  if (admin.isNotEmpty) return admin;
  final fromListings = await _distinctFurnitureField('fill_material');
  if (fromListings.isNotEmpty) return fromListings;
  return const [
    'Cotton',
    'Feather',
    'Fibre',
    'Foam',
    'High Density Foam',
    'Memory Foam',
    'Polyester',
    'Polyurethane Foam',
    'Others',
  ];
});
final furnitureFillMaterialsBySubcategoryProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, subcategory) async {
  final fromListings =
      await _distinctFurnitureField('fill_material', subcategory: subcategory);
  if (fromListings.isNotEmpty) return fromListings;
  return ref.watch(furnitureFillMaterialsProvider.future);
});

final furnitureColorsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final admin = await fetchAdminFilterOptions('furniture', 'color');
  if (admin.isNotEmpty) return admin;
  final fromListings = await _distinctFurnitureField('color');
  if (fromListings.isNotEmpty) return fromListings;
  return const [
    'White',
    'Silver',
    'Grey',
    'Black',
    'Red',
    'Gold',
    'Orange',
    'Blue',
    'Beige',
    'Yellow',
    'Purple',
    'Cement',
    'Burgundy',
    'Green',
    'Brown',
  ];
});
final furnitureColorsBySubcategoryProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, subcategory) async {
  final fromListings =
      await _distinctFurnitureField('color', subcategory: subcategory);
  if (fromListings.isNotEmpty) return fromListings;
  return ref.watch(furnitureColorsProvider.future);
});

final furnitureShapesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final admin = await fetchAdminFilterOptions('furniture', 'shape');
  if (admin.isNotEmpty) return admin;
  final fromListings = await _distinctFurnitureField('shape');
  if (fromListings.isNotEmpty) return fromListings;
  return const [
    'Corner',
    'Free Shape',
    'L-Shape',
    'Modular',
    'Square',
    'Standard',
    'U-Shape',
    'Others'
  ];
});
final furnitureShapesBySubcategoryProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, subcategory) async {
  final fromListings =
      await _distinctFurnitureField('shape', subcategory: subcategory);
  if (fromListings.isNotEmpty) return fromListings;
  return ref.watch(furnitureShapesProvider.future);
});

final furnitureTypesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final admin = await fetchAdminFilterOptions('furniture', 'type');
  if (admin.isNotEmpty) return admin;
  final fromListings = await _distinctFurnitureField('type');
  if (fromListings.isNotEmpty) return fromListings;
  return const [
    'Convertible',
    'Futon',
    'Loveseat',
    'Sectional',
    'Sleeper',
    'Sofa Bed',
    'Sofa Chaise',
    'Standard',
    'Others',
  ];
});
final furnitureTypesBySubcategoryProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, subcategory) async {
  final fromListings =
      await _distinctFurnitureField('type', subcategory: subcategory);
  if (fromListings.isNotEmpty) return fromListings;
  return ref.watch(furnitureTypesProvider.future);
});

final furnitureMaterialsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final admin = await fetchAdminFilterOptions('furniture', 'material');
  if (admin.isNotEmpty) return admin;
  final fromListings = await _distinctFurnitureField('material');
  if (fromListings.isNotEmpty) return fromListings;
  return const [
    'Coated Fabric',
    'Fabric',
    'Leather',
    'Metal',
    'Plastic',
    'Rattan',
    'Solid Wood',
    'Others'
  ];
});
final furnitureMaterialsBySubcategoryProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, subcategory) async {
  final fromListings =
      await _distinctFurnitureField('material', subcategory: subcategory);
  if (fromListings.isNotEmpty) return fromListings;
  return ref.watch(furnitureMaterialsProvider.future);
});

final furnitureSellerTypesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final admin = await fetchAdminFilterOptions('furniture', 'seller_type');
  if (admin.isNotEmpty) return admin;
  final fromListings = await _distinctFurnitureField('seller_type');
  if (fromListings.isNotEmpty) return fromListings;
  return const ['All Sellers', 'Individuals', 'Businesses'];
});
final furnitureSellerTypesBySubcategoryProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, subcategory) async {
  final fromListings =
      await _distinctFurnitureField('seller_type', subcategory: subcategory);
  if (fromListings.isNotEmpty) return fromListings;
  return ref.watch(furnitureSellerTypesProvider.future);
});

final furnitureMaxPriceBySubcategoryProvider =
    FutureProvider.autoDispose.family<double, String>((ref, subcategory) async {
  var query = Supabase.instance.client
      .from('listings')
      .select('price')
      .eq('category', 'furniture')
      .eq('is_active', true);
  if (subcategory.isNotEmpty) query = query.eq('subcategory', subcategory);
  final response = await query;
  final prices = (response as List<dynamic>)
      .map((e) => double.tryParse(
          ((e as Map<String, dynamic>)['price'] ?? '').toString()))
      .whereType<double>()
      .where((price) => price > 0)
      .toList();
  if (prices.isEmpty) return 100000;
  final maxPrice = prices.reduce((a, b) => a > b ? a : b);
  return ((maxPrice / 10000).ceil() * 10000).toDouble();
});
