import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/router/route_names.dart';
import '../../../cars/data/models/subcategory_model.dart';
import '../../../cars/presentation/providers/subcategories_provider.dart';
import '../../data/models/property_listing_model.dart';
import '../providers/property_listings_provider.dart';
import 'property_subtype_screen.dart';

const _kBlue = Color(0xFF2258A8);

class PropertiesScreen extends ConsumerStatefulWidget {
  const PropertiesScreen({super.key});

  @override
  ConsumerState<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends ConsumerState<PropertiesScreen> {
  String _activeType = 'All';

  static const _headerBoxDecoration = BoxDecoration(
    color: Color(0xFFF6F6F6),
    borderRadius: BorderRadius.all(Radius.circular(6)),
    boxShadow: [
      BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 1)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final subcatsAsync = ref.watch(subcategoriesProvider('properties'));
    final listingsAsync = ref.watch(propertyListingsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildSellFab(context),
      bottomNavigationBar: _buildBottomNav(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            _buildSearchBar(),
            const SizedBox(height: 14),
            Expanded(
              child: listingsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: _kBlue)),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (listings) {
                  return subcatsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: _kBlue)),
                    error: (_, __) => _buildBody(listings, const []),
                    data: (subcats) => _buildBody(listings, subcats),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<PropertyListingModel> listings, List<SubcategoryModel> subcats) {
    final types = {
      for (final l in listings)
        if (l.propertyType.trim().isNotEmpty) l.propertyType.trim()
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final chips = ['All', ...types.take(4)];
    final filtered = _activeType == 'All'
        ? listings
        : listings.where((l) => l.propertyType.toLowerCase().contains(_activeType.toLowerCase())).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(propertyListingsProvider);
        ref.invalidate(subcategoriesProvider('properties'));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubcategoryGrid(subcats),
            const SizedBox(height: 18),
            _buildTopDealsHeader(),
            const SizedBox(height: 10),
            _buildTypeChips(chips),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              const SizedBox(
                height: 280,
                child: Center(
                  child: Text('No properties yet', style: TextStyle(color: Colors.black45)),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 176,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _PropertyCard(item: filtered[i]),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSubcategoryGrid(List<SubcategoryModel> subcats) {
    // Show up to 7 items + 1 More button = max 8 slots
    final items = subcats.take(7).toList();
    // Build flat slot list: 'item' | 'more' | 'empty'
    // Each slot is either a SubcategoryModel, the string 'more', or null (empty)
    final slots = <Object?>[...items, 'more']; // always show More
    while (slots.length % 4 != 0) { slots.add(null); } // empty padding

    final rows = <List<Object?>>[];
    for (int i = 0; i < slots.length; i += 4) {
      rows.add(slots.sublist(i, i + 4));
    }

    return Column(
      children: rows.map((r) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: r.map((slot) {
              if (slot == null) {
                return const Expanded(child: SizedBox());
              }
              if (slot == 'more') {
                return Expanded(
                  child: _subcategoryCircle(name: 'More', iconUrl: null, isMore: true),
                );
              }
              final item = slot as SubcategoryModel;
              return Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PropertySubtypeScreen(
                        subcategoryName: item.name,
                        subcategorySlug: item.slug,
                      ),
                    ),
                  ),
                  child: _subcategoryCircle(
                    name: item.name,
                    iconUrl: item.iconUrl,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _subcategoryCircle({
    required String name,
    String? iconUrl,
    bool isMore = false,
    bool isActive = false,
  }) {
    final fallback = isMore ? Icons.more_horiz : Icons.home_work_outlined;
    final safeIconUrl = iconUrl ?? '';
    final hasIcon = safeIconUrl.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: _kBlue, width: isActive ? 2.5 : 1.5),
          ),
          child: Center(
            child: hasIcon
                ? (safeIconUrl.toLowerCase().contains('.svg')
                    ? SvgPicture.network(
                        safeIconUrl,
                        width: 26,
                        height: 26,
                        fit: BoxFit.contain,
                        placeholderBuilder: (_) => Icon(fallback, color: _kBlue, size: 22),
                      )
                    : Image.network(
                        safeIconUrl,
                        width: 26,
                        height: 26,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(fallback, color: _kBlue, size: 22),
                      ))
                : Icon(fallback, color: _kBlue, size: 22),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(fontSize: 11.6, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }

  Widget _buildTypeChips(List<String> chips) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) {
          final chip = chips[i];
          final active = chip == _activeType;
          return GestureDetector(
            onTap: () => setState(() => _activeType = chip),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: active ? _kBlue : Colors.white,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: _kBlue),
              ),
              child: Text(
                chip,
                style: GoogleFonts.poppins(
                  fontSize: 11.6,
                  fontWeight: FontWeight.w400,
                  color: active ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: chips.length,
      ),
    );
  }

  Widget _buildTopDealsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text('Top Deals', style: GoogleFonts.poppins(fontSize: 29.5 / 2, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('See all', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: _headerBoxDecoration,
            child: Row(
              children: [
                Image.asset('assets/images/flags/afghanistan.png', width: 22, height: 22, fit: BoxFit.cover),
                const SizedBox(width: 5),
                Text('Afghanistan', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 34,
            height: 34,
            decoration: _headerBoxDecoration,
            child: const Center(child: Icon(Icons.help_outline, size: 22, color: Colors.black54)),
          ),
          const SizedBox(width: 10),
          Container(
            width: 34,
            height: 34,
            decoration: _headerBoxDecoration,
            child: const Center(child: Icon(Icons.notifications_outlined, size: 22, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFC2C2C2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 16, color: Colors.black87),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Search', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400)),
            ),
            const Icon(Icons.tune, size: 16, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _buildSellFab(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.sell),
      child: SizedBox(
        width: 58,
        height: 58,
        child: CustomPaint(
          foregroundPainter: _SellRingPainter(),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [BoxShadow(color: Color(0x25000000), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: const Center(child: Icon(Icons.add, color: _kBlue, size: 28)),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 12,
            spreadRadius: 0,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 0,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              Expanded(
                child: _navItem(context, Icons.home_rounded, 'HOME', () => context.go(RouteNames.home)),
              ),
              Expanded(
                child: _navItem(context, Icons.chat_bubble_outline, 'CHATS', () => context.go(RouteNames.chats)),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'SELL',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black38,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(
                child: _navItem(context, Icons.favorite_border, 'MY ADS', () => context.go(RouteNames.favorites)),
              ),
              Expanded(
                child: _navItem(context, Icons.person_outline, 'ACCOUNT', () => context.go(RouteNames.account)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final isHome = label == 'HOME';
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: isHome ? _kBlue : Colors.black38),
            const SizedBox(height: 7),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isHome ? _kBlue : Colors.black38,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _PropertyCard extends StatefulWidget {
  final PropertyListingModel item;
  const _PropertyCard({required this.item});

  @override
  State<_PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<_PropertyCard> {
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
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 4.22, offset: Offset(0, 1.05)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(7.38),
                  topRight: Radius.circular(7.38),
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
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                      color: Color(0x140F172A), shape: BoxShape.circle),
                  child: const Icon(Icons.favorite_border, size: 14, color: Colors.white),
                ),
              ),
              if (item.images.length > 1)
                Positioned(
                  bottom: 6,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0x63000000),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_currentPage + 1}/${item.images.length}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.formattedPrice,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: _kBlue)),
                const SizedBox(height: 4),
                Text(item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                        color: Colors.black87)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: Color(0xFF505050)),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        item.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                            color: const Color(0xFF505050)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
      height: 101.27,
      color: const Color(0xFFEDEDED),
      child: const Center(
          child: Icon(Icons.home_work_outlined, color: Colors.grey, size: 34)));
}

class _SellRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeW = 6.5;
    final radius = size.width / 2 - strokeW / 2 - 1;
    final rect = Rect.fromCircle(center: center, radius: radius);
    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;

    const third = 2 * pi / 3;
    canvas.drawArc(rect, -pi / 2, third, false, arc(const Color(0xFF1D57A7)));
    canvas.drawArc(rect, -pi / 2 + third, third, false, arc(const Color(0xFF000000)));
    canvas.drawArc(rect, -pi / 2 + 2 * third, third, false, arc(const Color(0xFF3B77FE)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
