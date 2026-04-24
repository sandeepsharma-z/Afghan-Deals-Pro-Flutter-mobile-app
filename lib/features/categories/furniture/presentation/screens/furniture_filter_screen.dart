import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/furniture_provider.dart';

const _kBlue = Color(0xFF2258A8);

const _colorSwatches = <String, Color>{
  'White':    Color(0xFFF5F5F5),
  'Silver':   Color(0xFFC0C0C0),
  'Grey':     Color(0xFF808080),
  'Black':    Color(0xFF1A1A1A),
  'Red':      Color(0xFFE53935),
  'Gold':     Color(0xFFFFD700),
  'Orange':   Color(0xFFFF7043),
  'Blue':     Color(0xFF1565C0),
  'Beige':    Color(0xFFF5F0DC),
  'Yellow':   Color(0xFFFFEB3B),
  'Purple':   Color(0xFF7B1FA2),
  'Cement':   Color(0xFF8B8682),
  'Burgundy': Color(0xFF800020),
  'Green':    Color(0xFF2E7D32),
  'Brown':    Color(0xFF6D4C41),
};

class FurnitureFilterScreen extends ConsumerStatefulWidget {
  final String subcategory;
  const FurnitureFilterScreen({super.key, required this.subcategory});

  @override
  ConsumerState<FurnitureFilterScreen> createState() =>
      _FurnitureFilterScreenState();
}

class _FurnitureFilterScreenState extends ConsumerState<FurnitureFilterScreen> {
  int _selectedSection = 0;

  static const _kSections = [
    ('Furniture',     Icons.chair_outlined),
    ('Brand',         Icons.label_outline),
    ('Condition',     Icons.check_circle_outline),
    ('Price Range',   Icons.attach_money),
    ('Seller Type',   Icons.person_outline),
    ('Age',           Icons.schedule_outlined),
    ('Usage',         Icons.loop_outlined),
    ('Room type',     Icons.bed_outlined),
    ('Item Shape',    Icons.category_outlined),
    ('Fill Material', Icons.layers_outlined),
    ('Color',         Icons.palette_outlined),
    ('Shape',         Icons.shape_line_outlined),
    ('Type',          Icons.list_alt_outlined),
    ('Material',      Icons.texture_outlined),
  ];

  late FurnitureFilter _draft;
  final _brandSearch = TextEditingController();

  @override
  void initState() {
    super.initState();
    _draft = ref.read(furnitureFilterProvider);
  }

  @override
  void dispose() {
    _brandSearch.dispose();
    super.dispose();
  }

  bool _sectionHasValue(int i) {
    switch (i) {
      case 0:  return _draft.subcategories.isNotEmpty;
      case 1:  return _draft.brands.isNotEmpty;
      case 2:  return _draft.conditions.isNotEmpty;
      case 3:  return _draft.minPrice != null || _draft.maxPrice != null;
      case 4:  return _draft.sellerTypes.isNotEmpty;
      case 5:  return _draft.ages.isNotEmpty;
      case 6:  return _draft.usages.isNotEmpty;
      case 7:  return _draft.roomTypes.isNotEmpty;
      case 8:  return _draft.itemShapes.isNotEmpty;
      case 9:  return _draft.fillMaterials.isNotEmpty;
      case 10: return _draft.colors.isNotEmpty;
      case 11: return _draft.shapes.isNotEmpty;
      case 12: return _draft.types.isNotEmpty;
      case 13: return _draft.materials.isNotEmpty;
      default: return false;
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
          icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Filter',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _draft = const FurnitureFilter());
              ref.read(furnitureFilterProvider.notifier).state =
                  const FurnitureFilter();
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
                MediaQuery.of(context).padding.bottom - 210)
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
          border: Border(bottom: BorderSide(color: Color(0xFFE8E9EB), width: 1)),
        ),
        child: Row(
          children: [
            Icon(_kSections[i].$2,
                size: 14,
                color: isActive ? _kBlue : const Color(0xFF7C7D88)),
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
              const Icon(Icons.check_circle, color: Color(0xFF00BA00), size: 21),
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
                ref.read(furnitureFilterProvider.notifier).state = _draft;
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
        return _checklistSection(
          ref.watch(furnitureSubcategoriesProvider).when(
            loading: () => const AsyncValue.loading(),
            error: (e, s) => AsyncValue.error(e, s),
            data: (subs) => AsyncValue.data(subs.map((s) => s.name).toList()),
          ),
          selected: _draft.subcategories,
          onToggle: (v) => setState(() => _draft = _draft.copyWith(
              subcategories: _toggle(_draft.subcategories, v))),
        );
      case 1:
        return _brandSection();
      case 2:
        return _checklistSection(ref.watch(furnitureConditionsProvider),
            selected: _draft.conditions,
            onToggle: (v) => setState(() => _draft =
                _draft.copyWith(conditions: _toggle(_draft.conditions, v))));
      case 3:
        return _priceSection();
      case 4:
        return _checklistSection(ref.watch(furnitureSellerTypesProvider),
            selected: _draft.sellerTypes,
            onToggle: (v) => setState(() => _draft =
                _draft.copyWith(sellerTypes: _toggle(_draft.sellerTypes, v))));
      case 5:
        return _checklistSection(ref.watch(furnitureAgesProvider),
            selected: _draft.ages,
            onToggle: (v) => setState(
                () => _draft = _draft.copyWith(ages: _toggle(_draft.ages, v))));
      case 6:
        return _checklistSection(ref.watch(furnitureUsagesProvider),
            selected: _draft.usages,
            onToggle: (v) => setState(() =>
                _draft = _draft.copyWith(usages: _toggle(_draft.usages, v))));
      case 7:
        return _checklistSection(ref.watch(furnitureRoomTypesProvider),
            selected: _draft.roomTypes,
            onToggle: (v) => setState(() => _draft =
                _draft.copyWith(roomTypes: _toggle(_draft.roomTypes, v))));
      case 8:
        return _checklistSection(ref.watch(furnitureItemShapesProvider),
            selected: _draft.itemShapes,
            onToggle: (v) => setState(() => _draft =
                _draft.copyWith(itemShapes: _toggle(_draft.itemShapes, v))));
      case 9:
        return _checklistSection(ref.watch(furnitureFillMaterialsProvider),
            selected: _draft.fillMaterials,
            onToggle: (v) => setState(() => _draft = _draft.copyWith(
                fillMaterials: _toggle(_draft.fillMaterials, v))));
      case 10:
        return _colorSection();
      case 11:
        return _checklistSection(ref.watch(furnitureShapesProvider),
            selected: _draft.shapes,
            onToggle: (v) => setState(() =>
                _draft = _draft.copyWith(shapes: _toggle(_draft.shapes, v))));
      case 12:
        return _checklistSection(ref.watch(furnitureTypesProvider),
            selected: _draft.types,
            onToggle: (v) => setState(
                () => _draft = _draft.copyWith(types: _toggle(_draft.types, v))));
      case 13:
        return _checklistSection(ref.watch(furnitureMaterialsProvider),
            selected: _draft.materials,
            onToggle: (v) => setState(() => _draft =
                _draft.copyWith(materials: _toggle(_draft.materials, v))));
      default:
        return const SizedBox();
    }
  }

