import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/spare_parts_provider.dart';
import 'spare_parts_results_screen.dart';

const _kBlue = Color(0xFF2258A8);

class SparePartsModelsScreen extends ConsumerStatefulWidget {
  final SparePartBrand brand;
  const SparePartsModelsScreen({super.key, required this.brand});

  @override
  ConsumerState<SparePartsModelsScreen> createState() =>
      _SparePartsModelsScreenState();
}

class _SparePartsModelsScreenState
    extends ConsumerState<SparePartsModelsScreen> {
  String _search = '';
  String? _selectedModel;
  int? _selectedYear;

  SparePartModelOption? _selectedModelOption(SparePartBrandMeta meta) {
    final selected = _selectedModel;
    if (selected == null || selected.trim().isEmpty) return null;
    for (final model in meta.models) {
      if (model.name.toLowerCase() == selected.toLowerCase()) return model;
    }
    return null;
  }

  int _effectiveMinYear(
      SparePartBrandMeta meta, SparePartModelOption? selectedModel) {
    return selectedModel?.minYear ?? meta.minYear;
  }

  int _effectiveMaxYear(
      SparePartBrandMeta meta, SparePartModelOption? selectedModel) {
    return selectedModel?.maxYear ?? meta.maxYear;
  }

  @override
  Widget build(BuildContext context) {
    final metaAsync = ref.watch(
      sparePartBrandMetaProvider(
        SparePartBrandMetaFilter(
          brandName: widget.brand.name,
          brandSlug: widget.brand.slug,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.brand.name,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () {},
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: _kBlue, width: 1),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_business_outlined,
                          size: 14, color: _kBlue),
                      const SizedBox(width: 5),
                      Text(
                        'Add Shop',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _kBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
        ),
      ),
      bottomNavigationBar: metaAsync.when(
        loading: () => const SizedBox(height: 70),
        error: (_, __) => const SizedBox(height: 70),
        data: (meta) {
          final selectedModel = _selectedModelOption(meta);
          final minYear = _effectiveMinYear(meta, selectedModel);
          final maxYear = _effectiveMaxYear(meta, selectedModel);
          var year = _selectedYear ?? maxYear;
          if (year < minYear) year = minYear;
          if (year > maxYear) year = maxYear;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SparePartsResultsScreen(
                          initialMake: widget.brand.name,
                          initialModel: _selectedModel,
                          fromYear: year,
                          toYear: year,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Apply For All',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      body: metaAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kBlue)),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: GoogleFonts.poppins(color: Colors.red, fontSize: 12),
          ),
        ),
        data: (meta) {
          final selectedModel = _selectedModelOption(meta);
          final minYear = _effectiveMinYear(meta, selectedModel);
          final maxYear = _effectiveMaxYear(meta, selectedModel);

          _selectedYear ??= maxYear;
          if (_selectedYear! < minYear) _selectedYear = minYear;
          if (_selectedYear! > maxYear) _selectedYear = maxYear;

          final filtered = _search.trim().isEmpty
              ? meta.models
              : meta.models
                  .where(
                    (m) => m.name
                        .toLowerCase()
                        .contains(_search.trim().toLowerCase()),
                  )
                  .toList();
          final topModels = filtered.take(7).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Model',
                  style: GoogleFonts.poppins(
                    fontSize: 30 / 2,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 14),
                _ModelSearchBox(
                  onChanged: (value) => setState(() => _search = value),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  itemCount: topModels.length + 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (_, i) {
                    if (i == topModels.length) {
                      return _ModelTile(
                        label: 'More',
                        selected: false,
                        onTap: () {},
                        child: const Icon(Icons.more_horiz,
                            size: 24, color: _kBlue),
                      );
                    }
                    final model = topModels[i];
                    final isSelected = _selectedModel == model.name;
                    return _ModelTile(
                      label: model.name,
                      selected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedModel = isSelected ? null : model.name;
                          final selected = isSelected ? null : model;
                          final newMin = _effectiveMinYear(meta, selected);
                          final newMax = _effectiveMaxYear(meta, selected);
                          var nextYear = _selectedYear ?? newMax;
                          if (nextYear < newMin) nextYear = newMin;
                          if (nextYear > newMax) nextYear = newMax;
                          _selectedYear = nextYear;
                        });
                      },
                      child: _ModelLogo(
                        iconUrl: model.iconUrl,
                        selected: isSelected,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Select Year',
                  style: GoogleFonts.poppins(
                    fontSize: 30 / 2,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 14),
                _SingleYearField(
                  value: _selectedYear ?? maxYear,
                  minYear: minYear,
                  maxYear: maxYear,
                  onChanged: (year) => setState(() => _selectedYear = year),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ModelSearchBox extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _ModelSearchBox({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 39,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFC2C2C2), width: 1),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Row(
        children: [
          const SizedBox(width: 11),
          const Icon(Icons.search, size: 15, color: Color(0xFF1E1E1E)),
          const SizedBox(width: 7),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                hintText: 'Search',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF1E1E1E),
                  fontWeight: FontWeight.w400,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _ModelTile extends StatelessWidget {
  final String label;
  final bool selected;
  final Widget child;
  final VoidCallback onTap;

  const _ModelTile({
    required this.label,
    required this.selected,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: _kBlue, width: selected ? 2 : 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: child),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11.6,
              color: Colors.black87,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelLogo extends StatelessWidget {
  final String? iconUrl;
  final bool selected;
  const _ModelLogo({required this.iconUrl, required this.selected});

  @override
  Widget build(BuildContext context) {
    final url = iconUrl;

    if (url == null || url.isEmpty) {
      return Icon(
        Icons.directions_car_outlined,
        color: selected ? _kBlue : const Color(0xFF2258A8),
        size: 22,
      );
    }

    if (url.toLowerCase().contains('.svg')) {
      return SvgPicture.network(
        url,
        width: 26,
        height: 26,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => Icon(
          Icons.directions_car_outlined,
          color: selected ? _kBlue : const Color(0xFF2258A8),
          size: 22,
        ),
      );
    }

    return Image.network(
      url,
      width: 26,
      height: 26,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.directions_car_outlined,
        color: selected ? _kBlue : const Color(0xFF2258A8),
        size: 22,
      ),
    );
  }
}

class _SingleYearField extends StatelessWidget {
  final int value;
  final int minYear;
  final int maxYear;
  final ValueChanged<int> onChanged;

  const _SingleYearField({
    required this.value,
    required this.minYear,
    required this.maxYear,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDialog<int>(
          context: context,
          builder: (_) => _YearPickerDialog(
            initial: value,
            minYear: minYear,
            maxYear: maxYear,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFC4C4C4), width: 1.26),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                value.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 24 / 2,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF0B4CB4),
                ),
              ),
            ),
            SvgPicture.asset(
              'assets/images/calendar_icon.svg',
              width: 22,
              height: 22,
            ),
          ],
        ),
      ),
    );
  }
}

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
    final startYear =
        widget.minYear <= widget.maxYear ? widget.minYear : widget.maxYear;
    final endYear =
        widget.maxYear >= widget.minYear ? widget.maxYear : widget.minYear;
    final years = List.generate(endYear - startYear + 1, (i) => startYear + i);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Select Year',
        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 240,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.6,
          ),
          itemCount: years.length,
          itemBuilder: (_, i) {
            final y = years[i];
            final active = y == _selected;
            final inRange = y >= widget.minYear && y <= widget.maxYear;
            return GestureDetector(
              onTap: () => setState(() => _selected = y),
              child: Container(
                decoration: BoxDecoration(
                  color: active ? _kBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: active
                        ? _kBlue
                        : inRange
                            ? const Color(0xFF2258A8).withValues(alpha: 0.4)
                            : const Color(0xFFDDDDDD),
                  ),
                ),
                child: Center(
                  child: Text(
                    y.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: active
                          ? Colors.white
                          : inRange
                              ? _kBlue
                              : Colors.black54,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(color: Colors.black54),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: Text(
            'OK',
            style: GoogleFonts.poppins(
              color: _kBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
