import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/favorite_button.dart';
import '../../../../../features/listings/data/models/car_sale_model.dart';
import '../providers/car_brands_provider.dart';
import '../providers/car_listings_provider.dart';
import 'brand_models_screen.dart';
import 'car_sale_detail_screen.dart';
import 'cars_filter_screen.dart';

const _kBlue = Color(0xFF2258A8);

// Derived dynamically from listings

bool _matchesSelectedCarValue(String value, Set<String> selected) {
  final normalized = value.toLowerCase().trim();
  if (normalized.isEmpty) return false;
  return selected.any((item) {
    final target = item.toLowerCase().trim();
    return normalized == target || normalized.contains(target);
  });
}

bool _matchesCarFilters(CarSaleModel car, CarFilters? filters) {
  if (filters == null) return true;

  final carYear = int.tryParse(car.year.trim());
  final carPrice = double.tryParse(car.price.trim()) ?? 0;

  if (carYear != null &&
      (carYear < filters.fromYear || carYear > filters.toYear)) {
    return false;
  }
  if (carPrice < filters.minPrice || carPrice > filters.maxPrice) {
    return false;
  }
  if (filters.makes.isNotEmpty &&
      !_matchesSelectedCarValue(car.make, filters.makes)) {
    return false;
  }
  if (filters.models.isNotEmpty &&
      !_matchesSelectedCarValue(car.model, filters.models)) {
    return false;
  }
  if (filters.subModels.isNotEmpty &&
      !_matchesSelectedCarValue(car.bodyType, filters.subModels)) {
    return false;
  }
  if (filters.specs.isNotEmpty &&
      !_matchesSelectedCarValue(car.condition, filters.specs)) {
    return false;
  }
  if (filters.dealTypes.isNotEmpty &&
      !_matchesSelectedCarValue(car.sellerType, filters.dealTypes)) {
    return false;
  }
  if (filters.transmission.isNotEmpty &&
      !_matchesSelectedCarValue(car.transmission, filters.transmission)) {
    return false;
  }
  if (filters.fuelType.isNotEmpty &&
      !_matchesSelectedCarValue(car.fuelType, filters.fuelType)) {
    return false;
  }
  if (filters.extColors.isNotEmpty &&
      !_matchesSelectedCarValue(car.color, filters.extColors)) {
    return false;
  }
  if (filters.driveLines.isNotEmpty &&
      !_matchesSelectedCarValue(car.driveline, filters.driveLines)) {
    return false;
  }
  if (filters.cylinders.isNotEmpty &&
      !_matchesSelectedCarValue(car.cylinders, filters.cylinders)) {
    return false;
  }
  if (filters.intColors.isNotEmpty &&
      !_matchesSelectedCarValue(car.interiorColor, filters.intColors)) {
    return false;
  }
  if (filters.regions.isNotEmpty &&
      !_matchesSelectedCarValue(car.region, filters.regions)) {
    return false;
  }
  if (filters.cities.isNotEmpty &&
      !_matchesSelectedCarValue(car.location, filters.cities)) {
    return false;
  }

  return true;
}

