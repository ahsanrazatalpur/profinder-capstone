// lib/features/trust_safety/models/user_ts_models.dart
//
// Trust & Safety (USER-facing, Part 8) — typed models for:
//   GET /admin-panel/reports/mine/              → MyReport
//   GET /admin-panel/moderation-status/mine/    → MyModerationStatus
//   GET /admin-panel/appeals/mine/              → MyAppeal
//   POST /admin-panel/appeals/create/           → MyAppeal
//
// These are DELIBERATELY narrower than the admin-facing models in
// features/admin/models/ts_models.dart: the backend serializers behind
// these endpoints never send the reported user's identity, internal admin
// notes, the reviewing admin's identity, or the exact punishment handed to
// someone else. Nothing here re-adds those fields — if the backend doesn't
// send it, it isn't parsed.

// ── JSON helpers (same conventions as the admin ts_models.dart) ────────────

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

// ── Vocabulary (codes match the backend exactly) ────────────────────────────

class MyReportStatus {
  MyReportStatus._();
  static const pending = 'pending';
  static const reviewed = 'reviewed';
  static const actionTaken = 'action_taken';
  static const dismissed = 'dismissed';
  static const all = [pending, reviewed, actionTaken, dismissed];
}

/// General, non-specific outcome codes — see MyUserReportSerializer.get_outcome
/// on the backend. Never reveals the reported user's actual punishment.
class MyReportOutcome {
  MyReportOutcome._();
  static const pending = 'pending';
  static const reviewedNoAction = 'reviewed_no_action';
  static const actionTaken = 'action_taken';
  static const dismissed = 'dismissed';
}

/// Report categories — matches apps.admin_panel.models.UserReport
/// .REASON_CHOICES exactly (Part 7 additions included).
class ReportCategory {
  ReportCategory._();
  static const spam = 'spam';
  static const harassment = 'harassment';
  static const fraud = 'fraud';
  static const fakeProfile = 'fake_profile';
  static const inappropriateContent = 'inappropriate_content';
  static const paymentFraud = 'payment_fraud';
  static const offPlatformPayment = 'off_platform_payment';
  static const threatsSafety = 'threats_safety';
  static const discrimination = 'discrimination';
  static const serviceMisconduct = 'service_misconduct';
  static const other = 'other';
  static const all = [
    spam,
    harassment,
    fraud,
    fakeProfile,
    inappropriateContent,
    paymentFraud,
    offPlatformPayment,
    threatsSafety,
    discrimination,
    serviceMisconduct,
    other,
  ];
}

class ModerationActionType {
  ModerationActionType._();
  static const warning = 'warning';
  static const restrictMessaging = 'restrict_messaging';
  static const restrictBooking = 'restrict_booking';
  static const suspendTemporary = 'suspend_temporary';
  static const suspendPermanent = 'suspend_permanent';

  static bool isSuspension(String t) => t == suspendTemporary || t == suspendPermanent;
  static bool isRestriction(String t) => t == restrictMessaging || t == restrictBooking;
}

class MyAppealStatus {
  MyAppealStatus._();
  static const pending = 'pending';
  static const approved = 'approved';
  static const rejected = 'rejected';
  static const all = [pending, approved, rejected];
}

// ── My Report ────────────────────────────────────────────────────────────

/// A report the CURRENT user submitted about someone else. Only what
/// MyUserReportSerializer sends: no reported-user identity, no admin note,
/// no reviewer identity, no exact punishment — see that serializer's
/// docstring on the backend for the full list of what is never included.
class MyReport {
  final int id;
  final String category; // backend `reason` code
  final String? categoryDisplay;
  final String description;
  final String status;
  final String? statusDisplay;
  final String outcome; // general/non-specific — see MyReportOutcome
  final DateTime? createdAt;

  const MyReport({
    required this.id,
    required this.category,
    this.categoryDisplay,
    this.description = '',
    required this.status,
    this.statusDisplay,
    this.outcome = MyReportOutcome.pending,
    this.createdAt,
  });

  bool get isPending => status == MyReportStatus.pending;
  bool get isResolved => status == MyReportStatus.actionTaken || status == MyReportStatus.dismissed;

  factory MyReport.fromJson(Map<String, dynamic> j) {
    return MyReport(
      id: _int(j['id']) ?? 0,
      category: _str(j['category']) ?? ReportCategory.other,
      categoryDisplay: _str(j['category_display']),
      description: _str(j['description']) ?? '',
      status: _str(j['status']) ?? MyReportStatus.pending,
      statusDisplay: _str(j['status_display']),
      outcome: _str(j['outcome']) ?? MyReportOutcome.pending,
      createdAt: _date(j['created_at']),
    );
  }
}

// ── My moderation action (an action currently in force against ME) ─────────

class MyModerationAction {
  final int id;
  final String actionType;
  final String? actionTypeDisplay;
  final String status; // always "active" for what this endpoint returns
  final String reason; // why this was done — shown to the affected user
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final bool canAppeal;
  final bool hasPendingAppeal;

