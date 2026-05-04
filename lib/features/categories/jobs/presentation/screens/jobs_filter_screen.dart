import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/jobs_provider.dart';

const _kBlue = Color(0xFF2258A8);

class JobsFilterScreen extends ConsumerStatefulWidget {
  final String subcategory;
  const JobsFilterScreen({super.key, required this.subcategory});

  @override
  ConsumerState<JobsFilterScreen> createState() => _JobsFilterScreenState();
}

class _JobsFilterScreenState extends ConsumerState<JobsFilterScreen> {
  int _selectedSection = 0;

  static const _kSections = [
    ('Job Category', Icons.category_outlined),
    ('Job Type', Icons.work_outline),
    ('Experience', Icons.trending_up),
    ('Salary Range', Icons.attach_money),
    ('Industry', Icons.business),
    ('Education', Icons.school),
    ('Seller Type', Icons.person_outline),
    ('Region', Icons.location_on_outlined),
  ];

  late JobsFilter _draft;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(jobsFilterProvider);
  }

  bool _sectionHasValue(int i) {
    switch (i) {
      case 0:
        return _draft.jobCategories.isNotEmpty;
      case 1:
        return _draft.jobTypes.isNotEmpty;
      case 2:
        return _draft.experiences.isNotEmpty;
      case 3:
        return _draft.minSalary != null || _draft.maxSalary != null;
      case 4:
        return _draft.industries.isNotEmpty;
      case 5:
        return _draft.educations.isNotEmpty;
      case 6:
        return _draft.sellerTypes.isNotEmpty;
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
          onPressed: () => context.pop(),
        ),
        title: Text('Filter',
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _draft = const JobsFilter());
              ref.read(jobsFilterProvider.notifier).state = const JobsFilter();
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
                ref.read(jobsFilterProvider.notifier).state = _draft;
                context.pop();
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
          ref.watch(jobsCategoriesBySubcategoryProvider(widget.subcategory)),
          selected: _draft.jobCategories,
          onToggle: (v) => setState(() => _draft =
              _draft.copyWith(jobCategories: _toggle(_draft.jobCategories, v))),
        );
      case 1:
        return _checklistSection(
            ref.watch(jobsTypesBySubcategoryProvider(widget.subcategory)),
            selected: _draft.jobTypes,
            onToggle: (v) => setState(() => _draft =
                _draft.copyWith(jobTypes: _toggle(_draft.jobTypes, v))));
      case 2:
        return _checklistSection(
            ref.watch(jobsExperiencesBySubcategoryProvider(widget.subcategory)),
            selected: _draft.experiences,
            onToggle: (v) => setState(() => _draft =
                _draft.copyWith(experiences: _toggle(_draft.experiences, v))));
      case 3:
        return _salarySection();
      case 4:
        return _checklistSection(
            ref.watch(jobsIndustriesBySubcategoryProvider(widget.subcategory)),
            selected: _draft.industries,
            onToggle: (v) => setState(() => _draft =
                _draft.copyWith(industries: _toggle(_draft.industries, v))));
      case 5:
        return _checklistSection(
            ref.watch(jobsEducationsBySubcategoryProvider(widget.subcategory)),
            selected: _draft.educations,
            onToggle: (v) => setState(() => _draft =
                _draft.copyWith(educations: _toggle(_draft.educations, v))));
      case 6:
        return _checklistSection(
            ref.watch(jobsSellerTypesBySubcategoryProvider(widget.subcategory)),
            selected: _draft.sellerTypes,
            onToggle: (v) => setState(() => _draft =
                _draft.copyWith(sellerTypes: _toggle(_draft.sellerTypes, v))));
      case 7:
        return _regionSection();
      default:
        return const SizedBox();
    }
  }

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

  Widget _salarySection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Max Salary',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _draft.maxSalary?.toStringAsFixed(0) ?? '',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Max salary AFN',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFFD9D9D9), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _kBlue, width: 1),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: GoogleFonts.poppins(fontSize: 13),
            onChanged: (v) => setState(
                () => _draft = _draft.copyWith(maxSalary: double.tryParse(v))),
          ),
          const SizedBox(height: 16),
          Text('Min Salary',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _draft.minSalary?.toStringAsFixed(0) ?? '',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Min salary AFN',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFFD9D9D9), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _kBlue, width: 1),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: GoogleFonts.poppins(fontSize: 13),
            onChanged: (v) => setState(
                () => _draft = _draft.copyWith(minSalary: double.tryParse(v))),
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
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD9D9D9), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _kBlue, width: 1),
          ),
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
