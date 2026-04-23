import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/brand_listings_provider.dart';
import 'brand_results_screen.dart';

const _kBlue = Color(0xFF2258A8);

class BrandModelsScreen extends ConsumerStatefulWidget {
  final String brand;
  final String subcategory;
  const BrandModelsScreen({
    super.key,
    required this.brand,
    required this.subcategory,
  });

  @override
  ConsumerState<BrandModelsScreen> createState() => _BrandModelsScreenState();
}

class _BrandModelsScreenState extends ConsumerState<BrandModelsScreen> {
  String _search = '';
  String? _selectedModel;
  int? _fromYear;
  int? _toYear;
  String _selectedSort = 'Popular';

  static const _sortOptions = [
    'Popular',
    'Verified',
    'Newest to Oldest',
    'Oldest to Newest',
    'Price Highest to Lowest',
    'Price Lowest to Highest',
  ];

  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCFCFCF),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Sort',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(color: Color(0xFFE8E9EB), width: 1)),
                ),
                child: Column(
                  children: _sortOptions.map((item) {
                    final selected = item == _selectedSort;
                    return InkWell(
                      onTap: () {
                        setState(() => _selectedSort = item);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: Color(0xFFE8E9EB), width: 1)),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(item,
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87)),
                            ),
                            if (selected)
                              const Icon(Icons.check,
                                  color: _kBlue, size: 20),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final metaAsync = ref.watch(
      brandMetaProvider(
        BrandMetaFilter(brand: widget.brand, subcategory: widget.subcategory),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back_ios_new,
              size: 16, color: Colors.black87),
        ),
        title: Text(
          widget.brand,
          style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune, color: Colors.black87, size: 20),
          ),
          IconButton(
            onPressed: _openSortSheet,
            icon: SvgPicture.asset('assets/icons/bars_sort.svg', width: 20, height: 20),
          ),
          const SizedBox(width: 2),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
        ),
      ),
      bottomNavigationBar: metaAsync.when(
        data: (meta) => _buildApplyButton(context, meta),
        loading: () => const SizedBox(height: 70),
        error: (_, __) => _buildApplyButton(context, null),
      ),
      body: metaAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kBlue)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.red))),
        data: (meta) {
          // Initialize year pickers from actual data on first load
          _fromYear ??= meta.minYear;
          _toYear ??= meta.maxYear;

          final filtered = _search.isEmpty
              ? meta.models
              : meta.models
                  .where((m) =>
                      m.toLowerCase().contains(_search.toLowerCase()))
                  .toList();
          final allItems = [...filtered, 'More'];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Select Model ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Select Model',
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSearchBar(),
                ),
                const SizedBox(height: 16),
                if (meta.models.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Text(
                      'No models found for ${widget.brand}',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.black45),
                    ),
                  )
                else
                  _buildModelsGrid(allItems, meta),
                const SizedBox(height: 28),

                // ── Select Year ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Select Year',
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildYearPickers(meta),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFC2C2C2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, size: 16, color: Colors.black87),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (_search.isEmpty)
                  IgnorePointer(
                    child: Text('Search',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildModelsGrid(List<String> items, BrandMeta meta) {
    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += 4) {
      final rowItems =
          items.sublist(i, (i + 4).clamp(0, items.length)).toList();
      while (rowItems.length < 4) {
        rowItems.add('');
      }
      rows.add(
        Row(
          children: rowItems.map((name) {
            if (name.isEmpty) return const Expanded(child: SizedBox());
            final isMore = name == 'More';
            final isSelected = !isMore && _selectedModel == name;
            final iconUrl = isMore ? null : meta.iconForModel(name);
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (!isMore) {
                    setState(() => _selectedModel =
                        _selectedModel == name ? null : name);
                  }
                },
                child: Column(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? _kBlue.withValues(alpha: 0.08)
                            : Colors.white,
                        border: Border.all(
                          color: _kBlue,
                          width: isSelected ? 2.5 : 1.5,
                        ),
                      ),
                      child: Center(
                        child: isMore
                            ? const Icon(Icons.more_horiz,
                                color: _kBlue, size: 22)
                            : Padding(
                                padding: const EdgeInsets.all(3),
                                child: _buildModelIcon(
                                  iconUrl: iconUrl,
                                  isSelected: isSelected,
                                  size: 42,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected ? _kBlue : Colors.black87),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );
      if (i + 4 < items.length) rows.add(const SizedBox(height: 24));
    }
    return Column(children: rows);
  }

  Widget _buildModelIcon({
    required String? iconUrl,
    required bool isSelected,
    required double size,
  }) {
    final fallbackColor = isSelected ? _kBlue : const Color(0xFF6B8FC7);
    if (iconUrl == null || iconUrl.isEmpty) {
      return Icon(Icons.directions_car_outlined, color: fallbackColor, size: size);
    }
    final lower = iconUrl.toLowerCase();
    if (lower.contains('.svg')) {
      return SvgPicture.network(
        iconUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(fallbackColor, BlendMode.srcIn),
        placeholderBuilder: (_) => Icon(Icons.directions_car_outlined, color: fallbackColor, size: size),
      );
    }
    return Image.network(
      iconUrl,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(Icons.directions_car_outlined, color: fallbackColor, size: size),
    );
  }

  Widget _buildYearPickers(BrandMeta meta) {
    final from = _fromYear ?? meta.minYear;
    final to = _toYear ?? meta.maxYear;
    return Row(
      children: [
        Expanded(
            child: _yearField('From', from,
                (y) => setState(() => _fromYear = y), meta)),
        const SizedBox(width: 12),
        Expanded(
            child:
                _yearField('To', to, (y) => setState(() => _toYear = y), meta)),
      ],
    );
  }

  Widget _yearField(
      String label, int value, ValueChanged<int> onChanged, BrandMeta meta) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDialog<int>(
          context: context,
          builder: (_) => _YearPickerDialog(
            initial: value,
            minYear: meta.minYear,
            maxYear: meta.maxYear,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFC4C4C4), width: 1.26),
              borderRadius: BorderRadius.circular(8),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(value.toString(),
                      style: GoogleFonts.poppins(
                          fontSize: 14.63,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87)),
                ),
                SvgPicture.asset(
                  'assets/images/calendar_icon.svg',
                  width: 22,
                  height: 22,
                ),
              ],
            ),
          ),
          Positioned(
            top: -7,
            left: 10,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.black45,
                      height: 1.1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton(BuildContext context, BrandMeta? meta) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: meta == null
                ? null
                : () {
                    final from = _fromYear ?? meta.minYear;
                    final to = _toYear ?? meta.maxYear;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BrandResultsScreen(
                          subcategory: widget.subcategory,
                          brand: widget.brand,
                          model: _selectedModel,
                          fromYear: from,
                          toYear: to,
                        ),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBlue,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              _selectedModel != null
                  ? 'Show $_selectedModel Results'
                  : 'Show All Results',
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Year Picker Dialog ────────────────────────────────────────────────────────
class _YearPickerDialog extends StatefulWidget {
  final int initial;
  final int minYear;
  final int maxYear;
  const _YearPickerDialog(
      {required this.initial, required this.minYear, required this.maxYear});

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
    // Show a range spanning 5 years before minYear to current+2
    final startYear = (widget.minYear - 5).clamp(1990, widget.minYear);
    final endYear = DateTime.now().year + 2;
    final years = List.generate(endYear - startYear + 1, (i) => startYear + i);

    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text('Select Year',
          style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: double.maxFinite,
        height: 240,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.6),
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
                              : const Color(0xFFDDDDDD)),
                ),
                child: Center(
                  child: Text(y.toString(),
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: active
                              ? Colors.white
                              : inRange
                                  ? _kBlue
                                  : Colors.black54)),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: GoogleFonts.poppins(color: Colors.black54)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: Text('OK',
              style: GoogleFonts.poppins(
                  color: _kBlue, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
