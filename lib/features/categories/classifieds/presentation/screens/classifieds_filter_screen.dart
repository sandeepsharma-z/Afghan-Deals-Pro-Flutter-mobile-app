import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/classifieds_provider.dart';

const _kBlue = Color(0xFF2258A8);

class ClassifiedsFilterScreen extends ConsumerStatefulWidget {
  final String subcategory;
  const ClassifiedsFilterScreen({super.key, required this.subcategory});

  @override
  ConsumerState<ClassifiedsFilterScreen> createState() =>
      _ClassifiedsFilterScreenState();
}

class _ClassifiedsFilterScreenState
    extends ConsumerState<ClassifiedsFilterScreen> {
  int _selectedSection = 0;
  late ClassifiedsFilter _draft;

  static const _sections = [
    ('Condition', Icons.check_circle_outline),
    ('Seller Type', Icons.person_outline),
    ('Age', Icons.schedule_outlined),
    ('Price Range', Icons.attach_money),
    ('Region', Icons.location_on_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _draft = ref.read(classifiedsFilterProvider);
  }

  bool _sectionHasValue(int index) {
    switch (index) {
      case 0:
        return _draft.conditions.isNotEmpty;
      case 1:
        return _draft.sellerTypes.isNotEmpty;
      case 2:
        return _draft.ages.isNotEmpty;
      case 3:
        return _draft.minPrice != null || _draft.maxPrice != null;
      case 4:
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
              setState(() => _draft = const ClassifiedsFilter());
              ref.read(classifiedsFilterProvider.notifier).state =
                  const ClassifiedsFilter();
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_sections.length, _buildLeftItem),
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

  Widget _buildLeftItem(int index) {
    final isActive = index == _selectedSection;
    final hasValue = _sectionHasValue(index);
    return InkWell(
      onTap: () => setState(() => _selectedSection = index),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: Color(0xFFE8E9EB), width: 1)),
        ),
        child: Row(
          children: [
            Icon(_sections[index].$2,
                size: 14, color: isActive ? _kBlue : const Color(0xFF7C7D88)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _sections[index].$1,
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
                ref.read(classifiedsFilterProvider.notifier).state = _draft;
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
          ref.watch(
              classifiedsConditionsBySubcategoryProvider(widget.subcategory)),
          selected: _draft.conditions,
          onToggle: (v) => setState(() => _draft =
              _draft.copyWith(conditions: _toggle(_draft.conditions, v))),
        );
      case 1:
        return _checklistSection(
          ref.watch(
              classifiedsSellerTypesBySubcategoryProvider(widget.subcategory)),
          selected: _draft.sellerTypes,
          onToggle: (v) => setState(() => _draft =
              _draft.copyWith(sellerTypes: _toggle(_draft.sellerTypes, v))),
        );
      case 2:
        return _checklistSection(
          ref.watch(classifiedsAgesBySubcategoryProvider(widget.subcategory)),
          selected: _draft.ages,
          onToggle: (v) => setState(
              () => _draft = _draft.copyWith(ages: _toggle(_draft.ages, v))),
        );
      case 3:
        return _priceSection();
      case 4:
        return _regionSection();
      default:
        return const SizedBox();
    }
  }

  Widget _checklistSection(AsyncValue<List<String>> async,
      {required List<String> selected,
      required void Function(String) onToggle}) {
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
                final checked =
                    selected.any((s) => s.toLowerCase() == item.toLowerCase());
                return _CheckRow(
                  label: item,
                  selected: checked,
                  onTap: () => onToggle(item),
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
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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

  List<String> _toggle(List<String> list, String value) {
    final lower = value.toLowerCase();
    if (list.any((e) => e.toLowerCase() == lower)) {
      return list.where((e) => e.toLowerCase() != lower).toList();
    }
    return [...list, value];
  }
}

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
