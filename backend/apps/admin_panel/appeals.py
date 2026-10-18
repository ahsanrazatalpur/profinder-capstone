# apps/admin_panel/appeals.py
"""
Appeal service layer (Trust & Safety Part 6).

The ONE place where `Appeal` rows are created and decided, mirroring
`moderation.py`. Views only translate HTTP <-> these functions.

Design rules
------------
* An appeal is a REQUEST. Submitting one changes nothing about the moderation
  action; the action stays in force while the appeal is pending.
* Approval does not re-implement any moderation logic: it calls the existing
  `moderation.reverse_moderation_action`, so a reversal caused by an appeal is
  identical to one done by hand (history kept, AdminLog written, legacy-ban
  account restore, etc.). Rejection touches nothing but the appeal.
* No enforcement logic lives here (that's Part 3's read layer).
* Everything that changes state happens inside one `transaction.atomic()`
  together with its `AdminLog` row, so an approval can never leave the appeal
  "approved" with the action still active (or the reverse).
* Notifications are scheduled with `transaction.on_commit` and sent by
  `moderation_notifications` (the Part 5 system) — no new infrastructure.

Errors reuse the moderation exceptions, so views map them to the same
`{'error': ...}` + status-code shape as the rest of the admin panel.
"""
from django.db import IntegrityError, transaction
from django.utils import timezone

from apps.admin_panel import moderation_notifications
from apps.admin_panel.models import AdminLog, Appeal, ModerationAction
from apps.admin_panel.moderation import (
    STATUS_ACTIVE,
    ModerationConflict,
    ModerationError,
    ModerationNotFound,
    action_status,
    reverse_moderation_action,
)

_NOTE_LIMIT = 300  # keep AdminLog.note readable; the full note lives on the appeal


def _trim(text, limit=_NOTE_LIMIT):
    text = (text or '').strip()
    return text if len(text) <= limit else text[: limit - 1] + '…'


def _after_commit(sender, appeal_id):
    transaction.on_commit(lambda: sender(appeal_id))


# ── Submit (affected user) ───────────────────────────────────────────────────

@transaction.atomic
def submit_appeal(*, user, moderation_action_id, reason, evidence_url=''):
    """
    Create a pending appeal for `user` against one of THEIR moderation actions.

    `user` is always the authenticated requester. Status, reviewer, decision
    note and resolved_at are not parameters, so nothing a client sends can set
    them. `report` is copied from the action, never accepted from input.

    Raises ModerationError (400), ModerationNotFound (404) or
    ModerationConflict (409). "Not found" is deliberately identical whether the
    action doesn't exist or belongs to someone else, so ids can't be probed.
    """
    reason = (reason or '').strip()
    if not reason:
        raise ModerationError('An explanation is required.')

    # Filtering by target_user in the query itself is the ownership check: a
    # foreign action simply isn't found. The row lock serialises concurrent
    # submissions for the same action (no-op on SQLite, effective on Postgres).
    try:
        action = (ModerationAction.objects.select_for_update()
                  .select_related('report')
                  .get(pk=moderation_action_id, target_user_id=user.pk))
    except ModerationAction.DoesNotExist:
        raise ModerationNotFound('Moderation action not found.')

    if action_status(action) != STATUS_ACTIVE:
        raise ModerationConflict(
            'This action is no longer in effect, so it cannot be appealed.')

    if Appeal.objects.filter(moderation_action=action,
                             status=Appeal.STATUS_PENDING).exists():
        raise ModerationConflict(
            'You already have a pending appeal for this action.')

    try:
        # Inner savepoint so a race-lost IntegrityError doesn't poison the
        # outer transaction. The partial unique constraint is the real guard.
        with transaction.atomic():
            appeal = Appeal.objects.create(
                user=user,
                moderation_action=action,
                report=action.report,
                reason=reason,
                evidence_url=(evidence_url or '').strip(),
            )
    except IntegrityError:
        raise ModerationConflict(
            'You already have a pending appeal for this action.')

    _after_commit(moderation_notifications.notify_appeal_submitted, appeal.pk)
    return appeal


# ── Decide (admin) ───────────────────────────────────────────────────────────

def _lock_pending_appeal(appeal_id):
    """
    Return (appeal, action) locked, and verified still pending.

    Lock order is ALWAYS action row first, then appeal row — the same order
    `submit_appeal` uses — so an approval and a concurrent submission can't
    deadlock on Postgres.
    """
    action_id = (Appeal.objects.filter(pk=appeal_id)
                 .values_list('moderation_action_id', flat=True).first())
    if action_id is None:
        raise ModerationNotFound('Appeal not found.')

    action = ModerationAction.objects.select_for_update().get(pk=action_id)
    appeal = (Appeal.objects.select_for_update()
              .select_related('user').get(pk=appeal_id))

    if appeal.status != Appeal.STATUS_PENDING:
        raise ModerationConflict(f'This appeal has already been {appeal.status}.')
    return appeal, action


@transaction.atomic
def approve_appeal(*, admin, appeal_id, decision_note=''):
    """
    Approve a pending appeal and reverse the appealed moderation action using
    the existing reversal logic.

    If the action is no longer in force (an admin already reversed it, or it
    expired while the appeal waited), the appeal is still approved — the
    user's goal is met — but nothing is reversed a second time.
    """
    appeal, action = _lock_pending_appeal(appeal_id)
    note = (decision_note or '').strip()
    now = timezone.now()

    reversed_now = False
    if action_status(action, now) == STATUS_ACTIVE:
        reason = f'Appeal #{appeal.pk} approved' + (f': {note}' if note else '')
        # notify=False: the user gets ONE "Appeal Approved" message instead of
        # that plus a separate generic "restriction lifted" one.
        reverse_moderation_action(
            admin=admin, action_id=action.pk, reason=reason, notify=False)
        reversed_now = True

    appeal.status = Appeal.STATUS_APPROVED
    appeal.reviewed_by = admin
    appeal.decision_note = note
    appeal.resolved_at = now
    appeal.save(update_fields=['status', 'reviewed_by', 'decision_note', 'resolved_at'])

    AdminLog.objects.create(
        admin=admin, action='appeal_approved', target_user=appeal.user,
        note=(f'Appeal #{appeal.pk} approved | {action.get_action_type_display()} '
              f'(#{action.pk}) ' + ('reversed' if reversed_now else 'was already not in effect')
              + (f' | note: {_trim(note)}' if note else '')))

    _after_commit(moderation_notifications.notify_appeal_resolved, appeal.pk)
    return appeal


@transaction.atomic
def reject_appeal(*, admin, appeal_id, decision_note):
    """
    Reject a pending appeal. The moderation action is left exactly as it is;
    only the appeal record changes. An internal note is required so every
    refusal is accountable.
    """
    note = (decision_note or '').strip()
    if not note:
        raise ModerationError('A decision note is required to reject an appeal.')

    appeal, action = _lock_pending_appeal(appeal_id)
    now = timezone.now()

    appeal.status = Appeal.STATUS_REJECTED
    appeal.reviewed_by = admin
    appeal.decision_note = note
    appeal.resolved_at = now
    appeal.save(update_fields=['status', 'reviewed_by', 'decision_note', 'resolved_at'])

    AdminLog.objects.create(
        admin=admin, action='appeal_rejected', target_user=appeal.user,
        note=(f'Appeal #{appeal.pk} rejected | {action.get_action_type_display()} '
              f'(#{action.pk}) left in place | note: {_trim(note)}'))

    _after_commit(moderation_notifications.notify_appeal_resolved, appeal.pk)
    return appeal
