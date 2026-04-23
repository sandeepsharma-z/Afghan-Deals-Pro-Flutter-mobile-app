import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/furniture_provider.dart';

const _kBlue = Color(0xFF2258A8);

const _colorSwatches = <String, Color>{
  'White': Color(0xFFF5F5F5),
  'Silver': Color(0xFFC0C0C0),
  'Grey': Color(0xFF808080),
  'Black': Color(0xFF1A1A1A),
  'Red': Color(0xFFE53935),
  'Gold': Color(0xFFFFD700),
  'Orange': Color(0xFFFF7043),
  'Blue': Color(0xFF1565C0),
  'Beige': Color(0xFFF5F0DC),
  'Yellow': Color(0xFFFFEB3B),
  'Purple': Color(0xFF7B1FA2),
  'Cement': Color(0xFF8B8682),
  'Burgundy': Color(0xFF800020),
  'Green': Color(0xFF2E7D32),
  'Brown': Color(0xFF6D4C41),
};

class FurnitureFilterScreen extends ConsumerStatefulWidget {
  final String subcategory;
  const FurnitureFilterScreen({super.key, required this.subcategory});

  @override
  ConsumerState<FurnitureFilterScreen> createState() => _FurnitureFilterScreenState();
}

class _FurnitureFilterScreenState extends ConsumerState<FurnitureFilterScreen> {
  int _selectedSection = 0;

