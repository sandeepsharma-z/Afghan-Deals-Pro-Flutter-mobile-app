import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _notifications = [
    _NotifData(
      icon: Icons.local_offer_outlined,
      iconColor: Color(0xFF1E56A6),
      iconBg: Color(0xFFE8F0FB),
      title: 'New offer on your listing',
      subtitle: 'Someone made an offer on your Toyota Corolla 2020',
      time: '2 min ago',
      isRead: false,
    ),
    _NotifData(
      icon: Icons.chat_bubble_outline,
      iconColor: Color(0xFF27AE60),
      iconBg: Color(0xFFE8F8EF),
      title: 'New message received',
      subtitle: 'Ahmad sent you a message about your iPhone 14 listing',
      time: '15 min ago',
      isRead: false,
    ),
    _NotifData(
      icon: Icons.favorite_border,
      iconColor: Color(0xFFC92325),
      iconBg: Color(0xFFFEEBEB),
      title: 'Someone saved your ad',
      subtitle: 'Your listing "2BHK Apartment Kabul" was saved by 3 people',
      time: '1 hr ago',
      isRead: true,
    ),
    _NotifData(
      icon: Icons.verified_outlined,
      iconColor: Color(0xFF1E56A6),
      iconBg: Color(0xFFE8F0FB),
      title: 'Profile verified!',
      subtitle: 'Your profile has been successfully verified',
      time: '2 hr ago',
      isRead: true,
    ),
    _NotifData(
      icon: Icons.campaign_outlined,
      iconColor: Color(0xFFFFA000),
      iconBg: Color(0xFFFFF8E1),
      title: 'Featured ad expiring soon',
      subtitle: 'Your featured listing expires in 24 hours. Renew now!',
      time: 'Yesterday',
      isRead: true,
    ),
    _NotifData(
      icon: Icons.star_outline,
      iconColor: Color(0xFFFFA000),
      iconBg: Color(0xFFFFF8E1),
      title: 'New review received',
      subtitle: 'Reza gave you a 5-star rating for your transaction',
      time: '2 days ago',
      isRead: true,
    ),
  ];

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
          'Notifications',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 28 / 15,
            letterSpacing: 0,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {},
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
      body: _notifications.isEmpty
          ? _buildEmpty()
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 1),
              itemBuilder: (_, i) => _NotifTile(data: _notifications[i]),
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
  final _NotifData data;
  const _NotifTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: data.isRead ? Colors.white : const Color(0xFFF0F5FF),
      child: InkWell(
        onTap: () {},
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
                  color: data.iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, size: 22, color: data.iconColor),
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
                            data.title,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: data.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (!data.isRead)
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
                      data.subtitle,
                      style: GoogleFonts.montserrat(
                          fontSize: 13, color: Colors.black54, height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.time,
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

class _NotifData {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String time;
  final bool isRead;

  const _NotifData({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isRead,
  });
}
