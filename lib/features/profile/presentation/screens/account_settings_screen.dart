import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

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
          'Account Settings',
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

            // Account section
            _sectionHeader('Account'),
            _settingsTile(
              icon: Icons.lock_outline,
              title: 'Change Password',
              onTap: () => _showChangePassword(context),
            ),

            const SizedBox(height: 12),

            // Privacy section
            _sectionHeader('Privacy'),
            _settingsTile(
              icon: Icons.block_outlined,
              title: 'Blocked Users',
              onTap: () {},
            ),

            const SizedBox(height: 12),

            // Danger zone
            _sectionHeader('Danger Zone'),
            _settingsTile(
              icon: Icons.logout,
              iconColor: AppColors.error,
              title: 'Deactivate Account',
              titleColor: AppColors.error,
              onTap: () => _showDeactivateDialog(context),
            ),
            _divider(),
            _settingsTile(
              icon: Icons.delete_outline,
              iconColor: AppColors.error,
              title: 'Delete Account',
              titleColor: AppColors.error,
              onTap: () => _showDeleteDialog(context),
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
          onTap: onTap,
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

  void _showChangePassword(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Change Password',
                style: GoogleFonts.montserrat(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _passField(currentCtrl, 'Current Password'),
            const SizedBox(height: 12),
            _passField(newCtrl, 'New Password'),
            const SizedBox(height: 12),
            _passField(confirmCtrl, 'Confirm New Password'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: Text('Update Password',
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

  void _showDeactivateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Deactivate Account',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
        content: Text(
            'Your account will be hidden. You can reactivate it anytime by logging in.',
            style: GoogleFonts.montserrat(fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.montserrat(color: Colors.black54))),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Deactivate',
                  style: GoogleFonts.montserrat(color: AppColors.error))),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Account',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
        content: Text(
            'This will permanently delete your account and all your data. This action cannot be undone.',
            style: GoogleFonts.montserrat(fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.montserrat(color: Colors.black54))),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Delete',
                  style: GoogleFonts.montserrat(color: AppColors.error))),
        ],
      ),
    );
  }
}
