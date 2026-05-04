import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kBlue = Color(0xFF2258A8);

class AppliedPropertyFilters {
  final Set<String> subcategories;
  final Set<String> propertyTypes;
  final Set<String> bedrooms;
  final Set<String> bathrooms;
  final Set<String> furnishings;
  final Set<String> locations;
  final double minPrice;
  final double maxPrice;

  const AppliedPropertyFilters({
    this.subcategories = const {},
    this.propertyTypes = const {},
    this.bedrooms = const {},
    this.bathrooms = const {},
    this.furnishings = const {},
    this.locations = const {},
    this.minPrice = 0,
    this.maxPrice = 150000,
  });

  bool get isEmpty =>
      subcategories.isEmpty &&
      propertyTypes.isEmpty &&
      bedrooms.isEmpty &&
      bathrooms.isEmpty &&
      furnishings.isEmpty &&
      locations.isEmpty &&
      minPrice == 0 &&
      maxPrice == 150000;
}

// ── Left-panel categories ─────────────────────────────────────────────────────

enum _Cat {
  property,
  location,
  propertyType,
  residentialCate,
  priceRange,
  bedrooms,
  bathrooms,
  areaSize,
  furnishing,
  excludeLocations,
  amenities,
  listedBy,
  rentIsPaid,
}

extension _CatX on _Cat {
  String get label {
    switch (this) {
      case _Cat.property:
        return 'Property';
      case _Cat.location:
        return 'Location';
      case _Cat.propertyType:
        return 'Property Type';
      case _Cat.residentialCate:
        return 'Residential Cate...';
      case _Cat.priceRange:
        return 'Price Range';
      case _Cat.bedrooms:
        return 'Bedrooms';
      case _Cat.bathrooms:
        return 'Bathrooms';
      case _Cat.areaSize:
        return 'Area / Size';
      case _Cat.furnishing:
        return 'Furnishing Type';
      case _Cat.excludeLocations:
        return 'Exclude Locations';
      case _Cat.amenities:
        return 'Amenities';
      case _Cat.listedBy:
        return 'Listed By';
      case _Cat.rentIsPaid:
        return 'Rent Is Paid';
    }
  }

  IconData get icon {
    switch (this) {
      case _Cat.property:
        return Icons.home_work_outlined;
      case _Cat.location:
        return Icons.location_on_outlined;
      case _Cat.propertyType:
        return Icons.category_outlined;
      case _Cat.residentialCate:
        return Icons.apartment_outlined;
      case _Cat.priceRange:
        return Icons.attach_money_outlined;
      case _Cat.bedrooms:
        return Icons.bed_outlined;
      case _Cat.bathrooms:
        return Icons.bathtub_outlined;
      case _Cat.areaSize:
        return Icons.square_foot;
      case _Cat.furnishing:
        return Icons.chair_outlined;
      case _Cat.excludeLocations:
        return Icons.location_off_outlined;
      case _Cat.amenities:
        return Icons.pool_outlined;
      case _Cat.listedBy:
        return Icons.person_outline;
      case _Cat.rentIsPaid:
        return Icons.calendar_month_outlined;
    }
  }
}

// ── Static data ───────────────────────────────────────────────────────────────

const _subcategories = [
  'For Sale: Residential',
  'For Rent: Residential',
  'For Sale: Commercial',
  'For Rent: Commercial',
  'New Project',
  'Land & Plots',
  'PG & Guest House',
];

const _kPropertyTypes = [
  'Residential',
  'Commercial',
  'Rooms',
  'Monthly Rent',
  'Daily Rent',
];

const _kResidentialCats = [
  'All Residential',
  'Apartment',
  'Hotel Apartment',
  'PentHouse',
  'Residential Building',
  'Residential Floor',
  'Townhouse',
  'Villa Compound',
  'Villa',
];

const _bedroomOptions = ['Studio', '1', '2', '3', '4', '5', '6+'];
const _bathroomOptions = ['1', '2', '3', '4', '5', '6', '7+'];

const _furnishingOptions = [
  'All',
  'Furnished',
  'Unfurnished',
];

const _amenitiesList = [
  'Maids Room',
  'Study',
  'Central A/C & Heating',
  'Balcony',
  'Private Garden',
  'Private Pool',
  'Private Gym',
  'Private Jacuzzi',
  'Shared Pool',
  'Shared Spa',
  'Shared Gym',
  'Security',
  'Maid Service',
  'Covered Parking',
];

