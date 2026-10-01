// lib/features/admin/screens/admin_complaints_screen.dart
//
// Business Management → Complaints
// Service/booking-dispute workflow: Open → In Progress → Resolved/Rejected.
// Distinct from Reported Users (Trust & Safety, user-conduct reports).
//
// Backend:
//   GET   /api/admin-panel/complaints/?status=open&category=no_show
//   PATCH /api/admin-panel/complaints/<id>/
//     { assign_to_me: true } or { status, resolution_note }

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../shared/widgets/universal_app_bar.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  List<dynamic> _all = [];
  String _statusFilter = 'open';

  static const _statuses = [
    ('open', 'Open', Color(0xFFF59E0B)),
    ('in_progress', 'In Progress', Color(0xFF3B82F6)),
    ('resolved', 'Resolved', Color(0xFF16A34A)),
    ('rejected', 'Rejected', Color(0xFF64748B)),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await _api.get('/admin-panel/complaints/?status=$_statusFilter');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _all = r.data is List ? List<dynamic>.from(r.data) : [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load complaints'; });
    }
  }

  Future<void> _assignToMe(dynamic c) async {
    try {
      await _api.patch('/admin-panel/complaints/${c['id']}/', {'assign_to_me': true});
      _load();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to assign.');
    }
  }

  void _resolveDialog(dynamic complaint, String status) {
    final noteCtrl = TextEditingController();
    final isResolve = status == 'resolved';
    showDialog(
      context: context,
      builder: (dialogContext) => _StyledDialog(
        icon: isResolve ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
        iconColor: isResolve ? context.colors.accent : AppColors.error,
        title: isResolve ? 'Resolve Complaint' : 'Reject Complaint',
        content: _StyledTextField(controller: noteCtrl, hintText: 'Resolution note', maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isResolve ? context.colors.accent : AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _api.patch('/admin-panel/complaints/${complaint['id']}/',
                    {'status': status, 'resolution_note': noteCtrl.text.trim()});
                _load();
              } catch (e) {
                if (!mounted) return;
                _showSnack('Failed to update.');
              }
            },
            child: Text(isResolve ? 'Resolve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ]),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: UniversalAppBar(
        title: 'Complaints',
        icon: Icons.report_problem_rounded,
        showBack: false,
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            // Breakpoints: mobile single column, tablet two, desktop three+.
            final crossAxisCount = width >= 1100 ? 3 : (width >= 700 ? 2 : 1);

            return Column(
              children: [
                _FilterBar(
                  statuses: _statuses,
                  activeKey: _statusFilter,
                  onSelect: (key) {
                    setState(() => _statusFilter = key);
                    _load();
                  },
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: _loading
                        ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator(color: AppColors.adminColor))
                        : _error != null
                            ? _ErrorState(key: const ValueKey('error'), onRetry: _load)
                            : _all.isEmpty
                                ? _EmptyState(key: const ValueKey('empty'), statusFilter: _statusFilter)
                                : RefreshIndicator(
                                    key: const ValueKey('content'),
                                    onRefresh: _load,
                                    color: AppColors.adminColor,
                                    child: Center(
                                      child: ConstrainedBox(
                                        // Keeps content readable on very wide desktop windows
                                        // instead of stretching cards edge to edge.
                                        constraints: const BoxConstraints(maxWidth: 1400),
                                        child: crossAxisCount == 1
                                            ? ListView.builder(
                                                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                                                itemCount: _all.length,
                                                itemBuilder: (_, i) => _AnimatedListEntry(
                                                  index: i,
                                                  child: _ComplaintCard(
                                                    complaint: _all[i],
                                                    statuses: _statuses,
                                                    onAssign: _assignToMe,
                                                    onResolve: (c) => _resolveDialog(c, 'resolved'),
                                                    onReject: (c) => _resolveDialog(c, 'rejected'),
                                                  ),
                                                ),
                                              )
                                            : GridView.builder(
                                                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: crossAxisCount,
                                                  crossAxisSpacing: 14,
                                                  mainAxisSpacing: 14,
                                                  mainAxisExtent: 208,
                                                ),
                                                itemCount: _all.length,
                                                itemBuilder: (_, i) => _AnimatedListEntry(
                                                  index: i,
                                                  child: _ComplaintCard(
                                                    complaint: _all[i],
                                                    statuses: _statuses,
                                                    onAssign: _assignToMe,
                                                    onResolve: (c) => _resolveDialog(c, 'resolved'),
                                                    onReject: (c) => _resolveDialog(c, 'rejected'),
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Horizontal status filter chips. Selecting a chip drives `_statusFilter`
/// and re-triggers `_load()` in the parent — same behavior as before, just
/// with an animated selection transition for smoother feedback.
class _FilterBar extends StatelessWidget {
  final List<(String, String, Color)> statuses;
  final String activeKey;
  final ValueChanged<String> onSelect;
  const _FilterBar({required this.statuses, required this.activeKey, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: statuses.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final (key, label, color) = statuses[i];
            final isActive = activeKey == key;
            return _FilterChip(label: label, color: color, isActive: isActive, onTap: () => onSelect(key));
          },
        ),
      ),
    );
  }
}

class _FilterChip extends StatefulWidget {
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.color, required this.isActive, required this.onTap});

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: widget.isActive
                ? widget.color.withOpacity(0.12)
                : (_hovered ? const Color(0xFFEEF0F3) : const Color(0xFFF5F7FA)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.isActive ? widget.color : Colors.transparent),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
              color: widget.isActive ? widget.color : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single complaint record. Presentation only — action buttons forward
/// straight to the parent's existing API-backed handlers, gated by the
/// same `status == 'open' / 'in_progress'` checks as the original.
class _ComplaintCard extends StatefulWidget {
  final dynamic complaint;
  final List<(String, String, Color)> statuses;
  final ValueChanged<dynamic> onAssign;
  final ValueChanged<dynamic> onResolve;
  final ValueChanged<dynamic> onReject;

  const _ComplaintCard({
    required this.complaint,
    required this.statuses,
    required this.onAssign,
    required this.onResolve,
    required this.onReject,
  });

  @override
  State<_ComplaintCard> createState() => _ComplaintCardState();
}

class _ComplaintCardState extends State<_ComplaintCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.complaint;
    final status = c['status']?.toString() ?? 'open';
    final color = widget.statuses.firstWhere((e) => e.$1 == status, orElse: () => widget.statuses[0]).$3;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        transform: _hovered ? (Matrix4.identity()..translate(0.0, -2.0)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _hovered ? color.withOpacity(0.45) : const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: _hovered ? Colors.black.withOpacity(0.08) : Colors.black.withOpacity(0.03),
              blurRadius: _hovered ? 16 : 6,
              offset: Offset(0, _hovered ? 6 : 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    c['category_display']?.toString() ?? '',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.error),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    c['status_display']?.toString() ?? '',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              c['description']?.toString() ?? '',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF374151), height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.compare_arrows_rounded, size: 13, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${c['complainant_name']} vs ${c['against_name']}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (c['assigned_to_name'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 13, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Assigned to: ${c['assigned_to_name']}',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF3B82F6)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            if (status == 'open' || status == 'in_progress') ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (status == 'open')
                    Expanded(
                      child: _HoverOutlinedButton(
                        icon: Icons.person_add_alt_1_rounded,
                        label: 'Assign to Me',
                        color: AppColors.adminColor,
                        onPressed: () => widget.onAssign(c),
                      ),
                    ),
                  if (status == 'in_progress') ...[
                    Expanded(
                      child: _HoverOutlinedButton(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Resolve',
                        color: context.colors.accent,
                        onPressed: () => widget.onResolve(c),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _HoverOutlinedButton(
                        icon: Icons.cancel_outlined,
                        label: 'Reject',
                        color: AppColors.error,
                        onPressed: () => widget.onReject(c),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Outlined action button with a hover tint on desktop/web; falls back to
/// standard press feedback on touch devices.
class _HoverOutlinedButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  const _HoverOutlinedButton({required this.icon, required this.label, required this.color, required this.onPressed});

  @override
  State<_HoverOutlinedButton> createState() => _HoverOutlinedButtonState();
}

class _HoverOutlinedButtonState extends State<_HoverOutlinedButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: SizedBox(
        height: 38,
        child: OutlinedButton.icon(
          onPressed: widget.onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: widget.color,
            backgroundColor: _hovered ? widget.color.withOpacity(0.06) : Colors.transparent,
            side: BorderSide(color: widget.color.withOpacity(_hovered ? 0.6 : 0.35)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          icon: Icon(widget.icon, size: 14),
          label: Text(widget.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  const _StyledTextField({required this.controller, required this.hintText, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.adminColor, width: 1.4),
        ),
      ),
    );
  }
}

/// Shared dialog chrome (icon + title + rounded card) so Resolve/Reject
/// dialogs look consistent; the actions/content passed in are unchanged.
class _StyledDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget content;
  final List<Widget> actions;
  const _StyledDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 14),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
              const SizedBox(height: 14),
              content,
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String statusFilter;
  const _EmptyState({super.key, required this.statusFilter});

  @override
  Widget build(BuildContext context) {
    final isOpen = statusFilter == 'open';
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 90),
          child: Center(
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isOpen ? context.colors.accent.withOpacity(0.1) : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOpen ? Icons.celebration_rounded : Icons.check_circle_outline_rounded,
                  size: 44,
                  color: isOpen ? context.colors.accent : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isOpen ? 'No open complaints — all clear!' : 'No complaints in this category',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), shape: BoxShape.circle),
            child: const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.error),
          ),
          const SizedBox(height: 14),
          const Text('Failed to load complaints', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Staggered fade + slide-up entrance for list/grid items. Purely visual —
/// runs once per build using the item's index to offset its start delay,
/// so the list feels populated rather than static.
class _AnimatedListEntry extends StatelessWidget {
  final int index;
  final Widget child;
  const _AnimatedListEntry({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final delay = (index.clamp(0, 12)) * 35;
    return TweenAnimationBuilder<double>(
      key: ValueKey('entry_$index'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 320 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, (1 - value) * 14), child: child),
      ),
      child: child,
    );
  }
}