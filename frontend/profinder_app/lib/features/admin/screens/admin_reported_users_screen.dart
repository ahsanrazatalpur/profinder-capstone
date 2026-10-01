// lib/features/admin/screens/admin_reported_users_screen.dart
//
// Admin → Reports (Trust & Safety).
//
// Upgraded from the original "Reported Users" list:
//   • category, severity, status, reporter, date and related booking / message /
//     evidence indicators on every card
//   • filters: status, severity, category, date; plus sort by newest / severity
//   • tap → full report detail with moderation actions
//   • desktop: list + detail split view; phone: list → full-screen detail
//
// Filtering is client-side: GET /admin-panel/reports/ is unpaginated and only
// supports ?status=, and the admin needs live counts for every filter anyway.
//
// The old inline "Also ban this user" checkbox (legacy `ban_user` PATCH with no
// confirmation) is intentionally gone; moderation now goes through the
// moderation-actions API with confirmation.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/ts_models.dart';
import '../services/trust_safety_service.dart';
import '../widgets/report_detail_panel.dart';
import '../widgets/ts_ui.dart';
import 'admin_report_detail_screen.dart';
import '../../../shared/widgets/universal_app_bar.dart';

enum _DateFilter { any, today, week, month, custom }

enum _Sort { newest, severity }

class AdminReportedUsersScreen extends StatefulWidget {
  const AdminReportedUsersScreen({super.key});

  @override
  State<AdminReportedUsersScreen> createState() =>
      _AdminReportedUsersScreenState();
}

class _AdminReportedUsersScreenState extends State<AdminReportedUsersScreen> {
  static const String _allKey = '__all__';
  static const double _splitBreakpoint = 1000;

  final TrustSafetyService _service = TrustSafetyService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<TsReport> _all = [];
  bool _loading = true;
  String? _error;
  int? _selectedId;

