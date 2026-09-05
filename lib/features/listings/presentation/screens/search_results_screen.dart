import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../categories/cars/presentation/screens/car_sale_detail_screen.dart';
import '../../../categories/classifieds/presentation/screens/classifieds_detail_screen.dart';
import '../../../categories/electronics/presentation/screens/electronics_detail_screen.dart';
import '../../../categories/furniture/presentation/screens/furniture_detail_screen.dart';
import '../../../categories/jobs/presentation/screens/jobs_detail_screen.dart';
import '../../../categories/mobiles/presentation/screens/mobile_detail_screen.dart';
import '../../../categories/properties/data/models/property_listing_model.dart';
import '../../../categories/properties/presentation/screens/property_detail_screen.dart';
import '../../../categories/spare_parts/presentation/providers/spare_parts_provider.dart';
import '../../../categories/spare_parts/presentation/screens/spare_parts_detail_screen.dart';
import '../../data/models/car_sale_model.dart';
import '../../data/models/classified_listing_model.dart';
import '../../data/models/electronics_listing_model.dart';
import '../../data/models/furniture_listing_model.dart';
import '../../data/models/jobs_listing_model.dart';
import '../../data/models/listing_model.dart';
import '../../data/models/mobile_listing_model.dart';
import '../../../../core/utils/image_url.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchResultsScreen extends StatefulWidget {
  final String initialQuery;

  const SearchResultsScreen({super.key, this.initialQuery = ''});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late final TextEditingController _searchCtrl;
  Timer? _debounce;
  bool _loading = false;
  List<ListingModel> _results = const [];

  static const _blue = Color(0xFF2258A8);

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialQuery);
    _searchCtrl.addListener(_onSearchChanged);
    if (widget.initialQuery.trim().isNotEmpty) {
      _search(widget.initialQuery);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search(_searchCtrl.text);
    });
  }

  Future<void> _search(String rawQuery) async {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _loading = false;
        _results = const [];
      });
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await Supabase.instance.client
          .from('listings')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(200);

      final items = (response as List)
          .map((row) => ListingModel.fromMap(row as Map<String, dynamic>))
          .where((item) => _matches(item, query))
          .toList();

      if (!mounted) return;
      setState(() => _results = items);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _matches(ListingModel item, String query) {
    final haystack = [
      item.title,
      item.description ?? '',
      item.category,
      item.subcategory ?? '',
      item.sellerName,
      item.country,
      item.region ?? '',
      item.city ?? '',
      ...item.categoryData.values.map((v) => v?.toString() ?? ''),
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }

  void _openListing(ListingModel item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _detailScreenFor(item)),
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
        return _UnknownListingScreen(listing: listing);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _searchCtrl.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: Colors.black87),
        ),
        title: Text(
          'Search',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFC2C2C2)),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                children: [
                  Image.asset('assets/images/logo.png',
                      height: 22, fit: BoxFit.contain),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _search,
                      decoration: InputDecoration(
                        hintText: 'Discover AFGHAN DEALS PRO Deal',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isCollapsed: true,
                        hintStyle: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: _searchCtrl.clear,
                      child: const Icon(Icons.close,
                          size: 18, color: Colors.black45),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _blue))
                : !hasQuery
                    ? _emptyState('Search listings across all categories')
                    : _results.isEmpty
                        ? _emptyState('No listings')
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
                            itemCount: _results.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) => _SearchResultCard(
                              item: _results[i],
                              onTap: () => _openListing(_results[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String text) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black45,
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final ListingModel item;
  final VoidCallback onTap;

  const _SearchResultCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final image = item.images.isNotEmpty ? item.images.first : '';
    final price = item.price == null
        ? ''
        : '${item.currency} ${item.price!.toStringAsFixed(item.price!.truncateToDouble() == item.price ? 0 : 2)}';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 94,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 7,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(8),
              ),
              child: SizedBox(
                width: 102,
                height: double.infinity,
                child: image.isEmpty
                    ? Container(
                        color: const Color(0xFFEDEDED),
                        child: const Icon(Icons.image_outlined,
                            color: Colors.black26),
                      )
                    : Image(image: CachedNetworkImageProvider(sizedImageUrl(image)),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFEDEDED),
                          child: const Icon(Icons.image_outlined,
                              color: Colors.black26),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (price.isNotEmpty)
                      Text(
                        price,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2258A8),
                        ),
                      ),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      [
                        item.category,
                        if ((item.city ?? '').trim().isNotEmpty) item.city!,
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnknownListingScreen extends StatelessWidget {
  final ListingModel listing;

  const _UnknownListingScreen({required this.listing});

  @override
  Widget build(BuildContext context) {
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
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Text(
            listing.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
