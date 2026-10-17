// lib/features/support/screens/my_tickets_screen.dart
//
// The signed-in user's support tickets (newest activity first).

import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../../../services/support_service.dart';
import '../models/ticket_models.dart';
import '../widgets/support_state_views.dart';
import '../widgets/support_status_chip.dart';
import '../widgets/ticket_labels.dart';
import 'new_ticket_screen.dart';
import 'ticket_detail_screen.dart';

class MyTicketsScreen extends StatefulWidget {
  /// Overridable for tests; defaults to the real API.
  final TicketDataSource? source;

  const MyTicketsScreen({super.key, this.source});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  late final TicketDataSource _source = widget.source ?? SupportService();

  SupportResult<List<SupportTicketSummary>>? _result;
  bool _loading = true;
  int _reqId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showSpinner = true}) async {
    final id = ++_reqId;
    if (showSpinner) setState(() => _loading = true);
    final result = await _source.getTickets();
    if (!mounted || id != _reqId) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  Future<void> _newTicket() async {
    final created = await Navigator.push<SupportTicketDetail>(
      context,
      MaterialPageRoute(builder: (_) => NewTicketScreen(source: _source)),
    );
    if (!mounted || created == null) return;
    final t = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.ticketCreatedMessage(created.summary.reference))),
    );
    _load(showSpinner: false);
  }

  Future<void> _open(SupportTicketSummary ticket) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TicketDetailScreen(ticketId: ticket.id, source: _source),
      ),
    );
    if (mounted) _load(showSpinner: false); // status / new reply may have changed
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: UniversalAppBar(
        title: t.ticketsTitle,
        icon: Icons.support_agent_rounded,
        actions: [
          AppBarIconButton(
            icon: Icons.refresh_rounded,
            tooltip: t.refreshTooltip,
            onGradient: true,
            onPressed: _loading ? () {} : _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newTicket,
        icon: const Icon(Icons.add_rounded),
        label: Text(t.ticketsNewCta),
      ),
      body: SafeArea(child: _body(context, t)),
    );
  }

  Widget _body(BuildContext context, AppLocalizations t) {
    if (_loading) return const SupportLoadingState();
    final result = _result;
    if (result == null || !result.isOk) {
      return SupportErrorState(
        onRetry: _load,
        message: ticketFailureMessage(t, result?.failure),
      );
    }
    final tickets = result.data!;
    if (tickets.isEmpty) {
      return SupportEmptyState(
        icon: Icons.support_agent_rounded,
        title: t.ticketsEmptyTitle,
        message: t.ticketsEmptyMessage,
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(showSpinner: false),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            // Bottom space so the floating button never covers the last card.
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSizes.md, AppSizes.md, AppSizes.md, 96,
            ),
            itemCount: tickets.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
            itemBuilder: (context, i) => _TicketCard(
              ticket: tickets[i],
              onTap: () => _open(tickets[i]),
            ),
          ),
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final SupportTicketSummary ticket;
  final VoidCallback onTap;

  const _TicketCard({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = context.colors;
    final styles = context.textStyles;
    final hasNewReply = ticket.lastMessageIsStaff && ticket.status != TicketStatus.closed;

    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(color: colors.divider),
      ),
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.subject,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: styles.bodyLarge.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  [
                    ticketCategoryLabel(t, ticket.category),
                    formatTicketTime(context, ticket.lastActivityAt),
                  ].where((s) => s.isNotEmpty).join(' · '),
                  style: styles.bodySmall.copyWith(letterSpacing: 0),
                ),
                const SizedBox(height: AppSizes.sm),
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.xs,
                  children: [
                    TicketStatusChip(status: ticket.status),
                    if (hasNewReply)
                      SupportStatusChip(
                        label: t.ticketNewReplyBadge,
                        icon: Icons.chat_bubble_rounded,
                        tone: SupportChipTone.warning,
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
}