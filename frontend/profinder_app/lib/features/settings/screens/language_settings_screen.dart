// lib/features/settings/screens/language_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/localization/language_sync_service.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/localization/supported_languages.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../services/auth_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/universal_app_bar.dart';

/// Reached from Settings → Language. Changing the selection here updates
/// the whole app immediately (LocaleProvider.setLocale -> notifyListeners),
/// no restart needed, and syncs to the backend if the user is logged in.
class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final localeProvider = context.watch<LocaleProvider>();
    final currentCode = localeProvider.locale.languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? context.colors.background
          : AppColors.lightScaffold,
      appBar: UniversalAppBar(
        title: t.languageLabel,
        icon: Icons.language_rounded,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: SupportedLanguages.all.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final lang = SupportedLanguages.all[i];
          final selected = lang.code == currentCode;
          return Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(
                color: selected
                    ? context.colors.primary
                    : context.colors.divider,
              ),
            ),
            child: ListTile(
              onTap: () => _selectLanguage(context, lang.code),
              // Same look as the first-launch language screen: country flag chip,
              // English name, native name underneath.
              leading: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.background,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  border: Border.all(color: context.colors.divider),
                ),
                child: Text(lang.flag, style: const TextStyle(fontSize: 20)),
              ),
              title: Text(
                lang.englishName,
                style: TextStyle(
                  fontSize: AppFontSizes.body,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? context.colors.primaryDark
                      : context.colors.textPrimary,
                ),
              ),
              subtitle: Text(
                lang.nativeName,
                textDirection: lang.isRtl
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.textSecondary,
                ),
              ),
              trailing: selected
                  ? Icon(
                      Icons.check_circle_rounded,
                      color: context.colors.primary,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectLanguage(BuildContext context, String code) async {
    final localeProvider = context.read<LocaleProvider>();
    final auth = context.read<AuthProvider>();
    if (code == localeProvider.locale.languageCode) return;

    await localeProvider.setLocale(code);

    // If the user is logged in, keep the backend in sync so it's picked
    // up correctly on their next login (e.g. on a different device).
    if (auth.isLoggedIn) {
      await LanguageSyncService().uploadLanguage(code);
    }

    if (context.mounted) {
      final t = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.languageUpdated),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
