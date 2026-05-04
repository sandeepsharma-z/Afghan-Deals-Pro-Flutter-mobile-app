import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/favorite_button.dart';
import '../../../../../features/listings/data/models/car_sale_model.dart';
import '../providers/car_listings_provider.dart';

// Map display title → Supabase subcategory value
const _subcategoryMap = {
  'Used Cars': 'used',
  'New Cars': 'new',
  'Export Cars': 'export',
  'Motorcycles': 'motorcycles',
  'Auto Accessories & Parts': 'accessories',
  'Heavy Vehicles': 'heavy',
  'Boats': 'boats',
  'Number Plates': 'number-plates',
};

class CarListingsScreen extends ConsumerStatefulWidget {
  final String subcategory;
  const CarListingsScreen({super.key, required this.subcategory});

  @override
  ConsumerState<CarListingsScreen> createState() => _CarListingsScreenState();
}

class _CarListingsScreenState extends ConsumerState<CarListingsScreen> {
  bool _isGrid = false;
  String _sortBy = 'Latest';
  String _selectedBodyType = 'All';
  String _selectedCondition = 'All';
  int? _fromYear;
  int? _toYear;

  static const _sortOptions = [
    'Latest',
    'Price: Low to High',
    'Price: High to Low',
    'Most Popular',
  ];

  String get _supabaseSubcategory =>
      _subcategoryMap[widget.subcategory] ?? widget.subcategory.toLowerCase();

  List<CarSaleModel> _applyFilters(List<CarSaleModel> cars) {
    return cars.where((c) {
      final bodyType = c.bodyType.trim().toLowerCase();
      final condition = c.condition.trim().toLowerCase();
      final year = int.tryParse(c.year.trim());

      if (_selectedBodyType != 'All' && bodyType != _selectedBodyType.toLowerCase()) return false;
      if (_selectedCondition != 'All' && condition != _selectedCondition.toLowerCase()) return false;
      if (_fromYear != null && year != null && year < _fromYear!) return false;
      if (_toYear != null && year != null && year > _toYear!) return false;
      return true;
    }).toList();
  }

