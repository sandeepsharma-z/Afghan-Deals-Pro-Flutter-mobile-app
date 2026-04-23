import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/router/route_names.dart';
import '../providers/electronics_provider.dart';
import '../../../../../features/listings/data/models/electronics_listing_model.dart';
import 'electronics_listings_screen.dart';
import 'electronics_detail_screen.dart';

const _kBlue = Color(0xFF2258A8);

/// Fallback icon per subcategory slug
IconData _iconForSlug(String slug) {
  if (slug.contains('tv') || slug.contains('video') || slug.contains('audio')) {
    return Icons.tv_outlined;
  }
  if (slug.contains('kitchen') || slug.contains('appliance')) {
    return Icons.kitchen_outlined;
  }
  if (slug.contains('fridge') || slug.contains('refrigerator')) {
    return Icons.ac_unit_outlined;
  }
  if (slug.contains('camera') || slug.contains('lens')) {
    return Icons.camera_alt_outlined;
  }
  if (slug.contains('washing') || slug.contains('laundry')) {
    return Icons.local_laundry_service_outlined;
  }
  if (slug.contains('ac') || slug.contains('air')) {
    return Icons.wind_power_outlined;
  }
  if (slug.contains('game') || slug.contains('entertainment')) {
    return Icons.sports_esports_outlined;
  }
  return Icons.devices_other_outlined;
}

class ElectronicsScreen extends ConsumerStatefulWidget {
  const ElectronicsScreen({super.key});

  @override
  ConsumerState<ElectronicsScreen> createState() => _ElectronicsScreenState();
}

class _ElectronicsScreenState extends ConsumerState<ElectronicsScreen> {
  static const _headerBoxDecoration = BoxDecoration(
    color: Color(0xFFF6F6F6),
    borderRadius: BorderRadius.all(Radius.circular(6)),
    boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 1))],
  );

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(electronicsListingsProvider);
    final subcategoriesAsync = ref.watch(electronicsSubcategoriesProvider);

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
            _buildSearchBar(context),
            const SizedBox(height: 14),
            Expanded(
              child: listingsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: _kBlue)),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (listings) => _buildBody(listings, subcategoriesAsync),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    List<ElectronicsListingModel> listings,
    AsyncValue<List<ElectronicsSubcategory>> subcategoriesAsync,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(electronicsListingsProvider);
        ref.invalidate(electronicsSubcategoriesProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            subcategoriesAsync.when(
              loading: () => const SizedBox(
                height: 130,
                child: Center(child: CircularProgressIndicator(color: _kBlue)),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (subs) => _buildSubcategoryGrid(subs),
            ),
            const SizedBox(height: 18),
            _buildTopDealsHeader(listings),
            const SizedBox(height: 12),
            if (listings.isEmpty)
              const SizedBox(
                height: 280,
                child: Center(
                  child: Text('No listings yet', style: TextStyle(color: Colors.black45)),
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
                    mainAxisExtent: 204,
                  ),
                  itemCount: listings.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ElectronicsDetailScreen(item: listings[i]),
                    )),
                    child: _ElectronicsCard(item: listings[i]),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSubcategoryGrid(List<ElectronicsSubcategory> subs) {
    // Show first 7 + "More" button
    final visible = subs.take(7).toList();
    final slots = <Object?>[...visible, 'more'];
    while (slots.length % 4 != 0) { slots.add(null); }
    final rows = <List<Object?>>[];
    for (int i = 0; i < slots.length; i += 4) { rows.add(slots.sublist(i, i + 4)); }

    return Column(
      children: rows.map((r) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: r.map((slot) {
              if (slot == null) return const Expanded(child: SizedBox());
              if (slot == 'more') {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const ElectronicsListingsScreen(
                        subcategory: '',
                        subcategoryLabel: 'All Electronics',
                      ),
                    )),
                    child: _subcategoryCircle(
                      label: 'More',
                      iconUrl: null,
                      slug: 'more',
                      isMore: true,
                    ),
                  ),
                );
              }
              final s = slot as ElectronicsSubcategory;
              return Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ElectronicsListingsScreen(
                      subcategory: s.slug,
                      subcategoryLabel: s.name,
                    ),
                  )),
                  child: _subcategoryCircle(
                    label: s.name,
                    iconUrl: s.iconUrl,
                    slug: s.slug,
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
    required String label,
    required String? iconUrl,
    required String slug,
    bool isMore = false,
  }) {
    final fallbackIcon = isMore ? Icons.more_horiz : _iconForSlug(slug);

    Widget iconWidget;
    if (isMore) {
      iconWidget = Icon(fallbackIcon, color: _kBlue, size: 22);
    } else if (iconUrl != null && iconUrl.isNotEmpty) {
      if (iconUrl.toLowerCase().contains('.svg')) {
        iconWidget = SvgPicture.network(
          iconUrl,
          width: 26,
          height: 26,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => Icon(fallbackIcon, color: _kBlue, size: 22),
        );
      } else {
        iconWidget = Image.network(
          iconUrl,
          width: 26,
          height: 26,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(fallbackIcon, color: _kBlue, size: 22),
        );
      }
    } else {
      iconWidget = Icon(fallbackIcon, color: _kBlue, size: 22);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: _kBlue, width: 1.5),
          ),
          child: Center(child: iconWidget),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(fontSize: 11.6, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }

  Widget _buildTopDealsHeader(List<ElectronicsListingModel> listings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text('Top Deals',
              style: GoogleFonts.poppins(fontSize: 14.75, fontWeight: FontWeight.w600)),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const ElectronicsListingsScreen(
                subcategory: '',
                subcategoryLabel: 'All Electronics',
              ),
            )),
            child: Text('See all',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500)),
          ),
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
            child: Row(children: [
              Image.asset('assets/images/flags/afghanistan.png', width: 22, height: 22, fit: BoxFit.cover),
              const SizedBox(width: 5),
              Text('Afghanistan',
                  style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500)),
            ]),
          ),
          const SizedBox(width: 10),
          Container(width: 34, height: 34, decoration: _headerBoxDecoration,
              child: const Center(child: Icon(Icons.help_outline, size: 22, color: Colors.black54))),
          const SizedBox(width: 10),
          Container(width: 34, height: 34, decoration: _headerBoxDecoration,
              child: const Center(child: Icon(Icons.notifications_outlined, size: 22, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const ElectronicsListingsScreen(
            subcategory: '',
            subcategoryLabel: 'All Electronics',
          ),
        )),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFC2C2C2)),
          ),
          child: Row(children: [
            const Icon(Icons.search, size: 16, color: Colors.black87),
            const SizedBox(width: 8),
            Expanded(child: Text('Search electronics...',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400))),
            const Icon(Icons.tune, size: 16, color: Colors.black54),
          ]),
        ),
      ),
    );
  }

  Widget _buildSellFab(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.sell),
      child: SizedBox(
        width: 58, height: 58,
        child: CustomPaint(
          foregroundPainter: _SellRingPainter(),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Colors.white,
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
        boxShadow: [BoxShadow(color: Color(0x28000000), blurRadius: 12, offset: Offset(0, -4))],
      ),
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 0,
        child: SizedBox(
          height: 66,
          child: Row(children: [
            Expanded(child: _navItem(Icons.home_rounded, 'HOME', () => context.go(RouteNames.home))),
            Expanded(child: _navItem(Icons.chat_bubble_outline, 'CHATS', () => context.go(RouteNames.chats))),
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text('SELL', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black38)),
              const SizedBox(height: 8),
            ])),
            Expanded(child: _navItem(Icons.favorite_border, 'MY ADS', () => context.go(RouteNames.myAds))),
            Expanded(child: _navItem(Icons.person_outline, 'ACCOUNT', () => context.go(RouteNames.account))),
          ]),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: double.infinity,
        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Icon(icon, size: 24, color: Colors.black38),
          const SizedBox(height: 7),
          Text(label, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black38)),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

