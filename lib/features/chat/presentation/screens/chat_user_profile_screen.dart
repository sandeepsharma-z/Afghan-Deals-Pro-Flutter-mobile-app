import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import '../../../../../core/auth/app_auth.dart';
import '../../data/models/chat_thread_model.dart';
import '../providers/chat_provider.dart';
import '../../../../../core/localization/app_localizations.dart';

final chatUserProfileProvider = FutureProvider.autoDispose
    .family<_ChatUserProfileData, ChatThreadModel>((ref, thread) async {
  final client = Supabase.instance.client;
  final me = AppAuth.currentUserId;
  Map<String, dynamic>? profile;
  int listingsCount = 0;
  bool isBlocked = false;

  try {
    profile = await client
        .from('profiles')
        .select()
        .eq(AppAuth.profileIdColumn, thread.peerId)
        .maybeSingle();
  } catch (_) {
    profile = null;
  }

  try {
    final rows = await client
        .from('listings')
        .select('id')
        .eq('seller_id', thread.peerId);
    listingsCount = (rows as List<dynamic>).length;
  } catch (_) {
    listingsCount = 0;
  }

  if (me != null && me.isNotEmpty) {
    try {
      final row = await client
          .from('blocked_users')
          .select('id')
          .eq('blocker_id', me)
          .eq('blocked_id', thread.peerId)
          .maybeSingle();
      isBlocked = row != null;
    } catch (_) {
      isBlocked = false;
    }
  }

  return _ChatUserProfileData(
    id: thread.peerId,
    name: _firstText(profile, const ['name', 'full_name']) ?? thread.peerName,
    email: _firstText(profile, const ['email']),
    phone: _firstText(profile, const ['phone']),
    avatarUrl: _firstText(profile, const ['avatar_url', 'avatar']),
    country: _firstText(profile, const ['country']),
    city: _firstText(profile, const ['city', 'region']),
    isVerified: profile?['is_verified'] == true,
    createdAt: DateTime.tryParse(profile?['created_at']?.toString() ?? ''),
    listingsCount: listingsCount,
    isBlocked: isBlocked,
  );
});

class ChatUserProfileScreen extends ConsumerStatefulWidget {
  final ChatThreadModel thread;

  const ChatUserProfileScreen({super.key, required this.thread});

  @override
  ConsumerState<ChatUserProfileScreen> createState() =>
      _ChatUserProfileScreenState();
}

class _ChatUserProfileScreenState extends ConsumerState<ChatUserProfileScreen> {
  bool _reporting = false;
  bool _blocking = false;
  bool? _blockedOverride;

