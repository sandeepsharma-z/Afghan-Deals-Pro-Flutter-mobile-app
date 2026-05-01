import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

const _kBlue = Color(0xFF2258A8);

class CarFilters {
  final Set<String> makes;
  final Set<String> models;
  final Set<String> subModels;
  final Set<String> specs;
  final Set<String> dealTypes;
  final Set<String> transmission;
  final Set<String> fuelType;
  final Set<String> extColors;
  final Set<String> driveLines;
  final Set<String> cylinders;
  final Set<String> intColors;
  final Set<String> regions;
  final Set<String> cities;
  final int fromYear;
  final int toYear;
  final double minPrice;
  final double maxPrice;

  CarFilters({
    required this.makes,
    required this.models,
    required this.subModels,
    required this.specs,
    required this.dealTypes,
    required this.transmission,
    required this.fuelType,
    required this.extColors,
    required this.driveLines,
    required this.cylinders,
    required this.intColors,
    required this.regions,
    required this.cities,
    required this.fromYear,
    required this.toYear,
    required this.minPrice,
    required this.maxPrice,
  });
}

class CarsFilterScreen extends ConsumerStatefulWidget {
  final CarFilters? initialFilters;
  const CarsFilterScreen({super.key, this.initialFilters});

  @override
  ConsumerState<CarsFilterScreen> createState() => _CarsFilterScreenState();
}

class _CarsFilterScreenState extends ConsumerState<CarsFilterScreen> {
  int _selectedSection = 0;
  late List<String> _availableMakes;
  late List<String> _availableModels;
  late List<String> _availableTransmissions;
  late List<String> _availableFuelTypes;
  late List<String> _availableColors;
  late List<String> _availableDriveLines;
  late List<String> _availableCylinders;
  late List<String> _availableIntColors;
  late List<String> _availableRegions;
  late List<String> _availableCities;

  static const _kSections = [
    ('Makes', Icons.directions_car_outlined),
    ('Models', Icons.style_outlined),
    ('Sub-Models', Icons.dashboard_outlined),
    ('Year Range', Icons.calendar_today_outlined),
    ('Specs', Icons.info_outlined),
    ('Deal Type', Icons.person_outline),
    ('Transmission', Icons.settings_outlined),
    ('Fuel Type', Icons.local_gas_station_outlined),
    ('Ext. Color', Icons.palette_outlined),
    ('Driveline', Icons.trending_up_outlined),
    ('Cylinders', Icons.blur_on_outlined),
    ('Int. Color', Icons.color_lens_outlined),
    ('Region', Icons.location_on_outlined),
    ('City', Icons.location_city_outlined),
    ('Price Range', Icons.attach_money_outlined),
  ];

  late Set<String> _makes;
  late Set<String> _models;
  late Set<String> _subModels;
  late Set<String> _specs;
  late Set<String> _dealTypes;
  late Set<String> _transmission;
  late Set<String> _fuelTypes;
  late Set<String> _extColors;
  late Set<String> _driveLines;
  late Set<String> _cylinders;
  late Set<String> _intColors;
  late Set<String> _regions;
  late Set<String> _cities;
  late int _fromYear;
  late int _toYear;
  late double _minPrice;
  late double _maxPrice;

  @override
  void initState() {
    super.initState();
    _initFromPrevious();
    _setDefaultValues();
  }

  void _setDefaultValues() {
    _availableMakes = ['Toyota', 'Honda', 'BMW', 'Mercedes-Benz', 'Audi', 'Volkswagen', 'Ford', 'Chevrolet', 'Hyundai', 'Kia', 'Nissan', 'Mazda'];
    _availableModels = ['Civic', 'Accord', 'CR-V', 'Pilot', 'Camry', 'Corolla', 'Land Cruiser', '3 Series', '5 Series', '7 Series', 'X5', 'X3'];
    _availableTransmissions = ['Manual', 'Automatic', 'CVT'];
    _availableFuelTypes = ['Petrol', 'Diesel', 'CNG', 'Hybrid', 'Electric'];
    _availableColors = ['White', 'Silver', 'Grey', 'Black', 'Red', 'Gold', 'Orange', 'Blue', 'Beige', 'Yellow', 'Purple', 'Brown', 'Green'];
    _availableDriveLines = ['FWD', 'RWD', 'AWD', '4WD'];
    _availableCylinders = ['3', '4', '6', '8', '10', '12'];
    _availableIntColors = ['Beige', 'Black', 'Red', 'Silver', 'Burgundy', 'Grey', 'White', 'Brown'];
    _availableRegions = ['Kabul', 'Kandahar', 'Herat', 'Balkh', 'Nangarhar', 'Kunduz'];
    _availableCities = ['Kabul', 'Kandahar', 'Herat', 'Mazar-e Sharif', 'Jalalabad'];
  }

