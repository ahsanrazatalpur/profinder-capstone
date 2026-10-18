# apps/admin_panel/moderation.py
"""
Moderation action service layer (Trust & Safety Part 4).

This is the ONE place where `ModerationAction` rows are created and
reversed. Both the new admin moderation API and the legacy
`AdminReportActionView` (`ban_user` flag) call into here, so there is a
single moderation system rather than two that can drift apart.

What this module deliberately does NOT do
-----------------------------------------
* It does not add enforcement. Whether a user is actually blocked from
  messaging/booking is still decided solely by `apps.admin_panel
  .enforcement` (Part 3), which reads the rows written here. Creating a
  `suspend_*` action here does NOT touch `User.is_active` — the only
  exception is the legacy `ban_user` bridge (see `record_legacy_report_ban`),
  which preserves the pre-existing behaviour of that flag exactly.
* It knows nothing about appeals.

Notifications (Part 5) are scheduled here with `transaction.on_commit` and
sent by `moderation_notifications`. Scheduling lives in this one layer so every
path — the new API, the legacy report ban, the legacy unban — notifies exactly
once per state change, and never for a transaction that rolled back.

Every write happens inside `transaction.atomic()` together with its
`AdminLog` row, so an action can never exist without its audit entry (or
vice versa).
"""
from django.db import transaction
from django.utils import timezone

from apps.admin_panel.enforcement import _is_effectively_active, get_active_actions
from apps.admin_panel import moderation_notifications
from apps.admin_panel.models import AdminLog, ModerationAction
from apps.users.models import User


# ── Errors ────────────────────────────────────────────────────────────────────
# Views translate these to `{'error': <message>}` + `status_code`, matching the
# error shape used by the rest of the admin panel.

class ModerationError(Exception):
    status_code = 400

    def __init__(self, message):
        super().__init__(message)
        self.message = message


class ModerationNotFound(ModerationError):
    status_code = 404


class ModerationConflict(ModerationError):
    """The request is well-formed but clashes with the current state."""
    status_code = 409


# Action types that only make sense with no expiry / an expiry.
_RESTRICTIONS = (
    ModerationAction.ACTION_RESTRICT_MESSAGING,
    ModerationAction.ACTION_RESTRICT_BOOKING,
)
_SUSPENSIONS = (
    ModerationAction.ACTION_SUSPEND_TEMPORARY,
    ModerationAction.ACTION_SUSPEND_PERMANENT,
)

_NOTE_REASON_LIMIT = 300  # keep AdminLog.note readable; full text lives on the action


# ── Status helper (used by serializer + history filters) ─────────────────────

STATUS_ACTIVE    = 'active'     # in force right now
STATUS_SCHEDULED = 'scheduled'  # active flag set but starts_at is in the future
STATUS_EXPIRED   = 'expired'    # ran its course (expires_at passed) — never reversed
STATUS_REVERSED  = 'reversed'   # an admin deactivated it
STATUS_CHOICES   = (STATUS_ACTIVE, STATUS_SCHEDULED, STATUS_EXPIRED, STATUS_REVERSED)


def action_status(action: ModerationAction, now=None) -> str:
    """
    Human-meaningful lifecycle state, derived on every call (never stored) so
    it can't go stale. 'active' defers to Part 3's `_is_effectively_active`
    so this API and enforcement can never disagree about what is in force.
    """
    now = now or timezone.now()
    if not action.is_active:
        return STATUS_REVERSED
    if _is_effectively_active(action, now):
        return STATUS_ACTIVE
    if action.starts_at and action.starts_at > now:
        return STATUS_SCHEDULED
    return STATUS_EXPIRED


def _notify_after_commit(sender, action_id):
    """
    Run a notification sender once the surrounding transaction commits (or
    immediately if there isn't one). If the transaction rolls back, nothing is
    sent. Senders re-read the DB and swallow their own errors.
    """
    transaction.on_commit(lambda: sender(action_id))


def _trim(text, limit=_NOTE_REASON_LIMIT):
    text = (text or '').strip()
    return text if len(text) <= limit else text[: limit - 1] + '…'


# ── Create ────────────────────────────────────────────────────────────────────

