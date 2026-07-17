import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/auth/app_auth.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../../core/localization/app_localizations.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _client = Supabase.instance.client;
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceAll('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
              context.l10n.t('account_settings'),
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
                _sectionHeader(context.l10n.t('account')),
                _settingsTile(
                  icon: Icons.lock_outline,
                  title: context.l10n.t('change_password'),
                  onTap: _showChangePassword,
                ),
                const SizedBox(height: 12),
                _sectionHeader(context.l10n.t('privacy')),
                _settingsTile(
                  icon: Icons.block_outlined,
                  title: context.l10n.t('blocked_users'),
                  onTap: _showBlockedUsers,
                ),
                const SizedBox(height: 12),
                _sectionHeader(context.l10n.t('danger_zone')),
                _settingsTile(
                  icon: Icons.logout,
                  iconColor: AppColors.error,
                  title: context.l10n.t('deactivate_account'),
                  titleColor: AppColors.error,
                  onTap: _showDeactivateDialog,
                ),
                _divider(),
                _settingsTile(
                  icon: Icons.delete_outline,
                  iconColor: AppColors.error,
                  title: context.l10n.t('delete_account'),
                  titleColor: AppColors.error,
                  onTap: _showDeleteDialog,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        if (_busy)
          Container(
            color: const Color(0x33000000),
            child: const Center(
                child: CircularProgressIndicator(color: Colors.white)),
          ),
      ],
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

  Widget _settingsTile({
    required IconData icon,
    required String title,
    String? trailing,
    Color? iconColor,
    Color? titleColor,
    VoidCallback? onTap,
  }) =>
      Container(
        color: Colors.white,
        child: InkWell(
          onTap: _busy ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Icon(icon, size: 22, color: iconColor ?? Colors.black54),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(title,
                      style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: titleColor ?? Colors.black87)),
                ),
                if (trailing != null) ...[
                  Text(trailing,
                      style: GoogleFonts.montserrat(
                          fontSize: 13, color: Colors.black45)),
                  const SizedBox(width: 4),
                ],
                Icon(Icons.chevron_right,
                    size: 18,
                    color: titleColor != null
                        ? titleColor.withValues(alpha: 0.5)
                        : Colors.black38),
              ],
            ),
          ),
        ),
      );

  Widget _divider() => const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF0F0F0),
      indent: 52,
      endIndent: 0);

  void _showChangePassword() {
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.t('change_password'),
                style: GoogleFonts.montserrat(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _passField(newCtrl, context.l10n.t('new_password')),
            const SizedBox(height: 12),
            _passField(confirmCtrl, context.l10n.t('confirm_password')),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final messenger = ScaffoldMessenger.of(context);
                  final l10n = context.l10n;
                  final password = newCtrl.text.trim();
                  final confirm = confirmCtrl.text.trim();
                  if (password.length < 6) {
                    _snack(l10n.t('min_6_characters'),
                        error: true);
                    return;
                  }
                  if (password != confirm) {
                    _snack(l10n.t('passwords_not_match'), error: true);
                    return;
                  }
                  Navigator.pop(sheetContext);
                  _run(() async {
                    if (AppAuth.isFirebaseAuthenticated) {
                      throw Exception('Password change is only available for email login.');
                    }
                    await _client.auth.updateUser(
                      UserAttributes(password: password),
                    );
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.t('password_updated')),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  });
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: Text(context.l10n.t('update_password'),
                    style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _passField(TextEditingController ctrl, String hint) => TextField(
        controller: ctrl,
        obscureText: true,
        style: GoogleFonts.montserrat(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.montserrat(fontSize: 14, color: Colors.black38),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      );

  void _showBlockedUsers() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => const _BlockedUsersSheet(),
    );
  }

  void _showDeactivateDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.t('deactivate_account'),
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
        content: Text(
            context.l10n.t('deactivate_account_desc'),
            style: GoogleFonts.montserrat(fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.montserrat(color: Colors.black54))),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deactivateAccount();
              },
              child: Text(context.l10n.t('deactivate'),
                  style: GoogleFonts.montserrat(color: AppColors.error))),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.t('delete_account'),
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
        content: Text(
            context.l10n.t('delete_account_desc'),
            style: GoogleFonts.montserrat(fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.montserrat(color: Colors.black54))),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteAccount();
              },
              child: Text('Delete',
                  style: GoogleFonts.montserrat(color: AppColors.error))),
        ],
      ),
    );
  }

  Future<void> _deactivateAccount() async {
    await _run(() async {
      final me = AppAuth.currentUserId;
      if (me == null || me.isEmpty) throw Exception('Please login again.');
      await _client.from('profiles').update({
        'is_active': false,
        'deactivated_at': DateTime.now().toIso8601String(),
      }).eq(AppAuth.profileIdColumn, me);
      await _client
          .from('listings')
          .update({'is_active': false}).eq('seller_id', me);
      await AppAuth.signOutAll();
      if (!mounted) return;
      context.go(RouteNames.home);
    });
  }

  Future<void> _deleteAccount() async {
    await _run(() async {
      if (AppAuth.isFirebaseAuthenticated) {
        final fbUser = fb.FirebaseAuth.instance.currentUser;
        // Best-effort removal of the Supabase profile linked to this phone user.
        try {
          await _client.rpc('delete_my_account_firebase',
              params: {'p_firebase_uid': fbUser?.uid});
        } catch (_) {}
        try {
          await fbUser?.delete();
        } on fb.FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            throw Exception(
                'For security, please log in again and then retry deleting your account.');
          }
          rethrow;
        }
      } else {
        try {
          await _client.rpc('delete_my_account');
        } catch (e) {
          throw Exception(
              'Delete account setup missing. Run ACCOUNT_SETTINGS_SQL_SETUP.sql in Supabase.');
        }
      }
      await AppAuth.signOutAll();
      if (!mounted) return;
      context.go(RouteNames.home);
    });
  }
}