  void _initFromPrevious() {
    if (widget.initialFilters != null) {
      _makes = Set.from(widget.initialFilters!.makes);
      _models = Set.from(widget.initialFilters!.models);
      _subModels = Set.from(widget.initialFilters!.subModels);
      _specs = Set.from(widget.initialFilters!.specs);
      _dealTypes = Set.from(widget.initialFilters!.dealTypes);
      _transmission = Set.from(widget.initialFilters!.transmission);
      _fuelTypes = Set.from(widget.initialFilters!.fuelType);
      _extColors = Set.from(widget.initialFilters!.extColors);
      _driveLines = Set.from(widget.initialFilters!.driveLines);
      _cylinders = Set.from(widget.initialFilters!.cylinders);
      _intColors = Set.from(widget.initialFilters!.intColors);
      _regions = Set.from(widget.initialFilters!.regions);
      _cities = Set.from(widget.initialFilters!.cities);
      _fromYear = widget.initialFilters!.fromYear;
      _toYear = widget.initialFilters!.toYear;
      _minPrice = widget.initialFilters!.minPrice;
      _maxPrice = widget.initialFilters!.maxPrice;
    } else {
      _makes = {};
      _models = {};
      _subModels = {};
      _specs = {};
      _dealTypes = {};
      _transmission = {};
      _fuelTypes = {};
      _extColors = {};
      _driveLines = {};
      _cylinders = {};
      _intColors = {};
      _regions = {};
      _cities = {};
      _fromYear = 2000;
      _toYear = 2027;
      _minPrice = 0;
      _maxPrice = 150000;
    }
  }

  bool _sectionHasValue(int i) {
    switch (i) {
      case 0:  return _makes.isNotEmpty;
      case 1:  return _models.isNotEmpty;
      case 2:  return _subModels.isNotEmpty;
      case 3:  return _fromYear != 2000 || _toYear != 2027;
      case 4:  return _specs.isNotEmpty;
      case 5:  return _dealTypes.isNotEmpty;
      case 6:  return _transmission.isNotEmpty;
      case 7:  return _fuelTypes.isNotEmpty;
      case 8:  return _extColors.isNotEmpty;
      case 9:  return _driveLines.isNotEmpty;
      case 10: return _cylinders.isNotEmpty;
      case 11: return _intColors.isNotEmpty;
      case 12: return _regions.isNotEmpty;
      case 13: return _cities.isNotEmpty;
      case 14: return _minPrice != 0 || _maxPrice != 150000;
      default: return false;
    }
  }

  void _reset() {
    setState(() {
      _makes.clear();
      _models.clear();
      _subModels.clear();
      _specs.clear();
      _dealTypes.clear();
      _transmission.clear();
      _fuelTypes.clear();
      _extColors.clear();
      _driveLines.clear();
      _cylinders.clear();
      _intColors.clear();
      _regions.clear();
      _cities.clear();
      _minPrice = 0;
      _maxPrice = 150000;
      // Keep original year range from navigation, don't reset it
    });
  }

