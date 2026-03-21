import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';
import '../../../chat/presentation/screens/chats_screen.dart';
import '../../../profile/presentation/screens/favorites_screen.dart';
import '../../../profile/presentation/screens/account_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _activeIndex = 0;
  String _selectedCountry = 'Afghanistan';

  static const _categories = [
    _Category('Cars',                   Icons.directions_car_outlined,  'assets/images/categories/car.png'),
    _Category('Properties',             Icons.home_outlined,             'assets/images/categories/home.png'),
    _Category('Mobiles',                Icons.smartphone_outlined,       'assets/images/categories/mobile.png'),
    _Category('Spare Parts',            Icons.build_outlined,            'assets/images/categories/spare_parts.png'),
    _Category('Electronics/\nAppliances', Icons.tv_outlined,             'assets/images/categories/appliance.png'),
    _Category('Furniture',              Icons.chair_outlined,            'assets/images/categories/furniture.png'),
    _Category('Classifieds',            Icons.grid_view_outlined,        null),
    _Category('Jobs',                   Icons.work_outline,              'assets/images/categories/jobs.png'),
  ];

  // Shared box decoration for header buttons
  static const _headerBoxDecoration = BoxDecoration(
    color: Color(0xFFF6F6F6),
    borderRadius: BorderRadius.all(Radius.circular(6)),
    boxShadow: [
      BoxShadow(
        color: Color(0x40000000),
        blurRadius: 4,
        offset: Offset(0, 1),
      ),
    ],
  );

  String _flagFor(String country) {
    switch (country) {
      case 'Afghanistan': return '🇦🇫';
      case 'Oman':        return '🇴🇲';
      case 'UAE':         return '🇦🇪';
      case 'Qatar':       return '🇶🇦';
      case 'KSA':         return '🇸🇦';
      case 'Syria':       return '🇸🇾';
      case 'Pakistan':    return '🇵🇰';
      case 'Iran':        return '🇮🇷';
      case 'Turkey':      return '🇹🇷';
      case 'Germany':     return '🇩🇪';
      default:            return '🌍';
    }
  }

  void _showCountrySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => _CountrySheet(
        countries: const [
          _Country('Afghanistan', '🇦🇫', null),
          _Country('Oman',        '🇴🇲', 'assets/images/flags/oman.png'),
          _Country('UAE',         '🇦🇪', 'assets/images/flags/uae.png'),
          _Country('Qatar',       '🇶🇦', 'assets/images/flags/qatar.png'),
          _Country('KSA',         '🇸🇦', 'assets/images/flags/ksa.png'),
          _Country('Syria',       '🇸🇾', 'assets/images/flags/syria.png'),
        ],
        selected: _selectedCountry,
        onSelect: (c) {
          setState(() => _selectedCountry = c);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: IndexedStack(
          index: _activeIndex == 1 ? 1 : (_activeIndex == 3 ? 2 : _activeIndex == 4 ? 3 : 0),
          children: [
            // HOME
            Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 10),
                _buildDiscoverBar(),
                const SizedBox(height: 10),
                Expanded(child: _buildGrid()),
              ],
            ),
            // CHATS
            const ChatsScreen(),
            // MY ADS / FAVORITES
            const FavoritesScreen(),
            // ACCOUNT
            const AccountScreen(),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildSellFab(),
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Image.asset('assets/images/logo.png', height: 48, fit: BoxFit.contain),
          const Spacer(),

          // Country selector — tappable
          GestureDetector(
            onTap: _showCountrySheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: _headerBoxDecoration,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_flagFor(_selectedCountry), style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 5),
                  Text(
                    _selectedCountry,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Help (?)
          Container(
            width: 34,
            height: 34,
            decoration: _headerBoxDecoration,
            child: const Center(
              child: Icon(Icons.help_outline, size: 18, color: Colors.black54),
            ),
          ),

          const SizedBox(width: 8),

          // Notification Bell
          Container(
            width: 34,
            height: 34,
            decoration: _headerBoxDecoration,
            child: const Center(
              child: Icon(Icons.notifications_outlined, size: 19, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Discover / Search Bar ────────────────────────────────────────────────
  Widget _buildDiscoverBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFC2C2C2)),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 22, fit: BoxFit.contain),
            const SizedBox(width: 10),
            Text(
              'Discover AFGHAN DEALS PRO Deal',
              style: GoogleFonts.montserrat(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Categories Grid ───────────────────────────────────────────────────────
  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.15,
      ),
      itemCount: _categories.length,
      itemBuilder: (_, i) => _buildCategoryCard(_categories[i]),
    );
  }

  Widget _buildCategoryCard(_Category cat) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFB4B4B4)),
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
                child: cat.imagePath != null
                    ? Image.asset(
                        cat.imagePath!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      )
                    : Center(
                        child: Icon(cat.icon, size: 52, color: Colors.grey.shade400),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 2, 8, 10),
              child: Text(
                cat.name,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Sell FAB ──────────────────────────────────────────────────────────────
  Widget _buildSellFab() {
    return GestureDetector(
      onTap: () => setState(() => _activeIndex = 2),
      child: SizedBox(
        width: 58,
        height: 58,
        child: CustomPaint(
          foregroundPainter: _SellRingPainter(),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x25000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.add, color: Color(0xFF2258A8), size: 28),
            ),
          ),
        ),
      ),
    );
  }

  // ─── BottomAppBar ──────────────────────────────────────────────────────────
  Widget _buildBottomAppBar() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 12,
            spreadRadius: 0,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 0,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              Expanded(child: _navItem(0, Icons.home_rounded, 'HOME')),
              Expanded(child: _navItem(1, Icons.chat_bubble_outline, 'CHATS')),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('SELL',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black38,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              Expanded(child: _navItem(3, Icons.favorite_border, 'MY ADS')),
              Expanded(child: _navItem(4, Icons.person_outline, 'ACCOUNT')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = _activeIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: active ? AppColors.navActive : Colors.black38),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.navActive : Colors.black38,
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

// ─── Country bottom sheet ──────────────────────────────────────────────────────
class _CountrySheet extends StatelessWidget {
  final List<_Country> countries;
  final String selected;
  final ValueChanged<String> onSelect;

  const _CountrySheet({
    required this.countries,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return Container(
      height: screenH * 0.48,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Select Country',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 22, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Country list — scrollable
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: countries.length,
              separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8), indent: 20, endIndent: 20),
              itemBuilder: (_, i) {
                final c = countries[i];
                final isSelected = c.name == selected;
                return GestureDetector(
                  onTap: () => onSelect(c.name),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected ? AppColors.navActive : const Color(0xFFBBBBBB),
                              width: 2,
                            ),
                            color: isSelected ? AppColors.navActive : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        c.imagePath != null
                            ? Image.asset(c.imagePath!, width: 34, height: 34, fit: BoxFit.cover)
                            : Text(c.flag, style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 12),
                        Text(
                          c.name,
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data ──────────────────────────────────────────────────────────────────────
class _Category {
  final String name;
  final IconData icon;
  final String? imagePath;
  const _Category(this.name, this.icon, [this.imagePath]);
}

class _Country {
  final String name;
  final String flag;
  final String? imagePath;
  const _Country(this.name, this.flag, [this.imagePath]);
}

// ─── Sell button ring painter ──────────────────────────────────────────────────
class _SellRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeW = 6.5;
    final radius = size.width / 2 - strokeW / 2 - 1;
    final rect = Rect.fromCircle(center: center, radius: radius);

    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;

    const third = 2 * pi / 3;
    canvas.drawArc(rect, -pi / 2,             third, false, arc(const Color(0xFF1D57A7)));
    canvas.drawArc(rect, -pi / 2 + third,     third, false, arc(const Color(0xFF000000)));
    canvas.drawArc(rect, -pi / 2 + 2 * third, third, false, arc(const Color(0xFF3B77FE)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
