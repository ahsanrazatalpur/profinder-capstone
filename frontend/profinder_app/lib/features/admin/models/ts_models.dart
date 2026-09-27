// lib/features/admin/models/ts_models.dart
//
// Trust & Safety (admin) — typed models for the Part 4–6 backend contract.
//
// Every parser is deliberately null-tolerant: `severity`, `evidence_url`,
// `related_booking*` and `related_message*` only exist on report payloads from
// a backend that includes the Part 7 serializer additions. Against an older
// backend they simply parse to null and the UI hides them.

// ── JSON helpers ────────────────────────────────────────────────────────────

String? _str(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

int? _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '');
}

bool _bool(dynamic v) => v is bool ? v : false;

DateTime? _date(dynamic v) {
  final s = _str(v);
  if (s == null) return null;
  return DateTime.tryParse(s)?.toLocal();
}

Map<String, dynamic>? _map(dynamic v) {
  if (v is Map) return Map<String, dynamic>.from(v);
  return null;
}

// ── Vocabulary (codes match the backend exactly) ────────────────────────────

class ReportStatus {
  ReportStatus._();
  static const pending = 'pending';
  static const reviewed = 'reviewed';
  static const actionTaken = 'action_taken';
  static const dismissed = 'dismissed';
  static const all = [pending, reviewed, actionTaken, dismissed];
}

class Severity {
  Severity._();
  static const low = 'low';
  static const medium = 'medium';
  static const high = 'high';
  static const critical = 'critical';
  static const all = [critical, high, medium, low]; // highest first

  /// Higher = more urgent. Unknown / missing sorts last.
  static int rank(String? s) {
    switch (s) {
      case critical:
        return 4;
      case high:
        return 3;
      case medium:
        return 2;
      case low:
        return 1;
      default:
        return 0;
    }
  }
}

class ReportCategory {
  ReportCategory._();
  static const all = [
    'spam',
    'harassment',
    'fraud',
    'fake_profile',
    'inappropriate_content',
    'payment_fraud',
    'off_platform_payment',
    'threats_safety',
    'discrimination',
    'service_misconduct',
    'other',
  ];
}

class ActionType {
  ActionType._();
  static const warning = 'warning';
  static const restrictMessaging = 'restrict_messaging';
  static const restrictBooking = 'restrict_booking';
  static const suspendTemporary = 'suspend_temporary';
  static const suspendPermanent = 'suspend_permanent';
  static const all = [
    warning,
    restrictMessaging,
    restrictBooking,
    suspendTemporary,
    suspendPermanent,
  ];

  static bool isSuspension(String t) =>
      t == suspendTemporary || t == suspendPermanent;

  /// Restrictions may optionally carry an end date; warnings never do;
  /// temporary suspensions require one; permanent suspensions forbid one.
  static bool allowsOptionalExpiry(String t) =>
      t == restrictMessaging || t == restrictBooking;
}

class ActionState {
  ActionState._();
  static const active = 'active';
  static const scheduled = 'scheduled';
  static const expired = 'expired';
  static const reversed = 'reversed';
}

class AppealStatus {
  AppealStatus._();
  static const pending = 'pending';
  static const approved = 'approved';
  static const rejected = 'rejected';
  static const all = [pending, approved, rejected];
}

// ── Related context ─────────────────────────────────────────────────────────

class BookingRef {
  final int id;
  final String status;
  final String? statusDisplay;
  final String? date;
  final String? time;
  final String? customerName;
  final String? professionalName;

  const BookingRef({
    required this.id,
    required this.status,
    this.statusDisplay,
    this.date,
    this.time,
    this.customerName,
    this.professionalName,
  });

  static BookingRef? fromJson(dynamic json) {
    final m = _map(json);
    if (m == null) return null;
    final id = _int(m['id']);
    if (id == null) return null;
    return BookingRef(
      id: id,
      status: _str(m['status']) ?? '',
      statusDisplay: _str(m['status_display']),
      date: _str(m['date']),
      time: _str(m['time']),
      customerName: _str(m['customer_name']),
      professionalName: _str(m['professional_name']),
    );
  }
}

class MessageRef {
  final int id;
  final int? conversationId;
  final int? senderId;
  final String? senderName;
  final String text;
  final DateTime? createdAt;
  final bool isDeleted;
  final int attachmentCount;

  const MessageRef({
    required this.id,
    this.conversationId,
    this.senderId,
    this.senderName,
    this.text = '',
    this.createdAt,
    this.isDeleted = false,
    this.attachmentCount = 0,
  });

