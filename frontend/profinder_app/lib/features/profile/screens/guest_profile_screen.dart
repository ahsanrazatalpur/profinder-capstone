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
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/profile_header_card.dart';
import '../../about/screens/about_screen.dart';

class GuestProfileScreen extends StatelessWidget {
  const GuestProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final scale = ResponsiveUtils.scaleForWidth(width);

    final contentMaxWidth = width > 680 ? 680.0 : width;
    final hPad = ResponsiveUtils.screenPadding(width);
    final sectionGap = ResponsiveUtils.sp(28, scale, min: 24, max: 32);

    return Scaffold(
      backgroundColor: context.colors.background,
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
                  heroGradientLight: const [AppColors.heroGradientLight1, AppColors.heroGradientLight2],
                  heroGradientDark: const [AppColors.heroGradientLight1, AppColors.heroGradientLight2],
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
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
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

                // ── Quick Actions (locked — same layout as customer,
                //    tap par login screen khulta hai) ────────────────
                Row(children: [
                  Expanded(child: _lockedQuickAction(context, Icons.calendar_today_rounded, 'Bookings', scale)),
                  const SizedBox(width: 10),
                  Expanded(child: _lockedQuickAction(context, Icons.account_balance_wallet_rounded, 'Wallet', scale)),
                  const SizedBox(width: 10),
                  Expanded(child: _lockedQuickAction(context, Icons.favorite_rounded, 'Saved', scale)),
                  const SizedBox(width: 10),
                  Expanded(child: _lockedQuickAction(context, Icons.rate_review_rounded, 'Reviews', scale)),
                ]),

                SizedBox(height: sectionGap),

                // ── Account Section ─────────────────────────────
                _sectionHeader(context, t.accountSection, Icons.account_circle_rounded, scale),
                const SizedBox(height: 10),
                Opacity(
                  opacity: 0.55,
                  child: _menuTile(
                    context,
                    icon: Icons.edit_outlined,
                    iconColor: const Color(0xFF0EA5E9),
                    title: 'Edit Profile',
                    subtitle: 'Not available',
                    scale: scale,
                    onTap: () {},
                    trailing: const SizedBox.shrink(),
                  ),
                ),
                _menuTile(
                  context,
                  icon: Icons.login_rounded,
                  iconColor: const Color(0xFF6366F1),
                  title: t.login,
                  subtitle: t.profileAccessBookingsProfile,
                  scale: scale,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                ),
                _menuTile(
                  context,
                  icon: Icons.person_add_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: t.register,
                  subtitle: t.profileCreateFreeCustomerAccount,
                  scale: scale,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                ),
                _menuTile(
                  context,
                  icon: Icons.workspace_premium_rounded,
                  iconColor: const Color(0xFF7C3AED),
                  title: t.profileBecomeProfessional,
                  subtitle: t.profileListServicesGetHired,
                  scale: scale,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen(initialRole: 'professional')),
                  ),
                ),

                SizedBox(height: sectionGap),

                // ── Preferences Section ─────────────────────────
                _sectionHeader(context, t.preferencesSection, Icons.settings_rounded, scale),
                const SizedBox(height: 10),
                Opacity(
                  opacity: 0.55,
                  child: _menuTile(
                    context,
                    icon: Icons.notifications_outlined,
                    iconColor: const Color(0xFFDB2777),
                    title: 'Notifications',
                    subtitle: 'Not available',
                    scale: scale,
                    onTap: () {},
                    trailing: const SizedBox.shrink(),
                  ),
                ),
                _menuTile(
                  context,
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xFF06B6D4),
                  title: t.languageLabel,
                  subtitle: t.profileEnglish,
                  scale: scale,
                  onTap: () => _showComingSoon(context, t.languageLabel),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: context.colors.textSecondary.withOpacity(0.4),
                    size: ResponsiveUtils.sp(20, scale, min: 18, max: 24),
                  ),
                ),
                Builder(builder: (context) {
                  final themeProvider = context.watch<ThemeProvider>();
                  return _menuSwitchTile(
                    context,
                    icon: Icons.dark_mode_rounded,
                    iconColor: const Color(0xFF4F46E5),
                    title: t.darkModeLabel,
                    subtitle: themeProvider.isDarkMode ? 'On' : 'Off',
                    scale: scale,
                    value: themeProvider.isDarkMode,
                    onChanged: (v) => context.read<ThemeProvider>().toggleTheme(),
                  );
                }),
                Opacity(
                  opacity: 0.55,
                  child: _menuTile(
                    context,
                    icon: Icons.security_rounded,
                    iconColor: const Color(0xFF16A34A),
                    title: 'Security',
                    subtitle: 'Not available',
                    scale: scale,
                    onTap: () {},
                    trailing: const SizedBox.shrink(),
                  ),
                ),

                SizedBox(height: sectionGap),

                // ── Support Section ─────────────────────────────
                _sectionHeader(context, t.supportSection, Icons.support_rounded, scale),
                const SizedBox(height: 10),
                _menuTile(
                  context,
                  icon: Icons.help_center_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: t.profileHelpSupport,
                  scale: scale,
                  onTap: () => _showComingSoon(context, t.homeHelpCenter),
                ),
                _menuTile(
                  context,
                  icon: Icons.privacy_tip_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: t.profilePrivacyPolicy,
                  scale: scale,
                  onTap: () => _showComingSoon(context, t.profilePrivacyPolicy),
                ),
                _menuTile(
                  context,
                  icon: Icons.info_rounded,
                  iconColor: const Color(0xFF6366F1),
                  title: t.profileAboutProfinder,
                  // FIX: dummy static dialog ki jagah ab wahi AboutScreen
                  // jo customer/professional profile use karte hain — admin
                  // ka post kiya hua About content yahan bhi dikhega
                  scale: scale,
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                ),

                SizedBox(height: sectionGap * 1.5),

                // ── Footer ──────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      AppLogo(size: ResponsiveUtils.sp(32, scale, min: 30, max: 40)),
                      const SizedBox(height: 8),
                      Text(
                        t.profileProfinderV100,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.sp(12, scale, min: 11, max: 14),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                          color: context.colors.textSecondary.withOpacity(0.6),
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

  Widget _sectionHeader(BuildContext context, String text, IconData icon, double scale) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.12),
                  const Color(0xFF6366F1).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6366F1),
              size: ResponsiveUtils.sp(15, scale, min: 13, max: 17),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: ResponsiveUtils.sp(11, scale, min: 10, max: 13),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6366F1),
              letterSpacing: 1.0,
            ),
          ),
        ],
      );

  Widget _lockedQuickAction(BuildContext context, IconData icon, String label, double scale) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Opacity(
      opacity: 0.55,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: context.colors.textSecondary.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: context.colors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required double scale,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final leadingSize = ResponsiveUtils.sp(40, scale, min: 36, max: 46);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.06) 
              : Colors.black.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.15) 
                : Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: leadingSize,
                  height: leadingSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        iconColor.withOpacity(0.12),
                        iconColor.withOpacity(0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: ResponsiveUtils.sp(20, scale, min: 18, max: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.sp(15, scale, min: 14, max: 17),
                          fontWeight: FontWeight.w500,
                          color: context.colors.textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.sp(12.5, scale, min: 12, max: 14),
                            fontWeight: FontWeight.w400,
                            color: context.colors.textSecondary.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuSwitchTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required double scale,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final leadingSize = ResponsiveUtils.sp(40, scale, min: 36, max: 46);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.06) 
              : Colors.black.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.15) 
                : Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: leadingSize,
              height: leadingSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    iconColor.withOpacity(0.12),
                    iconColor.withOpacity(0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: ResponsiveUtils.sp(20, scale, min: 18, max: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.sp(15, scale, min: 14, max: 17),
                      fontWeight: FontWeight.w500,
                      color: context.colors.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.sp(12.5, scale, min: 12, max: 14),
                        fontWeight: FontWeight.w400,
                        color: context.colors.textSecondary.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              activeColor: const Color(0xFF6366F1),
              activeTrackColor: const Color(0xFF6366F1).withOpacity(0.25),
              inactiveThumbColor: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
              inactiveTrackColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    final t = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.comingSoon(feature)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF6366F1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

}