  Widget _checklistSection(
    AsyncValue<List<String>> asyncItems, {
    required List<String> selected,
    required void Function(String) onToggle,
  }) {
    return asyncItems.when(
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
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.black45)),
            )
          : Column(
              children: items.map((item) {
                final isChecked = selected
                    .any((s) => s.toLowerCase() == item.toLowerCase());
                return _CheckRow(
                  label: item,
                  selected: isChecked,
                  onTap: () => onToggle(item),
                );
              }).toList(),
            ),
    );
  }

  Widget _brandSection() {
    return ref.watch(furnitureBrandsProvider).when(
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
      data: (brands) {
        final query = _brandSearch.text.toLowerCase();
        final filtered =
            brands.where((b) => b.toLowerCase().contains(query)).toList();
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _brandSearch,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.black38),
                prefixIcon:
                    const Icon(Icons.search, size: 18, color: Colors.black38),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text('No brands',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.black45)),
            )
          else
            ...filtered.map((b) {
              final isChecked = _draft.brands
                  .any((x) => x.toLowerCase() == b.toLowerCase());
              return _CheckRow(
                label: b,
                selected: isChecked,
                onTap: () => setState(() => _draft = _draft.copyWith(
                    brands: _toggle(_draft.brands, b))),
              );
            }),
        ]);
      },
    );
  }

  Widget _colorSection() {
    return ref.watch(furnitureColorsProvider).when(
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
      data: (colors) => Column(
        children: colors.map((c) {
          final isChecked =
              _draft.colors.any((x) => x.toLowerCase() == c.toLowerCase());
          final swatch = _colorSwatches[c];
          return InkWell(
            onTap: () => setState(() => _draft =
                _draft.copyWith(colors: _toggle(_draft.colors, c))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                    bottom: BorderSide(color: Color(0xFFE8E9EB), width: 1)),
              ),
              child: Row(children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isChecked ? _kBlue : Colors.white,
                    border: Border.all(
                        color: isChecked ? _kBlue : const Color(0xFFBBBBBB),
                        width: 1.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: isChecked
                      ? const Center(
                          child: Icon(Icons.check, size: 12, color: Colors.white))
                      : null,
                ),
                const SizedBox(width: 10),
                if (swatch != null) ...[
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: swatch,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFFDDDDDD), width: 1),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(c,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.black87)),
                ),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _priceSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Max Price',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _draft.maxPrice?.toStringAsFixed(0) ?? '',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Max price AFN',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: GoogleFonts.poppins(fontSize: 13),
            onChanged: (v) => setState(
                () => _draft = _draft.copyWith(maxPrice: double.tryParse(v))),
          ),
          const SizedBox(height: 16),
          Text('Min Price',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _draft.minPrice?.toStringAsFixed(0) ?? '',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Min price AFN',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: GoogleFonts.poppins(fontSize: 13),
            onChanged: (v) => setState(
                () => _draft = _draft.copyWith(minPrice: double.tryParse(v))),
          ),
        ],
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
