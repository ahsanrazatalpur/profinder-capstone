// lib/features/onboarding/screens/language_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/localization/supported_languages.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/theme/app_theme.dart';

/// Shown exactly once — the first time the app is ever opened — before the
/// splash/auth flow. LocaleProvider.hasChosenLanguage gates this in main.dart:
/// once the user presses Continue here, this screen never appears again
/// unless the app data is reset.
class LanguageSelectionScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const LanguageSelectionScreen({super.key, required this.onContinue});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  late String _selectedCode;

  @override
  void initState() {
    super.initState();
    // Pre-select whatever LocaleProvider already detected from the device.
    _selectedCode = context.read<LocaleProvider>().locale.languageCode;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    // This screen appears before the user has ever chosen a theme
    // preference (it's the very first thing shown on a fresh install),
    // so it's always rendered in light mode — deliberately independent
    // of ThemeProvider's current/default value. Wrapping in Theme here
    // means context.colors below also resolves to light, since it reads
    // Theme.of(context).brightness.
    return Theme(
      data: AppTheme.lightTheme,
      child: Builder(builder: (context) => _buildScaffold(context, t)),
    );
  }

  Widget _buildScaffold(BuildContext context, AppLocalizations t) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // Real ProFinder logo — no name/tagline here, the heading
              // below already says "Welcome to ProFinder".
              const AppLogo(size: 88, showName: false),

              const SizedBox(height: 20),
              Text(
                t.authWelcomeProfinder,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.selectLanguageSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: context.colors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),

              // Language list — every entry here comes straight from
              // SupportedLanguages.all, so this only ever shows languages
              // the app actually ships (en, ur, hi, ar, fr, es).
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(color: context.colors.divider),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: SupportedLanguages.all.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: context.colors.divider),
                    itemBuilder: (_, i) {
                      final lang = SupportedLanguages.all[i];
                      final selected = lang.code == _selectedCode;
                      return _LanguageTile(
                        language: lang,
                        selected: selected,
                        onTap: () => setState(() => _selectedCode = lang.code),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.language_rounded, size: 18, color: context.colors.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      t.languageChangeNote,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: context.colors.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),

              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24, top: 20),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      await context.read<LocaleProvider>().setLocale(_selectedCode);
                      widget.onContinue();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          t.continueLabel,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
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

  const _LanguageTile({required this.language, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: selected ? context.colors.primaryLight : Colors.transparent,
        child: Row(
          children: [
            // Flag chip
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.background,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                border: Border.all(color: context.colors.divider),
              ),
              child: Text(language.flag, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.englishName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: selected ? context.colors.primaryDark : context.colors.textPrimary,
                    ),
                  ),
                  Text(
                    language.nativeName,
                    textDirection: language.isRtl ? TextDirection.rtl : TextDirection.ltr,
                    style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                  ),
                ],
              ),
            ),
            // Radio indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? context.colors.primary : context.colors.divider,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: context.colors.primary),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}