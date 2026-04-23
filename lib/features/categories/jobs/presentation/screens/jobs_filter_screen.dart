import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  final _sections = const [
    ('Job Category',  Icons.category_outlined),
    ('Job Type',      Icons.work_outline),
    ('Experience',    Icons.trending_up_outlined),
    ('Salary Range',  Icons.attach_money),
    ('Industry',      Icons.business_outlined),
    ('Education',     Icons.school_outlined),
    ('Seller Type',   Icons.person_outline),
    ('Region',        Icons.location_on_outlined),
  ];

  late JobsFilter _draft;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(jobsFilterProvider);
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
              setState(() => _draft = const JobsFilter());
              ref.read(jobsFilterProvider.notifier).state = const JobsFilter();
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
              ref.read(jobsFilterProvider.notifier).state = _draft;
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
      case 0: return _draft.jobCategories.isNotEmpty;
      case 1: return _draft.jobTypes.isNotEmpty;
      case 2: return _draft.experiences.isNotEmpty;
      case 3: return _draft.minSalary != null || _draft.maxSalary != null;
      case 4: return _draft.industries.isNotEmpty;
      case 5: return _draft.educations.isNotEmpty;
      case 6: return _draft.sellerTypes.isNotEmpty;
      case 7: return _draft.region.isNotEmpty;
      default: return false;
    }
  }

  Widget _buildSectionContent() {
    switch (_selectedSection) {
      case 0:
        return _checklistSection(
          ref.watch(jobsSubcategoriesProvider).when(
            loading: () => const AsyncValue.loading(),
            error: (e, s) => AsyncValue.error(e, s),
            data: (subs) => AsyncValue.data(subs.map((s) => s.name).toList()),
          ),
          selected: _draft.jobCategories,
          onToggle: (v) => setState(() => _draft =
              _draft.copyWith(jobCategories: _toggle(_draft.jobCategories, v))),
        );
      case 1:
        return _checklistSection(ref.watch(jobsTypesProvider),
            selected: _draft.jobTypes,
            onToggle: (v) => setState(() =>
                _draft = _draft.copyWith(jobTypes: _toggle(_draft.jobTypes, v))));
      case 2:
        return _checklistSection(ref.watch(jobsExperiencesProvider),
            selected: _draft.experiences,
            onToggle: (v) => setState(() =>
                _draft = _draft.copyWith(experiences: _toggle(_draft.experiences, v))));
      case 3:
        return _salarySection();
      case 4:
        return _checklistSection(ref.watch(jobsIndustriesProvider),
            selected: _draft.industries,
            onToggle: (v) => setState(() =>
                _draft = _draft.copyWith(industries: _toggle(_draft.industries, v))));
      case 5:
        return _checklistSection(ref.watch(jobsEducationsProvider),
            selected: _draft.educations,
            onToggle: (v) => setState(() =>
                _draft = _draft.copyWith(educations: _toggle(_draft.educations, v))));
      case 6:
        return _checklistSection(ref.watch(jobsSellerTypesProvider),
            selected: _draft.sellerTypes,
            onToggle: (v) => setState(() =>
                _draft = _draft.copyWith(sellerTypes: _toggle(_draft.sellerTypes, v))));
      case 7:
        return _regionSection();
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
                final isChecked =
                    selected.any((s) => s.toLowerCase() == items[i].toLowerCase());
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

  Widget _salarySection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Max Salary', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _draft.maxSalary?.toStringAsFixed(0) ?? '',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Max salary AFN',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: GoogleFonts.poppins(fontSize: 13),
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(maxSalary: double.tryParse(v))),
          ),
          const SizedBox(height: 16),
          Text('Min Salary', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _draft.minSalary?.toStringAsFixed(0) ?? '',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Min salary AFN',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: GoogleFonts.poppins(fontSize: 13),
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(minSalary: double.tryParse(v))),
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
