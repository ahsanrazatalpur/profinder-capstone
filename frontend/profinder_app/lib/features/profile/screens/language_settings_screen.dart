// lib/features/profile/screens/language_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/localization/language_sync_service.dart';
import '../../../core/localization/supported_languages.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/auth_provider.dart';
import '../../../core/theme/theme_context_ext.dart';

/// Reached from Settings → Language. Changing the selection here updates
/// the whole app immediately (LocaleProvider.setLocale -> notifyListeners),
/// no restart needed, and syncs to the backend if the user is logged in.
class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();
    final currentCode = localeProvider.locale.languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(t.languageLabel,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF374151)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: SupportedLanguages.all.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final lang = SupportedLanguages.all[i];
          final selected = lang.code == currentCode;
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? context.colors.primary : const Color(0xFFE5E7EB)),
            ),
            child: ListTile(
              onTap: () => _selectLanguage(context, lang.code),
              title: Text(
                lang.nativeName,
                textDirection: lang.isRtl ? TextDirection.rtl : TextDirection.ltr,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: lang.nativeName != lang.englishName ? Text(lang.englishName) : null,
              trailing: selected ? Icon(Icons.check_circle_rounded, color: context.colors.primary) : null,
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectLanguage(BuildContext context, String code) async {
    final localeProvider = context.read<LocaleProvider>();
    if (code == localeProvider.locale.languageCode) return;

    await localeProvider.setLocale(code);

    // If the user is logged in, keep the backend in sync so it's picked
    // up correctly on their next login (e.g. on a different device).
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      await LanguageSyncService().uploadLanguage(code);
    }

    if (context.mounted) {
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.languageUpdated), behavior: SnackBarBehavior.floating),
      );
    }
  }
}