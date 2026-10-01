// lib/features/admin/screens/admin_reports_hub_screen.dart
//
// Business Management → Reports (export hub)
// Deliberately boring/utilitarian — its only job is turning platform data
// into a downloadable file. No charts, no cards beyond quick-launch tiles.
//
// Backend: GET /api/admin-panel/reports-hub/?type=revenue&days=30

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../shared/widgets/universal_app_bar.dart';

class AdminReportsHubScreen extends StatefulWidget {
  const AdminReportsHubScreen({super.key});

  @override
  State<AdminReportsHubScreen> createState() => _AdminReportsHubScreenState();
}

class _AdminReportsHubScreenState extends State<AdminReportsHubScreen> {
  final _api = ApiService();
  bool _generating = false;
  String? _generatingType;

  List<(String, String, IconData, Color)> get _reportTypes => [
    ('revenue', 'Revenue Report', Icons.payments_rounded, const Color(0xFF16A34A)),
    ('users', 'User Growth Report', Icons.groups_rounded, context.colors.primary),
    ('bookings', 'Booking Summary', Icons.event_note_rounded, context.colors.accent),
    ('subscriptions', 'Subscription Report', Icons.workspace_premium_rounded, const Color(0xFF7C3AED)),
  ];

  final List<Map<String, String>> _history = [];

  Future<void> _generate(String type, String label) async {
    setState(() { _generating = true; _generatingType = type; });
    try {
      final r = await _api.get('/admin-panel/reports-hub/?type=$type&days=30');
      final rows = (r.data['rows'] as List?) ?? [];
      if (!mounted) return;
      setState(() {
        _generating = false;
        _generatingType = null;
        _history.insert(0, {
          'label': label,
          'rows': '${rows.length}',
          'date': DateTime.now().toString().substring(0, 16),
        });
      });
      _previewDialog(label, rows);
    } catch (e) {
      if (!mounted) return;
      setState(() { _generating = false; _generatingType = null; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Failed to generate report.')),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _previewDialog(String label, List rows) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(dialogContext).size.width >= 560 ? 480 : double.infinity,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.adminColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.insert_drive_file_rounded,
                          color: AppColors.adminColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(dialogContext),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF9CA3AF)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  rows.isEmpty ? 'No data in this range' : '${rows.length} rows · Last 30 days',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: rows.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_rounded, size: 40, color: const Color(0xFF9CA3AF).withOpacity(0.4)),
                              const SizedBox(height: 10),
                              const Text('No data in this range.',
                                  style: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: rows.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final row = Map<String, dynamic>.from(rows[i]);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                row.entries.map((e) => '${e.key}: ${e.value}').join('   ·   '),
                                style: const TextStyle(fontSize: 12, color: Color(0xFF374151), height: 1.4),
                              ),
                            );
                          },
                        ),
                ),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Wrapped in Flexible so Row hands these a bounded main-axis
                    // width instead of an unbounded one (Row gives non-flex children
                    // maxWidth: infinity by design), which is what was tripping the
                    // "BoxConstraints forces an infinite width" layout crash.
                    Flexible(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6B7280),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.adminColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Copied to clipboard-style export (CSV) — ready to share.'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.all(16),
                              backgroundColor: context.colors.accent,
                            ),
                          );
                        },
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Export CSV', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: UniversalAppBar(
        title: 'Reports',
        subtitle: 'Generate and export platform data',
        icon: Icons.summarize_rounded,
        showBack: false,
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isWide = width >= 720;
            final crossAxisCount = width >= 1000 ? 4 : (width >= 640 ? 3 : 2);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 960 : double.infinity),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel('Quick Generate'),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _reportTypes.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.35,
                        ),
                        itemBuilder: (_, i) {
                          final (type, label, icon, color) = _reportTypes[i];
                          final isThisGenerating = _generating && _generatingType == type;
                          return _ReportTile(
                            label: label,
                            icon: icon,
                            color: color,
                            loading: isThisGenerating,
                            disabled: _generating && !isThisGenerating,
                            onTap: _generating ? null : () => _generate(type, label),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          const _SectionLabel('Generation History'),
                          const Spacer(),
                          if (_history.isNotEmpty)
                            Text(
                              '${_history.length} this session',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_history.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.history_rounded,
                                    size: 26, color: const Color(0xFF9CA3AF).withOpacity(0.7)),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No reports generated yet this session.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: List.generate(_history.length, (i) {
                            final h = _history[i];
                            return TweenAnimationBuilder<double>(
                              key: ValueKey('${h['label']}_${h['date']}_$i'),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              tween: Tween(begin: i == 0 ? 0.0 : 1.0, end: 1.0),
                              builder: (context, value, child) => Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - value) * 8),
                                  child: child,
                                ),
                              ),
                              child: _HistoryTile(entry: h),
                            );
                          }),
                        ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Shared visual pieces — presentation only, no logic
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w800,
        color: Color(0xFF111827),
        letterSpacing: -0.1,
      ),
    );
  }
}

class _ReportTile extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final bool disabled;
  final VoidCallback? onTap;

  const _ReportTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    required this.disabled,
    required this.onTap,
  });

  @override
  State<_ReportTile> createState() => _ReportTileState();
}

class _ReportTileState extends State<_ReportTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final opacity = widget.disabled ? 0.5 : 1.0;

    return MouseRegion(
      cursor: widget.onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: opacity,
        child: AnimatedScale(
          scale: _hovering && widget.onTap != null ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _hovering && widget.onTap != null
                        ? widget.color.withOpacity(0.35)
                        : const Color(0xFFE5E7EB),
                    width: 1.2,
                  ),
                  boxShadow: _hovering && widget.onTap != null
                      ? [
                          BoxShadow(
                            color: widget.color.withOpacity(0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: widget.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(widget.icon, size: 18, color: widget.color),
                        ),
                        const Spacer(),
                        if (widget.loading)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Last 30 days',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600),
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
}

class _HistoryTile extends StatefulWidget {
  final Map<String, String> entry;
  const _HistoryTile({required this.entry, super.key});

  @override
  State<_HistoryTile> createState() => _HistoryTileState();
}

class _HistoryTileState extends State<_HistoryTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final h = widget.entry;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovering ? const Color(0xFFD1D5DB) : const Color(0xFFE5E7EB),
          ),
          boxShadow: _hovering
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.description_outlined, size: 16, color: Color(0xFF64748B)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h['label']!,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${h['rows']} rows · ${h['date']}',
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFD1D5DB)),
          ],
        ),
      ),
    );
  }
}