import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../features/listings/data/models/jobs_listing_model.dart';

const _kBlue = Color(0xFF2258A8);

class JobsDetailScreen extends StatefulWidget {
  final JobsListingModel item;
  const JobsDetailScreen({super.key, required this.item});

  @override
  State<JobsDetailScreen> createState() => _JobsDetailScreenState();
}

class _JobsDetailScreenState extends State<JobsDetailScreen> {
  bool _isFavorited = false;
  int _currentImage = 0;

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
                  _buildTopSection(item),
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

  Widget _buildTopSection(JobsListingModel item) {
    final images = item.images;
    if (images.isEmpty) {
      // No image — show minimal header with back + actions
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
              ),
              const Spacer(),
              _circleBtn(Icons.share_outlined, () {}),
              const SizedBox(width: 8),
              _circleBtn(
                _isFavorited ? Icons.favorite : Icons.favorite_border,
                () => setState(() => _isFavorited = !_isFavorited),
                color: _isFavorited ? Colors.red : Colors.black87,
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _currentImage = i),
            itemBuilder: (_, i) => Image.network(
              images[i],
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFEDEDED),
                child: const Center(child: Icon(Icons.work_outline, color: Colors.grey, size: 60)),
              ),
            ),
          ),
        ),
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
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 12,
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
        if (images.length > 1)
          Positioned(
            bottom: 10, left: 0, right: 0,
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

  Widget _buildInfoSection(JobsListingModel item) {
    final details = <_Row>[
      if (item.company.isNotEmpty)      _Row('Company',    item.company),
      if (item.jobType.isNotEmpty)      _Row('Job Type',   item.jobType),
      if (item.experience.isNotEmpty)   _Row('Experience', item.experience),
      if (item.industry.isNotEmpty)     _Row('Industry',   item.industry),
      if (item.education.isNotEmpty)    _Row('Education',  item.education),
      if (item.condition.isNotEmpty)    _Row('Condition',  item.condition),
      if (item.age.isNotEmpty)          _Row('Age',        item.age),
      if (item.usage.isNotEmpty)        _Row('Usage',      item.usage),
      if (item.warranty.isNotEmpty)     _Row('Warranty',   item.warranty),
      _Row('Posted On', item.formattedDate),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title,
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: _kBlue)),
          if (item.company.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(item.company,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54)),
          ],
          if (item.location.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF505050)),
              const SizedBox(width: 4),
              Text(item.location,
                  style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF505050))),
            ]),
          ],
          const SizedBox(height: 6),
          // Salary chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Salary: ${item.formattedPrice}',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _kBlue),
            ),
          ),
          const Divider(height: 28, color: Color(0xFFE8E8E8)),
          Text('Details',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...details.map((r) => _detailRow(r.label, r.value)),
          if (item.description.isNotEmpty) ...[
            const Divider(height: 24, color: Color(0xFFE8E8E8)),
            const SizedBox(height: 4),
            Text('Description',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(item.description,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54, height: 1.55)),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black45)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(JobsListingModel item) {
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

class _Row {
  final String label;
  final String value;
  const _Row(this.label, this.value);
}
