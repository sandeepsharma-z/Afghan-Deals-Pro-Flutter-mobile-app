import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/favorite_button.dart';
import '../providers/spare_parts_provider.dart';
import 'spare_parts_detail_screen.dart';
import 'spare_parts_models_screen.dart';
import 'spare_parts_results_screen.dart';

const _kBlue = Color(0xFF2258A8);

class SparePartsScreen extends ConsumerStatefulWidget {
  const SparePartsScreen({super.key});

  @override
  ConsumerState<SparePartsScreen> createState() => _SparePartsScreenState();
}

class _SparePartsScreenState extends ConsumerState<SparePartsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final brandsAsync = ref.watch(sparePartBrandsProvider);
    final listingsAsync = ref.watch(
      sparePartListingsProvider(
        SparePartFilter(search: _search.trim().isEmpty ? null : _search),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Spare Parts',
          style: GoogleFonts.poppins(
            fontSize: 30 / 2,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () => context.push(
                  RouteNames.postAd.replaceAll(':category', 'spare-parts'),
                ),
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: _kBlue, width: 1),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_business_outlined,
                          size: 14, color: _kBlue),
                      const SizedBox(width: 5),
                      Text(
                        'Add Shop',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _kBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
        ),
      ),
      body: brandsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kBlue)),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: GoogleFonts.poppins(color: Colors.red, fontSize: 12),
          ),
        ),
        data: (brands) {
          final filtered = _search.trim().isEmpty
              ? brands
              : brands
                  .where(
                    (b) => b.name
                        .toLowerCase()
                        .contains(_search.trim().toLowerCase()),
                  )
                  .toList();

          final topBrands = filtered.take(7).toList();

          return listingsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: _kBlue)),
            error: (e, _) => Center(
              child: Text('Error: $e',
                  style: GoogleFonts.poppins(color: Colors.red, fontSize: 12)),
            ),
            data: (listings) {
              final topListings = listings.take(6).toList();
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Make',
                      style: GoogleFonts.poppins(
                        fontSize: 30 / 2,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SearchBox(
                      onChanged: (value) => setState(() => _search = value),
                    ),
                    const SizedBox(height: 20),
                    GridView.builder(
                      itemCount: topBrands.length + 1,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.95,
                      ),
                      itemBuilder: (_, i) {
                        if (i == topBrands.length) {
                          return _BrandTile(
                            label: 'More',
                            selected: false,
                            onTap: () {},
                            child: const Icon(Icons.more_horiz,
                                size: 24, color: _kBlue),
                          );
                        }
                        final brand = topBrands[i];
                        return _BrandTile(
                          label: brand.name,
                          selected: false,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    SparePartsModelsScreen(brand: brand),
                              ),
                            );
                          },
                          child: _BrandLogo(brand: brand, selected: false),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    _TopDealsHeader(
                      onSeeAll: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SparePartsResultsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (topListings.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('No spare parts found',
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: Colors.black45)),
                        ),
                      )
                    else
                      GridView.builder(
                        itemCount: topListings.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent: 176,
                        ),
                        itemBuilder: (_, i) =>
                            _SparePartMiniCard(listing: topListings[i]),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TopDealsHeader extends StatelessWidget {
  final VoidCallback onSeeAll;
  const _TopDealsHeader({required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Top Deals',
            style: GoogleFonts.poppins(
                fontSize: 14.75, fontWeight: FontWeight.w600)),
        const Spacer(),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onSeeAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text('See all',
                style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w500)),
          ),
        ),
      ],
    );
  }
}

class _SparePartMiniCard extends StatelessWidget {
  final SparePartListing listing;
  const _SparePartMiniCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SparePartsDetailScreen(listing: listing),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7.38),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 4.22,
              offset: Offset(0, 1.05),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 101.27,
                  width: double.infinity,
                  child: listing.images.isEmpty
                      ? const ColoredBox(
                          color: Color(0xFFF0F0F0),
                          child: Center(
                            child: Icon(Icons.build_outlined,
                                color: Colors.grey, size: 40),
                          ),
                        )
                      : Image.network(
                          listing.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Color(0xFFF0F0F0),
                            child: Center(
                              child: Icon(Icons.build_outlined,
                                  color: Colors.grey, size: 40),
                            ),
                          ),
                        ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: FavoriteButton(
                    listingId: listing.id,
                    size: 24,
                    backgroundColor: const Color(0x100F172A),
                    showShadow: false,
                    unselectedIconColor: Colors.white,
                    selectedIconColor: Colors.red,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.formattedPrice,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: _kBlue,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: Color(0xFF505050)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          listing.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: const Color(0xFF505050),
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                          ),
                        ),
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
}

class _SearchBox extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBox({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 39,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFC2C2C2), width: 1),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Row(
        children: [
          const SizedBox(width: 11),
          const Icon(Icons.search, size: 15, color: Color(0xFF1E1E1E)),
          const SizedBox(width: 7),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                hintText: 'Search',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF1E1E1E),
                  fontWeight: FontWeight.w400,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _BrandTile extends StatelessWidget {
  final String label;
  final bool selected;
  final Widget child;
  final VoidCallback onTap;

  const _BrandTile({
    required this.label,
    required this.selected,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: _kBlue, width: selected ? 2 : 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: child),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11.6,
              color: Colors.black87,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  final SparePartBrand brand;
  final bool selected;
  const _BrandLogo({required this.brand, required this.selected});

  @override
  Widget build(BuildContext context) {
    final url = brand.logoUrl;

    if (url == null || url.isEmpty) {
      return Icon(
        Icons.directions_car_outlined,
        color: selected ? _kBlue : const Color(0xFF2258A8),
        size: 22,
      );
    }

    if (url.toLowerCase().contains('.svg')) {
      return SvgPicture.network(
        url,
        width: 26,
        height: 26,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => Icon(
          Icons.directions_car_outlined,
          color: selected ? _kBlue : const Color(0xFF2258A8),
          size: 22,
        ),
      );
    }

    return Image.network(
      url,
      width: 26,
      height: 26,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.directions_car_outlined,
        color: selected ? _kBlue : const Color(0xFF2258A8),
        size: 22,
      ),
    );
  }
}
