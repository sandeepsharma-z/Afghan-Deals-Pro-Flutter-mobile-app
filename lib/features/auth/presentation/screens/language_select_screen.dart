import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Shown on first launch, before anything else, so a user who reads no English
/// never has to find the language setting. Each language is written in its own
/// script and picking one takes you straight into the app.
class LanguageSelectScreen extends ConsumerWidget {
  /// When opened from inside the app there is a back button and picking a
  /// language pops instead of navigating home.
  final bool isFirstRun;

  const LanguageSelectScreen({super.key, this.isFirstRun = true});

  // Pashto first: most of our users are in Afghanistan.
  static const _order = ['ps', 'fa', 'ur', 'en'];

  static List<AppLanguage> get _languages {
    final byCode = {for (final l in supportedAppLanguages) l.code: l};
    return [
      for (final code in _order)
        if (byCode[code] != null) byCode[code]!,
    ];
  }

  Future<void> _select(
      BuildContext context, WidgetRef ref, AppLanguage language) async {
    await ref.read(appLanguageProvider.notifier).setLocale(language.locale);
    if (!context.mounted) return;
    if (isFirstRun) {
      context.go(RouteNames.home);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(appLanguageProvider).languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isFirstRun
          ? null
          : AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              foregroundColor: AppColors.black,
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: isFirstRun ? AppDimensions.xxl : AppDimensions.sm),
              Image.asset(
                'assets/images/logo.png',
                height: 72,
                errorBuilder: (_, __, ___) => const SizedBox(height: 72),
              ),
              const SizedBox(height: AppDimensions.lg),
              // The prompt is repeated in every language so it is readable
              // whatever the user speaks.
              Text(
                'خپله ژبه وټاکئ',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: AppDimensions.xs),
              Text(
                'زبان خود را انتخاب کنید  •  اپنی زبان منتخب کریں',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.caption,
              ),
              Text(
                'Choose your language',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppDimensions.lg),
              Expanded(
                child: ListView.separated(
                  itemCount: _languages.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppDimensions.sm + 4),
                  itemBuilder: (context, i) {
                    final language = _languages[i];
                    return _LanguageTile(
                      language: language,
                      selected: language.code == current,
                      onTap: () => _select(context, ref, language),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppDimensions.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        // Deliberately tall: this is the one control a first-time user must be
        // able to hit without reading anything.
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.sm + 4,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.greyBorder,
            width: selected ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    language.nativeName,
                    textDirection:
                        language.isRtl ? TextDirection.rtl : TextDirection.ltr,
                    style: AppTextStyles.heading3,
                  ),
                  if (language.nativeName != language.name) ...[
                    const SizedBox(height: 2),
                    Text(language.name, style: AppTextStyles.caption),
                  ],
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }
}
