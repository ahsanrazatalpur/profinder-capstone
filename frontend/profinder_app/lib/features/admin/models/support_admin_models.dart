// lib/features/admin/models/support_admin_models.dart
//
// Parsed responses of /api/support/admin/tickets/... (admin only, English).
// Defensive parsing: a missing field never throws.

DateTime? _date(Object? raw) => raw is String ? DateTime.tryParse(raw)?.toLocal() : null;

String _s(Object? v) => (v ?? '').toString();

class AdminPerson {
  final int id;
  final String name;
  final String email;
  final String role;

  const AdminPerson({required this.id, required this.name, required this.email, required this.role});

  static AdminPerson? fromJson(Object? raw) {
    if (raw is! Map) return null;
    return AdminPerson(
      id: (raw['id'] as num?)?.toInt() ?? 0,
      name: _s(raw['name']),
      email: _s(raw['email']),
      role: _s(raw['role']),
    );
  }
}

class AdminTicketCounts {
  final Map<String, int> byStatus;
  final int unassignedActive;
  final int mineActive;
  final int needsReply;

  const AdminTicketCounts({
    required this.byStatus,
    required this.unassignedActive,
    required this.mineActive,
    required this.needsReply,
  });

  int get active => (byStatus['open'] ?? 0) + (byStatus['in_progress'] ?? 0) + (byStatus['awaiting_user'] ?? 0);

  factory AdminTicketCounts.fromJson(Map<String, dynamic> json) {
    int n(String k) => (json[k] as num?)?.toInt() ?? 0;
    return AdminTicketCounts(
      byStatus: {
        for (final k in const ['open', 'in_progress', 'awaiting_user', 'resolved', 'closed']) k: n(k),
      },
      unassignedActive: n('unassigned_active'),
      mineActive: n('mine_active'),
      needsReply: n('needs_reply'),
    );
  }
}

class AdminTicketSummary {
  final int id;
  final String reference;
  final String subject;
  final String category;
  final String status;
  final String priority;
  final String role;
  final AdminPerson? requester;
  final String contactEmail;
  final AdminPerson? assignedTo;
  final DateTime? createdAt;
  final DateTime? lastActivityAt;
  final bool needsReply;

  const AdminTicketSummary({
    required this.id,
    required this.reference,
    required this.subject,
    required this.category,
    required this.status,
    required this.priority,
    required this.role,
    required this.requester,
    required this.contactEmail,
    required this.assignedTo,
    required this.createdAt,
    required this.lastActivityAt,
    required this.needsReply,
  });

  bool get isGuest => requester == null;

  /// Who wrote in: the account's name, or the e-mail a guest gave.
  String get requesterLabel {
    final r = requester;
    if (r != null) return r.name.isNotEmpty ? r.name : r.email;
    return contactEmail;
  }

  factory AdminTicketSummary.fromJson(Map<String, dynamic> json) => AdminTicketSummary(
        id: (json['id'] as num?)?.toInt() ?? 0,
        reference: _s(json['reference']),
        subject: _s(json['subject']),
        category: _s(json['category']),
        status: _s(json['status']).isEmpty ? 'open' : _s(json['status']),
        priority: _s(json['priority']).isEmpty ? 'normal' : _s(json['priority']),
        role: _s(json['role']),
        requester: AdminPerson.fromJson(json['requester']),
        contactEmail: _s(json['contact_email']),
        assignedTo: AdminPerson.fromJson(json['assigned_to']),
        createdAt: _date(json['created_at']),
        lastActivityAt: _date(json['last_activity_at']),
        needsReply: json['needs_reply'] == true,
      );
}

class AdminTicketMessage {
  final int id;
  final String body;
  final bool isStaff;
  final bool isInternal;
  final String? authorName;
  final DateTime? createdAt;

  const AdminTicketMessage({
    required this.id,
    required this.body,
    required this.isStaff,
    required this.isInternal,
    required this.authorName,
    required this.createdAt,
  });

  factory AdminTicketMessage.fromJson(Map<String, dynamic> json) => AdminTicketMessage(
        id: (json['id'] as num?)?.toInt() ?? 0,
        body: _s(json['body']),
        isStaff: json['is_staff'] == true,
        isInternal: json['is_internal'] == true,
        authorName: json['author_name'] as String?,
        createdAt: _date(json['created_at']),
      );
}

class AdminTicketEvent {
  final String action;
  final String detail;
  final String? actorName;
  final DateTime? createdAt;

  const AdminTicketEvent({
    required this.action,
    required this.detail,
    required this.actorName,
    required this.createdAt,
  });

  factory AdminTicketEvent.fromJson(Map<String, dynamic> json) => AdminTicketEvent(
        action: _s(json['action']),
        detail: _s(json['detail']),
        actorName: json['actor_name'] as String?,
        createdAt: _date(json['created_at']),
      );
}

class AdminTicketDetail {
  final AdminTicketSummary summary;
  final int? relatedBooking;
  final String platform;
  final String appVersion;
  final String appLanguage;
  final DateTime? closedAt;
  final List<AdminTicketMessage> messages;
  final List<AdminTicketEvent> events;

  const AdminTicketDetail({
    required this.summary,
    required this.relatedBooking,
    required this.platform,
    required this.appVersion,
    required this.appLanguage,
    required this.closedAt,
    required this.messages,
    required this.events,
  });

  bool get isClosed => summary.status == 'closed';

  factory AdminTicketDetail.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(Object? raw, T Function(Map<String, dynamic>) f) => raw is List
        ? raw.whereType<Map>().map((m) => f(Map<String, dynamic>.from(m))).toList()
        : <T>[];
    return AdminTicketDetail(
      summary: AdminTicketSummary.fromJson(json),
      relatedBooking: (json['related_booking'] as num?)?.toInt(),
      platform: _s(json['platform']),
      appVersion: _s(json['app_version']),
      appLanguage: _s(json['app_language']),
      closedAt: _date(json['closed_at']),
      messages: list(json['messages'], AdminTicketMessage.fromJson),
      events: list(json['events'], AdminTicketEvent.fromJson),
    );
  }
}

class AdminTicketPage {
  final int count;
  final List<AdminTicketSummary> results;

  const AdminTicketPage({required this.count, required this.results});

  factory AdminTicketPage.fromJson(Map<String, dynamic> json) {
    final raw = json['results'];
    return AdminTicketPage(
      count: (json['count'] as num?)?.toInt() ?? 0,
      results: raw is List
          ? raw.whereType<Map>().map((m) => AdminTicketSummary.fromJson(Map<String, dynamic>.from(m))).toList()
          : const [],
    );
  }
}