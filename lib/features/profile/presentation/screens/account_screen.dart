import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  static const _blue = Color(0xFF2258A8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE8E8E8), width: 1),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Center(
              child: Text(
                'Account',
                style: GoogleFonts.montserrat(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  // ── Profile card ─────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE8E8E8)),
                    ),
                    child: Row(
                      children: [
                        // Logo
                        Image.asset(
                          'assets/images/logo.png',
                          height: 44,
                          width: 44,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 14),
                        // Info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'pinki sharma',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Get Verified button
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFCCCCCC)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Get Verified',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified, size: 14, color: _blue),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Joined on March 2026',
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Section 1: Profile, Account Settings, Notification ─
                  _menuSection([
                    _MenuItem(Icons.person_outline,    'Profile',               null),
                    _MenuItem(Icons.settings_outlined,  'Account Settings',      null),
                    _MenuItem(Icons.notifications_outlined, 'Notification Settings', null),
                  ]),

                  const SizedBox(height: 14),

                  // ── Section 2: Country, Language ──────────────
                  _menuSection([
                    _MenuItem(Icons.location_city_outlined, 'Country',  'All Cities'),
                    _MenuItem(Icons.translate_outlined,      'Language', 'English'),
                  ]),

                  const SizedBox(height: 14),

                  // ── Section 3: Log Out ─────────────────────────
                  _menuSection([
                    _MenuItem(Icons.logout, 'Log Out', null, isLogout: true),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuSection(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              GestureDetector(
                onTap: () {},
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(item.icon, size: 22, color: Colors.black54),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.label,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: item.isLogout ? Colors.black87 : Colors.black87,
                          ),
                        ),
                      ),
                      if (item.trailing != null) ...[
                        Text(
                          item.trailing!,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: Colors.black45,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (!item.isLogout)
                        const Icon(Icons.chevron_right, size: 18, color: Colors.black38),
                    ],
                  ),
                ),
              ),
              if (i < items.length - 1)
                const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0), indent: 16, endIndent: 16),
            ],
          );
        }),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String? trailing;
  final bool isLogout;
  const _MenuItem(this.icon, this.label, this.trailing, {this.isLogout = false});
}
