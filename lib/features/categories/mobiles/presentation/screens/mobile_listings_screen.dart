import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../features/chat/presentation/providers/chat_provider.dart';
import '../../../../../features/listings/data/models/mobile_listing_model.dart';
import '../providers/mobile_listings_provider.dart';
import 'mobile_detail_screen.dart';
import 'mobile_filter_screen.dart';

const _kBlue = Color(0xFF2258A8);

const _sortOptions = [
  'Popular',
  'Verified',
  'Newest to Oldest',
  'Oldest to Newest',
  'Price Highest to Lowest',
  'Price Lowest to Highest',
];

class MobileListingsScreen extends ConsumerStatefulWidget {
  /// Brand name to filter by. Empty string = show all.
  final String brand;
  const MobileListingsScreen({super.key, required this.brand});

  @override
  ConsumerState<MobileListingsScreen> createState() =>
      _MobileListingsScreenState();
}

class _MobileListingsScreenState extends ConsumerState<MobileListingsScreen> {
  String _sortBy = 'Newest to Oldest';

  List<MobileListingModel> _sorted(List<MobileListingModel> list) {
    final out = List<MobileListingModel>.from(list);
    switch (_sortBy) {
      case 'Price Lowest to Highest':
        out.sort((a, b) => (double.tryParse(a.price) ?? 0)
            .compareTo(double.tryParse(b.price) ?? 0));
        break;
      case 'Price Highest to Lowest':
        out.sort((a, b) => (double.tryParse(b.price) ?? 0)
            .compareTo(double.tryParse(a.price) ?? 0));
        break;
      case 'Oldest to Newest':
        out.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      default:
        out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final brand = widget.brand;
    final asyncData = brand.isEmpty
        ? ref.watch(mobileListingsProvider)
        : ref.watch(mobileListingsByBrandProvider(brand));

    final cities = ref.watch(mobileCitiesProvider).valueOrNull ?? <String>[];

    final title = brand.isEmpty ? 'Mobile Phones' : brand;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 28 / 15,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/bars_sort.svg',
              width: 20,
              height: 20,
            ),
            onPressed: () => _showSortSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black87, size: 20),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MobileFilterScreen(cities: cities),
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
        ),
      ),
      body: asyncData.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kBlue)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (listings) {
          final sorted = _sorted(listings);
          return Column(
            children: [
              Expanded(
                child: sorted.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.smartphone_outlined,
                                size: 64, color: Colors.black26),
                            const SizedBox(height: 12),
                            Text('No listings found',
                                style: GoogleFonts.poppins(
                                    fontSize: 16, color: Colors.black45)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => brand.isEmpty
                            ? ref.refresh(mobileListingsProvider.future)
                            : ref.refresh(
                                mobileListingsByBrandProvider(brand).future),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            mainAxisExtent: 245,
                          ),
                          itemCount: sorted.length,
                          itemBuilder: (_, i) => _MobileListCard(
                            listing: sorted[i],
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    MobileDetailScreen(mobile: sorted[i]),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sort By',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            ..._sortOptions.map((opt) => Column(
                  children: [
                    ListTile(
                      title: Text(opt,
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: opt == _sortBy
                                  ? FontWeight.w600
                                  : FontWeight.w400)),
                      trailing: opt == _sortBy
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () {
                        setState(() => _sortBy = opt);
                        Navigator.pop(ctx);
                      },
                    ),
                    Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        color: const Color(0xFFEEEEEE)),
                  ],
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Grid Card ──────────────────────────────────────────────────────────────────

class _MobileListCard extends ConsumerWidget {
  final MobileListingModel listing;
  final VoidCallback onTap;
  const _MobileListCard({required this.listing, required this.onTap});

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
  }

  Future<void> _openChat(BuildContext context, WidgetRef ref) async {
    try {
      final chatId =
          await ref.read(chatActionsProvider).openOrCreateChatForListing(
                listingId: listing.id,
                sellerId: listing.sellerId,
              );
      if (!context.mounted) return;
      context.push('/chat/$chatId');
    } catch (e) {
      if (!context.mounted) return;
      final message = e.toString().replaceAll('Exception: ', '');
      if (message.toLowerCase().contains('please sign in first')) {
        context.push(RouteNames.onboarding);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = _formatDate(listing.createdAt);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7.38),
          border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
          boxShadow: const [
            BoxShadow(
                color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──────────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(7.38)),
                  child: listing.imageUrl.isNotEmpty
                      ? Image.network(
                          listing.imageUrl,
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                // Share + Heart
                const Positioned(
                  top: 6,
                  right: 6,
                  child: Row(
                    children: [
                      _CircleBtn(icon: Icons.reply_outlined),
                      SizedBox(width: 4),
                      _CircleBtn(icon: Icons.favorite_border),
                    ],
                  ),
                ),
                // Image count
                if (listing.images.isNotEmpty)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0x63000000),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.image_outlined,
                              color: Colors.white, size: 9),
                          const SizedBox(width: 3),
                          Text('${listing.images.length}',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
                                  height: 1)),
                        ],
                      ),
                    ),
                  ),
                // Featured badge
                if (listing.isFeatured)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Featured',
                          style: GoogleFonts.poppins(
                              fontSize: 7,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
              ],
            ),
            // ── Content ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price + date
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(listing.formattedPrice,
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _kBlue)),
                      ),
                      Text(date,
                          style: GoogleFonts.poppins(
                              fontSize: 7.5, color: const Color(0xFF505050))),
                    ],
                  ),
                  // Title
                  Text(listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.black)),
                  // Category / Brand
                  Text(
                    'Mobile Phones${listing.brand.isNotEmpty ? ' / ${listing.brand}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.black54),
                  ),
                  // Age
                  if (listing.condition.isNotEmpty)
                    Text('Age: ${listing.condition}',
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: Colors.black54)),
                  const SizedBox(height: 4),
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 10, color: Color(0xFF505050)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(listing.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontSize: 10, color: const Color(0xFF505050))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Divider(
                      height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
                  const SizedBox(height: 4),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const _ActionBtn(icon: Icons.phone_outlined),
                      const SizedBox(width: 6),
                      _ActionBtn(
                        icon: Icons.chat_bubble_outline,
                        onTap: () => _openChat(context, ref),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
      height: 110,
      color: const Color(0xFFEDEDED),
      child: const Center(
          child: Icon(Icons.smartphone, color: Colors.grey, size: 34)));
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _ActionBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 31,
        height: 22,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
          color: Colors.white,
        ),
        child: Center(child: Icon(icon, size: 14, color: _kBlue)),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  const _CircleBtn({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration:
          const BoxDecoration(color: Color(0x140F172A), shape: BoxShape.circle),
      child: Icon(icon, size: 14, color: Colors.white),
    );
  }
}