class _BlockedUsersSheet extends StatefulWidget {
  const _BlockedUsersSheet();

  @override
  State<_BlockedUsersSheet> createState() => _BlockedUsersSheetState();
}

class _BlockedUsersSheetState extends State<_BlockedUsersSheet> {
  final _client = Supabase.instance.client;
  late Future<List<_BlockedUser>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_BlockedUser>> _load() async {
    final me = AppAuth.currentUserId;
    if (me == null || me.isEmpty) return const [];

    final rows = await _client
        .from('blocked_users')
        .select('id, blocked_id, created_at')
        .eq('blocker_id', me)
        .order('created_at', ascending: false);

    final blocked = <_BlockedUser>[];
    for (final row in rows as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final blockedId = map['blocked_id']?.toString() ?? '';
      Map<String, dynamic>? profile;
      try {
        profile = await _client
            .from('profiles')
            .select('name,email,phone,avatar_url')
            .eq(AppAuth.profileIdColumn, blockedId)
            .maybeSingle();
      } catch (_) {}
      blocked.add(_BlockedUser(
        id: map['id']?.toString() ?? '',
        blockedId: blockedId,
        name: profile?['name']?.toString() ??
            profile?['email']?.toString() ??
            profile?['phone']?.toString() ??
            'Unknown user',
        subtitle:
            profile?['email']?.toString() ?? profile?['phone']?.toString(),
        avatarUrl: profile?['avatar_url']?.toString(),
      ));
    }
    return blocked;
  }

  Future<void> _unblock(_BlockedUser user) async {
    await _client.from('blocked_users').delete().eq('id', user.id);
    if (!mounted) return;
    setState(() => _future = _load());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.t('user_unblocked'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Text(context.l10n.t('blocked_users_list'),
                      style: GoogleFonts.montserrat(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<_BlockedUser>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final users = snapshot.data ?? const [];
                  if (users.isEmpty) {
                    return Center(
                      child: Text(context.l10n.t('no_blocked_users'),
                          style: GoogleFonts.montserrat(
                              fontSize: 14, color: Colors.black45)),
                    );
                  }
                  return ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final user = users[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFEDEDED),
                          backgroundImage: user.avatarUrl != null &&
                                  user.avatarUrl!.trim().isNotEmpty
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                          child: user.avatarUrl == null ||
                                  user.avatarUrl!.trim().isEmpty
                              ? const Icon(Icons.person, color: Colors.black38)
                              : null,
                        ),
                        title: Text(user.name,
                            style: GoogleFonts.montserrat(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: user.subtitle == null
                            ? null
                            : Text(user.subtitle!,
                                style: GoogleFonts.montserrat(fontSize: 12)),
                        trailing: TextButton(
                          onPressed: () => _unblock(user),
                          child: Text(context.l10n.t('unblock'),
                              style: GoogleFonts.montserrat(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockedUser {
  final String id;
  final String blockedId;
  final String name;
  final String? subtitle;
  final String? avatarUrl;

  const _BlockedUser({
    required this.id,
    required this.blockedId,
    required this.name,
    this.subtitle,
    this.avatarUrl,
  });
}
