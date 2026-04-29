import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/furniture_provider.dart';
import '../../../../../features/listings/data/models/furniture_listing_model.dart';
import 'furniture_detail_screen.dart';
import 'furniture_filter_screen.dart';

const _kBlue = Color(0xFF2258A8);

class FurnitureListingsScreen extends ConsumerStatefulWidget {
  final String subcategory;
  final String subcategoryLabel;
  const FurnitureListingsScreen({
    super.key,
    required this.subcategory,
    required this.subcategoryLabel,
  });

  @override
  ConsumerState<FurnitureListingsScreen> createState() => _FurnitureListingsScreenState();
}

class _FurnitureListingsScreenState extends ConsumerState<FurnitureListingsScreen> {
  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(furnitureFilteredProvider(widget.subcategory));
    final filter = ref.watch(furnitureFilterProvider);
    final hasFilter = !filter.isEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
        ),
        title: Text(
          widget.subcategoryLabel.isEmpty ? 'All Furniture' : widget.subcategoryLabel,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => FurnitureFilterScreen(subcategory: widget.subcategory),
            )),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Stack(children: [
                SvgPicture.asset('assets/icons/filter.svg', width: 20, height: 20),
                if (hasFilter)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: _kBlue, shape: BoxShape.circle),
                    ),
                  ),
              ]),
            ),
          ),
          GestureDetector(
            onTap: () => _showSortSheet(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SvgPicture.asset('assets/icons/bars_sort.svg', width: 20, height: 20),
            ),
          ),
        ],
      ),
      body: listingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _kBlue)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) => items.isEmpty
            ? Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.chair_outlined, size: 64, color: Colors.black26),
                  const SizedBox(height: 12),
                  Text('No listings found',
                      style: GoogleFonts.poppins(fontSize: 15, color: Colors.black45)),
                ]),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 176,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => FurnitureDetailScreen(item: items[i]),
                  )),
                  child: _FurnitureResultCard(item: items[i]),
                ),
              ),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    final filter = ref.read(furnitureFilterProvider);
    final options = [
      ('Newest to Oldest', 'newest'),
      ('Oldest to Newest', 'oldest'),
      ('Price Highest to Lowest', 'price_high'),
      ('Price Lowest to Highest', 'price_low'),
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('Sort', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          ...options.map((opt) => ListTile(
                title: Text(opt.$1, style: GoogleFonts.poppins(fontSize: 14)),
                trailing: filter.sortBy == opt.$2
                    ? const Icon(Icons.check, color: _kBlue)
                    : null,
                onTap: () {
                  ref.read(furnitureFilterProvider.notifier).state =
                      filter.copyWith(sortBy: opt.$2);
                  Navigator.of(context).pop();
                },
              )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _FurnitureResultCard extends StatefulWidget {
  final FurnitureListingModel item;
  const _FurnitureResultCard({required this.item});

  @override
  State<_FurnitureResultCard> createState() => _FurnitureResultCardState();
}

class _FurnitureResultCardState extends State<_FurnitureResultCard> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    if (widget.item.images.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted) return;
        final next = (_currentPage + 1) % widget.item.images.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
        setState(() => _currentPage = next);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7.38),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 4.22, offset: Offset(0, 1.05))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7.38), topRight: Radius.circular(7.38),
              ),
              child: item.images.isEmpty
                  ? _placeholder()
                  : SizedBox(
                      height: 101.27,
                      width: double.infinity,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: item.images.length,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemBuilder: (_, i) => Image.network(
                          item.images[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        ),
                      ),
                    ),
            ),
            if (item.images.isNotEmpty)
              Positioned(
                bottom: 6, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0x63000000),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_currentPage + 1}/${item.images.length}',
                    style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.w500, color: Colors.white),
                  ),
                ),
              ),
            Positioned(
              top: 8, right: 8,
              child: Container(
                width: 28, height: 28,
                decoration: const BoxDecoration(color: Color(0x140F172A), shape: BoxShape.circle),
                child: const Icon(Icons.favorite_border, size: 14, color: Colors.white),
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.formattedPrice,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3, color: _kBlue)),
              const SizedBox(height: 4),
              Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, height: 1.3, color: Colors.black87)),
              const SizedBox(height: 5),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF505050)),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(item.location, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400, height: 1.3, color: const Color(0xFF505050))),
                ),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        height: 101.27, color: const Color(0xFFF0F0F0),
        child: const Center(child: Icon(Icons.chair_outlined, color: Color(0xFFCCCCCC), size: 40)));
}
