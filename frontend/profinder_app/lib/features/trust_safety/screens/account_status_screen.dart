// lib/features/trust_safety/screens/account_status_screen.dart
//
// Trust & Safety Part 8 — "Account Moderation Status" for the CURRENT user
// (customer or professional). Always fetches fresh from the backend via
// UserTrustSafetyService (never derived from cached/local state — see
// MyModerationStatusView on the backend). Also surfaces the user's own
// appeals and lets them submit a new one for an eligible action.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../services/auth_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/user_ts_models.dart';
import '../services/user_trust_safety_service.dart';
import '../widgets/moderation_action_card.dart';
import '../widgets/appeal_form_sheet.dart';
import '../widgets/ts_labels.dart';

class AccountStatusScreen extends StatefulWidget {
  const AccountStatusScreen({super.key});

  @override
  State<AccountStatusScreen> createState() => _AccountStatusScreenState();
}

class _AccountStatusScreenState extends State<AccountStatusScreen> {
  final _service = UserTrustSafetyService();

  bool _loading = true;
  bool _hasError = false;
  MyModerationStatus _status = const MyModerationStatus.empty();
  List<MyAppeal> _appeals = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final results = await Future.wait([
        _service.fetchMyModerationStatus(),
        _service.fetchMyAppeals(),
      ]);
      if (!mounted) return;
      setState(() {
        _status = results[0] as MyModerationStatus;
        _appeals = results[1] as List<MyAppeal>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  Future<void> _openAppealSheet(MyModerationAction action, Color accent) async {
    final submitted = await showAppealFormSheet(context, action: action, accentColor: accent);
    if (submitted == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final accent = AppHelpers.getRoleColor(auth.role ?? 'customer');
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width > 600;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        title: Text(
          t.myTsAccountStatusTitle,
          style: TextStyle(
            fontSize: isTablet ? 18.0 : 16.0,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: context.colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(color: accent, strokeWidth: 3),
              ),
            )
          : _hasError
              ? _buildErrorState(context, t)
              : RefreshIndicator(
                  color: accent,
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_status.isInGoodStanding)
                          _buildGoodStanding(context, t)
                        else
                          ..._status.actions.map(
                            (a) => ModerationActionCard(
                              action: a,
                              accentColor: accent,
                              onAppealTap: () => _openAppealSheet(a, accent),
                            ),
                          ),
                        const SizedBox(height: 24),
                        _buildAppealsSection(context, t, accent),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorState(BuildContext context, AppLocalizations t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: context.colors.textSecondary),
            const SizedBox(height: 12),
            Text(
              t.myTsStatusLoadError,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: context.colors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _load, child: Text(t.tsRetry)),
          ],
        ),
      ),
    );
  }

  Widget _buildGoodStanding(BuildContext context, AppLocalizations t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: AppColors.success.withOpacity(0.14), shape: BoxShape.circle),
            child: const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            t.myTsGoodStandingTitle,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            t.myTsGoodStandingMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAppealsSection(BuildContext context, AppLocalizations t, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            t.myTsMyAppealsTitle.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.colors.textSecondary, letterSpacing: 0.6),
          ),
        ),
        if (_appeals.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              t.myTsMyAppealsEmpty,
              style: TextStyle(fontSize: 12.5, color: context.colors.textSecondary),
            ),
          )
        else
          ..._appeals.map((a) => _appealTile(context, t, a)),
      ],
    );
  }

  Widget _appealTile(BuildContext context, AppLocalizations t, MyAppeal appeal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color statusColor = appeal.isApproved
        ? AppColors.success
        : appeal.isRejected
            ? AppColors.error
            : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : context.colors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moderationActionTypeLabel(t, appeal.actionType, fallback: appeal.actionTypeDisplay),
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  appeal.reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                ),
                if (appeal.createdAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    AppHelpers.formatDate(appeal.createdAt!),
                    style: TextStyle(fontSize: 11, color: context.colors.textSecondary.withOpacity(0.8)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.14), borderRadius: BorderRadius.circular(20)),
            child: Text(
              appealStatusLabel(t, appeal.status),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }
}