// ── Listing Card ─────────────────────────────────────────────────────────────
class _ElectronicsCard extends StatelessWidget {
  final ElectronicsListingModel item;
  const _ElectronicsCard({required this.item});

  @override
  Widget build(BuildContext context) {
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
                  : Image.network(item.imageUrl, height: 110, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder()),
            ),
            if (item.isFeatured)
              Positioned(top: 8, left: 8, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFFF6B00), borderRadius: BorderRadius.circular(4)),
                child: Text('Featured', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white)),
              )),
            Positioned(top: 8, right: 8, child: Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(color: Color(0x140F172A), shape: BoxShape.circle),
              child: const Icon(Icons.favorite_border, size: 14, color: Colors.white),
            )),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.formattedPrice,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3, color: _kBlue)),
              const SizedBox(height: 3),
              Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, height: 1.3, color: Colors.black87)),
              if (item.age.isNotEmpty || item.brand.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  [if (item.age.isNotEmpty) 'Age: ${item.age}', if (item.brand.isNotEmpty) item.brand].join(' · '),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400, height: 1.3, color: Colors.black54),
                ),
              ],
              const SizedBox(height: 5),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF505050)),
                const SizedBox(width: 3),
                Expanded(child: Text(item.location, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400, height: 1.3, color: const Color(0xFF505050)))),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(height: 110, color: const Color(0xFFEDEDED),
      child: const Center(child: Icon(Icons.devices_other, color: Colors.grey, size: 34)));
}

class _SellRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeW = 6.5;
    final radius = size.width / 2 - strokeW / 2 - 1;
    final rect = Rect.fromCircle(center: center, radius: radius);
    Paint arc(Color c) => Paint()
      ..color = c ..style = PaintingStyle.stroke ..strokeWidth = strokeW ..strokeCap = StrokeCap.butt;
    const third = 2 * pi / 3;
    canvas.drawArc(rect, -pi / 2, third, false, arc(const Color(0xFF1D57A7)));
    canvas.drawArc(rect, -pi / 2 + third, third, false, arc(const Color(0xFF000000)));
    canvas.drawArc(rect, -pi / 2 + 2 * third, third, false, arc(const Color(0xFF3B77FE)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
