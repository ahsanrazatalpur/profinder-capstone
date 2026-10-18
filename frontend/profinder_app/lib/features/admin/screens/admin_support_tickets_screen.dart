// lib/features/admin/screens/admin_support_tickets_screen.dart
//
// Support → Tickets inbox (admin panel tab, English only).
//
// Backend:
//   GET /api/support/admin/tickets/summary/
//   GET /api/support/admin/tickets/?status=&assigned=&needs_reply=&q=&offset=&limit=

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/support_admin_service.dart';
import '../../../services/support_service.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../models/support_admin_models.dart';
import '../widgets/admin_ticket_ui.dart';
import 'admin_support_ticket_detail_screen.dart';

/// Inbox filters: key -> (label, status, assigned, needsReply).
class _Filter {
  final String key;
  final String label;
  final String? status;
  final String? assigned;
  final bool needsReply;

  const _Filter(
    this.key,
    this.label, {
    this.status,
    this.assigned,
    this.needsReply = false,
  });
}

const List<_Filter> _filters = [
  _Filter('needs_reply', 'Needs reply', needsReply: true),
  _Filter('active', 'Active', status: 'active'),
  _Filter('mine', 'Mine', status: 'active', assigned: 'me'),
  _Filter('unassigned', 'Unassigned', status: 'active', assigned: 'unassigned'),
  _Filter('resolved', 'Resolved', status: 'resolved'),
  _Filter('closed', 'Closed', status: 'closed'),
  _Filter('all', 'All'),
];

class AdminSupportTicketsScreen extends StatefulWidget {
  /// Overridable for tests; defaults to the real API.
  final SupportAdminDataSource? source;

  const AdminSupportTicketsScreen({super.key, this.source});

  @override
  State<AdminSupportTicketsScreen> createState() =>
      _AdminSupportTicketsScreenState();
}

class _AdminSupportTicketsScreenState extends State<AdminSupportTicketsScreen> {
  static const _pageSize = 30;

  late final SupportAdminDataSource _source =
      widget.source ?? SupportAdminService();
  final _search = TextEditingController();
  Timer? _debounce;

  String _filterKey = 'active';
  AdminTicketCounts? _counts;
  List<AdminTicketSummary> _tickets = [];
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  SupportFailure? _failure;
  int _reqId = 0;

  _Filter get _filter => _filters.firstWhere((f) => f.key == _filterKey);

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<SupportResult<AdminTicketPage>> _fetch(int offset) {
    final f = _filter;
    return _source.getTickets(
      status: f.status,
      assigned: f.assigned,
      needsReply: f.needsReply,
      query: _search.text,
      offset: offset,
      limit: _pageSize,
    );
  }

  Future<void> _reload({bool spinner = true}) async {
    final id = ++_reqId;
    if (spinner)
      setState(() {
        _loading = true;
        _failure = null;
      });
    final countsFuture = _source.getCounts();
    final pageFuture = _fetch(0);
    final counts = await countsFuture;
    final page = await pageFuture;
    if (!mounted || id != _reqId) return;
    setState(() {
      _loading = false;
      if (counts.isOk) _counts = counts.data;
      if (page.isOk) {
        _tickets = page.data!.results;
        _total = page.data!.count;
        _failure = null;
      } else {
        _failure = page.failure;
      }
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _tickets.length >= _total) return;
    final id = _reqId;
    setState(() => _loadingMore = true);
    final page = await _fetch(_tickets.length);
    if (!mounted || id != _reqId) return;
    setState(() {
      _loadingMore = false;
      if (page.isOk) {
        _tickets = [..._tickets, ...page.data!.results];
        _total = page.data!.count;
      }
    });
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _reload);
  }

