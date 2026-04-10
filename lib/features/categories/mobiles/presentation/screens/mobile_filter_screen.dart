import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/mobile_listings_provider.dart';

const _kBlue = Color(0xFF2258A8);

// ── Static data ────────────────────────────────────────────────────────────────

const _kFallbackBrands = [
  'iPhone', 'Samsung', 'Vivo', 'Oppo', 'OnePlus',
  'Google Pixel', 'Realme', 'Xiaomi', 'Huawei', 'Sony',
  'Nokia', 'Motorola', 'LG', 'HTC',
];

const _kFallbackSellerTypes = ['Any', 'Individual', 'Dealer', 'Brand'];

const _kFallbackAges = ['0-3 months', '3-6 months', '6-12 months', '1+ year'];

const _kFallbackWarranties = ['Yes', 'No', 'Does not apply'];

const _kFallbackScreenSizes = [
  'Under 5"', '5" - 5.5"', '5.5" - 6"', '6" - 6.5"', 'Above 6.5"',
];

const _kFallbackDamageDetails = [
  'No Damage', 'Cracked Screen', 'Dented Body',
  'Scratches', 'Water Damage', 'Other',
];

const _kFallbackBatteryHealths = [
  '100%', '90%+', '80%+', '70%+', 'Below 70%', 'Unknown',
];

const _kFallbackVersions = [
  'International', 'GCC', 'US', 'Korean', 'Japanese', 'Chinese',
];

const _kFallbackStorages = [
  '16GB', '32GB', '64GB', '128GB', '256GB', '512GB', '1TB',
];

const _kColorMap = <String, Color>{
  'White':    Color(0xFFFFFFFF),
  'Black':    Color(0xFF111111),
  'Silver':   Color(0xFFC0C0C0),
  'Gold':     Color(0xFFB8860B),
  'Blue':     Color(0xFF1565C0),
  'Red':      Color(0xFFE53935),
  'Green':    Color(0xFF2E7D32),
  'Purple':   Color(0xFF7B1FA2),
  'Pink':     Color(0xFFE91E8C),
  'Yellow':   Color(0xFFFFD600),
  'Orange':   Color(0xFFFF6D00),
  'Grey':     Color(0xFF808080),
};

// ── Filter categories ──────────────────────────────────────────────────────────

enum _Cat {
  brand, model, condition, priceRange, sellerType,
  age, warranty, screenSize, damageDetails,
  batteryHealth, version, storage, color, region,
}

extension _CatLabel on _Cat {
  String get label {
    switch (this) {
      case _Cat.brand:         return 'Brand';
      case _Cat.model:         return 'Model';
      case _Cat.condition:     return 'Condition';
      case _Cat.priceRange:    return 'Price Range';
      case _Cat.sellerType:    return 'Seller Type';
      case _Cat.age:           return 'Age';
      case _Cat.warranty:      return 'Warranty';
      case _Cat.screenSize:    return 'Screen Size';
      case _Cat.damageDetails: return 'Damage Details';
      case _Cat.batteryHealth: return 'Battery Health';
      case _Cat.version:       return 'Version';
      case _Cat.storage:       return 'Storage Capacity';
      case _Cat.color:         return 'Color';
      case _Cat.region:        return 'Region';
    }
  }

