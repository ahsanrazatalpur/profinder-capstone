# apps/admin_panel/moderation_notifications.py
"""
Moderation notifications (Trust & Safety Part 5).

Everything here goes through the EXISTING notification infrastructure:
`apps.notifications.utils.notify_user` / `notify_admins`, which write a row to
the existing `Notification` model (type 'report', already defined) and push via
the existing FCM helper. No new provider, model or notification type.

PRINCIPLES
----------
* The database is the source of truth, not the notification. Each sender takes
  an id and RE-READS the row when it runs, so what a user is told always
  reflects current state (e.g. no "you're restricted" push for an action that
  was reversed a moment later). Notification text is informational only;
  nothing in the system reads a Notification to decide what is enforced.
* Callers schedule these with `transaction.on_commit`, so nothing is sent for a
  transaction that rolls back, and the FCM network call never runs while
  moderation rows are locked.
* A notification failure must NEVER break or roll back a moderation action.
  Every public function here swallows and logs its own errors.

PRIVACY (what a notification to the affected user may contain)
--------------------------------------------------------------
ALLOWED : the action type, the admin-provided `reason`, start/end times,
          the action's own id.
NEVER   : the reporter's identity (name/email/id), the report id, the internal
          `admin_note`, the acting admin's identity, the reversal reason, or
          anything about any other user's moderation history.
`reason` is written by an admin and shown to the user, so it is also scrubbed of
the linked report's reporter name/email as a best-effort safety net.
"""
import logging
import re
from datetime import timezone as dt_timezone

from apps.admin_panel.models import Appeal, ModerationAction, UserReport
from apps.notifications.utils import notify_admins, notify_user

logger = logging.getLogger(__name__)

# The appeal BACKEND exists (Part 6), but there is no in-app way to file one
# until the Flutter UI ships. Keep this False until then, so no notification
# tells a user to do something they can't yet do. Flipping it to True is the
# only change needed: `_appeal_line` below is already wired into every
# action notification.
APPEALS_AVAILABLE = True

NOTIF_TYPE = 'report'          # existing 'Report / Moderation' type
_REASON_MAX = 500              # keep push/DB text reasonable

GENERIC_REASON = 'Violation of our community guidelines.'

# action_type -> (title, event, noun used in the "lifted" message)
_KIND = {
    ModerationAction.ACTION_WARNING:
        ('Community Guidelines Warning', 'warning_issued', 'warning'),
    ModerationAction.ACTION_RESTRICT_MESSAGING:
        ('Messaging Restricted', 'messaging_restricted', 'messaging restriction'),
    ModerationAction.ACTION_RESTRICT_BOOKING:
        ('Booking Restricted', 'booking_restricted', 'booking restriction'),
    ModerationAction.ACTION_SUSPEND_TEMPORARY:
        ('Account Temporarily Suspended', 'account_suspended', 'temporary suspension'),
    ModerationAction.ACTION_SUSPEND_PERMANENT:
        ('Account Permanently Suspended', 'account_suspended', 'permanent suspension'),
}

# Reversing these tells the user something is restored. Retracting a bare
# warning restricts nothing, so it is deliberately not announced.
_REVERSAL_NOTIFIED = (
    ModerationAction.ACTION_RESTRICT_MESSAGING,
    ModerationAction.ACTION_RESTRICT_BOOKING,
    ModerationAction.ACTION_SUSPEND_TEMPORARY,
    ModerationAction.ACTION_SUSPEND_PERMANENT,
)


# ── text helpers ─────────────────────────────────────────────────────────────

def _fmt_dt(value):
    return value.astimezone(dt_timezone.utc).strftime('%d %b %Y, %H:%M UTC')


def _sentence(text):
    text = (text or '').strip()
    return text if text[-1:] in '.!?' else text + '.'


def _truncate(text, limit=_REASON_MAX):
    text = (text or '').strip()
    return text if len(text) <= limit else text[: limit - 1].rstrip() + '…'


def _user_facing_reason(action):
    """
    The admin-provided reason, made safe to show to the affected user:
    the linked report's reporter name/email (if an admin typed them into the
    reason) is redacted. Best-effort only — the real protection is that
    `reason` is a user-facing field and `admin_note` is never used here.
    """
    reason = (action.reason or '').strip() or GENERIC_REASON
    report = action.report
    if report is not None and report.reporter_id:
        reporter = report.reporter
        for needle in {(reporter.email or '').strip(), (reporter.name or '').strip()}:
            if len(needle) >= 3:
                reason = re.sub(re.escape(needle), '[redacted]', reason, flags=re.IGNORECASE)
    return _truncate(reason)


