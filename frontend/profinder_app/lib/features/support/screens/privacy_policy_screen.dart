// lib/features/support/screens/privacy_policy_screen.dart
//
// In-app Privacy Policy, Platform Terms & Direct Dealing Guidelines.
// Consolidates:
// 1. Direct dealing & intermediary directory policy (no in-app payments).
// 2. Platform responsibility, dispute resolution, and Pakistani legal guidelines.
// 3. How "Jobs Done" is transparently verified.
// 4. Safe dealing recommendations for customers and professionals.
// 5. Data protection, privacy standards, and sensitive document security.

import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../../../services/support_service.dart';
import '../models/policy_document.dart';
import '../widgets/support_section_heading.dart';
import '../widgets/support_state_views.dart';

typedef PolicyLoader =
    Future<SupportResult<PolicyDocument>> Function(String lang);

class PrivacyPolicyScreen extends StatefulWidget {
  /// Overridable for tests; defaults to the real API.
  final PolicyLoader? loader;

  const PrivacyPolicyScreen({super.key, this.loader});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  SupportResult<PolicyDocument>? _result;
  bool _loading = true;
  String? _loadedLang;
  int _requestId = 0;

  Future<SupportResult<PolicyDocument>> _fetch(String lang) =>
      (widget.loader ?? (l) => SupportService().getPrivacyPolicy(lang: l))(
        lang,
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Localizations.localeOf(context).languageCode;
    if (lang != _loadedLang) {
      _loadedLang = lang;
      _load(lang);
    }
  }

