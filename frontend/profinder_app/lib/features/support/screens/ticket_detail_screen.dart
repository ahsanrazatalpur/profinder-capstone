// lib/features/support/screens/ticket_detail_screen.dart
//
// One ticket: header, conversation, reply box. A closed ticket shows a notice
// instead of the reply box. Replies keep their text when sending fails.

import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../../../services/support_service.dart';
import '../models/ticket_models.dart';
import '../widgets/support_search_field.dart' show detectTextDirection;
import '../widgets/support_state_views.dart';
import '../widgets/ticket_labels.dart';

class TicketDetailScreen extends StatefulWidget {
  final int ticketId;

  /// Overridable for tests; defaults to the real API.
  final TicketDataSource? source;

  const TicketDetailScreen({super.key, required this.ticketId, this.source});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late final TicketDataSource _source = widget.source ?? SupportService();
  final _reply = TextEditingController();
  final _scroll = ScrollController();

  SupportResult<SupportTicketDetail>? _result;
  bool _loading = true;
  bool _sending = false;
  int _reqId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reply.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool showSpinner = true}) async {
    final id = ++_reqId;
    if (showSpinner) setState(() => _loading = true);
    final result = await _source.getTicket(widget.ticketId);
    if (!mounted || id != _reqId) return;
    setState(() {
      _result = result;
      _loading = false;
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _send() async {
    final text = _reply.text.trim();
    if (_sending || text.isEmpty) return;
    final t = AppLocalizations.of(context);
    setState(() => _sending = true);
    final result = await _source.replyToTicket(widget.ticketId, text);
    if (!mounted) return;
    if (result.isOk) {
      _reply.clear();
      setState(() {
        _result = result;
        _sending = false;
      });
      _scrollToEnd();
    } else {
      setState(() => _sending = false);
      _snack(ticketFailureMessage(t, result.failure));
      if (result.failure == SupportFailure.conflict) _load(showSpinner: false);
    }
  }

  Future<void> _confirmClose() async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.ticketCloseConfirmTitle),
        content: Text(t.ticketCloseConfirmMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancelCta)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.ticketCloseCta)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final result = await _source.closeTicket(widget.ticketId);
    if (!mounted) return;
    if (result.isOk) {
      setState(() => _result = result);
    } else {
      _snack(ticketFailureMessage(t, result.failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final detail = _result?.data;
    final canClose = detail != null && !detail.isClosed;
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
          if (canClose) ...[
            const SizedBox(width: AppSizes.sm),
            AppBarIconButton(
              icon: Icons.check_circle_outline_rounded,
              tooltip: t.ticketCloseCta,
              onGradient: true,
              onPressed: _confirmClose,
            ),
          ],
        ],
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
    final detail = result.data!;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsetsDirectional.all(AppSizes.md),
                children: [
                  _header(context, t, detail),
                  const SizedBox(height: AppSizes.md),
                  for (final m in detail.messages) _MessageBubble(message: m),
                ],
              ),
            ),
            if (detail.isClosed) _closedNotice(context, t) else _composer(context, t),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AppLocalizations t, SupportTicketDetail detail) {
    final styles = context.textStyles;
    final s = detail.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.subject, style: styles.h3.copyWith(letterSpacing: 0)),
        const SizedBox(height: AppSizes.xs),
        Text(
          [
            ticketCategoryLabel(t, s.category),
            formatTicketTime(context, s.createdAt),
          ].where((x) => x.isNotEmpty).join(' · '),
          style: styles.bodySmall.copyWith(letterSpacing: 0),
        ),
        if (s.reference.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            t.guestContactReference(s.reference),
            style: styles.bodySmall.copyWith(letterSpacing: 0),
          ),
        ],
        const SizedBox(height: AppSizes.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TicketStatusChip(status: s.status),
        ),
      ],
    );
  }

  Widget _closedNotice(BuildContext context, AppLocalizations t) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(AppSizes.md),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, size: AppSizes.iconMd - 4, color: colors.textSecondary),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              t.ticketClosedNotice,
              style: context.textStyles.bodySmall.copyWith(letterSpacing: 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _composer(BuildContext context, AppLocalizations t) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(AppSizes.md, AppSizes.sm, AppSizes.sm, AppSizes.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _reply,
              enabled: !_sending,
              minLines: 1,
              maxLines: 5,
              maxLength: kTicketBodyMax,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: context.textStyles.inputText.copyWith(letterSpacing: 0),
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
              decoration: InputDecoration(hintText: t.ticketReplyHint),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: AppSizes.xs),
          IconButton.filled(
            tooltip: t.ticketReplySendTooltip,
            onPressed: (_sending || _reply.text.trim().isEmpty) ? null : _send,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final TicketMessageItem message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = context.colors;
    final styles = context.textStyles;
    final fromSupport = message.isStaff;
    final maxWidth = (MediaQuery.sizeOf(context).width * 0.82).clamp(0.0, 560.0);
    final bodyDirection = detectTextDirection(message.body) ?? Directionality.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSizes.sm + 4),
      child: Align(
        alignment: fromSupport ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            padding: const EdgeInsetsDirectional.all(AppSizes.sm + 4),
            decoration: BoxDecoration(
              color: fromSupport ? colors.surface : colors.primaryLight,
              border: Border.all(color: colors.divider),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fromSupport ? t.ticketSupportTeamLabel : t.ticketYouLabel,
                  style: styles.bodySmall.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0),
                ),
                const SizedBox(height: AppSizes.xs),
                // The text follows its own language, not the app locale.
                Directionality(
                  textDirection: bodyDirection,
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      message.body,
                      textAlign: TextAlign.start,
                      style: styles.bodyMedium.copyWith(height: 1.5, letterSpacing: 0),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  formatTicketTime(context, message.createdAt),
                  style: styles.bodySmall.copyWith(letterSpacing: 0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}