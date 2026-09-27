// lib/features/professional/screens/help_support_screen.dart
//
// Static FAQ + contact screen. "Send us an email" button uses url_launcher
// to open the device's mail app — this package is already a common Flutter
// dependency; add `url_launcher` to pubspec.yaml if not already present.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../l10n/generated/app_localizations.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  // Static FAQ keys — content is localized via helper methods
  static const _faqKeys = [
    'faq_get_verified',
    'faq_withdraw_earnings',
    'faq_booking_pending',
    'faq_improve_profile',
    'faq_change_availability',
  ];

  String _getFaqQuestion(String key, BuildContext context) {
    switch (key) {
      case 'faq_get_verified':
        return AppLocalizations.of(context)!.faqGetVerifiedQ;
      case 'faq_withdraw_earnings':
        return AppLocalizations.of(context)!.faqWithdrawEarningsQ;
      case 'faq_booking_pending':
        return AppLocalizations.of(context)!.faqBookingPendingQ;
      case 'faq_improve_profile':
        return AppLocalizations.of(context)!.faqImproveProfileQ;
      case 'faq_change_availability':
        return AppLocalizations.of(context)!.faqChangeAvailabilityQ;
      default:
        return '';
    }
  }

  String _getFaqAnswer(String key, BuildContext context) {
    switch (key) {
      case 'faq_get_verified':
        return AppLocalizations.of(context)!.faqGetVerifiedA;
      case 'faq_withdraw_earnings':
        return AppLocalizations.of(context)!.faqWithdrawEarningsA;
      case 'faq_booking_pending':
        return AppLocalizations.of(context)!.faqBookingPendingA;
      case 'faq_improve_profile':
        return AppLocalizations.of(context)!.faqImproveProfileA;
      case 'faq_change_availability':
        return AppLocalizations.of(context)!.faqChangeAvailabilityA;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width > 600;

    // Build FAQ items with localized content
    final faqs = _faqKeys.map((key) {
      return {
        'q': _getFaqQuestion(key, context),
        'a': _getFaqAnswer(key, context),
      };
    }).toList();

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.helpSupportTitle,
          style: TextStyle(
            fontSize: isTablet ? 18.0 : 16.0,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // ── Contact Card ──────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.needMoreHelpLabel,
                        style: TextStyle(
                          fontSize: isTablet ? 15 : 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context)!.supportTeamReplyLabel,
                        style: TextStyle(
                          fontSize: isTablet ? 12 : 11,
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showContactSheet(context),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 18 : 14,
                      vertical: isTablet ? 10 : 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.contactCta,
                    style: TextStyle(
                      fontSize: isTablet ? 13 : 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.professionalColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── FAQ Section ──────────────────────────────
          Text(
            AppLocalizations.of(context)!.faqSectionLabel,
            style: TextStyle(
              fontSize: isTablet ? 16 : 15,
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 10),
          ...faqs.map((faq) => _buildFaqTile(
                context,
                faq['q']!,
                faq['a']!,
                isDark,
                isTablet,
              )),
        ],
      ),
    );
  }

  void _showContactSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width > 600;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 24 : 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.15)
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.contactSupportTitle,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.professionalColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.email_outlined,
                      color: AppColors.professionalColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.contactEmailLabel,
                    style: TextStyle(
                      fontSize: isTablet ? 15 : 14,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!.contactEmailSubtitle,
                    style: TextStyle(
                      fontSize: isTablet ? 13 : 12,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: context.colors.textSecondary,
                    size: 20,
                  ),
                  onTap: () {}, // ⚠️ Wire up url_launcher's launchUrl(Uri(scheme: 'mailto', ...)) here
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.professionalColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: AppColors.professionalColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.contactChatLabel,
                    style: TextStyle(
                      fontSize: isTablet ? 15 : 14,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!.contactChatSubtitle,
                    style: TextStyle(
                      fontSize: isTablet ? 13 : 12,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: context.colors.textSecondary,
                    size: 20,
                  ),
                  onTap: () {}, // ⚠️ Hook up to your support chat provider (Intercom, Zendesk, etc.)
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqTile(
    BuildContext context,
    String question,
    String answer,
    bool isDark,
    bool isTablet,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
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
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Text(
            question,
            style: TextStyle(
              fontSize: isTablet ? 14.5 : 13.5,
              fontWeight: FontWeight.w600,
              color: context.colors.textPrimary,
              letterSpacing: -0.1,
            ),
          ),
          iconColor: AppColors.professionalColor,
          collapsedIconColor: context.colors.textSecondary,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          expandedAlignment: Alignment.topLeft,
          children: [
            Text(
              answer,
              style: TextStyle(
                fontSize: isTablet ? 13.5 : 12.5,
                color: context.colors.textSecondary,
                height: 1.6,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}