import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../router/route_names.dart';
import '../theme/app_colors.dart';
import '../../features/chat/presentation/providers/chat_provider.dart';

class AppBottomNav extends ConsumerWidget {
  final int activeIndex;
  const AppBottomNav({super.key, this.activeIndex = 0});

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go(RouteNames.home); break;
      case 1: context.push(RouteNames.chats); break;
      case 3: context.push(RouteNames.myAds); break;
      case 4: context.push(RouteNames.account); break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalUnread = ref.watch(totalUnreadProvider);

    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(color: Color(0x28000000), blurRadius: 12, spreadRadius: 0, offset: Offset(0, -4)),
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
              Expanded(child: _navItem(context, 0, Icons.home_rounded, 'HOME', 0)),
              Expanded(child: _chatNavItem(context, totalUnread)),
              // Center notch space
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('SELL',
                        style: GoogleFonts.montserrat(
                            fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black38)),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(child: _navItem(context, 3, Icons.favorite_border, 'MY ADS', 0)),
              Expanded(child: _navItem(context, 4, Icons.person_outline, 'ACCOUNT', 0)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatNavItem(BuildContext context, int unread) {
    final active = activeIndex == 1;
    return GestureDetector(
      onTap: () => _onTap(context, 1),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.chat_bubble_outline, size: 24,
                    color: active ? AppColors.navActive : Colors.black38),
                if (unread > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC92325),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: GoogleFonts.montserrat(
                            fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text('CHATS',
                style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: active ? AppColors.navActive : Colors.black38)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int index, IconData icon, String label, int badge) {
    final active = activeIndex == index;
    return GestureDetector(
      onTap: () => _onTap(context, index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: active ? AppColors.navActive : Colors.black38),
            const SizedBox(height: 7),
            Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: active ? AppColors.navActive : Colors.black38)),
            const SizedBox(height: 8),
          ],
        ),
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
        child: CustomPaint(
          foregroundPainter: _SellRingPainter(),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [BoxShadow(color: Color(0x25000000), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: const Center(
              child: Icon(Icons.add, color: Color(0xFF2258A8), size: 28),
            ),
          ),
        ),
      ),
    );
  }
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
    canvas.drawArc(rect, -pi / 2,           third, false, arc(const Color(0xFF1D57A7)));
    canvas.drawArc(rect, -pi / 2 + third,   third, false, arc(const Color(0xFF000000)));
    canvas.drawArc(rect, -pi / 2 + 2*third, third, false, arc(const Color(0xFF3B77FE)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
