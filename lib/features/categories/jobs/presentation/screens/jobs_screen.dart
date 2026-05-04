import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/favorite_button.dart';
import '../providers/jobs_provider.dart';
import '../../../../../features/listings/data/models/jobs_listing_model.dart';
import 'jobs_listings_screen.dart';
import 'jobs_detail_screen.dart';

const _kBlue = Color(0xFF2258A8);

const _kJobSlugAssets = <String, String>{
  'accountant': 'assets/icons/jobs/accountant.svg',
  'designer': 'assets/icons/jobs/designer.svg',
  'driver': 'assets/icons/jobs/driver.svg',
  'it-engineer-developer': 'assets/icons/jobs/it-engineer-developer.svg',
  'office-assistant': 'assets/icons/jobs/office-assistant.svg',
  'sales-and-marketing': 'assets/icons/jobs/sales-and-marketing.svg',
  'sales-marketing': 'assets/icons/jobs/sales-and-marketing.svg',
  'teacher': 'assets/icons/jobs/teacher.svg',
};

IconData _iconForSlug(String slug) {
  if (slug.contains('sales') || slug.contains('marketing')) {
    return Icons.trending_up_outlined;
  }
  if (slug.contains('teacher') || slug.contains('education')) {
    return Icons.school_outlined;
  }
  if (slug.contains('account')) return Icons.calculate_outlined;
  if (slug.contains('design')) return Icons.design_services_outlined;
  if (slug.contains('office') || slug.contains('assistant')) {
    return Icons.business_center_outlined;
  }
  if (slug.contains('driver') || slug.contains('transport')) {
    return Icons.drive_eta_outlined;
  }
  if (slug.contains('it') ||
      slug.contains('engineer') ||
      slug.contains('developer')) {
    return Icons.computer_outlined;
  }
  if (slug.contains('health') ||
      slug.contains('doctor') ||
      slug.contains('nurse')) {
    return Icons.medical_services_outlined;
  }
  if (slug.contains('finance') || slug.contains('bank')) {
    return Icons.account_balance_outlined;
  }
  return Icons.work_outline;
}

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  String _selectedChip = '';
  late final TextEditingController _searchCtrl;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static const _headerBoxDecoration = BoxDecoration(
    color: Color(0xFFF6F6F6),
    borderRadius: BorderRadius.all(Radius.circular(6)),
    boxShadow: [
      BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 1))
    ],
  );

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(jobsListingsProvider);
    final subcategoriesAsync = ref.watch(jobsSubcategoriesProvider);

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
                loading: () => const Center(
                    child: CircularProgressIndicator(color: _kBlue)),
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
    List<JobsListingModel> listings,
    AsyncValue<List<JobsSubcategory>> subcategoriesAsync,
  ) {
    var filtered = _selectedChip.isEmpty
        ? listings
        : listings
            .where((l) => jobMatchesSubcategory(l, _selectedChip))
            .toList();

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((l) => [
                l.title,
                l.description,
                l.company,
                l.subcategory,
                l.subcategoryLabel,
                l.jobType,
                l.experience,
                l.industry,
                l.education,
                l.sellerType,
                l.sellerName,
                l.city,
                l.currency,
                l.price,
                l.formattedPrice,
              ].join(' ').toLowerCase().contains(_searchQuery))
          .toList();
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(jobsListingsProvider);
        ref.invalidate(jobsSubcategoriesProvider);
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
                    mainAxisExtent: 176,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => JobsDetailScreen(item: filtered[i]),
                    )),
                    child: _JobCard(item: filtered[i]),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSubcategoryGrid(List<JobsSubcategory> subs) {
    final visible = subs.take(7).toList();
    final slots = <Object?>[...visible, 'more'];
    while (slots.length % 4 != 0) {
      slots.add(null);
    }
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
              if (slot == null) return const Expanded(child: SizedBox());
              if (slot == 'more') {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => JobsMoreCategoriesScreen(
                        subcategories: subs,
                      ),
                    )),
                    child: _subcategoryCircle(
                        label: 'More',
                        iconUrl: null,
                        slug: 'more',
                        isMore: true),
                  ),
                );
              }
              final s = slot as JobsSubcategory;
              return Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => JobsListingsScreen(
                      subcategory: s.slug,
                      subcategoryLabel: s.name,
                    ),
                  )),
                  child: _subcategoryCircle(
                      label: s.name, iconUrl: s.iconUrl, slug: s.slug),
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
    final localAsset = _kJobSlugAssets[slug];

    Widget iconWidget;
    if (isMore) {
      iconWidget = Icon(fallbackIcon, color: _kBlue, size: 22);
    } else if (localAsset != null) {
      iconWidget = SvgPicture.asset(
        localAsset,
        width: 26,
        height: 26,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => Icon(fallbackIcon, color: _kBlue, size: 22),
      );
    } else if (iconUrl != null && iconUrl.isNotEmpty) {
      if (iconUrl.toLowerCase().contains('.svg')) {
        iconWidget = SvgPicture.network(
          iconUrl,
          width: 26,
          height: 26,
          fit: BoxFit.contain,
          placeholderBuilder: (_) =>
              Icon(fallbackIcon, color: _kBlue, size: 22),
        );
      } else {
        iconWidget = Image.network(
          iconUrl,
          width: 26,
          height: 26,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              Icon(fallbackIcon, color: _kBlue, size: 22),
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
        SizedBox(
          height: 34,
          child: Align(
            alignment: Alignment.topCenter,
            child: Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 11.5, height: 1.25, fontWeight: FontWeight.w400),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopDealsHeader(
      AsyncValue<List<JobsSubcategory>> subcategoriesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Text('Top Deals',
                style: GoogleFonts.poppins(
                    fontSize: 14.75, fontWeight: FontWeight.w600)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const JobsListingsScreen(
                  subcategory: '',
                  subcategoryLabel: 'All Jobs',
                ),
              )),
              child: Text('See all',
                  style: GoogleFonts.poppins(
                      fontSize: 11, fontWeight: FontWeight.w500)),
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
                ...subs.take(5).map((s) => _chip(s.name, s.slug)),
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
          border:
              Border.all(color: isSelected ? _kBlue : const Color(0xFFDDDDDD)),
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
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(Icons.arrow_back_ios_new,
                size: 20, color: Colors.black87),
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
                  style: GoogleFonts.montserrat(
                      fontSize: 12, fontWeight: FontWeight.w500)),
            ]),
          ),
          const SizedBox(width: 10),
          Container(
              width: 34,
              height: 34,
              decoration: _headerBoxDecoration,
              child: const Center(
                  child: Icon(Icons.help_outline,
                      size: 22, color: Colors.black54))),
          const SizedBox(width: 10),
          Container(
              width: 34,
              height: 34,
              decoration: _headerBoxDecoration,
              child: const Center(
                  child: Icon(Icons.notifications_outlined,
                      size: 22, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFC2C2C2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.search, size: 16, color: Colors.black87),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search jobs...',
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.black45),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w400),
              ),
            ),
            if (_searchCtrl.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.close, size: 16, color: Colors.black54),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SvgPicture.asset('assets/icons/filter.svg',
                    width: 16, height: 16),
              ),
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
              boxShadow: [
                BoxShadow(
                    color: Color(0x25000000),
                    blurRadius: 8,
                    offset: Offset(0, 2))
              ],
            ),
            child:
                const Center(child: Icon(Icons.add, color: _kBlue, size: 28)),
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
              color: Color(0x28000000), blurRadius: 12, offset: Offset(0, -4))
        ],
      ),
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 0,
        child: SizedBox(
          height: 66,
          child: Row(children: [
            Expanded(
                child: _navItem(Icons.home_rounded, 'HOME',
                    () => context.go(RouteNames.home))),
            Expanded(
                child: _navItem(Icons.chat_bubble_outline, 'CHATS',
                    () => context.go(RouteNames.chats))),
            Expanded(
                child:
                    Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text('SELL',
                  style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.black38)),
              const SizedBox(height: 8),
            ])),
            Expanded(
                child: _navItem(Icons.favorite_border, 'MY ADS',
                    () => context.push(RouteNames.myAds))),
            Expanded(
                child: _navItem(Icons.person_outline, 'ACCOUNT',
                    () => context.go(RouteNames.account))),
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
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.black38)),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

