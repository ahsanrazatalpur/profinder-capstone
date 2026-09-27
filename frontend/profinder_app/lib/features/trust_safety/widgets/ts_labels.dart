// lib/features/trust_safety/widgets/ts_labels.dart
//
// Small, localization-only helpers shared across the user-facing Trust &
// Safety screens (My Reports, Account Status, appeal form). Kept in this
// feature (rather than importing admin's features/admin/widgets/ts_ui.dart)
// so the customer/professional UI has no dependency on admin-only code —
// but the *localization keys* used are deliberately the same `tsCat*`,
// `tsStatus*`, `tsAct*`, `tsAppeal*` ones the admin UI already defined
// (see ts_ui.dart's tsActionTypeLabel for the admin-side equivalent), so a
// category/status/action-type always reads identically everywhere in the
// app — just one localized label per code.

import '../../../l10n/generated/app_localizations.dart';
import '../models/user_ts_models.dart';

String reportCategoryLabel(AppLocalizations t, String code) {
  switch (code) {
    case ReportCategory.spam: return t.tsCatSpam;
    case ReportCategory.harassment: return t.tsCatHarassment;
    case ReportCategory.fraud: return t.tsCatFraud;
    case ReportCategory.fakeProfile: return t.tsCatFakeProfile;
    case ReportCategory.inappropriateContent: return t.tsCatInappropriate;
    case ReportCategory.paymentFraud: return t.tsCatPaymentFraud;
    case ReportCategory.offPlatformPayment: return t.tsCatOffPlatform;
    case ReportCategory.threatsSafety: return t.tsCatThreats;
    case ReportCategory.discrimination: return t.tsCatDiscrimination;
    case ReportCategory.serviceMisconduct: return t.tsCatMisconduct;
    default: return t.tsCatOther;
  }
}

String reportStatusLabel(AppLocalizations t, String status) {
  switch (status) {
    case MyReportStatus.pending: return t.tsStatusPending;
    case MyReportStatus.reviewed: return t.tsStatusReviewed;
    case MyReportStatus.actionTaken: return t.tsStatusActionTaken;
    case MyReportStatus.dismissed: return t.tsStatusDismissed;
    default: return status;
  }
}

String reportOutcomeLabel(AppLocalizations t, String outcome) {
  switch (outcome) {
    case MyReportOutcome.reviewedNoAction: return t.myTsOutcomeReviewedNoAction;
    case MyReportOutcome.actionTaken: return t.myTsOutcomeActionTaken;
    case MyReportOutcome.dismissed: return t.myTsOutcomeDismissed;
    default: return t.myTsOutcomePending;
  }
}

/// Mirrors admin's `tsActionTypeLabel` (features/admin/widgets/ts_ui.dart)
/// so an action type reads identically whether an admin or the affected
/// user is looking at it — same localization keys, just duplicated here to
/// avoid a user-facing screen depending on admin-only code.
String moderationActionTypeLabel(AppLocalizations t, String code, {String? fallback}) {
  switch (code) {
    case ModerationActionType.warning: return t.tsActWarning;
    case ModerationActionType.restrictMessaging: return t.tsActRestrictMessaging;
    case ModerationActionType.restrictBooking: return t.tsActRestrictBooking;
    case ModerationActionType.suspendTemporary: return t.tsActSuspendTemporary;
    case ModerationActionType.suspendPermanent: return t.tsActSuspendPermanent;
    default: return (fallback != null && fallback.isNotEmpty) ? fallback : code;
  }
}

String appealStatusLabel(AppLocalizations t, String status) {
  switch (status) {
    case MyAppealStatus.approved: return t.tsAppealApproved;
    case MyAppealStatus.rejected: return t.tsAppealRejected;
    default: return t.tsAppealPending;
  }
}