  final _sections = const [
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
        ),
        title: Text('Filter',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _draft = const FurnitureFilter());
              ref.read(furnitureFilterProvider.notifier).state = const FurnitureFilter();
            },
            child: Text('Clear All',
                style: GoogleFonts.poppins(fontSize: 13, color: _kBlue)),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              ref.read(furnitureFilterProvider.notifier).state = _draft;
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text('Apply',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ),
      body: Row(
        children: [
          // Left sidebar
          Container(
            width: 135,
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Color(0xFFE8E8E8))),
            ),
            child: ListView.builder(
              itemCount: _sections.length,
              itemBuilder: (_, i) {
                final isSelected = i == _selectedSection;
                final hasValue = _sectionHasValue(i);
                return GestureDetector(
                  onTap: () => setState(() => _selectedSection = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
                    decoration: BoxDecoration(
                      border: const Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
                      color: isSelected ? Colors.white : const Color(0xFFF8F8F8),
                    ),
                    child: Row(children: [
                      Icon(_sections[i].$2,
                          size: 15,
                          color: isSelected ? _kBlue : Colors.black45),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(_sections[i].$1,
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: isSelected ? _kBlue : Colors.black87)),
                      ),
                      if (hasValue)
                        Container(
                          width: 7, height: 7,
                          decoration: const BoxDecoration(color: _kBlue, shape: BoxShape.circle),
                        ),
                    ]),
                  ),
                );
              },
            ),
          ),
          // Right content
          Expanded(child: _buildSectionContent()),
        ],
      ),
    );
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

  Widget _buildSectionContent() {
    switch (_selectedSection) {
      case 0: // Furniture subcategory
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
      case 1: // Brand with search
        return _brandSection();
      case 2:
        return _checklistSection(ref.watch(furnitureConditionsProvider),
            selected: _draft.conditions,
            onToggle: (v) => setState(() => _draft = _draft.copyWith(conditions: _toggle(_draft.conditions, v))));
      case 3:
        return _priceSection();
      case 4:
        return _checklistSection(ref.watch(furnitureSellerTypesProvider),
            selected: _draft.sellerTypes,
            onToggle: (v) => setState(() => _draft = _draft.copyWith(sellerTypes: _toggle(_draft.sellerTypes, v))));
      case 5:
        return _checklistSection(ref.watch(furnitureAgesProvider),
            selected: _draft.ages,
            onToggle: (v) => setState(() => _draft = _draft.copyWith(ages: _toggle(_draft.ages, v))));
      case 6:
        return _checklistSection(ref.watch(furnitureUsagesProvider),
            selected: _draft.usages,
            onToggle: (v) => setState(() => _draft = _draft.copyWith(usages: _toggle(_draft.usages, v))));
      case 7:
        return _checklistSection(ref.watch(furnitureRoomTypesProvider),
            selected: _draft.roomTypes,
            onToggle: (v) => setState(() => _draft = _draft.copyWith(roomTypes: _toggle(_draft.roomTypes, v))));
      case 8:
        return _checklistSection(ref.watch(furnitureItemShapesProvider),
            selected: _draft.itemShapes,
            onToggle: (v) => setState(() => _draft = _draft.copyWith(itemShapes: _toggle(_draft.itemShapes, v))));
      case 9:
        return _checklistSection(ref.watch(furnitureFillMaterialsProvider),
            selected: _draft.fillMaterials,
            onToggle: (v) => setState(() => _draft = _draft.copyWith(fillMaterials: _toggle(_draft.fillMaterials, v))));
      case 10:
        return _colorSection();
      case 11:
        return _checklistSection(ref.watch(furnitureShapesProvider),
            selected: _draft.shapes,
            onToggle: (v) => setState(() => _draft = _draft.copyWith(shapes: _toggle(_draft.shapes, v))));
      case 12:
        return _checklistSection(ref.watch(furnitureTypesProvider),
            selected: _draft.types,
            onToggle: (v) => setState(() => _draft = _draft.copyWith(types: _toggle(_draft.types, v))));
      case 13:
        return _checklistSection(ref.watch(furnitureMaterialsProvider),
            selected: _draft.materials,
            onToggle: (v) => setState(() => _draft = _draft.copyWith(materials: _toggle(_draft.materials, v))));
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
      loading: () => const Center(child: CircularProgressIndicator(color: _kBlue)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) => items.isEmpty
          ? Center(child: Text('No options', style: GoogleFonts.poppins(color: Colors.black45)))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
              itemBuilder: (_, i) {
                final isChecked = selected.any((s) => s.toLowerCase() == items[i].toLowerCase());
                return InkWell(
                  onTap: () => onToggle(items[i]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(children: [
                      _checkbox(isChecked),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(items[i],
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87)),
                      ),
                    ]),
                  ),
                );
              },
            ),
    );
  }

  Widget _brandSection() {
    return ref.watch(furnitureBrandsProvider).when(
      loading: () => const Center(child: CircularProgressIndicator(color: _kBlue)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (brands) {
        final query = _brandSearch.text.toLowerCase();
        final filtered = brands.where((b) => b.toLowerCase().contains(query)).toList();
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _brandSearch,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.black38),
                prefixIcon: const Icon(Icons.search, size: 18, color: Colors.black38),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text('No brands', style: GoogleFonts.poppins(color: Colors.black45)))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
                    itemBuilder: (_, i) {
                      final isChecked = _draft.brands.any(
                          (b) => b.toLowerCase() == filtered[i].toLowerCase());
                      return InkWell(
                        onTap: () => setState(() => _draft = _draft.copyWith(
                            brands: _toggle(_draft.brands, filtered[i]))),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(children: [
                            _checkbox(isChecked),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(filtered[i],
                                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87)),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ]);
      },
    );
  }

  Widget _colorSection() {
    return ref.watch(furnitureColorsProvider).when(
      loading: () => const Center(child: CircularProgressIndicator(color: _kBlue)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (colors) => ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: colors.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
        itemBuilder: (_, i) {
          final isChecked = _draft.colors.any((c) => c.toLowerCase() == colors[i].toLowerCase());
          final swatch = _colorSwatches[colors[i]];
          return InkWell(
            onTap: () => setState(() =>
                _draft = _draft.copyWith(colors: _toggle(_draft.colors, colors[i]))),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                _checkbox(isChecked),
                const SizedBox(width: 12),
                if (swatch != null) ...[
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: swatch,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(colors[i],
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87)),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _priceSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Max Price', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _draft.maxPrice?.toStringAsFixed(0) ?? '',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Max price AFN',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: GoogleFonts.poppins(fontSize: 13),
            onChanged: (v) => setState(() => _draft = _draft.copyWith(maxPrice: double.tryParse(v))),
          ),
          const SizedBox(height: 16),
          Text('Min Price', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _draft.minPrice?.toStringAsFixed(0) ?? '',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Min price AFN',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: GoogleFonts.poppins(fontSize: 13),
            onChanged: (v) => setState(() => _draft = _draft.copyWith(minPrice: double.tryParse(v))),
          ),
        ],
      ),
    );
  }

  Widget _checkbox(bool isChecked) {
    return Container(
      width: 18, height: 18,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: isChecked ? _kBlue : const Color(0xFFCCCCCC), width: 1.5),
        color: isChecked ? _kBlue : Colors.white,
      ),
      child: isChecked ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
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