  void _apply() {
    final filters = CarFilters(
      makes: _makes,
      models: _models,
      subModels: _subModels,
      specs: _specs,
      dealTypes: _dealTypes,
      transmission: _transmission,
      fuelType: _fuelTypes,
      extColors: _extColors,
      driveLines: _driveLines,
      cylinders: _cylinders,
      intColors: _intColors,
      regions: _regions,
      cities: _cities,
      fromYear: _fromYear,
      toYear: _toYear,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
    );
    Navigator.pop(context, filters);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Filter',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
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
                MediaQuery.of(context).padding.bottom - 170)
            .clamp(200.0, double.infinity);
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: (MediaQuery.of(context).size.width - 34) / 2,
                height: panelH,
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
                      children: List.generate(_kSections.length, _buildLeftItem),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: panelH,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                      child: _buildSectionContent(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildLeftItem(int i) {
    final isActive = i == _selectedSection;
    final hasValue = _sectionHasValue(i);
    return InkWell(
      onTap: () => setState(() => _selectedSection = i),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: const BoxDecoration(
          color: Colors.transparent,
          border: Border(bottom: BorderSide(color: Color(0xFFE8E9EB), width: 1)),
        ),
        child: Row(
          children: [
            Icon(_kSections[i].$2, size: 14, color: isActive ? _kBlue : const Color(0xFF7C7D88)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _kSections[i].$1,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                  color: isActive ? _kBlue : Colors.black,
                ),
              ),
            ),
            if (hasValue) const Icon(Icons.check_circle, color: Color(0xFF00BA00), size: 21),
          ],
        ),
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
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  child: Text('Reset',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _kBlue)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Apply',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_selectedSection) {
      case 0:  return _checklistSection(items: _availableMakes, selected: _makes, onToggle: (v) => setState(() => _makes = _toggle(_makes, v)));
      case 1:  return _checklistSection(items: _availableModels, selected: _models, onToggle: (v) => setState(() => _models = _toggle(_models, v)));
      case 2:  return _checklistSection(items: const ['Standard', 'Sport', 'Luxury', 'SE', 'EX', 'GL', 'GT', 'LX', 'DX', 'GLE', 'GLX', 'S-Line', 'RS'], selected: _subModels, onToggle: (v) => setState(() => _subModels = _toggle(_subModels, v)));
      case 3:  return _yearRangeSection();
      case 4:  return _checklistSection(items: const ['Used', 'New', 'Export', 'Rental'], selected: _specs, onToggle: (v) => setState(() => _specs = _toggle(_specs, v)));
      case 5:  return _checklistSection(items: const ['Owner', 'Dealer', 'Agent'], selected: _dealTypes, onToggle: (v) => setState(() => _dealTypes = _toggle(_dealTypes, v)));
      case 6:  return _checklistSection(items: _availableTransmissions, selected: _transmission, onToggle: (v) => setState(() => _transmission = _toggle(_transmission, v)));
      case 7:  return _checklistSection(items: _availableFuelTypes, selected: _fuelTypes, onToggle: (v) => setState(() => _fuelTypes = _toggle(_fuelTypes, v)));
      case 8:  return _checklistSection(items: _availableColors, selected: _extColors, onToggle: (v) => setState(() => _extColors = _toggle(_extColors, v)));
      case 9:  return _checklistSection(items: _availableDriveLines, selected: _driveLines, onToggle: (v) => setState(() => _driveLines = _toggle(_driveLines, v)));
      case 10: return _checklistSection(items: _availableCylinders, selected: _cylinders, onToggle: (v) => setState(() => _cylinders = _toggle(_cylinders, v)));
      case 11: return _checklistSection(items: _availableIntColors, selected: _intColors, onToggle: (v) => setState(() => _intColors = _toggle(_intColors, v)));
      case 12: return _checklistSection(items: _availableRegions, selected: _regions, onToggle: (v) => setState(() => _regions = _toggle(_regions, v)));
      case 13: return _checklistSection(items: _availableCities, selected: _cities, onToggle: (v) => setState(() => _cities = _toggle(_cities, v)));
      case 14: return _priceRangeSection();
      default: return const SizedBox();
    }
  }

  Widget _checklistSection({required List<String> items, required Set<String> selected, required Function(String) onToggle}) {
    return Column(
      children: items.map((item) {
        final isChecked = selected.any((s) => s.toLowerCase() == item.toLowerCase());
        return _CheckRow(label: item, selected: isChecked, onTap: () => onToggle(item));
      }).toList(),
    );
  }

  Widget _yearRangeSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('From', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          _yearDropdown(_fromYear, 1990, 2027, (v) => setState(() => _fromYear = v)),
          const SizedBox(height: 16),
          Text('To', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          _yearDropdown(_toYear, 1990, 2027, (v) => setState(() => _toYear = v)),
        ],
      ),
    );
  }

  Widget _priceRangeSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Min Price', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          _priceDropdown(_minPrice.toInt(), 0, 150000, (v) => setState(() => _minPrice = v.toDouble())),
          const SizedBox(height: 16),
          Text('Max Price', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          _priceDropdown(_maxPrice.toInt(), 0, 150000, (v) => setState(() => _maxPrice = v.toDouble())),
        ],
      ),
    );
  }

  Widget _yearDropdown(int value, int min, int max, ValueChanged<int> onChanged) {
    return Container(
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
              .map((e) => DropdownMenuItem<int>(value: e, child: Text(e.toString())))
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ),
    );
  }

  Widget _priceDropdown(int value, int min, int max, ValueChanged<int> onChanged) {
    return Container(
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
          items: List.generate((max - min) ~/ 5000 + 1, (i) => min + (i * 5000))
              .map((e) => DropdownMenuItem<int>(value: e, child: Text('${(e / 1000).toStringAsFixed(0)}K')))
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ),
    );
  }

  Set<String> _toggle(Set<String> set, String value) {
    if (set.contains(value)) {
      set.remove(value);
    } else {
      set.add(value);
    }
    return set;
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CheckRow({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE8E9EB), width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: selected ? _kBlue : Colors.white,
                border: Border.all(color: selected ? _kBlue : const Color(0xFFBBBBBB), width: 1.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: selected ? const Center(child: Icon(Icons.check, size: 12, color: Colors.white)) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: selected ? _kBlue : Colors.black,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
