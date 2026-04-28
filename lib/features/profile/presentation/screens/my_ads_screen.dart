import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../features/listings/data/models/listing_model.dart';
import '../providers/favorites_provider.dart';

final favoriteListingsProvider =
    StreamProvider.autoDispose<List<ListingModel>>((ref) {
  final favorites = ref.watch(favoritesProvider);

  return Supabase.instance.client
      .from('listings')
      .stream(primaryKey: const ['id'])
      .map((rows) {
        final items = <ListingModel>[];
        for (final row in rows) {
          try {
            final map = Map<String, dynamic>.from(row);
            if (favorites.contains(map['id'])) {
              // Normalize data like myAdsProvider does
              map['seller_id'] = map['seller_id']?.toString() ?? '';
              map['seller_name'] = map['seller_name']?.toString() ?? '';
              map['category'] = map['category']?.toString() ?? '';
              map['title'] = map['title']?.toString() ?? 'Untitled';
              map['currency'] = map['currency']?.toString() ?? 'AFN';
              map['images'] = (map['images'] as List<dynamic>?) ?? <dynamic>[];
              map['country'] = map['country']?.toString() ?? 'Afghanistan';
              map['category_data'] =
                  (map['category_data'] as Map<String, dynamic>?) ??
                      <String, dynamic>{};
              map['created_at'] =
                  map['created_at']?.toString() ?? DateTime.now().toIso8601String();

              final listing = ListingModel.fromMap(map);
              items.add(listing);
            }
          } catch (e) {
            // Log error but continue processing other items
            debugPrint('Error converting favorite listing: $e');
          }
        }
        return items;
      });
});

final myAdsProvider = StreamProvider.autoDispose<List<ListingModel>>((ref) {
  final me = Supabase.instance.client.auth.currentUser;
  if (me == null) return Stream.value(const <ListingModel>[]);

  return Supabase.instance.client
      .from('listings')
      .stream(primaryKey: const ['id'])
      .eq('seller_id', me.id)
      .order('created_at', ascending: false)
      .map((rows) {
        final items = <ListingModel>[];
        for (final row in rows) {
          final map = Map<String, dynamic>.from(row);
          map['seller_id'] = map['seller_id']?.toString() ?? me.id;
          map['seller_name'] = map['seller_name']?.toString() ?? '';
          map['category'] = map['category']?.toString() ?? '';
          map['title'] = map['title']?.toString() ?? 'Untitled';
          map['currency'] = map['currency']?.toString() ?? 'AFN';
          map['images'] = (map['images'] as List<dynamic>?) ?? <dynamic>[];
          map['country'] = map['country']?.toString() ?? 'Afghanistan';
          map['category_data'] =
              (map['category_data'] as Map<String, dynamic>?) ??
                  <String, dynamic>{};
          map['created_at'] =
              map['created_at']?.toString() ?? DateTime.now().toIso8601String();
          try {
            items.add(ListingModel.fromMap(map));
          } catch (_) {}
        }
        return items;
      });
});

class MyAdsScreen extends ConsumerStatefulWidget {
  const MyAdsScreen({super.key});