  Future<void> _load(String lang) async {
    final id = ++_requestId;
    setState(() => _loading = true);
    final result = await _fetch(lang);
    if (!mounted || id != _requestId) {
      return;
    }
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: UniversalAppBar(
        title: t.profilePrivacyPolicy,
        icon: Icons.privacy_tip_rounded,
      ),
      body: SafeArea(child: _body(context, t)),
    );
  }

  Widget _body(BuildContext context, AppLocalizations t) {
    if (_loading) return const SupportLoadingState();
    final result = _result;
    final doc = (result != null && result.isOk) ? result.data : null;
    return _fullContent(context, t, doc);
  }

  Widget _fullContent(
    BuildContext context,
    AppLocalizations t,
    PolicyDocument? doc,
  ) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = ResponsiveUtils.scaleForWidth(width);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentMaxWidth = width > 720 ? 720.0 : width;
    final hPad = ResponsiveUtils.screenPadding(width);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentMaxWidth),
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 18),
          children: [
            // ── Hero Notice: Intermediary Model & Direct Dealing ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.primary.withValues(alpha: 0.22),
                          AppColors.accentPurple.withValues(alpha: 0.16),
                        ]
                      : [
                          const Color(0xFFEFF6FF),
                          const Color(0xFFF5F3FF),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(
                  color: isDark
                      ? AppColors.primary.withValues(alpha: 0.35)
                      : const Color(0xFFBFDBFE),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_user_rounded,
                      size: 34,
                      color: context.colors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Direct Dealing & Intermediary Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.sp(17.5, scale, min: 16, max: 20),
                      fontWeight: FontWeight.w800,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'براہ راست لین دین اور پلیٹ فارم شرائط و ضوابط',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.sp(14, scale, min: 13, max: 15),
                      fontWeight: FontWeight.w600,
                      color: context.colors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'ProFinder acts solely as a discovery and booking directory. All work agreements, negotiations, and payments take place directly between clients and independent service professionals.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.sp(13, scale, min: 12, max: 14),
                      color: context.colors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Section 1: Intermediary Platform Model ──
            _policyCard(
              context: context,
              icon: Icons.storefront_outlined,
              iconColor: AppColors.primary,
              title: '1. Intermediary Platform Model (صرف رابطہ و بکنگ)',
              description:
                  'ProFinder provides an open technology platform enabling customers to search, discover, compare portfolios, and connect with local independent service professionals. '
                  'ProFinder does not provide direct labor, employ service professionals, or supervise physical execution of services.',
              isDark: isDark,
              scale: scale,
            ),

            const SizedBox(height: 14),

            // ── Section 2: Direct Payments Only ──
            _policyCard(
              context: context,
              icon: Icons.payments_outlined,
              iconColor: AppColors.emerald,
              title: '2. Direct Payments Only (براہ راست ادائیگی)',
              description:
                  '• No In-App Payment Processing: ProFinder does not charge, collect, hold, or escrow customer funds for service bookings.\n'
                  '• Independent Dealing: All rates, quotes, material costs, and payments are settled directly between the client and the professional (via Cash, Direct Bank Transfer, Raast, or Mobile Wallets).\n'
                  '• Informational Price Estimates: Listed rates are indicative starting estimates provided by professionals. Final agreed costs are determined mutually between both parties.',
              isDark: isDark,
              scale: scale,
            ),

            const SizedBox(height: 14),

            // ── Section 3: Platform Responsibility & Safety ──
            _policyCard(
              context: context,
              icon: Icons.shield_outlined,
              iconColor: AppColors.indigo,
              title: '3. Platform Responsibility & Safety (ذمہ داری اور حدود)',
              description:
                  '• Independent Contracts: Any engagement formed is strictly a direct bilateral contract between the customer and the professional.\n'
                  '• Mutual Discretion: Both parties engage and conduct transactions entirely at their own mutual discretion.\n'
                  '• Platform Moderation: ProFinder reviews user reports, moderates listings, investigates suspicious accounts, and suspends accounts violating community standards under applicable Pakistani laws.',
              isDark: isDark,
              scale: scale,
            ),

            const SizedBox(height: 14),

            // ── Section 4: How "Jobs Done" is Tracked ──
            _policyCard(
              context: context,
              icon: Icons.verified_rounded,
              iconColor: AppColors.accentPurple,
              title: '4. How "Jobs Done" is Tracked (کام کی تصدیق)',
              description:
                  '• Verified Completion Flow: A job is counted transparently when an inquiry is accepted and confirmed as completed by both parties.\n'
                  '• Client Confirmation: Customers have direct authority in their inquiries dashboard to confirm completed services upon satisfactory delivery.\n'
                  '• Verified Reviews: Once confirmed, customers are invited to rate and write verified reviews.',
              isDark: isDark,
              scale: scale,
            ),

            const SizedBox(height: 14),

            // ── Section 5: Safety Best Practices ──
            _safetyNotice(context, isDark, scale),

            const SizedBox(height: 20),

            // ── Section 6: Data Privacy & Sensitive Document Protection ──
            _policyCard(
              context: context,
              icon: Icons.lock_outline_rounded,
              iconColor: AppColors.cyan,
              title: '5. Privacy & Sensitive Document Protection (ڈیٹا کا تحفظ)',
              description:
                  '• Sensitive Documents Protected: CNIC images, government IDs, and trade licences uploaded by professionals for verification are stored securely and never made accessible through public profile pages or public APIs.\n'
                  '• Contact Data: Phone numbers and communication data are shared strictly for facilitating direct service inquiries and verified communication.\n'
                  '• Chat Data: In-app chat, messages, and voice notes are handled securely to facilitate your customer-professional discussions.',
              isDark: isDark,
              scale: scale,
            ),

            // If backend returned published policy document blocks, render them seamlessly below
            if (doc != null && doc.blocks.isNotEmpty) ...[
              const SizedBox(height: 24),
              SupportSectionHeading(
                text: doc.title.isNotEmpty ? doc.title : 'Additional Legal & Privacy Policies',
                padding: const EdgeInsetsDirectional.only(bottom: AppSizes.sm),
              ),
              Directionality(
                textDirection: doc.isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final block in doc.blocks) _block(context, block),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            // ── Footer ──
            Center(
              child: Text(
                'ProFinder Platform Policy & Privacy Terms • Pakistan Scope • 2026',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ResponsiveUtils.sp(11.5, scale, min: 10.5, max: 12.5),
                  color: context.colors.textSecondary.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _policyCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isDark,
    required double scale,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: context.colors.divider.withValues(alpha: isDark ? 0.25 : 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.035),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 21, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.sp(15, scale, min: 14, max: 16.5),
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            description,
            style: TextStyle(
              fontSize: ResponsiveUtils.sp(13.2, scale, min: 12.2, max: 14.2),
              color: context.colors.textSecondary,
              height: 1.48,
            ),
          ),
        ],
      ),
    );
  }

  Widget _safetyNotice(BuildContext context, bool isDark, double scale) {
    final tips = [
      '🔍 Inspect Work First: Always review completed work before making any direct payment.',
      '🚫 Avoid 100% Upfront Advances: Never transfer full payment in advance to unverified individuals.',
      '📝 Document Agreements: Keep clear records of agreed scope, materials, and price in chat messages.',
      '🧾 Request Receipts: Ask the professional for a direct physical or digital payment receipt.',
      '🛡️ Report Suspicious Behavior: Report any misconduct, scam attempts, or policy violations via our Support Center.',
    ];

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.warningAmber.withValues(alpha: 0.12)
            : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isDark
              ? AppColors.warningAmber.withValues(alpha: 0.35)
              : const Color(0xFFFDE68A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_rounded,
                color: AppColors.warningAmber,
                size: 21,
              ),
              const SizedBox(width: 10),
              Text(
                'Best Practices for Safe Dealing (اہم مشورے)',
                style: TextStyle(
                  fontSize: ResponsiveUtils.sp(14.5, scale, min: 13.5, max: 16),
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.warningAmber : const Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Text(
                tip,
                style: TextStyle(
                  fontSize: ResponsiveUtils.sp(12.8, scale, min: 12, max: 13.8),
                  color: isDark
                      ? context.colors.textSecondary
                      : const Color(0xFF78350F),
                  height: 1.44,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _block(BuildContext context, PolicyBlock block) {
    final colors = context.colors;
    final styles = context.textStyles;
    switch (block.type) {
      case PolicyBlockType.heading:
        return SupportSectionHeading(
          text: block.text,
          padding: const EdgeInsetsDirectional.only(
            top: AppSizes.md,
            bottom: AppSizes.sm,
          ),
        );
      case PolicyBlockType.bullet:
        return Padding(
          padding: const EdgeInsetsDirectional.only(bottom: AppSizes.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  top: 9,
                  end: AppSizes.sm + 4,
                ),
                child: Icon(Icons.circle, size: 6, color: colors.textSecondary),
              ),
              Expanded(
                child: Text(
                  block.text,
                  style: styles.bodyLarge.copyWith(
                    height: 1.55,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      case PolicyBlockType.paragraph:
        return Padding(
          padding: const EdgeInsetsDirectional.only(bottom: AppSizes.sm + 4),
          child: Text(
            block.text,
            style: styles.bodyLarge.copyWith(height: 1.55, letterSpacing: 0),
          ),
        );
    }
  }
}
