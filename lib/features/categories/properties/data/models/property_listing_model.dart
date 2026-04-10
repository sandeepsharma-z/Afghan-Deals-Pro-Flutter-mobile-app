class PropertyListingModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String title;
  final String description;
  final String price;
  final String currency;
  final String city;
  final List<String> images;
  final bool isFeatured;
  final String createdAt;
  final String subcategory;

  final String propertyType;
  final int bedrooms;
  final int bathrooms;
  final String area;
  final String purpose;
  final String furnishing;

  const PropertyListingModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.city,
    required this.images,
    required this.isFeatured,
    required this.createdAt,
    required this.subcategory,
    required this.propertyType,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.purpose,
    required this.furnishing,
  });

  String get imageUrl => images.isNotEmpty ? images.first : '';

  String get formattedPrice {
    final num? val = num.tryParse(price);
    if (val == null) return '$currency $price';
    final s = val.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '$currency ${buf.toString()}';
  }

  String get location => city.trim().isNotEmpty ? city.trim() : 'Afghanistan';

  factory PropertyListingModel.fromMap(Map<String, dynamic> map) {
    final cd = (map['category_data'] as Map<String, dynamic>?) ?? {};
    final imgs = (map['images'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return PropertyListingModel(
      id: map['id']?.toString() ?? '',
      sellerId: map['seller_id']?.toString() ?? '',
      sellerName: map['seller_name']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      price: map['price']?.toString() ?? '0',
      currency: map['currency']?.toString() ?? 'AFN',
      city: map['city']?.toString() ?? '',
      images: imgs,
      isFeatured: map['is_featured'] as bool? ?? false,
      createdAt: map['created_at']?.toString() ?? '',
      subcategory: map['subcategory']?.toString() ?? '',
      propertyType: cd['property_type']?.toString() ?? '',
      bedrooms: int.tryParse(cd['bedrooms']?.toString() ?? '') ?? 0,
      bathrooms: int.tryParse(cd['bathrooms']?.toString() ?? '') ?? 0,
      area: cd['area']?.toString() ?? '',
      purpose: cd['purpose']?.toString() ?? '',
      furnishing: cd['furnishing']?.toString() ?? '',
    );
  }
}
