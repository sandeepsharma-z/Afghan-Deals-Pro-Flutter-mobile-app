import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/auth_provider.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthActionLoading;

    ref.listen(authNotifierProvider, (_, next) {
      if (next is AuthActionError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message, style: AppTextStyles.body.copyWith(color: AppColors.white)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          ),
        );
        ref.read(authNotifierProvider.notifier).reset();
      }
      if (next is AuthActionSuccess) {
        context.go(RouteNames.home);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.black),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: AppColors.grey),
                      const SizedBox(width: 4),
                      Text('Help', style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
                child: Column(
                  children: [
                    const SizedBox(height: AppDimensions.md),

                    Image.asset('assets/images/logo.png', width: 130, height: 130, fit: BoxFit.contain),
                    const SizedBox(height: 20),

                    Text(
                      'Welcome to AFGHAN DEALS PRO',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: 10),

                    Text(
                      'The trusted community of\nbuyers and sellers',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: AppDimensions.xl),

                    // Continue with Phone
                    _OutlineButton(
                      onTap: () => context.push(RouteNames.phoneLogin),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.smartphone_outlined, size: 20, color: AppColors.black),
                          const SizedBox(width: 10),
                          Text('Continue with Phone', style: AppTextStyles.label),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),

                    // Continue with Google
                    _OutlineButton(
                      onTap: isLoading ? null : () async {
                        await ref.read(authNotifierProvider.notifier).signInWithGoogle();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _GoogleIcon(),
                          const SizedBox(width: 10),
                          Text('Continue with Google', style: AppTextStyles.label),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),

                    // Sign in with Apple
                    AppButton(
                      label: 'Sign in with Apple',
                      onTap: isLoading ? null : () async {
                        await ref.read(authNotifierProvider.notifier).signInWithApple();
                      },
                      isLoading: isLoading,
                      prefixIcon: const Icon(Icons.apple, size: 22, color: AppColors.white),
                    ),

                    const SizedBox(height: 20),

                    // OR divider
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.greyBorder, thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('OR', style: AppTextStyles.small),
                        ),
                        const Expanded(child: Divider(color: AppColors.greyBorder, thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.md),

                    // Login with Email
                    GestureDetector(
                      onTap: () => context.push(RouteNames.signIn),
                      child: Text(
                        'Login with Email',
                        style: AppTextStyles.bodyBold.copyWith(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppDimensions.lg),

                    // Terms
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AppTextStyles.small.copyWith(height: 1.6),
                        children: [
                          const TextSpan(text: 'If you continue, you are accepting\n'),
                          TextSpan(
                            text: 'AFGHAN DEALS PRO Terms and Conditions\nand Privacy Policy',
                            style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600, color: AppColors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _OutlineButton({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: AppDimensions.buttonHeight,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          border: Border.all(color: AppColors.greyBorder, width: 1.2),
        ),
        child: child,
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
  <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
  <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z" fill="#FBBC05"/>
  <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_svg, width: 20, height: 20);
  }
}
