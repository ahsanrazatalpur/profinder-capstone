// lib/features/notifications/screens/notification_screen.dart
//
// In-App Notifications Screen
// Features: list all notifications grouped by date, unread badge,
//           mark as read, mark all read, pull-to-refresh, responsive layout.
//
// Backend endpoints:
//   GET   /api/notifications/                    → all notifications
//   PATCH /api/notifications/<id>/read/          → mark single as read
//
// NOTE: Some backend-generated titles/messages may still contain emoji
// (e.g. "Service Completed! 🎉"). This screen strips emoji on display and
// relies on a proper type-based icon + accent color instead, so the UI
// stays consistent no matter what the backend sends.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/theme_context_ext.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _api = ApiService();

  bool          _loading       = true;
  String?       _error;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await _api.get('/notifications/');
      if (!mounted) return;
      final list = r.data is List ? List<dynamic>.from(r.data) : [];
      // Newest first
      list.sort((a, b) {
        final aDate = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(0);
        final bDate = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(0);
        return bDate.compareTo(aDate);
      });
      setState(() { _loading = false; _notifications = list; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load notifications'; });
    }
  }

  // ── Mark single as read ───────────────────────────────────
  Future<void> _markRead(dynamic notif) async {
    if (notif['is_read'] == true) return;
    try {
      await _api.patch('/notifications/${notif['id']}/read/', {});
      setState(() {
        final idx = _notifications.indexWhere((n) => n['id'] == notif['id']);
        if (idx != -1) _notifications[idx]['is_read'] = true;
      });
    } catch (_) {}
  }

  // ── Mark all as read ──────────────────────────────────────
  Future<void> _markAllRead() async {
    final unread = _notifications.where((n) => n['is_read'] != true).toList();
    if (unread.isEmpty) return;

    for (final n in unread) {
      try {
        await _api.patch('/notifications/${n['id']}/read/', {});
      } catch (_) {}
    }
    setState(() {
      for (final n in _notifications) n['is_read'] = true;
    });
    _showSnack('All notifications marked as read');
  }

  int get _unreadCount =>
      _notifications.where((n) => n['is_read'] != true).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: _loading
            ? _buildLoader()
            : _error != null
                ? _buildError()
                : _notifications.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
      ),
    );
  }

  // ── Responsive, date-grouped list ─────────────────────────
  Widget _buildList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width      = constraints.maxWidth;
        final isTablet    = width >= 700;
        final maxContentW = isTablet ? 640.0 : width;
        final hPad        = isTablet ? 0.0 : 16.0;

        final sections = _groupByDate(_notifications);

        return RefreshIndicator(
          onRefresh: _load,
          color: context.colors.primary,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentW),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
                itemCount: sections.length,
                itemBuilder: (_, i) => _buildSection(sections[i]),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(_NotifSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Text(
            section.label.toUpperCase(),
            style: TextStyle(
              fontSize:      11,
              fontWeight:    FontWeight.w700,
              letterSpacing: 0.6,
              color:         context.colors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color:        context.colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.divider, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (int i = 0; i < section.items.length; i++) ...[
                _buildTile(section.items[i]),
                if (i != section.items.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 68,
                    color: context.colors.divider,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Notification Row (flat, native-app style) ─────────────
  Widget _buildTile(dynamic notif) {
    final rawTitle   = notif['title']?.toString()   ?? '';
    final rawMessage = notif['message']?.toString() ?? '';
    final title      = _stripEmoji(rawTitle);
    final message    = _stripEmoji(rawMessage);
    final type       = notif['type']?.toString()    ?? 'general';
    final isRead     = notif['is_read'] == true;
    final createdAt  = notif['created_at']?.toString() ?? '';

    final color = _typeColor(type);
    final icon  = _typeIcon(type);

    return Material(
      color: isRead
          ? Colors.transparent
          : context.colors.primary.withOpacity(0.05),
      child: InkWell(
        onTap: () => _markRead(notif),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon avatar
              Container(
                width:  40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize:   14,
                        fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                        color:      context.colors.textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 13,
                        color:    context.colors.textSecondary,
                        height:   1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color:    context.colors.textDisabled,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Unread indicator
              if (!isRead)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Container(
                    width:  8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation:       0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          Text('Notifications',
              style: TextStyle(
                  fontSize:   17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color:      context.colors.textPrimary)),
          if (_unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              constraints: const BoxConstraints(minWidth: 20),
              decoration: BoxDecoration(
                color:        AppColors.error,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_unreadCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize:   11,
                    fontWeight: FontWeight.w700,
                    color:      Colors.white),
              ),
            ),
          ],
        ],
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            size: 20, color: context.colors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_unreadCount > 0)
          TextButton(
            onPressed: _markAllRead,
            child: Text('Mark all read',
                style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w600,
                    color:      context.colors.primary)),
          ),
        IconButton(
          icon: Icon(Icons.refresh_rounded,
              color: context.colors.textSecondary, size: 21),
          onPressed: _load,
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: context.colors.divider),
      ),
    );
  }

  // ── Date grouping ──────────────────────────────────────────
  List<_NotifSection> _groupByDate(List<dynamic> items) {
    final Map<String, List<dynamic>> buckets = {};
    final order = <String>[];

    for (final n in items) {
      final raw = n['created_at']?.toString() ?? '';
      final dt  = DateTime.tryParse(raw)?.toLocal();
      final label = dt == null ? 'Earlier' : _sectionLabel(dt);
      if (!buckets.containsKey(label)) {
        buckets[label] = [];
        order.add(label);
      }
      buckets[label]!.add(n);
    }

    return [
      for (final label in order) _NotifSection(label, buckets[label]!),
    ];
  }

  String _sectionLabel(DateTime dt) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that  = DateTime(dt.year, dt.month, dt.day);
    final diff  = today.difference(that).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7)  return 'This Week';
    if (today.year == dt.year && today.month == dt.month) return 'This Month';
    return '${_monthName(dt.month)} ${dt.year}';
  }

  String _monthName(int m) => const [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][m - 1];

  // ── Helpers ───────────────────────────────────────────────

  /// Strips emoji / pictograph characters coming from backend-generated
  /// copy so the UI shows a clean, official look. Type-based icon +
  /// accent color already communicate the notification kind visually.
  static final RegExp _emojiPattern = RegExp(
    r'[\u{1F1E6}-\u{1F1FF}\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{2190}-\u{21FF}\u{FE0F}\u{200D}\u{2000}-\u{206F}]',
    unicode: true,
  );

  String _stripEmoji(String input) {
    if (input.isEmpty) return input;
    final cleaned = input
        .replaceAll(_emojiPattern, '')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
    return cleaned.isEmpty ? input : cleaned;
  }

  Color _typeColor(String type) {
    return switch (type) {
      'review'       => const Color(0xFFF59E0B),
      'payment'      => const Color(0xFF10B981),
      'subscription' => const Color(0xFF8B5CF6),
      'booking'       => context.colors.primary,
      'report'       => const Color(0xFFEF4444), // warning/moderation red
      _              => context.colors.primary,
    };
  }

  IconData _typeIcon(String type) {
    return switch (type) {
      'review'       => Icons.star_rounded,
      'payment'      => Icons.payments_outlined,
      'subscription' => Icons.workspace_premium_rounded,
      'booking'      => Icons.event_available_rounded,
      'report'       => Icons.shield_outlined,
      _              => Icons.notifications_outlined,
    };
  }

  String _formatDate(String raw) {
    try {
      final dt   = DateTime.parse(raw).toLocal();
      final now  = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1)  return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24)   return '${diff.inHours}h ago';
      if (diff.inDays < 7)     return '${diff.inDays}d ago';

      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Widget _buildLoader() => Center(
        child: CircularProgressIndicator(
            color: context.colors.primary, strokeWidth: 2.5));

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.error),
            const SizedBox(height: 12),
            Text('Failed to load notifications',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon:  const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color:  context.colors.primaryLight,
                shape:  BoxShape.circle,
              ),
              child: Icon(Icons.notifications_none_rounded,
                  color: context.colors.primary, size: 38),
            ),
            const SizedBox(height: 16),
            Text('No Notifications Yet',
                style: TextStyle(
                    fontSize:   16,
                    fontWeight: FontWeight.w700,
                    color:      context.colors.textPrimary)),
            const SizedBox(height: 8),
            Text('Booking updates aur alerts yahan dikhenge',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor:  context.colors.accent,
      behavior:         SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }
}

class _NotifSection {
  final String label;
  final List<dynamic> items;
  _NotifSection(this.label, this.items);
}