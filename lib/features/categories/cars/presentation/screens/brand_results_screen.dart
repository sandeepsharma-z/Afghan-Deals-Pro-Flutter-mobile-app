import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/brand_listings_provider.dart';
import '../../../../../features/listings/data/models/car_sale_model.dart';
import 'car_sale_detail_screen.dart';
import 'cars_filter_screen.dart';

const _kBlue = Color(0xFF2258A8);

class BrandResultsScreen extends ConsumerStatefulWidget {
  final String subcategory;
  final String brand;
  final String? model;
  final int fromYear;
  final int toYear;

  const BrandResultsScreen({
    super.key,
    required this.subcategory,
    required this.brand,
    this.model,
    required this.fromYear,
    required this.toYear,
  });

  @override
  ConsumerState<BrandResultsScreen> createState() =>
      _BrandResultsScreenState();
}

class _BrandResultsScreenState extends ConsumerState<BrandResultsScreen> {
  String _selectedSort = 'Popular';
  CarFilters? _appliedFilters;

  static const _sortOptions = [
    'Popular',
    'Verified',
    'Newest to Oldest',
    'Oldest to Newest',
    'Price Highest to Lowest',
    'Price Lowest to Highest',
  ];

  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCFCFCF),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Sort',
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(
                    top: BorderSide(color: Color(0xFFE8E9EB), width: 1)),
              ),
              child: Column(
                children: _sortOptions.map((item) {
                  final selected = item == _selectedSort;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedSort = item);
                      context.pop();
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: Color(0xFFE8E9EB), width: 1)),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(item,
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87)),
                          ),
                          if (selected)
                            const Icon(Icons.check,
                                color: _kBlue, size: 20),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  List<CarSaleModel> _applyFilters(List<CarSaleModel> list) {
    if (_appliedFilters == null) return list;
    final f = _appliedFilters!;

    return list.where((car) {
      try {
        final carYear = int.tryParse(car.year) ?? 0;
        if (carYear < f.fromYear || carYear > f.toYear) return false;

        if (f.makes.isNotEmpty && !_matchesFilter(car.make, f.makes)) return false;
        if (f.models.isNotEmpty && !_matchesFilter(car.model, f.models)) return false;
        if (f.subModels.isNotEmpty && !_matchesFilter(car.model, f.subModels)) return false;
        if (f.transmission.isNotEmpty && !_matchesFilter(car.transmission, f.transmission)) return false;
        if (f.fuelType.isNotEmpty && !_matchesFilter(car.fuelType, f.fuelType)) return false;
        if (f.extColors.isNotEmpty && !_matchesFilter(car.color, f.extColors)) return false;
        if (f.driveLines.isNotEmpty && !_matchesFilter(car.driveline, f.driveLines)) return false;
        if (f.cylinders.isNotEmpty && !_matchesFilter(car.cylinders, f.cylinders)) return false;
        if (f.intColors.isNotEmpty && !_matchesFilter(car.interiorColor, f.intColors)) return false;
        if (f.regions.isNotEmpty && !_matchesFilter(car.location, f.regions)) return false;
        if (f.cities.isNotEmpty && !_matchesFilter(car.location, f.cities)) return false;

        final price = double.tryParse(car.price) ?? 0;
        if (price < f.minPrice || price > f.maxPrice) return false;

        return true;
      } catch (e) {
        return true;
      }
    }).toList();
  }

  bool _matchesFilter(String carValue, Set<String> filterValues) {
    if (filterValues.isEmpty) return true;
    final carLower = carValue.toLowerCase().trim();
    return filterValues.any((f) => carLower.contains(f.toLowerCase().trim()));
  }

  List<CarSaleModel> _sorted(List<CarSaleModel> list) {
    final copy = List<CarSaleModel>.from(list);
    switch (_selectedSort) {
      case 'Newest to Oldest':
        copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Oldest to Newest':
        copy.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Price Highest to Lowest':
        copy.sort((a, b) =>
            (double.tryParse(b.price) ?? 0)
                .compareTo(double.tryParse(a.price) ?? 0));
        break;
      case 'Price Lowest to Highest':
        copy.sort((a, b) =>
            (double.tryParse(a.price) ?? 0)
                .compareTo(double.tryParse(b.price) ?? 0));
        break;
    }
    return copy;
  }


  @override
  Widget build(BuildContext context) {
    final filter = BrandFilter(
      subcategory: widget.subcategory,
      brand: widget.brand,
      model: widget.model,
      fromYear: widget.fromYear,
      toYear: widget.toYear,
    );
    final listingsAsync = ref.watch(brandListingsProvider(filter));

    final subtitle = [
      widget.model ?? widget.brand,
      '${widget.fromYear}–${widget.toYear}',
    ].join(' · ');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black87, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text('Results',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
            Text(subtitle,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.black45)),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () async {
              final defaultFilters = _appliedFilters ?? CarFilters(
                makes: {},
                models: {},
                subModels: {},
                specs: {},
                dealTypes: {},
                transmission: {},
                fuelType: {},
                extColors: {},
                driveLines: {},
                cylinders: {},
                intColors: {},
                regions: {},
                cities: {},
                fromYear: widget.fromYear,
                toYear: widget.toYear,
                minPrice: 0,
                maxPrice: 150000,
              );
              final result = await Navigator.of(context).push<CarFilters>(
                MaterialPageRoute(
                  builder: (_) => CarsFilterScreen(initialFilters: defaultFilters),
                ),
              );
              if (result != null) {
                setState(() => _appliedFilters = result);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SvgPicture.asset('assets/icons/filter.svg', width: 20, height: 20),
            ),
          ),
          GestureDetector(
            onTap: _openSortSheet,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SvgPicture.asset('assets/icons/bars_sort.svg', width: 20, height: 20),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child:
              Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
        ),
      ),
      body: listingsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kBlue)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.red))),
        data: (listings) {
          final filtered = _applyFilters(listings);
          final sorted = _sorted(filtered);
          if (sorted.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_car_outlined,
                      size: 64, color: Color(0xFFCCCCCC)),
                  const SizedBox(height: 12),
                  Text('No listings found',
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.black38)),
                ],
              ),
            );
          }
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${sorted.length} listing${sorted.length == 1 ? '' : 's'} found',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.black45),
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(10, 4, 10, 20),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 255,
                  ),
                  itemCount: sorted.length,
                  itemBuilder: (_, i) => _CarCard(car: sorted[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Car Card (real data) ──────────────────────────────────────────────────────
class _CarCard extends StatefulWidget {
  final CarSaleModel car;
  const _CarCard({required this.car});

  @override
  State<_CarCard> createState() => _CarCardState();
}

class _CarCardState extends State<_CarCard> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    if (widget.car.images.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        final next = (_currentPage + 1) % widget.car.images.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );
        setState(() => _currentPage = next);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;
    final createdDate = _formatCardDate(car.createdAt);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CarSaleDetailScreen(car: car),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7.38),
          border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ────────────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(7.38),
                    topRight: Radius.circular(7.38),
                  ),
                  child: SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: car.images.isEmpty
                        ? _placeholderImage()
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: car.images.length,
                            onPageChanged: (i) =>
                                setState(() => _currentPage = i),
                            itemBuilder: (_, i) => Image.network(
                              car.images[i],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _placeholderImage(),
                            ),
                          ),
                  ),
                ),
                // Share + Heart
                const Positioned(
                  top: 6,
                  right: 6,
                  child: Row(
                    children: [
                      _CircleBtn(icon: Icons.reply_outlined),
                      SizedBox(width: 4),
                      _CircleBtn(icon: Icons.favorite_border),
                    ],
                  ),
                ),
                // Photo count
                if (car.images.isNotEmpty)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0x63000000),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.image_outlined,
                              color: Colors.white, size: 9),
                          const SizedBox(width: 3),
                          Text(
                              car.images.length > 1
                                  ? '${_currentPage + 1}/${car.images.length}'
                                  : '${car.images.length}',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
                                  height: 1)),
                        ],
                      ),
                    ),
                  ),
                if (car.isFeatured)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Featured',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),

            // ── Content ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(car.formattedPrice,
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _kBlue)),
                      ),
                      Text(createdDate,
                          style: GoogleFonts.poppins(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF505050))),
                    ],
                  ),
                  Text(car.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.black)),
                  if (car.make.isNotEmpty)
                    Text(car.make,
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87)),
                  Row(
                    children: [
                      if (car.year.isNotEmpty) ...[
                        Text('Year: ',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87)),
                        Text(car.year,
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: Colors.black87)),
                        const SizedBox(width: 8),
                      ],
                      if (car.mileage.isNotEmpty) ...[
                        Text('KM: ',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87)),
                        Expanded(
                          child: Text(car.mileage,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black87)),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 10, color: Color(0xFF505050)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                            car.location.isNotEmpty
                                ? car.location
                                : 'Afghanistan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF505050))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFD9D9D9)),
                  const SizedBox(height: 7),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _ActionBtn(
                        child: const Icon(Icons.phone_outlined,
                            color: _kBlue, size: 14),
                        onTap: () =>
                            launchUrl(Uri.parse('tel:+93700000000')),
                      ),
                      const SizedBox(width: 6),
                      _ActionBtn(
                        child: const FaIcon(FontAwesomeIcons.whatsapp,
                            color: _kBlue, size: 14),
                        onTap: () => launchUrl(
                          Uri.parse('https://wa.me/93700000000'),
                          mode: LaunchMode.externalApplication,
                        ),
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

  Widget _placeholderImage() {
    return Container(
      height: 110,
      color: const Color(0xFFF0F0F0),
      child: const Center(
        child: Icon(Icons.directions_car, size: 40, color: Colors.grey),
      ),
    );
  }

  String _formatCardDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    return '$day ${months[dt.month - 1]} ${dt.year}';
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  const _CircleBtn({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 12, color: Colors.black87),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _ActionBtn({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 31,
        height: 22,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
          color: Colors.white,
        ),
        child: Center(child: child),
      ),
    );
  }
}
