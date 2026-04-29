import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../features/listings/data/models/listing_model.dart';

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
      items.add(ListingModel.fromMap(row as Map<String, dynamic>));
    } catch (e) {
      debugPrint('Error mapping ad: $e');
    }
  }
  return items;
});

class MyAdsScreen extends ConsumerWidget {
  const MyAdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(myAdsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
          if (ads.isEmpty) {
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

          return GridView.builder(
            padding: const EdgeInsets.all(14),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 14,
              mainAxisExtent: 200,
            ),
            itemCount: ads.length,
            itemBuilder: (context, index) {
              final ad = ads[index];
              return _AdCard(key: ValueKey(ad.id), ad: ad);
            },
          );
        },
      ),
    );
  }
}

class _AdCard extends StatefulWidget {
  const _AdCard({super.key, required this.ad});
  final ListingModel ad;

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

    return Column(
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
                    child: const Icon(Icons.image_outlined, color: Color(0xFF98A2B3)),
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
    );
  }
}
