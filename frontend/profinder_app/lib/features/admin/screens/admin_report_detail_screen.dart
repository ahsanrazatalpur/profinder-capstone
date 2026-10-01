// lib/features/admin/screens/admin_report_detail_screen.dart
//
// Full-screen wrapper around [ReportDetailPanel] for phones and narrow
// windows. On wide screens the reports list embeds the panel directly.

import 'package:flutter/material.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/ts_models.dart';
import '../services/trust_safety_service.dart';
import '../widgets/report_detail_panel.dart';
import '../widgets/ts_ui.dart';
import '../../../shared/widgets/universal_app_bar.dart';

class AdminReportDetailScreen extends StatelessWidget {
  final TsReport report;
  final List<TsReport> allReports;
  final TrustSafetyService service;
  final ValueChanged<TsReport> onReportChanged;
  final ValueChanged<TsReport> onOpenReport;

  const AdminReportDetailScreen({
    super.key,
    required this.report,
    required this.allReports,
    required this.service,
    required this.onReportChanged,
    required this.onOpenReport,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: TsColors.bg,
      appBar: UniversalAppBar(
        title: l.tsReportNumber(report.id.toString()),
        icon: Icons.flag_rounded,
      ),
      body: SafeArea(
        top: false,
        child: ReportDetailPanel(
          report: report,
          allReports: allReports,
          service: service,
          onReportChanged: onReportChanged,
          onOpenReport: onOpenReport,
        ),
      ),
    );
  }
}