@transaction.atomic
def create_moderation_action(*, admin, target_user, action_type, reason,
                             admin_note='', report=None, expires_at=None,
                             legacy_ban_applied=False, write_log=True,
                             skip_duplicate_check=False):
    """
    Create a moderation action and its audit-log entry atomically.

    `admin` is always taken from the authenticated request by the caller;
    `is_active`, `starts_at` and `created_at` are never parameters, so no
    caller (and therefore no client) can set them. New actions always begin
    active, effective immediately.

    `skip_duplicate_check` exists solely for the legacy report `ban_user`
    bridge, which must keep working exactly as before even if the user already
    holds an equivalent action created through the new API.

    Raises ModerationError (400) / ModerationConflict (409).
    """
    if action_type not in dict(ModerationAction.ACTION_CHOICES):
        raise ModerationError('Unsupported action_type.')
    reason = (reason or '').strip()
    if not reason:
        raise ModerationError('A reason is required.')

    now = timezone.now()

    # Defence in depth: the serializer already checks these, but this function
    # is also called from non-serializer paths, and the DB CheckConstraints are
    # a last resort that would surface as an unfriendly 500.
    if action_type == ModerationAction.ACTION_SUSPEND_TEMPORARY:
        if expires_at is None:
            raise ModerationError('Temporary suspensions require expires_at.')
    if action_type == ModerationAction.ACTION_SUSPEND_PERMANENT and expires_at is not None:
        raise ModerationError('Permanent suspensions must not have expires_at.')
    if expires_at is not None and expires_at <= now:
        raise ModerationError('expires_at must be in the future.')

    # Lock the target row so two admins acting at the same instant can't both
    # pass the duplicate check below (no-op on SQLite, effective on Postgres).
    target = User.objects.select_for_update().get(pk=target_user.pk)

    if report is not None and report.reported_user_id != target.pk:
        raise ModerationError('The report is about a different user than the target.')

    # ── Obviously-invalid combinations, judged against what is in force now ──
    active = [] if skip_duplicate_check else get_active_actions(target)
    if action_type != ModerationAction.ACTION_WARNING:
        # Warnings may stack (they're a record, they block nothing); a second
        # identical restriction/suspension would just be noise.
        if any(a.action_type == action_type for a in active):
            label = dict(ModerationAction.ACTION_CHOICES)[action_type]
            raise ModerationConflict(
                f'This user already has an active "{label}". '
                f'Reverse it first if you need to replace it.')
    if action_type == ModerationAction.ACTION_SUSPEND_TEMPORARY and any(
            a.action_type == ModerationAction.ACTION_SUSPEND_PERMANENT for a in active):
        raise ModerationConflict(
            'This user is already permanently suspended; a temporary '
            'suspension would be meaningless.')

    action = ModerationAction(
        report=report,
        target_user=target,
        performed_by=admin,
        action_type=action_type,
        reason=reason,
        admin_note=(admin_note or '').strip(),
        starts_at=now,
        expires_at=expires_at,
        is_active=True,
        legacy_ban_applied=legacy_ban_applied,
    )
    action.clean()   # model-level invariants (expiry rules)
    action.save()

    if write_log:
        label = action.get_action_type_display()
        parts = [f'{label} (#{action.pk})']
        if report is not None:
            parts.append(f'report #{report.pk}')
        if expires_at is not None:
            parts.append(f'expires {expires_at.isoformat()}')
        parts.append(f'reason: {_trim(reason)}')
        AdminLog.objects.create(
            admin=admin, action='moderation_action', target_user=target,
            note=' | '.join(parts))

    _notify_after_commit(moderation_notifications.notify_action_created, action.pk)
    return action


# ── Reverse ───────────────────────────────────────────────────────────────────

