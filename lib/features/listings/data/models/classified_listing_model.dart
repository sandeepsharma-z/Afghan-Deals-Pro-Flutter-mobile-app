class ClassifiedListingModel {
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

  // category_data fields
  final String brand;
  final String condition;
  final String age;
  final String usage;
  final String sellerType;
  final String phone;

  const ClassifiedListingModel({
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
    required this.brand,
    required this.condition,
    required this.age,
    required this.usage,
    required this.sellerType,
    required this.phone,
  });

  String get imageUrl => images.isNotEmpty ? images.first : '';

  String get formattedPrice {
    final num? val = num.tryParse(price);
    if (val == null) return price.isEmpty ? 'Negotiable' : '$currency $price';
    final s = val.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '$currency ${buf.toString()}';
  }

  String get location => city.trim().isNotEmpty ? city.trim() : 'Afghanistan';

  String get timeAgo {
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  String get formattedDate {
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return createdAt;
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
  }

  factory ClassifiedListingModel.fromMap(Map<String, dynamic> map) {
    final cd = (map['category_data'] as Map<String, dynamic>?) ?? {};
    final imgs = (map['images'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    return ClassifiedListingModel(
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
      brand: cd['brand']?.toString() ?? '',
      condition: cd['condition']?.toString() ?? '',
      age: cd['age']?.toString() ?? '',
      usage: cd['usage']?.toString() ?? '',
      sellerType: cd['seller_type']?.toString() ?? '',
      phone: cd['phone']?.toString() ?? map['phone']?.toString() ?? '',
    );
  }
}