def _appeal_line():
    # Empty until the client can actually file an appeal (see APPEALS_AVAILABLE).
    if not APPEALS_AVAILABLE:
        return ''
    return 'If you believe this was a mistake, you can submit an appeal.'


# ── message builders (pure: action in -> (title, message, data) out) ─────────

def build_action_notification(action):
    title, event, _noun = _KIND[action.action_type]
    reason = _user_facing_reason(action)
    t = action.action_type

    if t == ModerationAction.ACTION_WARNING:
        parts = [
            'Our moderation team reviewed activity on your account and found a '
            'violation of our community guidelines.',
            f'Reason: {_sentence(reason)}',
            'This is a warning only and your access is not affected, but further '
            'violations may lead to restrictions or suspension.',
        ]
    elif t == ModerationAction.ACTION_RESTRICT_MESSAGING:
        parts = [
            'Our moderation team reviewed your account and restricted your ability '
            'to send messages.',
            f'Reason: {_sentence(reason)}',
            _restriction_status(action),
            'This restriction applies to messaging only.',
        ]
    elif t == ModerationAction.ACTION_RESTRICT_BOOKING:
        parts = [
            'Our moderation team reviewed your account and restricted your ability '
            'to create new bookings.',
            f'Reason: {_sentence(reason)}',
            _restriction_status(action),
            'This restriction applies to creating new bookings only.',
        ]
    elif t == ModerationAction.ACTION_SUSPEND_TEMPORARY:
        parts = [
            'Your account has been temporarily suspended after our moderation team '
            'found a violation of our community guidelines.',
            f'Reason: {_sentence(reason)}',
            f'Suspension started: {_fmt_dt(action.starts_at)}.',
            f'Suspension ends: {_fmt_dt(action.expires_at)}.',
        ]
    else:  # ACTION_SUSPEND_PERMANENT
        parts = [
            'Your account has been permanently suspended after our moderation team '
            'found a serious violation of our community guidelines.',
            f'Reason: {_sentence(reason)}',
            f'Suspension started: {_fmt_dt(action.starts_at)}.',
            'This suspension has no end date.',
        ]

    parts.append(_appeal_line())
    message = ' '.join(p for p in parts if p)

    data = {
        'event': event,
        'moderation_action_id': action.pk,
        'action_type': action.action_type,
        'status': 'active',
    }
    if action.expires_at:
        data['expires_at'] = action.expires_at.isoformat()
    return title, message, data


def _restriction_status(action):
    if action.expires_at:
        return f'Status: Active until {_fmt_dt(action.expires_at)}.'
    return 'Status: Active. No end date has been set.'


def build_reversal_notification(action):
    _title, _event, noun = _KIND[action.action_type]
    is_suspension = action.action_type in (
        ModerationAction.ACTION_SUSPEND_TEMPORARY,
        ModerationAction.ACTION_SUSPEND_PERMANENT)
    title = 'Suspension Lifted' if is_suspension else 'Restriction Lifted'
    # Deliberately neutral: the reversal reason is internal, and other actions
    # may still be in force, so this claims nothing beyond "this one is lifted".
    message = f'The {noun} on your account has been lifted by our moderation team.'
    data = {
        'event': 'suspension_lifted' if is_suspension else 'restriction_lifted',
        'moderation_action_id': action.pk,
        'action_type': action.action_type,
        'status': 'reversed',
    }
    return title, message, data


# ── senders (called via transaction.on_commit; never raise) ──────────────────

def _load(action_id):
    return (ModerationAction.objects
            .select_related('target_user', 'report', 'report__reporter')
            .filter(pk=action_id).first())


def notify_action_created(action_id):
    """Tell the affected user (only) that a moderation action was applied."""
    try:
        action = _load(action_id)
        # Source of truth is the DB: if it was reversed before we got here,
        # don't announce a restriction that no longer exists.
        if action is None or not action.is_active:
            return
        title, message, data = build_action_notification(action)
        notify_user(action.target_user, title, message, notif_type=NOTIF_TYPE, data=data)
    except Exception:
        logger.exception('[MODERATION-NOTIFY] failed for created action %s', action_id)