  const MyModerationAction({
    required this.id,
    required this.actionType,
    this.actionTypeDisplay,
    this.status = 'active',
    this.reason = '',
    this.startsAt,
    this.expiresAt,
    this.createdAt,
    this.canAppeal = false,
    this.hasPendingAppeal = false,
  });

  bool get isWarning => actionType == ModerationActionType.warning;
  bool get isSuspension => ModerationActionType.isSuspension(actionType);
  bool get isRestriction => ModerationActionType.isRestriction(actionType);
  bool get isTemporarySuspension => actionType == ModerationActionType.suspendTemporary;
  bool get isPermanentSuspension => actionType == ModerationActionType.suspendPermanent;
  bool get isMessagingRestriction => actionType == ModerationActionType.restrictMessaging;
  bool get isBookingRestriction => actionType == ModerationActionType.restrictBooking;

  factory MyModerationAction.fromJson(Map<String, dynamic> j) {
    return MyModerationAction(
      id: _int(j['id']) ?? 0,
      actionType: _str(j['action_type']) ?? '',
      actionTypeDisplay: _str(j['action_type_display']),
      status: _str(j['status']) ?? 'active',
      reason: _str(j['reason']) ?? '',
      startsAt: _date(j['starts_at']),
      expiresAt: _date(j['expires_at']),
      createdAt: _date(j['created_at']),
      canAppeal: _bool(j['can_appeal']),
      hasPendingAppeal: _bool(j['has_pending_appeal']),
    );
  }
}

/// A single, consistent snapshot of the CURRENT user's moderation state —
/// always fetched fresh from the backend (see UserTrustSafetyService),
/// never derived from local/cached state.
class MyModerationStatus {
  final bool isSuspended;
  final bool isPermanentlySuspended;
  final bool isTemporarilySuspended;
  final bool messagingRestricted;
  final bool bookingRestricted;
  final bool hasActiveWarning;
  final List<MyModerationAction> actions;

  const MyModerationStatus({
    this.isSuspended = false,
    this.isPermanentlySuspended = false,
    this.isTemporarilySuspended = false,
    this.messagingRestricted = false,
    this.bookingRestricted = false,
    this.hasActiveWarning = false,
    this.actions = const [],
  });

  bool get isInGoodStanding => actions.isEmpty;

  const MyModerationStatus.empty() : this();

  factory MyModerationStatus.fromJson(Map<String, dynamic> j) {
    final list = j['actions'] is List ? List<dynamic>.from(j['actions']) : const [];
    return MyModerationStatus(
      isSuspended: _bool(j['is_suspended']),
      isPermanentlySuspended: _bool(j['is_permanently_suspended']),
      isTemporarilySuspended: _bool(j['is_temporarily_suspended']),
      messagingRestricted: _bool(j['messaging_restricted']),
      bookingRestricted: _bool(j['booking_restricted']),
      hasActiveWarning: _bool(j['has_active_warning']),
      actions: list
          .whereType<Map>()
          .map((m) => MyModerationAction.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }
}

// ── My appeal ────────────────────────────────────────────────────────────

/// What the appealing user sees about their own appeal. Deliberately
/// excludes decision_note and reviewer identity — see MyAppealSerializer on
/// the backend.
class MyAppeal {
  final int id;
  final int moderationActionId;
  final String actionType;
  final String? actionTypeDisplay;
  final String actionReason;
  final String actionStatus; // active | scheduled | expired | reversed
  final String reason; // written by the appealing user
  final String? evidenceUrl;
  final String status;
  final String? statusDisplay;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  const MyAppeal({
    required this.id,
    required this.moderationActionId,
    this.actionType = '',
    this.actionTypeDisplay,
    this.actionReason = '',
    this.actionStatus = '',
    this.reason = '',
    this.evidenceUrl,
    required this.status,
    this.statusDisplay,
    this.createdAt,
    this.resolvedAt,
  });

  bool get isPending => status == MyAppealStatus.pending;
  bool get isApproved => status == MyAppealStatus.approved;
  bool get isRejected => status == MyAppealStatus.rejected;
  bool get hasEvidence => evidenceUrl != null && evidenceUrl!.trim().isNotEmpty;

  factory MyAppeal.fromJson(Map<String, dynamic> j) {
    return MyAppeal(
      id: _int(j['id']) ?? 0,
      moderationActionId: _int(j['moderation_action']) ?? 0,
      actionType: _str(j['action_type']) ?? '',
      actionTypeDisplay: _str(j['action_type_display']),
      actionReason: _str(j['action_reason']) ?? '',
      actionStatus: _str(j['action_status']) ?? '',
      reason: _str(j['reason']) ?? '',
      evidenceUrl: _str(j['evidence_url']),
      status: _str(j['status']) ?? MyAppealStatus.pending,
      statusDisplay: _str(j['status_display']),
      createdAt: _date(j['created_at']),
      resolvedAt: _date(j['resolved_at']),
    );
  }
}