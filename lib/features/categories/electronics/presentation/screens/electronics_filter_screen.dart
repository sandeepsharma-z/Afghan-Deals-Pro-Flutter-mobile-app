import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/electronics_provider.dart';

const _kBlue = Color(0xFF2258A8);

class ElectronicsFilterScreen extends ConsumerStatefulWidget {
  final String subcategory;
  const ElectronicsFilterScreen({super.key, required this.subcategory});

  @override
  ConsumerState<ElectronicsFilterScreen> createState() => _ElectronicsFilterScreenState();
}

class _ElectronicsFilterScreenState extends ConsumerState<ElectronicsFilterScreen> {
  int _selectedSection = 0;

  final _sections = const [
    'Brand', 'Model', 'Condition', 'Price Range', 'Seller Type', 'Age', 'Warranty', 'Region',
  ];

  late ElectronicsFilter _draft;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(electronicsFilterProvider);
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
        title: Text('Filter', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _draft = const ElectronicsFilter());
              ref.read(electronicsFilterProvider.notifier).state = const ElectronicsFilter();
            },
            child: Text('Clear All', style: GoogleFonts.poppins(fontSize: 13, color: _kBlue)),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              ref.read(electronicsFilterProvider.notifier).state = _draft;
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text('Apply', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ),
      body: Row(
        children: [
          // Left section list
          Container(
            width: 130,
            decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFFE8E8E8)))),
            child: ListView.builder(
              itemCount: _sections.length,
              itemBuilder: (_, i) {
                final isSelected = i == _selectedSection;
                final hasValue = _sectionHasValue(i);
                return GestureDetector(
                  onTap: () => setState(() => _selectedSection = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      border: const Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
                      color: isSelected ? Colors.white : const Color(0xFFF8F8F8),
                    ),
                    child: Row(children: [
                      Expanded(child: Text(_sections[i],
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: isSelected ? _kBlue : Colors.black87))),
                      if (hasValue)
                        Container(
                          width: 8, height: 8,
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
      case 0: return _draft.brands.isNotEmpty;
      case 1: return _draft.models.isNotEmpty;
      case 2: return _draft.conditions.isNotEmpty;
      case 3: return _draft.minPrice != null || _draft.maxPrice != null;
      case 4: return _draft.sellerTypes.isNotEmpty;
      case 5: return _draft.ages.isNotEmpty;
      case 6: return _draft.warranties.isNotEmpty;
      case 7: return _draft.region.isNotEmpty;
      default: return false;
    }
  }

  Widget _buildSectionContent() {
    switch (_selectedSection) {
      case 0: return _checklistSection(ref.watch(electronicsBrandsProvider),
          selected: _draft.brands,
          onToggle: (v) => setState(() => _draft = _draft.copyWith(brands: _toggle(_draft.brands, v))));
      case 1: return _checklistSection(ref.watch(electronicsModelsProvider(_draft.brands.isNotEmpty ? _draft.brands.first : '')),
          selected: _draft.models,
          onToggle: (v) => setState(() => _draft = _draft.copyWith(models: _toggle(_draft.models, v))));
      case 2: return _checklistSection(ref.watch(electronicsConditionsProvider),
          selected: _draft.conditions,
          onToggle: (v) => setState(() => _draft = _draft.copyWith(conditions: _toggle(_draft.conditions, v))));
      case 3: return _priceSection();
      case 4: return _checklistSection(ref.watch(electronicsSellerTypesProvider),
          selected: _draft.sellerTypes,
          onToggle: (v) => setState(() => _draft = _draft.copyWith(sellerTypes: _toggle(_draft.sellerTypes, v))));
      case 5: return _checklistSection(ref.watch(electronicsAgesProvider),
          selected: _draft.ages,
          onToggle: (v) => setState(() => _draft = _draft.copyWith(ages: _toggle(_draft.ages, v))));
      case 6: return _checklistSection(ref.watch(electronicsWarrantiesProvider),
          selected: _draft.warranties,
          onToggle: (v) => setState(() => _draft = _draft.copyWith(warranties: _toggle(_draft.warranties, v))));
      case 7: return _regionSection();
      default: return const SizedBox();
    }
  }

  Widget _checklistSection(AsyncValue<List<String>> async, {required List<String> selected, required void Function(String) onToggle}) {
    return async.when(
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
                      Container(
                        width: 18, height: 18,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: isChecked ? _kBlue : const Color(0xFFCCCCCC), width: 1.5),
                          color: isChecked ? _kBlue : Colors.white,
                        ),
                        child: isChecked
                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(items[i], style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87))),
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

  Widget _regionSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextFormField(
        initialValue: _draft.region,
        decoration: InputDecoration(
          hintText: 'Search region / city',
          prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        style: GoogleFonts.poppins(fontSize: 13),
        onChanged: (v) => setState(() => _draft = _draft.copyWith(region: v)),
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
