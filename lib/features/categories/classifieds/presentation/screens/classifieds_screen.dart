import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/router/route_names.dart';
import '../providers/classifieds_provider.dart';
import '../../../../../features/listings/data/models/classified_listing_model.dart';
import 'classifieds_listings_screen.dart';
import 'classifieds_detail_screen.dart';

const _kBlue = Color(0xFF2258A8);

const _kSlugAssets = <String, String>{
  // Fashion
  'men':                 'assets/icons/classifieds/men.svg',
  'women':               'assets/icons/classifieds/women.svg',
  'kids-fashion':        'assets/icons/classifieds/kids-fashion.svg',
  'bags':                'assets/icons/classifieds/bags.svg',
  'footwear':            'assets/icons/classifieds/footwear.svg',
  'jewelry':             'assets/icons/classifieds/jewelry.svg',
  'watches-accessories': 'assets/icons/classifieds/watches-accessories.svg',
  // Books & Sports
  'academic-books':      'assets/icons/classifieds/academic-books.svg',
  'fiction-books':       'assets/icons/classifieds/fiction-books.svg',
  'kids-book':           'assets/icons/classifieds/kids-book.svg',
  'exam-preparation':    'assets/icons/classifieds/exam-preparation.svg',
  'sports-accessories':  'assets/icons/classifieds/sports-accessories.svg',
  'cricket-gear':        'assets/icons/classifieds/cricket-gear.svg',
  'fitness-equipment':   'assets/icons/classifieds/fitness-equipment.svg',
};

IconData _iconForSlug(String slug) {
  if (slug.contains('men') || slug.contains('women') || slug.contains('fashion')) return Icons.checkroom_outlined;
  if (slug.contains('bag')) return Icons.shopping_bag_outlined;
  if (slug.contains('foot') || slug.contains('shoe')) return Icons.do_not_step_outlined;
  if (slug.contains('jewel')) return Icons.diamond_outlined;
  if (slug.contains('watch')) return Icons.watch_outlined;
  if (slug.contains('book') || slug.contains('exam')) return Icons.menu_book_outlined;
  if (slug.contains('sport') || slug.contains('cricket') || slug.contains('fitness')) return Icons.sports_outlined;
  if (slug.contains('kid')) return Icons.child_care_outlined;
  return Icons.grid_view_outlined;
}

class ClassifiedsScreen extends ConsumerStatefulWidget {
  const ClassifiedsScreen({super.key});

  @override
  ConsumerState<ClassifiedsScreen> createState() => _ClassifiedsScreenState();
}

class _ClassifiedsScreenState extends ConsumerState<ClassifiedsScreen> {
  String _selectedChip = '';