  Future<void> _open(AdminTicketSummary t) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AdminSupportTicketDetailScreen(ticketId: t.id, source: _source),
      ),
    );
    if (mounted) _reload(spinner: false); // status / assignee may have changed
  }

  String _chipLabel(_Filter f) {
    final c = _counts;
    if (c == null) return f.label;
    final n = switch (f.key) {
      'needs_reply' => c.needsReply,
      'active' => c.active,
      'mine' => c.mineActive,
      'unassigned' => c.unassignedActive,
      'resolved' => c.byStatus['resolved'] ?? 0,
      'closed' => c.byStatus['closed'] ?? 0,
      _ => null,
    };
    return n == null ? f.label : '${f.label} ($n)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightScaffold,
      appBar: UniversalAppBar(
        title: 'Support tickets',
        icon: Icons.support_agent_rounded,
        color: AppColors.adminColor,
        showBack: false,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _filterBar(),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _filterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        children: [
          TextField(
            controller: _search,
            onChanged: _onSearchChanged,
            onSubmitted: (_) => _reload(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search reference, subject or email',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Clear',
                      onPressed: () {
                        _search.clear();
                        _reload();
                      },
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filters[i];
                return ChoiceChip(
                  label: Text(_chipLabel(f)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  selected: f.key == _filterKey,
                  selectedColor: AppColors.adminColor.withValues(alpha: 0.15),
                  onSelected: (_) {
                    setState(() => _filterKey = f.key);
                    _reload();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.adminColor),
      );
    }
    if (_failure != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: AppColors.neutral400,
              ),
              const SizedBox(height: 12),
              Text(
                _failure == SupportFailure.unauthorized
                    ? 'You do not have access to support tickets.'
                    : 'Failed to load tickets.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _reload, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_tickets.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _reload(spinner: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            Icon(Icons.inbox_rounded, size: 40, color: AppColors.neutral400),
            SizedBox(height: 12),
            Center(child: Text('No tickets here.')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _reload(spinner: false),
      color: AppColors.adminColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: _tickets.length + (_tickets.length < _total ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              if (i >= _tickets.length) {
                return Center(
                  child: _loadingMore
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            color: AppColors.adminColor,
                          ),
                        )
                      : OutlinedButton(
                          onPressed: _loadMore,
                          child: Text(
                            'Load more (${_total - _tickets.length} left)',
                          ),
                        ),
                );
              }
              return _TicketCard(
                ticket: _tickets[i],
                onTap: () => _open(_tickets[i]),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final AdminTicketSummary ticket;
  final VoidCallback onTap;

  const _TicketCard({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = adminTicketStatusColor(ticket.status);
    final meta = [
      ticket.reference,
      adminTicketCategoryLabel(ticket.category),
      adminTicketTime(context, ticket.lastActivityAt),
    ].where((s) => s.isNotEmpty).join(' · ');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticket.subject,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppFontSizes.body,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray800,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    ticket.isGuest
                        ? Icons.person_off_outlined
                        : Icons.person_outline_rounded,
                    size: 14,
                    color: AppColors.neutral400,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      ticket.isGuest
                          ? 'Guest · ${ticket.requesterLabel}'
                          : ticket.requesterLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppFontSizes.small,
                        color: AppColors.grayDeep,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                meta,
                style: const TextStyle(
                  fontSize: AppFontSizes.caption,
                  color: AppColors.neutral400,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  AdminTicketPill(
                    label: adminTicketStatusLabel(ticket.status),
                    icon: adminTicketStatusIcon(ticket.status),
                    color: statusColor,
                  ),
                  if (ticket.needsReply)
                    const AdminTicketPill(
                      label: 'Needs reply',
                      icon: Icons.reply_rounded,
                      color: AppColors.error,
                    ),
                  if (ticket.priority != 'normal')
                    AdminTicketPill(
                      label:
                          '${adminTicketPriorityLabel(ticket.priority)} priority',
                      icon: ticket.priority == 'high'
                          ? Icons.priority_high_rounded
                          : Icons.arrow_downward_rounded,
                      color: ticket.priority == 'high'
                          ? AppColors.error
                          : AppColors.slate500,
                    ),
                  if (ticket.assignedTo != null)
                    AdminTicketPill(
                      label: ticket.assignedTo!.name.isNotEmpty
                          ? ticket.assignedTo!.name
                          : ticket.assignedTo!.email,
                      icon: Icons.assignment_ind_outlined,
                      color: AppColors.primary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
