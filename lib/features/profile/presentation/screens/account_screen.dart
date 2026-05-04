import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/onboarding_screen.dart';
import '../../../home/presentation/providers/country_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/profile_options_provider.dart';
import 'profile_screen.dart';
import 'account_settings_screen.dart';
import 'notification_settings_screen.dart';
import '../../../../core/router/route_names.dart';
import 'package:go_router/go_router.dart';

class AccountScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const AccountScreen({super.key, this.embedded = false});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  static const _grey = Color(0xFF7C7D88);

  String _selectedCountry = 'Afghanistan';
  String _selectedLanguage = 'Pashto';
  bool _loadedPreferences = false;

  void _loadPreferences(dynamic profile, List<String> languages) {
    if (_loadedPreferences) return;
    _loadedPreferences = true;
    final meta = Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
    final profileCountry = profile?.country?.toString().trim() ?? '';
    final metaCountry = meta['country']?.toString().trim() ?? '';
    final metaLanguage = meta['language']?.toString().trim() ?? '';

    _selectedCountry = profileCountry.isNotEmpty
        ? profileCountry
        : (metaCountry.isNotEmpty ? metaCountry : _selectedCountry);
    _selectedLanguage = metaLanguage.isNotEmpty
        ? metaLanguage
        : (languages.contains(_selectedLanguage)
            ? _selectedLanguage
            : (languages.isNotEmpty ? languages.first : 'English'));
  }

  Future<void> _savePreference({
    String? country,
    String? language,
  }) async {
    final updates = <String, dynamic>{};
    if (country != null) updates['country'] = country;

    if (updates.isNotEmpty) {
      await ref.read(profileNotifierProvider.notifier).updateProfile(updates);
      ref.invalidate(profileProvider);
    }

    final metadata = <String, dynamic>{};
    if (country != null) metadata['country'] = country;
    if (language != null) metadata['language'] = language;
    if (metadata.isNotEmpty) {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: metadata),
      );
      ref.invalidate(authStateProvider);
    }
  }

  void _showLanguagePicker(List<String> langs) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Language',
                    style: GoogleFonts.montserrat(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: langs.length,
            itemBuilder: (_, i) {
              final lang = langs[i];
              final selected = lang == _selectedLanguage;
              return Column(
                children: [
                  ListTile(
                    title: Text(lang,
                        style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400)),
                    trailing: selected
                        ? const Icon(Icons.check, color: Color(0xFF1E56A6))
                        : null,
                    onTap: () {
                      setState(() => _selectedLanguage = lang);
                      _savePreference(language: lang);
                      Navigator.pop(context);
                    },
                  ),
                  Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: const Color(0xFFBBBBBB)),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showCountryPicker(List<String> countries, List<String> languages) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Country',
                    style: GoogleFonts.montserrat(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: countries.length,
            itemBuilder: (_, i) {
              final c = countries[i];
              final selected = c == _selectedCountry;
              return Column(
                children: [
                  ListTile(
                    title: Text(c,
                        style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400)),
                    trailing: selected
                        ? const Icon(Icons.check, color: Color(0xFF1E56A6))
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCountry = c;
                        if (!languages.contains(_selectedLanguage) &&
                            languages.isNotEmpty) {
                          _selectedLanguage = languages.first;
                        }
                      });
                      ref.read(selectedCountryProvider.notifier).setCountry(c);
                      _savePreference(
                        country: c,
                        language: _selectedLanguage,
                      );
                      Navigator.pop(context);
                    },
                  ),
                  Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: const Color(0xFFBBBBBB)),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  bool _uploadingAvatar = false;

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70, maxWidth: 512);
    if (picked == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final bytes = await picked.readAsBytes();
      final ext = picked.path.split('.').last;
      final path = 'avatars/${user.id}.$ext';

      await Supabase.instance.client.storage.from('avatars').uploadBinary(
          path, bytes,
          fileOptions: FileOptions(upsert: true, contentType: 'image/$ext'));

      final url =
          Supabase.instance.client.storage.from('avatars').getPublicUrl(path);

      await ref
          .read(profileNotifierProvider.notifier)
          .updateProfile({'avatar_url': url});
      await Supabase.instance.client.auth
          .updateUser(UserAttributes(data: {'avatar_url': url}));
      ref.invalidate(profileProvider);
      ref.invalidate(authStateProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;

    if (authState.hasValue && user == null) {
      return const OnboardingScreen();
    }

    final profile = ref.watch(profileProvider).valueOrNull;
    final countries =
        ref.watch(profileCountriesProvider).valueOrNull ?? const <String>[];
    final languages =
        ref.watch(profileLanguagesProvider(_selectedCountry)).valueOrNull ??
            const <String>['English'];
    _loadPreferences(profile, languages);

    final displayName = profile?.name?.isNotEmpty == true
        ? profile!.name!
        : (user?.name?.isNotEmpty == true
            ? user!.name!
            : (user?.email ?? user?.phone ?? 'Guest'));
    final isVerified = profile?.isVerified ?? false;
    final joinedDate = user?.createdAt != null
        ? 'Joined on ${_formatDate(user!.createdAt!)}'
        : '';
    final topInset = widget.embedded ? 0.0 : MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButtonLocation:
          widget.embedded ? null : FloatingActionButtonLocation.centerDocked,
      floatingActionButton: widget.embedded ? null : const AppSellFab(),
      bottomNavigationBar:
          widget.embedded ? null : const AppBottomNav(activeIndex: 4),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Profile card ──────────────────────────────
                  Container(
                    margin: EdgeInsets.fromLTRB(14, 14 + topInset, 14, 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x40000000),
                          blurRadius: 3,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        GestureDetector(
                          onTap: _pickAndUploadAvatar,
                          child: Stack(
                            children: [
                              Container(
                                width: 59,
                                height: 59,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color: Color(0x40000000), blurRadius: 1)
                                  ],
                                ),
                                child: ClipOval(
                                  child: _uploadingAvatar
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : (profile?.avatarUrl != null
                                          ? Image.network(profile!.avatarUrl!,
                                              fit: BoxFit.cover)
                                          : user?.avatarUrl != null
                                              ? Image.network(user!.avatarUrl!,
                                                  fit: BoxFit.cover)
                                              : Padding(
                                                  padding:
                                                      const EdgeInsets.all(6),
                                                  child: Image.asset(
                                                      'assets/images/logo-01.png',
                                                      fit: BoxFit.contain),
                                                )),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1E56A6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt,
                                      size: 10, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Info
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayName,
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: isVerified
                                        ? const Color(0xFF027329)
                                        : const Color(0xFFCCCCCC),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isVerified ? 'Verified' : 'Get Verified',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isVerified
                                            ? const Color(0xFF027329)
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: isVerified
                                            ? const Color(0xFF027329)
                                            : _grey,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check,
                                          size: 10, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (joinedDate.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                joinedDate,
                                style: GoogleFonts.montserrat(
                                    fontSize: 14, color: _grey),
                              ),
                            ],
                          ],
                        )),
                      ],
                    ),
                  ),

                  // ── Menu items ────────────────────────────────
                  const SizedBox(height: 16),
                  _flatItem(Icons.person_outline, 'Profile', null,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileScreen()))),
                  _flatItem(Icons.settings_outlined, 'Account Settings', null,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AccountSettingsScreen()))),
                  _flatItem(Icons.notifications_outlined,
                      'Notification Settings', null,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const NotificationSettingsScreen()))),
                  _line(),
                  _flatItem(
                      Icons.location_city_outlined, 'Country', _selectedCountry,
                      onTap: () => _showCountryPicker(countries, languages)),
                  _flatItem(
                      Icons.translate_outlined, 'Language', _selectedLanguage,
                      onTap: () => _showLanguagePicker(languages)),
                  _line(),
                  _flatItem(Icons.logout, 'Log Out', null, onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text('Log Out',
                            style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w600)),
                        content: Text('Are you sure you want to log out?',
                            style: GoogleFonts.montserrat()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel',
                                style: GoogleFonts.montserrat(
                                    color: Colors.black54)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Log Out',
                                style:
                                    GoogleFonts.montserrat(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(authNotifierProvider.notifier).signOut();
                      if (mounted && context.mounted) {
                        context.go(RouteNames.splash);
                      }
                    }
                  }),
                  _line(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _flatItem(IconData icon, String label, String? trailing,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () {},
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.black54),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            if (trailing != null) ...[
              Text(
                trailing,
                style:
                    GoogleFonts.montserrat(fontSize: 12, color: Colors.black45),
              ),
              const SizedBox(width: 2),
            ],
            const Icon(Icons.chevron_right, size: 18, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _line() => const Divider(
      height: 24,
      thickness: 1,
      color: Color(0xFFDDDDDD),
      indent: 16,
      endIndent: 16);

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
