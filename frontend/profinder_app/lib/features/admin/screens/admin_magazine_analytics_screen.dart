// lib/features/admin/screens/admin_magazine_analytics_screen.dart
//
// Admin — Tips Magazine Analytics Dashboard.
// Shows total views, unique readers, per-article breakdown,
// category performance, and recent viewer logs.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../magazine/models/article_model.dart';
import '../../magazine/services/magazine_service.dart';
import '../../../core/theme/theme_context_ext.dart';

class AdminMagazineAnalyticsScreen extends StatefulWidget {
  const AdminMagazineAnalyticsScreen({super.key});

  @override
  State<AdminMagazineAnalyticsScreen> createState() =>
      _AdminMagazineAnalyticsScreenState();
}

class _AdminMagazineAnalyticsScreenState
    extends State<AdminMagazineAnalyticsScreen> {
  final _service = MagazineService();

  bool                      _loading = true;
  String?                   _error;
  MagazineAnalyticsSummary? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final data = await _service.adminGetAnalytics();
    if (!mounted) return;
    if (data == null) {
      setState(() { _loading = false; _error = 'Failed to load analytics.'; });
    } else {
      setState(() { _loading = false; _data = data; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.adminColor,
        elevation:       0,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Magazine Analytics',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
                color: AppColors.adminColor, strokeWidth: 2.5))
          : _error != null
              ? _buildError()
              : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    final d = _data!;
    return RefreshIndicator(
      color:     AppColors.adminColor,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [

          // ── Summary Cards ──────────────────────────────
          _buildSectionTitle('Overview'),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap:  true,
            physics:     const NeverScrollableScrollPhysics(),
            crossAxisCount:   2,
            crossAxisSpacing: 10,
            mainAxisSpacing:  10,
            childAspectRatio: 1.6,
            children: [
              _statCard('Total Views',    '${d.totalViews}',
                  Icons.visibility_rounded,        const Color(0xFF2563EB)),
              _statCard('Today',          '${d.viewsToday}',
                  Icons.today_rounded,             const Color(0xFF10B981)),
              _statCard('This Week',      '${d.viewsThisWeek}',
                  Icons.date_range_rounded,        const Color(0xFF8B5CF6)),
              _statCard('Unique Readers', '${d.uniqueReaders}',
                  Icons.people_alt_rounded,        const Color(0xFFF59E0B)),
            ],
          ),

          const SizedBox(height: 24),

          // ── Category Breakdown ─────────────────────────
          if (d.categoryBreakdown.isNotEmpty) ...[
            _buildSectionTitle('Views by Category'),
            const SizedBox(height: 10),
            ...d.categoryBreakdown.map((c) => _categoryBar(c, d.totalViews)),
            const SizedBox(height: 24),
          ],

          // ── Per Article ────────────────────────────────
          _buildSectionTitle('Articles Performance'),
          const SizedBox(height: 10),
          ...d.articles.map((a) => _articleAnalyticsCard(a)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize:   14,
            fontWeight: FontWeight.w800,
            color:      Color(0xFF111827),
            letterSpacing: 0.2));
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color:        color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize:   20,
                      fontWeight: FontWeight.w900,
                      color:      color)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryBar(CategoryBreakdown cat, int totalViews) {
    Color color;
    try { color = Color(int.parse(cat.categoryColor.replaceFirst('#', '0xFF'))); }
    catch (_) { color = context.colors.primary; }
    final pct = totalViews > 0 ? cat.totalViews / totalViews : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(cat.categoryName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: Color(0xFF111827))),
              Text('${cat.totalViews} views',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value:            pct.clamp(0.0, 1.0),
              backgroundColor:  color.withOpacity(0.10),
              valueColor:       AlwaysStoppedAnimation<Color>(color),
              minHeight:        6,
            ),
          ),
          const SizedBox(height: 4),
          Text('${(pct * 100).toStringAsFixed(1)}% of total',
              style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }

  Widget _articleAnalyticsCard(ArticleAnalytics a) {
    Color catColor;
    try { catColor = Color(int.parse(a.categoryColor.replaceFirst('#', '0xFF'))); }
    catch (_) { catColor = context.colors.primary; }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color:        catColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.article_outlined, color: catColor, size: 20),
          ),
          title: Text(a.title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: Color(0xFF111827)),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(children: [
              _miniStat(Icons.visibility_rounded, '${a.viewsCount}', const Color(0xFF2563EB)),
              const SizedBox(width: 10),
              _miniStat(Icons.people_alt_rounded, '${a.uniqueViewers} unique', const Color(0xFF10B981)),
            ]),
          ),
          // ── Recent viewers list ──────────────────────────
          children: [
            if (a.recentViews.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No views yet.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
              )
            else ...[
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),
              const Text('Recent Viewers',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: Color(0xFF374151))),
              const SizedBox(height: 8),
              ...a.recentViews.map((v) => _viewerRow(v)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String label, Color color) {
    return Row(children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    ]);
  }

  Widget _viewerRow(ViewLog v) {
    final isGuest = v.userName == 'Guest' || v.userName.isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color:  isGuest
                ? const Color(0xFFF1F5F9)
                : context.colors.primary.withOpacity(0.10),
            shape:  BoxShape.circle,
          ),
          child: Icon(
            isGuest ? Icons.person_outline_rounded : Icons.person_rounded,
            size:  14,
            color: isGuest ? const Color(0xFF9CA3AF) : context.colors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isGuest ? 'Guest User' : v.userName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: Color(0xFF111827)),
              ),
              if (!isGuest && v.userRole.isNotEmpty)
                Text(
                  v.userRole,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                ),
            ],
          ),
        ),
        Text(
          _formatDate(v.viewedAt),
          style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
        ),
      ]),
    );
  }

  Widget _buildError() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.error_outline_rounded, size: 52, color: AppColors.error),
      const SizedBox(height: 12),
      Text(_error!, style: const TextStyle(fontSize: 14, color: Color(0xFF374151),
          fontWeight: FontWeight.w600)),
      const SizedBox(height: 20),
      ElevatedButton.icon(onPressed: _load,
          icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text('Retry'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
    ],
  ));

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month]} ${dt.day}, ${dt.year}';
    } catch (_) { return ''; }
  }
}