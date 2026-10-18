// lib/features/support/models/ticket_models.dart
//
// Parsed responses of /api/support/tickets/... Parsing is defensive: a missing
// or unexpected field never throws.

enum TicketStatus { open, inProgress, awaitingUser, resolved, closed }

TicketStatus parseTicketStatus(Object? raw) {
  switch (raw) {
    case 'in_progress':
      return TicketStatus.inProgress;
    case 'awaiting_user':
      return TicketStatus.awaitingUser;
    case 'resolved':
      return TicketStatus.resolved;
    case 'closed':
      return TicketStatus.closed;
    default:
      return TicketStatus.open;
  }
}

/// Category keys accepted by the server (SupportTicket.CATEGORY_CHOICES).
const List<String> kTicketCategories = [
  'account',
  'booking',
  'payment',
  'verification',
  'technical',
  'privacy',
  'feedback',
  'other',
];

/// Limits mirrored from the server (ticket_serializers.py).
const int kTicketSubjectMax = 150;
const int kTicketBodyMax = 5000;

DateTime? _date(Object? raw) =>
    raw is String ? DateTime.tryParse(raw)?.toLocal() : null;

class SupportTicketSummary {
  final int id;
  final String reference;
  final String subject;
  final String category;
  final TicketStatus status;
  final DateTime? createdAt;
  final DateTime? lastActivityAt;

  /// True when the newest visible message is from support.
  final bool lastMessageIsStaff;

  const SupportTicketSummary({
    required this.id,
    required this.reference,
    required this.subject,
    required this.category,
    required this.status,
    required this.createdAt,
    required this.lastActivityAt,
    required this.lastMessageIsStaff,
  });

  factory SupportTicketSummary.fromJson(Map<String, dynamic> json) =>
      SupportTicketSummary(
        id: (json['id'] as num?)?.toInt() ?? 0,
        reference: (json['reference'] ?? '').toString(),
        subject: (json['subject'] ?? '').toString(),
        category: (json['category'] ?? 'other').toString(),
        status: parseTicketStatus(json['status']),
        createdAt: _date(json['created_at']),
        lastActivityAt: _date(json['last_activity_at']),
        lastMessageIsStaff: json['last_message_is_staff'] == true,
      );
}

class TicketMessageItem {
  final int id;
  final String body;
  final bool isStaff;
  final DateTime? createdAt;

  const TicketMessageItem({
    required this.id,
    required this.body,
    required this.isStaff,
    required this.createdAt,
  });

  factory TicketMessageItem.fromJson(Map<String, dynamic> json) =>
      TicketMessageItem(
        id: (json['id'] as num?)?.toInt() ?? 0,
        body: (json['body'] ?? '').toString(),
        isStaff: json['is_staff'] == true,
        createdAt: _date(json['created_at']),
      );
}

class SupportTicketDetail {
  final SupportTicketSummary summary;
  final List<TicketMessageItem> messages;

  const SupportTicketDetail({required this.summary, required this.messages});

  bool get isClosed => summary.status == TicketStatus.closed;

  factory SupportTicketDetail.fromJson(Map<String, dynamic> json) {
    final raw = json['messages'];
    return SupportTicketDetail(
      summary: SupportTicketSummary.fromJson(json),
      messages: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (m) =>
                      TicketMessageItem.fromJson(Map<String, dynamic>.from(m)),
                )
                .toList()
          : const [],
    );
  }
}

/// Result of the logged-out contact form.
class GuestReceipt {
  /// Null when the server silently dropped the message (honeypot); the UI
  /// treats that exactly like a normal success.
  final String? reference;

  const GuestReceipt(this.reference);

  factory GuestReceipt.fromJson(Map<String, dynamic> json) =>
      GuestReceipt(json['reference'] as String?);
}