def notify_action_reversed(action_id):
    """Tell the affected user that a restriction/suspension was lifted."""
    try:
        action = _load(action_id)
        if (action is None or action.is_active
                or action.action_type not in _REVERSAL_NOTIFIED):
            return
        title, message, data = build_reversal_notification(action)
        notify_user(action.target_user, title, message, notif_type=NOTIF_TYPE, data=data)
    except Exception:
        logger.exception('[MODERATION-NOTIFY] failed for reversed action %s', action_id)


def notify_admins_of_new_report(report_id):
    """
    Alert admins to a newly submitted Trust & Safety report. Uses the existing
    `notify_admins` helper (same as the messaging report flow), so it lands in
    every admin's normal notification list + push.
    """
    try:
        report = (UserReport.objects.select_related('reported_user')
                  .filter(pk=report_id).first())
        if report is None:
            return
        notify_admins(
            title='New Report Submitted',
            message=(f'A new report ({report.get_reason_display()}) was filed against '
                     f'{report.reported_user.name} — review required.'),
            notif_type=NOTIF_TYPE,
            data={'report_id': report.pk, 'event': 'report_submitted',
                  'severity': report.severity},
        )
    except Exception:
        logger.exception('[MODERATION-NOTIFY] failed for new report %s', report_id)


# ── Appeals (Trust & Safety Part 6) ──────────────────────────────────────────
# Same rules as above: the user only ever sees their OWN appeal's outcome, never
# the internal decision note, the deciding admin, or the report behind the
# action. Text is fixed; nothing free-form from an admin is interpolated.

def _load_appeal(appeal_id):
    return (Appeal.objects
            .select_related('user', 'moderation_action')
            .filter(pk=appeal_id).first())


def notify_appeal_submitted(appeal_id):
    """
    Confirm receipt to the appealing user, and alert admins that a new appeal
    needs review (same pattern as a new report). Skipped if it's no longer
    pending — the DB, not this message, is the source of truth.
    """
    try:
        appeal = _load_appeal(appeal_id)
        if appeal is None or appeal.status != Appeal.STATUS_PENDING:
            return
        action = appeal.moderation_action
        _title, _event, noun = _KIND[action.action_type]

        try:
            notify_user(
                appeal.user,
                title='Appeal Submitted',
                message=(f"We've received your appeal about the {noun} on your account. "
                         "Our team will review it and you'll be notified when a decision is made."),
                notif_type=NOTIF_TYPE,
                data={'event': 'appeal_submitted', 'appeal_id': appeal.pk,
                      'moderation_action_id': action.pk, 'status': appeal.status},
            )
        except Exception:
            logger.exception('[APPEAL-NOTIFY] user confirmation failed for appeal %s', appeal_id)

        notify_admins(
            title='New Appeal Submitted',
            message=(f'{appeal.user.name} appealed a {action.get_action_type_display().lower()} '
                     '— review required.'),
            notif_type=NOTIF_TYPE,
            data={'event': 'appeal_submitted', 'appeal_id': appeal.pk,
                  'moderation_action_id': action.pk},
        )
    except Exception:
        logger.exception('[APPEAL-NOTIFY] failed for submitted appeal %s', appeal_id)


def notify_appeal_resolved(appeal_id):
    """Tell the appealing user (only) whether their appeal was approved or rejected."""
    try:
        appeal = _load_appeal(appeal_id)
        if appeal is None or appeal.status == Appeal.STATUS_PENDING:
            return
        action = appeal.moderation_action
        _title, _event, noun = _KIND[action.action_type]

        if appeal.status == Appeal.STATUS_APPROVED:
            title = 'Appeal Approved'
            message = (f'Your appeal was reviewed and approved. '
                       f'The {noun} on your account has been lifted.')
        else:
            title = 'Appeal Decision'
            message = (f"Your appeal was reviewed and we've decided to keep the "
                       f'{noun} on your account in place.')

        notify_user(
            appeal.user, title, message, notif_type=NOTIF_TYPE,
            data={'event': f'appeal_{appeal.status}', 'appeal_id': appeal.pk,
                  'moderation_action_id': action.pk, 'status': appeal.status},
        )
    except Exception:
        logger.exception('[APPEAL-NOTIFY] failed for resolved appeal %s', appeal_id)