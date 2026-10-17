// lib/features/admin/screens/admin_support_ticket_detail_screen.dart
//
// One support ticket for admins (English only): conversation incl. internal
// notes, status / priority / assignee, and a reply box with a Reply /
// Internal note switch.
//
// Backend:
//   GET   /api/support/admin/tickets/<id>/
//   PATCH /api/support/admin/tickets/<id>/        { status | priority | assigned_to }
//   POST  /api/support/admin/tickets/<id>/reply/  { body, internal }

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/support_admin_service.dart';
import '../../../services/support_service.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../models/support_admin_models.dart';
import '../widgets/admin_ticket_ui.dart';

const int _maxBody = 5000;

const Map<String, String> _eventLabels = {
  'created': 'Ticket created',
  'created_by_guest': 'Guest message received',
  'user_reply': 'User replied',
  'reopened_by_reply': 'Reopened by user reply',
  'staff_reply': 'Support replied',
  'internal_note': 'Internal note added',
  'status_changed': 'Status changed',
  'priority_changed': 'Priority changed',
  'assigned': 'Assignee changed',
  'closed_by_user': 'Closed by user',
};

class AdminSupportTicketDetailScreen extends StatefulWidget {
  final int ticketId;

  /// Overridable for tests; defaults to the real API.
  final SupportAdminDataSource? source;

  const AdminSupportTicketDetailScreen({super.key, required this.ticketId, this.source});

  @override
  State<AdminSupportTicketDetailScreen> createState() => _AdminSupportTicketDetailScreenState();
}

class _AdminSupportTicketDetailScreenState extends State<AdminSupportTicketDetailScreen> {
  late final SupportAdminDataSource _source = widget.source ?? SupportAdminService();
  final _text = TextEditingController();
  final _scroll = ScrollController();

  SupportResult<AdminTicketDetail>? _result;
  bool _loading = true;
  bool _sending = false;
  bool _updating = false;
  bool _internal = false;
  int _reqId = 0;