const _listedByOptions = ['Agency', 'Landlord', 'Developer'];
const _rentPaidOptions = ['Yearly', 'Bi-Yearly', 'Quarterly', 'Monthly'];

// ── Deal type tabs ────────────────────────────────────────────────────────────

enum _Deal { rent, buy, offPlan }

extension _DealX on _Deal {
  String get label {
    switch (this) {
      case _Deal.rent:
        return 'Rent';
      case _Deal.buy:
        return 'Buy';
      case _Deal.offPlan:
        return 'Off-Plan';
    }
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class PropertyFilterScreen extends StatefulWidget {
  final List<String> cities;
  final List<String> subcategories;
  final List<String> propertyTypes;
  final List<String> bedrooms;
  final List<String> bathrooms;
  final List<String> furnishings;
  final double maxPrice;
  final AppliedPropertyFilters? initialFilters;

  const PropertyFilterScreen({
    super.key,
    this.cities = const [],
    this.subcategories = const [],
    this.propertyTypes = const [],
    this.bedrooms = const [],
    this.bathrooms = const [],
    this.furnishings = const [],
    this.maxPrice = 150000,
    this.initialFilters,
  });

  @override
  State<PropertyFilterScreen> createState() => _PropertyFilterScreenState();
}

class _PropertyFilterScreenState extends State<PropertyFilterScreen> {
  _Cat _active = _Cat.property;
  _Deal _deal = _Deal.rent;

  final Set<String> _subcats = {};
  final Set<String> _propertyTypes = {};
  final Set<String> _residentialCats = {};
  final Set<String> _bedrooms = {};
  final Set<String> _bathrooms = {};
  final Set<String> _furnishings = {};
  final Set<String> _regions = {};
  final Set<String> _excludeRegions = {};
  final Set<String> _amenities = {};
  final Set<String> _listedBy = {};
  final Set<String> _rentPaid = {};

  double _minPrice = 0;
  double _maxPrice = 150000;
  double _minArea = 0;
  double _maxArea = 10000;

  String _subcatSearch = '';
  String _propTypeSearch = '';
  String _amenitySearch = '';
  String _locationSearch = '';
  String _excludeSearch = '';

  final _minPriceCtrl = TextEditingController(text: '');
  final _maxPriceCtrl = TextEditingController(text: '150000');
  final _minAreaCtrl = TextEditingController(text: '');
  final _maxAreaCtrl = TextEditingController(text: '');

  @override
  void dispose() {
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    _minAreaCtrl.dispose();
    _maxAreaCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialFilters;
    if (initial == null) return;
    _subcats.addAll(initial.subcategories);
    _propertyTypes.addAll(initial.propertyTypes);
    _bedrooms.addAll(initial.bedrooms);
    _bathrooms.addAll(initial.bathrooms);
    _furnishings.addAll(initial.furnishings);
    _regions.addAll(initial.locations);
    _minPrice = initial.minPrice;
    _maxPrice = initial.maxPrice;
    _minPriceCtrl.text = _minPrice == 0 ? '' : _minPrice.toInt().toString();
    _maxPriceCtrl.text = _maxPrice.toInt().toString();
  }

  void _clearAll() => setState(() {
        _subcats.clear();
        _propertyTypes.clear();
        _residentialCats.clear();
        _bedrooms.clear();
        _bathrooms.clear();
        _furnishings.clear();
        _regions.clear();
        _excludeRegions.clear();
        _amenities.clear();
        _listedBy.clear();
        _rentPaid.clear();
        _minPrice = 0;
        _maxPrice = widget.maxPrice;
        _minArea = 0;
        _maxArea = 10000;
        _minPriceCtrl.clear();
        _maxPriceCtrl.text = widget.maxPrice.toInt().toString();
        _minAreaCtrl.clear();
        _maxAreaCtrl.clear();
        _subcatSearch = '';
        _propTypeSearch = '';
        _amenitySearch = '';
        _locationSearch = '';
        _excludeSearch = '';
        _deal = _Deal.rent;
        _active = _Cat.property;
      });

  List<String> _dynamicOrFallback(
      List<String> dynamicValues, List<String> fallback) {
    final clean = dynamicValues
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return clean.isEmpty ? fallback : clean;
  }

  bool _hasVal(_Cat cat) {
    switch (cat) {
      case _Cat.property:
        return _subcats.isNotEmpty;
      case _Cat.location:
        return _regions.isNotEmpty;
      case _Cat.propertyType:
        return _propertyTypes.isNotEmpty;
      case _Cat.residentialCate:
        return _residentialCats.isNotEmpty;
      case _Cat.priceRange:
        return _minPrice != 0 || _maxPrice != 150000;
      case _Cat.bedrooms:
        return _bedrooms.isNotEmpty;
      case _Cat.bathrooms:
        return _bathrooms.isNotEmpty;
      case _Cat.areaSize:
        return _minArea != 0 || _maxArea != 10000;
      case _Cat.furnishing:
        return _furnishings.isNotEmpty;
      case _Cat.excludeLocations:
        return _excludeRegions.isNotEmpty;
      case _Cat.amenities:
        return _amenities.isNotEmpty;
      case _Cat.listedBy:
        return _listedBy.isNotEmpty;
      case _Cat.rentIsPaid:
        return _rentPaid.isNotEmpty;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
              size: 16, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Filter',
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: _clearAll,
            child: Text('Clear All',
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w400, color: _kBlue)),
          ),
        ],
        scrolledUnderElevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
        ),
      ),
      bottomNavigationBar: _buildApplyBar(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Deal type tabs ─────────────────────────────────────────────
            _buildDealTabs(),
            const SizedBox(height: 12),
            // ── Left + Right panels ────────────────────────────────────────
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left panel
                  Expanded(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            MediaQuery.of(context).padding.bottom -
                            240,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                              color: const Color(0xFFD0D0D0), width: 1),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: _Cat.values.map(_buildLeftItem).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Right panel
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildRight(widget.cities),
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

  // ── Deal tabs ──────────────────────────────────────────────────────────────

  Widget _buildDealTabs() {
    return Row(
      children: _Deal.values.map((d) {
        final active = _deal == d;
        final isLast = d == _Deal.offPlan;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 8),
            child: GestureDetector(
              onTap: () => setState(() => _deal = d),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: active
                        ? const Color(0xFF2258A8)
                        : const Color(0xFFF2F2F2),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(d.label,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color:
                            active ? const Color(0xFF2258A8) : Colors.black87)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Left item ──────────────────────────────────────────────────────────────

  Widget _buildLeftItem(_Cat cat) {
    final active = _active == cat;
    final hasVal = _hasVal(cat);

    return InkWell(
      onTap: () => setState(() => _active = cat),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: const BoxDecoration(
          color: Colors.transparent,
          border:
              Border(bottom: BorderSide(color: Color(0xFFE8E9EB), width: 1)),
        ),
        child: Row(
          children: [
            Icon(cat.icon,
                size: 14, color: active ? _kBlue : const Color(0xFF7C7D88)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(cat.label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.0,
                      color: active ? _kBlue : Colors.black)),
            ),
            if (hasVal) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check_circle,
                  color: Color(0xFF00BA00), size: 21),
            ],
          ],
        ),
      ),
    );
  }

  // ── Right panel dispatcher ─────────────────────────────────────────────────

  Widget _buildRight(List<String> cities) {
    switch (_active) {
      case _Cat.property:
        return _buildCheckList(
          items: _dynamicOrFallback(widget.subcategories, _subcategories)
              .where(
                  (s) => s.toLowerCase().contains(_subcatSearch.toLowerCase()))
              .toList(),
          selected: _subcats,
          showSearch: true,
          searchVal: _subcatSearch,
          onSearch: (v) => setState(() => _subcatSearch = v),
        );

      case _Cat.location:
        return _buildCheckList(
          items: cities
              .where((c) =>
                  c.toLowerCase().contains(_locationSearch.toLowerCase()))
              .toList(),
          selected: _regions,
          showSearch: true,
          searchVal: _locationSearch,
          onSearch: (v) => setState(() => _locationSearch = v),
        );

      case _Cat.propertyType:
        return _buildCheckList(
          items: _dynamicOrFallback(widget.propertyTypes, _kPropertyTypes)
              .where((t) =>
                  t.toLowerCase().contains(_propTypeSearch.toLowerCase()))
              .toList(),
          selected: _propertyTypes,
          showSearch: true,
          searchVal: _propTypeSearch,
          onSearch: (v) => setState(() => _propTypeSearch = v),
        );

      case _Cat.residentialCate:
        return _buildCheckList(
          items: _kResidentialCats,
          selected: _residentialCats,
        );

      case _Cat.priceRange:
        return _buildPriceRange();

      case _Cat.bedrooms:
        return _buildCheckList(
          items: _dynamicOrFallback(widget.bedrooms, _bedroomOptions),
          selected: _bedrooms,
        );

      case _Cat.bathrooms:
        return _buildCheckList(
          items: _dynamicOrFallback(widget.bathrooms, _bathroomOptions),
          selected: _bathrooms,
        );

      case _Cat.areaSize:
        return _buildAreaSize();

      case _Cat.furnishing:
        return _buildCheckList(
          items: _dynamicOrFallback(widget.furnishings, _furnishingOptions),
          selected: _furnishings,
        );

      case _Cat.excludeLocations:
        return _buildCheckList(
          items: cities
              .where(
                  (c) => c.toLowerCase().contains(_excludeSearch.toLowerCase()))
              .toList(),
          selected: _excludeRegions,
          showSearch: true,
          searchVal: _excludeSearch,
          onSearch: (v) => setState(() => _excludeSearch = v),
        );

      case _Cat.amenities:
        return _buildCheckList(
          items: _amenitiesList
              .where(
                  (a) => a.toLowerCase().contains(_amenitySearch.toLowerCase()))
              .toList(),
          selected: _amenities,
          showSearch: true,
          searchVal: _amenitySearch,
          onSearch: (v) => setState(() => _amenitySearch = v),
        );

      case _Cat.listedBy:
        return _buildCheckList(
          items: _listedByOptions,
          selected: _listedBy,
        );

      case _Cat.rentIsPaid:
        return _buildCheckList(
          items: _rentPaidOptions,
          selected: _rentPaid,
        );
    }
  }

  // ── Check list ─────────────────────────────────────────────────────────────

  Widget _buildCheckList({
    required List<String> items,
    required Set<String> selected,
    bool showSearch = false,
    String searchVal = '',
    ValueChanged<String>? onSearch,
  }) {
    return Column(
      children: [
        if (showSearch) _searchBar(searchVal, onSearch!),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              final checked = selected.contains(item);
              return _CheckRow(
                label: item,
                checked: checked,
                onTap: () => setState(() {
                  checked ? selected.remove(item) : selected.add(item);
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Price range ────────────────────────────────────────────────────────────

  Widget _buildPriceRange() {
    final max = widget.maxPrice <= 0 ? 150000.0 : widget.maxPrice;
    final labels = [
      '${(max / 1000).round()}K+',
      '${(max * 0.75 / 1000).round()}K',
      '${(max * 0.5 / 1000).round()}K',
      '${(max * 0.25 / 1000).round()}K',
      '0',
    ];
    const sliderPad = 24.0;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          children: [
            SizedBox(
              height: 480,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Vertical slider
                  SizedBox(
                    width: 36,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: _kBlue,
                          inactiveTrackColor: const Color(0xFFD9D9D9),
                          overlayColor: Colors.transparent,
                          thumbShape: const _PropWhiteThumbShape(),
                          trackHeight: 3,
                        ),
                        child: Slider(
                          value: _maxPrice,
                          min: 0,
                          max: max,
                          onChanged: (v) => setState(() {
                            _maxPrice = v;
                            _maxPriceCtrl.text = v.toInt().toString();
                            _maxPriceCtrl.selection = TextSelection.collapsed(
                                offset: _maxPriceCtrl.text.length);
                          }),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Labels
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: sliderPad),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: labels
                            .map((l) => Text(l,
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black)))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Max price box
            _priceBox(
              label: 'Max price AED',
              controller: _maxPriceCtrl,
              onChanged: (v) {
                final n = double.tryParse(v);
                if (n != null) setState(() => _maxPrice = n.clamp(0, 150000));
              },
            ),
            const SizedBox(height: 10),
            // Min price box with floating label
            Stack(
              clipBehavior: Clip.none,
              children: [
                _priceBox(
                  label: '',
                  controller: _minPriceCtrl,
                  onChanged: (v) {
                    final n = double.tryParse(v);
                    if (n != null) {
                      setState(() => _minPrice = n.clamp(0, 150000));
                    }
                  },
                ),
                Positioned(
                  top: -7,
                  left: 10,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text('Min price AED',
                        style: GoogleFonts.poppins(
                            fontSize: 8.85,
                            height: 12.14 / 8.85,
                            color: const Color(0xFF9A9A9A))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceBox({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFC4C4C4), width: 1.36),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        onChanged: onChanged,
        style: GoogleFonts.poppins(
            fontSize: 15.74, fontWeight: FontWeight.w400, color: Colors.black),
        decoration: InputDecoration(
          hintText: label.isEmpty ? '0' : label,
          hintStyle: GoogleFonts.poppins(fontSize: 15.74, color: Colors.black),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ── Area size ──────────────────────────────────────────────────────────────

  Widget _buildAreaSize() {
    const labels = ['33,600 sqft', '11300 sqft', '75 sqft', '38 sqft', '0'];
    const sliderPad = 24.0;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          children: [
            SizedBox(
              height: 480,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Vertical slider
                  SizedBox(
                    width: 36,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: _kBlue,
                          inactiveTrackColor: const Color(0xFFD9D9D9),
                          overlayColor: Colors.transparent,
                          thumbShape: const _PropWhiteThumbShape(),
                          trackHeight: 3,
                        ),
                        child: Slider(
                          value: _maxArea,
                          min: 0,
                          max: 33600,
                          onChanged: (v) => setState(() {
                            _maxArea = v;
                            _maxAreaCtrl.text = v.toInt().toString();
                            _maxAreaCtrl.selection = TextSelection.collapsed(
                                offset: _maxAreaCtrl.text.length);
                          }),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Labels
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: sliderPad),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: labels
                            .map((l) => Text(l,
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black)))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Max sqft box
            _priceBox(
              label: 'Max sqft',
              controller: _maxAreaCtrl,
              onChanged: (v) {
                final n = double.tryParse(v);
                if (n != null) setState(() => _maxArea = n.clamp(0, 33600));
              },
            ),
            const SizedBox(height: 10),
            // Min sqft box with floating label
            Stack(
              clipBehavior: Clip.none,
              children: [
                _priceBox(
                  label: '',
                  controller: _minAreaCtrl,
                  onChanged: (v) {
                    final n = double.tryParse(v);
                    if (n != null) setState(() => _minArea = n.clamp(0, 33600));
                  },
                ),
                Positioned(
                  top: -7,
                  left: 10,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text('Min sqft',
                        style: GoogleFonts.poppins(
                            fontSize: 8.85,
                            height: 12.14 / 8.85,
                            color: const Color(0xFF9A9A9A))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────────

  Widget _searchBar(String val, ValueChanged<String> onChanged) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFF2F2F2), width: 1),
        borderRadius: BorderRadius.circular(9),
        color: Colors.white,
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Icon(Icons.search, size: 18, color: Colors.black),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle:
                    GoogleFonts.poppins(fontSize: 11, color: Colors.black),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Apply bar ──────────────────────────────────────────────────────────────

  Widget _buildApplyBar() {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(
                AppliedPropertyFilters(
                  subcategories: Set<String>.from(_subcats),
                  propertyTypes: Set<String>.from(_propertyTypes),
                  bedrooms: Set<String>.from(_bedrooms),
                  bathrooms: Set<String>.from(_bathrooms),
                  furnishings: Set<String>.from(_furnishings),
                  locations: Set<String>.from(_regions),
                  minPrice: _minPrice,
                  maxPrice: _maxPrice,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text('Apply',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _CheckRow extends StatelessWidget {
  final String label;
  final bool checked;
  final VoidCallback onTap;

  const _CheckRow({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: const BoxDecoration(
          color: Colors.white,
          border:
              Border(bottom: BorderSide(color: Color(0xFFE8E9EB), width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: checked ? _kBlue : Colors.white,
                border: Border.all(
                    color: checked ? _kBlue : const Color(0xFFBBBBBB),
                    width: 1.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: checked
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: checked ? _kBlue : Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropWhiteThumbShape extends SliderComponentShape {
  const _PropWhiteThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(9, 9);

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {
    final canvas = context.canvas;
    canvas.drawCircle(
        center,
        9,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill);
    canvas.drawCircle(
        center,
        9,
        Paint()
          ..color = const Color(0xFFCCCCCC)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }
}
