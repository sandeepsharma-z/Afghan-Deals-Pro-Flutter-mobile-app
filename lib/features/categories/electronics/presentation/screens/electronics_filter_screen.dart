import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/electronics_provider.dart';

const _kBlue = Color(0xFF2258A8);

class ElectronicsFilterScreen extends ConsumerStatefulWidget {
  final String subcategory;
  const ElectronicsFilterScreen({super.key, required this.subcategory});

  @override
  ConsumerState<ElectronicsFilterScreen> createState() =>
      _ElectronicsFilterScreenState();
}

class _ElectronicsFilterScreenState
    extends ConsumerState<ElectronicsFilterScreen> {
  int _selectedSection = 0;

  static const _kSections = [
    ('Brand', Icons.label_outline),
    ('Model', Icons.devices),
    ('Condition', Icons.check_circle_outline),
    ('Price Range', Icons.attach_money),
    ('Seller Type', Icons.person_outline),
    ('Age', Icons.schedule),
    ('Warranty', Icons.security),
    ('Region', Icons.location_on_outlined),
  ];

  late ElectronicsFilter _draft;

  final _brandSearchCtrl = TextEditingController();
  final _modelSearchCtrl = TextEditingController();
  String _modelBrand = '';

  @override
  void initState() {
    super.initState();
    _draft = ref.read(electronicsFilterProvider);
    _modelBrand = _draft.brands.isNotEmpty ? _draft.brands.first : '';
  }

  @override
  void dispose() {
    _brandSearchCtrl.dispose();
    _modelSearchCtrl.dispose();
    super.dispose();
  }

  bool _sectionHasValue(int i) {
    switch (i) {
      case 0:
        return _draft.brands.isNotEmpty;
      case 1:
        return _draft.models.isNotEmpty;
      case 2:
        return _draft.conditions.isNotEmpty;
      case 3:
        return _draft.minPrice != null || _draft.maxPrice != null;
      case 4:
        return _draft.sellerTypes.isNotEmpty;
      case 5:
        return _draft.ages.isNotEmpty;
      case 6:
        return _draft.warranties.isNotEmpty;
      case 7:
        return _draft.region.isNotEmpty;
      default:
        return false;
    }
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
            onPressed: () {
              setState(() {
                _draft = const ElectronicsFilter();
                _brandSearchCtrl.clear();
                _modelSearchCtrl.clear();
                _modelBrand = '';
              });
              ref.read(electronicsFilterProvider.notifier).state =
                  const ElectronicsFilter();
            },
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
      body: Builder(builder: (context) {
        final panelH = (MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom -
                210)
            .clamp(200.0, double.infinity);
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left panel ──────────────────────────────────────────
              SizedBox(
                width: (MediaQuery.of(context).size.width - 34) / 2,
                height: panelH,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(22),
                    border:
                        Border.all(color: const Color(0xFFD0D0D0), width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          List.generate(_kSections.length, _buildLeftItem),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // ── Right panel ─────────────────────────────────────────
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
          border:
              Border(bottom: BorderSide(color: Color(0xFFE8E9EB), width: 1)),
        ),
        child: Row(
          children: [
            Icon(_kSections[i].$2,
                size: 14, color: isActive ? _kBlue : const Color(0xFF7C7D88)),
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
                  letterSpacing: 0,
                  color: isActive ? _kBlue : Colors.black,
                ),
              ),
            ),
            if (hasValue) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check_circle,
                  color: Color(0xFF00BA00), size: 21),
            ],
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
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                ref.read(electronicsFilterProvider.notifier).state = _draft;
                Navigator.of(context).pop();
              },
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

  Widget _buildSectionContent() {
    switch (_selectedSection) {
      case 0:
        return _brandSection();
      case 1:
        return _modelSection();
      case 2:
        return _checklistSection(
            ref.watch(
                electronicsConditionsBySubcategoryProvider(widget.subcategory)),
            selected: _draft.conditions,
            onToggle: (v) => setState(() => _draft =
                _draft.copyWith(conditions: _toggle(_draft.conditions, v))));
      case 3:
        return _priceSection();
      case 4:
        return _checklistSection(
            ref.watch(electronicsSellerTypesBySubcategoryProvider(
                widget.subcategory)),
            selected: _draft.sellerTypes,
            onToggle: (v) => setState(() => _draft =
                _draft.copyWith(sellerTypes: _toggle(_draft.sellerTypes, v))));
      case 5:
        return _checklistSection(
            ref.watch(electronicsAgesBySubcategoryProvider(widget.subcategory)),
            selected: _draft.ages,
            onToggle: (v) => setState(
                () => _draft = _draft.copyWith(ages: _toggle(_draft.ages, v))));
      case 6:
        return _checklistSection(
            ref.watch(
                electronicsWarrantiesBySubcategoryProvider(widget.subcategory)),
            selected: _draft.warranties,
            onToggle: (v) => setState(() => _draft =
                _draft.copyWith(warranties: _toggle(_draft.warranties, v))));
      case 7:
        return _regionSection();
      default:
        return const SizedBox();
    }
  }

  // ── Brand section with search ────────────────────────────────────────────
  Widget _brandSection() {
    return ref
        .watch(electronicsBrandsBySubcategoryProvider(widget.subcategory))
        .when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
                child:
                    CircularProgressIndicator(color: _kBlue, strokeWidth: 2)),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(14),
            child: Text('Error: $e',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.red)),
          ),
          data: (brands) {
            final query = _brandSearchCtrl.text.toLowerCase();
            final filtered = query.isEmpty
                ? brands
                : brands.where((b) => b.toLowerCase().contains(query)).toList();
            return Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                  child: TextField(
                    controller: _brandSearchCtrl,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.poppins(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.black38),
                      prefixIcon: const Icon(Icons.search,
                          size: 16, color: Colors.black45),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                      ),
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text('No brands found',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.black45)),
                  )
                else
                  ...filtered.map((brand) {
                    final isChecked = _draft.brands
                        .any((b) => b.toLowerCase() == brand.toLowerCase());
                    return _CheckRow(
                      label: brand,
                      selected: isChecked,
                      onTap: () {
                        final newBrands = _toggle(_draft.brands, brand);
                        setState(() {
                          _draft = _draft.copyWith(brands: newBrands);
                          if (_modelBrand.isEmpty && newBrands.isNotEmpty) {
                            _modelBrand = newBrands.first;
                          } else if (newBrands.isEmpty) {
                            _modelBrand = '';
                          }
                        });
                      },
                    );
                  }),
              ],
            );
          },
        );
  }

  // ── Model section with search + brand dropdown ───────────────────────────
  Widget _modelSection() {
    final activeBrand = _modelBrand.isNotEmpty
        ? _modelBrand
        : (_draft.brands.isNotEmpty ? _draft.brands.first : '');

    return ref
        .watch(electronicsModelsBySubcategoryProvider(
            (brand: activeBrand, subcategory: widget.subcategory)))
        .when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
                child:
                    CircularProgressIndicator(color: _kBlue, strokeWidth: 2)),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(14),
            child: Text('Error: $e',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.red)),
          ),
          data: (models) {
            final query = _modelSearchCtrl.text.toLowerCase();
            final filtered = query.isEmpty
                ? models
                : models.where((m) => m.toLowerCase().contains(query)).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                  child: TextField(
                    controller: _modelSearchCtrl,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.poppins(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.black38),
                      prefixIcon: const Icon(Icons.search,
                          size: 16, color: Colors.black45),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                      ),
                    ),
                  ),
                ),
                // Brand dropdown (only when brands are selected)
                if (_draft.brands.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFDDDDDD)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _modelBrand.isNotEmpty
                              ? _modelBrand
                              : _draft.brands.first,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down,
                              size: 18, color: Colors.black54),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: Colors.black87),
                          items: _draft.brands
                              .map((b) =>
                                  DropdownMenuItem(value: b, child: Text(b)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _modelBrand = v);
                          },
                        ),
                      ),
                    ),
                  ),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      _draft.brands.isEmpty
                          ? 'Select a brand first'
                          : 'No models found',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.black45),
                    ),
                  )
                else
                  ...filtered.map((model) {
                    final isChecked = _draft.models
                        .any((m) => m.toLowerCase() == model.toLowerCase());
                    return _CheckRow(
                      label: model,
                      selected: isChecked,
                      onTap: () => setState(() => _draft = _draft.copyWith(
                          models: _toggle(_draft.models, model))),
                    );
                  }),
              ],
            );
          },
        );
  }

  // ── Price section with vertical slider ───────────────────────────────────
  Widget _priceSection() {
    return ref
        .watch(electronicsMaxPriceBySubcategoryProvider(widget.subcategory))
        .when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
                child:
                    CircularProgressIndicator(color: _kBlue, strokeWidth: 2)),
          ),
          error: (_, __) => _priceSectionBody(100000),
          data: _priceSectionBody,
        );
  }

  Widget _priceSectionBody(double maxVal) {
    final currentMax = (_draft.maxPrice ?? maxVal).clamp(0.0, maxVal);

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical slider
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Price labels
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _priceLabel('${(maxVal / 1000).toInt()}K+',
                        isHighlighted: currentMax >= maxVal * 0.9),
                    _priceLabel('${(maxVal * 0.75 / 1000).toInt()}K',
                        isHighlighted: currentMax >= maxVal * 0.625 &&
                            currentMax < maxVal * 0.9),
                    _priceLabel('${(maxVal * 0.5 / 1000).toInt()}K',
                        isHighlighted: currentMax >= maxVal * 0.375 &&
                            currentMax < maxVal * 0.625),
                    _priceLabel('${(maxVal * 0.25 / 1000).toInt()}K',
                        isHighlighted: currentMax >= maxVal * 0.125 &&
                            currentMax < maxVal * 0.375),
                    _priceLabel('0',
                        isHighlighted: currentMax < maxVal * 0.125),
                  ],
                ),
                const SizedBox(width: 8),
                // Vertical slider (rotated horizontal)
                SizedBox(
                  width: 36,
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _kBlue,
                        inactiveTrackColor: const Color(0xFFDDDDDD),
                        thumbColor: _kBlue,
                        overlayColor: _kBlue.withValues(alpha: 0.15),
                        trackHeight: 3,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 7),
                      ),
                      child: Slider(
                        value: currentMax,
                        min: 0,
                        max: maxVal,
                        onChanged: (v) => setState(() => _draft =
                            _draft.copyWith(maxPrice: v == 0 ? null : v)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Max price field
          TextFormField(
            key: ValueKey('max_${_draft.maxPrice}'),
            initialValue: _draft.maxPrice != null
                ? _draft.maxPrice!.toStringAsFixed(0)
                : '',
            keyboardType: TextInputType.number,
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Max price AFN',
              hintStyle:
                  GoogleFonts.poppins(fontSize: 13, color: Colors.black38),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (v) {
              final parsed = double.tryParse(v);
              setState(() => _draft = _draft.copyWith(maxPrice: parsed));
            },
          ),
          const SizedBox(height: 12),
          // Min price field
          TextFormField(
            key: ValueKey('min_${_draft.minPrice}'),
            initialValue: _draft.minPrice != null
                ? _draft.minPrice!.toStringAsFixed(0)
                : '',
            keyboardType: TextInputType.number,
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Min price AFN',
              hintStyle:
                  GoogleFonts.poppins(fontSize: 13, color: Colors.black38),
              labelText: _draft.minPrice != null ? 'Min price AFN' : null,
              labelStyle:
                  GoogleFonts.poppins(fontSize: 12, color: Colors.black45),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (v) {
              final parsed = double.tryParse(v);
              setState(() => _draft = _draft.copyWith(minPrice: parsed));
            },
          ),
        ],
      ),
    );
  }

  Widget _priceLabel(String text, {required bool isHighlighted}) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
        color: isHighlighted ? _kBlue : Colors.black45,
      ),
    );
  }

  // ── Region section ────────────────────────────────────────────────────────
  Widget _regionSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextFormField(
        initialValue: _draft.region,
        decoration: InputDecoration(
          hintText: 'Search region / city',
          prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        style: GoogleFonts.poppins(fontSize: 13),
        onChanged: (v) => setState(() => _draft = _draft.copyWith(region: v)),
      ),
    );
  }

  // ── Generic checklist section ─────────────────────────────────────────────
  Widget _checklistSection(
    AsyncValue<List<String>> async, {
    required List<String> selected,
    required void Function(String) onToggle,
  }) {
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
            child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(14),
        child: Text('Error: $e',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.red)),
      ),
      data: (items) => items.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(14),
              child: Text('No options',
                  style:
                      GoogleFonts.poppins(fontSize: 12, color: Colors.black45)),
            )
          : Column(
              children: items.map((item) {
                final isChecked =
                    selected.any((s) => s.toLowerCase() == item.toLowerCase());
                return _CheckRow(
                  label: item,
                  selected: isChecked,
                  onTap: () => onToggle(item),
                );
              }).toList(),
            ),
    );
  }

  List<String> _toggle(List<String> list, String value) {
    final lower = value.toLowerCase();
    if (list.any((e) => e.toLowerCase() == lower)) {
      return list.where((e) => e.toLowerCase() != lower).toList();
    }
    return [...list, value];
  }
}

// ── Shared checkbox row ────────────────────────────────────────────────────────
class _CheckRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CheckRow(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                color: selected ? _kBlue : Colors.white,
                border: Border.all(
                    color: selected ? _kBlue : const Color(0xFFBBBBBB),
                    width: 1.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: selected
                  ? const Center(
                      child: Icon(Icons.check, size: 12, color: Colors.white))
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
                  color: selected ? _kBlue : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