  void _openFilterSheet(List<CarSaleModel> cars) {
    final bodyTypes = {for (final c in cars) if (c.bodyType.trim().isNotEmpty) c.bodyType.trim()}.toList()..sort();
    final conditions = {for (final c in cars) if (c.condition.trim().isNotEmpty) c.condition.trim()}.toList()..sort();
    final years = [for (final c in cars) if (int.tryParse(c.year.trim()) != null) int.parse(c.year.trim())]..sort();
    final minYear = years.isNotEmpty ? years.first : DateTime.now().year - 20;
    final maxYear = years.isNotEmpty ? years.last : DateTime.now().year;

    int tempFrom = _fromYear ?? minYear;
    int tempTo = _toYear ?? maxYear;
    String tempBody = _selectedBodyType;
    String tempCondition = _selectedCondition;

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(22))),
      builder: (_) => StatefulBuilder(builder: (context, setModalState) => SafeArea(top: false, child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: const Color(0xFFCFCFCF), borderRadius: BorderRadius.circular(999)))),
            const SizedBox(height: 12),
            Text('Filter', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            Text('Body Type', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            _dropdown(value: tempBody, items: ['All', ...bodyTypes], onChanged: (v) => setModalState(() => tempBody = v)),
            const SizedBox(height: 12),
            Text('Condition', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            _dropdown(value: tempCondition, items: ['All', ...conditions], onChanged: (v) => setModalState(() => tempCondition = v)),
            const SizedBox(height: 12),
            Text('Year Range', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _yearField(label: 'From', value: tempFrom, min: minYear, max: maxYear, onChanged: (v) => setModalState(() => tempFrom = v))),
              const SizedBox(width: 10),
              Expanded(child: _yearField(label: 'To', value: tempTo, min: minYear, max: maxYear, onChanged: (v) => setModalState(() => tempTo = v))),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => setModalState(() {tempBody = 'All'; tempCondition = 'All'; tempFrom = minYear; tempTo = maxYear;}), child: const Text('Reset'))),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(onPressed: () {
                if (tempFrom > tempTo) {final swap = tempFrom; tempFrom = tempTo; tempTo = swap;}
                setState(() {_selectedBodyType = tempBody; _selectedCondition = tempCondition; _fromYear = tempFrom; _toYear = tempTo;});
                context.pop();
              }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2258A8), foregroundColor: Colors.white), child: const Text('Apply'))),
            ]),
          ])))))));
  }

  Widget _dropdown({required String value, required List<String> items, required ValueChanged<String> onChanged}) {
    final selected = items.contains(value) ? value : items.first;
    return Container(height: 42, padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFC4C4C4)), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: selected, isExpanded: true,
        items: items.map((e) => DropdownMenuItem<String>(value: e, child: Text(e))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); })));
  }

  Widget _yearField({required String label, required int value, required int min, required int max, required ValueChanged<int> onChanged}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54)),
      const SizedBox(height: 4),
      Container(height: 42, padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFC4C4C4)), borderRadius: BorderRadius.circular(8)),
        child: DropdownButtonHideUnderline(child: DropdownButton<int>(value: value, isExpanded: true,
          items: List.generate(max - min + 1, (i) => min + i).map((e) => DropdownMenuItem<int>(value: e, child: Text(e.toString()))).toList(),
          onChanged: (v) { if (v != null) onChanged(v); })))]);
  }

  List<CarSaleModel> _sortListings(List<CarSaleModel> list) {
    final sorted = List<CarSaleModel>.from(list);
    switch (_sortBy) {
      case 'Price: Low to High':
        sorted.sort((a, b) =>
            (double.tryParse(a.price) ?? 0)
                .compareTo(double.tryParse(b.price) ?? 0));
        break;
      case 'Price: High to Low':
        sorted.sort((a, b) =>
            (double.tryParse(b.price) ?? 0)
                .compareTo(double.tryParse(a.price) ?? 0));
        break;
      default:
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(carListingsProvider(_supabaseSubcategory));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black87, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.subcategory,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 28 / 15,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black87, size: 20),
            onPressed: () => asyncData.whenData((cars) => _openFilterSheet(cars)),
          ),
          IconButton(
            icon: const Icon(Icons.swap_vert, color: Colors.black87, size: 20),
            onPressed: () {},
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child:
              Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
        ),
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (listings) {
          final filtered = _applyFilters(listings);
          final sorted = _sortListings(filtered);
          return Column(
            children: [
              // Filter bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    _filterChip(Icons.tune, 'Filter', () {}),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showSortSheet(sorted),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: const Color(0xFFDDDDDD)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_sortBy,
                                style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down,
                                size: 16),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text('${sorted.length} results',
                        style: GoogleFonts.montserrat(
                            fontSize: 12, color: Colors.black45)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _isGrid = !_isGrid),
                      child: Icon(
                        _isGrid ? Icons.view_list : Icons.grid_view,
                        size: 20,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              Expanded(
                child: sorted.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.directions_car_outlined,
                                size: 64, color: Colors.black26),
                            const SizedBox(height: 12),
                            Text('No listings found',
                                style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    color: Colors.black45)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.refresh(
                            carListingsProvider(_supabaseSubcategory)
                                .future),
                        child: _isGrid
                            ? _buildGrid(sorted)
                            : _buildList(sorted),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterChip(
          IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text(label,
                  style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
        ),
      );

  Widget _buildList(List<CarSaleModel> listings) => ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: listings.length,
        itemBuilder: (_, i) => _ListingCard(listing: listings[i]),
      );

  Widget _buildGrid(List<CarSaleModel> listings) => GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.72,
        ),
        itemCount: listings.length,
        itemBuilder: (_, i) => _GridCard(listing: listings[i]),
      );

  void _showSortSheet(List<CarSaleModel> listings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sort By',
                    style: GoogleFonts.montserrat(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => context.pop()),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          ..._sortOptions.map((opt) => Column(
                children: [
                  ListTile(
                    title: Text(opt,
                        style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: opt == _sortBy
                                ? FontWeight.w600
                                : FontWeight.w400)),
                    trailing: opt == _sortBy
                        ? const Icon(Icons.check,
                            color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() => _sortBy = opt);
                      context.pop();
                    },
                  ),
                  Container(
                      height: 1,
                      margin:
                          const EdgeInsets.symmetric(horizontal: 16),
                      color: const Color(0xFFEEEEEE)),
                ],
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── List Card ─────────────────────────────────────────────────────────────────
class _ListingCard extends StatelessWidget {
  final CarSaleModel listing;
  const _ListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 4,
              offset: Offset(0, 2))
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Row(
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(12)),
                  child: listing.imageUrl.isNotEmpty
                      ? Image.network(
                          listing.imageUrl,
                          width: 130,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _imagePlaceholder(130, 110),
                        )
                      : _imagePlaceholder(130, 110),
                ),
                if (listing.isFeatured)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA000),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Featured',
                          style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
              ],
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(listing.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
                    const SizedBox(height: 6),
                    Text(listing.formattedPrice,
                        style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (listing.year.isNotEmpty)
                          _tag(listing.year),
                        if (listing.mileage.isNotEmpty)
                          _tag(listing.mileage),
                        if (listing.transmission.isNotEmpty)
                          _tag(listing.transmission),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: Colors.black38),
                        const SizedBox(width: 2),
                        Text(listing.location,
                            style: GoogleFonts.montserrat(
                                fontSize: 11, color: Colors.black38)),
                        const Spacer(),
                        Text(listing.timeAgo,
                            style: GoogleFonts.montserrat(
                                fontSize: 11, color: Colors.black38)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text,
            style: GoogleFonts.montserrat(
                fontSize: 10, color: Colors.black54)),
      );
}

// ── Grid Card ─────────────────────────────────────────────────────────────────
class _GridCard extends StatelessWidget {
  final CarSaleModel listing;
  const _GridCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 4,
              offset: Offset(0, 2))
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12)),
                  child: listing.imageUrl.isNotEmpty
                      ? Image.network(
                          listing.imageUrl,
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _imagePlaceholder(double.infinity, 110),
                        )
                      : _imagePlaceholder(double.infinity, 110),
                ),
                if (listing.isFeatured)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFFA000),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text('Featured',
                          style: GoogleFonts.montserrat(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: FavoriteButton(
                    listingId: listing.id,
                    size: 28,
                    backgroundColor: const Color(0x100F172A),
                        showShadow: false,
                    unselectedIconColor: Colors.white,
                    selectedIconColor: Colors.red,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(listing.formattedPrice,
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: Colors.black38),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(listing.location,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                                fontSize: 10, color: Colors.black38)),
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

Widget _imagePlaceholder(double width, double height) => Container(
      width: width,
      height: height,
      color: const Color(0xFFF0F0F0),
      child: const Icon(Icons.directions_car,
          size: 48, color: Color(0xFFCCCCCC)),
    );
