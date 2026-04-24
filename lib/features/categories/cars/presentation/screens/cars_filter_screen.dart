import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../features/admin/presentation/providers/admin_dynamic_provider.dart';
import '../providers/car_filter_provider.dart';

const _kBlue = Color(0xFF2258A8);

// ── Static data ───────────────────────────────────────────────────────────────

const _makeList = [
  'Mercedes', 'Toyota', 'Nissan', 'Lexus', 'Bmw', 'Ford', 'Kia',
  'Hyundai', 'Land Rover', 'Chevrolet', 'Dodge', 'Mitsubishi', 'Honda',
  'Audi', 'Porsche',
];

const _modelMap = <String, List<String>>{
  'Mercedes': [
    'E Class', 'S Class', 'C Class', 'G Class', 'GLC Class', 'GLE Class',
    'A Class', 'CLA Class', 'GLS Class', 'CLS Class', 'V Class', 'CLE', 'GT',
  ],
  'Toyota': ['Camry', 'Corolla', 'Land Cruiser', 'Hilux', 'Prado', 'RAV4', 'Yaris'],
  'Bmw': ['3 Series', '5 Series', '7 Series', 'X3', 'X5', 'X7', 'M3', 'M5'],
  'Nissan': ['Patrol', 'Altima', 'Sunny', 'X-Trail', 'Pathfinder'],
  'Lexus': ['LX', 'GX', 'RX', 'ES', 'IS'],
};

const _subModelMap = <String, Map<String, List<String>>>{
  'Mercedes': {
    'GLE Class': ['43', '350', '450', '63', '53', '63S'],
    'A Class': ['140', '160', '170', '190', '210', '150'],
  },
  'Toyota': {
    'Land Cruiser': ['200', '300', 'GX', 'GXR', 'VXR'],
    'Prado': ['TXL', 'VXL', 'GXL'],
  },
};

const _regionList = [
  'Abu Dhabi', 'Ajman', 'Dubai', 'AL Sharjah', 'Ras AL Khaimah',
  'Al SharJah', 'Umm Al Quwain',
];

const _cityMap = <String, List<String>>{
  'Abu Dhabi':     ['Abu Dhabi City', 'Al Ain', 'Ruwais', 'Liwa', 'Madinat Zayed'],
  'Ajman':         ['Ajman City', 'Al Jurf', 'Al Rawda', 'Al Nuaimiya'],
  'Dubai':         ['Deira', 'Bur Dubai', 'Jumeirah', 'Al Barsha', 'Downtown', 'Dubai Marina'],
  'AL Sharjah':    ['Sharjah City', 'Khor Fakkan', 'Kalba', 'Dhaid'],
  'Al SharJah':    ['Sharjah City', 'Khor Fakkan', 'Kalba', 'Dhaid'],
  'Ras AL Khaimah':['Ras Al Khaimah City', 'Al Nakheel', 'Al Dhait', 'Khuzam'],
  'Umm Al Quwain': ['Umm Al Quwain City', 'Al Raas', 'Al Salama'],
};

const _exteriorColorMap = <String, Color>{
  'White':    Color(0xFFFFFFFF),
  'Silver':   Color(0xFFC0C0C0),
  'Grey':     Color(0xFF808080),
  'Black':    Color(0xFF111111),
  'Red':      Color(0xFFE53935),
  'Gold':     Color(0xFFB8860B),
  'Orange':   Color(0xFFFF6D00),
  'Blue':     Color(0xFF1565C0),
  'Beige':    Color(0xFFF5F5DC),
  'Yellow':   Color(0xFFFFD600),
  'Purple':   Color(0xFF7B1FA2),
  'Cement':   Color(0xFF9E9E9E),
  'Burgundy': Color(0xFF880E4F),
  'Green':    Color(0xFF2E7D32),
  'Brown':    Color(0xFF4E342E),
};

