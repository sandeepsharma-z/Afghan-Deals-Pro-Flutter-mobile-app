import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/notification_model.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  final VoidCallback? onBackToHome;
  const NotificationsScreen({super.key, this.onBackToHome});

  void _goBack(BuildContext context) {
    if (onBackToHome != null) {
      onBackToHome!();
      return;
    }
    context.go(RouteNames.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
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
          'Notifications',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 28 / 15,
            letterSpacing: 0,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              await ref
                  .read(notificationsActionsProvider)
                  .markAllAsRead(userId);
              ref.invalidate(notificationsProvider);
            },
            child: Text(
              'Mark all read',
              style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: const Color(0xFF1E56A6),
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
        ),
      ),
      body: notificationsAsync.when(
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
                  'Error loading notifications',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => ref.invalidate(notificationsProvider),
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
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmpty();
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 1),
            itemBuilder: (_, i) => _NotifTile(
              notification: notifications[i],
              onMarkAsRead: () async {
                await ref
                    .read(notificationsActionsProvider)
                    .markAsRead(notifications[i].id);
                ref.invalidate(notificationsProvider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F0FB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none_outlined,
                  size: 40, color: Color(0xFF1E56A6)),
            ),
            const SizedBox(height: 16),
            Text('No notifications yet',
                style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
            const SizedBox(height: 8),
            Text("You're all caught up!",
                style: GoogleFonts.montserrat(
                    fontSize: 14, color: Colors.black45)),
          ],
        ),
      );
}

class _NotifTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onMarkAsRead;

  const _NotifTile({
    required this.notification,
    required this.onMarkAsRead,
  });

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Map<String, dynamic> _getIconData(String iconType) {
    const iconMap = {
      'offer': {
        'icon': Icons.local_offer_outlined,
        'color': Color(0xFF1E56A6),
        'bg': Color(0xFFE8F0FB),
      },
      'message': {
        'icon': Icons.chat_bubble_outline,
        'color': Color(0xFF27AE60),
        'bg': Color(0xFFE8F8EF),
      },
      'favorite': {
        'icon': Icons.favorite_border,
        'color': Color(0xFFC92325),
        'bg': Color(0xFFFEEBEB),
      },
      'verified': {
        'icon': Icons.verified_outlined,
        'color': Color(0xFF1E56A6),
        'bg': Color(0xFFE8F0FB),
      },
      'featured': {
        'icon': Icons.campaign_outlined,
        'color': Color(0xFFFFA000),
        'bg': Color(0xFFFFF8E1),
      },
      'review': {
        'icon': Icons.star_outline,
        'color': Color(0xFFFFA000),
        'bg': Color(0xFFFFF8E1),
      },
      'report': {
        'icon': Icons.flag_outlined,
        'color': Color(0xFFC92325),
        'bg': Color(0xFFFEEBEB),
      },
      'block': {
        'icon': Icons.block,
        'color': Color(0xFFC92325),
        'bg': Color(0xFFFEEBEB),
      },
    };

    return iconMap[iconType] ??
        {
          'icon': Icons.notifications_outlined,
          'color': const Color(0xFF1E56A6),
          'bg': const Color(0xFFE8F0FB),
        };
  }

  @override
  Widget build(BuildContext context) {
    final iconData = _getIconData(notification.iconType);

    return Container(
      color: notification.isRead ? Colors.white : const Color(0xFFF0F5FF),
      child: InkWell(
        onTap: onMarkAsRead,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconData['bg'] as Color,
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData['icon'] as IconData,
                    size: 22, color: iconData['color'] as Color),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E56A6),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.subtitle,
                      style: GoogleFonts.montserrat(
                          fontSize: 13, color: Colors.black54, height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(notification.createdAt),
                      style: GoogleFonts.montserrat(
                          fontSize: 12, color: Colors.black38),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
