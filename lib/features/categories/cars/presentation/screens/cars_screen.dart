import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import 'car_listings_screen.dart';
import 'rental_cars_screen.dart';

class CarsScreen extends StatelessWidget {
  const CarsScreen({super.key});

  static const _subcategories = [
    _CarSubcategory(title: 'Used Cars', isNew: false),
    _CarSubcategory(title: 'New Cars', isNew: false),
    _CarSubcategory(title: 'Export Cars', isNew: false),
    _CarSubcategory(title: 'Rental Cars', isNew: true),
    _CarSubcategory(title: 'Motorcycles', isNew: false),
    _CarSubcategory(title: 'Auto Accessories & Parts', isNew: false),
    _CarSubcategory(title: 'Heavy Vehicles', isNew: false),
    _CarSubcategory(title: 'Boats', isNew: false),
    _CarSubcategory(title: 'Number Plates', isNew: false),
  ];

  @override
  Widget build(BuildContext context) {
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
      body: ListView.separated(
        itemCount: _subcategories.length,
        separatorBuilder: (_, __) => const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFF0F0F0),
            indent: 16,
            endIndent: 16),
        itemBuilder: (_, i) {
          final sub = _subcategories[i];
          return _SubcategoryTile(subcategory: sub);
        },
      ),
    );
  }
}

class _SubcategoryTile extends StatelessWidget {
  final _CarSubcategory subcategory;
  const _SubcategoryTile({required this.subcategory});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (subcategory.title == 'Rental Cars') {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RentalCarsScreen(),
              ));
        } else {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CarListingsScreen(subcategory: subcategory.title),
              ));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    subcategory.title,
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

class _CarSubcategory {
  final String title;
  final bool isNew;
  const _CarSubcategory({required this.title, required this.isNew});
}