  static const _headerBoxDecoration = BoxDecoration(
    color: Color(0xFFF6F6F6),
    borderRadius: BorderRadius.all(Radius.circular(6)),
    boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 1))],
  );

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(classifiedsListingsProvider);
    final subcategoriesAsync = ref.watch(classifiedsSubcategoriesProvider);

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
    List<ClassifiedListingModel> listings,
    AsyncValue<List<ClassifiedSubcategory>> subcategoriesAsync,
  ) {
    final filtered = _selectedChip.isEmpty
        ? listings
        : listings.where((l) => l.subcategory.toLowerCase() == _selectedChip.toLowerCase()).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(classifiedsListingsProvider);
        ref.invalidate(classifiedsSubcategoriesProvider);
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
            const SizedBox(height: 16),
            _buildTopDealsHeader(subcategoriesAsync),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              const SizedBox(
                height: 260,
                child: Center(
                  child: Text('No listings yet',
                      style: TextStyle(color: Colors.black45)),
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
                    mainAxisExtent: 198,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ClassifiedsDetailScreen(item: filtered[i]),
                    )),
                    child: _ClassifiedCard(item: filtered[i]),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static const _fashionSlugs = {
    'men', 'women', 'kids-fashion', 'bags', 'footwear', 'jewelry', 'watches-accessories',
  };
  static const _booksSportsSlugs = {
    'academic-books', 'fiction-books', 'kids-book', 'exam-preparation',
    'sports-accessories', 'cricket-gear', 'fitness-equipment',
  };

  Widget _buildSubcategoryGrid(List<ClassifiedSubcategory> subs) {
    final fashion = subs.where((s) => _fashionSlugs.contains(s.slug)).toList();
    final booksAndSports = subs.where((s) => _booksSportsSlugs.contains(s.slug)).toList();

    // fallback: split by index
    final fashionList = fashion.isNotEmpty ? fashion : subs.take(7).toList();
    final booksList = booksAndSports.isNotEmpty
        ? booksAndSports
        : (subs.length > 7 ? subs.skip(7).toList() : <ClassifiedSubcategory>[]);

    // Build slots: 7 fashion + 1 "Books & Sports" group circle = 8 total (2 rows of 4)
    final slots = <_CircleSlot>[
      ...fashionList.map((s) => _CircleSlot.sub(s)),
      if (booksList.isNotEmpty) _CircleSlot.group('Books & Sports', booksList),
    ];

    final rows = <List<_CircleSlot>>[];
    for (int i = 0; i < slots.length; i += 4) {
      rows.add(slots.sublist(i, (i + 4).clamp(0, slots.length)));
    }

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              ...row.map((slot) => Expanded(
                child: slot.isGroup
                    ? GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => _BooksAndSportsScreen(subcategories: slot.groupItems!),
                        )),
                        child: _subcategoryCircle(
                          label: 'Books &\nSports',
                          iconUrl: null,
                          slug: '__books_sports__',
                          customIcon: Icons.sports_outlined,
                        ),
                      )
                    : GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => _ClassifiedsCategoryScreen(
                            title: slot.sub!.name,
                            slug: slot.sub!.slug,
                          ),
                        )),
                        child: _subcategoryCircle(
                          label: slot.sub!.name,
                          iconUrl: slot.sub!.iconUrl,
                          slug: slot.sub!.slug,
                        ),
                      ),
              )),
              ...List.generate(4 - row.length, (_) => const Expanded(child: SizedBox())),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _subcategoryCircle({
    required String label,
    required String? iconUrl,
    required String slug,
    IconData? customIcon,
  }) {
    final fallbackIcon = customIcon ?? _iconForSlug(slug);
    final localAsset = _kSlugAssets[slug];

    Widget iconWidget;
    if (customIcon != null) {
      iconWidget = Icon(customIcon, color: _kBlue, size: 22);
    } else if (localAsset != null) {
      iconWidget = SvgPicture.asset(
        localAsset,
        width: 26, height: 26, fit: BoxFit.contain,
        placeholderBuilder: (_) => Icon(fallbackIcon, color: _kBlue, size: 22),
      );
    } else if (iconUrl != null && iconUrl.isNotEmpty) {
      if (iconUrl.toLowerCase().contains('.svg')) {
        iconWidget = SvgPicture.network(
          iconUrl, width: 26, height: 26, fit: BoxFit.contain,
          placeholderBuilder: (_) => Icon(fallbackIcon, color: _kBlue, size: 22),
        );
      } else {
        iconWidget = Image.network(
          iconUrl, width: 26, height: 26, fit: BoxFit.contain,
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
          width: 55, height: 55,
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
          style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }

  Widget _buildTopDealsHeader(AsyncValue<List<ClassifiedSubcategory>> subcategoriesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Text('Top Deals',
                style: GoogleFonts.poppins(fontSize: 14.75, fontWeight: FontWeight.w600)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ClassifiedsListingsScreen(
                  subcategory: '',
                  subcategoryLabel: 'All Classifieds',
                ),
              )),
              child: Text('See all',
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500)),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        subcategoriesAsync.maybeWhen(
          data: (subs) => SizedBox(
            height: 34,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              children: [
                _chip('All', ''),
                ...subs.take(6).map((s) => _chip(s.name, s.slug)),
              ],
            ),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _chip(String label, String slug) {
    final isSelected = _selectedChip == slug;
    return GestureDetector(
      onTap: () => setState(() => _selectedChip = slug),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _kBlue : Colors.white,
          border: Border.all(color: isSelected ? _kBlue : const Color(0xFFDDDDDD)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: _headerBoxDecoration,
          child: Row(children: [
            Image.asset('assets/images/flags/afghanistan.png',
                width: 22, height: 22, fit: BoxFit.cover),
            const SizedBox(width: 5),
            Text('Afghanistan',
                style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500)),
          ]),
        ),
        const SizedBox(width: 10),
        Container(
            width: 34, height: 34, decoration: _headerBoxDecoration,
            child: const Center(child: Icon(Icons.help_outline, size: 22, color: Colors.black54))),
        const SizedBox(width: 10),
        Container(
            width: 34, height: 34, decoration: _headerBoxDecoration,
            child: const Center(
                child: Icon(Icons.notifications_outlined, size: 22, color: Colors.black87))),
      ]),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const ClassifiedsListingsScreen(
            subcategory: '',
            subcategoryLabel: 'All Classifieds',
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
            Expanded(child: Text('Search classifieds...',
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
              Text('SELL',
                  style: GoogleFonts.montserrat(
                      fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black38)),
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
          Text(label,
              style: GoogleFonts.montserrat(
                  fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black38)),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

// ── Listing Card ──────────────────────────────────────────────────────────────
class _ClassifiedCard extends StatelessWidget {
  final ClassifiedListingModel item;
  const _ClassifiedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 1))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(7), topRight: Radius.circular(7)),
              child: item.images.isEmpty
                  ? _placeholder()
                  : Image.network(item.imageUrl,
                      height: 108, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder()),
            ),
            if (item.isFeatured)
              Positioned(
                top: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFF6B00),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text('Featured',
                      style: GoogleFonts.poppins(
                          fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            Positioned(
              top: 8, right: 8,
              child: Container(
                width: 28, height: 28,
                decoration: const BoxDecoration(
                    color: Color(0x140F172A), shape: BoxShape.circle),
                child: const Icon(Icons.favorite_border, size: 14, color: Colors.white),
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.formattedPrice,
                  style: GoogleFonts.poppins(
                      fontSize: 13.5, fontWeight: FontWeight.w700, color: _kBlue)),
              const SizedBox(height: 3),
              Text(item.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black87)),
              if (item.condition.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(item.condition,
                    style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.black45)),
              ],
              const SizedBox(height: 5),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 12, color: Color(0xFF505050)),
                const SizedBox(width: 3),
                Expanded(
                    child: Text(item.location,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: const Color(0xFF505050)))),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
      height: 108, color: const Color(0xFFEDEDED),
      child: const Center(
          child: Icon(Icons.grid_view_outlined, color: Colors.grey, size: 34)));
}