  String get svgAsset {
    switch (this) {
      case _Cat.brand:         return 'assets/icons/mobile_filter/brand.svg';
      case _Cat.model:         return 'assets/icons/mobile_filter/model.svg';
      case _Cat.condition:     return 'assets/icons/mobile_filter/condition.svg';
      case _Cat.priceRange:    return 'assets/icons/mobile_filter/price rande.svg';
      case _Cat.sellerType:    return 'assets/icons/mobile_filter/seller typer.svg';
      case _Cat.age:           return 'assets/icons/mobile_filter/age.svg';
      case _Cat.warranty:      return 'assets/icons/mobile_filter/warranty.svg';
      case _Cat.screenSize:    return 'assets/icons/mobile_filter/screen size.svg';
      case _Cat.damageDetails: return 'assets/icons/mobile_filter/damage details.svg';
      case _Cat.batteryHealth: return 'assets/icons/mobile_filter/battery health.svg';
      case _Cat.version:       return 'assets/icons/mobile_filter/version.svg';
      case _Cat.storage:       return 'assets/icons/mobile_filter/storage capacity.svg';
      case _Cat.color:         return 'assets/icons/mobile_filter/color.svg';
      case _Cat.region:        return 'assets/icons/mobile_filter/region.svg';
    }
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class MobileFilterScreen extends StatefulWidget {
  final List<String> cities;
  const MobileFilterScreen({super.key, required this.cities});

  @override
  State<MobileFilterScreen> createState() => _MobileFilterScreenState();
}

class _MobileFilterScreenState extends State<MobileFilterScreen> {
  _Cat _active = _Cat.brand;

  // Selections
  final Set<String> _brands      = {};
  final Set<String> _models      = {};
  final Set<String> _conditions  = {};
  final Set<String> _sellerTypes = {};
  final Set<String> _ages        = {};
  final Set<String> _warranties  = {};
  final Set<String> _screenSizes = {};
  final Set<String> _damages     = {};
  final Set<String> _batteries   = {};
  final Set<String> _versions    = {};
  final Set<String> _storages    = {};
  final Set<String> _colors      = {};
  final Set<String> _regions     = {};

  double _maxPrice = 150000;
  double _minPrice = 0;
  final _maxCtrl = TextEditingController(text: '150000');
  final _minCtrl = TextEditingController(text: '');

  String _brandSearch  = '';
  String _modelSearch  = '';
  String _regionSearch = '';

  // Model dropdown
  String _modelBrand    = '';
  bool   _modelDropOpen = false;

  @override
  void dispose() {
    _maxCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  void _clearAll() => setState(() {
    _brands.clear(); _models.clear(); _conditions.clear();
    _sellerTypes.clear(); _warranties.clear(); _screenSizes.clear();
    _ages.clear(); _damages.clear(); _batteries.clear(); _versions.clear();
    _storages.clear(); _colors.clear(); _regions.clear();
    _maxPrice = 150000; _maxCtrl.text = '150000';
    _minPrice = 0; _minCtrl.clear();
    _brandSearch = ''; _modelSearch = ''; _regionSearch = '';
    _modelBrand = ''; _modelDropOpen = false;
    _active = _Cat.brand;
  });

  bool _hasVal(_Cat cat) {
    switch (cat) {
      case _Cat.brand:         return _brands.isNotEmpty;
      case _Cat.model:         return _models.isNotEmpty;
      case _Cat.condition:     return _conditions.isNotEmpty;
      case _Cat.priceRange:    return _maxPrice != 150000 || _minPrice != 0;
      case _Cat.sellerType:    return _sellerTypes.isNotEmpty;
      case _Cat.age:           return _ages.isNotEmpty;
      case _Cat.warranty:      return _warranties.isNotEmpty;
      case _Cat.screenSize:    return _screenSizes.isNotEmpty;
      case _Cat.damageDetails: return _damages.isNotEmpty;
      case _Cat.batteryHealth: return _batteries.isNotEmpty;
      case _Cat.version:       return _versions.isNotEmpty;
      case _Cat.storage:       return _storages.isNotEmpty;
      case _Cat.color:         return _colors.isNotEmpty;
      case _Cat.region:        return _regions.isNotEmpty;
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
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Left panel ────────────────────────────────────
                  Expanded(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            MediaQuery.of(context).padding.bottom - 210,
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
                            children: _Cat.values
                                .map(_buildLeftItem)
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // ── Right panel ───────────────────────────────────
                  Expanded(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            MediaQuery.of(context).padding.bottom - 210,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SingleChildScrollView(
                          child: _buildRight(),
                        ),
                      ),
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

  Widget _buildLeftItem(_Cat cat) {
    final isActive = cat == _active;
    final hasValue = _hasVal(cat);
    return InkWell(
      onTap: () => setState(() => _active = cat),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: const BoxDecoration(
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Color(0xFFE8E9EB), width: 1),
          ),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              cat.svgAsset,
              width: 14,
              height: 14,
              fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(
                isActive ? _kBlue : const Color(0xFF7C7D88),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                cat.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                  letterSpacing: 0,
                  color: isActive ? _kBlue : Colors.black,
                ),
              ),
            ),
            if (hasValue) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check_circle, color: Color(0xFF00BA00), size: 21),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRight() {
    switch (_active) {
      case _Cat.brand:
        return _buildBrand();
      case _Cat.model:
        return _buildModel();
      case _Cat.condition:
        return Consumer(
          builder: (context, ref, _) {
            final async = ref.watch(mobileConditionsProvider);
            return async.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2)),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(14),
                child: Text('Error loading conditions', style: GoogleFonts.poppins(fontSize: 12, color: Colors.red)),
              ),
              data: (items) => items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text('No conditions found', style: GoogleFonts.poppins(fontSize: 12, color: Colors.black45)),
                    )
                  : _buildCheckList(items, _conditions),
            );
          },
        );
      case _Cat.priceRange:
        return _buildPriceRange();
      case _Cat.sellerType:
        return Consumer(
          builder: (context, ref, _) {
            final async = ref.watch(mobileSellerTypesProvider);
            return async.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Error loading seller types',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
                ),
              ),
              data: (items) {
                final options = items.isEmpty ? _kFallbackSellerTypes : items;
                return _buildCheckList(options, _sellerTypes);
              },
            );
          },
        );
      case _Cat.age:
        return Consumer(
          builder: (context, ref, _) {
            final async = ref.watch(mobileAgesProvider);
            return async.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Error loading ages',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
                ),
              ),
              data: (items) {
                final options = items.isEmpty ? _kFallbackAges : items;
                return _buildCheckList(options, _ages);
              },
            );
          },
        );
      case _Cat.warranty:
        return Consumer(
          builder: (context, ref, _) {
            final async = ref.watch(mobileWarrantiesProvider);
            return async.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Error loading warranties',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
                ),
              ),
              data: (items) {
                final options = items.isEmpty ? _kFallbackWarranties : items;
                return _buildCheckList(options, _warranties);
              },
            );
          },
        );
      case _Cat.screenSize:
        return Consumer(
          builder: (context, ref, _) {
            final async = ref.watch(mobileScreenSizesProvider);
            return async.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Error loading screen sizes',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
                ),
              ),
              data: (items) {
                final options = items.isEmpty ? _kFallbackScreenSizes : items;
                return _buildCheckList(options, _screenSizes);
              },
            );
          },
        );
      case _Cat.damageDetails:
        return Consumer(
          builder: (context, ref, _) {
            final async = ref.watch(mobileDamageDetailsProvider);
            return async.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Error loading damage details',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
                ),
              ),
              data: (items) {
                final options = items.isEmpty ? _kFallbackDamageDetails : items;
                return _buildCheckList(options, _damages);
              },
            );
          },
        );
      case _Cat.batteryHealth:
        return Consumer(
          builder: (context, ref, _) {
            final async = ref.watch(mobileBatteryHealthsProvider);
            return async.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Error loading battery health',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
                ),
              ),
              data: (items) {
                final options = items.isEmpty ? _kFallbackBatteryHealths : items;
                return _buildCheckList(options, _batteries);
              },
            );
          },
        );
      case _Cat.version:
        return Consumer(
          builder: (context, ref, _) {
            final async = ref.watch(mobileVersionsProvider);
            return async.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Error loading versions',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
                ),
              ),
              data: (items) {
                final options = items.isEmpty ? _kFallbackVersions : items;
                return _buildCheckList(options, _versions);
              },
            );
          },
        );
      case _Cat.storage:
        return Consumer(
          builder: (context, ref, _) {
            final async = ref.watch(mobileStoragesProvider);
            return async.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Error loading storage values',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
                ),
              ),
              data: (items) {
                final options = items.isEmpty ? _kFallbackStorages : items;
                return _buildCheckList(options, _storages);
              },
            );
          },
        );
      case _Cat.color:
        return _buildColor();
      case _Cat.region:
        return _buildRegion();
    }
  }

  // ── Right panel builders ───────────────────────────────────────────────────

  Widget _buildBrand() {
    return Consumer(
      builder: (context, ref, _) {
        final asyncBrands = ref.watch(mobileFilterBrandsProvider);
        return asyncBrands.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2),
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              'Error loading brands',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
            ),
          ),
          data: (items) {
            final brands = items.isEmpty ? _kFallbackBrands : items;
            final filtered = brands
                .where((b) => b.toLowerCase().contains(_brandSearch.toLowerCase()))
                .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: _searchBox(
                    'Search brand',
                    (v) => setState(() => _brandSearch = v),
                  ),
                ),
                ...filtered.map(
                  (b) => _CheckRow(
                    label: b,
                    selected: _brands.contains(b),
                    onTap: () => setState(
                      () => _brands.contains(b) ? _brands.remove(b) : _brands.add(b),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildModel() {
    return Consumer(
      builder: (context, ref, _) {
        final asyncBrands = ref.watch(mobileFilterBrandsProvider);
        final brands = asyncBrands.valueOrNull;
        final brandOptions =
            (brands == null || brands.isEmpty) ? _kFallbackBrands : brands;
        final activeBrand = _modelBrand.isEmpty ? brandOptions.first : _modelBrand;
        final asyncModels = ref.watch(mobileModelsByBrandProvider(activeBrand));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search (above dropdown) ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: _searchBox('Search model', (v) => setState(() => _modelSearch = v)),
            ),
            // ── Brand dropdown ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: GestureDetector(
                onTap: () => setState(() => _modelDropOpen = !_modelDropOpen),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD9D9D9)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          activeBrand,
                          style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black87),
                        ),
                      ),
                      Icon(
                        _modelDropOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 18,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_modelDropOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD9D9D9)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: brandOptions.map((b) => InkWell(
                      onTap: () => setState(() {
                        _modelBrand = b;
                        _modelDropOpen = false;
                        _modelSearch = '';
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        child: Row(
                          children: [
                            Expanded(child: Text(b, style: GoogleFonts.poppins(fontSize: 12.5))),
                            if (activeBrand == b)
                              const Icon(Icons.check, size: 14, color: _kBlue),
                          ],
                        ),
                      ),
                    )).toList(),
                  ),
                ),
              ),
            // ── Model list (dynamic from Supabase) ──────────────
            asyncModels.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2)),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(14),
                child: Text('Error loading models', style: GoogleFonts.poppins(fontSize: 12, color: Colors.red)),
              ),
              data: (allModels) {
                final filtered = allModels
                    .where((m) => m.toLowerCase().contains(_modelSearch.toLowerCase()))
                    .toList();
                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      'No models found',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.black45),
                    ),
                  );
                }
                return Column(
                  children: filtered.map((m) => _CheckRow(
                    label: m,
                    selected: _models.contains(m),
                    onTap: () => setState(() =>
                        _models.contains(m) ? _models.remove(m) : _models.add(m)),
                  )).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPriceRange() {
    const labels = ['150K+', '113K', '75K', '38K', '0'];
    const sliderPad = 24.0;
    // No SingleChildScrollView — outer right panel already scrolls
    return Padding(
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
                        thumbShape: _WhiteThumbShape(),
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
                // Labels aligned to slider track
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
            label: 'Max price AFN',
            controller: _maxCtrl,
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
                  child: Text('Min price AFN',
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

  Color _colorForName(String colorName) {
    final trimmed = colorName.trim();
    final mapped = _kColorMap.entries.firstWhere(
      (entry) => entry.key.toLowerCase() == trimmed.toLowerCase(),
      orElse: () => const MapEntry('', Color(0xFFE0E0E0)),
    );
    if (mapped.key.isNotEmpty) return mapped.value;

    final hex = trimmed.replaceAll('#', '');
    if (hex.length == 6) {
      final value = int.tryParse(hex, radix: 16);
      if (value != null) return Color(0xFF000000 | value);
    }
    if (hex.length == 8) {
      final value = int.tryParse(hex, radix: 16);
      if (value != null) return Color(value);
    }
    return const Color(0xFFE0E0E0);
  }

  Widget _buildColor() {
    return Consumer(
      builder: (context, ref, _) {
        final async = ref.watch(mobileColorsProvider);
        return async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2),
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              'Error loading colors',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
            ),
          ),
          data: (items) {
            final colorNames = items.isEmpty ? _kColorMap.keys.toList() : items;
            return Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Color',
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: colorNames.map((name) {
                      final swatchColor = _colorForName(name);
                      final selected = _colors.contains(name);
                      return GestureDetector(
                        onTap: () => setState(() => selected
                            ? _colors.remove(name)
                            : _colors.add(name)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: swatchColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? _kBlue
                                      : const Color(0xFFD9D9D9),
                                  width: selected ? 2.5 : 1,
                                ),
                              ),
                              child: selected
                                  ? Icon(
                                      Icons.check,
                                      size: 16,
                                      color: swatchColor.computeLuminance() > 0.5
                                          ? Colors.black
                                          : Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              name,
                              style: GoogleFonts.poppins(
                                  fontSize: 9, color: Colors.black87),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRegion() {
    final locations = widget.cities;
    final filtered = locations
        .where((c) =>
            c.toLowerCase().contains(_regionSearch.toLowerCase()))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: _searchBox('Search location',
              (v) => setState(() => _regionSearch = v)),
        ),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text('No locations available',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.black45)),
          )
        else
          ...filtered.map((c) => _CheckRow(
                label: c,
                selected: _regions.contains(c),
                onTap: () => setState(() => _regions.contains(c)
                    ? _regions.remove(c)
                    : _regions.add(c)),
              )),
      ],
    );
  }

  Widget _buildCheckList(List<String> items, Set<String> selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((item) => _CheckRow(
                label: item,
                selected: selected.contains(item),
                onTap: () => setState(() => selected.contains(item)
                    ? selected.remove(item)
                    : selected.add(item)),
              ))
          .toList(),
    );
  }


  Widget _searchBox(String hint, ValueChanged<String> onChanged) {
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
              style: GoogleFonts.poppins(
                  fontSize: 11, height: 18 / 11, letterSpacing: 0, color: Colors.black),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.poppins(
                    fontSize: 11, height: 18 / 11, color: Colors.black),
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

// ── Helpers ────────────────────────────────────────────────────────────────────

class _CheckRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CheckRow({
    required this.label,
    required this.selected,
    required this.onTap,
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
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: selected ? _kBlue : Colors.white,
                border: Border.all(
                  color: selected ? _kBlue : const Color(0xFFBBBBBB),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: selected
                  ? const Center(child: Icon(Icons.check, size: 12, color: Colors.white))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.0,
                    letterSpacing: 0,
                    color: selected ? _kBlue : Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhiteThumbShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(18, 18);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
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
          ..color = _kBlue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }
}
