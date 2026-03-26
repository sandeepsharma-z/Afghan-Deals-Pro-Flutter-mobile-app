import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/auth_provider.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _focusNode = FocusNode();

  String _countryCode = '+93';
  String _countryFlag = '🇦🇫';

  static const _countries = [
    ('🇦🇫', 'Afghanistan', '+93'),
    ('🇵🇰', 'Pakistan',    '+92'),
    ('🇮🇳', 'India',       '+91'),
    ('🇦🇪', 'UAE',         '+971'),
    ('🇸🇦', 'Saudi Arabia','+966'),
    ('🇶🇦', 'Qatar',       '+974'),
    ('🇴🇲', 'Oman',        '+968'),
    ('🇮🇷', 'Iran',        '+98'),
    ('🇸🇾', 'Syria',       '+963'),
    ('🇹🇷', 'Turkey',      '+90'),
    ('🇩🇪', 'Germany',     '+49'),
    ('🇬🇧', 'UK',          '+44'),
    ('🇺🇸', 'USA',         '+1'),
  ];

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Select Country Code',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          const Divider(),
          ..._countries.map((c) => ListTile(
                leading: Text(c.$1, style: const TextStyle(fontSize: 24)),
                title: Text(c.$2),
                trailing: Text(c.$3,
                    style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                onTap: () {
                  setState(() {
                    _countryFlag = c.$1;
                    _countryCode = c.$3;
                  });
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = '$_countryCode${_phoneController.text.trim()}';
    if (_phoneController.text.trim().isEmpty) return;

    final success = await ref.read(authNotifierProvider.notifier).sendPhoneOtp(phone);
    if (success && mounted) {
      context.push('/otp/${Uri.encodeComponent(phone)}');
    }
  }

  @override
  Widget build(BuildContext context) {
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
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Faded logo watermark
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Opacity(
                  opacity: 0.08,
                  child: Image.asset('assets/images/logo.png', width: 220, height: 220, fit: BoxFit.contain),
                ),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 8),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, size: 30, color: AppColors.black),
                    onPressed: () => context.pop(),
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: AppDimensions.lg),

                        Text(
                          'Enter your Phone\nNumber',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading2,
                        ),
                        const SizedBox(height: AppDimensions.sm),

                        Text(
                          'We will send a confirmation code to your phone',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(height: 1.5),
                        ),
                        const SizedBox(height: AppDimensions.lg),

                        // Phone input
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                            border: Border.all(color: AppColors.greyBorder, width: 1.2),
                          ),
                          child: Row(
                            children: [
                              // Country code selector
                              GestureDetector(
                                onTap: _showCountryPicker,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(_countryFlag, style: const TextStyle(fontSize: 18)),
                                      const SizedBox(width: 6),
                                      Text(_countryCode, style: AppTextStyles.bodyBold),
                                      const SizedBox(width: 2),
                                      const Icon(Icons.arrow_drop_down, size: 18, color: Colors.black54),
                                    ],
                                  ),
                                ),
                              ),
                              Container(height: 24, width: 1, color: AppColors.greyBorder),
                              Expanded(
                                child: TextField(
                                  controller: _phoneController,
                                  focusNode: _focusNode,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(12),
                                  ],
                                  style: AppTextStyles.body,
                                  decoration: InputDecoration(
                                    hintText: 'Phone number',
                                    hintStyle: AppTextStyles.body.copyWith(color: AppColors.grey),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                  onSubmitted: (_) => _sendOtp(),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),
                      ],
                    ),
                  ),
                ),

                // Next button
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.screenPadding,
                    0,
                    AppDimensions.screenPadding,
                    AppDimensions.xl,
                  ),
                  child: AppButton(
                    label: 'Next',
                    onTap: isLoading ? null : _sendOtp,
                    isLoading: isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
