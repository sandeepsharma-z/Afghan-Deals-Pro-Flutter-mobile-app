import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String? phoneNumber;
  final String? email;

  const OtpScreen({super.key, this.phoneNumber, this.email})
      : assert(phoneNumber != null || email != null,
            'Either phoneNumber or email must be provided');

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _secondsLeft = 60;
  Timer? _timer;

  bool get _isEmail => widget.email != null;
  String get _target => widget.email ?? widget.phoneNumber ?? '';

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _resend() async {
    for (var c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
    if (_isEmail) {
      await ref.read(authNotifierProvider.notifier).sendEmailOtp(widget.email!);
    } else {
      await ref.read(authNotifierProvider.notifier).sendPhoneOtp(widget.phoneNumber!);
    }
    _startTimer();
  }

  void _onChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (index == 5 && value.length == 1) {
      _verify();
    }
  }

  String get _otp => _controllers.map((c) => c.text).join();

  String get _formattedTime {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _verify() async {
    if (_otp.length < 6) return;

    bool success;
    if (_isEmail) {
      success = await ref.read(authNotifierProvider.notifier).verifyEmailOtp(
            email: widget.email!,
            otp: _otp,
          );
    } else {
      success = await ref.read(authNotifierProvider.notifier).verifyPhoneOtp(
            phone: widget.phoneNumber!,
            otp: _otp,
          );
    }

    if (success && mounted) {
      context.go(RouteNames.home);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthActionLoading;

    ref.listen(authNotifierProvider, (_, next) {
      if (next is AuthActionError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message,
                style: AppTextStyles.body.copyWith(color: AppColors.white)),
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
            Positioned(
              bottom: 100, left: 0, right: 0,
              child: Center(
                child: Opacity(
                  opacity: 0.08,
                  child: Image.asset('assets/images/logo-01.png',
                      width: 220, height: 220, fit: BoxFit.contain),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.screenPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppDimensions.lg),

                        Text('Enter verification\ncode', style: AppTextStyles.heading2),
                        const SizedBox(height: AppDimensions.sm),

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'We sent a 6-digit code to $_target',
                                style: AppTextStyles.caption.copyWith(height: 1.5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: const Icon(Icons.edit_square,
                                  size: 20, color: AppColors.grey),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppDimensions.xl),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            return _OtpBox(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              onChanged: (val) => _onChanged(val, index),
                            );
                          }),
                        ),

                        const SizedBox(height: AppDimensions.lg),

                        Center(
                          child: Column(
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: AppTextStyles.caption,
                                  children: [
                                    const TextSpan(text: "Didn't get the code? "),
                                    WidgetSpan(
                                      child: GestureDetector(
                                        onTap: _secondsLeft == 0 && !isLoading
                                            ? _resend
                                            : null,
                                        child: Text(
                                          'Resend',
                                          style: AppTextStyles.caption.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: _secondsLeft == 0
                                                ? AppColors.primary
                                                : AppColors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              RichText(
                                text: TextSpan(
                                  style: AppTextStyles.caption,
                                  children: [
                                    const TextSpan(text: 'Expires in '),
                                    TextSpan(
                                      text: _formattedTime,
                                      style: AppTextStyles.caption.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
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

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.screenPadding,
                    0,
                    AppDimensions.screenPadding,
                    AppDimensions.xl,
                  ),
                  child: AppButton(
                    label: 'Submit',
                    onTap: isLoading ? null : _verify,
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

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        style: AppTextStyles.heading3,
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: const BorderSide(color: AppColors.greyBorder, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
          ),
        ),
      ),
    );
  }
}
