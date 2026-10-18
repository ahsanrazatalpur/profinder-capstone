// lib/features/profile/screens/guest_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/app_logo.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/register_screen.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/theme_mode_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/profile_header_card.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../../../shared/widgets/universal_dialog.dart';
import '../../about/screens/about_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../support/screens/help_center_screen.dart';
import '../../support/screens/privacy_policy_screen.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/localization/supported_languages.dart';
import 'language_settings_screen.dart';
import '../../../shared/widgets/profile_menu_tile.dart';
import '../../../shared/widgets/profile_quick_action_card.dart';
import '../../../shared/widgets/profile_section_header.dart';

class GuestProfileScreen extends StatelessWidget {
  const GuestProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final scale = ResponsiveUtils.scaleForWidth(width);

    final contentMaxWidth = width > 680 ? 680.0 : width;
    final hPad = ResponsiveUtils.screenPadding(width);
    final sectionGap = ResponsiveUtils.sp(24, scale, min: 20, max: 28);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: UniversalAppBar(
        title: t.profileTitle,
        icon: Icons.person_rounded,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: ListView(
              padding: EdgeInsets.all(hPad),
              children: [
                // ── Guest Identity Hero ────────────────────────────
                ProfileHeaderCard(
                  accentColor: AppColors.customerColor,
                  accentColorSecondary: AppColors.heroGradientLight2,
                  heroGradientLight: const [
                    AppColors.heroGradientLight1,
                    AppColors.heroGradientLight2,
                  ],
                  heroGradientDark: const [
                    AppColors.heroGradientLight1,
                    AppColors.heroGradientLight2,
                  ],
                  statusText: t.profileBrowsingAsGuest,
                  statusIcon: Icons.person_outline_rounded,
                  description: t.profileLoginBookSaveManageRequests,
                  avatarIcon: Icons.person_rounded,
                  actions: [
                    ProfileHeaderAction(
                      label: t.register,
                      icon: Icons.person_add_rounded,
                      primary: true,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      ),
                    ),
                    ProfileHeaderAction(
                      label: t.login,
                      icon: Icons.login_rounded,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: sectionGap),

                // ── Quick Actions Row (4 Cards) ──
                Row(
                  children: [
                    Expanded(
                      child: ProfileQuickActionCard(
                        icon: Icons.calendar_today_rounded,
                        label: t.bookings,
                        isLocked: true,
                        onTap: () => _promptSignIn(context, t.bookings),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ProfileQuickActionCard(
                        icon: Icons.account_balance_wallet_rounded,
                        label: t.profileWalletLabel,
                        isLocked: true,
                        onTap: () =>
                            _promptSignIn(context, t.profileWalletLabel),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ProfileQuickActionCard(
                        icon: Icons.favorite_rounded,
                        label: t.profileSavedLabel,
                        isLocked: true,
                        onTap: () =>
                            _promptSignIn(context, t.profileSavedLabel),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ProfileQuickActionCard(
                        icon: Icons.rate_review_rounded,
                        label: t.profileReviewsLabel,
                        isLocked: true,
                        onTap: () =>
                            _promptSignIn(context, t.profileReviewsLabel),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: sectionGap),

                // ── Group 1: Activity & Services (Same as Customer/Pro) ──
                ProfileSectionHeader(
                  title: t.accountSection,
                  icon: Icons.work_outline_rounded,
                  iconColor: AppColors.indigo,
                  scale: scale,
                ),
                ProfileMenuTile(
                  icon: Icons.workspace_premium_rounded,
                  iconColor: AppColors.warningAmber,
                  title: t.subscriptionUpgradeLabel,
                  subtitle: t.subscriptionUpgradeStatus,
                  isLocked: true,
                  scale: scale,
                  onLockedTap: () =>
                      _promptSignIn(context, t.subscriptionUpgradeLabel),
                ),
                ProfileMenuTile(
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: AppColors.badgeTrending,
                  title: t.walletActionLabel,
                  subtitle: t.walletActionSubtitle,
                  isLocked: true,
                  scale: scale,
                  onLockedTap: () =>
                      _promptSignIn(context, t.walletActionLabel),
                ),
                ProfileMenuTile(
                  icon: Icons.calendar_today_outlined,
                  iconColor: AppColors.cyan,
                  title: t.bookingsActionLabel,
                  subtitle: t.bookingsActionSubtitle,
                  isLocked: true,
                  scale: scale,
                  onLockedTap: () =>
                      _promptSignIn(context, t.bookingsActionLabel),
                ),
                ProfileMenuTile(
                  icon: Icons.favorite_border_rounded,
                  iconColor: AppColors.pink,
                  title: t.savedProfessionalsActionLabel,
                  subtitle: t.savedProfessionalsActionSubtitle,
                  isLocked: true,
                  scale: scale,
                  onLockedTap: () =>
                      _promptSignIn(context, t.savedProfessionalsActionLabel),
                ),
                ProfileMenuTile(
                  icon: Icons.rate_review_outlined,
                  iconColor: AppColors.violet,
                  title: t.reviewsActionLabel,
                  subtitle: t.reviewsActionSubtitle,
                  isLocked: true,
                  scale: scale,
                  onLockedTap: () =>
                      _promptSignIn(context, t.reviewsActionLabel),
                ),
                ProfileMenuTile(
                  icon: Icons.receipt_long_outlined,
                  iconColor: AppColors.indigo,
                  title: t.paymentsActionLabel,
                  subtitle: t.paymentsActionSubtitle,
                  isLocked: true,
                  scale: scale,
                  onLockedTap: () =>
                      _promptSignIn(context, t.paymentsActionLabel),
                ),

                SizedBox(height: sectionGap),

                // ── Group 2: Preferences (Same as Customer/Pro) ──
                ProfileSectionHeader(
                  title: t.preferencesSection,
                  icon: Icons.settings_rounded,
                  iconColor: AppColors.indigo,
                  scale: scale,
                ),
                ProfileMenuTile(
                  icon: Icons.notifications_outlined,
                  iconColor: AppColors.rose,
                  title: t.notificationsActionLabel,
                  subtitle: t.notificationsActionSubtitle,
                  isLocked: true,
                  scale: scale,
                  onLockedTap: () =>
                      _promptSignIn(context, t.notificationsActionLabel),
                ),
                Builder(
                  builder: (context) {
                    final currentLang = SupportedLanguages.byCode(
                      context.watch<LocaleProvider>().locale.languageCode,
                    );
                    return ProfileMenuTile(
                      icon: Icons.language_rounded,
                      iconColor: AppColors.cyan,
                      title: t.languageLabel,
                      subtitle: currentLang.nativeName,
                      scale: scale,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LanguageSettingsScreen(),
                        ),
                      ),
                    );
                  },
                ),
                Builder(
                  builder: (context) {
                    final mode = context.watch<ThemeProvider>().themeMode;
                    return ProfileMenuTile(
                      icon: themeModeIcon(mode),
                      iconColor: AppColors.indigoDeep,
                      title: t.themeModeTitle,
                      subtitle: themeModeLabel(t, mode),
                      scale: scale,
                      onTap: () => showThemeModeSheet(context),
                    );
                  },
                ),
                ProfileMenuTile(
                  icon: Icons.settings_outlined,
                  iconColor: AppColors.slate500,
                  title: t.settingsActionLabel,
                  subtitle: t.settingsActionSubtitle,
                  scale: scale,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
                ProfileMenuTile(
                  icon: Icons.security_rounded,
                  iconColor: AppColors.emerald,
                  title: t.securityActionLabel,
                  subtitle: t.securityActionSubtitle,
                  isLocked: true,
                  scale: scale,
                  onLockedTap: () =>
                      _promptSignIn(context, t.securityActionLabel),
                ),

                SizedBox(height: sectionGap),

                // ── Group 3: Trust, Safety & Support (Same as Customer/Pro) ──
                ProfileSectionHeader(
                  title: t.supportSection,
                  icon: Icons.support_rounded,
                  iconColor: AppColors.indigo,
                  scale: scale,
                ),
                ProfileMenuTile(
                  icon: Icons.shield_outlined,
                  iconColor: AppColors.dangerRed,
                  title: t.myTsAccountStatusTitle,
                  subtitle: t.myTsAccountStatusActionSubtitle,
                  isLocked: true,
                  scale: scale,
                  onLockedTap: () =>
                      _promptSignIn(context, t.myTsAccountStatusTitle),
                ),
                ProfileMenuTile(
                  icon: Icons.outlined_flag_rounded,
                  iconColor: AppColors.sky,
                  title: t.myTsMyReportsTitle,
                  subtitle: t.myTsMyReportsActionSubtitle,
                  isLocked: true,
                  scale: scale,
                  onLockedTap: () =>
                      _promptSignIn(context, t.myTsMyReportsTitle),
                ),
                ProfileMenuTile(
                  icon: Icons.help_outline_rounded,
                  iconColor: AppColors.teal,
                  title: t.helpActionLabel,
                  subtitle: t.helpActionSubtitle,
                  scale: scale,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
                  ),
                ),
                ProfileMenuTile(
                  icon: Icons.support_agent_rounded,
                  iconColor: AppColors.accentPurple,
                  title: t.ticketsTitle,
                  subtitle: t.ticketsTileSubtitle,
                  isLocked: true,
                  scale: scale,
                  onLockedTap: () => _promptSignIn(context, t.ticketsTitle),
                ),
                ProfileMenuTile(
                  icon: Icons.privacy_tip_rounded,
                  iconColor: AppColors.emerald,
                  title: t.profilePrivacyPolicy,
                  subtitle: t.privacyActionSubtitle,
                  scale: scale,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  ),
                ),
                ProfileMenuTile(
                  icon: Icons.info_rounded,
                  iconColor: AppColors.indigo,
                  title: t.aboutActionLabel,
                  subtitle: t.aboutActionSubtitle,
                  scale: scale,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  ),
                ),

                SizedBox(height: sectionGap),

                // ── Group 4: Join / Become Pro Banner ──
                ProfileMenuTile(
                  icon: Icons.workspace_premium_rounded,
                  iconColor: AppColors.accentPurple,
                  title: t.profileBecomeProfessional,
                  subtitle: t.profileListServicesGetHired,
                  scale: scale,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const RegisterScreen(initialRole: 'professional'),
                    ),
                  ),
                ),

                SizedBox(height: sectionGap * 1.5),

                // ── Footer ──────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      AppLogo(
                        size: ResponsiveUtils.sp(32, scale, min: 30, max: 40),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.profileProfinderV100,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.sp(
                            12,
                            scale,
                            min: 11,
                            max: 14,
                          ),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                          color: context.colors.textSecondary.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _promptSignIn(BuildContext context, String feature) {
    UniversalDialog.showLoginPrompt(context, featureName: feature);
  }
}
