import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/notification_settings_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  final VoidCallback? onBackToHome;
  const NotificationSettingsScreen({super.key, this.onBackToHome});

  void _goBack(BuildContext context) {
    if (onBackToHome != null) {
      onBackToHome!();
      return;
    }
    context.go(RouteNames.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 48,
        leading: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _goBack(context),
          child: const SizedBox(
            width: 48,
            height: kToolbarHeight,
            child: Center(
              child: Icon(Icons.arrow_back_ios_new,
                  size: 18, color: Colors.black87),
            ),
          ),
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
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading settings',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () =>
                      ref.invalidate(notificationSettingsProvider),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Retry',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (settings) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _MasterToggle(
                  value: settings.pushEnabled,
                  onChanged: (v) async {
                    await ref
                        .read(notificationSettingsActionsProvider)
                        .updateSetting(userId, 'push_enabled', v);
                    ref.invalidate(notificationSettingsProvider);
                  },
                ),
                const SizedBox(height: 12),
                _SectionHeader(title: 'Messages & Activity'),
                _ToggleTile(
                  icon: Icons.chat_bubble_outline,
                  iconBg: const Color(0xFFE8F8EF),
                  iconColor: const Color(0xFF27AE60),
                  title: 'New Messages',
                  subtitle: 'When someone sends you a message',
                  value: settings.newMessages,
                  onChanged: (v) async {
                    await ref
                        .read(notificationSettingsActionsProvider)
                        .updateSetting(userId, 'new_messages', v);
                    ref.invalidate(notificationSettingsProvider);
                  },
                ),
                _Divider(),
                _ToggleTile(
                  icon: Icons.local_offer_outlined,
                  iconBg: const Color(0xFFE8F0FB),
                  iconColor: AppColors.primary,
                  title: 'New Offers',
                  subtitle: 'When someone makes an offer on your ad',
                  value: settings.newOffers,
                  onChanged: (v) async {
                    await ref
                        .read(notificationSettingsActionsProvider)
                        .updateSetting(userId, 'new_offers', v);
                    ref.invalidate(notificationSettingsProvider);
                  },
                ),
                _Divider(),
                _ToggleTile(
                  icon: Icons.favorite_border,
                  iconBg: const Color(0xFFFEEBEB),
                  iconColor: const Color(0xFFC92325),
                  title: 'Saved Ad Activity',
                  subtitle: 'When someone saves your listing',
                  value: settings.savedAds,
                  onChanged: (v) async {
                    await ref
                        .read(notificationSettingsActionsProvider)
                        .updateSetting(userId, 'saved_ads', v);
                    ref.invalidate(notificationSettingsProvider);
                  },
                ),
                const SizedBox(height: 12),
                _SectionHeader(title: 'Deals & Updates'),
                _ToggleTile(
                  icon: Icons.trending_down_outlined,
                  iconBg: const Color(0xFFFFF8E1),
                  iconColor: const Color(0xFFFFA000),
                  title: 'Price Drops',
                  subtitle: 'When saved items drop in price',
                  value: settings.priceDrops,
                  onChanged: (v) async {
                    await ref
                        .read(notificationSettingsActionsProvider)
                        .updateSetting(userId, 'price_drops', v);
                    ref.invalidate(notificationSettingsProvider);
                  },
                ),
                _Divider(),
                _ToggleTile(
                  icon: Icons.campaign_outlined,
                  iconBg: const Color(0xFFFFF8E1),
                  iconColor: const Color(0xFFFFA000),
                  title: 'Promotions',
                  subtitle: 'Special offers and featured deals',
                  value: settings.promotions,
                  onChanged: (v) async {
                    await ref
                        .read(notificationSettingsActionsProvider)
                        .updateSetting(userId, 'promotions', v);
                    ref.invalidate(notificationSettingsProvider);
                  },
                ),
                _Divider(),
                _ToggleTile(
                  icon: Icons.newspaper_outlined,
                  iconBg: const Color(0xFFE8F0FB),
                  iconColor: AppColors.primary,
                  title: 'Weekly Digest',
                  subtitle: 'Weekly summary of activity',
                  value: settings.weeklyDigest,
                  onChanged: (v) async {
                    await ref
                        .read(notificationSettingsActionsProvider)
                        .updateSetting(userId, 'weekly_digest', v);
                    ref.invalidate(notificationSettingsProvider);
                  },
                ),
                const SizedBox(height: 12),
                _SectionHeader(title: 'Account'),
                _ToggleTile(
                  icon: Icons.security_outlined,
                  iconBg: const Color(0xFFE8F8EF),
                  iconColor: const Color(0xFF27AE60),
                  title: 'Account Alerts',
                  subtitle: 'Login, password changes, security alerts',
                  value: settings.accountAlerts,
                  onChanged: (v) async {
                    await ref
                        .read(notificationSettingsActionsProvider)
                        .updateSetting(userId, 'account_alerts', v);
                    ref.invalidate(notificationSettingsProvider);
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MasterToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MasterToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
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
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(title,
          style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black45,
              letterSpacing: 0.5)),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
        height: 1, thickness: 1, color: Color(0xFFF0F0F0), indent: 70);
  }
}
