import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/jobs_provider.dart';
import '../../../../../features/listings/data/models/jobs_listing_model.dart';
import 'jobs_detail_screen.dart';
import 'jobs_filter_screen.dart';

const _kBlue = Color(0xFF2258A8);

class JobsListingsScreen extends ConsumerStatefulWidget {
  final String subcategory;
  final String subcategoryLabel;
  const JobsListingsScreen({
    super.key,
    required this.subcategory,
    required this.subcategoryLabel,
  });

  @override
  ConsumerState<JobsListingsScreen> createState() => _JobsListingsScreenState();
}

class _JobsListingsScreenState extends ConsumerState<JobsListingsScreen> {
  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(jobsFilteredProvider(widget.subcategory));
    final filter = ref.watch(jobsFilterProvider);
    final hasFilter = !filter.isEmpty;

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
          widget.subcategoryLabel.isEmpty ? 'All Jobs' : widget.subcategoryLabel,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: Stack(children: [
              const Icon(Icons.tune, color: Colors.black87),
              if (hasFilter)
                Positioned(
                  right: 0, top: 0,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: _kBlue, shape: BoxShape.circle),
                  ),
                ),
            ]),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => JobsFilterScreen(subcategory: widget.subcategory),
            )),
          ),
          IconButton(
            icon: const Icon(Icons.sort, color: Colors.black87),
            onPressed: () => _showSortSheet(context),
          ),
        ],
      ),
      body: listingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _kBlue)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) => items.isEmpty
            ? Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.work_outline, size: 64, color: Colors.black26),
                  const SizedBox(height: 12),
                  Text('No jobs found',
                      style: GoogleFonts.poppins(fontSize: 15, color: Colors.black45)),
                ]),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 224,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => JobsDetailScreen(item: items[i]),
                  )),
                  child: _JobResultCard(item: items[i]),
                ),
              ),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    final filter = ref.read(jobsFilterProvider);
    final options = [
      ('Newest to Oldest', 'newest'),
      ('Oldest to Newest', 'oldest'),
      ('Salary Highest to Lowest', 'salary_high'),
      ('Salary Lowest to Highest', 'salary_low'),
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('Sort', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          ...options.map((opt) => ListTile(
                title: Text(opt.$1, style: GoogleFonts.poppins(fontSize: 14)),
                trailing: filter.sortBy == opt.$2 ? const Icon(Icons.check, color: _kBlue) : null,
                onTap: () {
                  ref.read(jobsFilterProvider.notifier).state = filter.copyWith(sortBy: opt.$2);
                  Navigator.of(context).pop();
                },
              )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _JobResultCard extends StatelessWidget {
  final JobsListingModel item;
  const _JobResultCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Color(0x30000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8), topRight: Radius.circular(8),
              ),
              child: item.images.isEmpty
                  ? _placeholder()
                  : Image.network(item.imageUrl, height: 118, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder()),
            ),
            if (item.images.isNotEmpty)
              Positioned(
                bottom: 6, left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Icons.camera_alt_outlined, size: 10, color: Colors.white),
                    const SizedBox(width: 3),
                    Text('${item.images.length}',
                        style: GoogleFonts.poppins(fontSize: 9, color: Colors.white)),
                  ]),
                ),
              ),
            Positioned(
              top: 6, right: 6,
              child: Container(
                width: 26, height: 26,
                decoration: const BoxDecoration(color: Color(0x28000000), shape: BoxShape.circle),
                child: const Icon(Icons.favorite_border, size: 13, color: Colors.white),
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.formattedPrice,
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _kBlue)),
              const SizedBox(height: 2),
              Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w500, color: Colors.black87)),
              if (item.experience.isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.work_outline, size: 11, color: Color(0xFF505050)),
                  const SizedBox(width: 3),
                  Expanded(child: Text('${item.experience} exp.', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF505050)))),
                ]),
              ],
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 11, color: Color(0xFF505050)),
                const SizedBox(width: 3),
                Expanded(child: Text(item.location, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF505050)))),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: _contactBtn(Icons.phone_outlined, const Color(0xFF2258A8))),
                const SizedBox(width: 6),
                Expanded(child: _contactBtn(Icons.chat_bubble_outline, const Color(0xFF25D366))),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _contactBtn(IconData icon, Color color) {
    return Container(
      height: 26,
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(child: Icon(icon, size: 14, color: color)),
    );
  }

  Widget _placeholder() => Container(
        height: 118, color: const Color(0xFFEDEDED),
        child: const Center(child: Icon(Icons.work_outline, color: Colors.grey, size: 36)));
}