const _interiorColorMap = <String, Color>{
  'Beige':    Color(0xFFF5F5DC),
  'Black':    Color(0xFF111111),
  'Red':      Color(0xFFE53935),
  'Silver':   Color(0xFFC0C0C0),
  'Burgundy': Color(0xFF880E4F),
  'Grey':     Color(0xFF808080),
  'White':    Color(0xFFFFFFFF),
  'Brown':    Color(0xFF4E342E),
  'Yellow':   Color(0xFFFFD600),
  'Orange':   Color(0xFFFF6D00),
  'Blue':     Color(0xFF1565C0),
};

// ── Filter categories ─────────────────────────────────────────────────────────

enum _Cat {
  make, model, year, specs, subModel, dealType,
  transmission, driveline, fuelType, cylinders,
  priceRange, exteriorColor, interiorColor, region, city,
}

extension _CatX on _Cat {
  String get label {
    switch (this) {
      case _Cat.make:          return 'Make';
      case _Cat.model:         return 'Model';
      case _Cat.year:          return 'Year';
      case _Cat.specs:         return 'Specs';
      case _Cat.subModel:      return 'Sub-Model';
      case _Cat.dealType:      return 'Deal Ty...';
      case _Cat.transmission:  return 'Transmission';
      case _Cat.driveline:     return 'Driveline';
      case _Cat.fuelType:      return 'Fuel Type';
      case _Cat.cylinders:     return 'Cylinders';
      case _Cat.priceRange:    return 'Price Range';
      case _Cat.exteriorColor: return 'Exterior Color';
      case _Cat.interiorColor: return 'Interior Color';
      case _Cat.region:        return 'Region';
      case _Cat.city:          return 'City';
    }
  }

  IconData get icon {
    // Only used for Make (no SVG available)
    return Icons.directions_car_outlined;
  }

