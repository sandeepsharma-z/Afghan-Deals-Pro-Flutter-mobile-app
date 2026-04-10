class SubcategoryModel {
  final String id;
  final String categorySlug;
  final String name;
  final String slug;
  final String? iconUrl;
  final bool isActive;
  final bool isNew;
  final int sortOrder;

  const SubcategoryModel({
    required this.id,
    required this.categorySlug,
    required this.name,
    required this.slug,
    this.iconUrl,
    required this.isActive,
    required this.isNew,
    required this.sortOrder,
  });

  factory SubcategoryModel.fromMap(Map<String, dynamic> map) {
    return SubcategoryModel(
      id: (map['id'] ?? '').toString(),
      categorySlug: (map['category_slug'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      slug: (map['slug'] ?? '').toString(),
      iconUrl: map['icon_url']?.toString(),
      isActive: map['is_active'] as bool? ?? true,
      isNew: map['is_new'] as bool? ?? false,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 999,
    );
  }
}
