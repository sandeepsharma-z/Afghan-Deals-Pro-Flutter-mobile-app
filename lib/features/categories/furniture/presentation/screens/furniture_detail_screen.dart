import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../features/listings/data/models/furniture_listing_model.dart';

class FurnitureDetailScreen extends StatefulWidget {
  final FurnitureListingModel item;
  const FurnitureDetailScreen({super.key, required this.item});

  @override
  State<FurnitureDetailScreen> createState() => _FurnitureDetailScreenState();
}

class _FurnitureDetailScreenState extends State<FurnitureDetailScreen> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentImage = 0;
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    if (widget.item.images.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        final next = (_currentImage + 1) % widget.item.images.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );
        setState(() => _currentImage = next);
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
    final item = widget.item;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(item),
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -14),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _circleButton(icon: Icons.reply_outlined, onTap: _shareItem),
                            const SizedBox(width: 10),
                            _circleButton(
                              icon: _isFavorited ? Icons.favorite : Icons.favorite_border,
                              onTap: () => setState(() => _isFavorited = !_isFavorited),
                              color: _isFavorited ? Colors.red : Colors.black87,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Price
                    Text(item.formattedPrice,
                        style: GoogleFonts.poppins(fontSize: 17.88, fontWeight: FontWeight.w600, color: Colors.black, height: 24.24 / 17.88)),
                    const SizedBox(height: 4),
                    // Title
                    Text(item.title,
                        style: GoogleFonts.poppins(fontSize: 17.24, fontWeight: FontWeight.w400, color: const Color(0xFF141414), height: 31.04 / 17.24)),
                    const SizedBox(height: 6),
                    // Subtitle
                    Text('Furniture${item.subcategoryLabel.isNotEmpty ? ' / ${item.subcategoryLabel}' : ''}',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.black45)),
                    const SizedBox(height: 8),
                    // Location
                    Row(children: [
                      const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF505050)),
                      const SizedBox(width: 5),
                      Text(item.location,
                          style: GoogleFonts.poppins(fontSize: 11.62, fontWeight: FontWeight.w400, color: const Color(0xFF505050), height: 17.06 / 11.62)),
                    ]),
                    const SizedBox(height: 14),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
                    const SizedBox(height: 14),
                    // Description
                    if (item.description.isNotEmpty)
                      Text(item.description,
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFF141414), height: 1.6)),
                    if (item.description.isNotEmpty) const SizedBox(height: 14),
                    if (item.description.isNotEmpty) const Divider(height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
                    if (item.description.isNotEmpty) const SizedBox(height: 14),
                    // Details
                    if (item.age.isNotEmpty) _detailOverviewRow('Age', item.age),
                    if (item.condition.isNotEmpty) _detailOverviewRow('Condition', item.condition),
                    if (item.color.isNotEmpty) _detailOverviewRow('Color', item.color),
                    if (item.usage.isNotEmpty) _detailOverviewRow('Usage', item.usage),
                    if (item.brand.isNotEmpty) _detailOverviewRow('Brand', item.brand),
                    if (item.material.isNotEmpty) _detailOverviewRow('Material', item.material),
                    _detailOverviewRow('Posted', item.formattedDate),
                    const SizedBox(height: 14),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
                    const SizedBox(height: 14),
                    // Actions
                    Row(children: [
                      Expanded(child: _detailAction(Icons.phone_outlined, 'Call', onTap: () => _launch('tel:${item.phone}'))),
                      const SizedBox(width: 8),
                      Expanded(child: _whatsAppAction(onTap: () => _launch('https://wa.me/${item.phone.replaceAll(RegExp(r'[^0-9]'), '')}'))),
                      const SizedBox(width: 8),
                      Expanded(child: _detailAction(Icons.sms_outlined, 'SMS', onTap: () => _launch('sms:${item.phone}'))),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(FurnitureListingModel item) {
    final images = item.images.isEmpty ? <String>[] : item.images;
    return Stack(
      children: [
        SizedBox(
          height: 280,
          child: images.isEmpty
              ? Container(
                  color: const Color(0xFFEDEDED),
                  child: const Center(child: Icon(Icons.chair_outlined, color: Colors.grey, size: 60)),
                )
              : PageView.builder(
                  controller: _pageController,
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _currentImage = i),
                  itemBuilder: (_, i) => Image.network(
                    images[i],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFEDEDED),
                      child: const Center(child: Icon(Icons.chair_outlined, color: Colors.grey, size: 60)),
                    ),
                  ),
                ),
        ),
        // Back button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 21, height: 21,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 12, color: Colors.black87),
            ),
          ),
        ),
        // Image counter
        if (images.isNotEmpty)
          Positioned(
            bottom: 12, left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0x63000000),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(children: [
                const Icon(Icons.image_outlined, size: 15, color: Colors.white),
                const SizedBox(width: 4),
                Text('${_currentImage + 1}/${images.length}',
                    style: GoogleFonts.poppins(fontSize: 11.62, fontWeight: FontWeight.w400, color: Colors.white, height: 17.06 / 11.62)),
              ]),
            ),
          ),
        // Dots indicator
        if (images.length > 1)
          Positioned(
            bottom: 14,
            left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _currentImage ? 10 : 7,
                height: i == _currentImage ? 10 : 7,
                decoration: const BoxDecoration(
                  color: Color(0xFFD9D9D9),
                  shape: BoxShape.circle,
                ),
              )),
            ),
          ),
      ],
    );
  }

  void _shareItem() {
    final itemName = widget.item.title;
    final shareText = 'Check out this furniture: $itemName - ${widget.item.formattedPrice} on Afghan Deals Pro';

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
                      content: Text('Copied: $itemName'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.message, color: Color(0xFF2258A8)),
                title: Text('Share via Message',
                    style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Shared: $itemName'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.link, color: Color(0xFF2258A8)),
                title: Text('Copy Link',
                    style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: 'afghan-deals-pro://furniture/${widget.item.id}'),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Link copied for $itemName'),
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

  Widget _detailOverviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(child: Text(label, style: GoogleFonts.poppins(fontSize: 17.24, fontWeight: FontWeight.w400, color: Colors.black, height: 25.12 / 17.24))),
        SizedBox(width: 132, child: Text(value, style: GoogleFonts.poppins(fontSize: 17.24, fontWeight: FontWeight.w600, color: Colors.black, height: 25.12 / 17.24))),
      ]),
    );
  }

  Widget _circleButton({required IconData icon, Color color = Colors.black87, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x30000000), blurRadius: 4)],
        ),
        child: Icon(icon, size: 18, color: color),
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
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 14.24,
                    fontWeight: FontWeight.w400,
                    color: Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _whatsAppAction({required VoidCallback onTap}) {
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
            const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF2258A8)),
            const SizedBox(width: 8),
            Text('WhatsApp',
                style: GoogleFonts.poppins(
                    fontSize: 14.24,
                    fontWeight: FontWeight.w400,
                    color: Colors.black)),
          ],
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri);
  }
}
