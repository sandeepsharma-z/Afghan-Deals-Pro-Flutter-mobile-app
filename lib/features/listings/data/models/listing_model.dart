import '../../domain/entities/listing_entity.dart';

class ListingModel extends ListingEntity {
  const ListingModel({
    required super.id,
    required super.category,
    super.subcategory,
    required super.title,
    super.description,
    super.price,
    required super.currency,
    required super.images,
    required super.sellerId,
    required super.sellerName,
    required super.country,
    super.region,
    super.city,
    required super.isActive,
    required super.isFeatured,
    required super.viewCount,
    required super.categoryData,
    required super.createdAt,
  });

  factory ListingModel.fromMap(Map<String, dynamic> map) {
    try {
      DateTime parsedDate;
      try {
        final createdAt = map['created_at'];
        if (createdAt == null) {
          parsedDate = DateTime.now();
        } else if (createdAt is DateTime) {
          parsedDate = createdAt;
        } else {
          parsedDate = DateTime.parse(createdAt.toString());
        }
      } catch (e) {
        parsedDate = DateTime.now();
      }

      // Safe type casting with fallbacks
      final id = map['id']?.toString() ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}';
      final category = map['category']?.toString() ?? 'uncategorized';
      final title = map['title']?.toString() ?? 'Untitled';
      final sellerId = map['seller_id']?.toString() ?? 'unknown';

      // Safe price conversion
      double? price;
      try {
        if (map['price'] != null) {
          price = (map['price'] as num).toDouble();
        }
      } catch (e) {
        price = null;
      }

      // Safe images conversion
      List<String> images = [];
      try {
        final rawImages = map['images'];
        if (rawImages is List<dynamic>) {
          images = rawImages
              .map((e) => e?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } catch (e) {
        images = [];
      }

      // Safe categoryData conversion
      Map<String, dynamic> categoryData = {};
      try {
        if (map['category_data'] is Map) {
          categoryData = Map<String, dynamic>.from(map['category_data'] as Map);
        }
      } catch (e) {
        categoryData = {};
      }

      return ListingModel(
        id: id,
        category: category,
        subcategory: map['subcategory']?.toString(),
        title: title,
        description: map['description']?.toString(),
        price: price,
        currency: map['currency']?.toString() ?? 'AFN',
        images: images,
        sellerId: sellerId,
        sellerName: map['seller_name']?.toString() ?? '',
        country: map['country']?.toString() ?? 'Afghanistan',
        region: map['region']?.toString(),
        city: map['city']?.toString(),
        isActive: (map['is_active'] as bool?) ?? true,
        isFeatured: (map['is_featured'] as bool?) ?? false,
        viewCount: (map['view_count'] as int?) ?? 0,
        categoryData: categoryData,
        createdAt: parsedDate,
      );
    } catch (e) {
      // If everything fails, return a minimal valid listing
      return ListingModel(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        category: 'uncategorized',
        title: 'Error Loading',
        currency: 'AFN',
        images: const [],
        sellerId: 'unknown',
        sellerName: '',
        country: 'Afghanistan',
        isActive: false,
        isFeatured: false,
        viewCount: 0,
        categoryData: const {},
        createdAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'subcategory': subcategory,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'images': images,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'country': country,
      'region': region,
      'city': city,
      'is_active': isActive,
      'is_featured': isFeatured,
      'view_count': viewCount,
      'category_data': categoryData,
    };
  }
}