  Future<void> _reportUser(_ChatUserProfileData user) async {
    final reason = await _pickReportReason();
    if (reason == null || !mounted) return;

    setState(() => _reporting = true);
    try {
      await _insertAdminUserReport(
        user: user,
        reason: reason,
        description:
            'Reported from chat for listing: ${widget.thread.listingTitle}',
      );
      await _insertAppNotification(
        type: 'report',
        title: 'Report submitted',
        subtitle: 'Admin will review your report against ${user.name}.',
        iconType: 'report',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.t('report_submitted'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _reporting = false);
    }
  }

  Future<void> _blockUser(_ChatUserProfileData user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${context.l10n.t('block')} ${user.name}?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          context.l10n.t('block_user_desc'),
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.t('block'),
                style: GoogleFonts.poppins(color: const Color(0xFFC92325))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _blocking = true);
    try {
      await ref.read(chatActionsProvider).blockUser(
            blockedUserId: user.id,
            chatId: widget.thread.id,
          );
      unawaited(_insertAdminUserReport(
        user: user,
        reason: 'Blocked user',
        description:
            'User blocked from chat for listing: ${widget.thread.listingTitle}',
      ).catchError((Object _) {}));
      unawaited(_insertAppNotification(
        type: 'block',
        title: 'User blocked',
        subtitle: '${user.name} can no longer chat with you.',
        iconType: 'block',
      ).catchError((Object _) {}));
      ref.invalidate(chatThreadsProvider);
      ref.invalidate(chatThreadByIdProvider(widget.thread.id));
      ref.invalidate(isChatBlockedProvider(widget.thread.id));
      ref.invalidate(chatUserProfileProvider(widget.thread));

      if (mounted) {
        setState(() => _blockedOverride = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.t('user_blocked_chat_disabled'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _blocking = false);
    }
  }

  Future<void> _unblockUser(_ChatUserProfileData user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${context.l10n.t('unblock')} ${user.name}?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          context.l10n.t('unblock_user_desc'),
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.t('unblock'),
                style: GoogleFonts.poppins(color: const Color(0xFF2258A8))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _blocking = true);
    try {
      await ref.read(chatActionsProvider).unblockUser(blockedUserId: user.id);
      ref.invalidate(chatThreadsProvider);
      ref.invalidate(chatThreadByIdProvider(widget.thread.id));
      ref.invalidate(isChatBlockedProvider(widget.thread.id));
      ref.invalidate(chatUserProfileProvider(widget.thread));

      if (mounted) {
        setState(() => _blockedOverride = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.t('user_unblocked_chat_enabled'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _blocking = false);
    }
  }

  Future<void> _insertAdminUserReport({
    required _ChatUserProfileData user,
    required String reason,
    required String description,
  }) async {
    final client = Supabase.instance.client;
    final payload = <String, dynamic>{
      'title': reason.isNotEmpty ? reason : 'User Report',
      'type': 'user',
      'target_id': user.id,
      'target_title': user.name,
      'reason': reason.isNotEmpty ? reason : 'Reported',
      'description':
          description.isNotEmpty ? description : 'No details provided',
      'reported_by': AppAuth.currentUserId,
      'status': 'open',
    };
    const optionalOrder = [
      'status',
      'reported_by',
      'target_title',
      'target_id',
      'type',
      'description',
    ];

    for (var i = 0; i < 10; i++) {
      try {
        await client.from('reports').insert(payload);
        return;
      } on PostgrestException catch (e) {
        // Handle constraint violations by removing optional fields
        if (e.code == '23502' || e.code == 'PGRST204') {
          final missingColumn =
              RegExp("'([^']+)' column").firstMatch(e.message);
          final column = missingColumn?.group(1);
          if (column != null && payload.containsKey(column)) {
            payload.remove(column);
            continue;
          }
          final keyToRemove = optionalOrder
              .where(payload.containsKey)
              .cast<String?>()
              .firstWhere((key) => key != null, orElse: () => null);
          if (keyToRemove != null) {
            payload.remove(keyToRemove);
            continue;
          }
        }
        // Silent fail for reports - not critical
        return;
      }
    }

    // Silent fail - reporting is non-critical
  }

  Future<void> _insertAppNotification({
    required String type,
    required String title,
    required String subtitle,
    required String iconType,
  }) async {
    final client = Supabase.instance.client;
    final userId = AppAuth.currentUserId;
    if (userId == null || userId.isEmpty) return;

    final payload = <String, dynamic>{
      'user_id': userId,
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'icon_type': iconType,
      'is_read': false,
      'action_url': '/notifications',
    };
    const optionalOrder = ['action_url', 'is_read', 'icon_type', 'type'];

    for (var i = 0; i < 8; i++) {
      try {
        await client.from('notifications').insert(payload);
        return;
      } on PostgrestException catch (e) {
        final missingColumn = RegExp("'([^']+)' column").firstMatch(e.message);
        final column = missingColumn?.group(1);
        if (e.code == 'PGRST204') {
          if (column != null && payload.containsKey(column)) {
            payload.remove(column);
            continue;
          }
          final keyToRemove = optionalOrder
              .where(payload.containsKey)
              .cast<String?>()
              .firstWhere((key) => key != null, orElse: () => null);
          if (keyToRemove != null) {
            payload.remove(keyToRemove);
            continue;
          }
        }
        return;
      } catch (_) {
        return;
      }
    }
  }

  Future<String?> _pickReportReason() {
    const reasons = [
      'Fraud or scam',
      'Abusive behavior',
      'Spam messages',
      'Wrong listing information',
      'Other',
    ];
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(context.l10n.t('report_user'),
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            for (final reason in reasons)
              ListTile(
                title: Text(reason,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => Navigator.pop(context, reason),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(chatUserProfileProvider(widget.thread));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.l10n.t('user_profile'),
            style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(e.toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ),
        data: (user) {
          final isBlocked = _blockedOverride ?? user.isBlocked;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE9E9E9)),
                ),
                child: Column(
                  children: [
                    _avatar(user),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87),
                          ),
                        ),
                        if (user.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified,
                              size: 18, color: Color(0xFF027329)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _location(user),
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.black54),
                    ),
                    if (isBlocked) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEEBEB),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: const Color(0xFFC92325)
                                  .withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          context.l10n.t('blocked'),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFC92325),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child:
                              _stat(context.l10n.t('listings'), user.listingsCount.toString()),
                        ),
                        Expanded(
                          child: _stat(context.l10n.t('member_since'), _memberSince(user)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _infoCard(user),
              const SizedBox(height: 12),
              _listingCard(),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _outlineButton(
                      icon: Icons.flag_outlined,
                      label: _reporting ? '${context.l10n.t('reporting')}...' : context.l10n.t('report'),
                      color: const Color(0xFFC92325),
                      onTap: _reporting ? null : () => _reportUser(user),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _outlineButton(
                      icon: isBlocked ? Icons.block : Icons.block_outlined,
                      label: isBlocked
                          ? context.l10n.t('blocked')
                          : (_blocking ? '${context.l10n.t('blocking')}...' : context.l10n.t('block')),
                      color: const Color(0xFFC92325),
                      onTap: _blocking
                          ? null
                          : (isBlocked
                              ? () => _unblockUser(user)
                              : () => _blockUser(user)),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _avatar(_ChatUserProfileData user) {
    final avatarUrl = user.avatarUrl;
    return Container(
      width: 86,
      height: 86,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFEFF2F8),
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl != null && avatarUrl.isNotEmpty
          ? Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _avatarFallback(),
            )
          : _avatarFallback(),
    );
  }

  Widget _avatarFallback() =>
      const Icon(Icons.person, size: 42, color: Color(0xFF8C98A8));

  Widget _stat(String label, String value) => Column(
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.black45)),
        ],
      );

  Widget _infoCard(_ChatUserProfileData user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9E9E9)),
      ),
      child: Column(
        children: [
          _infoRow(Icons.email_outlined, context.l10n.t('email'), user.email ?? context.l10n.t('not_shared')),
          _divider(),
          _infoRow(Icons.phone_outlined, context.l10n.t('phone'), user.phone ?? context.l10n.t('not_shared')),
          _divider(),
          _infoRow(Icons.location_on_outlined, context.l10n.t('location'), _location(user)),
        ],
      ),
    );
  }

  Widget _listingCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9E9E9)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: widget.thread.listingImageUrl != null &&
                    widget.thread.listingImageUrl!.isNotEmpty
                ? Image.network(widget.thread.listingImageUrl!,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _listingFallback())
                : _listingFallback(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.t('chat_listing'),
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.black45)),
                const SizedBox(height: 3),
                Text(
                  widget.thread.listingTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _listingFallback() => Container(
        width: 54,
        height: 54,
        color: const Color(0xFFEFF2F8),
        child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF8C98A8)),
      );

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2258A8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.black45)),
                const SizedBox(height: 2),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFF0F0F0),
        indent: 46,
      );

  Widget _outlineButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: color),
        label: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.35)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  String _location(_ChatUserProfileData user) {
    final parts = [
      if (user.city != null && user.city!.trim().isNotEmpty) user.city!.trim(),
      if (user.country != null && user.country!.trim().isNotEmpty)
        user.country!.trim(),
    ];
    return parts.isEmpty ? context.l10n.t('location_not_shared') : parts.join(', ');
  }

  String _memberSince(_ChatUserProfileData user) {
    final dt = user.createdAt;
    if (dt == null) return '-';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

class _ChatUserProfileData {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? country;
  final String? city;
  final bool isVerified;
  final DateTime? createdAt;
  final int listingsCount;
  final bool isBlocked;

  const _ChatUserProfileData({
    this.id = '',
    this.name = 'User',
    this.email,
    this.phone,
    this.avatarUrl,
    this.country,
    this.city,
    this.isVerified = false,
    this.createdAt,
    this.listingsCount = 0,
    this.isBlocked = false,
  });
}

String? _firstText(Map<String, dynamic>? map, List<String> keys) {
  if (map == null) return null;
  for (final key in keys) {
    final value = map[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}
