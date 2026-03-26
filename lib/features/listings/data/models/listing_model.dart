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
    return ListingModel(
      id: map['id'] as String,
      category: map['category'] as String,
      subcategory: map['subcategory'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      price: map['price'] != null ? (map['price'] as num).toDouble() : null,
      currency: map['currency'] as String? ?? 'AFN',
      images: (map['images'] as List<dynamic>?)?.cast<String>() ?? [],
      sellerId: map['seller_id'] as String,
      sellerName: map['seller_name'] as String? ?? '',
      country: map['country'] as String? ?? 'Afghanistan',
      region: map['region'] as String?,
      city: map['city'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      isFeatured: map['is_featured'] as bool? ?? false,
      viewCount: map['view_count'] as int? ?? 0,
      categoryData: (map['category_data'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(map['created_at'] as String),
    );
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