  AdminTicketDetail? get _detail => _result?.data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool spinner = true}) async {
    final id = ++_reqId;
    if (spinner) setState(() => _loading = true);
    final result = await _source.getTicket(widget.ticketId);
    if (!mounted || id != _reqId) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _failureText(SupportFailure? f) {
    switch (f) {
      case SupportFailure.conflict:
        return 'This ticket is closed. Reopen it first.';
      case SupportFailure.invalid:
        return 'The server rejected that change.';
      case SupportFailure.unauthorized:
        return 'You do not have access to do this.';
      case SupportFailure.notFound:
        return 'This ticket no longer exists.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  Future<void> _update({String? status, String? priority, String? assignee}) async {
    if (_updating) return;
    setState(() => _updating = true);
    final result = await _source.update(widget.ticketId, status: status, priority: priority, assignee: assignee);
    if (!mounted) return;
    setState(() {
      _updating = false;
      if (result.isOk) _result = result;
    });
    if (!result.isOk) _snack(_failureText(result.failure));
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    final detail = _detail;
    if (_sending || body.isEmpty || detail == null) return;
    final internal = _internal || detail.isClosed;
    setState(() => _sending = true);
    final result = await _source.reply(widget.ticketId, body, internal: internal);
    if (!mounted) return;
    if (result.isOk) {
      _text.clear();
      setState(() {
        _result = result;
        _sending = false;
      });
      _scrollToEnd();
    } else {
      setState(() => _sending = false);
      _snack(_failureText(result.failure));
      if (result.failure == SupportFailure.conflict) _load(spinner: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return Scaffold(
      backgroundColor: AppColors.lightScaffold,
      appBar: UniversalAppBar(
        title: detail?.summary.reference ?? 'Ticket',
        icon: Icons.support_agent_rounded,
        color: AppColors.adminColor,
      ),
      body: SafeArea(top: false, child: _body()),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.adminColor));
    }
    final detail = _detail;
    if (detail == null) {
      final notFound = _result?.failure == SupportFailure.notFound;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(notFound ? 'This ticket no longer exists.' : 'Failed to load the ticket.'),
              if (!notFound) ...[
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _load, child: const Text('Retry')),
              ],
            ],
          ),
        ),
      );
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _load(spinner: false),
                child: ListView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    _header(detail),
                    const SizedBox(height: 12),
                    _actions(detail),
                    const SizedBox(height: 16),
                    for (final m in detail.messages) _bubble(detail, m),
                    _activity(detail),
                  ],
                ),
              ),
            ),
            _composer(detail),
          ],
        ),
      ),
    );
  }

  // A Material (not a decorated Container): the Activity section holds an
  // ExpansionTile (ListTile), which must paint on a real Material surface.
  Widget _card({required Widget child}) => Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.neutral200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: SizedBox(width: double.infinity, child: child),
        ),
      );

  Widget _header(AdminTicketDetail d) {
    final s = d.summary;
    final who = s.isGuest
        ? 'Guest · ${s.contactEmail}'
        : '${s.requesterLabel}${s.requester!.email.isNotEmpty && s.requester!.name.isNotEmpty ? ' · ${s.requester!.email}' : ''}'
            '${s.role.isNotEmpty ? ' (${s.role})' : ''}';
    final client = [d.platform, d.appVersion.isEmpty ? '' : 'v${d.appVersion}', d.appLanguage]
        .where((x) => x.isNotEmpty)
        .join(' · ');
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.subject,
              style: const TextStyle(fontSize: AppFontSizes.title2, fontWeight: FontWeight.w800, color: AppColors.gray800)),
          const SizedBox(height: 6),
          Text(who, style: const TextStyle(fontSize: AppFontSizes.small, color: AppColors.grayDeep)),
          const SizedBox(height: 2),
          Text(
            [
              adminTicketCategoryLabel(s.category),
              'Opened ${adminTicketTime(context, s.createdAt)}',
              if (d.relatedBooking != null) 'Booking #${d.relatedBooking}',
              if (client.isNotEmpty) client,
            ].join(' · '),
            style: const TextStyle(fontSize: AppFontSizes.caption, color: AppColors.neutral400),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              AdminTicketPill(
                label: adminTicketStatusLabel(s.status),
                icon: adminTicketStatusIcon(s.status),
                color: adminTicketStatusColor(s.status),
              ),
              if (s.priority != 'normal')
                AdminTicketPill(
                  label: '${adminTicketPriorityLabel(s.priority)} priority',
                  icon: s.priority == 'high' ? Icons.priority_high_rounded : Icons.arrow_downward_rounded,
                  color: s.priority == 'high' ? AppColors.error : AppColors.slate500,
                ),
              AdminTicketPill(
                label: s.assignedTo == null
                    ? 'Unassigned'
                    : (s.assignedTo!.name.isNotEmpty ? s.assignedTo!.name : s.assignedTo!.email),
                icon: Icons.assignment_ind_outlined,
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actions(AdminTicketDetail d) {
    final s = d.summary;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        PopupMenuButton<String>(
          tooltip: 'Change status',
          enabled: !_updating,
          onSelected: (v) => _update(status: v),
          itemBuilder: (_) => [
            for (final e in kAdminTicketStatusLabels.entries)
              PopupMenuItem(value: e.key, enabled: e.key != s.status, child: Text(e.value)),
          ],
          child: _actionChip(Icons.flag_outlined, 'Status: ${adminTicketStatusLabel(s.status)}'),
        ),
        PopupMenuButton<String>(
          tooltip: 'Change priority',
          enabled: !_updating,
          onSelected: (v) => _update(priority: v),
          itemBuilder: (_) => [
            for (final e in kAdminTicketPriorityLabels.entries)
              PopupMenuItem(value: e.key, enabled: e.key != s.priority, child: Text(e.value)),
          ],
          child: _actionChip(Icons.priority_high_rounded, 'Priority: ${adminTicketPriorityLabel(s.priority)}'),
        ),
        OutlinedButton.icon(
          onPressed: _updating ? null : () => _update(assignee: s.assignedTo == null ? 'me' : 'none'),
          icon: Icon(s.assignedTo == null ? Icons.person_add_alt_1_rounded : Icons.person_remove_alt_1_rounded, size: 18),
          label: Text(s.assignedTo == null ? 'Assign to me' : 'Unassign'),
        ),
        if (_updating)
          const Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      ],
    );
  }

  Widget _actionChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.gray700),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: AppFontSizes.small, fontWeight: FontWeight.w600)),
            const Icon(Icons.arrow_drop_down_rounded, size: 18),
          ],
        ),
      );

  Widget _bubble(AdminTicketDetail d, AdminTicketMessage m) {
    final internal = m.isInternal;
    final fromStaff = m.isStaff;
    final accent = internal ? AppColors.warningAmber : (fromStaff ? AppColors.primary : AppColors.slate500);
    final label = internal
        ? 'Internal note · ${m.authorName ?? 'admin'}'
        : (fromStaff ? (m.authorName ?? 'Support') : d.summary.requesterLabel);
    final maxWidth = (MediaQuery.sizeOf(context).width * 0.85).clamp(0.0, 640.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: fromStaff ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: internal ? AppColors.warningAmber.withValues(alpha: 0.12) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: internal ? AppColors.warningAmber : AppColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (internal) ...[
                      Icon(Icons.lock_rounded, size: 13, color: accent),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: AppFontSizes.caption, fontWeight: FontWeight.w800, color: accent)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Messages may be in any language: let the text pick its own direction.
                SelectableText(m.body, style: const TextStyle(fontSize: AppFontSizes.body, height: 1.45, color: AppColors.gray800)),
                const SizedBox(height: 4),
                Text(adminTicketTime(context, m.createdAt),
                    style: const TextStyle(fontSize: AppFontSizes.caption, color: AppColors.neutral400)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _activity(AdminTicketDetail d) {
    if (d.events.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: _card(
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: Text('Activity (${d.events.length})',
                style: const TextStyle(fontSize: AppFontSizes.small, fontWeight: FontWeight.w700)),
            children: [
              for (final e in d.events)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      [
                        _eventLabels[e.action] ?? e.action,
                        if (e.detail.isNotEmpty) e.detail,
                        if (e.actorName != null) 'by ${e.actorName}',
                        adminTicketTime(context, e.createdAt),
                      ].where((x) => x.isNotEmpty).join(' · '),
                      style: const TextStyle(fontSize: AppFontSizes.caption, color: AppColors.grayDeep),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _composer(AdminTicketDetail d) {
    final closed = d.isClosed;
    final internal = _internal || closed;
    final s = d.summary;
    final hint = internal
        ? 'Only admins can see this note.'
        : (s.isGuest ? 'This reply will be emailed to ${s.contactEmail}.' : 'The user will be notified of this reply.');

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.neutral200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (closed)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.lock_rounded, size: 14, color: AppColors.grayDeep),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text('Closed. Reopen it to reply to the user; internal notes are still allowed.',
                        style: TextStyle(fontSize: AppFontSizes.caption, color: AppColors.grayDeep)),
                  ),
                  TextButton(
                    onPressed: _updating ? null : () => _update(status: 'open'),
                    child: const Text('Reopen'),
                  ),
                ],
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                avatar: const Icon(Icons.reply_rounded, size: 16),
                label: const Text('Reply'),
                selected: !internal,
                // A closed ticket cannot receive a public reply (reopen it first).
                onSelected: closed ? null : (_) => setState(() => _internal = false),
              ),
              ChoiceChip(
                avatar: const Icon(Icons.lock_outline_rounded, size: 16),
                label: const Text('Internal note'),
                selected: internal,
                onSelected: (_) => setState(() => _internal = true),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _text,
                  enabled: !_sending,
                  minLines: 1,
                  maxLines: 6,
                  maxLength: _maxBody,
                  keyboardType: TextInputType.multiline,
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                  decoration: InputDecoration(
                    hintText: internal ? 'Write an internal note' : 'Write a reply',
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                tooltip: internal ? 'Add note' : 'Send reply',
                style: IconButton.styleFrom(backgroundColor: AppColors.adminColor),
                onPressed: (_sending || _text.text.trim().isEmpty) ? null : _send,
                icon: _sending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(hint, style: const TextStyle(fontSize: AppFontSizes.caption, color: AppColors.neutral400)),
        ],
      ),
    );
  }
}