import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _newMessages = true;
  bool _newOffers = true;
  bool _priceDrops = true;
  bool _savedAds = false;
  bool _accountAlerts = true;
  bool _promotions = false;
  bool _weeklyDigest = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notification Settings',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 28 / 15,
            letterSpacing: 0,
            color: Colors.black87,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            // Master toggle
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        color: Color(0xFFE8F0FB), shape: BoxShape.circle),
                    child: const Icon(Icons.notifications_outlined,
                        size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Push Notifications',
                            style: GoogleFonts.montserrat(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87)),
                        Text('Enable all push notifications',
                            style: GoogleFonts.montserrat(
                                fontSize: 12, color: Colors.black45)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _pushEnabled,
                    onChanged: (v) => setState(() => _pushEnabled = v),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Messages & Activity
            _sectionHeader('Messages & Activity'),
            _toggleTile(
              icon: Icons.chat_bubble_outline,
              iconBg: const Color(0xFFE8F8EF),
              iconColor: const Color(0xFF27AE60),
              title: 'New Messages',
              subtitle: 'When someone sends you a message',
              value: _newMessages,
              onChanged: (v) => setState(() => _newMessages = v),
            ),
            _divider(),
            _toggleTile(
              icon: Icons.local_offer_outlined,
              iconBg: const Color(0xFFE8F0FB),
              iconColor: AppColors.primary,
              title: 'New Offers',
              subtitle: 'When someone makes an offer on your ad',
              value: _newOffers,
              onChanged: (v) => setState(() => _newOffers = v),
            ),
            _divider(),
            _toggleTile(
              icon: Icons.favorite_border,
              iconBg: const Color(0xFFFEEBEB),
              iconColor: const Color(0xFFC92325),
              title: 'Saved Ad Activity',
              subtitle: 'When someone saves your listing',
              value: _savedAds,
              onChanged: (v) => setState(() => _savedAds = v),
            ),

            const SizedBox(height: 12),

            // Deals & Updates
            _sectionHeader('Deals & Updates'),
            _toggleTile(
              icon: Icons.trending_down_outlined,
              iconBg: const Color(0xFFFFF8E1),
              iconColor: const Color(0xFFFFA000),
              title: 'Price Drops',
              subtitle: 'When saved items drop in price',
              value: _priceDrops,
              onChanged: (v) => setState(() => _priceDrops = v),
            ),
            _divider(),
            _toggleTile(
              icon: Icons.campaign_outlined,
              iconBg: const Color(0xFFFFF8E1),
              iconColor: const Color(0xFFFFA000),
              title: 'Promotions',
              subtitle: 'Special offers and featured deals',
              value: _promotions,
              onChanged: (v) => setState(() => _promotions = v),
            ),
            _divider(),
            _toggleTile(
              icon: Icons.newspaper_outlined,
              iconBg: const Color(0xFFE8F0FB),
              iconColor: AppColors.primary,
              title: 'Weekly Digest',
              subtitle: 'Weekly summary of activity',
              value: _weeklyDigest,
              onChanged: (v) => setState(() => _weeklyDigest = v),
            ),

            const SizedBox(height: 12),

            // Account
            _sectionHeader('Account'),
            _toggleTile(
              icon: Icons.security_outlined,
              iconBg: const Color(0xFFE8F8EF),
              iconColor: const Color(0xFF27AE60),
              title: 'Account Alerts',
              subtitle: 'Login, password changes, security alerts',
              value: _accountAlerts,
              onChanged: (v) => setState(() => _accountAlerts = v),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text(title,
            style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black45,
                letterSpacing: 0.5)),
      );

  Widget _toggleTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration:
                    BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87)),
                    Text(subtitle,
                        style: GoogleFonts.montserrat(
                            fontSize: 12, color: Colors.black45)),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
      );

  Widget _divider() => const Divider(
      height: 1, thickness: 1, color: Color(0xFFF0F0F0), indent: 70);
}
