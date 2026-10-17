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

import '../../../services/content_localizer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_provider.dart';
import '../../bookings/screens/my_bookings_screen.dart';
import '../../profile/screens/payments_screen.dart';
import '../../subscription/screens/subscription_screen.dart';
import '../../support/screens/my_tickets_screen.dart';
import '../../professional/screens/professional_main_screen.dart';
import '../../professional/screens/professional_reviews_screen.dart';
import '../../professional/screens/professional_wallet_screen.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';

class NotificationScreen extends StatefulWidget {
  /// Admin only: switches the admin shell to a tab (the dashboard passes its
  /// own tab switcher). Not needed for customers and professionals.
  final void Function(int tabIndex)? onNavigateToAdminTab;

  const NotificationScreen({super.key, this.onNavigateToAdminTab});

  /// Transforms raw technical or legacy notification strings
  /// (e.g. "for Booking #31", "Booking #31 | 12 May 2026", "PF-2026-0004:")
  /// into polite, natural, user-friendly language.
  static String humanizeMessage(String input) {
    if (input.isEmpty) return input;
    String text = input;

    // "Your payment of 50 USD for Booking #31 was successful." -> "... for your booking was successful."
    text = text.replaceAll(RegExp(r'\bfor\s+Booking\s*#\d+\b', caseSensitive: false), 'for your booking');

    // "Booking #31 | 12 May 2026 at 10:00 AM" -> "Scheduled for 12 May 2026 at 10:00 AM"
    text = text.replaceAll(RegExp(r'\bBooking\s*#\d+\s*\|\s*', caseSensitive: false), 'Scheduled for ');

    // Standalone "Booking #31" -> "your booking"
    text = text.replaceAll(RegExp(r'\bBooking\s*#\d+\b', caseSensitive: false), 'your booking');

    // Legacy ticket & report references: "PF-2026-0001: new reply" -> "Support: new reply"
    text = text.replaceAll(RegExp(r'\bPF-\d{4}-\d+:\s*', caseSensitive: false), 'Support: ');
    text = text.replaceAll(RegExp(r'\bPF-\d{4}-\d+\b', caseSensitive: false), 'your support request');
    text = text.replaceAll(RegExp(r'\bReport\s*#\d+\b', caseSensitive: false), 'your report');
    text = text.replaceAll(RegExp(r'\bTicket\s*#\d+\b', caseSensitive: false), 'your ticket');

    return text.trim();
  }

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
      setState(() { _loading = false; _error = AppLocalizations.of(context).notificationsLoadError; });
    }
  }

  // ── Mark single as read ───────────────────────────────────
  Future<void> _markRead(dynamic notif) async {
    if (notif['is_read'] == true) return;
    try {
      await _api.patch('/notifications/${notif['id']}/read/', {});
      if (!mounted) return;
      setState(() {
        final idx = _notifications.indexWhere((n) => n['id'] == notif['id']);
        if (idx != -1) _notifications[idx]['is_read'] = true;
      });
    } catch (_) {}
  }

  // ── Tap: mark as read, then open the screen this notification is about ──
  // `target_type` comes from the backend (worked out from the original English
  // text, so it is correct in every app language). If an older server does not
  // send it yet, we fall back to the plain `type`.
  void _onNotificationTap(dynamic notif) {
    _markRead(notif); // fire and forget, never delays the navigation
    _openTarget(notif);
  }

  void _openTarget(dynamic notif) {
    final role   = context.read<AuthProvider>().role;
    final target = (notif['target_type'] ?? notif['type'] ?? 'general').toString();
    final nav    = Navigator.of(context);
    Widget? page;

    if (role == 'customer') {
      page = switch (target) {
        // 'review' for a customer = "Service completed, please review" -> bookings
        'booking' || 'review' => const MyBookingsScreen(),
        'payment'             => const PaymentsScreen(),
        'subscription'        => const SubscriptionScreen(userRole: 'customer'),
        'support'             => const MyTicketsScreen(),
        _                     => null,
      };
    } else if (role == 'admin') {
      // Tab numbers of the admin shell (admin_main_screen.dart).
      final tab = switch (target) {
        'professional_signup' => 12, // Verify
        'report'              => 9,  // Reports
        'appeal'              => 26, // Appeals
        'booking'             => 5,  // Bookings
        'support'             => 27, // Support
        _                     => null,
      };
      final goTo = widget.onNavigateToAdminTab;
      if (tab != null && goTo != null) {
        nav.pop(); // back to the admin shell, then show that tab
        goTo(tab);
      }
      return;
    } else if (role == 'professional') {
      if (target == 'booking') {
        // Bookings is a tab of the professional shell (same as a push tap).
        nav.popUntil((r) => r.isFirst);
        ProfessionalMainScreen.switchTab(1);
        return;
      }
      page = switch (target) {
        'review'       => const ProfessionalReviewsScreen(),
        'payment'      => const ProfessionalWalletScreen(),
        'subscription' => const SubscriptionScreen(userRole: 'professional'),
        'support'      => const MyTicketsScreen(),
        _              => null,
      };
    }
    // Plain announcements: nothing to open, the tap only marks it read.

    if (page != null) {
      final screen = page;
      nav.push(MaterialPageRoute(builder: (_) => screen));
    }
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
    if (!mounted) return;
    setState(() {
      for (final n in _notifications) {
        n['is_read'] = true;
      }
    });
    _showSnack(AppLocalizations.of(context).notificationsMarkAllReadSuccess);
  }

  // ── Clear all (asks first, then deletes everything on the server) ──
  Future<void> _clearAll() async {
    final t = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.notificationsClearAllTitle),
        content: Text(t.notificationsClearAllMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(t.notificationsClearAllCta),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _api.delete('/notifications/clear/');
      if (!mounted) return;
      setState(() => _notifications = []);
      _showSnack(AppLocalizations.of(context).notificationsClearAllSuccess);
    } catch (_) {
      if (!mounted) return;
      _showSnack(AppLocalizations.of(context).notificationsClearAllError);
    }
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
              fontSize: AppFontSizes.caption,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : context.colors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : context.colors.divider,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.04),
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
                        ? Colors.white.withValues(alpha: 0.06)
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
    final message    = NotificationScreen.humanizeMessage(_stripEmoji(rawMessage));
    final type       = notif['type']?.toString()    ?? 'general';
    final isRead     = notif['is_read'] == true;
    final createdAt  = notif['created_at']?.toString() ?? '';

    final color = _typeColor(type);
    final icon  = _typeIcon(type);

    return Material(
      color: isRead
          ? Colors.transparent
          : AppColors.customerColor.withValues(alpha: 0.05),
      child: InkWell(
        onTap: () => _onNotificationTap(notif),
        splashColor: AppColors.customerColor.withValues(alpha: 0.1),
        highlightColor: AppColors.customerColor.withValues(alpha: 0.05),
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
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.2),
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
                    LocalizedText(
                      title,
                      kind: LocKind.text,
                      style: TextStyle(
                        fontSize: AppFontSizes.body,
                        fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                        color: context.colors.textPrimary,
                        height: 1.3,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    LocalizedText(
                      message,
                      kind: LocKind.text,
                      style: TextStyle(
                        fontSize: AppFontSizes.secondary,
                        color: context.colors.textSecondary,
                        height: 1.4,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(createdAt),
                      style: TextStyle(
                        fontSize: AppFontSizes.caption,
                        color: context.colors.textSecondary.withValues(alpha: 0.6),
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
                          color: AppColors.customerColor.withValues(alpha: 0.3),
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
    return UniversalAppBar(
      title: AppLocalizations.of(context).notificationsTitle,
      icon: Icons.notifications_rounded,
      actions: [
        if (_unreadCount > 0) ...[
          AppBarIconButton(
            icon: Icons.done_all_rounded,
            tooltip: AppLocalizations.of(context).notificationsMarkAllReadCta,
            badgeCount: _unreadCount,
            onGradient: true,
            badgeBorderColor: universalBarColor(context),
            onPressed: _markAllRead,
          ),
          const SizedBox(width: 8),
        ],
        if (_notifications.isNotEmpty) ...[
          AppBarIconButton(
            icon: Icons.delete_sweep_rounded,
            tooltip: AppLocalizations.of(context).notificationsClearAllCta,
            onGradient: true,
            onPressed: _clearAll,
          ),
          const SizedBox(width: 8),
        ],
        AppBarIconButton(
          icon: Icons.refresh_rounded,
          tooltip: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
          onGradient: true,
          onPressed: _load,
        ),
      ],
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

    if (diff == 0) return AppLocalizations.of(context).notificationsSectionToday;
    if (diff == 1) return AppLocalizations.of(context).notificationsSectionYesterday;
    if (diff < 7)  return AppLocalizations.of(context).notificationsSectionThisWeek;
    if (today.year == dt.year && today.month == dt.month) return AppLocalizations.of(context).notificationsSectionThisMonth;
    return DateFormat.yMMMM(Localizations.localeOf(context).toString()).format(dt);
  }

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
      'review'       => AppColors.warningAmber,
      'payment'      => AppColors.emerald,
      'subscription' => AppColors.violet,
      'booking'      => AppColors.customerColor,
      'report'       => AppColors.favoriteRed,
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

      if (diff.inMinutes < 1)  return AppLocalizations.of(context).notificationsJustNow;
      if (diff.inMinutes < 60) return AppLocalizations.of(context).notificationsMinutesAgo(diff.inMinutes);
      if (diff.inHours < 24)   return AppLocalizations.of(context).notificationsHoursAgo(diff.inHours);
      if (diff.inDays < 7)     return AppLocalizations.of(context).notificationsDaysAgo(diff.inDays);

      return DateFormat.yMd(Localizations.localeOf(context).toString()).format(dt);
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
              AppLocalizations.of(context).notificationsLoadingText,
              style: TextStyle(
                fontSize: AppFontSizes.body,
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
                color: AppColors.error.withValues(alpha: 0.1),
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
              AppLocalizations.of(context).notificationsErrorTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppFontSizes.title,
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
                fontSize: AppFontSizes.body,
                color: context.colors.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                AppLocalizations.of(context).retryCta,
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
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
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
                color: AppColors.customerColor.withValues(alpha: 0.1),
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
              AppLocalizations.of(context).notificationsEmptyTitle,
              style: TextStyle(
                fontSize: AppFontSizes.title2,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).notificationsEmptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppFontSizes.body,
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
            ? AppColors.surface
            : context.colors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius10),
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