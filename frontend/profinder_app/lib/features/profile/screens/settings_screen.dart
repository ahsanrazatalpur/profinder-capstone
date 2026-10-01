// lib/features/profile/screens/settings_screen.dart

import 'package:flutter/material.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/localization/supported_languages.dart';
import 'language_settings_screen.dart';
import '../../../l10n/generated/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushEnabled  = true;
  bool _emailEnabled = true;

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.comingSoonMessage(feature)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: context.colors.divider),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width > 600;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: UniversalAppBar(
        title: AppLocalizations.of(context)!.settingsTitle,
        icon: Icons.settings_rounded,
      ),
      body: ListView(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // ── Notifications Section ──────────────────────
          _sectionLabel(AppLocalizations.of(context)!.notificationsSectionLabel, isDark),
          _switchTile(
            context,
            Icons.notifications_active_outlined,
            AppLocalizations.of(context)!.pushNotificationsLabel,
            AppLocalizations.of(context)!.pushNotificationsSubtitle,
            _pushEnabled,
            (v) => setState(() => _pushEnabled = v),
            isDark,
            isTablet,
          ),
          _switchTile(
            context,
            Icons.email_outlined,
            AppLocalizations.of(context)!.emailNotificationsLabel,
            AppLocalizations.of(context)!.emailNotificationsSubtitle,
            _emailEnabled,
            (v) => setState(() => _emailEnabled = v),
            isDark,
            isTablet,
          ),

          const SizedBox(height: 16),

          // ── Preferences Section ────────────────────────
          _sectionLabel(AppLocalizations.of(context)!.preferencesSectionLabel, isDark),
          Builder(builder: (context) {
            final currentCode = context.watch<LocaleProvider>().locale.languageCode;
            final currentLang = SupportedLanguages.byCode(currentCode);
            return _tile(
              context,
              Icons.language_rounded,
              AppLocalizations.of(context)!.languageLabel,
              currentLang.nativeName,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()),
              ),
              isDark: isDark,
              isTablet: isTablet,
            );
          }),
          _tile(
            context,
            Icons.attach_money_rounded,
            AppLocalizations.of(context)!.currencyLabel,
            'USD',
            () => _comingSoon(AppLocalizations.of(context)!.currencyFeatureName),
            isDark: isDark,
            isTablet: isTablet,
          ),
          Builder(builder: (context) {
            final themeProvider = context.watch<ThemeProvider>();
            return _switchTile(
              context,
              Icons.dark_mode_outlined,
              AppLocalizations.of(context)!.darkModeLabel,
              themeProvider.isDarkMode ? AppLocalizations.of(context)!.darkModeOnLabel : AppLocalizations.of(context)!.darkModeOffLabel,
              themeProvider.isDarkMode,
              (v) => context.read<ThemeProvider>().toggleTheme(),
              isDark,
              isTablet,
            );
          }),

          const SizedBox(height: 16),

          // ── Account Section ────────────────────────────
          _sectionLabel(AppLocalizations.of(context)!.accountSectionLabel, isDark),
          _tile(
            context,
            Icons.delete_outline_rounded,
            AppLocalizations.of(context)!.deleteAccountLabel,
            AppLocalizations.of(context)!.deleteAccountSubtitle,
            () => _confirmDelete(context),
            color: AppColors.error,
            isDark: isDark,
            isTablet: isTablet,
          ),
        ],
      ),
    );
  }

  // ── Section Label ──────────────────────────────────────
  Widget _sectionLabel(String text, bool isDark) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark
                ? Colors.white.withOpacity(0.5)
                : context.colors.textSecondary,
            letterSpacing: 0.6,
          ),
        ),
      );

  // ── Navigation Tile ────────────────────────────────────
  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Color? color,
    bool isDark = false,
    bool isTablet = false,
  }) {
    final c = color ?? context.colors.textPrimary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : context.colors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.06)
                : Colors.grey.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: c.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: c, size: 18),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: isTablet ? 15.0 : 14.0,
            fontWeight: FontWeight.w600,
            color: c,
            letterSpacing: -0.1,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: isTablet ? 12.0 : 11.5,
            color: context.colors.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: context.colors.textSecondary,
        ),
      ),
    );
  }

  // ── Switch Tile ────────────────────────────────────────
  Widget _switchTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
    bool isTablet,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : context.colors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.06)
                : Colors.grey.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.customerColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.customerColor,
            size: 18,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: isTablet ? 15.0 : 14.0,
            fontWeight: FontWeight.w600,
            color: context.colors.textPrimary,
            letterSpacing: -0.1,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: isTablet ? 12.0 : 11.5,
            color: context.colors.textSecondary,
          ),
        ),
        trailing: Switch(
          value: value,
          activeColor: AppColors.customerColor,
          activeTrackColor: AppColors.customerColor.withOpacity(0.3),
          inactiveThumbColor: isDark
              ? Colors.white.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ── Delete Account Confirmation ────────────────────────
  void _confirmDelete(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)!.deleteAccountDialogTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.deleteAccountDialogContent,
          style: TextStyle(
            fontSize: 14,
            color: context.colors.textSecondary,
            height: 1.5,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: context.colors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.okCta,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}