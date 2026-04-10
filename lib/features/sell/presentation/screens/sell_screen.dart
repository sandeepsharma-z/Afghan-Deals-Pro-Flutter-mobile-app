import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../home/data/models/home_category_model.dart';

class SellScreen extends ConsumerWidget {
  const SellScreen({super.key});

  static const _fallbackCategories = [
    _SellCategory(
      'Cars',
      Icons.directions_car_outlined,
      'cars',
      Color(0xFFE8F0FE),
      assetPath: 'assets/images/categories/car.png',
    ),
    _SellCategory(
      'Properties',
      Icons.home_outlined,
      'properties',
      Color(0xFFE8F5E9),
      assetPath: 'assets/images/categories/home.png',
    ),
    _SellCategory(
      'Mobiles',
      Icons.smartphone_outlined,
      'mobiles',
      Color(0xFFFFF8E1),
      assetPath: 'assets/images/categories/mobile.png',
    ),
    _SellCategory(
      'Spare Parts',
      Icons.build_outlined,
      'spare-parts',
      Color(0xFFE0F7FA),
      assetPath: 'assets/images/categories/spare_parts.png',
    ),
    _SellCategory(
      'Electronics/Appliances',
      Icons.tv_outlined,
      'electronics',
      Color(0xFFFCE4EC),
      assetPath: 'assets/images/categories/appliance.png',
    ),
    _SellCategory(
      'Furniture',
      Icons.chair_outlined,
      'furniture',
      Color(0xFFF3E5F5),
      assetPath: 'assets/images/categories/furniture.png',
    ),
    _SellCategory(
      'Classifieds',
      Icons.grid_view_outlined,
      'classifieds',
      Color(0xFFEDE7F6),
    ),
    _SellCategory(
      'Jobs',
      Icons.work_outline,
      'jobs',
      Color(0xFFFFF3E0),
      assetPath: 'assets/images/categories/jobs.png',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(homeCategoriesProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Post an Ad',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 28 / 15,
            letterSpacing: 0,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Choose a category',
              style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54),
            ),
          ),
          Expanded(
            child: categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildGrid(context, _fallbackCategories),
              data: (items) {
                final categories = items.isEmpty
                    ? _fallbackCategories
                    : items.map(_fromHomeCategory).toList();
                return _buildGrid(context, categories);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<_SellCategory> categories) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: categories.length,
      itemBuilder: (_, i) => _buildCategoryTile(context, categories[i]),
    );
  }

  _SellCategory _fromHomeCategory(HomeCategoryModel item) {
    return _SellCategory(
      item.name,
      _iconForCategory(item.slug),
      item.slug,
      _bgForCategory(item.slug),
      imageUrl: item.imageUrl,
    );
  }

  IconData _iconForCategory(String slug) {
    switch (slug) {
      case 'cars':
        return Icons.directions_car_outlined;
      case 'properties':
        return Icons.home_outlined;
      case 'mobiles':
        return Icons.smartphone_outlined;
      case 'spare-parts':
      case 'spare_parts':
        return Icons.build_outlined;
      case 'electronics':
        return Icons.tv_outlined;
      case 'furniture':
        return Icons.chair_outlined;
      case 'jobs':
        return Icons.work_outline;
      default:
        return Icons.grid_view_outlined;
    }
  }

  Color _bgForCategory(String slug) {
    switch (slug) {
      case 'cars':
        return const Color(0xFFE8F0FE);
      case 'properties':
        return const Color(0xFFE8F5E9);
      case 'mobiles':
        return const Color(0xFFFFF8E1);
      case 'electronics':
        return const Color(0xFFFCE4EC);
      case 'furniture':
        return const Color(0xFFF3E5F5);
      case 'spare-parts':
      case 'spare_parts':
        return const Color(0xFFE0F7FA);
      case 'jobs':
        return const Color(0xFFFFF3E0);
      default:
        return const Color(0xFFEDE7F6);
    }
  }

  Widget _buildCategoryTile(BuildContext context, _SellCategory cat) {
    return GestureDetector(
      onTap: () {
        if (cat.key == 'mobiles') {
          context.push(RouteNames.postMobile);
        } else if (cat.key == 'cars') {
          context.push(RouteNames.postCar);
        } else if (cat.key == 'properties') {
          context.push(RouteNames.postProperty);
        } else {
          context.push(RouteNames.postAd.replaceAll(':category', cat.key));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: cat.bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cat.bgColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCategoryVisual(cat),
            const SizedBox(height: 8),
            Text(
              cat.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryVisual(_SellCategory cat) {
    if (cat.imageUrl != null && cat.imageUrl!.isNotEmpty) {
      return Image.network(
        cat.imageUrl!,
        width: 56,
        height: 56,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(cat.icon, size: 36, color: AppColors.primary),
      );
    }

    if (cat.assetPath != null) {
      return Image.asset(
        cat.assetPath!,
        width: 56,
        height: 56,
        fit: BoxFit.contain,
      );
    }

    return Icon(cat.icon, size: 36, color: AppColors.primary);
  }
}

class _SellCategory {
  final String name;
  final IconData icon;
  final String key;
  final Color bgColor;
  final String? imageUrl;
  final String? assetPath;

  const _SellCategory(
    this.name,
    this.icon,
    this.key,
    this.bgColor, {
    this.imageUrl,
    this.assetPath,
  });
}
