import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../features/listings/data/models/electronics_listing_model.dart';
import '../providers/electronics_provider.dart';
import 'electronics_detail_screen.dart';
import 'electronics_filter_screen.dart';

const _kBlue = Color(0xFF2258A8);

class ElectronicsListingsScreen extends ConsumerStatefulWidget {
  final String subcategory;
  final String subcategoryLabel;
  const ElectronicsListingsScreen({
    super.key,
    required this.subcategory,
    required this.subcategoryLabel,
  });

  @override
  ConsumerState<ElectronicsListingsScreen> createState() =>
      _ElectronicsListingsScreenState();
}

class _ElectronicsListingsScreenState
    extends ConsumerState<ElectronicsListingsScreen> {
  String _sortBy = 'newest';

  @override
  Widget build(BuildContext context) {
    final listingsAsync =
        ref.watch(electronicsFilteredProvider(widget.subcategory));
    final filter = ref.watch(electronicsFilterProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
        ),
        title: Text(
          widget.subcategoryLabel,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: () => _showSortSheet(context),
            icon: SvgPicture.asset('assets/icons/bars_sort.svg', width: 20, height: 20),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ElectronicsFilterScreen(subcategory: widget.subcategory),
                  ));
                },
                icon: const Icon(Icons.tune, color: Colors.black87),
              ),
              if (!filter.isEmpty)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: _kBlue, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: listingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _kBlue)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (listings) {
          if (listings.isEmpty) {
            return const Center(
              child: Text('No listings found', style: TextStyle(color: Colors.black45)),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 240,
            ),
            itemCount: listings.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ElectronicsDetailScreen(item: listings[i]),
              )),
              child: _ListingCard(item: listings[i]),
            ),
          );
        },
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final options = [
          ('newest', 'Newest to Oldest'),
          ('oldest', 'Oldest to Newest'),
          ('price_high', 'Price Highest to Lowest'),
          ('price_low', 'Price Lowest to Highest'),
        ];
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Sort', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            ...options.map((opt) => ListTile(
              title: Text(opt.$2, style: GoogleFonts.poppins(fontSize: 14)),
              trailing: _sortBy == opt.$1
                  ? const Icon(Icons.check, color: _kBlue)
                  : null,
              onTap: () {
                setState(() => _sortBy = opt.$1);
                ref.read(electronicsFilterProvider.notifier).update(
                  (f) => f.copyWith(sortBy: opt.$1),
                );
                Navigator.of(context).pop();
              },
            )),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _ListingCard extends StatelessWidget {
  final ElectronicsListingModel item;
  const _ListingCard({required this.item});

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
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(7.38), topRight: Radius.circular(7.38),
                ),
                child: item.images.isEmpty
                    ? _placeholder()
                    : Image.network(item.imageUrl, height: 110, width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder()),
              ),
              Positioned(
                top: 6, left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                  child: Text(item.timeAgo, style: GoogleFonts.poppins(fontSize: 9, color: Colors.white)),
                ),
              ),
              Positioned(
                top: 6, right: 6,
                child: Container(
                  width: 26, height: 26,
                  decoration: const BoxDecoration(color: Color(0x20000000), shape: BoxShape.circle),
                  child: const Icon(Icons.favorite_border, size: 13, color: Colors.white),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.formattedPrice,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _kBlue)),
                const SizedBox(height: 2),
                Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w400, color: Colors.black87)),
                if (item.age.isNotEmpty || item.brand.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    [if (item.age.isNotEmpty) 'Age: ${item.age}', if (item.brand.isNotEmpty) item.brand].join(' · '),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 11, color: Color(0xFF505050)),
                  const SizedBox(width: 2),
                  Expanded(child: Text(item.location, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF505050)))),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: _actionBtn(Icons.phone_outlined, () => _call(item.phone))),
                  const SizedBox(width: 6),
                  Expanded(child: _waBtn(() => _whatsapp(item.phone))),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFD9D9D9))),
        child: Center(child: Icon(icon, size: 14, color: _kBlue)),
      ),
    );
  }

  Widget _waBtn(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFD9D9D9))),
        child: const Center(child: FaIcon(FontAwesomeIcons.whatsapp, size: 14, color: _kBlue)),
      ),
    );
  }

  Widget _placeholder() => Container(
      height: 110, color: const Color(0xFFEDEDED),
      child: const Center(child: Icon(Icons.devices_other, color: Colors.grey, size: 34)));

  void _call(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    launchUrl(Uri.parse('tel:${cleaned.isEmpty ? '+93700000000' : cleaned}'));
  }

  void _whatsapp(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    launchUrl(Uri.parse('https://wa.me/${cleaned.isEmpty ? '93700000000' : cleaned}'),
        mode: LaunchMode.externalApplication);
  }
}