  String? _status;
  String? _severity;
  String? _category;
  _DateFilter _date = _DateFilter.any;
  DateTimeRange? _customRange;
  _Sort _sort = _Sort.newest;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load(showSpinner: false);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final rows = await _service.fetchReports();
      if (!mounted) return;
      setState(() {
        _all = rows;
        _loading = false;
        _error = null;
        if (_selectedId != null && !rows.any((r) => r.id == _selectedId)) {
          _selectedId = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      setState(() {
        _loading = false;
        _error = tsErrorMessage(l, e);
      });
    }
  }

  void _replace(TsReport updated) {
    if (!mounted) return;
    setState(() {
      _all = _all.map((r) => r.id == updated.id ? updated : r).toList();
    });
  }

  // ── Filtering ─────────────────────────────────────────────────────────────

  bool _matchesDate(TsReport r, DateTime now) {
    if (_date == _DateFilter.any) return true;
    final d = r.createdAt;
    if (d == null) return false;
    switch (_date) {
      case _DateFilter.today:
        return d.year == now.year && d.month == now.month && d.day == now.day;
      case _DateFilter.week:
        return d.isAfter(now.subtract(const Duration(days: 7)));
      case _DateFilter.month:
        return d.isAfter(now.subtract(const Duration(days: 30)));
      case _DateFilter.custom:
        final range = _customRange;
        if (range == null) return true;
        return !d.isBefore(range.start) &&
            d.isBefore(range.end.add(const Duration(days: 1)));
      case _DateFilter.any:
        return true;
    }
  }

  List<TsReport> _apply(AppLocalizations l, {required bool ignoreStatus}) {
    final q = _search.trim().toLowerCase();
    final now = DateTime.now();
    final out = _all.where((r) {
      if (!ignoreStatus && _status != null && r.status != _status) return false;
      if (_severity != null && r.severity != _severity) return false;
      if (_category != null && r.category != _category) return false;
      if (!_matchesDate(r, now)) return false;
      if (q.isNotEmpty) {
        final hay = [
          r.id.toString(),
          r.reportedUserName,
          r.reportedUserEmail,
          r.reporterName,
          r.description,
          tsCategoryLabel(l, r.category, fallback: r.categoryDisplay),
        ].join(' ').toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();

    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    if (_sort == _Sort.severity) {
      out.sort((a, b) {
        final c = Severity.rank(b.severity).compareTo(Severity.rank(a.severity));
        if (c != 0) return c;
        return (b.createdAt ?? epoch).compareTo(a.createdAt ?? epoch);
      });
    } else {
      out.sort((a, b) => (b.createdAt ?? epoch).compareTo(a.createdAt ?? epoch));
    }
    return out;
  }

  bool get _hasActiveFilters =>
      _status != null ||
      _severity != null ||
      _category != null ||
      _date != _DateFilter.any ||
      _search.trim().isNotEmpty;

  void _clearFilters() {
    setState(() {
      _status = null;
      _severity = null;
      _category = null;
      _date = _DateFilter.any;
      _customRange = null;
      _search = '';
      _searchCtrl.clear();
    });
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _customRange,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _customRange = picked;
      _date = _DateFilter.custom;
    });
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _select(TsReport r, bool split) {
    if (split) {
      setState(() => _selectedId = r.id);
    } else {
      _openDetail(r);
    }
  }

  void _openDetail(TsReport r) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminReportDetailScreen(
          report: r,
          allReports: _all,
          service: _service,
          onReportChanged: _replace,
          onOpenReport: _openDetail,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pending = _all.where((r) => r.status == ReportStatus.pending).length;
    return Scaffold(
      backgroundColor: TsColors.bg,
      appBar: UniversalAppBar(
        title: l.tsReportsTitle,
        subtitle: l.tsPendingReview(pending.toString()),
        icon: Icons.flag_rounded,
        showBack: false,
        actions: [
          AppBarIconButton(
            icon: Icons.refresh_rounded,
            tooltip: l.tsRefresh,
            onPressed: () { if (!_loading) _load(); },
            onGradient: true,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          final split = c.maxWidth >= _splitBreakpoint;
          final list = _buildListColumn(l, split, c.maxWidth);
          if (!split) return list;
          return Row(
            children: [
              SizedBox(width: 460, child: list),
              const VerticalDivider(width: 1, color: TsColors.border),
              Expanded(child: _buildDetailPane(l)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailPane(AppLocalizations l) {
    TsReport? selected;
    for (final r in _all) {
      if (r.id == _selectedId) selected = r;
    }
    if (selected == null) {
      return TsEmptyState(
        icon: Icons.touch_app_outlined,
        title: l.tsSelectReport,
        message: l.tsSelectReportHint,
      );
    }
    return ReportDetailPanel(
      key: ValueKey<int>(selected.id),
      report: selected,
      allReports: _all,
      service: _service,
      onReportChanged: _replace,
      onOpenReport: (r) => setState(() => _selectedId = r.id),
    );
  }

  Widget _buildListColumn(AppLocalizations l, bool split, double width) {
    final hPad = split ? 14.0 : (width >= 700 ? 24.0 : 12.0);

    return Column(
      children: [
        _buildSearchAndFilters(l, hPad),
        Expanded(child: _buildBody(l, split, hPad)),
      ],
    );
  }

  Widget _buildSearchAndFilters(AppLocalizations l, double hPad) {
    final base = _apply(l, ignoreStatus: true);
    int countFor(String? s) =>
        s == null ? base.length : base.where((r) => r.status == s).length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              style: const TextStyle(fontSize: 13, color: TsColors.textPrimary),
              decoration: InputDecoration(
                hintText: l.tsSearchReportsHint,
                hintStyle: const TextStyle(fontSize: 13, color: TsColors.textFaint),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 20, color: TsColors.textFaint),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 18, color: TsColors.textFaint),
                        onPressed: () => setState(() {
                          _search = '';
                          _searchCtrl.clear();
                        }),
                      ),
                filled: true,
                fillColor: TsColors.bg,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: hPad),
              children: [
                _statusChip(l.tsAll, null, countFor(null), TsColors.accent),
                for (final s in ReportStatus.all)
                  _statusChip(tsStatusLabel(l, s), s, countFor(s), tsStatusColor(s)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: hPad),
              children: [
                _severityMenu(l),
                _categoryMenu(l),
                _dateMenu(l),
                _sortMenu(l),
                if (_hasActiveFilters)
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                    label: Text(l.tsClearFilters),
                    style: TextButton.styleFrom(foregroundColor: TsColors.accent),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, String? value, int count, Color color) {
    final selected = _status == value;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _status = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? color : color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? color : color.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _item(String value, String label, bool selected) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: selected
                ? const Icon(Icons.check_rounded, size: 17, color: TsColors.accent)
                : null,
          ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: TsColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuButton({
    required String label,
    required IconData icon,
    required bool active,
    required List<PopupMenuEntry<String>> Function(BuildContext) itemBuilder,
    required ValueChanged<String> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 38),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: itemBuilder,
        onSelected: onSelected,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? TsColors.accent.withValues(alpha: 0.1) : TsColors.bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? TsColors.accent : TsColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: active ? TsColors.accent : TsColors.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? TsColors.accent : TsColors.textBody,
                ),
              ),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 18,
                color: active ? TsColors.accent : TsColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _severityMenu(AppLocalizations l) {
    return _menuButton(
      label: _severity == null ? l.tsFilterSeverity : tsSeverityLabel(l, _severity),
      icon: Icons.priority_high_rounded,
      active: _severity != null,
      itemBuilder: (_) => [
        _item(_allKey, l.tsAll, _severity == null),
        for (final s in Severity.all) _item(s, tsSeverityLabel(l, s), _severity == s),
      ],
      onSelected: (v) => setState(() => _severity = v == _allKey ? null : v),
    );
  }

  Widget _categoryMenu(AppLocalizations l) {
    return _menuButton(
      label: _category == null ? l.tsFilterCategory : tsCategoryLabel(l, _category!),
      icon: Icons.flag_outlined,
      active: _category != null,
      itemBuilder: (_) => [
        _item(_allKey, l.tsAll, _category == null),
        for (final c in ReportCategory.all)
          _item(c, tsCategoryLabel(l, c), _category == c),
      ],
      onSelected: (v) => setState(() => _category = v == _allKey ? null : v),
    );
  }

  String _dateLabel(AppLocalizations l) {
    switch (_date) {
      case _DateFilter.today:
        return l.tsDateToday;
      case _DateFilter.week:
        return l.tsDate7;
      case _DateFilter.month:
        return l.tsDate30;
      case _DateFilter.custom:
        final r = _customRange;
        return r == null
            ? l.tsDateCustom
            : '${tsFmtDate(r.start)} – ${tsFmtDate(r.end)}';
      case _DateFilter.any:
        return l.tsFilterDate;
    }
  }

  Widget _dateMenu(AppLocalizations l) {
    return _menuButton(
      label: _dateLabel(l),
      icon: Icons.calendar_today_rounded,
      active: _date != _DateFilter.any,
      itemBuilder: (_) => [
        _item('any', l.tsDateAny, _date == _DateFilter.any),
        _item('today', l.tsDateToday, _date == _DateFilter.today),
        _item('week', l.tsDate7, _date == _DateFilter.week),
        _item('month', l.tsDate30, _date == _DateFilter.month),
        _item('custom', l.tsDateCustom, _date == _DateFilter.custom),
      ],
      onSelected: (v) {
        switch (v) {
          case 'today':
            setState(() => _date = _DateFilter.today);
            break;
          case 'week':
            setState(() => _date = _DateFilter.week);
            break;
          case 'month':
            setState(() => _date = _DateFilter.month);
            break;
          case 'custom':
            _pickCustomRange();
            break;
          default:
            setState(() => _date = _DateFilter.any);
        }
      },
    );
  }

  Widget _sortMenu(AppLocalizations l) {
    return _menuButton(
      label: _sort == _Sort.newest ? l.tsSortNewest : l.tsSortSeverity,
      icon: Icons.sort_rounded,
      active: _sort != _Sort.newest,
      itemBuilder: (_) => [
        _item('newest', l.tsSortNewest, _sort == _Sort.newest),
        _item('severity', l.tsSortSeverity, _sort == _Sort.severity),
      ],
      onSelected: (v) =>
          setState(() => _sort = v == 'severity' ? _Sort.severity : _Sort.newest),
    );
  }

  Widget _buildBody(AppLocalizations l, bool split, double hPad) {
    if (_loading) return const TsLoading();
    if (_error != null) {
      return TsErrorState(message: _error!, onRetry: () => _load());
    }
    final rows = _apply(l, ignoreStatus: false);

    if (_all.isEmpty) {
      return RefreshIndicator(
        color: TsColors.accent,
        onRefresh: () => _load(showSpinner: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            TsEmptyState(
              icon: Icons.verified_user_outlined,
              color: TsColors.success,
              title: l.tsNoReports,
              message: l.tsNoReportsHint,
            ),
          ],
        ),
      );
    }
    if (rows.isEmpty) {
      return ListView(
        children: [
          TsEmptyState(
            icon: Icons.search_off_rounded,
            title: l.tsNoMatches,
            message: l.tsNoMatchesHint,
          ),
          Center(
            child: TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
              label: Text(l.tsClearFilters),
              style: TextButton.styleFrom(foregroundColor: TsColors.accent),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      color: TsColors.accent,
      onRefresh: () => _load(showSpinner: false),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 24),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final r = rows[i];
          return _ReportCard(
            report: r,
            selected: split && r.id == _selectedId,
            onTap: () => _select(r, split),
          );
        },
      ),
    );
  }
}

// ── Card ─────────────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final TsReport report;
  final bool selected;
  final VoidCallback onTap;

  const _ReportCard({
    required this.report,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = report;
    final urgent = r.severity == Severity.critical && !r.isResolved;

    return TsCard(
      selected: selected,
      accentBorder: urgent ? TsColors.sevCritical.withValues(alpha: 0.45) : null,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TsUserAvatar(name: r.reportedUserName, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.reportedUserName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: TsColors.textPrimary,
                      ),
                    ),
                    Text(
                      tsRoleLabel(l, r.reportedUserRole),
                      style: const TextStyle(fontSize: 11.5, color: TsColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tsFmtDate(r.createdAt),
                style: const TextStyle(fontSize: 11, color: TsColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              TsBadge(
                label: tsCategoryLabel(l, r.category, fallback: r.categoryDisplay),
                color: TsColors.textBody,
                icon: Icons.flag_outlined,
              ),
              TsSeverityBadge(severity: r.severity),
              TsStatusBadge(status: r.status, display: r.statusDisplay),
              if (!r.reportedUserActive)
                TsBadge(
                  label: l.tsAccountBlocked,
                  color: AppColors.error,
                  icon: Icons.block_rounded,
                ),
            ],
          ),
          if (r.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              r.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: TsColors.textBody,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    if (r.hasBooking)
                      _Indicator(icon: Icons.calendar_month_rounded, label: l.tsIndBooking),
                    if (r.hasMessage)
                      _Indicator(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: l.tsIndMessage,
                      ),
                    if (r.hasEvidence)
                      _Indicator(icon: Icons.attach_file_rounded, label: l.tsIndEvidence),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l.tsReportedBy(r.reporterName.isEmpty ? '—' : r.reporterName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: TsColors.textFaint),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Indicator({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: TsColors.info),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: TsColors.info,
          ),
        ),
      ],
    );
  }
}