// lib/features/admin/screens/admin_analytics_screen.dart
//
// Enterprise-grade, mobile-first Analytics dashboard — Revenue, User Growth,
// Bookings, Country/City/Category breakdowns, AI Analytics, Booking Health,
// Platform Statistics.
//
// Design language: Stripe Dashboard × Airbnb Host Analytics × GA4 — soft
// cards, generous spacing, animated counters, gradient area charts, no
// external chart package (keeps pubspec untouched, same as before).
//
// Backend endpoint:
//   GET /api/admin-panel/analytics/?days=30   (days: 7 | 30 | 90)

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/theme_context_ext.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final _api = ApiService();

  bool    _loading   = true;
  bool    _refreshing = false;
  String? _error;
  int     _rangeDays = 30;
  Map<String, dynamic> _data = {};

  static const _ranges = [7, 30, 90];

  final _revenueFmt = NumberFormat.compact();
  final _plainFmt   = NumberFormat.compact();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = _data.isEmpty; _refreshing = _data.isNotEmpty; _error = null; });
    try {
      final r = await _api.get('/admin-panel/analytics/?days=$_rangeDays');
      if (!mounted) return;
      setState(() {
        _loading    = false;
        _refreshing = false;
        _data       = r.data is Map ? Map<String, dynamic>.from(r.data) : {};
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _refreshing = false; _error = 'Failed to load analytics'; });
    }
  }

  // ── Shared helpers ──────────────────────────────────────────────────────

  List<double> _seriesFrom(String key, String field) =>
      (_data[key] as List? ?? [])
          .map((e) => ((e[field] as num?) ?? 0).toDouble())
          .toList();

  /// Compares the average of the first half of a series to the second half,
  /// giving an honest "vs earlier in this range" trend — no fake numbers.
  double? _trendPercent(List<double> series) {
    if (series.length < 4) return null;
    final mid = series.length ~/ 2;
    final firstHalf  = series.sublist(0, mid);
    final secondHalf = series.sublist(mid);
    final firstAvg  = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
    if (firstAvg == 0) return secondAvg == 0 ? 0 : 100;
    return ((secondAvg - firstAvg) / firstAvg) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final bg = context.colors.background;
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: _loading
            ? _buildSkeleton()
            : _error != null
                ? _buildError()
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.adminColor,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 16),
                          _rangeSelector(),
                          const SizedBox(height: 24),
                          _kpiGrid(),
                          const SizedBox(height: 24),
                          _sectionTitle('Revenue'),
                          const SizedBox(height: 12),
                          _revenueHeroCard(),
                          const SizedBox(height: 24),
                          _sectionTitle('User Growth'),
                          const SizedBox(height: 12),
                          _userGrowthCard(),
                          const SizedBox(height: 24),
                          _sectionTitle('Booking Trend'),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _dailyBookingsCard()),
                              const SizedBox(width: 16),
                              Expanded(child: _monthlyBookingsCard()),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _sectionTitle('Booking Health'),
                          const SizedBox(height: 12),
                          _bookingHealthCard(),
                          const SizedBox(height: 24),
                          _sectionTitle('Breakdown'),
                          const SizedBox(height: 12),
                          _rankedCard(
                            title: 'Countries',
                            icon: Icons.public_rounded,
                            color: AppColors.info,
                            items: (_data['countries_distribution'] as List? ?? [])
                                .map((c) => _RankItem(
                                      label: c['country']?.toString() ?? 'Unknown',
                                      count: (c['count'] as num?)?.toInt() ?? 0,
                                      suffix: '${c['percentage']}%',
                                      avatar: _flagAvatar(c['country']?.toString() ?? ''),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 14),
                          _rankedCard(
                            title: 'Top Cities',
                            icon: Icons.location_city_rounded,
                            color: const Color(0xFF7C3AED),
                            items: (_data['top_cities'] as List? ?? [])
                                .map((c) => _RankItem(
                                      label: c['city']?.toString() ?? 'Unknown',
                                      count: (c['count'] as num?)?.toInt() ?? 0,
                                      avatar: _iconAvatar(Icons.location_on_rounded, const Color(0xFF7C3AED)),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 14),
                          _rankedCard(
                            title: 'Top Categories',
                            icon: Icons.category_rounded,
                            color: context.colors.accent,
                            items: (_data['top_categories'] as List? ?? [])
                                .map((c) => _RankItem(
                                      label: c['category']?.toString() ?? 'Uncategorized',
                                      count: (c['count'] as num?)?.toInt() ?? 0,
                                      avatar: _iconAvatar(Icons.category_rounded, context.colors.accent),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                          _sectionTitle('AI Analytics'),
                          const SizedBox(height: 12),
                          _aiAnalyticsCard(),
                          const SizedBox(height: 24),
                          _sectionTitle('Platform Statistics'),
                          const SizedBox(height: 12),
                          _platformStatsCard(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.adminColor, Color(0xFFB91C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.adminColor.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.insights_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Analytics',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
                SizedBox(height: 2),
                Text('Real-time business insights',
                    style: TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w500, color: Colors.white70)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _refreshing ? null : _load,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _refreshing
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Range selector (large tap targets, animated pill) ──────────────────
  Widget _rangeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.divider),
      ),
      child: Row(
        children: _ranges.map((d) {
          final isActive = _rangeDays == d;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_rangeDays == d) return;
                setState(() => _rangeDays = d);
                _load();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.adminColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: isActive
                      ? [BoxShadow(color: AppColors.adminColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))]
                      : null,
                ),
                child: Text('${d}D',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : context.colors.textSecondary)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.colors.textPrimary, letterSpacing: -0.2));

  Widget _cardShell({required Widget child, EdgeInsets? padding}) => Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.colors.divider),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 14, offset: const Offset(0, 4)),
          ],
        ),
        child: child,
      );

  // ── KPI Grid ─────────────────────────────────────────────────────────
  Widget _kpiGrid() {
    final revenueSeries = _seriesFrom('revenue_chart', 'amount');
    final totalRevenue  = revenueSeries.fold<double>(0, (a, b) => a + b);
    final bookingSeries = _seriesFrom('daily_bookings', 'count');
    final totalBookingsRange = bookingSeries.fold<double>(0, (a, b) => a + b);

    final ai = (_data['ai_analytics'] as Map?) ?? {};
    final searchSeries = ((ai['searches_trend'] as List?) ?? [])
        .map((e) => ((e['count'] as num?) ?? 0).toDouble())
        .toList();

    final stats = (_data['platform_statistics'] as Map?) ?? {};
    final completed = ((stats['completed_bookings'] as num?) ?? 0);
    final cancelled = ((stats['cancelled_bookings'] as num?) ?? 0);
    final activeSubs = ((stats['active_subscriptions'] as num?) ?? 0);

    final tiles = <Widget>[
      _kpiCard(
        label: 'Total Revenue',
        rawValue: totalRevenue,
        formatter: (v) => 'Rs ${_revenueFmt.format(v)}',
        icon: Icons.payments_rounded,
        color: const Color(0xFF16A34A),
        trendPercent: _trendPercent(revenueSeries),
        sparkline: revenueSeries,
      ),
      _kpiCard(
        label: 'Bookings ($_rangeDaysD)',
        rawValue: totalBookingsRange,
        formatter: (v) => _plainFmt.format(v),
        icon: Icons.event_note_rounded,
        color: const Color(0xFF2563EB),
        trendPercent: _trendPercent(bookingSeries),
        sparkline: bookingSeries,
      ),
      _kpiCard(
        label: 'Completed',
        rawValue: completed,
        formatter: (v) => _plainFmt.format(v),
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF16A34A),
      ),
      _kpiCard(
        label: 'Cancelled',
        rawValue: cancelled,
        formatter: (v) => _plainFmt.format(v),
        icon: Icons.cancel_rounded,
        color: const Color(0xFFDC2626),
      ),
      _kpiCard(
        label: 'AI Searches',
        rawValue: (ai['total_searches'] as num?) ?? 0,
        formatter: (v) => _plainFmt.format(v),
        icon: Icons.travel_explore_rounded,
        color: const Color(0xFFF59E0B),
        trendPercent: _trendPercent(searchSeries),
        sparkline: searchSeries,
      ),
      _kpiCard(
        label: 'Active Subs',
        rawValue: activeSubs,
        formatter: (v) => _plainFmt.format(v),
        icon: Icons.workspace_premium_rounded,
        color: const Color(0xFF7C3AED),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.22,
      children: tiles,
    );
  }

  String get _rangeDaysD => '${_rangeDays}d';

  Widget _kpiCard({
    required String label,
    required num rawValue,
    required String Function(double) formatter,
    required IconData icon,
    required Color color,
    double? trendPercent,
    List<double>? sparkline,
  }) {
    final hasTrend = trendPercent != null && trendPercent.isFinite;
    final trendUp  = (trendPercent ?? 0) >= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.divider),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (sparkline != null && sparkline.where((v) => v != 0).length >= 2)
            Positioned(
              left: -4, right: -4, bottom: -6, height: 30,
              child: Opacity(
                opacity: 0.5,
                child: CustomPaint(
                  painter: _LineChartPainter(series: [sparkline], colors: [color], filled: true),
                ),
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                  if (hasTrend) _trendPill(trendPercent, trendUp),
                ],
              ),
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: rawValue.toDouble()),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, val, _) => Text(
                  formatter(val),
                  style: TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w800, color: context.colors.textPrimary, letterSpacing: -0.3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: context.colors.textSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trendPill(double pct, bool up) {
    final color = up ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(up ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 12, color: color),
          const SizedBox(width: 2),
          Text('${pct.abs().toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  // ── Revenue hero card ────────────────────────────────────────────────
  Widget _revenueHeroCard() {
    final rows   = (_data['revenue_chart'] as List? ?? []);
    final values = _seriesFrom('revenue_chart', 'amount');
    final total  = values.fold<double>(0, (a, b) => a + b);
    final labels = _dateLabelsFrom(rows, 'period');

    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rs ${NumberFormat('#,##0').format(total)}',
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF16A34A), letterSpacing: -0.5)),
                  Text('last $_rangeDays days',
                      style: TextStyle(fontSize: 12, color: context.colors.textSecondary, fontWeight: FontWeight.w500)),
                ],
              ),
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.payments_rounded, color: Color(0xFF16A34A), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            width: double.infinity,
            child: values.isEmpty || values.every((v) => v == 0)
                ? _noData(height: 130)
                : CustomPaint(
                    painter: _LineChartPainter(
                      series: [values],
                      colors: const [Color(0xFF16A34A)],
                      filled: true,
                      showGrid: true,
                      showLastLabel: true,
                      lastLabel: 'Rs ${_revenueFmt.format(values.last)}',
                    ),
                  ),
          ),
          if (labels.length >= 2) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(labels.first, style: _axisLabelStyle()),
                if (labels.length > 2) Text(labels[labels.length ~/ 2], style: _axisLabelStyle()),
                Text(labels.last, style: _axisLabelStyle()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  TextStyle _axisLabelStyle() => TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.colors.textSecondary.withOpacity(0.7));

  List<String> _dateLabelsFrom(List rows, String field) {
    final out = <String>[];
    for (final r in rows) {
      final raw = r[field]?.toString();
      if (raw == null) continue;
      try {
        final d = DateTime.parse(raw.length == 7 ? '$raw-01' : raw);
        out.add(raw.length == 7 ? DateFormat('MMM yy').format(d) : DateFormat('MMM d').format(d));
      } catch (_) {
        out.add(raw);
      }
    }
    return out;
  }

  // ── User Growth (dual-line) ───────────────────────────────────────────
  Widget _userGrowthCard() {
    final rows          = (_data['user_growth'] as List? ?? []);
    final customers     = _seriesFrom('user_growth', 'customers');
    final professionals = _seriesFrom('user_growth', 'professionals');
    final labels        = _dateLabelsFrom(rows, 'period');
    final empty = (customers.isEmpty && professionals.isEmpty) ||
        (customers.every((v) => v == 0) && professionals.every((v) => v == 0));

    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16, runSpacing: 6,
            children: [
              _legendDot('Customers', context.colors.primary),
              _legendDot('Professionals', const Color(0xFF7C3AED)),
            ],
          ),
          const SizedBox(height: 4),
          Text('last 12 months',
              style: TextStyle(fontSize: 11.5, color: context.colors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
            width: double.infinity,
            child: empty
                ? _noData(height: 110)
                : CustomPaint(
                    painter: _LineChartPainter(
                      series: [customers, professionals],
                      colors: [context.colors.primary, const Color(0xFF7C3AED)],
                      showGrid: true,
                    ),
                  ),
          ),
          if (labels.length >= 2) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(labels.first, style: _axisLabelStyle()),
                Text(labels.last, style: _axisLabelStyle()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _legendDot(String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12.5, color: context.colors.textSecondary, fontWeight: FontWeight.w600)),
        ],
      );

  // ── Daily Bookings (bar) ────────────────────────────────────────────
  Widget _dailyBookingsCard() {
    final values = _seriesFrom('daily_bookings', 'count');
    final todayCount = values.isNotEmpty ? values.last.toInt() : 0;
    return _cardShell(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$todayCount',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.colors.accent, letterSpacing: -0.3)),
          const SizedBox(height: 2),
          Text('Daily Bookings',
              style: TextStyle(fontSize: 11.5, color: context.colors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            width: double.infinity,
            child: values.isEmpty || values.every((v) => v == 0)
                ? _noData(height: 64)
                : CustomPaint(
                    painter: _BarChartPainter(
                        values: values, color: context.colors.accent, highlightLast: true),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Monthly Bookings (bar) ──────────────────────────────────────────
  Widget _monthlyBookingsCard() {
    final values = _seriesFrom('monthly_bookings', 'count');
    final total  = values.fold<double>(0, (a, b) => a + b).toInt();
    return _cardShell(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$total',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0EA5E9), letterSpacing: -0.3)),
          const SizedBox(height: 2),
          Text('Monthly (12mo)',
              style: TextStyle(fontSize: 11.5, color: context.colors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            width: double.infinity,
            child: values.isEmpty || values.every((v) => v == 0)
                ? _noData(height: 64)
                : CustomPaint(
                    painter: _BarChartPainter(values: values, color: const Color(0xFF0EA5E9)),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Booking Health (real donut — completed / cancelled / in-progress) ──
  Widget _bookingHealthCard() {
    final stats = (_data['platform_statistics'] as Map?) ?? {};
    final total     = ((stats['total_bookings_all_time'] as num?) ?? 0).toDouble();
    final completed = ((stats['completed_bookings'] as num?) ?? 0).toDouble();
    final cancelled = ((stats['cancelled_bookings'] as num?) ?? 0).toDouble();
    final other     = (total - completed - cancelled).clamp(0, double.infinity);
    final completedPct = total > 0 ? (completed / total * 100) : 0.0;

    return _cardShell(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 92, height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, _) => CustomPaint(
                    size: const Size(92, 92),
                    painter: _DonutPainter(
                      values: [completed * t, cancelled * t, other * t],
                      colors: const [Color(0xFF16A34A), Color(0xFFDC2626), Color(0xFFE5E7EB)],
                      trackColor: context.colors.divider,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${completedPct.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: context.colors.textPrimary)),
                    Text('Done', style: TextStyle(fontSize: 10, color: context.colors.textSecondary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _legendRow('Completed', completed.toInt(), const Color(0xFF16A34A)),
                const SizedBox(height: 8),
                _legendRow('Cancelled', cancelled.toInt(), const Color(0xFFDC2626)),
                const SizedBox(height: 8),
                _legendRow('In progress', other.toInt(), const Color(0xFF9CA3AF)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendRow(String label, int value, Color color) => Row(
        children: [
          Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 12.5, color: context.colors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          Text('$value', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ],
      );

  // ── Ranked breakdown card (Countries / Cities / Categories) ────────────
  Widget _rankedCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<_RankItem> items,
  }) {
    final maxCount = items.isEmpty
        ? 1
        : items.map((e) => e.count).reduce((a, b) => a > b ? a : b).clamp(1, 1 << 30);

    const medalColors = [Color(0xFFF59E0B), Color(0xFF9CA3AF), Color(0xFFB45309)];

    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 7),
              Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: context.colors.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            _noData(height: 44)
          else
            ...items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final ratio = item.count / maxCount;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (i < 3)
                      Container(
                        width: 20, height: 20,
                        margin: const EdgeInsets.only(top: 1, right: 8),
                        decoration: BoxDecoration(color: medalColors[i], shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text('${i + 1}',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
                      )
                    else
                      const SizedBox(width: 28),
                    item.avatar,
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(item.label,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              Text(item.suffix != null ? '${item.count} · ${item.suffix}' : '${item.count}',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: ratio.toDouble().clamp(0, 1)),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (context, t, _) => ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: LinearProgressIndicator(
                                value: t,
                                minHeight: 7,
                                backgroundColor: context.colors.divider,
                                valueColor: AlwaysStoppedAnimation(color),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _iconAvatar(IconData icon, Color color) => Container(
        width: 26, height: 26,
        decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 13, color: color),
      );

  static const Map<String, String> _flagMap = {
    'Pakistan': '🇵🇰', 'India': '🇮🇳', 'United States': '🇺🇸', 'USA': '🇺🇸',
    'United Kingdom': '🇬🇧', 'UK': '🇬🇧', 'United Arab Emirates': '🇦🇪', 'UAE': '🇦🇪',
    'Saudi Arabia': '🇸🇦', 'Canada': '🇨🇦', 'Australia': '🇦🇺', 'Bangladesh': '🇧🇩',
    'China': '🇨🇳', 'Germany': '🇩🇪', 'France': '🇫🇷', 'Qatar': '🇶🇦', 'Kuwait': '🇰🇼',
    'Oman': '🇴🇲', 'Bahrain': '🇧🇭', 'Turkey': '🇹🇷', 'Malaysia': '🇲🇾', 'Indonesia': '🇮🇩',
    'Nepal': '🇳🇵', 'Sri Lanka': '🇱🇰', 'Afghanistan': '🇦🇫', 'Iran': '🇮🇷', 'Egypt': '🇪🇬',
    'South Africa': '🇿🇦', 'Singapore': '🇸🇬', 'Italy': '🇮🇹', 'Spain': '🇪🇸',
    'Netherlands': '🇳🇱', 'Japan': '🇯🇵', 'South Korea': '🇰🇷', 'Russia': '🇷🇺',
    'Brazil': '🇧🇷', 'Mexico': '🇲🇽', 'Philippines': '🇵🇭', 'Thailand': '🇹🇭',
    'Vietnam': '🇻🇳', 'Nigeria': '🇳🇬', 'Kenya': '🇰🇪', 'Ireland': '🇮🇪',
    'Switzerland': '🇨🇭', 'Sweden': '🇸🇪', 'Norway': '🇳🇴', 'New Zealand': '🇳🇿',
  };

  Widget _flagAvatar(String country) {
    final flag = _flagMap[country];
    if (flag != null) {
      return Container(
        width: 26, height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.info.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(flag, style: const TextStyle(fontSize: 13)),
      );
    }
    final initials = country.isEmpty
        ? '?'
        : country.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0].toUpperCase()).join();
    return Container(
      width: 26, height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.info.withOpacity(0.13), borderRadius: BorderRadius.circular(8)),
      child: Text(initials, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.info)),
    );
  }

  // ── AI Analytics ─────────────────────────────────────────────────────
  Widget _aiAnalyticsCard() {
    final ai = (_data['ai_analytics'] as Map?) ?? {};
    final trendValues = ((ai['searches_trend'] as List?) ?? [])
        .map((e) => ((e['count'] as num?) ?? 0).toDouble())
        .toList();
    final queries = (ai['top_queries'] as List?) ?? [];

    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _miniStat('Total Searches', '${ai['total_searches'] ?? 0}', AppColors.info, Icons.travel_explore_rounded)),
              const SizedBox(width: 16),
              Expanded(child: _miniStat('Search → Booking', '${ai['conversion_rate'] ?? 0}%', AppColors.success, Icons.query_stats_rounded)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 64,
            width: double.infinity,
            child: trendValues.isEmpty || trendValues.every((v) => v == 0)
                ? _noData(height: 64)
                : CustomPaint(
                    painter: _LineChartPainter(series: [trendValues], colors: const [AppColors.info], filled: true),
                  ),
          ),
          if (queries.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Top Searches',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: context.colors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: queries.take(8).map((q) {
                final query = q['query']?.toString() ?? '';
                final count = q['count'] ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$query · $count',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.info)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(label,
                  style: TextStyle(fontSize: 11.5, color: context.colors.textSecondary, fontWeight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.3)),
      ],
    );
  }

  // ── Platform Statistics (stat grid) ─────────────────────────────────
  Widget _platformStatsCard() {
    final stats = (_data['platform_statistics'] as Map?) ?? {};
    final tiles = [
      ('Total Bookings', stats['total_bookings_all_time'], Icons.event_note_rounded, const Color(0xFF2563EB)),
      ('Completed', stats['completed_bookings'], Icons.check_circle_rounded, const Color(0xFF16A34A)),
      ('Cancelled', stats['cancelled_bookings'], Icons.cancel_rounded, const Color(0xFFDC2626)),
      ('Total Searches', stats['total_searches_all_time'], Icons.travel_explore_rounded, const Color(0xFFF59E0B)),
      ('Active Subs', stats['active_subscriptions'], Icons.workspace_premium_rounded, const Color(0xFF7C3AED)),
      ('Active Ads', stats['active_popup_ads'], Icons.campaign_rounded, const Color(0xFFDB2777)),
      ('Categories', stats['total_categories'], Icons.category_rounded, const Color(0xFF0EA5E9)),
      ('Portfolio Items', stats['total_portfolio_items'], Icons.photo_library_rounded, const Color(0xFF14B8A6)),
      ('Total Reviews', stats['total_reviews'], Icons.star_rounded, const Color(0xFFF59E0B)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 700 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tiles.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.9,
          ),
          itemBuilder: (_, i) {
            final (label, value, icon, color) = tiles[i];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 17, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: ((value as num?) ?? 0).toDouble()),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (context, val, _) => Text(_plainFmt.format(val),
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.colors.textPrimary)),
                        ),
                        Text(label,
                            style: TextStyle(fontSize: 10.5, color: context.colors.textSecondary, fontWeight: FontWeight.w600),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _noData({double height = 60}) => SizedBox(
        height: height,
        child: Center(
          child: Text('No data yet',
              style: TextStyle(fontSize: 12, color: context.colors.textSecondary.withOpacity(0.7), fontWeight: FontWeight.w600)),
        ),
      );

  // ── Loading skeleton ─────────────────────────────────────────────────
  Widget _buildSkeleton() {
    Widget block({double height = 90, double? width}) => Container(
          height: height,
          width: width ?? double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(18),
          ),
        );
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        children: [
          block(height: 100),
          block(height: 52),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.22,
            children: List.generate(6, (_) => block(height: 110)),
          ),
          const SizedBox(height: 10),
          block(height: 220),
          block(height: 180),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded, size: 32, color: AppColors.error),
            ),
            const SizedBox(height: 14),
            Text('Failed to load analytics',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
            const SizedBox(height: 6),
            Text('Check your connection and try again',
                style: TextStyle(fontSize: 12.5, color: context.colors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small data holder for ranked list rows ──────────────────────────────
class _RankItem {
  final String label;
  final int count;
  final String? suffix;
  final Widget avatar;
  _RankItem({required this.label, required this.count, this.suffix, required this.avatar});
}

// ── Lightweight line/area chart painter (no external package needed) ────
class _LineChartPainter extends CustomPainter {
  final List<List<double>> series; // one or more lines
  final List<Color> colors;
  final bool filled;
  final bool showGrid;
  final bool showLastLabel;
  final String? lastLabel;

  _LineChartPainter({
    required this.series,
    required this.colors,
    this.filled = false,
    this.showGrid = false,
    this.showLastLabel = false,
    this.lastLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final allValues = series.expand((s) => s).toList();
    if (allValues.isEmpty) return;
    final maxVal = allValues.reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal == 0 ? 1 : maxVal;
    final chartHeight = showLastLabel ? size.height - 18 : size.height;

    if (showGrid) {
      final gridPaint = Paint()
        ..color = const Color(0xFF9CA3AF).withOpacity(0.14)
        ..strokeWidth = 1;
      for (var i = 0; i <= 3; i++) {
        final y = chartHeight * i / 3;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    for (var s = 0; s < series.length; s++) {
      final values = series[s];
      if (values.length < 2) continue;
      final color = colors[s % colors.length];
      final dx = size.width / (values.length - 1);

      final linePath = Path();
      for (var i = 0; i < values.length; i++) {
        final x = dx * i;
        final y = chartHeight - (values[i] / safeMax) * chartHeight;
        if (i == 0) {
          linePath.moveTo(x, y);
        } else {
          linePath.lineTo(x, y);
        }
      }

      if (filled) {
        final fillPath = Path.from(linePath)
          ..lineTo(size.width, chartHeight)
          ..lineTo(0, chartHeight)
          ..close();
        final fillPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [color.withOpacity(0.24), color.withOpacity(0.0)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));
        canvas.drawPath(fillPath, fillPaint);
      }

      final linePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(linePath, linePaint);

      // Last-point marker — draws attention to the most recent value.
      final lastX = dx * (values.length - 1);
      final lastY = chartHeight - (values.last / safeMax) * chartHeight;
      canvas.drawCircle(Offset(lastX, lastY), 3.6, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(lastX, lastY), 3.6, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2);
      canvas.drawCircle(Offset(lastX, lastY), 2, Paint()..color = color);

      if (showLastLabel && s == 0 && lastLabel != null) {
        final tp = TextPainter(
          text: TextSpan(text: lastLabel, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color)),
          textDirection: TextDirection.ltr,
        )..layout();
        final labelX = (lastX - tp.width).clamp(0, size.width - tp.width);
        tp.paint(canvas, Offset(labelX.toDouble(), size.height - 14));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.series != series;
}

// ── Lightweight bar chart painter ───────────────────────────────────────
class _BarChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final bool highlightLast;

  _BarChartPainter({required this.values, required this.color, this.highlightLast = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal == 0 ? 1 : maxVal;

    final gap = 4.0;
    final barWidth = (size.width - gap * (values.length - 1)) / values.length;

    for (var i = 0; i < values.length; i++) {
      final barHeight = math.max((values[i] / safeMax) * size.height, values[i] > 0 ? 2.0 : 0.0);
      final x = i * (barWidth + gap);
      final rect = Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight);
      final isLast = highlightLast && i == values.length - 1;
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: isLast
              ? [color, color.withOpacity(0.75)]
              : [color.withOpacity(0.32), color.withOpacity(0.32)],
        ).createShader(rect);
      canvas.drawRRect(
        RRect.fromRectAndCorners(rect, topLeft: const Radius.circular(4), topRight: const Radius.circular(4)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) => oldDelegate.values != values;
}

// ── Donut/ring chart painter (real segmented data, e.g. booking status) ──
class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final Color trackColor;
  final double strokeWidth;

  _DonutPainter({
    required this.values,
    required this.colors,
    required this.trackColor,
    this.strokeWidth = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width < size.height ? size.width : size.height) / 2 - strokeWidth / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (total <= 0) return;

    double startAngle = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;
      final sweep = (values[i] / total) * 2 * math.pi;
      final gap = values.length > 1 ? 0.05 : 0.0;
      final drawSweep = math.max(sweep - gap, 0.02);
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, drawSweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.trackColor != trackColor;
}