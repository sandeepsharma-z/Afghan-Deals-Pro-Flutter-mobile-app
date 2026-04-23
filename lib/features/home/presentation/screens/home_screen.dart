import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../chat/presentation/screens/chats_screen.dart';
import '../../../profile/presentation/screens/account_screen.dart';
import '../../../profile/presentation/screens/my_ads_screen.dart';
import '../../../categories/properties/presentation/screens/properties_screen.dart';
import '../../../categories/spare_parts/presentation/screens/spare_parts_screen.dart';
import '../../../categories/electronics/presentation/screens/electronics_screen.dart';
import '../../../categories/furniture/presentation/screens/furniture_screen.dart';
import '../../../categories/jobs/presentation/screens/jobs_screen.dart';
import '../providers/home_provider.dart';
import '../../data/models/home_category_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _activeIndex = 0;
  String _selectedCountry = 'Afghanistan';

  static const _fallbackCategories = [
    _CategoryTile(
      name: 'Cars',
      slug: 'cars',
      icon: Icons.directions_car_outlined,
      assetPath: 'assets/images/categories/car.png',
    ),
    _CategoryTile(
      name: 'Properties',
      slug: 'properties',
      icon: Icons.home_outlined,
      assetPath: 'assets/images/categories/home.png',
    ),
    _CategoryTile(
      name: 'Mobiles',
      slug: 'mobiles',
      icon: Icons.smartphone_outlined,
      assetPath: 'assets/images/categories/mobile.png',
    ),
    _CategoryTile(
      name: 'Spare Parts',
      slug: 'spare-parts',
      icon: Icons.build_outlined,
      assetPath: 'assets/images/categories/spare_parts.png',
    ),
    _CategoryTile(
      name: 'Electronics/Appliances',
      slug: 'electronics',
      icon: Icons.tv_outlined,
      assetPath: 'assets/images/categories/appliance.png',
    ),
    _CategoryTile(
      name: 'Furniture',
      slug: 'furniture',
      icon: Icons.chair_outlined,
      assetPath: 'assets/images/categories/furniture.png',
    ),
    _CategoryTile(
      name: 'Classifieds',
      slug: 'classifieds',
      icon: Icons.grid_view_outlined,
      assetPath: 'assets/images/categories/classifieds.png',
    ),
    _CategoryTile(
      name: 'Jobs',
      slug: 'jobs',
      icon: Icons.work_outline,
      assetPath: 'assets/images/categories/jobs.png',
    ),
  ];

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

  String? _flagImageFor(String country) {
    switch (country) {
      case 'Afghanistan':
        return 'assets/images/flags/afghanistan.png';
      case 'Oman':
        return 'assets/images/flags/oman.png';
      case 'UAE':
        return 'assets/images/flags/uae.png';
      case 'Qatar':
        return 'assets/images/flags/qatar.png';
      case 'KSA':
        return 'assets/images/flags/ksa.png';
      case 'Syria':
        return 'assets/images/flags/syria.png';
      default:
        return null;
    }
  }

  String _flagFor(String country) {
    switch (country) {
      case 'Afghanistan':
        return 'AF';
      case 'Oman':
        return 'OM';
      case 'UAE':
        return 'AE';
      case 'Qatar':
        return 'QA';
      case 'KSA':
        return 'SA';
      case 'Syria':
        return 'SY';
      case 'Pakistan':
        return 'PK';
      case 'Iran':
        return 'IR';
      case 'Turkey':
        return 'TR';
      case 'Germany':
        return 'DE';
      default:
        return 'GL';
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
          _Country('Afghanistan', 'AF', 'assets/images/flags/afghanistan.png',
              '+93'),
          _Country('Oman', 'OM', 'assets/images/flags/oman.png', '+968'),
          _Country('UAE', 'AE', 'assets/images/flags/uae.png', '+971'),
          _Country('Qatar', 'QA', 'assets/images/flags/qatar.png', '+974'),
          _Country('KSA', 'SA', 'assets/images/flags/ksa.png', '+966'),
          _Country('Syria', 'SY', 'assets/images/flags/syria.png', '+963'),
        ],
        selected: _selectedCountry,
        onSelect: (c) {
          setState(() => _selectedCountry = c);
          Navigator.pop(context);
        },
      ),
    );
  }

  static const _slugAssets = {
    'cars':        'assets/images/categories/car.png',
    'properties':  'assets/images/categories/home.png',
    'mobiles':     'assets/images/categories/mobile.png',
    'spare-parts': 'assets/images/categories/spare_parts.png',
    'spare_parts': 'assets/images/categories/spare_parts.png',
    'electronics': 'assets/images/categories/appliance.png',
    'furniture':   'assets/images/categories/furniture.png',
    'classifieds': 'assets/images/categories/classifieds.png',
    'jobs':        'assets/images/categories/jobs.png',
  };

  List<_CategoryTile> _mapRemoteCategories(List<HomeCategoryModel> items) {
    return items
        .map(
          (item) => _CategoryTile(
            name: _normalizeCategoryName(item.name, item.slug),
            slug: item.slug,
            icon: _iconForCategory(item.slug),
            imageUrl: item.imageUrl,
            assetPath: _slugAssets[item.slug],
          ),
        )
        .toList();
  }

  String _normalizeCategoryName(String name, String slug) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) return trimmed;

    final source = slug.replaceAll('-', ' ').replaceAll('_', ' ').trim();
    if (source.isEmpty) return 'Category';

    return source
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  IconData _iconForCategory(String slug) {
    switch (slug) {
      case 'cars':
        return Icons.directions_car_outlined;
      case 'properties':
        return Icons.home_outlined;
      case 'mobiles':
        return Icons.smartphone_outlined;
      case 'spare-parts':
      case 'spare_parts':
        return Icons.build_outlined;
      case 'electronics':
        return Icons.tv_outlined;
      case 'furniture':
        return Icons.chair_outlined;
      case 'jobs':
        return Icons.work_outline;
      case 'classifieds':
      default:
        return Icons.grid_view_outlined;
    }
  }

  void _openCategory(String slug) {
    if (slug == 'cars') {
      context.push(RouteNames.cars);
      return;
    }
    if (slug == 'properties') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PropertiesScreen()),
      );
      return;
    }
    if (slug == 'mobiles') {
      context.push(RouteNames.mobiles);
      return;
    }
    if (slug == 'spare-parts' || slug == 'spare_parts') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SparePartsScreen()),
      );
      return;
    }
    if (slug == 'electronics') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ElectronicsScreen()),
      );
      return;
    }
    if (slug == 'furniture') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const FurnitureScreen()),
      );
      return;
    }
    if (slug == 'jobs') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const JobsScreen()),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$slug category screen will be enabled soon.',
          style: GoogleFonts.montserrat(),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(homeCategoriesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: IndexedStack(
          index: _activeIndex == 1
              ? 1
              : (_activeIndex == 3
                  ? 2
                  : _activeIndex == 4
                      ? 3
                      : 0),
          children: [
            Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 10),
                _buildDiscoverBar(),
                const SizedBox(height: 10),
                Expanded(
                  child: categoriesAsync.when(
                    data: (items) {
                      final mapped = items.isEmpty
                          ? _fallbackCategories
                          : _mapRemoteCategories(items);
                      return _buildGrid(mapped);
                    },
                    loading: _buildGridLoading,
                    error: (_, __) => _buildGrid(_fallbackCategories),
                  ),
                ),
              ],
            ),
            ChatsScreen(
              onExploreListings: () => setState(() => _activeIndex = 0),
            ),
            const MyAdsScreen(),
            const AccountScreen(),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildSellFab(),
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Image.asset('assets/images/logo.png',
              height: 48, fit: BoxFit.contain),
          const Spacer(),
          GestureDetector(
            onTap: _showCountrySheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: _headerBoxDecoration,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _flagImageFor(_selectedCountry) != null
                      ? Image.asset(_flagImageFor(_selectedCountry)!,
                          width: 22, height: 22, fit: BoxFit.cover)
                      : Text(_flagFor(_selectedCountry),
                          style: const TextStyle(fontSize: 15)),
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
          const SizedBox(width: 12),
          Container(
            width: 34,
            height: 34,
            decoration: _headerBoxDecoration,
            child: const Center(
              child: Icon(Icons.help_outline, size: 22, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.push(RouteNames.notifications),
            child: Container(
              width: 34,
              height: 34,
              decoration: _headerBoxDecoration,
              child: const Center(
                child: Icon(Icons.notifications_outlined,
                    size: 23, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
            Image.asset('assets/images/logo.png',
                height: 22, fit: BoxFit.contain),
            const SizedBox(width: 10),
            Text(
              'Discover AFGHAN DEALS PRO Deal',
              style:
                  GoogleFonts.montserrat(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<_CategoryTile> categories) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.15,
      ),
      itemCount: categories.length,
      itemBuilder: (_, i) => _buildCategoryCard(categories[i]),
    );
  }

  Widget _buildGridLoading() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.15,
      ),
      itemCount: 6,
      itemBuilder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E2E2)),
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(_CategoryTile cat) {
    return GestureDetector(
      onTap: () => _openCategory(cat.slug),
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
                child: _buildCategoryImage(cat),
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

  Widget _buildCategoryImage(_CategoryTile cat) {
    if (cat.imageUrl != null && cat.imageUrl!.isNotEmpty) {
      return Image.network(
        cat.imageUrl!,
        fit: BoxFit.contain,
        width: double.infinity,
        errorBuilder: (_, __, ___) => cat.assetPath != null
            ? Image.asset(cat.assetPath!, fit: BoxFit.contain, width: double.infinity)
            : Center(child: Icon(cat.icon, size: 52, color: Colors.grey.shade400)),
      );
    }

    if (cat.assetPath != null) {
      return Image.asset(
        cat.assetPath!,
        fit: BoxFit.contain,
        width: double.infinity,
      );
    }

    return Center(
      child: Icon(cat.icon, size: 52, color: Colors.grey.shade400),
    );
  }

  Widget _buildSellFab() {
    return GestureDetector(
      onTap: () => context.push(RouteNames.sell),
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
          height: 66,
          child: Row(
            children: [
              Expanded(child: _navItem(0, Icons.home_rounded, 'HOME')),
              Expanded(child: _navItem(1, Icons.chat_bubble_outline, 'CHATS')),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'SELL',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black38,
                      ),
                    ),
                    const SizedBox(height: 8),
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
      onTap: () {
        final isGuest = Supabase.instance.client.auth.currentUser == null;
        final requiresAuth = index == 1; // CHATS tab
        if (isGuest && requiresAuth) {
          context.push(RouteNames.onboarding);
          return;
        }
        setState(() => _activeIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon,
                size: 24, color: active ? AppColors.navActive : Colors.black38),
            const SizedBox(height: 7),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.navActive : Colors.black38,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

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
                  child:
                      const Icon(Icons.close, size: 22, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: countries.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE8E8E8),
                indent: 20,
                endIndent: 20,
              ),
              itemBuilder: (_, i) {
                final c = countries[i];
                final isSelected = c.name == selected;
                return GestureDetector(
                  onTap: () => onSelect(c.name),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.navActive
                                  : const Color(0xFFBBBBBB),
                              width: 2,
                            ),
                            color: isSelected
                                ? AppColors.navActive
                                : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        c.imagePath != null
                            ? Image.asset(
                                c.imagePath!,
                                width: 34,
                                height: 34,
                                fit: BoxFit.cover,
                              )
                            : Text(c.flag,
                                style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            c.name,
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (c.dialCode.isNotEmpty)
                          Text(
                            c.dialCode,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black45,
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

class _CategoryTile {
  final String name;
  final String slug;
  final IconData icon;
  final String? imageUrl;
  final String? assetPath;

  const _CategoryTile({
    required this.name,
    required this.slug,
    required this.icon,
    this.imageUrl,
    this.assetPath,
  });
}

class _Country {
  final String name;
  final String flag;
  final String? imagePath;
  final String dialCode;

  const _Country(this.name, this.flag, [this.imagePath, this.dialCode = '']);
}

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
    canvas.drawArc(rect, -pi / 2, third, false, arc(const Color(0xFF1D57A7)));
    canvas.drawArc(
        rect, -pi / 2 + third, third, false, arc(const Color(0xFF000000)));
    canvas.drawArc(
        rect, -pi / 2 + 2 * third, third, false, arc(const Color(0xFF3B77FE)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
