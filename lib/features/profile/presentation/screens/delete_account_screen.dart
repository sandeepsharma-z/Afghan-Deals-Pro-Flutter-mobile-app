import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../delete_account.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool isDeleting = false;
  bool confirmed = false;

  Future<void> _handleDeleteAccount() async {
    if (!confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please confirm account deletion', style: AppTextStyles.body.copyWith(color: AppColors.white)),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => isDeleting = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      await DeleteAccountService.deleteUserAccount(userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account deleted successfully', style: AppTextStyles.body.copyWith(color: AppColors.white)),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/sign-in', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}', style: AppTextStyles.body.copyWith(color: AppColors.white)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Delete Account', style: AppTextStyles.heading3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: AppColors.redLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.red),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ Warning',
                      style: AppTextStyles.bodyBold.copyWith(color: AppColors.red),
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    Text(
                      'Deleting your account is permanent and cannot be undone. All your data will be deleted:',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    Text(
                      '• Profile & personal information\n• All listings\n• Chat history\n• Favorites & bookmarks',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.lg),

              // Confirmation Checkbox
              Row(
                children: [
                  Checkbox(
                    value: confirmed,
                    onChanged: (val) => setState(() => confirmed = val ?? false),
                  ),
                  Expanded(
                    child: Text(
                      'I understand that this action is permanent and cannot be reversed',
                      style: AppTextStyles.body,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.lg),

              // Delete Button
              AppButton(
                label: isDeleting ? 'Deleting...' : 'Delete My Account',
                onTap: isDeleting ? null : _handleDeleteAccount,
                type: AppButtonType.primary,
                fullWidth: true,
                isLoading: isDeleting,
              ),
              const SizedBox(height: AppDimensions.md),

              // Cancel Button
              AppButton(
                label: 'Cancel',
                onTap: () => Navigator.pop(context),
                type: AppButtonType.outline,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
