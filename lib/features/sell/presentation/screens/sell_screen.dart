import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';

class SellScreen extends StatelessWidget {
  const SellScreen({super.key});

  static const _categories = [
    _SellCategory(
        'Cars', Icons.directions_car_outlined, 'cars', Color(0xFFE8F0FE)),
    _SellCategory(
        'Properties', Icons.home_outlined, 'properties', Color(0xFFE8F5E9)),
    _SellCategory(
        'Mobiles', Icons.smartphone_outlined, 'mobiles', Color(0xFFFFF8E1)),
    _SellCategory(
        'Electronics', Icons.tv_outlined, 'electronics', Color(0xFFFCE4EC)),
    _SellCategory(
        'Furniture', Icons.chair_outlined, 'furniture', Color(0xFFF3E5F5)),
    _SellCategory(
        'Spare Parts', Icons.build_outlined, 'spare_parts', Color(0xFFE0F7FA)),
    _SellCategory('Jobs', Icons.work_outline, 'jobs', Color(0xFFFFF3E0)),
    _SellCategory('Classifieds', Icons.grid_view_outlined, 'classifieds',
        Color(0xFFEDE7F6)),
  ];

  @override
  Widget build(BuildContext context) {
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
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemCount: _categories.length,
              itemBuilder: (_, i) =>
                  _buildCategoryTile(context, _categories[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, _SellCategory cat) {
    return GestureDetector(
      onTap: () =>
          context.push(RouteNames.postAd.replaceAll(':category', cat.key)),
      child: Container(
        decoration: BoxDecoration(
          color: cat.bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cat.bgColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(cat.icon, size: 36, color: AppColors.primary),
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
}

class _SellCategory {
  final String name;
  final IconData icon;
  final String key;
  final Color bgColor;
  const _SellCategory(this.name, this.icon, this.key, this.bgColor);
}
