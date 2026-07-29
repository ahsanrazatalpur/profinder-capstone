// lib/features/profile/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/localization/supported_languages.dart';
import 'language_settings_screen.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/theme/theme_provider.dart';

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
      SnackBar(content: Text('$feature is coming soon'), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        title: Text('Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: context.colors.textPrimary), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionLabel('Notifications'),
          _switchTile(Icons.notifications_active_outlined, 'Push Notifications', 'Booking updates, messages & offers', _pushEnabled,
              (v) => setState(() => _pushEnabled = v)),
          _switchTile(Icons.email_outlined, 'Email Notifications', 'Receipts & account activity', _emailEnabled,
              (v) => setState(() => _emailEnabled = v)),

          const SizedBox(height: 16),
          _sectionLabel('Preferences'),
          Builder(builder: (context) {
            final currentCode = context.watch<LocaleProvider>().locale.languageCode;
            final currentLang = SupportedLanguages.byCode(currentCode);
            return _tile(
              Icons.language_rounded,
              'Language',
              currentLang.nativeName,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()),
              ),
            );
          }),
          _tile(Icons.attach_money_rounded, 'Currency', 'USD', () => _comingSoon('Currency selection')),
          Builder(builder: (context) {
            final themeProvider = context.watch<ThemeProvider>();
            return _switchTile(
              Icons.dark_mode_outlined,
              'Dark Mode',
              themeProvider.isDarkMode ? 'On' : 'Off',
              themeProvider.isDarkMode,
              (v) => context.read<ThemeProvider>().toggleTheme(),
            );
          }),

          const SizedBox(height: 16),
          _sectionLabel('Account'),
          _tile(Icons.delete_outline_rounded, 'Delete Account', 'Permanently remove your account', () => _confirmDelete(context), color: AppColors.error),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
        child: Text(text.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.colors.textSecondary, letterSpacing: 0.6)),
      );

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback onTap, {Color? color}) {
    final c = color ?? context.colors.textPrimary;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.colors.divider)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: c, size: 20),
        title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11.5, color: context.colors.textSecondary)),
        trailing: Icon(Icons.chevron_right_rounded, size: 18, color: context.colors.textSecondary),
      ),
    );
  }

  Widget _switchTile(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.colors.divider)),
      child: ListTile(
        leading: Icon(icon, color: context.colors.textPrimary, size: 20),
        title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11.5, color: context.colors.textSecondary)),
        trailing: Switch(value: value, activeColor: context.colors.primary, onChanged: onChanged),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Account?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
        content: Text('This needs to go through our support team for verification. Contact Help & Support to proceed.',
            style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }
}