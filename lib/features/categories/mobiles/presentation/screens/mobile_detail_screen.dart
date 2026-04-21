import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../chat/presentation/providers/chat_provider.dart';
import '../../../../chat/presentation/screens/chat_detail_screen.dart';
import '../../../../../features/listings/data/models/mobile_listing_model.dart';

class MobileDetailScreen extends ConsumerStatefulWidget {
  final MobileListingModel mobile;
  const MobileDetailScreen({super.key, required this.mobile});

  @override
  ConsumerState<MobileDetailScreen> createState() => _MobileDetailScreenState();
}

class _MobileDetailScreenState extends ConsumerState<MobileDetailScreen> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  bool _chatLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.mobile.images.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        final next = (_currentPage + 1) % widget.mobile.images.length;
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

  @override
  Widget build(BuildContext context) {
    final m = widget.mobile;
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE8E8E8))),
          ),
          child: Row(
            children: [
              Expanded(child: _detailAction(Icons.phone_outlined, 'Call')),
              const SizedBox(width: 8),
              Expanded(child: _whatsAppAction(onTap: _openChat)),
              const SizedBox(width: 8),
              Expanded(
                child: _chatButton(),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image slider ──────────────────────────────────────────────
              Stack(
                children: [
                  SizedBox(
                    height: 312,
                    width: double.infinity,
                    child: m.images.isEmpty
                        ? Container(
                            color: const Color(0xFFE8E8E8),
                            child: const Icon(Icons.smartphone,
                                size: 50, color: Colors.grey),
                          )
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: m.images.length,
                            onPageChanged: (i) =>
                                setState(() => _currentPage = i),
                            itemBuilder: (_, i) => Image.network(
                              m.images[i],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFE8E8E8),
                                child: const Icon(Icons.smartphone,
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
                            '${_currentPage + 1}/${m.images.isEmpty ? 1 : m.images.length}',
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
                  if (m.images.length > 1)
                    Positioned(
                      bottom: 14,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          m.images.length,
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

              // ── Content ───────────────────────────────────────────────────
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Share + Favourite
                    Transform.translate(
                      offset: const Offset(0, -14),
                      child: const Align(
                        alignment: Alignment.topRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _TopCircleButton(icon: Icons.reply_outlined),
                            SizedBox(width: 10),
                            _TopCircleButton(icon: Icons.favorite_border),
                          ],
                        ),
                      ),
                    ),

                    // Price
                    Text(
                      m.formattedPrice,
                      style: GoogleFonts.poppins(
                        fontSize: 17.88,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 24.24 / 17.88,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      m.title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 15, color: Color(0xFF505050)),
                        const SizedBox(width: 5),
                        Text(
                          m.location,
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

                    // Details section header
                    Text(
                      'Details',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Always-visible detail rows (no dividers on main screen)
                    if (m.color.isNotEmpty) _detailRow('Color', m.color),
                    if (m.age.isNotEmpty) _detailRow('Age', m.age),
                    if (m.storage.isNotEmpty)
                      _detailRow('Storage Capacity', m.storage),
                    if (m.warranty.isNotEmpty)
                      _detailRow('Warranty', m.warranty),
                    _detailRow('Posted On', m.formattedDate),

                    const SizedBox(height: 10),

                    // Show more Details → opens bottom sheet
                    GestureDetector(
                      onTap: () => _showAllDetailsSheet(context, m),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Show more Details',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF2258A8),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              size: 18,
                              color: Color(0xFF2258A8),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(
                        height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
                    const SizedBox(height: 14),

                    // Description
                    if (m.description.trim().isNotEmpty) ...[
                      Text(
                        'Description',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              m.description
                                  .trim()
                                  .replaceAll(RegExp(r'\s+'), ' '),
                              softWrap: true,
                              textAlign: TextAlign.justify,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF141414),
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(
                          height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
                      const SizedBox(height: 14),
                    ],

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllDetailsSheet(BuildContext context, MobileListingModel m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Details',
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            // All rows — fits content, dividers only between rows
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: _detailsList([
                if (m.color.isNotEmpty) (label: 'Color', value: m.color),
                if (m.age.isNotEmpty) (label: 'Age', value: m.age),
                if (m.storage.isNotEmpty)
                  (label: 'Storage Capacity', value: m.storage),
                if (m.warranty.isNotEmpty)
                  (label: 'Warranty', value: m.warranty),
                if (m.batteryHealth.isNotEmpty)
                  (
                    label: 'Percentage of Battery Health',
                    value: m.batteryHealth
                  ),
                if (m.condition.isNotEmpty)
                  (label: 'Condition', value: m.condition),
                if (m.version.isNotEmpty) (label: 'Version', value: m.version),
                if (m.damageDetails.isNotEmpty)
                  (label: 'Damages On Device', value: m.damageDetails),
                if (m.screenSize.isNotEmpty)
                  (label: 'Screen Size', value: m.screenSize),
                if (m.model.isNotEmpty) (label: 'Model', value: m.model),
                (label: 'Posted On', value: m.formattedDate),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(
            width: 160,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF555555),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsList(List<({String label, String value})> rows) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
      itemBuilder: (_, i) => _detailRow(rows[i].label, rows[i].value),
    );
  }

  Future<void> _openChat() async {
    if (_chatLoading) return;
    setState(() => _chatLoading = true);
    try {
      final chatId =
          await ref.read(chatActionsProvider).openOrCreateChatForListing(
                listingId: widget.mobile.id,
                sellerId: widget.mobile.sellerId,
              );
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatDetailScreen(chatId: chatId),
      ));
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceAll('Exception: ', '');
      if (message.toLowerCase().contains('please sign in first')) {
        context.push(RouteNames.onboarding);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _chatLoading = false);
    }
  }

  Widget _chatButton() {
    return GestureDetector(
      onTap: _chatLoading ? null : _openChat,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFD9D9D9)),
          color: Colors.white,
        ),
        child: Center(
          child: _chatLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2258A8),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_bubble_outline,
                        size: 16, color: Color(0xFF2258A8)),
                    const SizedBox(width: 8),
                    Text(
                      'Chat',
                      style: GoogleFonts.poppins(
                        fontSize: 14.24,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
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
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14.24,
                fontWeight: FontWeight.w400,
                color: Colors.black,
                height: 25.12 / 14.24,
              ),
            ),
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
  const _TopCircleButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Icon(icon, color: const Color(0xFF222222), size: 14),
    );
  }
}
