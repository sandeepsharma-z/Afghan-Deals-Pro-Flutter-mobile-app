import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'property_listings_screen.dart';

const _kBlue = Color(0xFF2258A8);
const _kBaseUrl =
    'https://nxgniehrrcpqqymorjxq.supabase.co/storage/v1/object/public/category-images/properties';

class _Subtype {
  final String name;
  final String? iconUrl;
  final IconData fallbackIcon;
  const _Subtype(this.name,
      {this.iconUrl, this.fallbackIcon = Icons.home_work_outlined});
}

const _residentialTypes = [
  _Subtype('Apartment', iconUrl: '$_kBaseUrl/apartment.svg'),
  _Subtype('Hotel Apartments', iconUrl: '$_kBaseUrl/hotel%20apartment.svg'),
  _Subtype('Penthouse', iconUrl: '$_kBaseUrl/pent%20house.svg'),
  _Subtype('Residential Building',
      iconUrl: '$_kBaseUrl/residential%20building.svg'),
  _Subtype('Townhouse', iconUrl: '$_kBaseUrl/townhouse.svg'),
  _Subtype('Villa', iconUrl: '$_kBaseUrl/villa.svg'),
];

const _commercialTypes = [
  _Subtype('Office', fallbackIcon: Icons.business_center),
  _Subtype('Shop', fallbackIcon: Icons.storefront),
  _Subtype('Showroom', fallbackIcon: Icons.store),
  _Subtype('Warehouse', fallbackIcon: Icons.warehouse),
  _Subtype('Commercial Building', fallbackIcon: Icons.business),
  _Subtype('Labor Camp', fallbackIcon: Icons.location_city),
];

const _landTypes = [
  _Subtype('Residential Land', fallbackIcon: Icons.landscape),
  _Subtype('Commercial Land', fallbackIcon: Icons.business_center),
  _Subtype('Industrial Land', fallbackIcon: Icons.factory),
  _Subtype('Agricultural Land', fallbackIcon: Icons.grass),
];

const _newProjectTypes = [
  _Subtype('Apartment', iconUrl: '$_kBaseUrl/apartment.svg'),
  _Subtype('Villa', iconUrl: '$_kBaseUrl/villa.svg'),
  _Subtype('Townhouse', iconUrl: '$_kBaseUrl/townhouse.svg'),
  _Subtype('Penthouse', iconUrl: '$_kBaseUrl/pent%20house.svg'),
];

const _pgTypes = [
  _Subtype('PG Accommodation', fallbackIcon: Icons.single_bed),
  _Subtype('Guest House', fallbackIcon: Icons.king_bed),
  _Subtype('Shared Room', fallbackIcon: Icons.group),
];

List<_Subtype> _subtypesForSlug(String slug) {
  final s = slug.toLowerCase();
  if (s.contains('commercial')) return _commercialTypes;
  if (s.contains('land') || s.contains('plot')) return _landTypes;
  if (s.contains('project')) return _newProjectTypes;
  if (s.contains('pg') || s.contains('guest')) return _pgTypes;
  return _residentialTypes;
}

String _allLabelForSlug(String slug) {
  final s = slug.toLowerCase();
  if (s.contains('commercial')) return 'All Commercial';
  if (s.contains('land') || s.contains('plot')) return 'All Land & Plots';
  if (s.contains('project')) return 'All New Projects';
  if (s.contains('pg') || s.contains('guest')) return 'All PG';
  return 'All Residential';
}

class PropertySubtypeScreen extends StatefulWidget {
  final String subcategoryName;
  final String subcategorySlug;

  const PropertySubtypeScreen({
    super.key,
    required this.subcategoryName,
    required this.subcategorySlug,
  });

  @override
  State<PropertySubtypeScreen> createState() => _PropertySubtypeScreenState();
}

class _PropertySubtypeScreenState extends State<PropertySubtypeScreen> {
  String? _selectedType;
  String _search = '';

  void _goToListings(String? propertyType) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PropertyListingsScreen(
        subcategoryName: widget.subcategoryName,
        subcategorySlug: widget.subcategorySlug,
        initialPropertyType: propertyType,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final subtypes = _subtypesForSlug(widget.subcategorySlug);
    final allLabel = _allLabelForSlug(widget.subcategorySlug);

    // Filter subtypes by search
    final filteredSubtypes = _search.isEmpty
        ? subtypes
        : subtypes
            .where((s) => s.name.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    // Build slot list: allLabel + filtered subtypes + 'More' + empty padding
    final names = [allLabel, ...filteredSubtypes.map((s) => s.name), 'More'];
    while (names.length % 4 != 0) {
      names.add('');
    }

    final rows = <List<String>>[];
    for (int i = 0; i < names.length; i += 4) {
      rows.add(names.sublist(i, i + 4));
    }

    // Heading label: "Select Type" or "Select Type: Apartment"
    final headingLabel =
        _selectedType != null ? 'Select Type: $_selectedType' : 'Select Type';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back_ios_new,
              size: 16, color: Colors.black87),
        ),
        title: Text(
          widget.subcategoryName,
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
        ),
      ),
      bottomNavigationBar: _buildApplyButton(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Heading (updates on selection) ────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                headingLabel,
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
            ),
            const SizedBox(height: 12),
            // ── Search bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSearchBar(),
            ),
            const SizedBox(height: 16),
            // ── Grid ──────────────────────────────────────────────────────
            ...rows.map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: row.map((name) {
                      if (name.isEmpty) {
                        return const Expanded(child: SizedBox());
                      }
                      final isMore = name == 'More';
                      final isAll = name == allLabel;
                      final isSelected = !isMore && _selectedType == name;
                      final subtype = isAll || isMore
                          ? null
                          : subtypes.firstWhere((s) => s.name == name,
                              orElse: () => const _Subtype('Other'));

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (isMore) return;
                            if (isAll) {
                              setState(() => _selectedType = null);
                            } else {
                              setState(() => _selectedType =
                                  _selectedType == name ? null : name);
                            }
                          },
                          child: Column(
                            children: [
                              Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? _kBlue.withValues(alpha: 0.08)
                                      : Colors.white,
                                  border: Border.all(
                                    color: _kBlue,
                                    width: isSelected ? 2.5 : 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: isMore
                                      ? const Icon(Icons.more_horiz,
                                          color: _kBlue, size: 22)
                                      : _buildIcon(
                                          isAll: isAll,
                                          subtype: subtype,
                                          isSelected: isSelected,
                                        ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11.6,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected ? _kBlue : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon({
    required bool isAll,
    required _Subtype? subtype,
    required bool isSelected,
  }) {
    final color = isSelected ? _kBlue : const Color(0xFF6B8FC7);
    if (isAll ||
        subtype == null ||
        (subtype.iconUrl == null || subtype.iconUrl!.isEmpty)) {
      return Icon(
        isAll
            ? Icons.home_work_outlined
            : subtype?.fallbackIcon ?? Icons.home_work_outlined,
        color: color,
        size: 22,
      );
    }
    return SvgPicture.network(
      subtype.iconUrl!,
      width: 22,
      height: 22,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      placeholderBuilder: (_) =>
          Icon(subtype.fallbackIcon, color: color, size: 22),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFC2C2C2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, size: 16, color: Colors.black87),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    isCollapsed: true,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (_search.isEmpty)
                  IgnorePointer(
                    child: Text('Search',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SvgPicture.asset('assets/icons/filter.svg', width: 16, height: 16),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildApplyButton() {
    final label =
        _selectedType != null ? 'Show $_selectedType' : 'Apply For All';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => _goToListings(_selectedType),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
