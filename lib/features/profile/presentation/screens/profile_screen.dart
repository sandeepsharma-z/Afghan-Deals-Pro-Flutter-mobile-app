import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/profile_options_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const _grey = Color(0xFF7C7D88);
  static const _border = Color(0xFFDDDDDD);

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _nationalityCtrl = TextEditingController();
  String? _gender;
  bool _loaded = false;

  void _populateFromProfile(dynamic profile) {
    if (_loaded) return;
    _loaded = true;

    final meta = Supabase.instance.client.auth.currentUser?.userMetadata ?? {};

    // Load name — profiles table first, then auth metadata fallback
    final name = (profile?.name as String?)?.isNotEmpty == true
        ? profile!.name as String
        : (meta['name'] as String? ?? '');
    final parts = name.trim().split(' ');
    _firstNameCtrl.text = (meta['first_name'] as String?)?.isNotEmpty == true
        ? meta['first_name'] as String
        : (parts.isNotEmpty ? parts.first : '');
    _lastNameCtrl.text = (meta['last_name'] as String?)?.isNotEmpty == true
        ? meta['last_name'] as String
        : (parts.length > 1 ? parts.sublist(1).join(' ') : '');

    _dobCtrl.text = (profile?.dob as String?)?.isNotEmpty == true
        ? profile!.dob as String
        : (meta['dob'] as String? ?? '');
    _nationalityCtrl.text =
        (profile?.nationality as String?)?.isNotEmpty == true
            ? profile!.nationality as String
            : (meta['nationality'] as String? ?? '');
    _gender = (profile?.gender as String?)?.isNotEmpty == true
        ? profile!.gender as String
        : meta['gender'] as String?;

    setState(() {});
  }

  Future<void> _saveChanges() async {
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final fullName = '$firstName $lastName'.trim();

    try {
      // Save all fields to profiles table
      await ref.read(profileNotifierProvider.notifier).updateProfile({
        'name': fullName,
        'phone':
            Supabase.instance.client.auth.currentUser?.userMetadata?['phone'] ??
                '',
        'nationality': _nationalityCtrl.text.trim(),
        'gender': _gender,
        'dob': _dobCtrl.text.trim().isNotEmpty ? _dobCtrl.text.trim() : null,
      });

      // Save extra fields to auth metadata
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {
          'first_name': firstName,
          'last_name': lastName,
          'name': fullName,
          'dob': _dobCtrl.text.trim(),
          'nationality': _nationalityCtrl.text.trim(),
          'gender': _gender,
        }),
      );

      // Refresh profile
      ref.invalidate(profileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showOptionPicker({
    required String title,
    required List<String> options,
    required ValueChanged<String> onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Divider(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (_, i) => ListTile(
                  title: Text(
                    options[i],
                    style: GoogleFonts.montserrat(fontSize: 14),
                  ),
                  trailing: options[i] == _nationalityCtrl.text ||
                          options[i] == _gender
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    onSelect(options[i]);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _dobCtrl.dispose();
    _nationalityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;

    // Redirect if not authenticated (only after auth state has loaded)
    if (authState.hasValue && user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(RouteNames.onboarding);
        }
      });
      return const Scaffold(body: SizedBox());
    }

    final profileAsync = ref.watch(profileProvider);
    final isSaving = ref.watch(profileNotifierProvider).isLoading;
    final nationalities =
        ref.watch(profileNationalitiesProvider).valueOrNull ?? const <String>[];
    final genders = ref.watch(profileGendersProvider).valueOrNull ??
        const ['Male', 'Female'];

    profileAsync.whenData((profile) => _populateFromProfile(profile));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black87, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'My Profile',
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
      body: profileAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (_) => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text('Profile Name',
                        style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black)),
                    const SizedBox(height: 4),
                    Text('This is displayed on your profile',
                        style:
                            GoogleFonts.montserrat(fontSize: 13, color: _grey)),
                    const SizedBox(height: 18),
                    _label('First Name'),
                    const SizedBox(height: 6),
                    _inputField(controller: _firstNameCtrl, hint: 'First Name'),
                    const SizedBox(height: 14),
                    _label('Last Name'),
                    const SizedBox(height: 6),
                    _inputField(controller: _lastNameCtrl, hint: 'Last Name'),
                    const SizedBox(height: 24),
                    const Divider(
                        height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                    const SizedBox(height: 24),
                    Text('Account details',
                        style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black)),
                    const SizedBox(height: 4),
                    Text('This is not visible to other users',
                        style:
                            GoogleFonts.montserrat(fontSize: 13, color: _grey)),
                    const SizedBox(height: 18),
                    Row(children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: Colors.black54),
                      const SizedBox(width: 6),
                      _label('Date of Birth'),
                    ]),
                    const SizedBox(height: 6),
                    _inputField(controller: _dobCtrl, hint: 'Date of Birth'),
                    const SizedBox(height: 14),
                    Row(children: [
                      const Icon(Icons.language_outlined,
                          size: 16, color: Colors.black54),
                      const SizedBox(width: 6),
                      _label('Nationality'),
                    ]),
                    const SizedBox(height: 6),
                    _dropdownField(
                      value: _nationalityCtrl.text.trim().isEmpty
                          ? 'Select nationality'
                          : _nationalityCtrl.text.trim(),
                      onTap: () => _showOptionPicker(
                        title: 'Nationality',
                        options: nationalities,
                        onSelect: (v) =>
                            setState(() => _nationalityCtrl.text = v),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      const Icon(Icons.person_outline,
                          size: 16, color: Colors.black54),
                      const SizedBox(width: 6),
                      _label('Gender'),
                    ]),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 32,
                      runSpacing: 10,
                      children: genders.map(_radioOption).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Save Changes',
                          style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.montserrat(
            fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
      );

  Widget _inputField(
          {required TextEditingController controller, required String hint}) =>
      TextField(
        controller: controller,
        style: GoogleFonts.montserrat(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.montserrat(fontSize: 14, color: Colors.black38),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _border, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      );

  Widget _dropdownField({required String value, required VoidCallback onTap}) {
    final isPlaceholder = value.startsWith('Select');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: isPlaceholder ? Colors.black38 : Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down,
                size: 20, color: Colors.black45),
          ],
        ),
      ),
    );
  }

  Widget _radioOption(String value) => GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _gender == value ? AppColors.primary : _border,
                  width: 1.5,
                ),
              ),
              child: _gender == value
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: AppColors.primary),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(value,
                style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87)),
          ],
        ),
      );
}