@transaction.atomic
def reverse_moderation_action(*, admin, action_id, reason, notify=True):
    """
    Deactivate an action while preserving its record. The row is never
    deleted; `is_active` flips to False and who/when/why are stored.

    `notify=False` suppresses the generic "restriction/suspension lifted"
    notification. Only the appeal-approval flow uses it, because there the user
    receives a single, more specific "Appeal Approved" notification instead.

    Raises ModerationNotFound (404), ModerationConflict (409) if it was
    already reversed, or ModerationError (400) if it has already expired
    naturally (nothing left to reverse).
    """
    reason = (reason or '').strip()
    if not reason:
        raise ModerationError('A reversal reason is required.')

    try:
        action = (ModerationAction.objects.select_for_update()
                  .select_related('target_user').get(pk=action_id))
    except ModerationAction.DoesNotExist:
        raise ModerationNotFound('Moderation action not found.')

    now = timezone.now()
    state = action_status(action, now)
    if state == STATUS_REVERSED:
        raise ModerationConflict('This moderation action has already been reversed.')
    if state == STATUS_EXPIRED:
        raise ModerationError(
            'This moderation action has already expired; there is nothing to reverse.')

    action.is_active = False
    action.reversed_at = now
    action.reversed_by = admin
    action.reversal_reason = reason
    action.save(update_fields=['is_active', 'reversed_at', 'reversed_by', 'reversal_reason'])

    AdminLog.objects.create(
        admin=admin, action='moderation_reversed', target_user=action.target_user,
        note=f'Reversed {action.get_action_type_display()} (#{action.pk}) | '
             f'reason: {_trim(reason)}')

    # Legacy bridge: a record born from the report `ban_user` flow also set
    # User.is_active=False. Restore it so reversing the record actually
    # restores the account — but only if no OTHER legacy-banned record is
    # still in force for this user.
    if action.legacy_ban_applied:
        _restore_account_if_no_legacy_ban_left(action.target_user, admin,
                                               note=f'Moderation action #{action.pk} reversed')

    if notify:
        _notify_after_commit(moderation_notifications.notify_action_reversed, action.pk)
    return action


def _restore_account_if_no_legacy_ban_left(user, admin, note):
    still_banned = any(a.legacy_ban_applied for a in get_active_actions(user))
    if still_banned or user.is_active:
        return
    user.is_active = True
    user.save(update_fields=['is_active'])
    AdminLog.objects.create(admin=admin, action='unban', target_user=user, note=note)


# ── Legacy bridge helpers ─────────────────────────────────────────────────────

def record_legacy_report_ban(*, admin, report, note=''):
    """
    Called by the legacy `AdminReportActionView` `ban_user` flow AFTER it has
    set `User.is_active=False`. Records the ban as a permanent-suspension
    `ModerationAction` linked to the report, so there is one history of what
    was done to the user rather than a ban that exists only as a flag.

    No extra AdminLog row: the legacy flow already writes its own 'ban' entry
    (kept unchanged for compatibility); writing another would double-log.
    """
    # `reason` is shown to the affected user (Part 5 notification), so it must
    # be neutral: the report's admin_note is INTERNAL and goes to `admin_note`
    # only, and the report id/reporter are never put in user-visible text.
    return create_moderation_action(
        admin=admin,
        target_user=report.reported_user,
        action_type=ModerationAction.ACTION_SUSPEND_PERMANENT,
        reason=moderation_notifications.GENERIC_REASON,
        admin_note=(note or '').strip(),
        report=report,
        legacy_ban_applied=True,
        write_log=False,
        skip_duplicate_check=True,
    )


@transaction.atomic
def sync_moderation_after_legacy_unban(*, user, admin):
    """
    Called by `BanUserView` when an admin unbans a user through the legacy
    ban/unban endpoint. Any in-force record created by the legacy report-ban
    bridge is reversed too, so the enforcement layer doesn't keep treating the
    user as suspended after an admin has explicitly unbanned them.
    Records created via the new API (legacy_ban_applied=False) are untouched.
    """
    now = timezone.now()
    stale = ModerationAction.objects.select_for_update().filter(
        target_user=user, legacy_ban_applied=True, is_active=True)
    for action in stale:
        if action_status(action, now) != STATUS_ACTIVE:
            continue
        action.is_active = False
        action.reversed_at = now
        action.reversed_by = admin
        action.reversal_reason = 'Account unbanned via the legacy ban/unban endpoint.'
        action.save(update_fields=['is_active', 'reversed_at', 'reversed_by', 'reversal_reason'])
        _notify_after_commit(moderation_notifications.notify_action_reversed, action.pk)