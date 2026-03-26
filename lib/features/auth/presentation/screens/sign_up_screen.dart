import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure      = true;
  String? _gender;
  String? _nationality;
  DateTime? _dob;

  static const _nationalities = [
    'Afghanistan', 'Pakistan', 'India', 'Iran', 'Bangladesh',
    'Turkey', 'Saudi Arabia', 'United Arab Emirates', 'United States',
    'United Kingdom', 'China', 'Russia', 'Germany', 'France',
    'Canada', 'Australia', 'Japan', 'South Korea', 'Malaysia',
    'Indonesia', 'Egypt', 'Nigeria', 'Kenya', 'South Africa', 'Other',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authNotifierProvider.notifier).signUpWithEmail(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      gender: _gender,
      nationality: _nationality,
      dob: _dob != null
          ? '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}'
          : null,
    );
    if (success && mounted) context.go(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider) is AuthActionLoading;

    ref.listen(authNotifierProvider, (_, next) {
      if (next is AuthActionError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message,
                style: AppTextStyles.body.copyWith(color: AppColors.white)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(authNotifierProvider.notifier).reset();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, size: 30, color: AppColors.black),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppDimensions.sm),
                      Text('Create Account', style: AppTextStyles.heading2),
                      const SizedBox(height: 6),
                      Text('Fill in your details to get started', style: AppTextStyles.caption),
                      const SizedBox(height: AppDimensions.lg),

                      // Full Name
                      _label('Full Name *'),
                      const SizedBox(height: 6),
                      _field(
                        controller: _nameCtrl,
                        hint: 'Enter your full name',
                        keyboardType: TextInputType.name,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: AppDimensions.md),

                      // Email
                      _label('Email *'),
                      const SizedBox(height: 6),
                      _field(
                        controller: _emailCtrl,
                        hint: 'Enter your email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email is required';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppDimensions.md),

                      // Phone
                      _label('Phone Number'),
                      const SizedBox(height: 6),
                      _field(
                        controller: _phoneCtrl,
                        hint: 'e.g. +93700000000',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: AppDimensions.md),

                      // Date of Birth
                      _label('Date of Birth'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _pickDob,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.greyBorder),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _dob != null
                                      ? '${_dob!.day}/${_dob!.month}/${_dob!.year}'
                                      : 'Select date of birth',
                                  style: AppTextStyles.body.copyWith(
                                    color: _dob != null ? AppColors.black : AppColors.grey,
                                  ),
                                ),
                              ),
                              const Icon(Icons.calendar_today_outlined,
                                  size: 18, color: AppColors.grey),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.md),

                      // Nationality
                      _label('Nationality'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _nationality,
                        hint: Text('Select nationality',
                            style: AppTextStyles.body.copyWith(color: AppColors.grey)),
                        style: AppTextStyles.body.copyWith(color: AppColors.black),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                            borderSide: const BorderSide(color: AppColors.greyBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        items: _nationalities
                            .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                            .toList(),
                        onChanged: (v) => setState(() => _nationality = v),
                      ),
                      const SizedBox(height: AppDimensions.md),

                      // Gender
                      _label('Gender'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        hint: Text('Select gender',
                            style: AppTextStyles.body.copyWith(color: AppColors.grey)),
                        style: AppTextStyles.body.copyWith(color: AppColors.black),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                            borderSide: const BorderSide(color: AppColors.greyBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        items: ['Male', 'Female', 'Prefer not to say']
                            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                      const SizedBox(height: AppDimensions.md),

                      // Password
                      _label('Password *'),
                      const SizedBox(height: 6),
                      _field(
                        controller: _passwordCtrl,
                        hint: 'Create a password (min 6 chars)',
                        obscure: _obscure,
                        suffix: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.grey, size: 20),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password is required';
                          if (v.length < 6) return 'Minimum 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppDimensions.xl),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimensions.screenPadding, 0, AppDimensions.screenPadding, AppDimensions.md),
              child: Column(
                children: [
                  AppButton(
                    label: 'Create Account',
                    onTap: isLoading ? null : _signUp,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => context.pushReplacement(RouteNames.signIn),
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.caption,
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Sign In',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w500, color: AppColors.black));

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: AppTextStyles.body,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.grey),
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: const BorderSide(color: AppColors.greyBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
        ),
      );
}
