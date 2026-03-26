import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';

class CarListingsScreen extends StatefulWidget {
  final String subcategory;
  const CarListingsScreen({super.key, required this.subcategory});

  @override
  State<CarListingsScreen> createState() => _CarListingsScreenState();
}

class _CarListingsScreenState extends State<CarListingsScreen> {
  bool _isGrid = false;
  String _sortBy = 'Latest';

  static const _sortOptions = [
    'Latest',
    'Price: Low to High',
    'Price: High to Low',
    'Most Popular'
  ];

  // Dummy listings
  static const _listings = [
    _CarListing(
      title: 'Toyota Corolla 2020',
      price: 'AFN 1,200,000',
      year: '2020',
      mileage: '45,000 km',
      transmission: 'Automatic',
      location: 'Kabul',
      timeAgo: '2 hours ago',
      isFeatured: true,
    ),
    _CarListing(
      title: 'Honda Civic 2019',
      price: 'AFN 980,000',
      year: '2019',
      mileage: '62,000 km',
      transmission: 'Manual',
      location: 'Kabul',
      timeAgo: '5 hours ago',
      isFeatured: false,
    ),
    _CarListing(
      title: 'Toyota Land Cruiser 2018',
      price: 'AFN 3,500,000',
      year: '2018',
      mileage: '80,000 km',
      transmission: 'Automatic',
      location: 'Mazar-i-Sharif',
      timeAgo: 'Yesterday',
      isFeatured: true,
    ),
    _CarListing(
      title: 'Hyundai Tucson 2021',
      price: 'AFN 2,100,000',
      year: '2021',
      mileage: '22,000 km',
      transmission: 'Automatic',
      location: 'Herat',
      timeAgo: '2 days ago',
      isFeatured: false,
    ),
    _CarListing(
      title: 'Suzuki Cultus 2022',
      price: 'AFN 750,000',
      year: '2022',
      mileage: '15,000 km',
      transmission: 'Manual',
      location: 'Kandahar',
      timeAgo: '3 days ago',
      isFeatured: false,
    ),
    _CarListing(
      title: 'Kia Sportage 2020',
      price: 'AFN 1,800,000',
      year: '2020',
      mileage: '38,000 km',
      transmission: 'Automatic',
      location: 'Kabul',
      timeAgo: '4 days ago',
      isFeatured: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
          widget.subcategory,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 28 / 15,
            letterSpacing: 0,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87, size: 22),
            onPressed: () {},
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
        ),
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Filter button
                _filterChip(Icons.tune, 'Filter', () {}),
                const SizedBox(width: 8),
                // Sort
                GestureDetector(
                  onTap: _showSortSheet,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFDDDDDD)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_sortBy,
                            style: GoogleFonts.montserrat(
                                fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, size: 16),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Count
                Text('${_listings.length} results',
                    style: GoogleFonts.montserrat(
                        fontSize: 12, color: Colors.black45)),
                const SizedBox(width: 8),
                // Grid/List toggle
                GestureDetector(
                  onTap: () => setState(() => _isGrid = !_isGrid),
                  child: Icon(
                    _isGrid ? Icons.view_list : Icons.grid_view,
                    size: 20,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // Listings
          Expanded(
            child: _isGrid ? _buildGrid() : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text(label,
                  style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
        ),
      );

  Widget _buildList() => ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _listings.length,
        itemBuilder: (_, i) => _ListingCard(listing: _listings[i]),
      );

  Widget _buildGrid() => GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.72,
        ),
        itemCount: _listings.length,
        itemBuilder: (_, i) => _GridCard(listing: _listings[i]),
      );

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sort By',
                    style: GoogleFonts.montserrat(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          ..._sortOptions.map((opt) => Column(
                children: [
                  ListTile(
                    title: Text(opt,
                        style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: opt == _sortBy
                                ? FontWeight.w600
                                : FontWeight.w400)),
                    trailing: opt == _sortBy
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() => _sortBy = opt);
                      Navigator.pop(context);
                    },
                  ),
                  Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: const Color(0xFFEEEEEE)),
                ],
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── List Card ──────────────────────────────────────────────────────────────────
class _ListingCard extends StatelessWidget {
  final _CarListing listing;
  const _ListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Row(
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(12)),
                  child: Container(
                    width: 130,
                    height: 110,
                    color: const Color(0xFFF0F0F0),
                    child: const Icon(Icons.directions_car,
                        size: 48, color: Color(0xFFCCCCCC)),
                  ),
                ),
                if (listing.isFeatured)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA000),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Featured',
                          style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
              ],
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(listing.title,
                        maxLines: 2,
                        style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
                    const SizedBox(height: 6),
                    Text(listing.price,
                        style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        _tag(listing.year),
                        _tag(listing.mileage),
                        _tag(listing.transmission),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: Colors.black38),
                        const SizedBox(width: 2),
                        Text(listing.location,
                            style: GoogleFonts.montserrat(
                                fontSize: 11, color: Colors.black38)),
                        const Spacer(),
                        Text(listing.timeAgo,
                            style: GoogleFonts.montserrat(
                                fontSize: 11, color: Colors.black38)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text,
            style: GoogleFonts.montserrat(fontSize: 10, color: Colors.black54)),
      );
}

// ── Grid Card ──────────────────────────────────────────────────────────────────
class _GridCard extends StatelessWidget {
  final _CarListing listing;
  const _GridCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Container(
                    height: 110,
                    width: double.infinity,
                    color: const Color(0xFFF0F0F0),
                    child: const Icon(Icons.directions_car,
                        size: 48, color: Color(0xFFCCCCCC)),
                  ),
                ),
                if (listing.isFeatured)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFFA000),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text('Featured',
                          style: GoogleFonts.montserrat(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.favorite_border,
                        size: 16, color: Colors.black54),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.title,
                      maxLines: 2,
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(listing.price,
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: Colors.black38),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(listing.location,
                            style: GoogleFonts.montserrat(
                                fontSize: 10, color: Colors.black38)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarListing {
  final String title, price, year, mileage, transmission, location, timeAgo;
  final bool isFeatured;
  const _CarListing({
    required this.title,
    required this.price,
    required this.year,
    required this.mileage,
    required this.transmission,
    required this.location,
    required this.timeAgo,
    required this.isFeatured,
  });
}