// ── Listing Card ──────────────────────────────────────────────────────────────
class JobsMoreCategoriesScreen extends StatelessWidget {
  final List<JobsSubcategory> subcategories;
  const JobsMoreCategoriesScreen({super.key, required this.subcategories});

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
              color: Colors.black87, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Jobs Categories',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisExtent: 104,
          crossAxisSpacing: 8,
          mainAxisSpacing: 14,
        ),
        itemCount: subcategories.length,
        itemBuilder: (context, index) {
          final item = subcategories[index];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => JobsListingsScreen(
                subcategory: item.slug,
                subcategoryLabel: item.name,
              ),
            )),
            child: _JobCategoryTile(item: item),
          );
        },
      ),
    );
  }
}

class _JobCategoryTile extends StatelessWidget {
  final JobsSubcategory item;
  const _JobCategoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final fallbackIcon = _iconForSlug(item.slug);
    final localAsset = _kJobSlugAssets[item.slug];
    final icon = localAsset != null
        ? SvgPicture.asset(
            localAsset,
            width: 26,
            height: 26,
            fit: BoxFit.contain,
            placeholderBuilder: (_) =>
                Icon(fallbackIcon, color: _kBlue, size: 22),
          )
        : Icon(fallbackIcon, color: _kBlue, size: 22);

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
          child: Center(child: icon),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 34,
          child: Align(
            alignment: Alignment.topCenter,
            child: Text(
              item.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                height: 1.25,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobsListingModel item;
  const _JobCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7.38),
        boxShadow: const [
          BoxShadow(
              color: Color(0x40000000),
              blurRadius: 4.22,
              offset: Offset(0, 1.05))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7.38),
                topRight: Radius.circular(7.38),
              ),
              child: item.images.isEmpty
                  ? _placeholder()
                  : Image.network(item.imageUrl,
                      height: 101.27,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder()),
            ),
            if (item.isFeatured)
              Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFF6B00),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text('Featured',
                        style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  )),
            Positioned(
                top: 8,
                right: 8,
                child: FavoriteButton(
                  listingId: item.id,
                  size: 28,
                  backgroundColor: const Color(0x100F172A),
                  showShadow: false,
                  unselectedIconColor: Colors.white,
                  selectedIconColor: Colors.red,
                )),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 12, color: Color(0xFF505050)),
                const SizedBox(width: 3),
                Expanded(
                    child: Text(item.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                            color: const Color(0xFF505050)))),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
      height: 101.27,
      color: const Color(0xFFEDEDED),
      child: const Center(
          child: Icon(Icons.work_outline, color: Colors.grey, size: 34)));
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
    canvas.drawArc(
        rect, -pi / 2 + third, third, false, arc(const Color(0xFF000000)));
    canvas.drawArc(
        rect, -pi / 2 + 2 * third, third, false, arc(const Color(0xFF3B77FE)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
