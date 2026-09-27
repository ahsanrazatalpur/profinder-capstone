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
import '../../../core/theme/theme_context_ext.dart';
import '../../../services/api_service.dart';
import '../../../l10n/generated/app_localizations.dart';

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
      setState(() { _loading = false; _error = AppLocalizations.of(context)!.notificationsLoadError; });
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
    _showSnack(AppLocalizations.of(context)!.notificationsMarkAllReadSuccess);
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
          color: AppColors.customerColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Text(
            section.label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: isDark
                  ? Colors.white.withOpacity(0.5)
                  : context.colors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : context.colors.divider,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
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
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : context.colors.divider,
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
    final isDark     = Theme.of(context).brightness == Brightness.dark;

    final color = _typeColor(type);
    final icon  = _typeIcon(type);

    return Material(
      color: isRead
          ? Colors.transparent
          : AppColors.customerColor.withOpacity(0.05),
      child: InkWell(
        onTap: () => _markRead(notif),
        splashColor: AppColors.customerColor.withOpacity(0.1),
        highlightColor: AppColors.customerColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 1,
                  ),
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
                        fontSize: 14,
                        fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                        color: context.colors.textPrimary,
                        height: 1.3,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.colors.textSecondary,
                        height: 1.4,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: context.colors.textSecondary.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
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
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.customerColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.customerColor.withOpacity(0.3),
                          blurRadius: 4,
                        ),
                      ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor: context.colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          Text(
            AppLocalizations.of(context)!.notificationsTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: context.colors.textPrimary,
            ),
          ),
          if (_unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              constraints: const BoxConstraints(minWidth: 20),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                '$_unreadCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: context.colors.textPrimary,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_unreadCount > 0)
          TextButton(
            onPressed: _markAllRead,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.customerColor,
            ),
            child: Text(
              AppLocalizations.of(context)!.notificationsMarkAllReadCta,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        IconButton(
          icon: Icon(
            Icons.refresh_rounded,
            color: context.colors.textSecondary,
            size: 21,
          ),
          onPressed: _load,
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : context.colors.divider,
        ),
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

    if (diff == 0) return AppLocalizations.of(context)!.notificationsSectionToday;
    if (diff == 1) return AppLocalizations.of(context)!.notificationsSectionYesterday;
    if (diff < 7)  return AppLocalizations.of(context)!.notificationsSectionThisWeek;
    if (today.year == dt.year && today.month == dt.month) return AppLocalizations.of(context)!.notificationsSectionThisMonth;
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
      'booking'      => AppColors.customerColor,
      'report'       => const Color(0xFFEF4444),
      _              => AppColors.customerColor,
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

      if (diff.inMinutes < 1)  return AppLocalizations.of(context)!.notificationsJustNow;
      if (diff.inMinutes < 60) return AppLocalizations.of(context)!.notificationsMinutesAgo(diff.inMinutes);
      if (diff.inHours < 24)   return AppLocalizations.of(context)!.notificationsHoursAgo(diff.inHours);
      if (diff.inDays < 7)     return AppLocalizations.of(context)!.notificationsDaysAgo(diff.inDays);

      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Widget _buildLoader() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: AppColors.customerColor,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.notificationsLoadingText,
              style: TextStyle(
                fontSize: 14,
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.notificationsErrorTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.colors.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                AppLocalizations.of(context)!.retryCta,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.customerColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
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
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.customerColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                color: AppColors.customerColor,
                size: 42,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.notificationsEmptyTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.notificationsEmptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.colors.textSecondary,
                letterSpacing: 0.2,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: isDark
            ? const Color(0xFF1E293B)
            : context.colors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class _NotifSection {
  final String label;
  final List<dynamic> items;
  _NotifSection(this.label, this.items);
}