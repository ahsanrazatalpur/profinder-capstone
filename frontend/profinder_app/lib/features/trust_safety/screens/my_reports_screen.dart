// lib/features/trust_safety/screens/my_reports_screen.dart
//
// Trust & Safety Part 8 — "My Reports": reports the CURRENT user submitted
// about other people. Backed by GET /admin-panel/reports/mine/ and
// MyUserReportSerializer, which is deliberately narrow — see that
// serializer's docstring on the backend for exactly what is shown and what
// is never included (reported user's identity, admin notes, reviewer
// identity, the exact moderation punishment given to anyone else).

import 'package:flutter/material.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../services/auth_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/user_ts_models.dart';
import '../services/user_trust_safety_service.dart';
import '../widgets/ts_labels.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final _service = UserTrustSafetyService();

  bool _loading = true;
  bool _hasError = false;
  List<MyReport> _reports = const [];

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
      final reports = await _service.fetchMyReports();
      if (!mounted) return;
      setState(() {
        _reports = reports;
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

  String _categoryLabel(AppLocalizations t, String code) => reportCategoryLabel(t, code);

  String _statusLabel(AppLocalizations t, String status) => reportStatusLabel(t, status);

  String _outcomeLabel(AppLocalizations t, String outcome) => reportOutcomeLabel(t, outcome);

  Color _statusColor(String status) {
    switch (status) {
      case MyReportStatus.actionTaken: return AppColors.success;
      case MyReportStatus.dismissed: return context.colors.textSecondary;
      case MyReportStatus.reviewed: return AppColors.primary;
      default: return AppColors.warningAmber; // pending
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final accent = AppHelpers.getRoleColor(auth.role ?? 'customer');

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: UniversalAppBar(
        title: t.myTsMyReportsTitle,
        icon: Icons.flag_rounded,
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
              ? _buildErrorState(context, t, accent)
              : _reports.isEmpty
                  ? _buildEmptyState(context, t, accent)
                  : RefreshIndicator(
                      color: accent,
                      onRefresh: _load,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _reports.length,
                        itemBuilder: (_, i) => _reportCard(context, t, _reports[i]),
                      ),
                    ),
    );
  }

  Widget _buildErrorState(BuildContext context, AppLocalizations t, Color accent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: context.colors.textSecondary),
            const SizedBox(height: 12),
            Text(
              t.myTsReportsLoadError,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: AppFontSizes.body, color: context.colors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _load, child: Text(t.tsRetry)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations t, Color accent) {
    return RefreshIndicator(
      color: accent,
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (_, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 44, color: context.colors.textSecondary.withValues(alpha: 0.5)),
                    const SizedBox(height: 14),
                    Text(
                      t.myTsReportsEmptyTitle,
                      style: TextStyle(fontSize: AppFontSizes.input, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.myTsReportsEmptyMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: AppFontSizes.secondary, color: context.colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _reportCard(BuildContext context, AppLocalizations t, MyReport report) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor(report.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : context.colors.divider),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _categoryLabel(t, report.category),
                  style: TextStyle(fontSize: AppFontSizes.input, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppSizes.radiusChip)),
                child: Text(
                  _statusLabel(t, report.status),
                  style: TextStyle(fontSize: AppFontSizes.caption, fontWeight: FontWeight.w700, color: statusColor),
                ),
              ),
            ],
          ),
          if (report.createdAt != null) ...[
            const SizedBox(height: 6),
            Text(
              '${t.myTsSubmittedLabel}: ${AppHelpers.formatDate(report.createdAt!)}',
              style: TextStyle(fontSize: AppFontSizes.small, color: context.colors.textSecondary),
            ),
          ],
          if (report.description.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              t.myTsYourDescriptionLabel,
              style: TextStyle(fontSize: AppFontSizes.caption, fontWeight: FontWeight.w600, color: context.colors.textSecondary, letterSpacing: 0.3),
            ),
            const SizedBox(height: 3),
            Text(
              report.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: AppFontSizes.secondary, color: context.colors.textPrimary, height: 1.35),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.colors.background,
              borderRadius: BorderRadius.circular(AppSizes.radius10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 15, color: context.colors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _outcomeLabel(t, report.outcome),
                    style: TextStyle(fontSize: AppFontSizes.small, color: context.colors.textSecondary, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}