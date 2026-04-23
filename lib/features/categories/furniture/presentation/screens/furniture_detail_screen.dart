import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../features/listings/data/models/furniture_listing_model.dart';

const _kBlue = Color(0xFF2258A8);

class FurnitureDetailScreen extends StatefulWidget {
  final FurnitureListingModel item;
  const FurnitureDetailScreen({super.key, required this.item});

  @override
  State<FurnitureDetailScreen> createState() => _FurnitureDetailScreenState();
}

class _FurnitureDetailScreenState extends State<FurnitureDetailScreen> {
  int _currentImage = 0;
  bool _isFavorited = false;
  bool _showMore = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageSection(item),
                  _buildInfoSection(item),
                ],
              ),
            ),
          ),
          _buildActionBar(item),
        ],
      ),
    );
  }

  Widget _buildImageSection(FurnitureListingModel item) {
    final images = item.images.isEmpty ? <String>[] : item.images;
    return Stack(
      children: [
        SizedBox(
          height: 300,
          child: images.isEmpty
              ? Container(
                  color: const Color(0xFFEDEDED),
                  child: const Center(child: Icon(Icons.chair_outlined, color: Colors.grey, size: 60)),
                )
              : PageView.builder(
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
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.black87),
            ),
          ),
        ),
        // Image counter
        if (images.isNotEmpty)
          Positioned(
            bottom: 12, left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.camera_alt_outlined, size: 13, color: Colors.white),
                const SizedBox(width: 4),
                Text('${_currentImage + 1}/${images.length}',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.white)),
              ]),
            ),
          ),
        // Dots indicator
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) => Container(
                width: i == _currentImage ? 18 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: i == _currentImage ? _kBlue : Colors.white.withValues(alpha: 0.7),
                ),
              )),
            ),
          ),
        // Share + Favorite
        Positioned(
          bottom: 12, right: 12,
          child: Row(children: [
            _circleBtn(Icons.share_outlined, () {}),
            const SizedBox(width: 8),
            _circleBtn(
              _isFavorited ? Icons.favorite : Icons.favorite_border,
              () => setState(() => _isFavorited = !_isFavorited),
              color: _isFavorited ? Colors.red : Colors.black87,
            ),
          ]),
        ),
      ],
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {Color color = Colors.black87}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Color(0x30000000), blurRadius: 4)],
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildInfoSection(FurnitureListingModel item) {
    final allDetails = <_DetailRow>[
      if (item.itemShape.isNotEmpty) _DetailRow('Item Shape', item.itemShape),
      if (item.age.isNotEmpty) _DetailRow('Age', item.age),
      if (item.condition.isNotEmpty) _DetailRow('Condition', item.condition),
      if (item.color.isNotEmpty) _DetailRow('Color', item.color),
      if (item.usage.isNotEmpty) _DetailRow('Usage', item.usage),
      if (item.brand.isNotEmpty) _DetailRow('Brand', item.brand),
      if (item.shape.isNotEmpty) _DetailRow('Shape', item.shape),
      if (item.type.isNotEmpty) _DetailRow('Type', item.type),
      if (item.material.isNotEmpty) _DetailRow('Material', item.material),
      if (item.fillMaterial.isNotEmpty) _DetailRow('Fill Material', item.fillMaterial),
      if (item.roomType.isNotEmpty) _DetailRow('Room Type', item.roomType),
      _DetailRow('Posted On', item.formattedDate),
    ];

    final visibleDetails = _showMore ? allDetails : allDetails.take(5).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.formattedPrice,
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: _kBlue)),
          const SizedBox(height: 4),
          Text(item.title,
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87)),
          const SizedBox(height: 2),
          Text('Furniture${item.subcategoryLabel.isNotEmpty ? ' / ${item.subcategoryLabel}' : ''}',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black45)),
          const Divider(height: 24, color: Color(0xFFE8E8E8)),
          Text('Details',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...visibleDetails.map((r) => _buildDetailRow(r.label, r.value)),
          if (allDetails.length > 5)
            GestureDetector(
              onTap: () => setState(() => _showMore = !_showMore),
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Text(
                    _showMore ? 'Show less Details' : 'Show more Details',
                    style: GoogleFonts.poppins(fontSize: 13, color: _kBlue, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          if (item.description.isNotEmpty) ...[
            const Divider(height: 24, color: Color(0xFFE8E8E8)),
            Text('Description',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(item.description,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54, height: 1.5)),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(FurnitureListingModel item) {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x20000000), blurRadius: 12, offset: Offset(0, -4))],
      ),
      child: Row(children: [
        Expanded(child: _actionBtn(Icons.phone_outlined, 'Call', Colors.white, _kBlue,
            () => _launch('tel:${item.phone}'))),
        const SizedBox(width: 10),
        Expanded(child: _actionBtn(Icons.chat_bubble_outline, 'WhatsApp', _kBlue, Colors.white,
            () => _launch('https://wa.me/${item.phone.replaceAll(RegExp(r'[^0-9]'), '')}'))),
        const SizedBox(width: 10),
        Expanded(child: _actionBtn(Icons.sms_outlined, 'SMS', Colors.white, _kBlue,
            () => _launch('sms:${item.phone}'))),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color bg, Color fg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: _kBlue, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
        ]),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri);
  }
}

class _DetailRow {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);
}
