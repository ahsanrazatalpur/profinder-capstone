// lib/features/admin/screens/admin_announcements_screen.dart
//
// Content Management → Announcements
// Persistent platform-wide in-app messages (maintenance/policy notices) —
// distinct from Notifications (push, fire-and-forget). Type auto-drives
// visual severity so admins don't hand-pick colors.
//
// Backend:
//   GET    /api/admin-panel/announcements/
//   POST   /api/admin-panel/announcements/       { title, message, type, audience, start_date, end_date }
//   PATCH  /api/admin-panel/announcements/<id>/   { is_active, ... }
//   DELETE /api/admin-panel/announcements/<id>/

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  List<dynamic> _announcements = [];

  // Neutral surface tokens used across this screen — kept local (rather than
  // pulling in a theme extension) since the original file didn't depend on
  // one; this keeps the visual language self-contained and unchanged for
  // any screen that doesn't already use the shared theme context.
  static const _bgColor = Color(0xFFF5F7FA);
  static const _cardColor = Colors.white;
  static const _borderColor = Color(0xFFE5E7EB);
  static const _textMuted = Color(0xFF6B7280);
  static const _textFaint = Color(0xFF9CA3AF);

  // Responsive breakpoints for the card grid / dialog width.
  static const double _tabletBreakpoint  = 700;
  static const double _desktopBreakpoint = 1100;
  static const double _maxContentWidth   = 1000;

  static const _typeStyles = {
    'info':        (Color(0xFF3B82F6), Icons.info_outline_rounded),
    'warning':     (Color(0xFFF59E0B), Icons.warning_amber_rounded),
    'maintenance': (Color(0xFFEF4444), Icons.build_circle_outlined),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Fetches the full announcement list. Always replaces (not merges) local
  /// state, so this is the single source of truth after create/toggle/delete.
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await _api.get('/admin-panel/announcements/');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _announcements = r.data is List ? List<dynamic>.from(r.data) : [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load announcements'; });
    }
  }

  /// Flips is_active via PATCH, then reloads so every card reflects the
  /// authoritative server state (rather than optimistically mutating locally).
  Future<void> _toggleActive(dynamic a) async {
    try {
      await _api.patch('/admin-panel/announcements/${a['id']}/', {'is_active': !(a['is_active'] == true)});
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update.')));
    }
  }

  /// Confirms, then permanently removes an announcement.
  Future<void> _delete(dynamic a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Announcement?'),
        content: Text('Remove "${a['title']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.delete('/admin-panel/announcements/${a['id']}/');
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      floatingActionButton: _composeFab(),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                // FIX: AnimatedSwitcher's default layoutBuilder stacks the
                // old/new children with Alignment.center. Since this
                // AnimatedSwitcher fills the full Expanded height, that
                // centered Stack was vertically centering the whole list
                // (even though the list itself top-aligns internally) —
                // which is why the single announcement card appeared
                // floating in the middle of the screen instead of hugging
                // the header. Overriding layoutBuilder to top-align fixes it
                // without touching the loading/error/list children at all.
                layoutBuilder: (currentChild, previousChildren) => Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                ),
                child: _loading
                    ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator(color: AppColors.adminColor))
                    : _error != null
                        ? _errorState(key: const ValueKey('error'))
                        : RefreshIndicator(
                            key: const ValueKey('content'),
                            onRefresh: _load,
                            color: AppColors.adminColor,
                            // AlwaysScrollable so the pull-to-refresh gesture
                            // works even when the list is empty (which was the
                            // case that felt unresponsive before).
                            child: _announcements.isEmpty
                                ? ListView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    children: [_emptyState()],
                                  )
                                : _announcementList(),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── FAB — collapses to icon-only on very narrow screens to avoid
  // crowding the bottom bar, expands to a labelled button otherwise. ──────
  Widget _composeFab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = MediaQuery.sizeOf(context).width < 360;
        if (isNarrow) {
          return Tooltip(
            message: 'New Announcement',
            child: FloatingActionButton(
              heroTag: 'admin_announcements_fab',
              backgroundColor: AppColors.adminColor,
              onPressed: _composeDialog,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
          );
        }
        return FloatingActionButton.extended(
          // Same tag as the narrow-screen branch above — they're mutually
          // exclusive (only one renders per build), so sharing a tag here
          // is safe and keeps this from colliding with any other admin
          // tab's FAB while all tabs sit mounted in the IndexedStack.
          heroTag: 'admin_announcements_fab',
          backgroundColor: AppColors.adminColor,
          onPressed: _composeDialog,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('New Announcement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        );
      },
    );
  }

  // ── Gradient header with live active-count summary ──────────────────────
  Widget _header() {
    final activeCount = _announcements.where((a) => a['is_active'] == true).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.adminColor, Color(0xFFB91C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: Color(0x33991B1B), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Announcements',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.2)),
                const SizedBox(height: 2),
                // Animated switcher avoids an abrupt jump when the count
                // changes after a toggle/create/delete round-trip.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    '$activeCount active',
                    key: ValueKey(activeCount),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.85)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Responsive announcement list — a single column on phones, a wrapping
  // multi-column layout on tablet/desktop. Natural (non-fixed) card heights
  // are preserved via Wrap rather than a fixed-aspect-ratio grid, so long
  // messages never clip.
  //
  // Alignment note: the list is anchored to the TOP of the available space
  // (rather than being vertically centered). Previously the content could
  // sit in the middle of the viewport with large empty gaps above and
  // below, which looked broken for a short list. Anchoring to the top
  // matches the behaviour of the countries/cities lists and gives the
  // screen a normal "content flows from the header down" feel.
  Widget _announcementList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= _desktopBreakpoint ? 3 : (width >= _tabletBreakpoint ? 2 : 1);
        final contentWidth = width > _maxContentWidth ? _maxContentWidth : width;
        const spacing = 12.0;
        final cardWidth = columns == 1 ? contentWidth : (contentWidth - spacing * (columns - 1)) / columns;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          child: Align(
            // Top-align the card grid so it hugs the header instead of
            // floating in the vertical middle of the viewport.
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: _maxContentWidth),
              child: Wrap(
                alignment: WrapAlignment.start,
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(_announcements.length, (i) {
                  return SizedBox(
                    width: cardWidth,
                    child: _FadeInUp(index: i, child: _announcementCard(_announcements[i])),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _announcementCard(dynamic a) {
    final type = a['type']?.toString() ?? 'info';
    final (color, icon) = _typeStyles[type] ?? _typeStyles['info']!;
    final isActive = a['is_active'] == true;

    return _HoverLift(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isActive ? color.withOpacity(0.3) : _borderColor),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30, height: 30,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      a['title']?.toString() ?? '',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Compact switch with a smaller transform scale so it fits
                // comfortably next to the title without pushing the row tall.
                Transform.scale(
                  scale: 0.85,
                  child: Tooltip(
                    message: isActive ? 'Deactivate' : 'Activate',
                    child: Switch(
                      value: isActive,
                      activeColor: color,
                      onChanged: (_) => _toggleActive(a),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              a['message']?.toString() ?? '',
              style: const TextStyle(fontSize: 12, color: Color(0xFF374151), height: 1.45),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    a['type_display']?.toString() ?? type,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.3),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    a['audience_display']?.toString() ?? '',
                    style: const TextStyle(fontSize: 10.5, color: _textFaint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Delete affordance — hover-only tint handled by IconButton's
                // own splash; sized to the 36px minimum touch target.
                Tooltip(
                  message: 'Delete',
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                    onPressed: () => _delete(a),
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(minimumSize: const Size(36, 36)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the compose sheet for a new announcement. Local dialog state
  /// (title/message controllers, selected type & audience) lives entirely
  /// inside this method's closure via StatefulBuilder — nothing here is
  /// persisted until "Publish" fires the POST request.
  void _composeDialog() {
    final titleCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String type = 'info';
    String audience = 'all';
    // FIX: previously, pressing Publish with an empty title/message just
    // did `return;` — no error, no feedback, dialog stayed open looking
    // unresponsive. This made it seem like only one announcement could ever
    // be created, when really the second attempt was just silently
    // rejected. Now we surface why via this inline error string.
    String? formError;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final dialogWidth = MediaQuery.sizeOf(dialogContext).width;
          final maxWidth = dialogWidth >= _tabletBreakpoint ? 480.0 : dialogWidth * 0.92;

          return Dialog(
            // Force a white surface — this dialog's text/fill colors are
            // hardcoded for a light background, and M3's default surface
            // is near-black in dark mode, which made the form unreadable.
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.adminColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.campaign_rounded, color: AppColors.adminColor, size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text('New Announcement',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: titleCtrl,
                        decoration: _dialogFieldDecoration('Title'),
                        onChanged: (_) {
                          if (formError != null) setDialogState(() => formError = null);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: messageCtrl,
                        maxLines: 3,
                        decoration: _dialogFieldDecoration('Message'),
                        onChanged: (_) {
                          if (formError != null) setDialogState(() => formError = null);
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _textMuted)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['info', 'warning', 'maintenance'].map((t) {
                          final isActive = type == t;
                          final (color, chipIcon) = _typeStyles[t]!;
                          return _SelectableChip(
                            label: t,
                            icon: chipIcon,
                            color: color,
                            selected: isActive,
                            onTap: () => setDialogState(() => type = t),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text('Audience', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _textMuted)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [('all', 'All'), ('customers', 'Customers'), ('professionals', 'Professionals')].map((e) {
                          final isActive = audience == e.$1;
                          return _SelectableChip(
                            label: e.$2,
                            color: AppColors.adminColor,
                            selected: isActive,
                            onTap: () => setDialogState(() => audience = e.$1),
                          );
                        }).toList(),
                      ),
                      if (formError != null) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 15, color: AppColors.error),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                formError!,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 22),
                      // FIX: this used to be a Row(mainAxisAlignment: end, ...)
                      // wrapping the Cancel/Publish buttons. Inside this
                      // dialog's layout chain (Dialog -> ConstrainedBox ->
                      // Padding -> SingleChildScrollView -> Column), a plain
                      // Row can end up laid out with unbounded width, which
                      // makes ElevatedButton's internal sizing throw
                      // "BoxConstraints forces an infinite width" the moment
                      // it's tapped/focused (the buttons never even needed to
                      // rebuild — hover/focus alone can trigger the layout
                      // pass that crashes). This is the exact same failure
                      // mode we hit and fixed in the countries/cities admin
                      // dialogs. OverflowBar lays its children out with
                      // bounded, intrinsic widths (right-aligned, spaced),
                      // and falls back to a vertical stack if they don't fit
                      // on narrow screens — so it never hits the unbounded-
                      // width path that Row does here.
                      OverflowBar(
                        alignment: MainAxisAlignment.end,
                        spacing: 8,
                        overflowSpacing: 8,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: _textMuted),
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.adminColor,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              // FIX: was `if (...) return;` with no feedback
                              // at all — the dialog just sat there looking
                              // broken. Now we tell the user exactly what's
                              // missing and keep the dialog open so they can
                              // fix it, instead of silently doing nothing.
                              final missingTitle = titleCtrl.text.trim().isEmpty;
                              final missingMessage = messageCtrl.text.trim().isEmpty;
                              if (missingTitle || missingMessage) {
                                setDialogState(() {
                                  formError = missingTitle && missingMessage
                                      ? 'Title and message are required.'
                                      : missingTitle
                                          ? 'Title is required.'
                                          : 'Message is required.';
                                });
                                return;
                              }
                              Navigator.pop(dialogContext);
                              try {
                                await _api.post('/admin-panel/announcements/', {
                                  'title': titleCtrl.text.trim(), 'message': messageCtrl.text.trim(),
                                  'type': type, 'audience': audience,
                                });
                                _load();
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create.')));
                              }
                            },
                            child: const Text('Publish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _dialogFieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: _bgColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.adminColor, width: 1.4),
        ),
      );

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle),
                child: Icon(Icons.campaign_outlined, size: 40, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 14),
              const Text(
                'No announcements yet',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap "New Announcement" to get started',
                style: TextStyle(fontSize: 12.5, color: _textFaint),
              ),
            ],
          ),
        ),
      );

  Widget _errorState({Key? key}) => Center(
        key: key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 14),
            const Text('Failed to load announcements',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            const SizedBox(height: 16),
            _HoverLift(
              child: ElevatedButton.icon(
                onPressed: _load,
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
            ),
          ],
        ),
      );
}

// ── Reusable pill-shaped selectable chip used for Type / Audience choices
// in the compose dialog. Uses Material + InkWell (rather than a bare
// GestureDetector) so taps get a proper ripple on mobile and a pointer
// cursor + hover tint on desktop/web. ──────────────────────────────────────
class _SelectableChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableChip({
    required this.label,
    this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withOpacity(0.12) : const Color(0xFFF5F7FA),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? color : Colors.transparent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: selected ? color : const Color(0xFF6B7280)),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Cosmetic-only: staggered fade + slide-up entrance for list items.
// Owns its own ticker; touches no business state. ───────────────────────
class _FadeInUp extends StatefulWidget {
  final Widget child;
  final int index;
  const _FadeInUp({required this.child, this.index = 0});

  @override
  State<_FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<_FadeInUp> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    // Cap the stagger so long lists don't leave later cards waiting too long.
    final delay = Duration(milliseconds: 30 * widget.index.clamp(0, 8));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

// ── Cosmetic-only: subtle hover-lift for desktop/web pointer input.
// No-op on touch devices since hover events never fire there. ───────────
class _HoverLift extends StatefulWidget {
  final Widget child;
  const _HoverLift({required this.child});

  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.015 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}