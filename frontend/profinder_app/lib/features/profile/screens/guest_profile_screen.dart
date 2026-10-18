// lib/features/profile/screens/guest_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_sizes.dart';
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
import '../../about/screens/about_screen.dart';
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
    final sectionGap = ResponsiveUtils.sp(28, scale, min: 24, max: 32);

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

                // ── Quick Actions (locked placeholders prompting guests to sign in) ──
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

                // ── Account Section ─────────────────────────────
                ProfileSectionHeader(
                  title: t.accountSection,
                  icon: Icons.account_circle_rounded,
                  iconColor: AppColors.indigo,
                  scale: scale,
                ),
                ProfileMenuTile(
                  icon: Icons.edit_outlined,
                  iconColor: AppColors.sky,
                  title: t.profileEditProfile,
                  subtitle: t.profileNotAvailable,
                  isLocked: true,
                  scale: scale,
                  trailing: const SizedBox.shrink(),
                ),
                ProfileMenuTile(
                  icon: Icons.login_rounded,
                  iconColor: AppColors.indigo,
                  title: t.login,
                  subtitle: t.profileAccessBookingsProfile,
                  scale: scale,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                ),
                ProfileMenuTile(
                  icon: Icons.person_add_rounded,
                  iconColor: AppColors.emerald,
                  title: t.register,
                  subtitle: t.profileCreateFreeCustomerAccount,
                  scale: scale,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                ),
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

                SizedBox(height: sectionGap),

                // ── Preferences Section ─────────────────────────
                ProfileSectionHeader(
                  title: t.preferencesSection,
                  icon: Icons.settings_rounded,
                  iconColor: AppColors.indigo,
                  scale: scale,
                ),
                ProfileMenuTile(
                  icon: Icons.notifications_outlined,
                  iconColor: AppColors.badgePopular,
                  title: t.notifications,
                  subtitle: t.profileNotAvailable,
                  isLocked: true,
                  scale: scale,
                  trailing: const SizedBox.shrink(),
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
                  icon: Icons.security_rounded,
                  iconColor: AppColors.greenDeep,
                  title: t.security,
                  subtitle: t.profileNotAvailable,
                  isLocked: true,
                  scale: scale,
                  trailing: const SizedBox.shrink(),
                ),

                SizedBox(height: sectionGap),

                // ── Support Section ─────────────────────────────
                ProfileSectionHeader(
                  title: t.supportSection,
                  icon: Icons.support_rounded,
                  iconColor: AppColors.indigo,
                  scale: scale,
                ),
                ProfileMenuTile(
                  icon: Icons.help_center_rounded,
                  iconColor: AppColors.warningAmber,
                  title: t.profileHelpSupport,
                  scale: scale,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
                  ),
                ),
                ProfileMenuTile(
                  icon: Icons.privacy_tip_rounded,
                  iconColor: AppColors.emerald,
                  title: t.profilePrivacyPolicy,
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
                  title: t.profileAboutProfinder,
                  scale: scale,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
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
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: Text(t.searchLoginRequired),
        content: Text('${t.profileLoginBookSaveManageRequests} ($feature)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: Text(t.login),
          ),
        ],
      ),
    );
  }
}