// ── _CircleSlot helper ────────────────────────────────────────────────────────
class _CircleSlot {
  final ClassifiedSubcategory? sub;
  final bool isGroup;
  final String? groupLabel;
  final List<ClassifiedSubcategory>? groupItems;

  const _CircleSlot._({this.sub, this.isGroup = false, this.groupLabel, this.groupItems});

  factory _CircleSlot.sub(ClassifiedSubcategory s) =>
      _CircleSlot._(sub: s);

  factory _CircleSlot.group(String label, List<ClassifiedSubcategory> items) =>
      _CircleSlot._(isGroup: true, groupLabel: label, groupItems: items);
}

// ── Books & Sports sub-screen (same UI as ClassifiedsScreen) ─────────────────
class _BooksAndSportsScreen extends ConsumerStatefulWidget {
  final List<ClassifiedSubcategory> subcategories;
  const _BooksAndSportsScreen({required this.subcategories});

  @override
  ConsumerState<_BooksAndSportsScreen> createState() => _BooksAndSportsScreenState();
}

class _BooksAndSportsScreenState extends ConsumerState<_BooksAndSportsScreen> {
  String _selectedChip = '';

  static const _headerBoxDecoration = BoxDecoration(
    color: Color(0xFFF6F6F6),
    borderRadius: BorderRadius.all(Radius.circular(6)),
    boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 1))],
  );

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(classifiedsListingsProvider);

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
                data: (all) {
                  final slugSet = widget.subcategories.map((s) => s.slug).toSet();
                  final listings = all.where((l) => slugSet.contains(l.subcategory)).toList();
                  return _buildBody(listings);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
        ),
        const SizedBox(width: 10),
        Text('Books & Sports',
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: _headerBoxDecoration,
          child: Row(children: [
            Image.asset('assets/images/flags/afghanistan.png',
                width: 22, height: 22, fit: BoxFit.cover),
            const SizedBox(width: 5),
            Text('Afghanistan',
                style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500)),
          ]),
        ),
        const SizedBox(width: 10),
        Container(
            width: 34, height: 34, decoration: _headerBoxDecoration,
            child: const Center(child: Icon(Icons.notifications_outlined, size: 22, color: Colors.black87))),
      ]),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const ClassifiedsListingsScreen(
            subcategory: '',
            subcategoryLabel: 'Books & Sports',
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
            Expanded(child: Text('Search books & sports...',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400))),
            const Icon(Icons.tune, size: 16, color: Colors.black54),
          ]),
        ),
      ),
    );
  }

  Widget _buildBody(List<ClassifiedListingModel> listings) {
    final filtered = _selectedChip.isEmpty
        ? listings
        : listings.where((l) => l.subcategory == _selectedChip).toList();

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(classifiedsListingsProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCircleGrid(),
            const SizedBox(height: 16),
            _buildTopDealsHeader(),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              const SizedBox(
                height: 260,
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
                    mainAxisExtent: 198,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ClassifiedsDetailScreen(item: filtered[i]),
                    )),
                    child: _ClassifiedCard(item: filtered[i]),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleGrid() {
    final rows = <List<ClassifiedSubcategory>>[];
    for (int i = 0; i < widget.subcategories.length; i += 4) {
      rows.add(widget.subcategories.sublist(i, (i + 4).clamp(0, widget.subcategories.length)));
    }
    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              ...row.map((s) {
                final localAsset = _kSlugAssets[s.slug];
                final fallback = _iconForSlug(s.slug);
                final iconWidget = localAsset != null
                    ? SvgPicture.asset(localAsset, width: 26, height: 26, fit: BoxFit.contain,
                        placeholderBuilder: (_) => Icon(fallback, color: _kBlue, size: 22))
                    : Icon(fallback, color: _kBlue, size: 22);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => _ClassifiedsCategoryScreen(
                        title: s.name,
                        slug: s.slug,
                      ),
                    )),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 55, height: 55,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: _kBlue, width: 1.5),
                          ),
                          child: Center(child: iconWidget),
                        ),
                        const SizedBox(height: 4),
                        Text(s.name,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(fontSize: 11.5)),
                      ],
                    ),
                  ),
                );
              }),
              ...List.generate(4 - row.length, (_) => const Expanded(child: SizedBox())),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopDealsHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Text('Top Deals',
                style: GoogleFonts.poppins(fontSize: 14.75, fontWeight: FontWeight.w600)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ClassifiedsListingsScreen(
                  subcategory: '',
                  subcategoryLabel: 'Books & Sports',
                ),
              )),
              child: Text('See all',
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500)),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            children: [
              _chip('All', ''),
              ...widget.subcategories.map((s) => _chip(s.name, s.slug)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, String slug) {
    final isSelected = _selectedChip == slug;
    return GestureDetector(
      onTap: () => setState(() => _selectedChip = slug),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _kBlue : Colors.white,
          border: Border.all(color: isSelected ? _kBlue : const Color(0xFFDDDDDD)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87)),
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
              Text('SELL',
                  style: GoogleFonts.montserrat(
                      fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black38)),
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
          Text(label,
              style: GoogleFonts.montserrat(
                  fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black38)),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

// ── Single subcategory screen (Men, Women, Bags, etc.) ───────────────────────
class _ClassifiedsCategoryScreen extends ConsumerStatefulWidget {
  final String title;
  final String slug;
  const _ClassifiedsCategoryScreen({required this.title, required this.slug});

  @override
  ConsumerState<_ClassifiedsCategoryScreen> createState() => _ClassifiedsCategoryScreenState();
}

class _ClassifiedsCategoryScreenState extends ConsumerState<_ClassifiedsCategoryScreen> {
  static const _headerBoxDecoration = BoxDecoration(
    color: Color(0xFFF6F6F6),
    borderRadius: BorderRadius.all(Radius.circular(6)),
    boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 1))],
  );

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(classifiedsFilteredProvider(widget.slug));

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
                data: (listings) => _buildBody(listings),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
        ),
        const SizedBox(width: 10),
        Text(widget.title,
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: _headerBoxDecoration,
          child: Row(children: [
            Image.asset('assets/images/flags/afghanistan.png',
                width: 22, height: 22, fit: BoxFit.cover),
            const SizedBox(width: 5),
            Text('Afghanistan',
                style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500)),
          ]),
        ),
        const SizedBox(width: 10),
        Container(
            width: 34, height: 34, decoration: _headerBoxDecoration,
            child: const Center(
                child: Icon(Icons.notifications_outlined, size: 22, color: Colors.black87))),
      ]),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
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
          Expanded(child: Text('Search ${widget.title.toLowerCase()}...',
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400))),
          const Icon(Icons.tune, size: 16, color: Colors.black54),
        ]),
      ),
    );
  }

  Widget _buildBody(List<ClassifiedListingModel> listings) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(classifiedsFilteredProvider(widget.slug)),
      child: listings.isEmpty
          ? const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 400,
                child: Center(
                  child: Text('No listings yet', style: TextStyle(color: Colors.black45)),
                ),
              ),
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(children: [
                      Text('Top Deals',
                          style: GoogleFonts.poppins(fontSize: 14.75, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('${listings.length} listings',
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.black45)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: 198,
                      ),
                      itemCount: listings.length,
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ClassifiedsDetailScreen(item: listings[i]),
                        )),
                        child: _ClassifiedCard(item: listings[i]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
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
              Text('SELL',
                  style: GoogleFonts.montserrat(
                      fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black38)),
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
          Text(label,
              style: GoogleFonts.montserrat(
                  fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black38)),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
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