  static MessageRef? fromJson(dynamic json) {
    final m = _map(json);
    if (m == null) return null;
    final id = _int(m['id']);
    if (id == null) return null;
    return MessageRef(
      id: id,
      conversationId: _int(m['conversation_id']),
      senderId: _int(m['sender_id']),
      senderName: _str(m['sender_name']),
      text: _str(m['text']) ?? '',
      createdAt: _date(m['created_at']),
      isDeleted: _bool(m['is_deleted']),
      attachmentCount: _int(m['attachment_count']) ?? 0,
    );
  }
}

// ── Report ──────────────────────────────────────────────────────────────────

class TsReport {
  final int id;
  final String category; // backend `reason` code
  final String? categoryDisplay;
  final String description;
  final String status;
  final String? statusDisplay;
  final String? severity; // null when the backend does not send it
  final String? evidenceUrl;
  final String adminNote; // INTERNAL — admin eyes only
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final String? reviewedByEmail;

  // Reporter identity — admin-only payload. Never surfaced to the reported user.
  final String reporterName;
  final String reporterEmail;

  final int reportedUserId;
  final String reportedUserName;
  final String reportedUserEmail;
  final String reportedUserRole;
  final bool reportedUserActive;

  final int? relatedBookingId;
  final BookingRef? relatedBooking;
  final int? relatedMessageId;
  final MessageRef? relatedMessage;

  const TsReport({
    required this.id,
    required this.category,
    this.categoryDisplay,
    this.description = '',
    required this.status,
    this.statusDisplay,
    this.severity,
    this.evidenceUrl,
    this.adminNote = '',
    this.createdAt,
    this.reviewedAt,
    this.reviewedByEmail,
    this.reporterName = '',
    this.reporterEmail = '',
    required this.reportedUserId,
    this.reportedUserName = '',
    this.reportedUserEmail = '',
    this.reportedUserRole = '',
    this.reportedUserActive = true,
    this.relatedBookingId,
    this.relatedBooking,
    this.relatedMessageId,
    this.relatedMessage,
  });

  bool get hasEvidence => evidenceUrl != null && evidenceUrl!.trim().isNotEmpty;
  bool get hasBooking => relatedBookingId != null;
  bool get hasMessage => relatedMessageId != null;
  bool get isResolved =>
      status == ReportStatus.actionTaken || status == ReportStatus.dismissed;
  bool get targetIsAdmin => reportedUserRole == 'admin';

  factory TsReport.fromJson(Map<String, dynamic> j) {
    return TsReport(
      id: _int(j['id']) ?? 0,
      category: _str(j['reason']) ?? 'other',
      categoryDisplay: _str(j['reason_display']),
      description: _str(j['description']) ?? '',
      status: _str(j['status']) ?? ReportStatus.pending,
      statusDisplay: _str(j['status_display']),
      severity: _str(j['severity']),
      evidenceUrl: _str(j['evidence_url']),
      adminNote: _str(j['admin_note']) ?? '',
      createdAt: _date(j['created_at']),
      reviewedAt: _date(j['reviewed_at']),
      reviewedByEmail: _str(j['reviewed_by_email']),
      reporterName: _str(j['reporter_name']) ?? '',
      reporterEmail: _str(j['reporter_email']) ?? '',
      reportedUserId: _int(j['reported_user']) ?? 0,
      reportedUserName: _str(j['reported_user_name']) ?? '',
      reportedUserEmail: _str(j['reported_user_email']) ?? '',
      reportedUserRole: _str(j['reported_user_role']) ?? '',
      // Older payloads always include this; default to "active" if absent.
      reportedUserActive: j['reported_user_active'] is bool
          ? j['reported_user_active'] as bool
          : true,
      relatedBookingId: _int(j['related_booking']),
      relatedBooking: BookingRef.fromJson(j['related_booking_detail']),
      relatedMessageId: _int(j['related_message']),
      relatedMessage: MessageRef.fromJson(j['related_message_detail']),
    );
  }
}

// ── Moderation action ───────────────────────────────────────────────────────

class ModerationAction {
  final int id;
  final String actionType;
  final String? actionTypeDisplay;
  final String state; // active | scheduled | expired | reversed
  final int? targetUserId;
  final String? targetUserName;
  final String? targetUserEmail;
  final int? reportId;
  final String? performedByName;
  final String? performedByEmail;
  final String reason; // user-facing text
  final String adminNote; // INTERNAL
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? reversedAt;
  final String? reversedByName;
  final String? reversedByEmail;
  final String reversalReason;
  final bool legacyBanApplied;