  @override
  ConsumerState<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends ConsumerState<MyAdsScreen> {
  bool _showAllAds = false;

  @override
  Widget build(BuildContext context) {
    final adsAsync = ref.watch(myAdsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE8E8E8), width: 1),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Center(
                    child: Text(
                      'My Ads',
                      style: GoogleFonts.montserrat(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: adsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
              data: (ads) {
                try {
                  return ref.watch(favoriteListingsProvider).when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, st) {
                          debugPrint('Favorites error: $e');
                          debugPrintStack(stackTrace: st);
                          return _buildContent(ads, []);
                        },
                        data: (favorites) => _buildContent(ads, favorites),
                      );
                } catch (e, st) {
                  debugPrint('Favorites watch error: $e');
                  debugPrintStack(stackTrace: st);
                  return _buildContent(ads, []);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      List<ListingModel> ads, List<ListingModel> favorites) {
    if (ads.isEmpty && favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 58,
              color: Colors.black26,
            ),
            const SizedBox(height: 12),
            Text(
              'No ads yet',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap SELL to post your first listing.',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      );
    }

    final displayAds = _showAllAds ? ads : ads.take(2).toList();

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myAdsProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ads.isNotEmpty) ...[
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All My Ads',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${ads.length} ad${ads.length == 1 ? '' : 's'}',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (ads.length > 2)
                    GestureDetector(
                      onTap: () {
                        setState(() => _showAllAds = !_showAllAds);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _showAllAds ? 'Show Less' : 'View All',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          if (!_showAllAds) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: Colors.black87,
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.builder(
                itemCount: displayAds.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 14,
                  mainAxisExtent: 164,
                ),
                itemBuilder: (context, index) {
                  return _AdCard(ad: displayAds[index]);
                },
              ),
              const SizedBox(height: 26),
            ],
            if (favorites.isNotEmpty) ...[
              Text(
                'Favorites',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                itemCount: favorites.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 14,
                  mainAxisExtent: 164,
                ),
                itemBuilder: (context, index) {
                  try {
                    return _AdCard(ad: favorites[index]);
                  } catch (e) {
                    debugPrint('Error building favorite card: $e');
                    return const SizedBox.shrink();
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdCard extends StatefulWidget {
  const _AdCard({required this.ad});
  final ListingModel ad;

  @override
  State<_AdCard> createState() => _AdCardState();
}

class _AdCardState extends State<_AdCard> {
  static const _blue = Color(0xFF2258A8);
  late final PageController _pageController;
  Timer? _autoplayTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _configureAutoplay();
  }

  @override
  void didUpdateWidget(covariant _AdCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ad.id != widget.ad.id ||
        oldWidget.ad.images.length != widget.ad.images.length) {
      _currentPage = 0;
      _configureAutoplay();
    }
  }

  @override
  void dispose() {
    _autoplayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _configureAutoplay() {
    _autoplayTimer?.cancel();
    if (widget.ad.images.length <= 1) return;
    _autoplayTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final total = widget.ad.images.length;
      if (total <= 1 || !_pageController.hasClients) return;
      final next = (_currentPage + 1) % total;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    });
  }

  String _formatPrice() {
    final ad = widget.ad;
    if (ad.price == null) return 'Price on request';
    final p = ad.price!;
    final formatted = p >= 1000000
        ? '${(p / 1000000).toStringAsFixed(1)}M'
        : p >= 1000
            ? '${(p / 1000).toStringAsFixed(0)}K'
            : p.toStringAsFixed(0);
    return '${ad.currency} $formatted';
  }

  String _meta() {
    final ad = widget.ad;
    final year = ad.categoryData['year']?.toString().trim();
    final km = ad.categoryData['km']?.toString().trim() ??
        ad.categoryData['mileage']?.toString().trim();
    if ((year == null || year.isEmpty) && (km == null || km.isEmpty)) {
      return ad.city ?? '';
    }
    if (km == null || km.isEmpty) return year ?? '';
    if (year == null || year.isEmpty) return km;
    return '$year  $km';
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.ad;
    final images = ad.images;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 102,
                width: double.infinity,
                child: images.isEmpty
                    ? _placeholder()
                    : PageView.builder(
                        controller: _pageController,
                        itemCount: images.length,
                        onPageChanged: (index) {
                          if (mounted) setState(() => _currentPage = index);
                        },
                        itemBuilder: (context, index) {
                          return Image.network(
                            images[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          );
                        },
                      ),
              ),
            ),
            const Positioned(
              top: 6,
              right: 6,
              child: Icon(
                Icons.favorite,
                color: Color(0xFFE53935),
                size: 18,
              ),
            ),
            Positioned(
              bottom: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.photo_camera_outlined,
                      color: Colors.white,
                      size: 10.5,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${images.length}',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          _formatPrice(),
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _blue,
          ),
        ),
        const SizedBox(height: 2),
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
          _meta(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
        width: double.infinity,
        color: const Color(0xFFEFF2F8),
        child: const Icon(
          Icons.image_outlined,
          color: Color(0xFF98A2B3),
          size: 26,
        ),
      );
}

