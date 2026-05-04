import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../categories/cars/presentation/screens/car_sale_detail_screen.dart';
import '../../../categories/classifieds/presentation/screens/classifieds_detail_screen.dart';
import '../../../categories/electronics/presentation/screens/electronics_detail_screen.dart';
import '../../../categories/furniture/presentation/screens/furniture_detail_screen.dart';
import '../../../categories/jobs/presentation/screens/jobs_detail_screen.dart';
import '../../../categories/mobiles/presentation/screens/mobile_detail_screen.dart';
import '../../../categories/properties/presentation/screens/property_detail_screen.dart';
import '../../../categories/spare_parts/presentation/providers/spare_parts_provider.dart';
import '../../../categories/spare_parts/presentation/screens/spare_parts_detail_screen.dart';
import '../../../categories/properties/data/models/property_listing_model.dart';
import '../../../listings/data/models/car_sale_model.dart';
import '../../../listings/data/models/classified_listing_model.dart';
import '../../../listings/data/models/electronics_listing_model.dart';
import '../../../listings/data/models/furniture_listing_model.dart';
import '../../../listings/data/models/jobs_listing_model.dart';
import '../../../../features/listings/data/models/listing_model.dart';
import '../../../listings/data/models/mobile_listing_model.dart';
import '../providers/favorites_provider.dart';

final myAdsProvider = FutureProvider<List<ListingModel>>((ref) async {
  final me = Supabase.instance.client.auth.currentUser;
  if (me == null) return const <ListingModel>[];

  final response = await Supabase.instance.client
      .from('listings')
      .select()
      .eq('seller_id', me.id)
      .order('created_at', ascending: false);

  if (response.isEmpty) return const <ListingModel>[];

  final items = <ListingModel>[];
  for (final row in response) {
    try {
      items.add(ListingModel.fromMap(row));
    } catch (e) {
      debugPrint('Error mapping ad: $e');
    }
  }
  return items;
});

class MyAdsScreen extends ConsumerWidget {
  final VoidCallback? onBackToHome;
  const MyAdsScreen({super.key, this.onBackToHome});

  void _goBack(BuildContext context) {
    if (onBackToHome != null) {
      debugPrint('MyAds embedded back tapped -> Home tab');
      onBackToHome!();
      return;
    }
    debugPrint('MyAds back tapped -> Home');
    context.go(RouteNames.home);
  }

