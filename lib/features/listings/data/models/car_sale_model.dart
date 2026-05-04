class CarSaleModel {
  final String id;
  final String sellerId;
  final String title;
  final String price;
  final String currency;
  final String location;
  final String region;
  final String createdAt;
  final bool isFeatured;
  final List<String> images;

  // category_data fields
  final String make;
  final String model;
  final String year;
  final String mileage;
  final String transmission;
  final String fuelType;
  final String bodyType;
  final String condition;
  final String color;
  final String driveline;
  final String cylinders;
  final String interiorColor;
  final String description;
  final String sellerName;
  final String sellerType;

  const CarSaleModel({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.price,
    required this.currency,
    required this.location,
    this.region = '',
    required this.createdAt,
    required this.isFeatured,
    required this.images,
    required this.make,
    required this.model,
    this.description = '',
    this.sellerName = 'Private Seller',
    this.sellerType = '',
    required this.year,
    required this.mileage,
    required this.transmission,
    required this.fuelType,
    required this.bodyType,
    required this.condition,
    required this.color,
    this.driveline = '',
    this.cylinders = '',
    this.interiorColor = '',
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

  String get timeAgo {
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  factory CarSaleModel.fromMap(Map<String, dynamic> map) {
    final cd = (map['category_data'] as Map<String, dynamic>?) ?? {};
    final imgs =
        (map['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            [];
    final rawPrice = map['price'];
    return CarSaleModel(
      id: map['id']?.toString() ?? '',
      sellerId: map['seller_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      price: rawPrice?.toString() ?? '0',
      currency: map['currency']?.toString() ?? 'AFN',
      location: map['city']?.toString() ?? '',
      region: map['region']?.toString() ?? cd['region']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? '',
      isFeatured: map['is_featured'] as bool? ?? false,
      images: imgs,
      make: cd['make']?.toString() ?? '',
      model: cd['model']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      sellerName: map['seller_name']?.toString() ?? 'Private Seller',
      sellerType: cd['seller_type']?.toString() ?? '',
      year: cd['year']?.toString() ?? '',
      mileage: cd['mileage']?.toString() ?? '',
      transmission: cd['transmission']?.toString() ?? '',
      fuelType: cd['fuel_type']?.toString() ?? '',
      bodyType: cd['body_type']?.toString() ?? '',
      condition: cd['condition']?.toString() ?? '',
      color: cd['color']?.toString() ?? '',
      driveline: cd['driveline']?.toString() ?? '',
      cylinders: cd['cylinders']?.toString() ?? '',
      interiorColor: cd['interior_color']?.toString() ?? '',
    );
  }
}
