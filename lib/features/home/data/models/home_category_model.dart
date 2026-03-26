class HomeCategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? imageUrl;
  final bool isActive;
  final int sortOrder;

  const HomeCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.imageUrl,
    required this.isActive,
    required this.sortOrder,
  });

  factory HomeCategoryModel.fromMap(Map<String, dynamic> map) {
    return HomeCategoryModel(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      slug: (map['slug'] ?? '').toString(),
      imageUrl: map['image_url']?.toString(),
      isActive: map['is_active'] as bool? ?? true,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 999,
    );
  }
}