CarFilterOptions _buildDynamicCarFilterOptions(List<CarSaleModel> cars) {
  List<String> distinct(Iterable<String> values) {
    final byKey = <String, String>{};
    for (final value in values) {
      final clean = value.trim();
      if (clean.isEmpty) continue;
      byKey.putIfAbsent(clean.toLowerCase(), () => clean);
    }
    return byKey.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  final years = <int>[];
  final prices = <double>[];
  for (final car in cars) {
    final year = int.tryParse(car.year.trim());
    if (year != null) years.add(year);
    final price = double.tryParse(car.price.trim());
    if (price != null) prices.add(price);
  }

  final currentYear = DateTime.now().year;
  final minYear =
      years.isEmpty ? currentYear - 20 : years.reduce((a, b) => a < b ? a : b);
  final maxYear =
      years.isEmpty ? currentYear : years.reduce((a, b) => a > b ? a : b);
  final maxPrice =
      prices.isEmpty ? 150000.0 : prices.reduce((a, b) => a > b ? a : b);

  return CarFilterOptions(
    makes: distinct(cars.map((c) => c.make)),
    models: distinct(cars.map((c) => c.model)),
    subModels: distinct(cars.map((c) => c.bodyType)),
    specs: distinct(cars.map((c) => c.condition)),
    dealTypes: distinct(cars.map((c) => c.sellerType)),
    transmission: distinct(cars.map((c) => c.transmission)),
    fuelType: distinct(cars.map((c) => c.fuelType)),
    extColors: distinct(cars.map((c) => c.color)),
    driveLines: distinct(cars.map((c) => c.driveline)),
    cylinders: distinct(cars.map((c) => c.cylinders)),
    intColors: distinct(cars.map((c) => c.interiorColor)),
    regions: distinct(cars.map((c) => c.region)),
    cities: distinct(cars.map((c) => c.location)),
    minYear: minYear,
    maxYear: maxYear,
    minPrice: 0,
    maxPrice: ((maxPrice <= 0 ? 150000 : maxPrice) / 5000).ceil() * 5000,
  );
}

CarFilters _initialCarFiltersFromOptions(
  CarFilterOptions options, {
  CarFilters? current,
}) {
  return current ??
      CarFilters(
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
        fromYear: options.minYear,
        toYear: options.maxYear,
        minPrice: options.minPrice,
        maxPrice: options.maxPrice,
      );
}

class NormalCarsScreen extends ConsumerStatefulWidget {
  final String subcategory;
  const NormalCarsScreen({super.key, required this.subcategory});

  @override
  ConsumerState<NormalCarsScreen> createState() => _NormalCarsScreenState();
}

class _NormalCarsScreenState extends ConsumerState<NormalCarsScreen> {
  String _activeFilter = 'All';
  String _selectedCountry = 'Afghanistan';
  String _selectedSort = 'Newest to Oldest';
  String _selectedBodyType = 'All';
  String _selectedCondition = 'All';
  int? _fromYear;
  int? _toYear;
  CarFilters? _appliedFilters;
  late final TextEditingController _searchCtrl;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static const _sortOptions = [
    'Newest to Oldest',
    'Oldest to Newest',
    'Price Highest to Lowest',
    'Price Lowest to Highest',
  ];

  String _flagFor(String country) {
    switch (country) {
      case 'Afghanistan':
        return 'AF';
      case 'Oman':
        return 'OM';
      case 'UAE':
        return 'AE';
      case 'Qatar':
        return 'QA';
      case 'KSA':
        return 'SA';
      case 'Syria':
        return 'SY';
      case 'Pakistan':
        return 'PK';
      case 'Iran':
        return 'IR';
      case 'Turkey':
        return 'TR';
      case 'Germany':
        return 'DE';
      default:
        return 'GL';
    }
  }

  String? _flagImageFor(String country) {
    switch (country) {
      case 'Afghanistan':
        return 'assets/images/flags/afghanistan.png';
      case 'Oman':
        return 'assets/images/flags/oman.png';
      case 'UAE':
        return 'assets/images/flags/uae.png';
      case 'Qatar':
        return 'assets/images/flags/qatar.png';
      case 'KSA':
        return 'assets/images/flags/ksa.png';
      case 'Syria':
        return 'assets/images/flags/syria.png';
      default:
        return null;
    }
  }

  void _showCountrySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => _CountrySheet(
        countries: const [
          _Country('Afghanistan', 'AF', 'assets/images/flags/afghanistan.png',
              '+93'),
          _Country('Oman', 'OM', 'assets/images/flags/oman.png', '+968'),
          _Country('UAE', 'AE', 'assets/images/flags/uae.png', '+971'),
          _Country('Qatar', 'QA', 'assets/images/flags/qatar.png', '+974'),
          _Country('KSA', 'SA', 'assets/images/flags/ksa.png', '+966'),
          _Country('Syria', 'SY', 'assets/images/flags/syria.png', '+963'),
        ],
        selected: _selectedCountry,
        onSelect: (c) {
          setState(() => _selectedCountry = c);
          context.pop();
        },
      ),
    );
  }

  static const _headerBoxDecoration = BoxDecoration(
    color: Color(0xFFF6F6F6),
    borderRadius: BorderRadius.all(Radius.circular(6)),
    boxShadow: [
      BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 1)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final asyncCars = ref.watch(carListingsProvider(widget.subcategory));
    final asyncBrands =
        ref.watch(carBrandsBySubcategoryProvider(widget.subcategory));

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildSellFab(context),
      bottomNavigationBar: _buildBottomNav(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: asyncCars.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (cars) {
                  final dbBrands = asyncBrands.valueOrNull ?? [];
                  final brandNames = dbBrands
                      .where((b) => b.isActive)
                      .map((b) => b.name)
                      .where((m) => m.isNotEmpty)
                      .toList();
                  final filterOptions = ['All', ...brandNames.take(4)];
                  final filtered = _sortCars(_applyFilters(cars));
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Sticky: search bar + brand pills ──────────
                      const SizedBox(height: 16),
                      _buildSearchBar(cars),
                      const SizedBox(height: 12),
                      _buildFilterChips(filterOptions),
                      const SizedBox(height: 14),
                      // ── Scrollable: brands grid + cards ───────────
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () => ref.refresh(
                              carListingsProvider(widget.subcategory).future),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _BrandsGrid(
                                  brands: dbBrands,
                                  subcategory: widget.subcategory,
                                ),
                                const SizedBox(height: 20),
                                _buildTopDealsHeader(),
                                const SizedBox(height: 12),
                                if (cars.isEmpty)
                                  const SizedBox(
                                    height: 320,
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.directions_car_outlined,
                                              size: 64,
                                              color: Color(0xFFCCCCCC)),
                                          SizedBox(height: 12),
                                          Text('No listings yet',
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.black45)),
                                          SizedBox(height: 4),
                                          Text(
                                              'Add listings from admin dashboard',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black38)),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  _buildCarsGrid(filtered),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Same header as HomeScreen ──────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(Icons.arrow_back_ios_new,
                size: 20, color: Colors.black87),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showCountrySheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: _headerBoxDecoration,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _flagImageFor(_selectedCountry) != null
                      ? Image.asset(_flagImageFor(_selectedCountry)!,
                          width: 22, height: 22, fit: BoxFit.cover)
                      : Text(_flagFor(_selectedCountry),
                          style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 5),
                  Text(_selectedCountry,
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 34,
            height: 34,
            decoration: _headerBoxDecoration,
            child: const Center(
                child:
                    Icon(Icons.help_outline, size: 22, color: Colors.black54)),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.push(RouteNames.notifications),
            child: Container(
              width: 34,
              height: 34,
              decoration: _headerBoxDecoration,
              child: const Center(
                  child: Icon(Icons.notifications_outlined,
                      size: 23, color: Colors.black87)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(List<CarSaleModel> cars) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFC2C2C2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.search, size: 16, color: Colors.black87),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search cars...',
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.black45),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87),
              ),
            ),
            if (_searchCtrl.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                },
                child: const Icon(Icons.close, size: 14, color: Colors.black45),
              ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _openFilterSheet(cars),
              child: SvgPicture.asset('assets/icons/filter.svg',
                  width: 16, height: 16),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _openSortSheet,
              child: SvgPicture.asset('assets/icons/bars_sort.svg',
                  width: 16, height: 16),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildTopDealsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text('Top Deals',
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 28 / 15,
                  color: Colors.black)),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _AllCarsScreen(
                  subcategory: widget.subcategory,
                  cars: ref
                          .watch(carListingsProvider(widget.subcategory))
                          .valueOrNull ??
                      [],
                ),
              ),
            ),
            child: Text('See all',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 28 / 11,
                    color: _kBlue)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(List<String> filterOptions) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filterOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final opt = filterOptions[i];
          final active = opt == _activeFilter;
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = opt),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: active ? _kBlue : Colors.transparent,
                border: active ? null : Border.all(color: _kBlue),
                borderRadius: BorderRadius.circular(23),
              ),
              child: Text(opt,
                  style: GoogleFonts.poppins(
                      fontSize: 11.6,
                      fontWeight: FontWeight.w400,
                      height: 20.89 / 11.6,
                      color: active ? Colors.white : Colors.black87)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCarsGrid(List<CarSaleModel> cars) {
    if (cars.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.directions_car_outlined,
                  size: 64, color: Colors.black26),
              const SizedBox(height: 12),
              Text('No listings found',
                  style:
                      GoogleFonts.poppins(fontSize: 14, color: Colors.black45)),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: List.generate((cars.length / 2).ceil(), (row) {
          final l = row * 2;
          final r = l + 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _CarCard(car: cars[l])),
                const SizedBox(width: 10),
                r < cars.length
                    ? Expanded(child: _CarCard(car: cars[r]))
                    : const Expanded(child: SizedBox()),
              ],
            ),
          );
        }),
      ),
    );
  }

  List<CarSaleModel> _applyFilters(List<CarSaleModel> cars) {
    return cars.where((c) {
      final make = c.make.trim().toLowerCase();
      final model = c.model.trim().toLowerCase();
      final bodyType = c.bodyType.trim().toLowerCase();
      final condition = c.condition.trim().toLowerCase();
      final year = int.tryParse(c.year.trim());

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery;
        if (!make.contains(query) &&
            !model.contains(query) &&
            !c.year.contains(query)) {
          return false;
        }
      }

      if (_activeFilter != 'All' &&
          !make.contains(_activeFilter.trim().toLowerCase())) {
        return false;
      }
      if (_selectedBodyType != 'All' &&
          bodyType != _selectedBodyType.toLowerCase()) {
        return false;
      }
      if (_selectedCondition != 'All' &&
          condition != _selectedCondition.toLowerCase()) {
        return false;
      }
      if (_fromYear != null && year != null && year < _fromYear!) {
        return false;
      }
      if (_toYear != null && year != null && year > _toYear!) {
        return false;
      }
      if (!_matchesCarFilters(c, _appliedFilters)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<CarSaleModel> _sortCars(List<CarSaleModel> list) {
    final copy = List<CarSaleModel>.from(list);
    switch (_selectedSort) {
      case 'Oldest to Newest':
        copy.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Price Highest to Lowest':
        copy.sort((a, b) => (double.tryParse(b.price) ?? 0)
            .compareTo(double.tryParse(a.price) ?? 0));
        break;
      case 'Price Lowest to Highest':
        copy.sort((a, b) => (double.tryParse(a.price) ?? 0)
            .compareTo(double.tryParse(b.price) ?? 0));
        break;
      default:
        copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return copy;
  }

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
            ..._sortOptions.map((item) {
              final selected = item == _selectedSort;
              return InkWell(
                onTap: () {
                  setState(() => _selectedSort = item);
                  context.pop();
                },
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                        top: BorderSide(color: Color(0xFFE8E9EB), width: 1)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                        const Icon(Icons.check, color: _kBlue, size: 20),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _openFilterSheet(List<CarSaleModel> cars) {
    if (widget.subcategory.trim().toLowerCase().contains('new')) {
      _openDynamicFilterScreen(cars);
      return;
    }

    final bodyTypes = {
      for (final c in cars)
        if (c.bodyType.trim().isNotEmpty) c.bodyType.trim()
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final conditions = {
      for (final c in cars)
        if (c.condition.trim().isNotEmpty) c.condition.trim()
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final years = [
      for (final c in cars)
        if (int.tryParse(c.year.trim()) != null) int.parse(c.year.trim())
    ]..sort();
    final minYear = years.isNotEmpty ? years.first : DateTime.now().year - 20;
    final maxYear = years.isNotEmpty ? years.last : DateTime.now().year;

    int tempFrom = _fromYear ?? minYear;
    int tempTo = _toYear ?? maxYear;
    String tempBody = _selectedBodyType;
    String tempCondition = _selectedCondition;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCFCFCF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Filter',
                          style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 14),
                      Text('Body Type',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      _dropdown(
                        value: tempBody,
                        items: ['All', ...bodyTypes],
                        onChanged: (v) => setModalState(() => tempBody = v),
                      ),
                      const SizedBox(height: 12),
                      Text('Condition',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      _dropdown(
                        value: tempCondition,
                        items: ['All', ...conditions],
                        onChanged: (v) =>
                            setModalState(() => tempCondition = v),
                      ),
                      const SizedBox(height: 12),
                      Text('Year Range',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _yearField(
                              label: 'From',
                              value: tempFrom,
                              min: minYear,
                              max: maxYear,
                              onChanged: (v) =>
                                  setModalState(() => tempFrom = v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _yearField(
                              label: 'To',
                              value: tempTo,
                              min: minYear,
                              max: maxYear,
                              onChanged: (v) => setModalState(() => tempTo = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedBodyType = 'All';
                                  _selectedCondition = 'All';
                                  _fromYear = null;
                                  _toYear = null;
                                });
                                context.pop();
                              },
                              child: const Text('Reset'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (tempFrom > tempTo) {
                                  final swap = tempFrom;
                                  tempFrom = tempTo;
                                  tempTo = swap;
                                }
                                setState(() {
                                  _selectedBodyType = tempBody;
                                  _selectedCondition = tempCondition;
                                  _fromYear = tempFrom;
                                  _toYear = tempTo;
                                });
                                context.pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kBlue,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openDynamicFilterScreen(List<CarSaleModel> cars) async {
    final options = _buildDynamicCarFilterOptions(cars);
    final result = await Navigator.of(context).push<CarFilters>(
      MaterialPageRoute(
        builder: (_) => CarsFilterScreen(
          initialFilters:
              _initialCarFiltersFromOptions(options, current: _appliedFilters),
          options: options,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _appliedFilters = result;
        _activeFilter = 'All';
        _selectedBodyType = 'All';
        _selectedCondition = 'All';
        _fromYear = null;
        _toYear = null;
      });
    }
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    final selected = items.contains(value) ? value : items.first;
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFC4C4C4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _yearField({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDialog<int>(
          context: context,
          builder: (_) =>
              _YearPickerDialog(initial: value, minYear: min, maxYear: max),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFC4C4C4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(child: Text('$label $value')),
            const Icon(Icons.calendar_month_outlined, size: 18, color: _kBlue),
          ],
        ),
      ),
    );
  }

  // ── Same bottom nav as HomeScreen ─────────────────────────────────────────
  Widget _buildSellFab(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.sell),
      child: SizedBox(
        width: 58,
        height: 58,
        child: CustomPaint(
          foregroundPainter: _SellRingPainter(),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Color(0x25000000),
                    blurRadius: 8,
                    offset: Offset(0, 2)),
              ],
            ),
            child:
                const Center(child: Icon(Icons.add, color: _kBlue, size: 28)),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
              color: Color(0x28000000),
              blurRadius: 12,
              spreadRadius: 0,
              offset: Offset(0, -4)),
        ],
      ),
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 0,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              Expanded(
                  child: _navItem(context, Icons.home_rounded, 'HOME',
                      () => context.go(RouteNames.home))),
              Expanded(
                  child: _navItem(context, Icons.chat_bubble_outline, 'CHATS',
                      () => context.push(RouteNames.chats))),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('SELL',
                        style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.black38)),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              Expanded(
                  child: _navItem(
                      context, Icons.favorite_border, 'MY ADS', () {})),
              Expanded(
                  child: _navItem(context, Icons.person_outline, 'ACCOUNT',
                      () => context.push(RouteNames.profile))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: Colors.black38),
            const SizedBox(height: 7),
            Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.black38)),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

// ── Brands Grid ───────────────────────────────────────────────────────────────
class _BrandsGrid extends StatelessWidget {
  final List<CarBrand> brands;
  final String subcategory;
  const _BrandsGrid({required this.brands, required this.subcategory});

  @override
  Widget build(BuildContext context) {
    // Show up to 7 brands + More button
    final display = brands.take(7).toList();
    // Use null as sentinel for 'More' and empty slots
    final allItems = <CarBrand?>[...display, null]; // null = More
    while (allItems.length % 4 != 0) {
      allItems.add(null);
    } // padding — but we distinguish below
    // Actually build rows with proper empty handling
    final rows = <List<CarBrand?>>[];
    for (var i = 0; i < allItems.length; i += 4) {
      rows.add(allItems.sublist(i, i + 4));
    }
    return Column(
      children: rows.asMap().entries.map((e) {
        return Column(
          children: [
            Row(
              children: e.value
                  .map(
                    (b) => b == null
                        ? const Expanded(child: SizedBox())
                        : _BrandBox(brand: b, subcategory: subcategory),
                  )
                  .toList(),
            ),
            if (e.key < rows.length - 1) const SizedBox(height: 24),
          ],
        );
      }).toList(),
    );
  }
}

class _BrandBox extends StatelessWidget {
  final CarBrand brand;
  final String subcategory;
  const _BrandBox({required this.brand, required this.subcategory});

  bool get _isSvgLogo {
    final url = brand.logoUrl?.toLowerCase() ?? '';
    return url.contains('.svg');
  }

  Widget _fallbackIcon() => const Icon(
        Icons.directions_car_outlined,
        color: _kBlue,
        size: 22,
      );

  @override
  Widget build(BuildContext context) {
    final hasLogo = brand.logoUrl != null && brand.logoUrl!.isNotEmpty;
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BrandModelsScreen(
              brand: brand.name,
              subcategory: subcategory,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: _kBlue, width: 2),
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: hasLogo
                      ? (_isSvgLogo
                          ? SvgPicture.network(
                              brand.logoUrl!,
                              fit: BoxFit.contain,
                              placeholderBuilder: (_) => const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            )
                          : Image.network(
                              brand.logoUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _fallbackIcon(),
                            ))
                      : _fallbackIcon(),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(brand.name,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 11.6,
                    fontWeight: FontWeight.w400,
                    height: 20.89 / 11.6,
                    color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}

// ── Car Card ──────────────────────────────────────────────────────────────────
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
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted) return;
        final next = (_currentPage + 1) % widget.car.images.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
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
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CarSaleDetailScreen(car: widget.car),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7.38),
          boxShadow: const [
            BoxShadow(
                color: Color(0x40000000),
                blurRadius: 4.22,
                offset: Offset(0, 1.05)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(7.38),
                    topRight: Radius.circular(7.38),
                  ),
                  child: car.images.isEmpty
                      ? _placeholder()
                      : SizedBox(
                          height: 101.27,
                          width: double.infinity,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: car.images.length,
                            onPageChanged: (i) =>
                                setState(() => _currentPage = i),
                            itemBuilder: (_, i) {
                              final img = car.images[i];
                              if (img.startsWith('assets/')) {
                                return Image.asset(
                                  img,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _placeholder(),
                                );
                              }
                              return Image.network(
                                img,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _placeholder(),
                              );
                            },
                          ),
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: FavoriteButton(
                    listingId: car.id,
                    size: 28,
                    backgroundColor: const Color(0x100F172A),
                        showShadow: false,
                    unselectedIconColor: Colors.white,
                    selectedIconColor: Colors.red,
                  ),
                ),
                if (car.images.length > 1)
                  Positioned(
                    bottom: 6,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0x63000000),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_currentPage + 1}/${car.images.length}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(car.formattedPrice,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: _kBlue)),
                  const SizedBox(height: 4),
                  Text(car.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                          color: Colors.black87)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: Color(0xFF505050)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          car.location.isNotEmpty
                              ? car.location
                              : 'Afghanistan',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              height: 1.3,
                              color: const Color(0xFF505050)),
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

  Widget _placeholder() => Container(
      height: 101.27,
      width: double.infinity,
      color: const Color(0xFFF0F0F0),
      child:
          const Icon(Icons.directions_car, size: 40, color: Color(0xFFCCCCCC)));
}

class _SellRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeW = 6.5;
    final radius = size.width / 2 - strokeW / 2 - 1;
    final rect = Rect.fromCircle(center: center, radius: radius);

    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;

    const third = 2 * pi / 3;
    canvas.drawArc(rect, -pi / 2, third, false, arc(const Color(0xFF1D57A7)));
    canvas.drawArc(
        rect, -pi / 2 + third, third, false, arc(const Color(0xFF000000)));
    canvas.drawArc(
        rect, -pi / 2 + 2 * third, third, false, arc(const Color(0xFF3B77FE)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Country {
  final String name;
  final String flag;
  final String? imagePath;
  final String dialCode;
  const _Country(this.name, this.flag, [this.imagePath, this.dialCode = '']);
}

class _CountrySheet extends StatelessWidget {
  final List<_Country> countries;
  final String selected;
  final ValueChanged<String> onSelect;

  const _CountrySheet({
    required this.countries,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return Container(
      height: screenH * 0.48,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('Select Country',
                    style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87)),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.pop(),
                  child:
                      const Icon(Icons.close, size: 22, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: countries.length,
              separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE8E8E8),
                  indent: 20,
                  endIndent: 20),
              itemBuilder: (_, i) {
                final c = countries[i];
                final isSelected = c.name == selected;
                return GestureDetector(
                  onTap: () => onSelect(c.name),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color:
                                  isSelected ? _kBlue : const Color(0xFFBBBBBB),
                              width: 2,
                            ),
                            color: isSelected ? _kBlue : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        c.imagePath != null
                            ? Image.asset(c.imagePath!,
                                width: 34, height: 34, fit: BoxFit.cover)
                            : Text(c.flag,
                                style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(c.name,
                              style: GoogleFonts.montserrat(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87)),
                        ),
                        if (c.dialCode.isNotEmpty)
                          Text(c.dialCode,
                              style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black45)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _YearPickerDialog extends StatefulWidget {
  final int initial;
  final int minYear;
  final int maxYear;
  const _YearPickerDialog({
    required this.initial,
    required this.minYear,
    required this.maxYear,
  });

  @override
  State<_YearPickerDialog> createState() => _YearPickerDialogState();
}

class _YearPickerDialogState extends State<_YearPickerDialog> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial.clamp(widget.minYear, widget.maxYear);
  }

  @override
  Widget build(BuildContext context) {
    final years = List<int>.generate(
      widget.maxYear - widget.minYear + 1,
      (i) => widget.minYear + i,
    ).reversed.toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 300,
        height: 380,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Text(
                    'Select Year',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: years.length,
                itemBuilder: (_, i) {
                  final y = years[i];
                  final selected = y == _selected;
                  return ListTile(
                    title: Text(
                      '$y',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected ? _kBlue : Colors.black87,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(Icons.check, color: _kBlue)
                        : null,
                    onTap: () => setState(() => _selected = y),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, _selected),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Done'),
                    ),
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

// ── All Cars Screen ────────────────────────────────────────────────────────
class _AllCarsScreen extends ConsumerStatefulWidget {
  final String subcategory;
  final List<CarSaleModel> cars;
  const _AllCarsScreen({required this.subcategory, required this.cars});

  @override
  ConsumerState<_AllCarsScreen> createState() => _AllCarsScreenState();
}

class _AllCarsScreenState extends ConsumerState<_AllCarsScreen> {
  String _selectedSort = 'Newest to Oldest';
  late final TextEditingController _searchCtrl;
  String _searchQuery = '';

  String _selectedBodyType = 'All';
  String _selectedCondition = 'All';
  int? _fromYear;
  int? _toYear;
  CarFilters? _appliedFilters;

  static const _sortOptions = [
    'Newest to Oldest',
    'Oldest to Newest',
    'Price Highest to Lowest',
    'Price Lowest to Highest',
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CarSaleModel> _applyFilters(List<CarSaleModel> cars) {
    return cars.where((c) {
      final bodyType = c.bodyType.trim().toLowerCase();
      final condition = c.condition.trim().toLowerCase();
      final year = int.tryParse(c.year.trim());

      if (_selectedBodyType != 'All' &&
          bodyType != _selectedBodyType.toLowerCase()) {
        return false;
      }
      if (_selectedCondition != 'All' &&
          condition != _selectedCondition.toLowerCase()) {
        return false;
      }
      if (_fromYear != null && year != null && year < _fromYear!) {
        return false;
      }
      if (_toYear != null && year != null && year > _toYear!) {
        return false;
      }
      if (!_matchesCarFilters(c, _appliedFilters)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<CarSaleModel> _applySearch(List<CarSaleModel> cars) {
    if (_searchQuery.isEmpty) return cars;
    return cars.where((c) {
      final make = c.make.trim().toLowerCase();
      final model = c.model.trim().toLowerCase();
      return make.contains(_searchQuery) ||
          model.contains(_searchQuery) ||
          c.year.contains(_searchQuery);
    }).toList();
  }

  List<CarSaleModel> _sortCars(List<CarSaleModel> list) {
    final copy = List<CarSaleModel>.from(list);
    switch (_selectedSort) {
      case 'Oldest to Newest':
        copy.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Price Highest to Lowest':
        copy.sort((a, b) => (double.tryParse(b.price) ?? 0)
            .compareTo(double.tryParse(a.price) ?? 0));
        break;
      case 'Price Lowest to Highest':
        copy.sort((a, b) => (double.tryParse(a.price) ?? 0)
            .compareTo(double.tryParse(b.price) ?? 0));
        break;
      default:
        copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return copy;
  }

  void _openFilterSheet(List<CarSaleModel> cars) {
    if (widget.subcategory.trim().toLowerCase().contains('new')) {
      _openDynamicFilterScreen(cars);
      return;
    }

    final bodyTypes = {
      for (final c in cars)
        if (c.bodyType.trim().isNotEmpty) c.bodyType.trim()
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final conditions = {
      for (final c in cars)
        if (c.condition.trim().isNotEmpty) c.condition.trim()
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final years = [
      for (final c in cars)
        if (int.tryParse(c.year.trim()) != null) int.parse(c.year.trim())
    ]..sort();
    final minYear = years.isNotEmpty ? years.first : DateTime.now().year - 20;
    final maxYear = years.isNotEmpty ? years.last : DateTime.now().year;

    int tempFrom = _fromYear ?? minYear;
    int tempTo = _toYear ?? maxYear;
    String tempBody = _selectedBodyType;
    String tempCondition = _selectedCondition;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCFCFCF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Filter',
                          style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 14),
                      Text('Body Type',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      _dropdown(
                        value: tempBody,
                        items: ['All', ...bodyTypes],
                        onChanged: (v) => setModalState(() => tempBody = v),
                      ),
                      const SizedBox(height: 12),
                      Text('Condition',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      _dropdown(
                        value: tempCondition,
                        items: ['All', ...conditions],
                        onChanged: (v) =>
                            setModalState(() => tempCondition = v),
                      ),
                      const SizedBox(height: 12),
                      Text('Year Range',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _yearField(
                              label: 'From',
                              value: tempFrom,
                              min: minYear,
                              max: maxYear,
                              onChanged: (v) =>
                                  setModalState(() => tempFrom = v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _yearField(
                              label: 'To',
                              value: tempTo,
                              min: minYear,
                              max: maxYear,
                              onChanged: (v) => setModalState(() => tempTo = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setModalState(() {
                                  tempBody = 'All';
                                  tempCondition = 'All';
                                  tempFrom = minYear;
                                  tempTo = maxYear;
                                });
                              },
                              child: const Text('Reset'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (tempFrom > tempTo) {
                                  final swap = tempFrom;
                                  tempFrom = tempTo;
                                  tempTo = swap;
                                }
                                setState(() {
                                  _selectedBodyType = tempBody;
                                  _selectedCondition = tempCondition;
                                  _fromYear = tempFrom;
                                  _toYear = tempTo;
                                });
                                context.pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kBlue,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openDynamicFilterScreen(List<CarSaleModel> cars) async {
    final options = _buildDynamicCarFilterOptions(cars);
    final result = await Navigator.of(context).push<CarFilters>(
      MaterialPageRoute(
        builder: (_) => CarsFilterScreen(
          initialFilters:
              _initialCarFiltersFromOptions(options, current: _appliedFilters),
          options: options,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _appliedFilters = result;
        _selectedBodyType = 'All';
        _selectedCondition = 'All';
        _fromYear = null;
        _toYear = null;
      });
    }
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    final selected = items.contains(value) ? value : items.first;
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFC4C4C4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _yearField({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54)),
        const SizedBox(height: 4),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFC4C4C4)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              items: List.generate(max - min + 1, (i) => min + i)
                  .map((e) => DropdownMenuItem<int>(
                      value: e, child: Text(e.toString())))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _sortCars(_applySearch(_applyFilters(widget.cars)));

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
            Text('All Cars',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => _openFilterSheet(widget.cars),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SvgPicture.asset('assets/icons/filter.svg',
                  width: 20, height: 20),
            ),
          ),
          GestureDetector(
            onTap: _openSortSheet,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SvgPicture.asset('assets/icons/bars_sort.svg',
                  width: 20, height: 20),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFC2C2C2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search, size: 16, color: Colors.black87),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search cars...',
                          hintStyle: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Colors.black45),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87),
                      ),
                    ),
                    if (_searchCtrl.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.black45),
                      ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.directions_car_outlined,
                              size: 64, color: Colors.black26),
                          const SizedBox(height: 12),
                          Text('No listings found',
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: Colors.black45)),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: RefreshIndicator(
                        onRefresh: () => ref.refresh(
                            carListingsProvider(widget.subcategory).future),
                        child: ListView(
                          children: [
                            ...List.generate((filtered.length / 2).ceil(),
                                (row) {
                              final l = row * 2;
                              final r = l + 1;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _CarCard(car: filtered[l])),
                                    const SizedBox(width: 10),
                                    r < filtered.length
                                        ? Expanded(
                                            child: _CarCard(car: filtered[r]))
                                        : const Expanded(child: SizedBox()),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

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
            ..._sortOptions.map((item) {
              final selected = item == _selectedSort;
              return InkWell(
                onTap: () {
                  setState(() => _selectedSort = item);
                  context.pop();
                },
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                        top: BorderSide(color: Color(0xFFE8E9EB), width: 1)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                        const Icon(Icons.check, color: _kBlue, size: 20),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
