// lib/features/support/widgets/ticket_labels.dart
//
// Localized labels, icons and the status chip for support tickets.

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../services/support_service.dart';
import '../models/ticket_models.dart';
import 'support_status_chip.dart';

String ticketCategoryLabel(AppLocalizations t, String key) {
  switch (key) {
    case 'account':
      return t.ticketCatAccount;
    case 'booking':
      return t.ticketCatBooking;
    case 'payment':
      return t.ticketCatPayment;
    case 'verification':
      return t.ticketCatVerification;
    case 'technical':
      return t.ticketCatTechnical;
    case 'privacy':
      return t.ticketCatPrivacy;
    case 'feedback':
      return t.ticketCatFeedback;
    default:
      return t.ticketCatOther;
  }
}

String ticketStatusLabel(AppLocalizations t, TicketStatus status) {
  switch (status) {
    case TicketStatus.open:
      return t.ticketStatusOpen;
    case TicketStatus.inProgress:
      return t.ticketStatusInProgress;
    case TicketStatus.awaitingUser:
      return t.ticketStatusAwaitingUser;
    case TicketStatus.resolved:
      return t.ticketStatusResolved;
    case TicketStatus.closed:
      return t.ticketStatusClosed;
  }
}

class TicketStatusChip extends StatelessWidget {
  final TicketStatus status;

  const TicketStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    late final IconData icon;
    late final SupportChipTone tone;
    switch (status) {
      case TicketStatus.open:
        icon = Icons.schedule_rounded;
        tone = SupportChipTone.info;
        break;
      case TicketStatus.inProgress:
        icon = Icons.sync_rounded;
        tone = SupportChipTone.info;
        break;
      case TicketStatus.awaitingUser:
        icon = Icons.hourglass_top_rounded;
        tone = SupportChipTone.warning;
        break;
      case TicketStatus.resolved:
        icon = Icons.check_circle_rounded;
        tone = SupportChipTone.success;
        break;
      case TicketStatus.closed:
        icon = Icons.lock_rounded;
        tone = SupportChipTone.neutral;
        break;
    }
    return SupportStatusChip(
      label: ticketStatusLabel(t, status),
      icon: icon,
      tone: tone,
    );
  }
}

/// Short date + time in the app locale, using MaterialLocalizations (no extra
/// date-formatting initialisation needed).
String formatTicketTime(BuildContext context, DateTime? time) {
  if (time == null) return '';
  final m = MaterialLocalizations.of(context);
  return '${m.formatShortDate(time)} ${m.formatTimeOfDay(TimeOfDay.fromDateTime(time))}';
}

/// Maps a service failure to a message for the ticket screens.
String ticketFailureMessage(AppLocalizations t, SupportFailure? failure) {
  switch (failure) {
    case SupportFailure.rateLimited:
      return t.ticketErrRateLimited;
    case SupportFailure.conflict:
      return t.ticketErrClosed;
    case SupportFailure.notFound:
      return t.ticketErrNotFound;
    case SupportFailure.unauthorized:
      return t.ticketErrSignIn;
    case SupportFailure.invalid:
      return t.ticketErrInvalid;
    case SupportFailure.network:
    case SupportFailure.other:
    case null:
      return t.supportErrorMessage;
  }
}
