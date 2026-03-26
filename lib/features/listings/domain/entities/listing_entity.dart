import 'package:equatable/equatable.dart';

class ListingEntity extends Equatable {
  final String id;
  final String category;
  final String? subcategory;
  final String title;
  final String? description;
  final double? price;
  final String currency;
  final List<String> images;
  final String sellerId;
  final String sellerName;
  final String country;
  final String? region;
  final String? city;
  final bool isActive;
  final bool isFeatured;
  final int viewCount;
  final Map<String, dynamic> categoryData;
  final DateTime createdAt;

  const ListingEntity({
    required this.id,
    required this.category,
    this.subcategory,
    required this.title,
    this.description,
    this.price,
    required this.currency,
    required this.images,
    required this.sellerId,
    required this.sellerName,
    required this.country,
    this.region,
    this.city,
    required this.isActive,
    required this.isFeatured,
    required this.viewCount,
    required this.categoryData,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, category, title, price, sellerId, createdAt];
}
