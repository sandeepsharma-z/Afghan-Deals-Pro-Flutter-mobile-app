import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../chat/presentation/providers/chat_provider.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../profile/presentation/providers/favorites_provider.dart';
import '../../data/models/property_listing_model.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  final PropertyListingModel property;
  const PropertyDetailScreen({super.key, required this.property});

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.property.images.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        final next = (_currentPage + 1) % widget.property.images.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );
        setState(() => _currentPage = next);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String get _formattedDate {
    final dt = DateTime.tryParse(widget.property.createdAt);
    if (dt == null) return widget.property.createdAt;
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${dt.day}th ${months[dt.month - 1]}, ${dt.year}';
  }

  void _shareItem() {
    final shareText =
        'Check out this property: ${widget.property.title} on Afghan Deals Pro';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Share Listing',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.copy, color: Color(0xFF2258A8)),
                title: Text('Copy to Clipboard',
                    style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: shareText));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copied: ${widget.property.title}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleFavorite() {
    final favorites = ref.read(favoritesProvider.notifier);
    final wasFavorite =
        ref.read(favoritesProvider).contains(widget.property.id);

    favorites.toggleFavorite(widget.property.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasFavorite ? 'Removed from Favorites' : 'Added to Favorites',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: wasFavorite ? Colors.red : Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.contains(p.id);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image slider ────────────────────────────────────────────
              Stack(
                children: [
                  SizedBox(
                    height: 312,
                    width: double.infinity,
                    child: p.images.isEmpty
                        ? Container(
                            color: const Color(0xFFE8E8E8),
                            child: const Icon(Icons.home_work_outlined,
                                size: 50, color: Colors.grey),
                          )
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: p.images.length,
                            onPageChanged: (i) =>
                                setState(() => _currentPage = i),
                            itemBuilder: (_, i) => Image.network(
                              p.images[i],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFE8E8E8),
                                child: const Icon(Icons.home_work_outlined,
                                    size: 50, color: Colors.grey),
                              ),
                            ),
                          ),
                  ),
                  // Back button
                  Positioned(
                    top: 12,
                    left: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 21,
                        height: 21,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            size: 12, color: Colors.black87),
                      ),
                    ),
                  ),
                  // Image counter
                  Positioned(
                    left: 14,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0x63000000),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.image_outlined,
                              color: Colors.white, size: 15),
                          const SizedBox(width: 4),
                          Text(
                            '${_currentPage + 1}/${p.images.isEmpty ? 1 : p.images.length}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 11.62,
                              fontWeight: FontWeight.w400,
                              height: 17.06 / 11.62,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Dot indicators
                  if (p.images.length > 1)
                    Positioned(
                      bottom: 14,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          p.images.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _currentPage ? 10 : 7,
                            height: i == _currentPage ? 10 : 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD9D9D9),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // ── Content ─────────────────────────────────────────────────
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Share + Favourite floating above
                    Transform.translate(
                      offset: const Offset(0, -14),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _TopCircleButton(
                              icon: Icons.reply_outlined,
                              onTap: _shareItem,
                            ),
                            const SizedBox(width: 10),
                            _TopCircleButton(
                              icon: isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              onTap: _toggleFavorite,
                              iconColor: isFavorite
                                  ? const Color(0xFFE53935)
                                  : const Color(0xFF222222),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Price
                    Text(
                      p.formattedPrice,
                      style: GoogleFonts.poppins(
                        fontSize: 17.88,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 24.24 / 17.88,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Beds / Baths / Area
                    Row(
                      children: [
                        if (p.bedrooms > 0) ...[
                          _DetailSpec(
                              icon: Icons.bed_outlined,
                              value: '${p.bedrooms} beds'),
                          const SizedBox(width: 14),
                        ],
                        if (p.bathrooms > 0) ...[
                          _DetailSpec(
                              icon: Icons.bathtub_outlined,
                              value: '${p.bathrooms} baths'),
                          const SizedBox(width: 14),
                        ],
                        if (p.area.isNotEmpty)
                          _DetailSpec(
                              icon: Icons.square_foot, value: '${p.area} sqft'),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 15, color: Color(0xFF505050)),
                        const SizedBox(width: 5),
                        Text(
                          p.location,
                          style: GoogleFonts.poppins(
                            fontSize: 11.62,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF505050),
                            height: 17.06 / 11.62,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(
                        height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
                    const SizedBox(height: 14),

                    // Description
                    Builder(
                      builder: (_) {
                        final raw = p.description.trim();
                        final clean = raw.isEmpty
                            ? 'No description available.'
                            : raw.replaceAll(RegExp(r'\s+'), ' ');
                        return SizedBox(
                          width: double.infinity,
                          child: Text(
                            clean,
                            softWrap: true,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF141414),
                              height: 1.6,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // Overview table
                    if (p.propertyType.isNotEmpty)
                      _overviewRow('Type', p.propertyType),
                    if (p.purpose.isNotEmpty)
                      _overviewRow('Purpose', p.purpose),
                    if (p.furnishing.isNotEmpty)
                      _overviewRow('Furnishing', p.furnishing),
                    _overviewRow('Updated', _formattedDate),
                    const SizedBox(height: 14),
                    const SizedBox(height: 2),

                    // Title
                    Text(
                      p.title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(
                        height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
                    const SizedBox(height: 14),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                            child: _detailAction(Icons.phone_outlined, 'Call')),
                        const SizedBox(width: 8),
                        Expanded(child: _whatsAppAction(onTap: _openChat)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _detailAction(
                                Icons.chat_bubble_outline, 'SMS',
                                onTap: _openChat)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overviewRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(k,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black)),
          ),
          SizedBox(
            width: 132,
            child: Text(v,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _openChat() async {
    try {
      final chatId =
          await ref.read(chatActionsProvider).openOrCreateChatForListing(
                listingId: widget.property.id,
                sellerId: widget.property.sellerId,
              );
      if (!mounted) return;
      context.push('/chat/$chatId');
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceAll('Exception: ', '');
      if (message.toLowerCase().contains('please sign in first')) {
        context.push(RouteNames.onboarding);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Widget _detailAction(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFD9D9D9)),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF2258A8)),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 14.24,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                    height: 25.12 / 14.24)),
          ],
        ),
      ),
    );
  }

  Widget _whatsAppAction({VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFD9D9D9)),
          color: Colors.white,
        ),
        child: const Center(
          child: FaIcon(FontAwesomeIcons.whatsapp,
              size: 16, color: Color(0xFF2258A8)),
        ),
      ),
    );
  }
}

class _TopCircleButton extends StatelessWidget {
  final IconData icon;
  final Function()? onTap;
  final Color? iconColor;
  const _TopCircleButton({required this.icon, this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 0)),
          ],
        ),
        child: Icon(icon, color: iconColor ?? const Color(0xFF222222), size: 14),
      ),
    );
  }
}

class _DetailSpec extends StatelessWidget {
  final IconData icon;
  final String value;
  const _DetailSpec({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF505050)),
        const SizedBox(width: 4),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 14.24,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF505050),
                height: 25.12 / 14.24)),
      ],
    );
  }
}
