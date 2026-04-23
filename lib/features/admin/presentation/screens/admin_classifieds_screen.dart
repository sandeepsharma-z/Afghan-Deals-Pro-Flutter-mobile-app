import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../listings/data/models/classified_listing_model.dart';
import '../../../categories/classifieds/presentation/screens/classifieds_detail_screen.dart';

const _kBlue = Color(0xFF2258A8);

// ── All classifieds listings for admin (no is_active filter) ─────────────────
final adminClassifiedsProvider =
    FutureProvider.autoDispose<List<ClassifiedListingModel>>((ref) async {
  final response = await Supabase.instance.client
      .from('listings')
      .select()
      .eq('category', 'classifieds')
      .order('created_at', ascending: false);
  return (response as List<dynamic>)
      .map((e) => ClassifiedListingModel.fromMap(e as Map<String, dynamic>))
      .toList();
});

// ── Category structure for admin dashboard ────────────────────────────────────
const _kAdminCategories = [
  _AdminCategory(
    title: 'Fashion',
    icon: Icons.checkroom_outlined,
    color: Color(0xFF7B5EA7),
    subcategories: [
      _AdminSub('Men',                  'men',                  Icons.person_outline),
      _AdminSub('Women',                'women',                Icons.person_outline),
      _AdminSub('Kids Fashion',         'kids-fashion',         Icons.child_care_outlined),
      _AdminSub('Bags',                 'bags',                 Icons.shopping_bag_outlined),
      _AdminSub('Footwear',             'footwear',             Icons.do_not_step_outlined),
      _AdminSub('Jewelry',              'jewelry',              Icons.diamond_outlined),
      _AdminSub('Watches & Accessories','watches-accessories',  Icons.watch_outlined),
    ],
  ),
  _AdminCategory(
    title: 'Books & Sports',
    icon: Icons.menu_book_outlined,
    color: Color(0xFF2258A8),
    subcategories: [
      _AdminSub('Academic Books',    'academic-books',    Icons.menu_book_outlined),
      _AdminSub('Fiction Books',     'fiction-books',     Icons.book_outlined),
      _AdminSub('Kids Book',         'kids-book',         Icons.child_care_outlined),
      _AdminSub('Exam Preparation',  'exam-preparation',  Icons.school_outlined),
      _AdminSub('Sports Accessories','sports-accessories',Icons.sports_outlined),
      _AdminSub('Cricket Gear',      'cricket-gear',      Icons.sports_cricket_outlined),
      _AdminSub('Fitness Equipment', 'fitness-equipment', Icons.fitness_center_outlined),
    ],
  ),
];

class _AdminCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<_AdminSub> subcategories;
  const _AdminCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.subcategories,
  });
}

class _AdminSub {
  final String label;
  final String slug;
  final IconData icon;
  const _AdminSub(this.label, this.slug, this.icon);
}

// ── Admin Classifieds Dashboard ───────────────────────────────────────────────
class AdminClassifiedsScreen extends ConsumerStatefulWidget {
  const AdminClassifiedsScreen({super.key});

  @override
  ConsumerState<AdminClassifiedsScreen> createState() =>
      _AdminClassifiedsScreenState();
}

class _AdminClassifiedsScreenState
    extends ConsumerState<AdminClassifiedsScreen> {
  String _selectedSlug = '';

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(adminClassifiedsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _kBlue,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: Colors.white),
        ),
        title: Text('Classifieds Dashboard',
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.invalidate(adminClassifiedsProvider),
          ),
        ],
      ),
      body: listingsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kBlue)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (all) => _buildDashboard(all),
      ),
    );
  }

  Widget _buildDashboard(List<ClassifiedListingModel> all) {
    final filtered = _selectedSlug.isEmpty
        ? all
        : all.where((l) => l.subcategory == _selectedSlug).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stats banner ────────────────────────────────────────────────
          Container(
            color: _kBlue,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Row(children: [
              _statBox('Total', all.length.toString(), Icons.list_alt_outlined),
              const SizedBox(width: 12),
              _statBox('Active',
                  all.where((l) => l.isFeatured).length.toString(),
                  Icons.star_outlined),
              const SizedBox(width: 12),
              _statBox('Categories', '14', Icons.category_outlined),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Category sections ────────────────────────────────────────────
          ..._kAdminCategories.map((cat) => _buildCategorySection(cat, all)),

          // ── Listings ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(children: [
              Text(
                _selectedSlug.isEmpty
                    ? 'All Listings'
                    : 'Listings: $_selectedSlug',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text('${filtered.length} items',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.black45)),
            ]),
          ),
          if (filtered.isEmpty)
            const SizedBox(
              height: 180,
              child: Center(
                  child: Text('No listings',
                      style: TextStyle(color: Colors.black38))),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: filtered.length,
              itemBuilder: (_, i) =>
                  _AdminListingRow(item: filtered[i]),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCategorySection(_AdminCategory cat, List<ClassifiedListingModel> all) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(children: [
              Icon(cat.icon, size: 18, color: cat.color),
              const SizedBox(width: 8),
              Text(cat.title,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cat.color)),
              const Spacer(),
              Text(
                '${all.where((l) => cat.subcategories.any((s) => s.slug == l.subcategory)).length} listings',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.black45),
              ),
            ]),
          ),
          // Sub-category grid
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 10,
              children: cat.subcategories.map((sub) {
                final count = all
                    .where((l) => l.subcategory == sub.slug)
                    .length;
                final isSelected = _selectedSlug == sub.slug;
                return GestureDetector(
                  onTap: () => setState(() =>
                      _selectedSlug = isSelected ? '' : sub.slug),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? _kBlue : const Color(0xFFF3F4F8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: isSelected
                              ? _kBlue
                              : const Color(0xFFE0E0E0)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(sub.icon,
                          size: 14,
                          color: isSelected ? Colors.white : _kBlue),
                      const SizedBox(width: 6),
                      Text(sub.label,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.black87)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : _kBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$count',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : _kBlue)),
                      ),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.white70)),
        ]),
      ),
    );
  }
}

// ── Admin listing row ─────────────────────────────────────────────────────────
class _AdminListingRow extends StatelessWidget {
  final ClassifiedListingModel item;
  const _AdminListingRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ClassifiedsDetailScreen(item: item),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
                color: Color(0x10000000), blurRadius: 4, offset: Offset(0, 1))
          ],
        ),
        child: Row(children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: item.images.isEmpty
                ? Container(
                    width: 60,
                    height: 60,
                    color: const Color(0xFFEDEDED),
                    child: const Icon(Icons.grid_view_outlined,
                        color: Colors.grey, size: 24),
                  )
                : Image.network(item.imageUrl,
                    width: 60, height: 60, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                          width: 60,
                          height: 60,
                          color: const Color(0xFFEDEDED),
                          child: const Icon(Icons.grid_view_outlined,
                              color: Colors.grey, size: 24),
                        )),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(item.formattedPrice,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kBlue)),
              const SizedBox(height: 2),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.subcategory.isEmpty ? 'general' : item.subcategory,
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: _kBlue),
                  ),
                ),
                const SizedBox(width: 6),
                Text(item.timeAgo,
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.black38)),
              ]),
            ]),
          ),
          const Icon(Icons.chevron_right, color: Colors.black26),
        ]),
      ),
    );
  }
}