  String? get svgAsset {
    switch (this) {
      case _Cat.make:          return null; // dynamic brand icon
      case _Cat.model:         return 'assets/images/car_filter_icons/model.svg';
      case _Cat.year:          return 'assets/images/car_filter_icons/year.svg';
      case _Cat.specs:         return 'assets/images/car_filter_icons/specs.svg';
      case _Cat.subModel:      return 'assets/images/car_filter_icons/sub_model.svg';
      case _Cat.dealType:      return 'assets/images/car_filter_icons/deal_type.svg';
      case _Cat.transmission:  return 'assets/images/car_filter_icons/transmission.svg';
      case _Cat.driveline:     return 'assets/images/car_filter_icons/driveline.svg';
      case _Cat.fuelType:      return 'assets/images/car_filter_icons/fuel_type.svg';
      case _Cat.cylinders:     return 'assets/images/car_filter_icons/cylinders.svg';
      case _Cat.priceRange:    return 'assets/images/car_filter_icons/price_range.svg';
      case _Cat.exteriorColor: return 'assets/images/car_filter_icons/color.svg';
      case _Cat.interiorColor: return 'assets/images/car_filter_icons/color.svg';
      case _Cat.region:        return 'assets/images/car_filter_icons/region.svg';
      case _Cat.city:          return 'assets/images/car_filter_icons/city.svg';
    }
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class CarsFilterScreen extends ConsumerStatefulWidget {
  const CarsFilterScreen({super.key});

  @override
  ConsumerState<CarsFilterScreen> createState() => _CarsFilterScreenState();
}

class _CarsFilterScreenState extends ConsumerState<CarsFilterScreen> {
  _Cat _active = _Cat.make;

  final Set<String> _makes         = {};
  final Set<String> _models        = {};
  final Set<String> _specs         = {};
  final Set<String> _subModels     = {};
  final Set<String> _dealTypes     = {};
  final Set<String> _transmissions = {};
  final Set<String> _driveLines    = {};
  final Set<String> _fuelTypes     = {};
  final Set<String> _cylinders     = {};
  final Set<String> _extColors     = {};
  final Set<String> _intColors     = {};
  final Set<String> _regions       = {};
  final Set<String> _cities        = {};
  String _citySearch = '';

  int    _fromYear = 2014;
  int    _toYear   = 2027;
  double _maxPrice = 38000;
  double _minPrice = 0;

  final _maxCtrl = TextEditingController(text: '38000');
  final _minCtrl = TextEditingController(text: '');

  String _makeSearch     = '';
  String _modelSearch    = '';
  String _subModelSearch = '';
  String _regionSearch   = '';

  String _modelMake        = 'Mercedes';
  String _subModelMake     = 'Mercedes';
  bool   _modelDropOpen    = false;
  bool   _subModelDropOpen = false;

  @override
  void dispose() {
    _maxCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  void _clearAll() => setState(() {
    _makes.clear(); _models.clear(); _specs.clear();
    _subModels.clear(); _dealTypes.clear(); _transmissions.clear();
    _driveLines.clear(); _fuelTypes.clear(); _cylinders.clear();
    _extColors.clear(); _intColors.clear(); _regions.clear(); _cities.clear();
    _fromYear = 2014; _toYear = 2027;
    _maxPrice = 38000; _maxCtrl.text = '38000';
    _minPrice = 0; _minCtrl.clear();
    _makeSearch = ''; _modelSearch = ''; _subModelSearch = '';
    _regionSearch = ''; _citySearch = '';
    _active = _Cat.make;
  });

  bool _hasVal(_Cat cat) {
    switch (cat) {
      case _Cat.make:          return _makes.isNotEmpty;
      case _Cat.model:         return _models.isNotEmpty;
      case _Cat.year:          return _fromYear != 2014 || _toYear != 2027;
      case _Cat.specs:         return _specs.isNotEmpty;
      case _Cat.subModel:      return _subModels.isNotEmpty;
      case _Cat.dealType:      return _dealTypes.isNotEmpty;
      case _Cat.transmission:  return _transmissions.isNotEmpty;
      case _Cat.driveline:     return _driveLines.isNotEmpty;
      case _Cat.fuelType:      return _fuelTypes.isNotEmpty;
      case _Cat.cylinders:     return _cylinders.isNotEmpty;
      case _Cat.priceRange:    return _maxPrice != 38000 || _minPrice != 0;
      case _Cat.exteriorColor: return _extColors.isNotEmpty;
      case _Cat.interiorColor: return _intColors.isNotEmpty;
      case _Cat.region:        return _regions.isNotEmpty;
      case _Cat.city:          return _cities.isNotEmpty;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 28 / 12,
                    letterSpacing: 0,
                    color: _kBlue)),
          ),
        ],
        scrolledUnderElevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
        ),
      ),
      bottomNavigationBar: _buildApplyBar(),
      body: Builder(builder: (context) {
        final panelH = (MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom - 210)
            .clamp(200.0, double.infinity);
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // SizedBox gives the Row a tight height so Expanded(ListView)
              // inside _buildRight() receives tight constraints and renders.
              SizedBox(
                height: panelH,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Left panel ──────────────────────────────────────
                    SizedBox(
                      width: (MediaQuery.of(context).size.width - 34) / 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFD0D0D0), width: 1),
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
                    const SizedBox(width: 10),
                    // ── Right panel ─────────────────────────────────────
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildRight(),
                      ),
                    ),
                  ],
                ),
              ),
              if (_active == _Cat.city && _regions.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Select Region First!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.0,
                        letterSpacing: 0,
                        color: const Color(0xFFC92325)),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  // ── Left item ──────────────────────────────────────────────────────────────

  Widget _buildLeftItem(_Cat cat) {
    final active = _active == cat;
    final hasVal = _hasVal(cat);
    final isDeal = cat == _Cat.dealType;

    return InkWell(
      onTap: () => setState(() => _active = cat),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: const BoxDecoration(
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Color(0xFFE8E9EB), width: 1),
          ),
        ),
        child: Row(
          children: [
            cat.svgAsset != null
                ? SvgPicture.asset(
                    cat.svgAsset!,
                    width: 14,
                    height: 14,
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(
                      active ? _kBlue : const Color(0xFF7C7D88),
                      BlendMode.srcIn,
                    ),
                  )
                : Icon(cat.icon,
                    size: 14,
                    color: active ? _kBlue : const Color(0xFF7C7D88)),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(cat.label,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.0,
                            letterSpacing: 0,
                            color: active ? _kBlue : const Color(0xFF000000))),
                  ),
                  if (isDeal) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _kBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('New',
                          style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
            ),
            if (cat == _Cat.city && _regions.isEmpty) ...[
              const SizedBox(width: 4),
              const Icon(Icons.error, color: Color(0xFFC92325), size: 18),
            ] else if (!isDeal && hasVal) ...[
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

  Widget _buildRight() {
    switch (_active) {
      case _Cat.make:
        final allMakes = ref.watch(carMakesProvider).valueOrNull ?? _makeList;
        return _buildCheckList(
          items: allMakes.where((m) =>
              m.toLowerCase().contains(_makeSearch.toLowerCase())).toList(),
          selected: _makes,
          showSearch: true,
          searchVal: _makeSearch,
          onSearch: (v) => setState(() => _makeSearch = v),
        );

      case _Cat.model:
        return _buildModelPanel();

      case _Cat.year:
        return _buildYearPanel();

      case _Cat.specs:
        return _buildSpecsPanel();

      case _Cat.subModel:
        return _buildSubModelPanel();

      case _Cat.dealType:
        final dealItems = ref.watch(carDealTypesProvider).valueOrNull;
        return _buildCheckList(
          items: (dealItems?.isNotEmpty == true)
              ? dealItems!
              : ['Sale Only', 'Sale or Exchange', 'Exchange Only'],
          selected: _dealTypes,
          fontSize: 12,
        );

      case _Cat.transmission:
        final txItems = ref.watch(carTransmissionsProvider).valueOrNull;
        return _buildCheckList(
          items: (txItems?.isNotEmpty == true)
              ? txItems!
              : ['Automatic', 'Manual'],
          selected: _transmissions,
          fontSize: 12,
        );

      case _Cat.driveline:
        final dlItems = ref.watch(carDrivelinesProvider).valueOrNull;
        return _buildCheckList(
          items: (dlItems?.isNotEmpty == true)
              ? dlItems!
              : ['Front', 'Rear', '4X4'],
          selected: _driveLines,
          fontSize: 12,
        );

      case _Cat.fuelType:
        final ftItems = ref.watch(carFuelTypesProvider).valueOrNull;
        return _buildCheckList(
          items: (ftItems?.isNotEmpty == true)
              ? ftItems!
              : ['Petrol', 'Hybrid', 'Diesel', 'Electric'],
          selected: _fuelTypes,
          fontSize: 12,
        );

      case _Cat.cylinders:
        final cylItems = ref.watch(carCylindersProvider).valueOrNull;
        return _buildCheckList(
          items: (cylItems?.isNotEmpty == true)
              ? cylItems!
              : ['2', '3', '4', '6', '8', '10', '12'],
          selected: _cylinders,
          fontSize: 12,
        );

      case _Cat.priceRange:
        return _buildPriceRange();

      case _Cat.exteriorColor:
        final dbExtColors = ref.watch(carColorsProvider).valueOrNull;
        return _buildColorList(_extColors,
            _buildColorMap(dbExtColors, _exteriorColorMap));

      case _Cat.interiorColor:
        final dbIntColors = ref.watch(carColorsProvider).valueOrNull;
        return _buildColorList(_intColors,
            _buildColorMap(dbIntColors, _interiorColorMap));

      case _Cat.region:
        final regionsData = ref.watch(allRegionsProvider);
        final regionNames = regionsData.valueOrNull
            ?.map((r) => r.regionName)
            .toList() ?? _regionList;
        return _buildCheckList(
          items: regionNames.where((r) =>
              r.toLowerCase().contains(_regionSearch.toLowerCase())).toList(),
          selected: _regions,
          showSearch: true,
          searchVal: _regionSearch,
          onSearch: (v) => setState(() => _regionSearch = v),
          fontSize: 12,
        );

      case _Cat.city:
        if (_regions.isEmpty) return const SizedBox.shrink();
        final regionsForCity = ref.watch(allRegionsProvider);
        final cityMap = regionsForCity.valueOrNull != null
            ? {for (final r in regionsForCity.valueOrNull!) r.regionName: r.cities}
            : _cityMap;
        final cityItems = _regions
            .expand((r) => cityMap[r] ?? <String>[])
            .where((c) => c.toLowerCase().contains(_citySearch.toLowerCase()))
            .toList();
        return _buildCheckList(
          items: cityItems,
          selected: _cities,
          showSearch: true,
          searchVal: _citySearch,
          onSearch: (v) => setState(() => _citySearch = v),
          fontSize: 12,
        );

    }
  }

  // ── Shared check list ──────────────────────────────────────────────────────

  Widget _buildCheckList({
    required List<String> items,
    required Set<String> selected,
    bool showSearch = false,
    String searchVal = '',
    ValueChanged<String>? onSearch,
    double fontSize = 16,
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
                fontSize: fontSize,
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

  // ── Model panel ────────────────────────────────────────────────────────────

  Widget _buildModelPanel() {
    final activeMake = _makes.isNotEmpty ? _makes.first : _modelMake;
    final allMakesForModel = ref.watch(carMakesProvider).valueOrNull ?? _makeList;
    final allModels = ref.watch(carModelsForMakeProvider(activeMake)).valueOrNull
        ?? (_modelMap[activeMake] ?? []);
    final models = allModels
        .where((m) => m.toLowerCase().contains(_modelSearch.toLowerCase()))
        .toList();

    return Stack(
      children: [
        Column(
          children: [
            _searchBar(_modelSearch, (v) => setState(() => _modelSearch = v)),
            InkWell(
              onTap: () => setState(() => _modelDropOpen = !_modelDropOpen),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE8E8E8))),
                ),
                child: Row(
                  children: [
                    Text(activeMake,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87)),
                    const Spacer(),
                    Icon(_modelDropOpen
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.black54, size: 20),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: models.map((m) {
                  final checked = _models.contains(m);
                  return _CheckRow(
                    label: m,
                    checked: checked,
                    onTap: () => setState(() {
                      checked ? _models.remove(m) : _models.add(m);
                    }),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        if (_modelDropOpen)
          Positioned(
            top: 88, // below search bar + make row
            left: 0,
            right: 0,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: allMakesForModel.map((m) => InkWell(
                    onTap: () => setState(() {
                      _modelMake = m;
                      _modelDropOpen = false;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      child: Text(m,
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: m == activeMake
                                  ? _kBlue
                                  : Colors.black87)),
                    ),
                  )).toList(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Sub-model panel ────────────────────────────────────────────────────────

  Widget _buildSubModelPanel() {
    final activeMake = _makes.isNotEmpty ? _makes.first : _subModelMake;
    final allMakesForSubModel = ref.watch(carMakesProvider).valueOrNull ?? _makeList;
    final groups = _subModelMap[activeMake] ?? {};
    final allEntries = groups.entries.toList();

    return Stack(
      children: [
        Column(
          children: [
        _searchBar(_subModelSearch,
            (v) => setState(() => _subModelSearch = v)),
        InkWell(
          onTap: () => setState(() => _subModelDropOpen = !_subModelDropOpen),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE8E8E8))),
            ),
            child: Row(
              children: [
                Text(activeMake,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87)),
                const Spacer(),
                Icon(_subModelDropOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.black54, size: 20),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            children: allEntries.asMap().entries.map((mapEntry) {
              final idx = mapEntry.key;
              final entry = mapEntry.value;
              final groupModels = entry.value.where((m) =>
                  m.toLowerCase().contains(_subModelSearch.toLowerCase())).toList();
              if (groupModels.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (idx != 0)
                    const Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                    child: Text(entry.key,
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.black)),
                  ),
                  ...groupModels.map((sub) {
                    final checked = _subModels.contains(sub);
                    return InkWell(
                      onTap: () => setState(() {
                        checked ? _subModels.remove(sub) : _subModels.add(sub);
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 18, height: 18,
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
                            Text(sub,
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black)),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            }).toList(),
          ),
        ),
          ],
        ),
        if (_subModelDropOpen)
          Positioned(
            top: 88,
            left: 0,
            right: 0,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: allMakesForSubModel.map((m) => InkWell(
                    onTap: () => setState(() {
                      _subModelMake = m;
                      _subModelDropOpen = false;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      child: Text(m,
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: m == activeMake
                                  ? _kBlue
                                  : Colors.black87)),
                    ),
                  )).toList(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Year panel ─────────────────────────────────────────────────────────────

  Widget _buildYearPanel() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _yearBox('Form', _fromYear, maxYear: _toYear,
                (y) => setState(() => _fromYear = y)),
            SizedBox(
              height: 102,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(1, 30),
                      painter: _DashedLinePainter(),
                    ),
                    const SizedBox(height: 2),
                    const Icon(Icons.keyboard_arrow_down,
                        color: Color(0xFF7C7D88), size: 18),
                    Transform.translate(
                      offset: const Offset(0, -8),
                      child: const Icon(Icons.keyboard_arrow_down,
                          color: Color(0xFF7C7D88), size: 18),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -12),
                      child: CustomPaint(
                        size: const Size(1, 30),
                        painter: _DashedLinePainter(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _yearBox('To', _toYear, minYear: _fromYear,
                (y) => setState(() => _toYear = y)),
          ],
        ),
      ),
    );
  }

  Widget _yearBox(String label, int value, ValueChanged<int> onChanged,
      {int minYear = 1990, int? maxYear}) {
    final ctx = context;
    return InkWell(
      onTap: () async {
        final picked = await showDialog<int>(
          context: ctx,
          builder: (_) => _YearPickerDialog(
            initial: value,
            minYear: minYear,
            maxYear: maxYear ?? DateTime.now().year,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                  color: const Color(0xFFC4C4C4), width: 1.26),
              borderRadius: BorderRadius.circular(8),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(value.toString(),
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87)),
                ),
                SvgPicture.asset(
                  'assets/images/calendar_icon.svg',
                  width: 22,
                  height: 22,
                ),
              ],
            ),
          ),
          Positioned(
            top: -8,
            left: 10,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.black45,
                      height: 1.1)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Specs panel ────────────────────────────────────────────────────────────

  Widget _buildSpecsPanel() {
    const specsItems = [
      _SpecOption('Imported', Icons.language_outlined, Color(0xFF1565C0)),
      _SpecOption('GCC', null, _kBlue),
    ];
    return ListView(
      children: specsItems.map((s) {
        final checked = _specs.contains(s.label);
        return _CheckRow(
          label: s.label,
          checked: checked,
          fontSize: 12,
          onTap: () => setState(() {
            checked ? _specs.remove(s.label) : _specs.add(s.label);
          }),
          leadingIcon: s.icon != null
              ? Icon(s.icon, size: 18, color: s.color)
              : Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: s.color, width: 2),
                  ),
                  child: Center(
                    child: Text('G',
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: s.color)),
                  ),
                ),
        );
      }).toList(),
    );
  }

  // ── Price range panel ──────────────────────────────────────────────────────

  Widget _buildPriceRange() {
    const labels = ['150K+', '113K', '75K', '38K', '0'];
    // slider internal vertical padding ≈ 24px each side (Flutter default overlay)
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
                // Vertical slider (left)
                SizedBox(
                  width: 36,
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _kBlue,
                        inactiveTrackColor: const Color(0xFFD9D9D9),
                        overlayColor: Colors.transparent,
                        thumbShape: const _WhiteThumbShape(),
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: _maxPrice,
                        min: 0,
                        max: 150000,
                        onChanged: (v) => setState(() {
                          _maxPrice = v;
                          _maxCtrl.text = v.toInt().toString();
                          _maxCtrl.selection = TextSelection.collapsed(
                              offset: _maxCtrl.text.length);
                        }),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Labels aligned to slider track positions
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: sliderPad),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: labels.map((l) => Text(l,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.black))).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Max price box (editable)
          _priceBox(
            label: 'Max price AED',
            controller: _maxCtrl,
            onChanged: (v) {
              final n = double.tryParse(v);
              if (n != null) setState(() => _maxPrice = n.clamp(0, 150000));
            },
          ),
          const SizedBox(height: 10),
          // Min price box (editable) with floating label
          Stack(
            clipBehavior: Clip.none,
            children: [
              _priceBox(
                label: '',
                controller: _minCtrl,
                onChanged: (v) {
                  final n = double.tryParse(v);
                  if (n != null) setState(() => _minPrice = n.clamp(0, 150000));
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
                          letterSpacing: 0,
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
            fontSize: 15.74,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
            color: Colors.black),
        decoration: InputDecoration(
          hintText: label.isEmpty ? '0' : label,
          hintStyle: GoogleFonts.poppins(
              fontSize: 15.74,
              color: Colors.black),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ── Color map builder ──────────────────────────────────────────────────────

  Map<String, Color> _buildColorMap(
      List<String>? dbColors, Map<String, Color> staticMap) {
    if (dbColors == null || dbColors.isEmpty) return staticMap;
    const fallback = Color(0xFF9E9E9E);
    return {for (final c in dbColors) c: staticMap[c] ?? fallback};
  }

  // ── Color list ─────────────────────────────────────────────────────────────

  Widget _buildColorList(
      Set<String> selected, Map<String, Color> colorMap) {
    return ListView(
      children: colorMap.entries.map((entry) {
        final checked = selected.contains(entry.key);
        return _CheckRow(
          label: entry.key,
          checked: checked,
          onTap: () => setState(() {
            checked
                ? selected.remove(entry.key)
                : selected.add(entry.key);
          }),
          fontSize: 12,
          leadingIcon: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: entry.value,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 2,
                  spreadRadius: 0,
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────────

  Widget _searchBar(String val, ValueChanged<String> onChanged) {
    return Container(
      height: 46,
      margin: EdgeInsets.zero,
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
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  height: 18 / 11,
                  letterSpacing: 0,
                  color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: GoogleFonts.poppins(
                    fontSize: 11,
                    height: 18 / 11,
                    color: Colors.black),
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
              onPressed: () => Navigator.of(context).pop(),
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

// ── Shared widgets ────────────────────────────────────────────────────────────

class _CheckRow extends StatelessWidget {
  final String label;
  final bool checked;
  final VoidCallback onTap;
  final Widget? leadingIcon;
  final double fontSize;

  const _CheckRow({
    required this.label,
    required this.checked,
    required this.onTap,
    this.leadingIcon,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
              bottom: BorderSide(color: Color(0xFFE8E9EB), width: 1)),
        ),
        child: Row(
          children: [
            // Checkbox
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
            if (leadingIcon != null) ...[
              leadingIcon!,
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w400,
                      height: 1.0,
                      letterSpacing: 0,
                      color: checked ? _kBlue : Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SpecOption {
  final String label;
  final IconData? icon;
  final Color color;
  const _SpecOption(this.label, this.icon, this.color);
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBBBBBB)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashH = 5.0;
    const gap = 4.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(
          Offset(size.width / 2, y),
          Offset(size.width / 2, y + dashH),
          paint);
      y += dashH + gap;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _WhiteThumbShape extends SliderComponentShape {
  const _WhiteThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(9, 9);

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

    // Shadow
    final shadowPaint = Paint()
      ..color = const Color(0x40000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
    canvas.drawCircle(center, 4.5, shadowPaint);

    // White fill
    final fillPaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawCircle(center, 4.5, fillPaint);
  }
}

// ── Year Picker Dialog ────────────────────────────────────────────────────────

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
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final years = List.generate(
      widget.maxYear - widget.minYear + 1,
      (i) => widget.minYear + i,
    );
    final scrollCtrl = ScrollController(
      initialScrollOffset: (years.indexOf(_selected)).clamp(0, years.length - 1) * 44.0,
    );
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: EdgeInsets.zero,
      title: Text('Select Year',
          style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: double.maxFinite,
        height: 280,
        child: Scrollbar(
          controller: scrollCtrl,
          thumbVisibility: true,
          child: ListView.builder(
          controller: scrollCtrl,
          itemCount: years.length,
          itemExtent: 44,
          itemBuilder: (_, i) {
            final y = years[i];
            final active = y == _selected;
            return InkWell(
              onTap: () {
                Navigator.pop(context, y);
              },
              child: Container(
                color: active ? _kBlue.withValues(alpha: 0.08) : Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.centerLeft,
                child: Text(y.toString(),
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? _kBlue : Colors.black87)),
              ),
            );
          },
        ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: GoogleFonts.poppins(color: Colors.black54)),
        ),
      ],
    );
  }
}
