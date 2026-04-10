import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/models/subcategory_model.dart';
import '../providers/subcategories_provider.dart';
import 'normal_cars_screen.dart';
import 'rental_cars_screen.dart';

class CarsScreen extends ConsumerWidget {
  const CarsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subcategoriesAsync = ref.watch(subcategoriesProvider('cars'));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Cars',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 28 / 15,
            letterSpacing: 0,
            color: Colors.black87,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
        ),
      ),
      body: subcategoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildList(_fallback),
        data: (subs) => _buildList(subs.isEmpty ? _fallback : subs),
      ),
    );
  }

  Widget _buildList(List<SubcategoryModel> subs) {
    return ListView.separated(
      itemCount: subs.length,
      separatorBuilder: (_, __) => const Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFFF0F0F0),
          indent: 16,
          endIndent: 16),
      itemBuilder: (context, i) => _SubcategoryTile(subcategory: subs[i]),
    );
  }

  // Fallback static list in case Supabase is empty/offline
  static const _fallback = [
    SubcategoryModel(id: '1', categorySlug: 'cars', name: 'Used Cars',                slug: 'used-cars',        isActive: true, isNew: false, sortOrder: 1),
    SubcategoryModel(id: '2', categorySlug: 'cars', name: 'New Cars',                 slug: 'new-cars',         isActive: true, isNew: false, sortOrder: 2),
    SubcategoryModel(id: '3', categorySlug: 'cars', name: 'Export Cars',              slug: 'export-cars',      isActive: true, isNew: false, sortOrder: 3),
    SubcategoryModel(id: '4', categorySlug: 'cars', name: 'Rental Cars',              slug: 'rental-cars',      isActive: true, isNew: true,  sortOrder: 4),
    SubcategoryModel(id: '5', categorySlug: 'cars', name: 'Motorcycles',              slug: 'motorcycles',      isActive: true, isNew: false, sortOrder: 5),
    SubcategoryModel(id: '6', categorySlug: 'cars', name: 'Auto Accessories & Parts', slug: 'auto-accessories', isActive: true, isNew: false, sortOrder: 6),
    SubcategoryModel(id: '7', categorySlug: 'cars', name: 'Heavy Vehicles',           slug: 'heavy-vehicles',   isActive: true, isNew: false, sortOrder: 7),
    SubcategoryModel(id: '8', categorySlug: 'cars', name: 'Boats',                    slug: 'boats',            isActive: true, isNew: false, sortOrder: 8),
    SubcategoryModel(id: '9', categorySlug: 'cars', name: 'Number Plates',            slug: 'number-plates',    isActive: true, isNew: false, sortOrder: 9),
  ];
}

class _SubcategoryTile extends StatelessWidget {
  final SubcategoryModel subcategory;
  const _SubcategoryTile({required this.subcategory});

  void _onTap(BuildContext context) {
    if (subcategory.slug == 'rental-cars') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const RentalCarsScreen()));
    } else {
      Navigator.push(context,
          MaterialPageRoute(
              builder: (_) => NormalCarsScreen(subcategory: subcategory.slug)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _onTap(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    subcategory.name,
                    style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87),
                  ),
                  if (subcategory.isNew) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'New',
                        style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}
