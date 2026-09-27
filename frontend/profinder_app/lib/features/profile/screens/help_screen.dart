// lib/features/profile/screens/help_screen.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../l10n/generated/app_localizations.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  // Static FAQ data — keys are mapped to localized strings in the build method
  static const _faqKeys = [
    'faq_how_to_book',
    'faq_how_to_cancel',
    'faq_how_refunds_work',
    'faq_how_to_get_verified',
    'faq_is_payment_secure',
  ];

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
          AppLocalizations.of(context)!.helpTitle,
          style: TextStyle(
            fontSize: isTablet ? 18.0 : 16.0,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: context.colors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // ── Support Banner ──────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
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
                        AppLocalizations.of(context)!.supportBannerTitle,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 16 : 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context)!.supportBannerSubtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: isTablet ? 13 : 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Contact Tiles ──────────────────────────────
          Row(
            children: [
              Expanded(
                child: _contactTile(
                  context,
                  Icons.email_outlined,
                  AppLocalizations.of(context)!.contactEmailTitle,
                  AppLocalizations.of(context)!.contactEmailSubtitle,
                  isDark,
                  isTablet,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _contactTile(
                  context,
                  Icons.chat_bubble_outline_rounded,
                  AppLocalizations.of(context)!.contactChatTitle,
                  AppLocalizations.of(context)!.contactChatSubtitle,
                  isDark,
                  isTablet,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── FAQ Section ────────────────────────────────
          Text(
            AppLocalizations.of(context)!.faqSectionTitle,
            style: TextStyle(
              fontSize: isTablet ? 15 : 14,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 10),

          ...faqs.map((f) => _faqTile(
                context,
                f['q']!,
                f['a']!,
                isDark,
                isTablet,
              )),
        ],
      ),
    );
  }

  // ── Helper methods for FAQ localization ──────────────
  String _getFaqQuestion(String key, BuildContext context) {
    switch (key) {
      case 'faq_how_to_book':
        return AppLocalizations.of(context)!.faqHowToBookQ;
      case 'faq_how_to_cancel':
        return AppLocalizations.of(context)!.faqHowToCancelQ;
      case 'faq_how_refunds_work':
        return AppLocalizations.of(context)!.faqRefundsQ;
      case 'faq_how_to_get_verified':
        return AppLocalizations.of(context)!.faqGetVerifiedQ;
      case 'faq_is_payment_secure':
        return AppLocalizations.of(context)!.faqPaymentSecureQ;
      default:
        return '';
    }
  }

  String _getFaqAnswer(String key, BuildContext context) {
    switch (key) {
      case 'faq_how_to_book':
        return AppLocalizations.of(context)!.faqHowToBookA;
      case 'faq_how_to_cancel':
        return AppLocalizations.of(context)!.faqHowToCancelA;
      case 'faq_how_refunds_work':
        return AppLocalizations.of(context)!.faqRefundsA;
      case 'faq_how_to_get_verified':
        return AppLocalizations.of(context)!.faqGetVerifiedA;
      case 'faq_is_payment_secure':
        return AppLocalizations.of(context)!.faqPaymentSecureA;
      default:
        return '';
    }
  }

  Widget _contactTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    bool isDark,
    bool isTablet,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      padding: EdgeInsets.all(isTablet ? 16 : 14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.08)
                : Colors.grey.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.customerColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.customerColor,
              size: isTablet ? 20 : 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: isTablet ? 14 : 13,
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: isTablet ? 11 : 10.5,
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _faqTile(BuildContext context, String q, String a, bool isDark, bool isTablet) {
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
              : const Color(0xFFE5E7EB),
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
            q,
            style: TextStyle(
              fontSize: isTablet ? 14.5 : 13.5,
              fontWeight: FontWeight.w600,
              color: context.colors.textPrimary,
              letterSpacing: -0.1,
            ),
          ),
          iconColor: AppColors.customerColor,
          collapsedIconColor: context.colors.textSecondary,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          expandedAlignment: Alignment.topLeft,
          children: [
            Text(
              a,
              style: TextStyle(
                fontSize: isTablet ? 13 : 12.5,
                color: context.colors.textSecondary,
                height: 1.5,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}