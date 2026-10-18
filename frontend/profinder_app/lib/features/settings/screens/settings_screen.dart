// lib/features/settings/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/localization/supported_languages.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/theme/theme_mode_picker.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../../notifications/services/push_notification_service.dart';
import '../../support/screens/new_ticket_screen.dart';
import '../../support/screens/privacy_policy_screen.dart';
import '../../../app/routes/app_routes.dart';
import '../../payments/services/payment_service.dart';
import '../widgets/delete_account_dialog.dart';
import 'language_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  final ApiService? api;
  const SettingsScreen({super.key, this.api});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final ApiService _api = widget.api ?? ApiService();
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _hasPassword = true;
  String _userEmail = '';
  String _selectedCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    try {
      final curr = await PaymentService().getSelectedCurrency();
      if (mounted) setState(() => _selectedCurrency = curr);
    } catch (_) {}
  }

  Future<void> _loadNotificationPreferences() async {
    // 1. Instant cache load from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _pushEnabled = prefs.getBool('pref_push_notifications') ?? true;
          _emailEnabled = prefs.getBool('pref_email_notifications') ?? true;
        });
      }
    } catch (_) {}

    // 2. Fetch server-side ground truth
    try {
      final res = await _api.get(AppConstants.me);
      if (res.data is Map && mounted) {
        final data = res.data as Map;
        final push = data['push_notifications'] as bool? ?? true;
        final email = data['email_notifications'] as bool? ?? true;
        final hasPassword = data['has_password'] as bool? ?? true;
        final userEmail = (data['email'] as String? ?? '').trim();

        setState(() {
          _pushEnabled = push;
          _emailEnabled = email;
          _hasPassword = hasPassword;
          _userEmail = userEmail;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('pref_push_notifications', push);
        await prefs.setBool('pref_email_notifications', email);
      }
    } catch (_) {}
  }

  Future<void> _onTogglePush(bool value) async {
    final errorMsg = AppLocalizations.of(context).saveSettingsError;

    setState(() => _pushEnabled = value);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pref_push_notifications', value);

      await _api.patch(AppConstants.me, {'push_notifications': value});

      if (value) {
        // Re-register FCM token when push notifications are turned back on
        PushNotificationService().registerToken();
      }
    } catch (_) {
      if (!mounted) return;
      // Revert on failure
      setState(() => _pushEnabled = !value);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pref_push_notifications', !value);

      if (!mounted) return;
      AppHelpers.showError(context, errorMsg);
    }
  }

  Future<void> _onToggleEmail(bool value) async {
    final errorMsg = AppLocalizations.of(context).saveSettingsError;

    setState(() => _emailEnabled = value);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pref_email_notifications', value);

      await _api.patch(AppConstants.me, {'email_notifications': value});
    } catch (_) {
      if (!mounted) return;
      // Revert on failure
      setState(() => _emailEnabled = !value);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pref_email_notifications', !value);

      if (!mounted) return;
      AppHelpers.showError(context, errorMsg);
    }
  }

  void _showCurrencySheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencies = const [
      {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
      {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
      {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
      {'code': 'PKR', 'name': 'Pakistani Rupee', 'symbol': '₨'},
      {'code': 'SAR', 'name': 'Saudi Riyal', 'symbol': '﷼'},
      {'code': 'AED', 'name': 'UAE Dirham', 'symbol': 'د.إ'},
      {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'},
      {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': 'CA\$'},
      {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'AU\$'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.customerColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: const Icon(
                          Icons.attach_money_rounded,
                          color: AppColors.customerColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).currencyLabel,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: currencies.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 64,
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    ),
                    itemBuilder: (context, index) {
                      final item = currencies[index];
                      final isSelected = item['code'] == _selectedCurrency;
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: isSelected
                              ? AppColors.customerColor.withValues(alpha: 0.15)
                              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.1)),
                          child: Text(
                            item['symbol']!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isSelected ? AppColors.customerColor : context.colors.textSecondary,
                            ),
                          ),
                        ),
                        title: Text(
                          '${item['name']} (${item['code']})',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.customerColor : context.colors.textPrimary,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.customerColor, size: 20)
                            : null,
                        onTap: () async {
                          final code = item['code']!;
                          await PaymentService().setSelectedCurrency(code);
                          if (mounted) {
                            setState(() => _selectedCurrency = code);
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            AppHelpers.showSuccess(
                              this.context,
                              'Currency updated to $code',
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
        title: AppLocalizations.of(context).settingsTitle,
        icon: Icons.settings_rounded,
      ),
      body: ListView(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // ── Notifications Section ──────────────────────
          _sectionLabel(
            AppLocalizations.of(context).notificationsSectionLabel,
            isDark,
          ),
          _switchTile(
            context,
            Icons.notifications_active_outlined,
            AppLocalizations.of(context).pushNotificationsLabel,
            AppLocalizations.of(context).pushNotificationsSubtitle,
            _pushEnabled,
            _onTogglePush,
            isDark,
            isTablet,
          ),
          _switchTile(
            context,
            Icons.email_outlined,
            AppLocalizations.of(context).emailNotificationsLabel,
            AppLocalizations.of(context).emailNotificationsSubtitle,
            _emailEnabled,
            _onToggleEmail,
            isDark,
            isTablet,
          ),

          const SizedBox(height: 16),

          // ── Preferences Section ────────────────────────
          _sectionLabel(
            AppLocalizations.of(context).preferencesSectionLabel,
            isDark,
          ),
          Builder(
            builder: (context) {
              final currentCode = context
                  .watch<LocaleProvider>()
                  .locale
                  .languageCode;
              final currentLang = SupportedLanguages.byCode(currentCode);
              return _tile(
                context,
                Icons.language_rounded,
                AppLocalizations.of(context).languageLabel,
                currentLang.nativeName,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LanguageSettingsScreen(),
                  ),
                ),
                isDark: isDark,
                isTablet: isTablet,
              );
            },
          ),
          _tile(
            context,
            Icons.attach_money_rounded,
            AppLocalizations.of(context).currencyLabel,
            _selectedCurrency,
            () => _showCurrencySheet(context),
            isDark: isDark,
            isTablet: isTablet,
          ),
          Builder(
            builder: (context) {
              final t = AppLocalizations.of(context);
              final mode = context.watch<ThemeProvider>().themeMode;
              return _tile(
                context,
                themeModeIcon(mode),
                t.themeModeTitle,
                themeModeLabel(t, mode),
                () => showThemeModeSheet(context),
                isDark: isDark,
                isTablet: isTablet,
              );
            },
          ),

          const SizedBox(height: 16),

          // ── Account Section ────────────────────────────
          _sectionLabel(
            AppLocalizations.of(context).accountSectionLabel,
            isDark,
          ),
          _tile(
            context,
            Icons.privacy_tip_rounded,
            AppLocalizations.of(context).profilePrivacyPolicy,
            AppLocalizations.of(context).privacyActionSubtitle,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
            isDark: isDark,
            isTablet: isTablet,
          ),
          _tile(
            context,
            Icons.delete_outline_rounded,
            AppLocalizations.of(context).deleteAccountLabel,
            AppLocalizations.of(context).deleteAccountSubtitle,
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
        fontSize: AppFontSizes.caption,
        fontWeight: FontWeight.bold,
        color: isDark
            ? Colors.white.withValues(alpha: 0.5)
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
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : context.colors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.06)
                : Colors.grey.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
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
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : context.colors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.06)
                : Colors.grey.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.customerColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, color: AppColors.customerColor, size: 18),
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
            activeThumbColor: AppColors.customerColor,
            activeTrackColor: AppColors.customerColor.withValues(alpha: 0.3),
            inactiveThumbColor: isDark
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.3),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  // ── Delete Account Confirmation ────────────────────────
  void _confirmDelete(BuildContext context) async {
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeleteAccountDialog(
        hasPassword: _hasPassword,
        userEmail: _userEmail,
      ),
    );

    if (deleted == true && context.mounted) {
      AppHelpers.showSuccess(
        context,
        'Your account has been deleted successfully.',
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    }
  }
}