  void _navigateToDetail(BuildContext context, ListingModel listing) {
    debugPrint('MyAds listing tapped: ${listing.id}');
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => _detailScreenFor(listing),
      ),
    );
  }

  Map<String, dynamic> _detailMap(ListingModel listing) {
    return {
      ...listing.toMap(),
      'id': listing.id,
      'seller_id': listing.sellerId,
      'seller_name': listing.sellerName,
      'created_at': listing.createdAt.toIso8601String(),
      'is_active': listing.isActive,
      'is_featured': listing.isFeatured,
      'view_count': listing.viewCount,
    };
  }

  Widget _detailScreenFor(ListingModel listing) {
    final map = _detailMap(listing);
    switch (listing.category.trim().toLowerCase().replaceAll('_', '-')) {
      case 'cars':
        return CarSaleDetailScreen(car: CarSaleModel.fromMap(map));
      case 'properties':
        return PropertyDetailScreen(
            property: PropertyListingModel.fromMap(map));
      case 'mobiles':
        return MobileDetailScreen(mobile: MobileListingModel.fromMap(map));
      case 'electronics':
        return ElectronicsDetailScreen(
            item: ElectronicsListingModel.fromMap(map));
      case 'furniture':
        return FurnitureDetailScreen(item: FurnitureListingModel.fromMap(map));
      case 'jobs':
        return JobsDetailScreen(item: JobsListingModel.fromMap(map));
      case 'classifieds':
        return ClassifiedsDetailScreen(
            item: ClassifiedListingModel.fromMap(map));
      case 'spare-parts':
        return SparePartsDetailScreen(listing: SparePartListing.fromMap(map));
      default:
        return _ListingDetailView(listing: listing);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(myAdsProvider);
    final favoritesAsync = ref.watch(favoritesProvider);
    final isEmbedded = onBackToHome != null;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButtonLocation:
          isEmbedded ? null : FloatingActionButtonLocation.centerDocked,
      floatingActionButton: isEmbedded ? null : const AppSellFab(),
      bottomNavigationBar:
          isEmbedded ? null : const AppBottomNav(activeIndex: 3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 48,
        leading: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _goBack(context),
          child: const SizedBox(
            width: 48,
            height: kToolbarHeight,
            child: Center(
              child: Icon(Icons.arrow_back_ios_new,
                  size: 18, color: Colors.black87),
            ),
          ),
        ),
        title: Text(
          'My Ads',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: const [SizedBox(width: 48)],
      ),
      body: adsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          debugPrint('Ads error: $e\n$st');
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading ads',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      ref.invalidate(myAdsProvider);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Retry',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        data: (ads) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // My Ads Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Ads',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '(${ads.length})',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (ads.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 40, color: Colors.black26),
                        const SizedBox(height: 8),
                        Text(
                          'No ads yet',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: ads.length,
                      itemBuilder: (context, index) {
                        final ad = ads[index];
                        return Padding(
                          padding: EdgeInsets.only(
                              right: index == ads.length - 1 ? 0 : 14),
                          child: SizedBox(
                            width: 150,
                            child: _AdCard(
                              key: ValueKey(ad.id),
                              ad: ad,
                              onTap: () => _navigateToDetail(context, ad),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 24),
                favoritesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Error loading favorites',
                        style: GoogleFonts.montserrat(
                            fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ),
                  data: (favorites) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'My Favorites',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              '(${favorites.length})',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (favorites.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: const Color(0xFFE0E0E0)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.favorite_border,
                                    size: 40, color: Colors.black26),
                                const SizedBox(height: 8),
                                Text(
                                  'No favorites yet',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 14,
                              mainAxisExtent: 180,
                            ),
                            itemCount: favorites.length,
                            itemBuilder: (context, index) {
                              final fav = favorites[index];
                              return _AdCard(
                                key: ValueKey(fav.id),
                                ad: fav,
                                onTap: () => _navigateToDetail(context, fav),
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AdCard extends StatefulWidget {
  const _AdCard({super.key, required this.ad, this.onTap});
  final ListingModel ad;
  final VoidCallback? onTap;

  @override
  State<_AdCard> createState() => _AdCardState();
}

class _AdCardState extends State<_AdCard> {
  static const _blue = Color(0xFF2258A8);
  late PageController _pageController;
  Timer? _autoplayTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoplay();
  }

  void _startAutoplay() {
    if (widget.ad.images.length <= 1) return;
    _autoplayTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      try {
        if (_pageController.hasClients) {
          final nextPage = (_currentPage + 1) % widget.ad.images.length;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _autoplayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String _formatPrice() {
    if (widget.ad.price == null) return 'Price on request';
    final p = widget.ad.price!;
    final formatted = p >= 1000000
        ? '${(p / 1000000).toStringAsFixed(1)}M'
        : p >= 1000
            ? '${(p / 1000).toStringAsFixed(0)}K'
            : p.toStringAsFixed(0);
    return '${widget.ad.currency} $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.ad;

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: ad.images.isEmpty
                  ? Container(
                      color: const Color(0xFFEFF2F8),
                      child: const Icon(Icons.image_outlined,
                          color: Color(0xFF98A2B3)),
                    )
                  : PageView.builder(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemCount: ad.images.length,
                      itemBuilder: (_, i) => Image.network(
                        ad.images[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFEFF2F8),
                          child: const Icon(Icons.image_outlined),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatPrice(),
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _blue,
            ),
          ),
          Text(
            ad.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          Text(
            ad.city ?? 'Location',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingDetailView extends StatelessWidget {
  final ListingModel listing;
  const _ListingDetailView({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          listing.title,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images
            if (listing.images.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  listing.images.first,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 250,
                    color: const Color(0xFFEEEEEE),
                    child: const Icon(Icons.image_outlined, color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Price
            Text(
              listing.price != null
                  ? 'AFN ${listing.price}'
                  : 'Price on request',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2258A8),
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              listing.title,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            // Location
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: Colors.black54),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${listing.city ?? 'N/A'}, ${listing.region ?? 'N/A'}',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            const SizedBox(height: 16),
            // Description
            if (listing.description != null && listing.description!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    listing.description!,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            // Category
            Text(
              'Category: ${listing.category}',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            // Seller
            Text(
              'Seller: ${listing.sellerName}',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
