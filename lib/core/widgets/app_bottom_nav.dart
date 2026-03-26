import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../router/route_names.dart';
import '../theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  final int activeIndex;
  const AppBottomNav({super.key, this.activeIndex = 0});

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RouteNames.home);
        break;
      case 1:
        context.push(RouteNames.chats);
        break;
      case 3:
        context.push(RouteNames.myAds);
        break;
      case 4:
        context.push(RouteNames.account);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Expanded(child: _navItem(context, 0, Icons.home_rounded, 'HOME')),
              Expanded(child: _navItem(context, 1, Icons.chat_bubble_outline, 'CHATS')),
              // Center notch space
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'SELL',
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
              Expanded(child: _navItem(context, 3, Icons.favorite_border, 'MY ADS')),
              Expanded(child: _navItem(context, 4, Icons.person_outline, 'ACCOUNT')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int index, IconData icon, String label) {
    final active = activeIndex == index;
    return GestureDetector(
      onTap: () => _onTap(context, index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
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
    );
  }
}

class AppSellFab extends StatelessWidget {
  const AppSellFab({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.sell),
      child: SizedBox(
        width: 58,
        height: 58,
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
          child: Center(
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2258A8), width: 2.5),
              ),
              child: const Icon(Icons.add, color: Color(0xFF2258A8), size: 26),
            ),
          ),
        ),
      ),
    );
  }
}
