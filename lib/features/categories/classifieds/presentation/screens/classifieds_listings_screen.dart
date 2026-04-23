import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/classifieds_provider.dart';
import '../../../../../features/listings/data/models/classified_listing_model.dart';
import 'classifieds_detail_screen.dart';

const _kBlue = Color(0xFF2258A8);

class ClassifiedsListingsScreen extends ConsumerStatefulWidget {
  final String subcategory;
  final String subcategoryLabel;
  const ClassifiedsListingsScreen({
    super.key,
    required this.subcategory,
    required this.subcategoryLabel,
  });

  @override
  ConsumerState<ClassifiedsListingsScreen> createState() =>
      _ClassifiedsListingsScreenState();
}

class _ClassifiedsListingsScreenState
    extends ConsumerState<ClassifiedsListingsScreen> {
  @override
  Widget build(BuildContext context) {
    final listingsAsync =
        ref.watch(classifiedsFilteredProvider(widget.subcategory));
    final filter = ref.watch(classifiedsFilterProvider);
    final hasFilter = !filter.isEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: Colors.black87),
        ),
        title: Text(
          widget.subcategoryLabel.isEmpty
              ? 'All Classifieds'
              : widget.subcategoryLabel,
          style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: Stack(children: [
              const Icon(Icons.tune, color: Colors.black87),
              if (hasFilter)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: _kBlue, shape: BoxShape.circle),
                  ),
                ),
            ]),
            onPressed: () => _showFilterSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.sort, color: Colors.black87),
            onPressed: () => _showSortSheet(context),
          ),
        ],
      ),
      body: listingsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kBlue)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) => items.isEmpty
            ? Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    const Icon(Icons.grid_view_outlined,
                        size: 64, color: Colors.black26),
                    const SizedBox(height: 12),
                    Text('No listings found',
                        style: GoogleFonts.poppins(
                            fontSize: 15, color: Colors.black45)),
                  ]))
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 218,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        ClassifiedsDetailScreen(item: items[i]),
                  )),
                  child: _ClassifiedCard(item: items[i]),
                ),
              ),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    final filter = ref.read(classifiedsFilterProvider);
    final options = [
      ('Newest to Oldest', 'newest'),
      ('Oldest to Newest', 'oldest'),
      ('Price Highest to Lowest', 'price_high'),
      ('Price Lowest to Highest', 'price_low'),
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('Sort',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          ...options.map((opt) => ListTile(
                title: Text(opt.$1,
                    style: GoogleFonts.poppins(fontSize: 14)),
                trailing: filter.sortBy == opt.$2
                    ? const Icon(Icons.check, color: _kBlue)
                    : null,
                onTap: () {
                  ref.read(classifiedsFilterProvider.notifier).state =
                      filter.copyWith(sortBy: opt.$2);
                  Navigator.of(context).pop();
                },
              )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final filter = ref.read(classifiedsFilterProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _FilterSheet(filter: filter, onApply: (f) {
        ref.read(classifiedsFilterProvider.notifier).state = f;
      }),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final ClassifiedsFilter filter;
  final void Function(ClassifiedsFilter) onApply;
  const _FilterSheet({required this.filter, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late ClassifiedsFilter _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.filter;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Text('Filter',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _draft = const ClassifiedsFilter()),
                child: Text('Clear All',
                    style: GoogleFonts.poppins(fontSize: 13, color: _kBlue)),
              ),
            ]),
          ),
          const Divider(height: 1),
          _filterRow('Condition', ['Flawless', 'Excellent', 'Good', 'Average', 'Poor'],
              _draft.conditions,
              (v) => setState(() => _draft = _draft.copyWith(
                  conditions: _toggle(_draft.conditions, v)))),
          _filterRow('Seller Type', ['All Sellers', 'Individuals', 'Businesses'],
              _draft.sellerTypes,
              (v) => setState(() => _draft = _draft.copyWith(
                  sellerTypes: _toggle(_draft.sellerTypes, v)))),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_draft);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Apply',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _filterRow(String label, List<String> options,
      List<String> selected, void Function(String) onToggle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: options.map((opt) {
            final isSelected =
                selected.any((s) => s.toLowerCase() == opt.toLowerCase());
            return GestureDetector(
              onTap: () => onToggle(opt),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? _kBlue : Colors.white,
                  border: Border.all(
                      color: isSelected
                          ? _kBlue
                          : const Color(0xFFDDDDDD)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(opt,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isSelected
                            ? Colors.white
                            : Colors.black87)),
              ),
            );
          }).toList(),
        ),
      ]),
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

class _ClassifiedCard extends StatelessWidget {
  final ClassifiedListingModel item;
  const _ClassifiedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
              color: Color(0x30000000), blurRadius: 4, offset: Offset(0, 1))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: item.images.isEmpty
                  ? _placeholder()
                  : Image.network(item.imageUrl,
                      height: 118,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder()),
            ),
            if (item.images.isNotEmpty)
              Positioned(
                bottom: 6, left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Icons.camera_alt_outlined,
                        size: 10, color: Colors.white),
                    const SizedBox(width: 3),
                    Text('${item.images.length}',
                        style: GoogleFonts.poppins(
                            fontSize: 9, color: Colors.white)),
                  ]),
                ),
              ),
            Positioned(
              top: 6, right: 6,
              child: Container(
                width: 26, height: 26,
                decoration: const BoxDecoration(
                    color: Color(0x28000000), shape: BoxShape.circle),
                child: const Icon(Icons.favorite_border,
                    size: 13, color: Colors.white),
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Expanded(
                  child: Text(item.formattedPrice,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kBlue)),
                ),
                Text(item.timeAgo,
                    style: GoogleFonts.poppins(
                        fontSize: 9, color: Colors.black38)),
              ]),
              const SizedBox(height: 2),
              Text(item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87)),
              if (item.condition.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(item.condition,
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.black45)),
              ],
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 11, color: Color(0xFF505050)),
                const SizedBox(width: 2),
                Expanded(
                    child: Text(item.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: const Color(0xFF505050)))),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                    child: _contactBtn(Icons.phone_outlined,
                        const Color(0xFF2258A8))),
                const SizedBox(width: 6),
                Expanded(
                    child: _contactBtn(Icons.chat_bubble_outline,
                        const Color(0xFF25D366))),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _contactBtn(IconData icon, Color color) {
    return Container(
      height: 26,
      decoration: BoxDecoration(
        border:
            Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(child: Icon(icon, size: 14, color: color)),
    );
  }

  Widget _placeholder() => Container(
      height: 118,
      color: const Color(0xFFEDEDED),
      child: const Center(
          child: Icon(Icons.grid_view_outlined,
              color: Colors.grey, size: 36)));
}
