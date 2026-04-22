import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../chat/presentation/providers/chat_provider.dart';
import '../../../../chat/presentation/screens/chat_detail_screen.dart';
import '../../../../../features/listings/data/models/electronics_listing_model.dart';

const _kBlue = Color(0xFF2258A8);

class ElectronicsDetailScreen extends ConsumerStatefulWidget {
  final ElectronicsListingModel item;
  const ElectronicsDetailScreen({super.key, required this.item});

  @override
  ConsumerState<ElectronicsDetailScreen> createState() =>
      _ElectronicsDetailScreenState();
}

class _ElectronicsDetailScreenState
    extends ConsumerState<ElectronicsDetailScreen> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  bool _chatLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.item.images.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        final next = (_currentPage + 1) % widget.item.images.length;
        _pageController.animateToPage(next,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic);
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
    final m = widget.item;
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
              Expanded(child: _actionBtn(Icons.phone_outlined, 'Call', () => _launchCall(m.phone))),
              const SizedBox(width: 8),
              Expanded(child: _whatsAppBtn(() => _launchWhatsApp(m.phone))),
              const SizedBox(width: 8),
              Expanded(child: _chatBtn()),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 312,
                    width: double.infinity,
                    child: m.images.isEmpty
                        ? Container(color: const Color(0xFFE8E8E8),
                            child: const Icon(Icons.devices_other, size: 50, color: Colors.grey))
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: m.images.length,
                            onPageChanged: (i) => setState(() => _currentPage = i),
                            itemBuilder: (_, i) => Image.network(m.images[i], fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE8E8E8),
                                    child: const Icon(Icons.devices_other, size: 50, color: Colors.grey))),
                          ),
                  ),
                  Positioned(
                    top: 12, left: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 21, height: 21,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back_ios_new, size: 12, color: Colors.black87),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14, bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0x63000000), borderRadius: BorderRadius.circular(7)),
                      child: Row(children: [
                        const Icon(Icons.image_outlined, color: Colors.white, size: 15),
                        const SizedBox(width: 4),
                        Text('${_currentPage + 1}/${m.images.isEmpty ? 1 : m.images.length}',
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w400)),
                      ]),
                    ),
                  ),
                  if (m.images.length > 1)
                    Positioned(
                      bottom: 14, left: 0, right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(m.images.length, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _currentPage ? 10 : 7,
                          height: i == _currentPage ? 10 : 7,
                          decoration: const BoxDecoration(color: Color(0xFFD9D9D9), shape: BoxShape.circle),
                        )),
                      ),
                    ),
                ],
              ),
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -14),
                      child: const Align(
                        alignment: Alignment.topRight,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          _CircleBtn(icon: Icons.reply_outlined),
                          SizedBox(width: 10),
                          _CircleBtn(icon: Icons.favorite_border),
                        ]),
                      ),
                    ),
                    Text(m.formattedPrice,
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
                    const SizedBox(height: 6),
                    Text(m.title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black)),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF505050)),
                      const SizedBox(width: 5),
                      Text(m.location, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF505050))),
                    ]),
                    const SizedBox(height: 14),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
                    const SizedBox(height: 14),
                    Text('Details', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
                    const SizedBox(height: 10),
                    if (m.condition.isNotEmpty) _detailRow('Condition', m.condition),
                    if (m.age.isNotEmpty) _detailRow('Age', m.age),
                    if (m.usage.isNotEmpty) _detailRow('Usage', m.usage),
                    if (m.warranty.isNotEmpty) _detailRow('Warranty', m.warranty),
                    _detailRow('Posted On', m.formattedDate),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _showAllDetails(context, m),
                      child: Center(
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('Show more Details',
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: _kBlue)),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, size: 18, color: _kBlue),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
                    const SizedBox(height: 14),
                    if (m.description.trim().isNotEmpty) ...[
                      Text('Description', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
                      const SizedBox(height: 8),
                      Text(m.description.trim().replaceAll(RegExp(r'\s+'), ' '),
                          textAlign: TextAlign.justify,
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFF141414), height: 1.6)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllDetails(BuildContext context, ElectronicsListingModel m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFD9D9D9), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Align(alignment: Alignment.centerLeft,
                  child: Text('Details', style: GoogleFonts.poppins(fontSize: 19, fontWeight: FontWeight.w600))),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: [
                  if (m.brand.isNotEmpty) 1,
                  if (m.model.isNotEmpty) 1,
                  if (m.condition.isNotEmpty) 1,
                  if (m.age.isNotEmpty) 1,
                  if (m.usage.isNotEmpty) 1,
                  if (m.warranty.isNotEmpty) 1,
                  if (m.sellerType.isNotEmpty) 1,
                  1,
                ].length,
                separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                itemBuilder: (_, i) {
                  final rows = [
                    if (m.brand.isNotEmpty) (label: 'Brand', value: m.brand),
                    if (m.model.isNotEmpty) (label: 'Model', value: m.model),
                    if (m.condition.isNotEmpty) (label: 'Condition', value: m.condition),
                    if (m.age.isNotEmpty) (label: 'Age', value: m.age),
                    if (m.usage.isNotEmpty) (label: 'Usage', value: m.usage),
                    if (m.warranty.isNotEmpty) (label: 'Warranty', value: m.warranty),
                    if (m.sellerType.isNotEmpty) (label: 'Seller Type', value: m.sellerType),
                    (label: 'Posted On', value: m.formattedDate),
                  ];
                  return _detailRow(rows[i].label, rows[i].value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Expanded(child: Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black))),
        SizedBox(width: 160, child: Text(value, style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF555555)))),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFD9D9D9)), color: Colors.white),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: _kBlue),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 14, color: Colors.black)),
        ]),
      ),
    );
  }

  Widget _whatsAppBtn(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFD9D9D9)), color: Colors.white),
        child: const Center(child: FaIcon(FontAwesomeIcons.whatsapp, size: 16, color: _kBlue)),
      ),
    );
  }

  Widget _chatBtn() {
    return GestureDetector(
      onTap: _chatLoading ? null : _openChat,
      child: Container(
        height: 38,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFD9D9D9)), color: Colors.white),
        child: Center(
          child: _chatLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _kBlue))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.chat_bubble_outline, size: 16, color: _kBlue),
                  const SizedBox(width: 8),
                  Text('Chat', style: GoogleFonts.poppins(fontSize: 14, color: Colors.black)),
                ]),
        ),
      ),
    );
  }

  Future<void> _openChat() async {
    if (_chatLoading) return;
    setState(() => _chatLoading = true);
    try {
      final chatId = await ref.read(chatActionsProvider).openOrCreateChatForListing(
            listingId: widget.item.id,
            sellerId: widget.item.sellerId,
          );
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatDetailScreen(chatId: chatId)));
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      if (msg.toLowerCase().contains('please sign in first')) {
        context.push(RouteNames.onboarding);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _chatLoading = false);
    }
  }

  Future<void> _launchCall(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    await launchUrl(Uri.parse('tel:${cleaned.isEmpty ? '+93700000000' : cleaned}'));
  }

  Future<void> _launchWhatsApp(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    await launchUrl(Uri.parse('https://wa.me/${cleaned.isEmpty ? '93700000000' : cleaned}'), mode: LaunchMode.externalApplication);
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  const _CircleBtn({required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24, height: 24,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 4)]),
      child: Icon(icon, color: const Color(0xFF222222), size: 14),
    );
  }
}