  const ModerationAction({
    required this.id,
    required this.actionType,
    this.actionTypeDisplay,
    required this.state,
    this.targetUserId,
    this.targetUserName,
    this.targetUserEmail,
    this.reportId,
    this.performedByName,
    this.performedByEmail,
    this.reason = '',
    this.adminNote = '',
    this.startsAt,
    this.expiresAt,
    this.createdAt,
    this.reversedAt,
    this.reversedByName,
    this.reversedByEmail,
    this.reversalReason = '',
    this.legacyBanApplied = false,
  });

  bool get isActive => state == ActionState.active;
  bool get isReversed => state == ActionState.reversed;

  /// The backend only accepts a reversal for actions that are neither
  /// reversed nor already expired.
  bool get isReversible =>
      state == ActionState.active || state == ActionState.scheduled;

  String get performedByLabel =>
      (performedByName != null && performedByName!.isNotEmpty)
          ? performedByName!
          : (performedByEmail ?? '');

  String get reversedByLabel =>
      (reversedByName != null && reversedByName!.isNotEmpty)
          ? reversedByName!
          : (reversedByEmail ?? '');

  factory ModerationAction.fromJson(Map<String, dynamic> j) {
    return ModerationAction(
      id: _int(j['id']) ?? 0,
      actionType: _str(j['action_type']) ?? '',
      actionTypeDisplay: _str(j['action_type_display']),
      state: _str(j['status']) ?? ActionState.active,
      targetUserId: _int(j['target_user']),
      targetUserName: _str(j['target_user_name']),
      targetUserEmail: _str(j['target_user_email']),
      reportId: _int(j['report']),
      performedByName: _str(j['performed_by_name']),
      performedByEmail: _str(j['performed_by_email']),
      reason: _str(j['reason']) ?? '',
      adminNote: _str(j['admin_note']) ?? '',
      startsAt: _date(j['starts_at']),
      expiresAt: _date(j['expires_at']),
      createdAt: _date(j['created_at']),
      reversedAt: _date(j['reversed_at']),
      reversedByName: _str(j['reversed_by_name']),
      reversedByEmail: _str(j['reversed_by_email']),
      reversalReason: _str(j['reversal_reason']) ?? '',
      legacyBanApplied: _bool(j['legacy_ban_applied']),
    );
  }
}

// ── Appeal ──────────────────────────────────────────────────────────────────

class TsAppeal {
  final int id;
  final String status;
  final String? statusDisplay;
  final int userId;
  final String userName;
  final String userEmail;
  final int moderationActionId;
  final ModerationAction? action;
  final int? reportId;
  final String reason; // written by the appealing user
  final String? evidenceUrl;
  final String? reviewedByName;
  final String? reviewedByEmail;
  final String decisionNote; // INTERNAL — never shown to the appealing user
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  const TsAppeal({
    required this.id,
    required this.status,
    this.statusDisplay,
    required this.userId,
    this.userName = '',
    this.userEmail = '',
    required this.moderationActionId,
    this.action,
    this.reportId,
    this.reason = '',
    this.evidenceUrl,
    this.reviewedByName,
    this.reviewedByEmail,
    this.decisionNote = '',
    this.createdAt,
    this.resolvedAt,
  });

  bool get isPending => status == AppealStatus.pending;
  bool get hasEvidence => evidenceUrl != null && evidenceUrl!.trim().isNotEmpty;

  String get reviewedByLabel =>
      (reviewedByName != null && reviewedByName!.isNotEmpty)
          ? reviewedByName!
          : (reviewedByEmail ?? '');

  factory TsAppeal.fromJson(Map<String, dynamic> j) {
    final actionJson = _map(j['moderation_action_detail']);
    return TsAppeal(
      id: _int(j['id']) ?? 0,
      status: _str(j['status']) ?? AppealStatus.pending,
      statusDisplay: _str(j['status_display']),
      userId: _int(j['user']) ?? 0,
      userName: _str(j['user_name']) ?? '',
      userEmail: _str(j['user_email']) ?? '',
      moderationActionId: _int(j['moderation_action']) ?? 0,
      action: actionJson == null ? null : ModerationAction.fromJson(actionJson),
      reportId: _int(j['report']),
      reason: _str(j['reason']) ?? '',
      evidenceUrl: _str(j['evidence_url']),
      reviewedByName: _str(j['reviewed_by_name']),
      reviewedByEmail: _str(j['reviewed_by_email']),
      decisionNote: _str(j['decision_note']) ?? '',
      createdAt: _date(j['created_at']),
      resolvedAt: _date(j['resolved_at']),
    );
  }
}