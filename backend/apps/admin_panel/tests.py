from datetime import timedelta, timezone as dt_timezone
from unittest import mock

from django.test import TestCase
from django.utils import timezone
from django.db import IntegrityError, transaction
from django.db.models import ProtectedError
from django.core.exceptions import ValidationError

from rest_framework.test import APIClient

from apps.admin_panel import moderation_notifications
from apps.admin_panel.models import AdminLog, Appeal, ModerationAction, UserReport
from apps.admin_panel.enforcement import (
    get_active_actions,
    get_moderation_status,
    is_suspended,
    can_send_messages,
    can_create_bookings,
)
from apps.notifications.models import Notification
from apps.users.models import User


class EnforcementTestCase(TestCase):
    """
    Focused tests for apps.admin_panel.enforcement (Trust & Safety Part 3).

    Covers exactly the scenarios called for in the task: temporary
    expiration, permanent suspension, messaging-only restriction,
    booking-only restriction, warning/no restriction, and multiple
    simultaneous actions (including that one expiring doesn't remove an
    unrelated still-active one).
    """

    def setUp(self):
        self.admin = User.objects.create_user(
            email='admin@test.com', name='Admin', role='admin', password='pass1234')
        self.target = User.objects.create_user(
            email='target@test.com', name='Target User', role='customer', password='pass1234')
        self.bystander = User.objects.create_user(
            email='bystander@test.com', name='Bystander', role='customer', password='pass1234')

    # ── Baseline: no actions at all ─────────────────────────────────────────
    def test_user_with_no_actions_is_fully_unrestricted(self):
        self.assertFalse(is_suspended(self.target))
        self.assertTrue(can_send_messages(self.target))
        self.assertTrue(can_create_bookings(self.target))
        status = get_moderation_status(self.target)
        self.assertEqual(status.active_actions, [])
        self.assertFalse(status.has_active_warning)

    # ── Warning blocks nothing ──────────────────────────────────────────────
    def test_warning_blocks_nothing(self):
        ModerationAction.objects.create(
            target_user=self.target, performed_by=self.admin,
            action_type=ModerationAction.ACTION_WARNING,
            reason='First warning',
        )
        status = get_moderation_status(self.target)
        self.assertTrue(status.has_active_warning)
        self.assertFalse(status.is_suspended)
        self.assertFalse(status.messaging_restricted)
        self.assertFalse(status.booking_restricted)
        self.assertTrue(can_send_messages(self.target))
        self.assertTrue(can_create_bookings(self.target))

    # ── Temporary suspension: active before expiry ──────────────────────────
    def test_temporary_suspension_active_before_expiry(self):
        ModerationAction.objects.create(
            target_user=self.target, performed_by=self.admin,
            action_type=ModerationAction.ACTION_SUSPEND_TEMPORARY,
            reason='Cool-off period',
            expires_at=timezone.now() + timedelta(days=1),
        )
        status = get_moderation_status(self.target)
        self.assertTrue(status.is_suspended)
        self.assertTrue(status.is_temporarily_suspended)
        self.assertFalse(status.is_permanently_suspended)
        self.assertIsNotNone(status.suspension_expires_at)
        # A suspension implies both restrictions, with no explicit rows needed.
        self.assertTrue(status.messaging_restricted)
        self.assertTrue(status.booking_restricted)
        self.assertFalse(can_send_messages(self.target))
        self.assertFalse(can_create_bookings(self.target))

    # ── Temporary suspension: automatically expired, no DB write needed ────
    def test_temporary_suspension_expires_automatically(self):
        action = ModerationAction.objects.create(
            target_user=self.target, performed_by=self.admin,
            action_type=ModerationAction.ACTION_SUSPEND_TEMPORARY,
            reason='Already over',
            expires_at=timezone.now() + timedelta(seconds=1),
        )
        # Confirm it reads as active immediately after creation.
        self.assertTrue(is_suspended(self.target))

        # Force it into the past without touching is_active — this is the
        # crux of the "no manual DB update just to expire" requirement.
        ModerationAction.objects.filter(pk=action.pk).update(
            expires_at=timezone.now() - timedelta(seconds=1)
        )
        action.refresh_from_db()
        self.assertTrue(action.is_active)  # flag was NOT flipped

        self.assertFalse(is_suspended(self.target))
        self.assertTrue(can_send_messages(self.target))
        self.assertTrue(can_create_bookings(self.target))
        self.assertEqual(get_active_actions(self.target), [])

    # ── Permanent suspension: active with no expiry, doesn't self-expire ───
    def test_permanent_suspension_active_indefinitely(self):
        ModerationAction.objects.create(
            target_user=self.target, performed_by=self.admin,
            action_type=ModerationAction.ACTION_SUSPEND_PERMANENT,
            reason='Severe repeated fraud',
        )
        status = get_moderation_status(self.target)
        self.assertTrue(status.is_suspended)
        self.assertTrue(status.is_permanently_suspended)
        self.assertIsNone(status.suspension_expires_at)
        self.assertFalse(can_send_messages(self.target))
        self.assertFalse(can_create_bookings(self.target))

    def test_permanent_suspension_reversed_by_admin_lifts_restriction(self):
        action = ModerationAction.objects.create(
            target_user=self.target, performed_by=self.admin,
            action_type=ModerationAction.ACTION_SUSPEND_PERMANENT,
            reason='Under appeal, reinstated',
        )
        self.assertTrue(is_suspended(self.target))
        # Only an explicit admin reversal (is_active=False) lifts it —
        # nothing here does this automatically.
        action.is_active = False
        action.save(update_fields=['is_active'])
        self.assertFalse(is_suspended(self.target))

    # ── Messaging restriction only ──────────────────────────────────────────
    def test_messaging_restriction_blocks_only_messaging(self):
        ModerationAction.objects.create(
            target_user=self.target, performed_by=self.admin,
            action_type=ModerationAction.ACTION_RESTRICT_MESSAGING,
            reason='Spammy messages',
        )
        status = get_moderation_status(self.target)
        self.assertFalse(status.is_suspended)
        self.assertTrue(status.messaging_restricted)
        self.assertFalse(status.booking_restricted)
        self.assertFalse(can_send_messages(self.target))
        self.assertTrue(can_create_bookings(self.target))

    # ── Booking restriction only ────────────────────────────────────────────
    def test_booking_restriction_blocks_only_booking(self):
        ModerationAction.objects.create(
            target_user=self.target, performed_by=self.admin,
            action_type=ModerationAction.ACTION_RESTRICT_BOOKING,
            reason='No-show pattern',
        )
        status = get_moderation_status(self.target)
        self.assertFalse(status.is_suspended)
        self.assertFalse(status.messaging_restricted)
        self.assertTrue(status.booking_restricted)
        self.assertTrue(can_send_messages(self.target))
        self.assertFalse(can_create_bookings(self.target))

    # ── Multiple simultaneous actions ───────────────────────────────────────
    def test_multiple_independent_restrictions_both_enforced(self):
        ModerationAction.objects.create(
            target_user=self.target, performed_by=self.admin,
            action_type=ModerationAction.ACTION_RESTRICT_MESSAGING,
            reason='Spam',
        )
        ModerationAction.objects.create(
            target_user=self.target, performed_by=self.admin,
            action_type=ModerationAction.ACTION_RESTRICT_BOOKING,
            reason='No-shows',
        )
        self.assertFalse(can_send_messages(self.target))
        self.assertFalse(can_create_bookings(self.target))

    def test_one_restriction_expiring_does_not_lift_the_other(self):
        """
        Two independent, unrelated restrictions must not interfere with
        each other: one expiring (or being reversed) must not accidentally
        clear the other.
        """
        expiring = ModerationAction.objects.create(
            target_user=self.target, performed_by=self.admin,
            action_type=ModerationAction.ACTION_RESTRICT_MESSAGING,
            reason='Temporary messaging cooldown',
            expires_at=timezone.now() + timedelta(seconds=1),
        )
        ModerationAction.objects.create(
            target_user=self.target, performed_by=self.admin,
            action_type=ModerationAction.ACTION_RESTRICT_BOOKING,
            reason='Separate, unrelated, no-expiry booking restriction',
        )
        self.assertFalse(can_send_messages(self.target))
        self.assertFalse(can_create_bookings(self.target))

        # Expire the messaging restriction only (again, no is_active flip).
        ModerationAction.objects.filter(pk=expiring.pk).update(
            expires_at=timezone.now() - timedelta(seconds=1)
        )
        self.assertTrue(can_send_messages(self.target))       # lifted
        self.assertFalse(can_create_bookings(self.target))     # still enforced

    def test_permanent_and_temporary_together_permanent_wins(self):
        """The strongest applicable restriction (permanent) is reported."""
        ModerationAction.objects.create(
            target_user=self.target, performed_by=self.admin,
            action_type=ModerationAction.ACTION_SUSPEND_TEMPORARY,
            reason='Earlier temp suspension',
            expires_at=timezone.now() + timedelta(days=3),
        )
        ModerationAction.objects.create(
            target_user=self.target, performed_by=self.admin,
            action_type=ModerationAction.ACTION_SUSPEND_PERMANENT,
            reason='Escalated to permanent',
        )
        status = get_moderation_status(self.target)
        self.assertTrue(status.is_suspended)
        self.assertTrue(status.is_permanently_suspended)
        self.assertIsNone(status.suspension_expires_at)

    # ── Isolation between users ──────────────────────────────────────────────
    def test_restriction_on_one_user_does_not_affect_another(self):
        ModerationAction.objects.create(
            target_user=self.target, performed_by=self.admin,
            action_type=ModerationAction.ACTION_SUSPEND_PERMANENT,
            reason='Only target is suspended',
        )
        self.assertTrue(is_suspended(self.target))
        self.assertFalse(is_suspended(self.bystander))
        self.assertTrue(can_send_messages(self.bystander))
        self.assertTrue(can_create_bookings(self.bystander))

    # ── Not-yet-started actions aren't enforced early ───────────────────────
    def test_future_starts_at_not_yet_enforced(self):
        ModerationAction.objects.create(
            target_user=self.target, performed_by=self.admin,
            action_type=ModerationAction.ACTION_RESTRICT_BOOKING,
            reason='Scheduled to start tomorrow',
            starts_at=timezone.now() + timedelta(days=1),
        )
        self.assertTrue(can_create_bookings(self.target))

    # ── Manual is_active=False always overrides, even before expiry ────────
    def test_manually_deactivated_restriction_is_not_enforced(self):
        action = ModerationAction.objects.create(
            target_user=self.target, performed_by=self.admin,
            action_type=ModerationAction.ACTION_RESTRICT_MESSAGING,
            reason='Reversed early by admin',
        )
        action.is_active = False
        action.save(update_fields=['is_active'])
        self.assertTrue(can_send_messages(self.target))


class ModerationActionConstraintTestCase(TestCase):
    """
    Sanity checks that Part 2's data-integrity rules are still intact and
    that enforcement logic can rely on them holding at the DB level.
    """

    def setUp(self):
        self.admin = User.objects.create_user(
            email='admin2@test.com', name='Admin2', role='admin', password='pass1234')
        self.target = User.objects.create_user(
            email='target2@test.com', name='Target2', role='customer', password='pass1234')

    def test_temporary_suspension_without_expiry_rejected_by_clean(self):
        action = ModerationAction(
            target_user=self.target, performed_by=self.admin,
            action_type=ModerationAction.ACTION_SUSPEND_TEMPORARY,
            reason='Missing expiry',
        )
        with self.assertRaises(ValidationError):
            action.full_clean(exclude=['report'])

    def test_temporary_suspension_without_expiry_rejected_by_db(self):
        with self.assertRaises(IntegrityError):
            with transaction.atomic():
                ModerationAction.objects.create(
                    target_user=self.target, performed_by=self.admin,
                    action_type=ModerationAction.ACTION_SUSPEND_TEMPORARY,
                    reason='Bypassing clean() directly',
                )


# ══════════════════════════════════════════════════════════════════════════════
# Trust & Safety Part 4 — moderation action APIs
# ══════════════════════════════════════════════════════════════════════════════

BASE = '/api/admin-panel'


def _future(**kw):
    return (timezone.now() + timedelta(**(kw or {'days': 3}))).isoformat()


class ModerationAPITestBase(TestCase):
    def setUp(self):
        self.admin = User.objects.create_user(
            email='admin@test.com', name='Admin', role='admin', password='pass1234')
        self.admin2 = User.objects.create_user(
            email='admin2@test.com', name='Admin Two', role='admin', password='pass1234')
        self.target = User.objects.create_user(
            email='target@test.com', name='Target', role='customer', password='pass1234')
        self.other = User.objects.create_user(
            email='other@test.com', name='Other', role='professional', password='pass1234')
        self.reporter = User.objects.create_user(
            email='reporter@test.com', name='Reporter', role='customer', password='pass1234')

        self.client = APIClient()
        self.client.force_authenticate(self.admin)

    # helpers
    def post_action(self, **overrides):
        payload = {
            'target_user': self.target.pk,
            'action_type': 'warning',
            'reason': 'Rule violation',
        }
        payload.update(overrides)
        return self.client.post(f'{BASE}/moderation-actions/', payload, format='json')

    def make_report(self, reported=None, **kw):
        return UserReport.objects.create(
            reporter=self.reporter, reported_user=reported or self.target,
            reason=kw.pop('reason', 'harassment'), **kw)


class ModerationCreatePermissionTests(ModerationAPITestBase):
    """Only admins may create/reverse/view; everyone else is rejected."""

    def test_authorized_admin_can_create_action(self):
        r = self.post_action()
        self.assertEqual(r.status_code, 201, r.data)
        action = ModerationAction.objects.get(pk=r.data['id'])
        self.assertEqual(action.performed_by, self.admin)
        self.assertEqual(action.target_user, self.target)
        self.assertTrue(action.is_active)
        self.assertEqual(r.data['status'], 'active')
        self.assertEqual(r.data['performed_by_email'], 'admin@test.com')

    def test_customer_is_rejected_on_create(self):
        self.client.force_authenticate(self.target)
        r = self.post_action(target_user=self.other.pk)
        self.assertEqual(r.status_code, 403)
        self.assertEqual(ModerationAction.objects.count(), 0)

    def test_professional_is_rejected_on_create(self):
        self.client.force_authenticate(self.other)
        r = self.post_action()
        self.assertEqual(r.status_code, 403)
        self.assertEqual(ModerationAction.objects.count(), 0)

    def test_unauthenticated_is_rejected(self):
        self.client.force_authenticate(None)
        r = self.post_action()
        self.assertIn(r.status_code, (401, 403))
        self.assertEqual(ModerationAction.objects.count(), 0)

    def test_non_admin_cannot_view_history_or_report_actions_or_reverse(self):
        action = ModerationAction.objects.create(
            target_user=self.target, performed_by=self.admin,
            action_type='warning', reason='x', report=self.make_report())
        self.client.force_authenticate(self.other)
        self.assertEqual(
            self.client.get(f'{BASE}/users/{self.target.pk}/moderation-actions/').status_code, 403)
        self.assertEqual(
            self.client.get(f'{BASE}/reports/{action.report_id}/moderation-actions/').status_code, 403)
        r = self.client.post(f'{BASE}/moderation-actions/{action.pk}/reverse/',
                             {'reason': 'nope'}, format='json')
        self.assertEqual(r.status_code, 403)
        action.refresh_from_db()
        self.assertTrue(action.is_active)          # untouched
        self.assertIsNone(action.reversed_at)

    def test_affected_user_cannot_read_own_history(self):
        ModerationAction.objects.create(
            target_user=self.target, performed_by=self.admin,
            action_type='warning', reason='x')
        self.client.force_authenticate(self.target)
        r = self.client.get(f'{BASE}/users/{self.target.pk}/moderation-actions/')
        self.assertEqual(r.status_code, 403)


class ModerationCreateValidationTests(ModerationAPITestBase):

    # ── client can't bypass server-controlled fields ─────────────────────────
    def test_client_cannot_set_admin_active_state_or_timestamps(self):
        r = self.post_action(
            performed_by=self.admin2.pk,
            admin=self.admin2.pk,
            is_active=False,
            starts_at='2000-01-01T00:00:00Z',
            created_at='2000-01-01T00:00:00Z',
            reversed_at='2000-01-01T00:00:00Z',
            reversed_by=self.admin2.pk,
            legacy_ban_applied=True,
        )
        self.assertEqual(r.status_code, 201, r.data)
        a = ModerationAction.objects.get(pk=r.data['id'])
        self.assertEqual(a.performed_by, self.admin)            # not admin2
        self.assertTrue(a.is_active)                            # not False
        self.assertGreater(a.created_at.year, 2000)
        self.assertGreater(a.starts_at.year, 2000)
        self.assertIsNone(a.reversed_at)
        self.assertIsNone(a.reversed_by)
        self.assertFalse(a.legacy_ban_applied)

    # ── target user ──────────────────────────────────────────────────────────
    def test_nonexistent_target_rejected(self):
        r = self.post_action(target_user=999999)
        self.assertEqual(r.status_code, 400)
        self.assertIn('target_user', r.data)

    def test_missing_target_rejected(self):
        r = self.client.post(f'{BASE}/moderation-actions/',
                             {'action_type': 'warning', 'reason': 'x'}, format='json')
        self.assertEqual(r.status_code, 400)
        self.assertIn('target_user', r.data)

    def test_cannot_target_self(self):
        r = self.post_action(target_user=self.admin.pk)
        self.assertEqual(r.status_code, 400)
        self.assertIn('target_user', r.data)

    def test_cannot_target_another_admin(self):
        r = self.post_action(target_user=self.admin2.pk)
        self.assertEqual(r.status_code, 400)
        self.assertEqual(ModerationAction.objects.count(), 0)

    # ── other required input ─────────────────────────────────────────────────
    def test_reason_required(self):
        for bad in ('', '   '):
            r = self.post_action(reason=bad)
            self.assertEqual(r.status_code, 400, bad)
            self.assertIn('reason', r.data)
        self.assertEqual(ModerationAction.objects.count(), 0)

    def test_invalid_action_type_rejected(self):
        r = self.post_action(action_type='ban_forever')
        self.assertEqual(r.status_code, 400)
        self.assertIn('action_type', r.data)

    # ── temporary suspension ─────────────────────────────────────────────────
    def test_temporary_suspension_requires_expiry(self):
        r = self.post_action(action_type='suspend_temporary')
        self.assertEqual(r.status_code, 400)
        self.assertIn('expires_at', r.data)
        self.assertEqual(ModerationAction.objects.count(), 0)

    def test_temporary_suspension_null_expiry_rejected(self):
        r = self.post_action(action_type='suspend_temporary', expires_at=None)
        self.assertEqual(r.status_code, 400)
        self.assertIn('expires_at', r.data)

    def test_temporary_suspension_past_expiry_rejected(self):
        past = (timezone.now() - timedelta(hours=1)).isoformat()
        r = self.post_action(action_type='suspend_temporary', expires_at=past)
        self.assertEqual(r.status_code, 400)
        self.assertIn('expires_at', r.data)

    def test_temporary_suspension_garbage_expiry_rejected(self):
        r = self.post_action(action_type='suspend_temporary', expires_at='next tuesday')
        self.assertEqual(r.status_code, 400)
        self.assertIn('expires_at', r.data)

    def test_temporary_suspension_with_future_expiry_succeeds_and_is_enforced(self):
        exp = _future(days=2)
        r = self.post_action(action_type='suspend_temporary', expires_at=exp)
        self.assertEqual(r.status_code, 201, r.data)
        self.assertIsNotNone(r.data['expires_at'])
        self.assertTrue(is_suspended(self.target))          # Part 3 reads our row
        self.assertFalse(can_send_messages(self.target))
        self.assertFalse(can_create_bookings(self.target))

    # ── permanent suspension ─────────────────────────────────────────────────
    def test_permanent_suspension_needs_no_expiry(self):
        r = self.post_action(action_type='suspend_permanent')
        self.assertEqual(r.status_code, 201, r.data)
        a = ModerationAction.objects.get(pk=r.data['id'])
        self.assertIsNone(a.expires_at)
        self.assertTrue(get_moderation_status(self.target).is_permanently_suspended)

    def test_permanent_suspension_with_expiry_rejected(self):
        r = self.post_action(action_type='suspend_permanent', expires_at=_future())
        self.assertEqual(r.status_code, 400)
        self.assertIn('expires_at', r.data)
        self.assertEqual(ModerationAction.objects.count(), 0)

    def test_new_api_suspension_does_not_change_account_flag(self):
        # Enforcement lives in Part 3's read layer; this endpoint only records.
        self.post_action(action_type='suspend_permanent')
        self.target.refresh_from_db()
        self.assertTrue(self.target.is_active)

    # ── restrictions ─────────────────────────────────────────────────────────
    def test_messaging_restriction_blocks_only_messaging(self):
        r = self.post_action(action_type='restrict_messaging')
        self.assertEqual(r.status_code, 201, r.data)
        self.assertFalse(can_send_messages(self.target))
        self.assertTrue(can_create_bookings(self.target))
        self.assertFalse(is_suspended(self.target))

    def test_booking_restriction_blocks_only_booking(self):
        r = self.post_action(action_type='restrict_booking')
        self.assertEqual(r.status_code, 201, r.data)
        self.assertFalse(can_create_bookings(self.target))
        self.assertTrue(can_send_messages(self.target))
        self.assertFalse(is_suspended(self.target))

    def test_restriction_with_past_expiry_rejected(self):
        past = (timezone.now() - timedelta(minutes=5)).isoformat()
        r = self.post_action(action_type='restrict_messaging', expires_at=past)
        self.assertEqual(r.status_code, 400)

    def test_restriction_with_future_expiry_allowed(self):
        r = self.post_action(action_type='restrict_booking', expires_at=_future(days=1))
        self.assertEqual(r.status_code, 201, r.data)

    # ── warning ──────────────────────────────────────────────────────────────
    def test_warning_creates_no_restriction(self):
        before_users = list(User.objects.values_list('pk', 'is_active'))
        r = self.post_action(action_type='warning')
        self.assertEqual(r.status_code, 201, r.data)
        self.assertEqual(ModerationAction.objects.count(), 1)   # one row, no side-rows
        status = get_moderation_status(self.target)
        self.assertTrue(status.has_active_warning)
        self.assertFalse(status.messaging_restricted)
        self.assertFalse(status.booking_restricted)
        self.assertFalse(status.is_suspended)
        self.assertEqual(before_users, list(User.objects.values_list('pk', 'is_active')))

    def test_warnings_may_stack(self):
        self.assertEqual(self.post_action(action_type='warning').status_code, 201)
        self.assertEqual(self.post_action(action_type='warning', reason='again').status_code, 201)

    # ── invalid combinations against current state ───────────────────────────
    def test_duplicate_active_restriction_conflicts(self):
        self.assertEqual(self.post_action(action_type='restrict_messaging').status_code, 201)
        r = self.post_action(action_type='restrict_messaging')
        self.assertEqual(r.status_code, 409)
        self.assertEqual(ModerationAction.objects.filter(
            action_type='restrict_messaging').count(), 1)

    def test_duplicate_permanent_suspension_conflicts(self):
        self.assertEqual(self.post_action(action_type='suspend_permanent').status_code, 201)
        self.assertEqual(self.post_action(action_type='suspend_permanent').status_code, 409)

    def test_temporary_suspension_under_permanent_conflicts(self):
        self.post_action(action_type='suspend_permanent')
        r = self.post_action(action_type='suspend_temporary', expires_at=_future())
        self.assertEqual(r.status_code, 409)

    def test_permanent_can_escalate_over_temporary(self):
        self.post_action(action_type='suspend_temporary', expires_at=_future())
        self.assertEqual(self.post_action(action_type='suspend_permanent').status_code, 201)

    def test_different_restrictions_can_coexist(self):
        self.assertEqual(self.post_action(action_type='restrict_messaging').status_code, 201)
        self.assertEqual(self.post_action(action_type='restrict_booking').status_code, 201)

    def test_reissue_allowed_after_reversal(self):
        first = self.post_action(action_type='restrict_messaging').data['id']
        self.client.post(f'{BASE}/moderation-actions/{first}/reverse/',
                         {'reason': 'mistake'}, format='json')
        self.assertEqual(self.post_action(action_type='restrict_messaging').status_code, 201)

    def test_reissue_allowed_after_natural_expiry(self):
        a = ModerationAction.objects.create(
            target_user=self.target, performed_by=self.admin,
            action_type='restrict_messaging', reason='old',
            expires_at=timezone.now() + timedelta(hours=1))
        ModerationAction.objects.filter(pk=a.pk).update(
            expires_at=timezone.now() - timedelta(minutes=1))
        self.assertEqual(self.post_action(action_type='restrict_messaging').status_code, 201)

    # ── audit log ────────────────────────────────────────────────────────────
    def test_creation_is_written_to_admin_log(self):
        r = self.post_action(action_type='restrict_booking', reason='No-shows')
        log = AdminLog.objects.get(action='moderation_action')
        self.assertEqual(log.admin, self.admin)
        self.assertEqual(log.target_user, self.target)
        self.assertIn(f"#{r.data['id']}", log.note)
        self.assertIn('No-shows', log.note)

    def test_rejected_request_writes_no_log(self):
        self.post_action(action_type='suspend_temporary')          # invalid
        self.assertFalse(AdminLog.objects.filter(action='moderation_action').exists())


class ModerationReportLinkageTests(ModerationAPITestBase):

    def test_action_can_be_linked_to_report(self):
        report = self.make_report()
        r = self.post_action(report=report.pk)
        self.assertEqual(r.status_code, 201, r.data)
        self.assertEqual(r.data['report'], report.pk)
        self.assertEqual(ModerationAction.objects.get(pk=r.data['id']).report, report)

    def test_action_without_report_is_allowed(self):
        r = self.post_action()
        self.assertEqual(r.status_code, 201)
        self.assertIsNone(r.data['report'])

    def test_null_report_is_allowed(self):
        self.assertEqual(self.post_action(report=None).status_code, 201)

    def test_nonexistent_report_rejected(self):
        r = self.post_action(report=424242)
        self.assertEqual(r.status_code, 400)
        self.assertIn('report', r.data)

    def test_report_about_a_different_user_rejected(self):
        report = self.make_report(reported=self.other)
        r = self.post_action(report=report.pk)          # target is self.target
        self.assertEqual(r.status_code, 400)
        self.assertIn('report', r.data)
        self.assertEqual(ModerationAction.objects.count(), 0)

    def test_report_actions_endpoint_lists_only_that_reports_actions(self):
        report = self.make_report()
        other_report = self.make_report()
        a1 = self.post_action(report=report.pk, action_type='warning').data['id']
        a2 = self.post_action(report=report.pk, action_type='restrict_messaging').data['id']
        self.post_action(report=other_report.pk, action_type='restrict_booking')
        self.post_action(action_type='warning')            # no report at all

        r = self.client.get(f'{BASE}/reports/{report.pk}/moderation-actions/')
        self.assertEqual(r.status_code, 200)
        self.assertEqual({x['id'] for x in r.data}, {a1, a2})
        self.assertTrue(all(x['report'] == report.pk for x in r.data))

    def test_report_actions_endpoint_includes_reversed_actions(self):
        report = self.make_report()
        a = self.post_action(report=report.pk).data['id']
        self.client.post(f'{BASE}/moderation-actions/{a}/reverse/',
                         {'reason': 'oops'}, format='json')
        r = self.client.get(f'{BASE}/reports/{report.pk}/moderation-actions/')
        self.assertEqual([x['status'] for x in r.data], ['reversed'])

    def test_report_actions_missing_report_404(self):
        self.assertEqual(
            self.client.get(f'{BASE}/reports/999999/moderation-actions/').status_code, 404)

    def test_report_with_no_actions_returns_empty_list(self):
        report = self.make_report()
        r = self.client.get(f'{BASE}/reports/{report.pk}/moderation-actions/')
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data, [])

    def test_report_actions_status_filter(self):
        report = self.make_report()
        keep = self.post_action(report=report.pk, action_type='warning').data['id']
        gone = self.post_action(report=report.pk, action_type='restrict_booking').data['id']
        self.client.post(f'{BASE}/moderation-actions/{gone}/reverse/',
                         {'reason': 'x'}, format='json')
        r = self.client.get(f'{BASE}/reports/{report.pk}/moderation-actions/?status=active')
        self.assertEqual([x['id'] for x in r.data], [keep])

    def test_creating_action_does_not_alter_report_status(self):
        # Legacy report workflow is independent; linkage is informational.
        report = self.make_report()
        self.post_action(report=report.pk)
        report.refresh_from_db()
        self.assertEqual(report.status, 'pending')


class ModerationHistoryTests(ModerationAPITestBase):

    def test_history_lists_all_states_newest_first(self):
        a_warn = self.post_action(action_type='warning').data['id']
        a_rev = self.post_action(action_type='restrict_messaging').data['id']
        self.client.post(f'{BASE}/moderation-actions/{a_rev}/reverse/',
                         {'reason': 'lifted'}, format='json')
        a_exp = ModerationAction.objects.create(
            target_user=self.target, performed_by=self.admin,
            action_type='restrict_booking', reason='old',
            expires_at=timezone.now() + timedelta(hours=1)).pk
        ModerationAction.objects.filter(pk=a_exp).update(
            expires_at=timezone.now() - timedelta(minutes=1))

        r = self.client.get(f'{BASE}/users/{self.target.pk}/moderation-actions/')
        self.assertEqual(r.status_code, 200)
        by_id = {x['id']: x for x in r.data}
        self.assertEqual(set(by_id), {a_warn, a_rev, a_exp})
        self.assertEqual(by_id[a_warn]['status'], 'active')
        self.assertEqual(by_id[a_rev]['status'], 'reversed')
        self.assertEqual(by_id[a_exp]['status'], 'expired')
        self.assertTrue(by_id[a_warn]['is_in_effect'])
        self.assertFalse(by_id[a_rev]['is_in_effect'])
        self.assertFalse(by_id[a_exp]['is_in_effect'])
        created = [x['created_at'] for x in r.data]
        self.assertEqual(created, sorted(created, reverse=True))

    def test_history_only_contains_that_users_actions(self):
        mine = self.post_action(target_user=self.target.pk).data['id']
        self.post_action(target_user=self.other.pk)
        r = self.client.get(f'{BASE}/users/{self.target.pk}/moderation-actions/')
        self.assertEqual([x['id'] for x in r.data], [mine])

    def test_history_records_which_admin_acted(self):
        self.client.force_authenticate(self.admin2)
        self.post_action()
        r = self.client.get(f'{BASE}/users/{self.target.pk}/moderation-actions/')
        self.assertEqual(r.data[0]['performed_by_email'], 'admin2@test.com')

    def test_history_empty_for_clean_user(self):
        r = self.client.get(f'{BASE}/users/{self.other.pk}/moderation-actions/')
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data, [])

    def test_history_unknown_user_404(self):
        self.assertEqual(
            self.client.get(f'{BASE}/users/999999/moderation-actions/').status_code, 404)

    def test_history_filters(self):
        w = self.post_action(action_type='warning').data['id']
        rm = self.post_action(action_type='restrict_messaging').data['id']
        self.client.post(f'{BASE}/moderation-actions/{rm}/reverse/',
                         {'reason': 'x'}, format='json')
        url = f'{BASE}/users/{self.target.pk}/moderation-actions/'
        self.assertEqual([x['id'] for x in self.client.get(url + '?status=active').data], [w])
        self.assertEqual([x['id'] for x in self.client.get(url + '?status=reversed').data], [rm])
        self.assertEqual(
            [x['id'] for x in self.client.get(url + '?action_type=restrict_messaging').data], [rm])
        self.assertEqual(self.client.get(url + '?status=expired').data, [])

    def test_history_invalid_filters_rejected(self):
        url = f'{BASE}/users/{self.target.pk}/moderation-actions/'
        self.assertEqual(self.client.get(url + '?status=bogus').status_code, 400)
        self.assertEqual(self.client.get(url + '?action_type=bogus').status_code, 400)


class ModerationReversalTests(ModerationAPITestBase):

    def reverse(self, action_id, reason='Reviewed and lifted', client=None):
        return (client or self.client).post(
            f'{BASE}/moderation-actions/{action_id}/reverse/',
            {'reason': reason} if reason is not None else {}, format='json')

    def test_reversal_deactivates_and_preserves_record(self):
        aid = self.post_action(action_type='restrict_messaging').data['id']
        self.assertFalse(can_send_messages(self.target))

        r = self.reverse(aid)
        self.assertEqual(r.status_code, 200, r.data)
        self.assertEqual(r.data['status'], 'reversed')
        self.assertFalse(r.data['is_active'])

        a = ModerationAction.objects.get(pk=aid)           # row still exists
        self.assertFalse(a.is_active)
        self.assertEqual(a.reversed_by, self.admin)
        self.assertIsNotNone(a.reversed_at)
        self.assertEqual(a.reversal_reason, 'Reviewed and lifted')
        # Original facts are untouched.
        self.assertEqual(a.performed_by, self.admin)
        self.assertEqual(a.reason, 'Rule violation')
        self.assertEqual(a.action_type, 'restrict_messaging')

        # Enforcement (Part 3) no longer applies it.
        self.assertTrue(can_send_messages(self.target))

    def test_reversal_records_the_reversing_admin_not_the_creator(self):
        aid = self.post_action().data['id']
        self.client.force_authenticate(self.admin2)
        self.reverse(aid)
        a = ModerationAction.objects.get(pk=aid)
        self.assertEqual(a.performed_by, self.admin)
        self.assertEqual(a.reversed_by, self.admin2)

    def test_reversed_action_still_appears_in_history(self):
        aid = self.post_action().data['id']
        self.reverse(aid)
        r = self.client.get(f'{BASE}/users/{self.target.pk}/moderation-actions/')
        self.assertEqual(len(r.data), 1)
        self.assertEqual(r.data[0]['reversal_reason'], 'Reviewed and lifted')
        self.assertEqual(r.data[0]['reversed_by_email'], 'admin@test.com')

    def test_reversing_permanent_suspension_lifts_restrictions(self):
        aid = self.post_action(action_type='suspend_permanent').data['id']
        self.assertTrue(is_suspended(self.target))
        self.assertEqual(self.reverse(aid).status_code, 200)
        self.assertFalse(is_suspended(self.target))
        self.assertTrue(can_send_messages(self.target))

    def test_reversing_one_action_leaves_others_in_force(self):
        m = self.post_action(action_type='restrict_messaging').data['id']
        self.post_action(action_type='restrict_booking')
        self.reverse(m)
        self.assertTrue(can_send_messages(self.target))
        self.assertFalse(can_create_bookings(self.target))

    def test_reversal_is_written_to_admin_log(self):
        aid = self.post_action().data['id']
        self.reverse(aid, reason='Appeal reviewed')
        log = AdminLog.objects.get(action='moderation_reversed')
        self.assertEqual(log.admin, self.admin)
        self.assertEqual(log.target_user, self.target)
        self.assertIn(f'#{aid}', log.note)
        self.assertIn('Appeal reviewed', log.note)
        # The original creation log entry is preserved as well.
        self.assertTrue(AdminLog.objects.filter(action='moderation_action').exists())

    def test_double_reversal_conflicts_and_keeps_first_reversal(self):
        aid = self.post_action().data['id']
        self.reverse(aid, reason='first')
        r = self.reverse(aid, reason='second')
        self.assertEqual(r.status_code, 409)
        a = ModerationAction.objects.get(pk=aid)
        self.assertEqual(a.reversal_reason, 'first')
        self.assertEqual(AdminLog.objects.filter(action='moderation_reversed').count(), 1)

    def test_reversal_requires_reason(self):
        aid = self.post_action().data['id']
        for bad in (None, '', '   '):
            r = self.reverse(aid, reason=bad)
            self.assertEqual(r.status_code, 400, repr(bad))
        self.assertTrue(ModerationAction.objects.get(pk=aid).is_active)

    def test_reverse_unknown_action_404(self):
        self.assertEqual(self.reverse(999999).status_code, 404)

    def test_expired_action_cannot_be_reversed(self):
        a = ModerationAction.objects.create(
            target_user=self.target, performed_by=self.admin,
            action_type='suspend_temporary', reason='x',
            expires_at=timezone.now() + timedelta(hours=1))
        ModerationAction.objects.filter(pk=a.pk).update(
            expires_at=timezone.now() - timedelta(minutes=1))
        r = self.reverse(a.pk)
        self.assertEqual(r.status_code, 400)
        a.refresh_from_db()
        self.assertTrue(a.is_active)          # unchanged; expiry is derived, not stored
        self.assertIsNone(a.reversed_at)

    def test_reversal_cannot_be_done_by_non_admin(self):
        aid = self.post_action().data['id']
        c = APIClient()
        c.force_authenticate(self.other)
        self.assertEqual(self.reverse(aid, client=c).status_code, 403)
        self.assertTrue(ModerationAction.objects.get(pk=aid).is_active)

    def test_client_cannot_smuggle_fields_into_reversal(self):
        aid = self.post_action().data['id']
        r = self.client.post(
            f'{BASE}/moderation-actions/{aid}/reverse/',
            {'reason': 'ok', 'reversed_by': self.admin2.pk,
             'reversed_at': '2000-01-01T00:00:00Z', 'is_active': True},
            format='json')
        self.assertEqual(r.status_code, 200)
        a = ModerationAction.objects.get(pk=aid)
        self.assertEqual(a.reversed_by, self.admin)
        self.assertGreater(a.reversed_at.year, 2000)
        self.assertFalse(a.is_active)


class LegacyReportEndpointCompatibilityTests(ModerationAPITestBase):
    """
    The pre-existing PATCH /reports/<id>/ workflow must behave exactly as
    before, while its `ban_user` flag no longer lives outside ModerationAction.
    """

    def patch_report(self, report, **body):
        return self.client.patch(f'{BASE}/reports/{report.pk}/', body, format='json')

    def test_status_only_update_unchanged_and_creates_no_action(self):
        report = self.make_report()
        r = self.patch_report(report, status='reviewed', admin_note='looked')
        self.assertEqual(r.status_code, 200, r.data)
        self.assertEqual(r.data['status'], 'reviewed')
        self.assertEqual(r.data['admin_note'], 'looked')
        self.assertEqual(ModerationAction.objects.count(), 0)
        self.target.refresh_from_db()
        self.assertTrue(self.target.is_active)

    def test_dismiss_unchanged_and_creates_no_action(self):
        report = self.make_report()
        r = self.patch_report(report, status='dismissed')
        self.assertEqual(r.status_code, 200)
        self.assertEqual(ModerationAction.objects.count(), 0)
        self.assertTrue(AdminLog.objects.filter(action='report_dismissed').exists())

    def test_invalid_status_still_400(self):
        report = self.make_report()
        self.assertEqual(self.patch_report(report, status='bogus').status_code, 400)

    def test_non_admin_still_403(self):
        report = self.make_report()
        self.client.force_authenticate(self.other)
        self.assertEqual(self.patch_report(report, status='reviewed').status_code, 403)

    def test_missing_report_still_404(self):
        r = self.client.patch(f'{BASE}/reports/999999/', {'status': 'reviewed'}, format='json')
        self.assertEqual(r.status_code, 404)

    def test_report_list_endpoint_unchanged(self):
        self.make_report()
        r = self.client.get(f'{BASE}/reports/')
        self.assertEqual(r.status_code, 200)
        self.assertEqual(len(r.data), 1)
        self.assertNotIn('moderation_actions', r.data[0])   # response shape unchanged

    def test_ban_user_still_deactivates_account_and_logs_ban(self):
        report = self.make_report()
        r = self.patch_report(report, status='action_taken', ban_user=True)
        self.assertEqual(r.status_code, 200, r.data)
        self.target.refresh_from_db()
        self.assertFalse(self.target.is_active)                        # legacy behaviour kept
        self.assertTrue(AdminLog.objects.filter(action='ban', target_user=self.target).exists())
        self.assertTrue(AdminLog.objects.filter(action='report_reviewed').exists())

    def test_ban_user_is_now_recorded_as_a_moderation_action(self):
        report = self.make_report()
        self.patch_report(report, status='action_taken', ban_user=True)
        a = ModerationAction.objects.get()
        self.assertEqual(a.action_type, 'suspend_permanent')
        self.assertEqual(a.target_user, self.target)
        self.assertEqual(a.performed_by, self.admin)
        self.assertEqual(a.report, report)
        self.assertIsNone(a.expires_at)
        self.assertTrue(a.is_active)
        self.assertTrue(a.legacy_ban_applied)
        # ...and it's visible through both new read endpoints.
        h = self.client.get(f'{BASE}/users/{self.target.pk}/moderation-actions/')
        self.assertEqual([x['id'] for x in h.data], [a.pk])
        rr = self.client.get(f'{BASE}/reports/{report.pk}/moderation-actions/')
        self.assertEqual([x['id'] for x in rr.data], [a.pk])

    def test_ban_user_does_not_double_log(self):
        report = self.make_report()
        self.patch_report(report, status='action_taken', ban_user=True)
        self.assertEqual(AdminLog.objects.filter(action='ban').count(), 1)
        self.assertFalse(AdminLog.objects.filter(action='moderation_action').exists())

    def test_ban_user_on_already_inactive_user_creates_nothing_new(self):
        self.target.is_active = False
        self.target.save()
        report = self.make_report()
        self.assertEqual(self.patch_report(report, ban_user=True, status='reviewed').status_code, 200)
        self.assertEqual(ModerationAction.objects.count(), 0)          # same as before: no-op

    def test_ban_user_still_works_when_new_api_suspension_already_exists(self):
        self.post_action(action_type='suspend_permanent')
        report = self.make_report()
        r = self.patch_report(report, status='action_taken', ban_user=True)
        self.assertEqual(r.status_code, 200, r.data)                   # never a 409 for legacy
        self.target.refresh_from_db()
        self.assertFalse(self.target.is_active)

    def test_reversing_legacy_ban_record_restores_account(self):
        report = self.make_report()
        self.patch_report(report, status='action_taken', ban_user=True)
        aid = ModerationAction.objects.get().pk
        r = self.client.post(f'{BASE}/moderation-actions/{aid}/reverse/',
                             {'reason': 'Ban was a mistake'}, format='json')
        self.assertEqual(r.status_code, 200, r.data)
        self.target.refresh_from_db()
        self.assertTrue(self.target.is_active)                         # account & record agree
        self.assertFalse(is_suspended(self.target))
        self.assertTrue(AdminLog.objects.filter(action='unban', target_user=self.target).exists())

    def test_reversing_new_api_suspension_does_not_touch_account_flag(self):
        aid = self.post_action(action_type='suspend_permanent').data['id']
        self.target.is_active = False          # e.g. banned independently via BanUserView
        self.target.save()
        self.client.post(f'{BASE}/moderation-actions/{aid}/reverse/',
                         {'reason': 'x'}, format='json')
        self.target.refresh_from_db()
        self.assertFalse(self.target.is_active)                        # left as the admin set it

    def test_legacy_unban_endpoint_lifts_legacy_ban_record(self):
        report = self.make_report()
        self.patch_report(report, status='action_taken', ban_user=True)
        r = self.client.patch(f'{BASE}/users/{self.target.pk}/ban/',
                              {'action': 'unban'}, format='json')
        self.assertEqual(r.status_code, 200)
        a = ModerationAction.objects.get()
        self.assertFalse(a.is_active)                                  # history kept, not deleted
        self.assertEqual(a.reversed_by, self.admin)
        self.assertFalse(is_suspended(self.target))                    # no lingering suspension

    def test_legacy_toggle_unban_lifts_legacy_ban_record(self):
        report = self.make_report()
        self.patch_report(report, status='action_taken', ban_user=True)
        r = self.client.post(f'{BASE}/users/{self.target.pk}/ban/', {}, format='json')  # toggle
        self.assertTrue(r.data['is_active'])
        self.assertFalse(is_suspended(self.target))

    def test_legacy_unban_leaves_new_api_actions_alone(self):
        aid = self.post_action(action_type='restrict_messaging').data['id']
        self.client.patch(f'{BASE}/users/{self.target.pk}/ban/', {'action': 'ban'}, format='json')
        self.client.patch(f'{BASE}/users/{self.target.pk}/ban/', {'action': 'unban'}, format='json')
        self.assertTrue(ModerationAction.objects.get(pk=aid).is_active)
        self.assertFalse(can_send_messages(self.target))

    def test_legacy_ban_endpoint_itself_still_works(self):
        r = self.client.patch(f'{BASE}/users/{self.target.pk}/ban/', {'action': 'ban'}, format='json')
        self.assertEqual(r.status_code, 200)
        self.assertFalse(r.data['is_active'])


# ══════════════════════════════════════════════════════════════════════════════
# Trust & Safety Part 5 — moderation notifications
# ══════════════════════════════════════════════════════════════════════════════

def _utc(dt):
    return dt.astimezone(dt_timezone.utc).strftime('%d %b %Y, %H:%M UTC')


class ModerationNotificationBase(ModerationAPITestBase):
    """
    Notifications are scheduled with transaction.on_commit, which Django's
    TestCase never fires on its own — so anything that should notify is wrapped
    in captureOnCommitCallbacks(execute=True). The real DB Notification model
    is used; only the FCM network call is mocked.
    """

    def setUp(self):
        super().setUp()
        self.target.fcm_token = 'fcm-target-token'
        self.target.save()
        patcher = mock.patch('apps.notifications.utils.send_fcm_push', return_value=True)
        self.fcm = patcher.start()
        self.addCleanup(patcher.stop)

    def act(self, **overrides):
        with self.captureOnCommitCallbacks(execute=True):
            return self.post_action(**overrides)

    def reverse(self, action_id, reason='Internal: appeal looked fine'):
        with self.captureOnCommitCallbacks(execute=True):
            return self.client.post(f'{BASE}/moderation-actions/{action_id}/reverse/',
                                    {'reason': reason}, format='json')

    def notes(self, user):
        return list(Notification.objects.filter(user=user).order_by('id'))

    def only_note(self, user):
        notes = self.notes(user)
        self.assertEqual(len(notes), 1, [n.title for n in notes])
        return notes[0]


class ModerationActionNotificationTests(ModerationNotificationBase):

    # ── 1. warning ───────────────────────────────────────────────────────────
    def test_warning_notifies_affected_user_with_reason(self):
        r = self.act(action_type='warning', reason='Abusive language in chat')
        self.assertEqual(r.status_code, 201, r.data)
        n = self.only_note(self.target)
        self.assertEqual(n.type, 'report')                     # existing type, none added
        self.assertEqual(n.title, 'Community Guidelines Warning')
        self.assertIn('reviewed', n.message)
        self.assertIn('violation of our community guidelines', n.message)
        self.assertIn('Abusive language in chat', n.message)
        self.assertFalse(n.is_read)

    def test_warning_is_pushed_via_existing_fcm_helper(self):
        r = self.act(action_type='warning', reason='Abusive language in chat')
        self.fcm.assert_called_once()
        args, kwargs = self.fcm.call_args
        self.assertEqual(args[0], 'fcm-target-token')
        self.assertEqual(args[1], 'Community Guidelines Warning')
        self.assertIn('Abusive language in chat', args[2])
        self.assertEqual(kwargs['data']['event'], 'warning_issued')
        self.assertEqual(kwargs['data']['moderation_action_id'], r.data['id'])

    def test_warning_only_notifies_the_affected_user(self):
        self.act(action_type='warning')
        for u in (self.admin, self.admin2, self.reporter, self.other):
            self.assertEqual(self.notes(u), [], u.email)

    def test_user_without_fcm_token_still_gets_db_notification(self):
        User.objects.filter(pk=self.target.pk).update(fcm_token=None)
        self.act(action_type='warning')
        self.assertEqual(len(self.notes(self.target)), 1)
        self.fcm.assert_not_called()

    # ── 2 / 4. restrictions ──────────────────────────────────────────────────
    def test_messaging_restriction_notification(self):
        self.act(action_type='restrict_messaging', reason='Spamming other users')
        n = self.only_note(self.target)
        self.assertEqual(n.title, 'Messaging Restricted')
        self.assertIn('Spamming other users', n.message)
        self.assertIn('Status: Active', n.message)
        self.assertIn('messaging only', n.message)
        self.assertEqual(self.fcm.call_args.kwargs['data']['event'], 'messaging_restricted')

    def test_messaging_restriction_with_expiry_states_end(self):
        exp = timezone.now() + timedelta(days=2)
        self.act(action_type='restrict_messaging', expires_at=exp.isoformat())
        n = self.only_note(self.target)
        self.assertIn('Active until', n.message)
        self.assertIn(_utc(ModerationAction.objects.get().expires_at), n.message)

    def test_booking_restriction_notification(self):
        self.act(action_type='restrict_booking', reason='Repeated no-shows')
        n = self.only_note(self.target)
        self.assertEqual(n.title, 'Booking Restricted')
        self.assertIn('Repeated no-shows', n.message)
        self.assertIn('bookings', n.message)
        self.assertEqual(self.fcm.call_args.kwargs['data']['event'], 'booking_restricted')

    # ── 5. temporary suspension ──────────────────────────────────────────────
    def test_temporary_suspension_notification_has_reason_start_and_end(self):
        exp = timezone.now() + timedelta(days=7)
        self.act(action_type='suspend_temporary', reason='Fraud pattern',
                 expires_at=exp.isoformat())
        a = ModerationAction.objects.get()
        n = self.only_note(self.target)
        self.assertEqual(n.title, 'Account Temporarily Suspended')
        self.assertIn('Fraud pattern', n.message)
        self.assertIn(f'Suspension started: {_utc(a.starts_at)}', n.message)
        self.assertIn(f'Suspension ends: {_utc(a.expires_at)}', n.message)
        data = self.fcm.call_args.kwargs['data']
        self.assertEqual(data['event'], 'account_suspended')
        self.assertEqual(data['action_type'], 'suspend_temporary')
        self.assertEqual(data['expires_at'], a.expires_at.isoformat())

    # ── 6. permanent suspension ──────────────────────────────────────────────
    def test_permanent_suspension_notification(self):
        self.act(action_type='suspend_permanent', reason='Confirmed scam')
        a = ModerationAction.objects.get()
        n = self.only_note(self.target)
        self.assertEqual(n.title, 'Account Permanently Suspended')
        self.assertIn('permanently suspended', n.message)
        self.assertIn('Confirmed scam', n.message)
        self.assertIn(f'Suspension started: {_utc(a.starts_at)}', n.message)
        self.assertIn('no end date', n.message)
        self.assertNotIn('Suspension ends', n.message)
        self.assertNotIn('expires_at', self.fcm.call_args.kwargs['data'])

    def test_no_appeal_promise_while_appeals_are_not_implemented(self):
        for t in ('warning', 'restrict_messaging', 'restrict_booking', 'suspend_permanent'):
            self.act(action_type=t)
        for n in self.notes(self.target):
            self.assertNotIn('appeal', n.message.lower(), n.title)

    # ── 7. reversal ──────────────────────────────────────────────────────────
    def test_reversing_restriction_notifies_user(self):
        aid = self.act(action_type='restrict_messaging').data['id']
        self.reverse(aid)
        notes = self.notes(self.target)
        self.assertEqual([n.title for n in notes], ['Messaging Restricted', 'Restriction Lifted'])
        self.assertIn('messaging restriction', notes[1].message)
        self.assertIn('lifted', notes[1].message)
        self.assertEqual(self.fcm.call_args.kwargs['data']['event'], 'restriction_lifted')
        self.assertEqual(self.fcm.call_args.kwargs['data']['status'], 'reversed')

    def test_reversing_suspension_notifies_user(self):
        aid = self.act(action_type='suspend_permanent').data['id']
        self.reverse(aid)
        last = self.notes(self.target)[-1]
        self.assertEqual(last.title, 'Suspension Lifted')
        self.assertIn('permanent suspension', last.message)

    def test_reversal_notification_does_not_leak_internal_reversal_reason(self):
        aid = self.act(action_type='restrict_booking').data['id']
        self.reverse(aid, reason='INTERNAL-SECRET: admin disagreed with colleague')
        for n in self.notes(self.target):
            self.assertNotIn('INTERNAL-SECRET', n.message)
            self.assertNotIn('INTERNAL-SECRET', n.title)
        for call in self.fcm.call_args_list:
            self.assertNotIn('INTERNAL-SECRET', str(call))

    def test_reversing_a_warning_does_not_notify(self):
        aid = self.act(action_type='warning').data['id']
        self.reverse(aid)
        self.assertEqual(len(self.notes(self.target)), 1)      # just the original warning

    def test_repeated_reversal_does_not_duplicate_notification(self):
        aid = self.act(action_type='restrict_messaging').data['id']
        self.assertEqual(self.reverse(aid).status_code, 200)
        self.assertEqual(self.reverse(aid).status_code, 409)
        lifted = [n for n in self.notes(self.target) if n.title == 'Restriction Lifted']
        self.assertEqual(len(lifted), 1)

    # ── lifecycle safety ─────────────────────────────────────────────────────
    def test_rejected_or_unauthorized_requests_send_nothing(self):
        self.act(action_type='suspend_temporary')               # invalid: no expiry
        self.act(target_user=999999)                            # invalid target
        self.client.force_authenticate(self.other)              # not an admin
        self.act()
        self.assertEqual(Notification.objects.count(), 0)
        self.fcm.assert_not_called()

    def test_conflict_sends_no_second_notification(self):
        self.act(action_type='restrict_booking')
        self.assertEqual(self.act(action_type='restrict_booking').status_code, 409)
        self.assertEqual(len(self.notes(self.target)), 1)

    def test_database_state_is_authoritative_over_pending_notification(self):
        # Action is created, but reversed in the DB before its notification runs.
        with self.captureOnCommitCallbacks(execute=False) as callbacks:
            aid = self.post_action(action_type='restrict_messaging').data['id']
        ModerationAction.objects.filter(pk=aid).update(is_active=False)
        for cb in callbacks:
            cb()
        self.assertEqual(self.notes(self.target), [])           # no stale "you're restricted"

    def test_nothing_is_sent_if_transaction_never_commits(self):
        with self.captureOnCommitCallbacks(execute=False):
            self.post_action(action_type='restrict_messaging')
        # callbacks captured but never executed == commit didn't happen
        self.assertEqual(Notification.objects.count(), 0)

    def test_notification_failure_never_breaks_the_moderation_action(self):
        with mock.patch('apps.admin_panel.moderation_notifications.notify_user',
                        side_effect=RuntimeError('fcm exploded')):
            r = self.act(action_type='suspend_permanent')
        self.assertEqual(r.status_code, 201)
        self.assertTrue(ModerationAction.objects.get(pk=r.data['id']).is_active)

    def test_reversal_survives_notification_failure(self):
        aid = self.act(action_type='restrict_messaging').data['id']
        with mock.patch('apps.admin_panel.moderation_notifications.notify_user',
                        side_effect=RuntimeError('boom')):
            r = self.reverse(aid)
        self.assertEqual(r.status_code, 200)
        self.assertFalse(ModerationAction.objects.get(pk=aid).is_active)

    def test_notification_is_not_the_source_of_truth(self):
        # Deleting the notification changes nothing about enforcement.
        self.act(action_type='restrict_messaging')
        Notification.objects.all().delete()
        self.assertFalse(can_send_messages(self.target))
        self.assertTrue(ModerationAction.objects.get().is_active)


class ModerationNotificationPrivacyTests(ModerationNotificationBase):
    """Reporter identity, report ids and internal notes must never reach the reported user."""

    def setUp(self):
        super().setUp()
        self.reporter.name = 'Zainab Qureshi'
        self.reporter.save()
        self.report = self.make_report(description='reporter private description')

    def everything_target_received(self):
        blob = []
        for n in self.notes(self.target):
            blob += [n.title, n.message, n.type]
        for call in self.fcm.call_args_list:
            blob.append(str(call))
        return '\n'.join(blob)

    def assert_no_leaks(self):
        blob = self.everything_target_received().lower()
        for secret in ('zainab', 'qureshi', 'reporter@test.com', 'reporter private description',
                       'internal note xyz', 'admin@test.com', 'admin two'):
            self.assertNotIn(secret, blob, secret)
        for call in self.fcm.call_args_list:
            data = call.kwargs['data']
            self.assertNotIn('report_id', data)
            self.assertNotIn('reporter', ' '.join(data.keys()).lower())
            self.assertNotIn(str(self.reporter.pk) + '_', str(data))

    def test_linked_report_does_not_leak_reporter_or_internal_note(self):
        for t, extra in (('warning', {}), ('restrict_messaging', {}), ('restrict_booking', {}),
                         ('suspend_temporary', {'expires_at': _future()}),
                         ('suspend_permanent', {})):
            r = self.act(action_type=t, report=self.report.pk, reason='Harassing another member',
                         admin_note='INTERNAL NOTE XYZ', **extra)
            self.assertEqual(r.status_code, 201, (t, r.data))
        self.assertEqual(len(self.notes(self.target)), 5)
        self.assert_no_leaks()
        self.assertIn('Harassing another member', self.everything_target_received())

    def test_admin_note_never_used_even_when_no_report(self):
        self.act(action_type='restrict_messaging', admin_note='INTERNAL NOTE XYZ')
        self.assert_no_leaks()

    def test_reporter_identity_typed_into_reason_is_redacted(self):
        self.act(action_type='warning', report=self.report.pk,
                 reason='Reported by Zainab Qureshi (reporter@test.com) for insults')
        n = self.only_note(self.target)
        self.assertNotIn('Zainab', n.message)
        self.assertNotIn('reporter@test.com', n.message)
        self.assertIn('[redacted]', n.message)
        self.assertIn('for insults', n.message)
        self.assert_no_leaks()

    def test_acting_admin_identity_not_in_notification(self):
        self.act(action_type='warning')
        self.assertNotIn(self.admin.name.lower(), self.everything_target_received().lower())

    def test_other_users_moderation_is_never_included(self):
        ModerationAction.objects.create(
            target_user=self.other, performed_by=self.admin, action_type='suspend_permanent',
            reason='OTHER-USERS-SECRET-REASON')
        self.act(action_type='warning')
        self.assertNotIn('OTHER-USERS-SECRET-REASON', self.everything_target_received())
        self.assertEqual(self.notes(self.other), [])

    def test_long_reason_is_truncated(self):
        self.act(action_type='warning', reason='x' * 1900)
        n = self.only_note(self.target)
        self.assertLess(len(n.message), 900)


class NewReportAdminNotificationTests(ModerationNotificationBase):

    def submit(self, user=None, **overrides):
        c = APIClient()
        c.force_authenticate(user or self.reporter)
        payload = {'reported_user': self.target.pk, 'reason': 'harassment',
                   'description': 'private details'}
        payload.update(overrides)
        with self.captureOnCommitCallbacks(execute=True):
            return c.post(f'{BASE}/reports/create/', payload, format='json')

    def test_all_admins_are_notified_of_new_report(self):
        r = self.submit()
        self.assertEqual(r.status_code, 201, r.data)
        for adm in (self.admin, self.admin2):
            n = [x for x in self.notes(adm) if x.title == 'New Report Submitted']
            self.assertEqual(len(n), 1, adm.email)
            self.assertEqual(n[0].type, 'report')
            self.assertIn('Harassment', n[0].message)
            self.assertIn(self.target.name, n[0].message)
            self.assertNotIn('private details', n[0].message)

    def test_admin_alert_is_pushed_through_existing_fcm(self):
        User.objects.filter(pk=self.admin.pk).update(fcm_token='fcm-admin-token')
        r = self.submit()
        pushed = [c for c in self.fcm.call_args_list if c.args[0] == 'fcm-admin-token']
        self.assertEqual(len(pushed), 1)
        self.assertEqual(pushed[0].kwargs['data']['event'], 'report_submitted')
        self.assertEqual(pushed[0].kwargs['data']['report_id'], r.data['id'])

    def test_reported_user_is_not_told_about_a_new_report(self):
        self.submit()
        self.assertEqual(self.notes(self.target), [])
        self.fcm.assert_not_called()              # target is the only one with a token

    def test_reporter_still_gets_their_own_confirmation(self):
        self.submit()
        titles = [n.title for n in self.notes(self.reporter)]
        self.assertEqual(titles, ['Report Submitted'])

    def test_non_admins_are_not_alerted(self):
        self.submit()
        self.assertEqual(self.notes(self.other), [])

    def test_invalid_report_notifies_nobody(self):
        r = self.submit(reason='not-a-reason')
        self.assertEqual(r.status_code, 400)
        self.assertEqual(Notification.objects.count(), 0)

    def test_admin_notification_failure_does_not_fail_report_submission(self):
        with mock.patch('apps.admin_panel.moderation_notifications.notify_admins',
                        side_effect=RuntimeError('down')):
            r = self.submit()
        self.assertEqual(r.status_code, 201)
        self.assertEqual(UserReport.objects.count(), 1)


class ReportResolutionNotificationTests(ModerationNotificationBase):
    """Reporter privacy + no-duplicates for the legacy PATCH /reports/<id>/ flow."""

    GENERIC = 'Your report has been reviewed and appropriate action has been taken.'

    def setUp(self):
        super().setUp()
        self.report = self.make_report(admin_note='')

    def patch(self, **body):
        with self.captureOnCommitCallbacks(execute=True):
            return self.client.patch(f'{BASE}/reports/{self.report.pk}/', body, format='json')

    def reporter_notes(self):
        return [n for n in self.notes(self.reporter) if n.title == 'Your Report Was Reviewed']

    # ── reporter gets only a generic outcome ─────────────────────────────────
    def test_reporter_gets_generic_outcome_without_punishment_details(self):
        r = self.patch(status='action_taken', ban_user=True,
                       admin_note='INTERNAL NOTE XYZ: 30 day plan')
        self.assertEqual(r.status_code, 200, r.data)
        n = self.reporter_notes()
        self.assertEqual(len(n), 1)
        self.assertEqual(n[0].message, self.GENERIC)
        blob = (n[0].title + n[0].message).lower()
        for banned in ('suspend', 'ban', 'permanent', 'temporar', 'restrict', 'warning',
                       'day', 'internal note', 'target@test.com', 'target'):
            self.assertNotIn(banned, blob, banned)
        for call in self.fcm.call_args_list:                     # nothing pushed to reporter
            self.assertNotEqual(call.args[0], 'fcm-reporter')

    def test_reporter_notification_data_has_no_moderation_details(self):
        User.objects.filter(pk=self.reporter.pk).update(fcm_token='fcm-reporter')
        self.patch(status='action_taken', ban_user=True)
        pushes = [c for c in self.fcm.call_args_list if c.args[0] == 'fcm-reporter']
        self.assertEqual(len(pushes), 1)
        data = pushes[0].kwargs['data']
        self.assertEqual(set(data), {'report_id', 'event', 'status'})
        self.assertEqual(data['event'], 'report_resolved')
        self.assertNotIn('moderation_action_id', data)
        self.assertNotIn('action_type', data)

    def test_dismissed_reporter_generic_and_reported_user_not_told(self):
        self.patch(status='dismissed')
        self.assertEqual(len(self.reporter_notes()), 1)
        self.assertNotIn('appropriate action', self.reporter_notes()[0].message)
        self.assertEqual(self.notes(self.target), [])

    def test_reviewed_only_does_not_notify_reported_user(self):
        self.patch(status='reviewed')
        self.assertEqual(len(self.reporter_notes()), 1)
        self.assertEqual(self.notes(self.target), [])

    # ── reported user: rich notification, no duplicates, no leaks ────────────
    def test_ban_user_sends_single_detailed_suspension_notice_to_reported_user(self):
        self.patch(status='action_taken', ban_user=True, admin_note='INTERNAL NOTE XYZ')
        notes = self.notes(self.target)
        self.assertEqual([n.title for n in notes], ['Account Permanently Suspended'])
        self.assertNotIn('INTERNAL NOTE XYZ', notes[0].message)   # admin_note stays internal
        self.assertNotIn('report #', notes[0].message.lower())
        self.assertIn('community guidelines', notes[0].message)
        self.assertNotIn('report_id', self.fcm.call_args.kwargs['data'])

    def test_legacy_ban_keeps_internal_note_out_of_reason_but_in_admin_note(self):
        self.patch(status='action_taken', ban_user=True, admin_note='INTERNAL NOTE XYZ')
        a = ModerationAction.objects.get()
        self.assertNotIn('INTERNAL NOTE XYZ', a.reason)
        self.assertNotIn('#', a.reason)
        self.assertEqual(a.admin_note, 'INTERNAL NOTE XYZ')

    def test_legacy_action_taken_without_action_still_sends_generic_warning_once(self):
        self.patch(status='action_taken')
        notes = self.notes(self.target)
        self.assertEqual([n.title for n in notes], ['Community Guidelines Warning'])
        self.assertNotIn('report_id', self.fcm.call_args.kwargs['data'])
        self.patch(status='action_taken', admin_note='edited note only')   # same status again
        self.assertEqual(len(self.notes(self.target)), 1)                  # not duplicated

    def test_action_taken_after_new_api_action_does_not_send_second_warning(self):
        self.act(action_type='restrict_messaging', report=self.report.pk, reason='Spam')
        self.assertEqual(len(self.notes(self.target)), 1)
        self.patch(status='action_taken')
        self.assertEqual([n.title for n in self.notes(self.target)], ['Messaging Restricted'])
        self.assertEqual(len(self.reporter_notes()), 1)                    # reporter still told

    def test_repeat_patch_same_status_does_not_renotify_reporter(self):
        self.patch(status='reviewed')
        self.patch(status='reviewed', admin_note='more notes')
        self.assertEqual(len(self.reporter_notes()), 1)

    def test_status_change_notifies_reporter_again(self):
        self.patch(status='reviewed')
        self.patch(status='action_taken')
        self.assertEqual(len(self.reporter_notes()), 2)

    def test_resetting_to_pending_does_not_notify_reporter(self):
        self.patch(status='pending', admin_note='x')
        self.assertEqual(self.reporter_notes(), [])

    def test_ban_on_report_with_existing_new_api_suspension_notifies_reported_user_of_each(self):
        self.act(action_type='suspend_permanent', reason='First reason')
        self.patch(status='action_taken', ban_user=True)
        titles = [n.title for n in self.notes(self.target)]
        self.assertEqual(titles, ['Account Permanently Suspended'] * 2)     # two real actions

    # ── legacy unban → lifted notice ─────────────────────────────────────────
    def test_legacy_unban_of_report_ban_notifies_reported_user(self):
        self.patch(status='action_taken', ban_user=True)
        with self.captureOnCommitCallbacks(execute=True):
            self.client.patch(f'{BASE}/users/{self.target.pk}/ban/',
                              {'action': 'unban'}, format='json')
        self.assertEqual([n.title for n in self.notes(self.target)],
                         ['Account Permanently Suspended', 'Suspension Lifted'])

    def test_reversing_report_ban_via_new_api_notifies_once(self):
        self.patch(status='action_taken', ban_user=True)
        aid = ModerationAction.objects.get().pk
        self.reverse(aid)
        lifted = [n for n in self.notes(self.target) if n.title == 'Suspension Lifted']
        self.assertEqual(len(lifted), 1)


# ══════════════════════════════════════════════════════════════════════════════
# Trust & Safety Part 6 — appeals
# ══════════════════════════════════════════════════════════════════════════════

class AppealTestBase(ModerationNotificationBase):
    """
    `self.client`       -> authenticated admin (from the Part 4 base)
    `self.user_client`  -> the affected user (self.target)
    `self.other_client` -> a second affected user (self.victim2)
    Actions are created straight through the ORM so notification assertions
    only see appeal-related messages; everything that should notify is wrapped
    in captureOnCommitCallbacks(execute=True) (see the Part 5 base).
    """

    def setUp(self):
        super().setUp()
        self.victim2 = User.objects.create_user(
            email='victim2@test.com', name='Second Victim', role='professional', password='pass1234')
        self.victim2.fcm_token = 'fcm-victim2-token'
        self.victim2.save()

        self.user_client = APIClient()
        self.user_client.force_authenticate(self.target)
        self.other_client = APIClient()
        self.other_client.force_authenticate(self.victim2)

        self.report = self.make_report(admin_note='INTERNAL REPORT NOTE')
        self.action = self.make_action(report=self.report)

    # ── helpers ──────────────────────────────────────────────────────────────
    def make_action(self, user=None, action_type='restrict_messaging', **kw):
        defaults = dict(target_user=user or self.target, performed_by=self.admin,
                        action_type=action_type, reason='Spamming other users',
                        admin_note='INTERNAL ACTION NOTE')
        defaults.update(kw)
        return ModerationAction.objects.create(**defaults)

    def submit(self, action=None, client=None, **overrides):
        action = action or self.action
        payload = {'moderation_action': getattr(action, 'pk', action),
                   'reason': 'This was a mistake, please review it.'}
        payload.update(overrides)
        with self.captureOnCommitCallbacks(execute=True):
            return (client or self.user_client).post(
                f'{BASE}/appeals/create/', payload, format='json')

    def decide(self, appeal_id, verb, client=None, **body):
        with self.captureOnCommitCallbacks(execute=True):
            return (client or self.client).post(
                f'{BASE}/appeals/{appeal_id}/{verb}/', body, format='json')

    def make_appeal(self, action=None, user=None, **kw):
        """Appeal created directly (no API / no notifications)."""
        action = action or self.action
        return Appeal.objects.create(
            user=user or action.target_user, moderation_action=action,
            report=action.report, reason=kw.pop('reason', 'please review'), **kw)


class AppealSubmissionTests(AppealTestBase):

    def test_valid_appeal_is_created(self):
        r = self.submit(evidence_url='https://example.com/proof.png')
        self.assertEqual(r.status_code, 201, r.data)
        a = Appeal.objects.get(pk=r.data['id'])
        self.assertEqual(a.user, self.target)
        self.assertEqual(a.moderation_action, self.action)
        self.assertEqual(a.report, self.report)                 # copied by the server
        self.assertEqual(a.reason, 'This was a mistake, please review it.')
        self.assertEqual(a.evidence_url, 'https://example.com/proof.png')
        self.assertEqual(a.status, 'pending')
        self.assertIsNone(a.reviewed_by)
        self.assertIsNone(a.resolved_at)
        self.assertEqual(a.decision_note, '')
        self.assertIsNotNone(a.created_at)
        self.assertEqual(r.data['status'], 'pending')
        self.assertEqual(r.data['moderation_action'], self.action.pk)

    def test_submitting_does_not_change_the_action(self):
        self.submit()
        self.action.refresh_from_db()
        self.assertTrue(self.action.is_active)
        self.assertIsNone(self.action.reversed_at)
        self.assertFalse(can_send_messages(self.target))        # still enforced while pending

    def test_appeal_without_a_report_is_fine(self):
        a = self.make_action(action_type='restrict_booking')      # no report
        r = self.submit(a)
        self.assertEqual(r.status_code, 201, r.data)
        self.assertIsNone(Appeal.objects.get(pk=r.data['id']).report)

    def test_warning_can_be_appealed(self):
        a = self.make_action(action_type='warning')
        self.assertEqual(self.submit(a).status_code, 201)

    def test_every_action_type_can_be_appealed(self):
        for t, extra in (('warning', {}), ('restrict_messaging', {}), ('restrict_booking', {}),
                         ('suspend_temporary', {'expires_at': timezone.now() + timedelta(days=3)}),
                         ('suspend_permanent', {})):
            a = self.make_action(action_type=t, **extra)
            self.assertEqual(self.submit(a).status_code, 201, t)

    # ── the client cannot set server-controlled fields ───────────────────────
    def test_client_cannot_set_status_reviewer_note_timestamps_user_or_report(self):
        other_report = self.make_report(reported=self.victim2)
        r = self.submit(
            status='approved', reviewed_by=self.admin.pk, decision_note='pre-approved',
            resolved_at='2000-01-01T00:00:00Z', created_at='2000-01-01T00:00:00Z',
            user=self.victim2.pk, report=other_report.pk, admin_note='x')
        self.assertEqual(r.status_code, 201, r.data)
        a = Appeal.objects.get(pk=r.data['id'])
        self.assertEqual(a.status, 'pending')
        self.assertIsNone(a.reviewed_by)
        self.assertEqual(a.decision_note, '')
        self.assertIsNone(a.resolved_at)
        self.assertGreater(a.created_at.year, 2000)
        self.assertEqual(a.user, self.target)                    # not victim2
        self.assertEqual(a.report, self.report)                  # not other_report
        self.action.refresh_from_db()
        self.assertTrue(self.action.is_active)                   # "approved" was ignored

    # ── ownership ────────────────────────────────────────────────────────────
    def test_user_cannot_appeal_another_users_action(self):
        theirs = self.make_action(user=self.victim2, reason='Their private reason')
        r = self.submit(theirs)
        self.assertEqual(r.status_code, 400)
        self.assertIn('moderation_action', r.data)
        self.assertEqual(Appeal.objects.count(), 0)
        self.assertEqual(Notification.objects.count(), 0)

    def test_foreign_and_nonexistent_actions_are_indistinguishable(self):
        theirs = self.make_action(user=self.victim2)
        foreign = self.submit(theirs)
        missing = self.submit(999999)
        self.assertEqual(foreign.status_code, missing.status_code)
        self.assertEqual(foreign.data, missing.data)             # can't probe ids

    def test_foreign_action_response_leaks_nothing_about_it(self):
        theirs = self.make_action(user=self.victim2, reason='Their private reason')
        r = self.submit(theirs)
        self.assertNotIn('Their private reason', str(r.data))
        self.assertNotIn('victim2', str(r.data))

    def test_admin_cannot_file_an_appeal_for_someone_elses_action(self):
        r = self.submit(self.action, client=self.client)          # self.client is the admin
        self.assertEqual(r.status_code, 400)
        self.assertEqual(Appeal.objects.count(), 0)

    def test_unauthenticated_cannot_appeal(self):
        c = APIClient()
        r = self.submit(client=c)
        self.assertIn(r.status_code, (401, 403))
        self.assertEqual(Appeal.objects.count(), 0)

    # ── input validation ─────────────────────────────────────────────────────
    def test_reason_required(self):
        for bad in ('', '   '):
            r = self.submit(reason=bad)
            self.assertEqual(r.status_code, 400, repr(bad))
            self.assertIn('reason', r.data)
        r = self.user_client.post(f'{BASE}/appeals/create/',
                                  {'moderation_action': self.action.pk}, format='json')
        self.assertEqual(r.status_code, 400)
        self.assertEqual(Appeal.objects.count(), 0)

    def test_action_id_required(self):
        r = self.user_client.post(f'{BASE}/appeals/create/', {'reason': 'x'}, format='json')
        self.assertEqual(r.status_code, 400)
        self.assertIn('moderation_action', r.data)

    def test_evidence_url_is_optional_but_must_be_http(self):
        self.assertEqual(self.submit(evidence_url='').status_code, 201)
        Appeal.objects.all().delete()
        for bad in ('javascript:alert(1)', 'ftp://example.com/x', 'not a url', 'file:///etc/passwd'):
            r = self.submit(evidence_url=bad)
            self.assertEqual(r.status_code, 400, bad)
            self.assertIn('evidence_url', r.data)
        self.assertEqual(Appeal.objects.count(), 0)

    # ── state of the action ──────────────────────────────────────────────────
    def test_reversed_action_cannot_be_appealed(self):
        ModerationAction.objects.filter(pk=self.action.pk).update(is_active=False)
        r = self.submit()
        self.assertEqual(r.status_code, 409)
        self.assertEqual(Appeal.objects.count(), 0)

    def test_expired_action_cannot_be_appealed(self):
        a = self.make_action(action_type='restrict_booking',
                             expires_at=timezone.now() + timedelta(hours=1))
        ModerationAction.objects.filter(pk=a.pk).update(
            expires_at=timezone.now() - timedelta(minutes=1))
        self.assertEqual(self.submit(a).status_code, 409)

    # ── duplicates ───────────────────────────────────────────────────────────
    def test_duplicate_pending_appeal_is_rejected(self):
        self.assertEqual(self.submit().status_code, 201)
        r = self.submit(reason='trying again')
        self.assertEqual(r.status_code, 409)
        self.assertEqual(Appeal.objects.filter(moderation_action=self.action).count(), 1)

    def test_duplicate_does_not_send_a_second_notification(self):
        self.submit()
        self.submit()
        confirmations = [n for n in self.notes(self.target) if n.title == 'Appeal Submitted']
        self.assertEqual(len(confirmations), 1)

    def test_different_actions_can_each_have_a_pending_appeal(self):
        second = self.make_action(action_type='restrict_booking')
        self.assertEqual(self.submit(self.action).status_code, 201)
        self.assertEqual(self.submit(second).status_code, 201)

    def test_two_users_can_each_appeal_their_own_action(self):
        mine = self.submit(self.action)
        theirs_action = self.make_action(user=self.victim2)
        theirs = self.submit(theirs_action, client=self.other_client)
        self.assertEqual((mine.status_code, theirs.status_code), (201, 201))

    def test_can_appeal_again_after_a_rejection(self):
        first = self.submit().data['id']
        self.decide(first, 'reject', decision_note='not convincing')
        self.assertEqual(self.submit(reason='new evidence').status_code, 201)
        self.assertEqual(Appeal.objects.filter(moderation_action=self.action).count(), 2)

    def test_database_itself_blocks_a_second_pending_appeal(self):
        self.make_appeal()
        with self.assertRaises(IntegrityError), transaction.atomic():
            self.make_appeal()

    def test_database_blocks_status_and_resolved_at_disagreeing(self):
        with self.assertRaises(IntegrityError), transaction.atomic():
            self.make_appeal(status='approved')                   # resolved_at missing
        with self.assertRaises(IntegrityError), transaction.atomic():
            self.make_appeal(status='pending', resolved_at=timezone.now())


class AppealSubmissionNotificationTests(AppealTestBase):

    def test_user_is_notified_that_appeal_was_submitted(self):
        r = self.submit()
        n = [x for x in self.notes(self.target) if x.title == 'Appeal Submitted']
        self.assertEqual(len(n), 1)
        self.assertEqual(n[0].type, 'report')                    # existing type, none added
        self.assertIn('received your appeal', n[0].message)
        self.assertIn('messaging restriction', n[0].message)
        pushes = [c for c in self.fcm.call_args_list if c.args[0] == 'fcm-target-token']
        self.assertEqual(len(pushes), 1)
        self.assertEqual(pushes[0].kwargs['data']['event'], 'appeal_submitted')
        self.assertEqual(pushes[0].kwargs['data']['appeal_id'], r.data['id'])

    def test_admins_are_alerted_to_a_new_appeal(self):
        User.objects.filter(pk=self.admin.pk).update(fcm_token='fcm-admin-token')
        self.submit()
        for adm in (self.admin, self.admin2):
            n = [x for x in self.notes(adm) if x.title == 'New Appeal Submitted']
            self.assertEqual(len(n), 1, adm.email)
            self.assertIn(self.target.name, n[0].message)
        self.assertTrue(any(c.args[0] == 'fcm-admin-token' for c in self.fcm.call_args_list))

    def test_nobody_else_is_notified(self):
        self.submit()
        self.assertEqual(self.notes(self.victim2), [])
        self.assertEqual(self.notes(self.other), [])
        self.assertEqual(self.notes(self.reporter), [])          # reporter never hears of appeals

    def test_rejected_submissions_send_nothing(self):
        self.submit(reason='')                                   # invalid
        self.submit(self.make_action(user=self.victim2))         # not theirs
        self.assertEqual(Notification.objects.count(), 0)

    def test_notification_failure_does_not_break_submission(self):
        with mock.patch('apps.admin_panel.moderation_notifications.notify_user',
                        side_effect=RuntimeError('fcm down')):
            r = self.submit()
        self.assertEqual(r.status_code, 201)
        self.assertEqual(Appeal.objects.count(), 1)


class AppealReviewPermissionTests(AppealTestBase):

    def setUp(self):
        super().setUp()
        self.appeal = self.make_appeal()

    def assert_denied_and_untouched(self, client, expected=(401, 403)):
        a = self.appeal.pk
        responses = [
            client.get(f'{BASE}/appeals/'),
            client.get(f'{BASE}/appeals/{a}/'),
            client.post(f'{BASE}/appeals/{a}/approve/', {'decision_note': 'x'}, format='json'),
            client.post(f'{BASE}/appeals/{a}/reject/', {'decision_note': 'x'}, format='json'),
        ]
        for r in responses:
            self.assertIn(r.status_code, expected)
        self.appeal.refresh_from_db()
        self.action.refresh_from_db()
        self.assertEqual(self.appeal.status, 'pending')
        self.assertTrue(self.action.is_active)
        self.assertIsNone(self.action.reversed_at)

    def test_customer_and_professional_cannot_review(self):
        self.assert_denied_and_untouched(self.other_client, expected=(403,))
        c = APIClient()
        c.force_authenticate(self.other)
        self.assert_denied_and_untouched(c, expected=(403,))

    def test_the_appealing_user_cannot_review_their_own_appeal(self):
        self.assert_denied_and_untouched(self.user_client, expected=(403,))

    def test_unauthenticated_cannot_review(self):
        self.assert_denied_and_untouched(APIClient())

    def test_admin_can_list_pending_appeals(self):
        approved = self.make_appeal(action=self.make_action(action_type='restrict_booking'),
                                    status='approved', resolved_at=timezone.now())
        r = self.client.get(f'{BASE}/appeals/?status=pending')
        self.assertEqual(r.status_code, 200)
        self.assertEqual([x['id'] for x in r.data], [self.appeal.pk])
        allr = self.client.get(f'{BASE}/appeals/')
        self.assertEqual({x['id'] for x in allr.data}, {self.appeal.pk, approved.pk})

    def test_admin_list_filters_and_validation(self):
        self.make_appeal(action=self.make_action(action_type='restrict_booking'),
                         status='rejected', resolved_at=timezone.now())
        self.assertEqual(len(self.client.get(f'{BASE}/appeals/?status=rejected').data), 1)
        self.assertEqual(self.client.get(f'{BASE}/appeals/?status=bogus').status_code, 400)

    def test_admin_detail_includes_review_context(self):
        r = self.client.get(f'{BASE}/appeals/{self.appeal.pk}/')
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data['user_email'], 'target@test.com')
        self.assertEqual(r.data['report'], self.report.pk)
        self.assertEqual(r.data['moderation_action_detail']['id'], self.action.pk)
        self.assertEqual(r.data['moderation_action_detail']['status'], 'active')
        self.assertIn('decision_note', r.data)

    def test_unknown_appeal_is_404_for_admin(self):
        self.assertEqual(self.client.get(f'{BASE}/appeals/999999/').status_code, 404)
        self.assertEqual(self.decide(999999, 'approve').status_code, 404)
        self.assertEqual(self.decide(999999, 'reject', decision_note='x').status_code, 404)


class AppealApprovalTests(AppealTestBase):

    def setUp(self):
        super().setUp()
        self.appeal = self.make_appeal()

    def test_approval_reverses_the_moderation_action(self):
        self.assertFalse(can_send_messages(self.target))
        r = self.decide(self.appeal.pk, 'approve', decision_note='Evidence checks out')
        self.assertEqual(r.status_code, 200, r.data)

        self.appeal.refresh_from_db()
        self.assertEqual(self.appeal.status, 'approved')
        self.assertEqual(self.appeal.reviewed_by, self.admin)
        self.assertEqual(self.appeal.decision_note, 'Evidence checks out')
        self.assertIsNotNone(self.appeal.resolved_at)

        self.action.refresh_from_db()                             # same logic as a manual reversal
        self.assertFalse(self.action.is_active)
        self.assertEqual(self.action.reversed_by, self.admin)
        self.assertIsNotNone(self.action.reversed_at)
        self.assertIn(f'Appeal #{self.appeal.pk}', self.action.reversal_reason)
        self.assertIn('Evidence checks out', self.action.reversal_reason)
        self.assertTrue(can_send_messages(self.target))           # enforcement lifted

        self.assertEqual(r.data['status'], 'approved')
        self.assertEqual(r.data['reviewed_by_email'], 'admin@test.com')

    def test_approval_keeps_full_history(self):
        self.decide(self.appeal.pk, 'approve')
        self.assertTrue(ModerationAction.objects.filter(pk=self.action.pk).exists())
        self.assertTrue(Appeal.objects.filter(pk=self.appeal.pk).exists())
        h = self.client.get(f'{BASE}/users/{self.target.pk}/moderation-actions/')
        self.assertEqual([x['status'] for x in h.data], ['reversed'])

    def test_note_is_optional_on_approval(self):
        r = self.decide(self.appeal.pk, 'approve')
        self.assertEqual(r.status_code, 200)
        self.action.refresh_from_db()
        self.assertEqual(self.action.reversal_reason, f'Appeal #{self.appeal.pk} approved')

    def test_approval_is_audit_logged(self):
        self.decide(self.appeal.pk, 'approve', decision_note='ok')
        log = AdminLog.objects.get(action='appeal_approved')
        self.assertEqual(log.admin, self.admin)
        self.assertEqual(log.target_user, self.target)
        self.assertIn(f'#{self.appeal.pk}', log.note)
        self.assertTrue(AdminLog.objects.filter(action='moderation_reversed').exists())

    def test_user_gets_one_approval_notification_and_no_duplicate_lifted_notice(self):
        self.submit_notes_before = len(self.notes(self.target))
        self.decide(self.appeal.pk, 'approve', decision_note='INTERNAL-APPROVAL-NOTE')
        notes = self.notes(self.target)
        self.assertEqual([n.title for n in notes], ['Appeal Approved'])
        self.assertIn('approved', notes[0].message)
        self.assertIn('messaging restriction', notes[0].message)
        self.assertIn('lifted', notes[0].message)
        self.assertNotIn('INTERNAL-APPROVAL-NOTE', notes[0].message)
        data = self.fcm.call_args.kwargs['data']
        self.assertEqual(data['event'], 'appeal_approved')
        self.assertEqual(data['status'], 'approved')

    def test_full_flow_submit_then_approve_notifications(self):
        a = self.make_action(action_type='suspend_permanent')
        r = self.submit(a)
        self.decide(r.data['id'], 'approve')
        self.assertEqual([n.title for n in self.notes(self.target)],
                         ['Appeal Submitted', 'Appeal Approved'])
        a.refresh_from_db()
        self.assertFalse(a.is_active)
        self.assertFalse(is_suspended(self.target))

    def test_approving_a_warning_removes_it(self):
        w = self.make_action(action_type='warning')
        r = self.submit(w)
        self.decide(r.data['id'], 'approve')
        w.refresh_from_db()
        self.assertFalse(w.is_active)
        self.assertFalse(get_moderation_status(self.target).has_active_warning)
        self.assertIn('warning', self.notes(self.target)[-1].message)

    def test_cannot_decide_twice(self):
        self.assertEqual(self.decide(self.appeal.pk, 'approve').status_code, 200)
        self.assertEqual(self.decide(self.appeal.pk, 'approve').status_code, 409)
        self.assertEqual(self.decide(self.appeal.pk, 'reject', decision_note='x').status_code, 409)
        self.appeal.refresh_from_db()
        self.assertEqual(self.appeal.status, 'approved')
        self.assertEqual(AdminLog.objects.filter(action='moderation_reversed').count(), 1)
        self.assertEqual([n.title for n in self.notes(self.target)], ['Appeal Approved'])

    def test_approval_when_action_was_already_reversed_still_approves_without_double_reversal(self):
        self.action.is_active = False
        self.action.reversed_at = timezone.now()
        self.action.reversed_by = self.admin2
        self.action.reversal_reason = 'lifted manually'
        self.action.save()
        r = self.decide(self.appeal.pk, 'approve')
        self.assertEqual(r.status_code, 200, r.data)
        self.appeal.refresh_from_db()
        self.assertEqual(self.appeal.status, 'approved')
        self.action.refresh_from_db()
        self.assertEqual(self.action.reversed_by, self.admin2)        # untouched
        self.assertEqual(self.action.reversal_reason, 'lifted manually')
        self.assertFalse(AdminLog.objects.filter(action='moderation_reversed').exists())

    def test_approval_when_action_already_expired_still_approves(self):
        a = self.make_action(action_type='restrict_booking',
                             expires_at=timezone.now() + timedelta(hours=1))
        ap = self.make_appeal(action=a)
        ModerationAction.objects.filter(pk=a.pk).update(
            expires_at=timezone.now() - timedelta(minutes=1))
        self.assertEqual(self.decide(ap.pk, 'approve').status_code, 200)
        ap.refresh_from_db()
        self.assertEqual(ap.status, 'approved')
        a.refresh_from_db()
        self.assertIsNone(a.reversed_at)                              # nothing to reverse

    def test_approving_legacy_ban_appeal_restores_the_account(self):
        # Uses the existing reversal logic, including its legacy-ban account restore.
        self.target.is_active = False
        self.target.save()
        ban = self.make_action(action_type='suspend_permanent', legacy_ban_applied=True)
        ap = self.make_appeal(action=ban)
        self.assertEqual(self.decide(ap.pk, 'approve').status_code, 200)
        self.target.refresh_from_db()
        self.assertTrue(self.target.is_active)

    def test_failed_reversal_rolls_the_whole_approval_back(self):
        from apps.admin_panel.moderation import ModerationError
        with mock.patch('apps.admin_panel.appeals.reverse_moderation_action',
                        side_effect=ModerationError('boom')):
            r = self.decide(self.appeal.pk, 'approve')
        self.assertEqual(r.status_code, 400)
        self.appeal.refresh_from_db()
        self.action.refresh_from_db()
        self.assertEqual(self.appeal.status, 'pending')               # not half-approved
        self.assertIsNone(self.appeal.resolved_at)
        self.assertTrue(self.action.is_active)
        self.assertFalse(AdminLog.objects.filter(action='appeal_approved').exists())
        self.assertEqual(Notification.objects.count(), 0)

    def test_notification_failure_does_not_undo_an_approval(self):
        with mock.patch('apps.admin_panel.moderation_notifications.notify_user',
                        side_effect=RuntimeError('fcm down')):
            r = self.decide(self.appeal.pk, 'approve')
        self.assertEqual(r.status_code, 200)
        self.action.refresh_from_db()
        self.assertFalse(self.action.is_active)


class AppealRejectionTests(AppealTestBase):

    def setUp(self):
        super().setUp()
        self.appeal = self.make_appeal()

    def test_rejection_preserves_the_moderation_action(self):
        r = self.decide(self.appeal.pk, 'reject', decision_note='Violation is clear')
        self.assertEqual(r.status_code, 200, r.data)

        self.appeal.refresh_from_db()
        self.assertEqual(self.appeal.status, 'rejected')
        self.assertEqual(self.appeal.reviewed_by, self.admin)
        self.assertEqual(self.appeal.decision_note, 'Violation is clear')
        self.assertIsNotNone(self.appeal.resolved_at)

        self.action.refresh_from_db()                               # completely untouched
        self.assertTrue(self.action.is_active)
        self.assertIsNone(self.action.reversed_at)
        self.assertIsNone(self.action.reversed_by)
        self.assertEqual(self.action.reversal_reason, '')
        self.assertFalse(can_send_messages(self.target))            # still enforced
        self.assertFalse(AdminLog.objects.filter(action='moderation_reversed').exists())

    def test_rejection_requires_an_internal_note(self):
        for body in ({}, {'decision_note': ''}, {'decision_note': '   '}):
            r = self.decide(self.appeal.pk, 'reject', **body)
            self.assertEqual(r.status_code, 400, body)
        self.appeal.refresh_from_db()
        self.assertEqual(self.appeal.status, 'pending')

    def test_rejection_is_audit_logged(self):
        self.decide(self.appeal.pk, 'reject', decision_note='no')
        log = AdminLog.objects.get(action='appeal_rejected')
        self.assertEqual(log.admin, self.admin)
        self.assertEqual(log.target_user, self.target)
        self.assertIn(f'#{self.appeal.pk}', log.note)

    def test_user_is_told_the_decision_without_the_note(self):
        self.decide(self.appeal.pk, 'reject', decision_note='INTERNAL-REJECTION-NOTE')
        notes = self.notes(self.target)
        self.assertEqual([n.title for n in notes], ['Appeal Decision'])
        self.assertIn('keep', notes[0].message)
        self.assertNotIn('INTERNAL-REJECTION-NOTE', notes[0].message)
        self.assertNotIn('lifted', notes[0].message)
        self.assertEqual(self.fcm.call_args.kwargs['data']['event'], 'appeal_rejected')

    def test_cannot_decide_twice_and_action_stays_put(self):
        self.assertEqual(self.decide(self.appeal.pk, 'reject', decision_note='a').status_code, 200)
        self.assertEqual(self.decide(self.appeal.pk, 'reject', decision_note='b').status_code, 409)
        self.assertEqual(self.decide(self.appeal.pk, 'approve').status_code, 409)
        self.action.refresh_from_db()
        self.assertTrue(self.action.is_active)
        self.appeal.refresh_from_db()
        self.assertEqual(self.appeal.decision_note, 'a')            # first decision stands
        self.assertEqual(len(self.notes(self.target)), 1)

    def test_rejected_appeal_history_is_kept_and_visible(self):
        self.decide(self.appeal.pk, 'reject', decision_note='no')
        self.assertTrue(Appeal.objects.filter(pk=self.appeal.pk).exists())
        self.assertEqual(len(self.client.get(f'{BASE}/appeals/?status=rejected').data), 1)
        mine = self.user_client.get(f'{BASE}/appeals/mine/')
        self.assertEqual([x['status'] for x in mine.data], ['rejected'])


class AppealPrivacyTests(AppealTestBase):
    """Own appeals only; no internal notes, admin identity or report details for users."""

    SECRET_FIELDS = ('decision_note', 'reviewed_by', 'reviewed_by_name', 'reviewed_by_email',
                     'report', 'user', 'user_email', 'moderation_action_detail', 'admin_note')

    def setUp(self):
        super().setUp()
        self.mine = self.make_appeal(reason='my explanation')
        self.theirs_action = self.make_action(user=self.victim2, reason='victim2 public reason')
        self.theirs = self.make_appeal(action=self.theirs_action, reason='victim2 private words')

    def test_mine_lists_only_my_appeals(self):
        r = self.user_client.get(f'{BASE}/appeals/mine/')
        self.assertEqual(r.status_code, 200)
        self.assertEqual([x['id'] for x in r.data], [self.mine.pk])
        blob = str(r.data)
        self.assertNotIn('victim2', blob)
        self.assertNotIn('victim2 private words', blob)

    def test_another_user_sees_only_their_own(self):
        r = self.other_client.get(f'{BASE}/appeals/mine/')
        self.assertEqual([x['id'] for x in r.data], [self.theirs.pk])
        self.assertNotIn('my explanation', str(r.data))

    def test_user_with_no_appeals_gets_empty_list(self):
        c = APIClient()
        c.force_authenticate(self.other)
        self.assertEqual(c.get(f'{BASE}/appeals/mine/').data, [])

    def test_mine_requires_authentication(self):
        self.assertIn(APIClient().get(f'{BASE}/appeals/mine/').status_code, (401, 403))

    def test_user_facing_payloads_hide_internal_fields(self):
        self.decide(self.mine.pk, 'reject', decision_note='INTERNAL-DECISION-NOTE')
        listing = self.user_client.get(f'{BASE}/appeals/mine/').data[0]
        created = self.submit(self.make_action(action_type='restrict_booking')).data
        for payload in (listing, created):
            for key in self.SECRET_FIELDS:
                self.assertNotIn(key, payload, key)
            blob = str(payload)
            for secret in ('INTERNAL-DECISION-NOTE', 'INTERNAL ACTION NOTE', 'INTERNAL REPORT NOTE',
                           'admin@test.com', 'Admin', 'reporter@test.com', 'Reporter'):
                self.assertNotIn(secret, blob, secret)
        self.assertEqual(listing['status'], 'rejected')              # outcome IS visible

    def test_user_still_sees_own_outcome_and_public_action_reason(self):
        self.decide(self.mine.pk, 'reject', decision_note='x')
        row = self.user_client.get(f'{BASE}/appeals/mine/').data[0]
        self.assertEqual(row['status'], 'rejected')
        self.assertIsNotNone(row['resolved_at'])
        self.assertEqual(row['action_reason'], 'Spamming other users')
        self.assertEqual(row['action_type'], 'restrict_messaging')

    def test_mine_status_filter(self):
        self.assertEqual(len(self.user_client.get(f'{BASE}/appeals/mine/?status=pending').data), 1)
        self.assertEqual(self.user_client.get(f'{BASE}/appeals/mine/?status=approved').data, [])
        self.assertEqual(self.user_client.get(f'{BASE}/appeals/mine/?status=nope').status_code, 400)

    def test_user_cannot_reach_admin_appeal_endpoints_for_any_appeal(self):
        for pk in (self.mine.pk, self.theirs.pk):
            self.assertEqual(self.user_client.get(f'{BASE}/appeals/{pk}/').status_code, 403)
        self.assertEqual(self.user_client.get(f'{BASE}/appeals/').status_code, 403)

    def test_user_cannot_read_moderation_history_via_admin_endpoints(self):
        self.assertEqual(
            self.user_client.get(f'{BASE}/users/{self.victim2.pk}/moderation-actions/').status_code, 403)
        self.assertEqual(
            self.user_client.get(f'{BASE}/users/{self.target.pk}/moderation-actions/').status_code, 403)

    def test_notifications_never_contain_internal_or_identifying_data(self):
        self.submit(self.make_action(action_type='restrict_booking'))
        self.decide(self.mine.pk, 'approve', decision_note='INTERNAL-DECISION-NOTE')
        blob = '\n'.join(n.title + ' ' + n.message for n in self.notes(self.target)).lower()
        pushes = str([c for c in self.fcm.call_args_list if c.args[0] == 'fcm-target-token']).lower()
        for secret in ('internal-decision-note', 'internal action note', 'internal report note',
                       'admin@test.com', 'reporter@test.com', 'victim2'):
            self.assertNotIn(secret, blob, secret)
            self.assertNotIn(secret, pushes, secret)
        for c in self.fcm.call_args_list:
            self.assertNotIn('report_id', c.kwargs['data'])

    def test_one_users_decision_never_notifies_another_user(self):
        self.decide(self.mine.pk, 'approve')
        self.assertEqual(self.notes(self.victim2), [])

    def test_appeal_history_cannot_be_deleted_out_from_under_it(self):
        with self.assertRaises(ProtectedError):
            self.action.delete()
        self.assertTrue(ModerationAction.objects.filter(pk=self.action.pk).exists())

    def test_decisions_never_delete_appeals(self):
        before = Appeal.objects.count()
        self.decide(self.mine.pk, 'approve')
        self.decide(self.theirs.pk, 'reject', decision_note='no')
        self.assertEqual(Appeal.objects.count(), before)
        self.assertEqual({a.status for a in Appeal.objects.all()}, {'approved', 'rejected'})


class AppealNoticeInActionNotificationsTests(ModerationNotificationBase):
    """The Part 5 'appeal availability' hook stays off until the client can file one."""

    def test_no_appeal_line_by_default(self):
        self.act(action_type='restrict_messaging')
        self.assertNotIn('appeal', self.only_note(self.target).message.lower())

    def test_appeal_line_appears_when_enabled(self):
        with mock.patch.object(moderation_notifications, 'APPEALS_AVAILABLE', True):
            for t in ('warning', 'restrict_messaging', 'restrict_booking', 'suspend_permanent'):
                self.act(action_type=t)
        for n in self.notes(self.target):
            self.assertIn('submit an appeal', n.message, n.title)


# ── Trust & Safety Part 7: report payload exposes severity / evidence / context ─

class ReportPayloadExposureTests(ModerationAPITestBase):
    """The admin report payloads must carry the fields the admin UI needs."""

    def _make_context(self):
        from datetime import date, time as dtime
        from apps.bookings.models import Booking
        from apps.messaging.models import Conversation, Message
        booking = Booking.objects.create(
            customer=self.reporter, professional=self.other,
            date=date(2026, 10, 1), time=dtime(10, 30), note='PRIVATE NOTE')
        conv = Conversation.objects.create(customer=self.reporter, professional=self.other)
        msg = Message.objects.create(conversation=conv, sender=self.other, text='pay me off-platform')
        return booking, msg

    def test_defaults_present_for_plain_report(self):
        self.make_report()
        r = self.client.get(f'{BASE}/reports/')
        self.assertEqual(r.status_code, 200)
        row = r.data[0]
        self.assertEqual(row['severity'], 'medium')
        self.assertEqual(row['severity_display'], 'Medium')
        self.assertEqual(row['evidence_url'], '')
        self.assertIsNone(row['related_booking'])
        self.assertIsNone(row['related_booking_detail'])
        self.assertIsNone(row['related_message'])
        self.assertIsNone(row['related_message_detail'])

    def test_related_booking_and_message_summaries(self):
        booking, msg = self._make_context()
        self.make_report(related_booking=booking, related_message=msg,
                         severity='high', evidence_url='https://example.com/p.png')
        row = self.client.get(f'{BASE}/reports/').data[0]
        self.assertEqual(row['severity'], 'high')
        self.assertEqual(row['evidence_url'], 'https://example.com/p.png')
        self.assertEqual(row['related_booking'], booking.pk)
        self.assertEqual(row['related_booking_detail']['status'], 'pending')
        self.assertEqual(row['related_booking_detail']['date'], '2026-10-01')
        self.assertEqual(row['related_booking_detail']['time'], '10:30')
        self.assertEqual(row['related_booking_detail']['professional_name'], 'Other')
        self.assertNotIn('note', row['related_booking_detail'])
        self.assertNotIn('PRIVATE NOTE', str(row['related_booking_detail']))
        self.assertEqual(row['related_message_detail']['text'], 'pay me off-platform')
        self.assertEqual(row['related_message_detail']['sender_name'], 'Other')
        self.assertFalse(row['related_message_detail']['is_deleted'])

    def test_deleted_message_content_stays_hidden(self):
        _, msg = self._make_context()
        msg.deleted_at = timezone.now()
        msg.save()
        self.make_report(related_message=msg)
        detail = self.client.get(f'{BASE}/reports/').data[0]['related_message_detail']
        self.assertTrue(detail['is_deleted'])
        self.assertEqual(detail['text'], '')

    def test_patch_response_includes_new_fields(self):
        report = self.make_report(severity='critical')
        r = self.client.patch(f'{BASE}/reports/{report.pk}/', {'status': 'reviewed'}, format='json')
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data['severity'], 'critical')
        self.assertIn('related_booking_detail', r.data)

    def test_new_fields_are_read_only_on_patch(self):
        report = self.make_report()
        self.client.patch(f'{BASE}/reports/{report.pk}/',
                          {'status': 'reviewed', 'severity': 'critical',
                           'evidence_url': 'https://evil.example'}, format='json')
        report.refresh_from_db()
        self.assertEqual(report.severity, 'medium')
        self.assertEqual(report.evidence_url, '')

    def test_list_query_count_does_not_grow_with_reports(self):
        from django.db import connection
        from django.test.utils import CaptureQueriesContext
        booking, msg = self._make_context()
        self.make_report(related_booking=booking, related_message=msg)
        with CaptureQueriesContext(connection) as one:
            self.client.get(f'{BASE}/reports/')
        for _ in range(4):
            self.make_report(related_booking=booking, related_message=msg)
        with CaptureQueriesContext(connection) as five:
            self.client.get(f'{BASE}/reports/')
        self.assertLessEqual(len(five), len(one))

    def test_non_admin_still_forbidden(self):
        self.make_report()
        self.client.force_authenticate(self.other)
        self.assertEqual(self.client.get(f'{BASE}/reports/').status_code, 403)


# ═══════════════════════════════════════════════════════════════════════════
# Trust & Safety Part 8 (user-facing) — My Reports / My Moderation Status
# ═══════════════════════════════════════════════════════════════════════════

class MyReportsTests(AppealTestBase):
    """
    GET /admin-panel/reports/mine/ — reports the CURRENT user submitted.
    Reuses AppealTestBase for self.user_client (target) / self.other_client
    (victim2) and self.admin.
    """

    def setUp(self):
        super().setUp()
        # self.report (from AppealTestBase) was made by self.reporter, not
        # self.target — irrelevant to these tests. Build reports authored
        # BY the two user_client identities instead.
        self.mine = UserReport.objects.create(
            reporter=self.target, reported_user=self.victim2,
            reason='harassment', description='They kept messaging me after I said stop.',
            admin_note='INTERNAL NOTE ABOUT VICTIM2', severity='high')
        self.theirs = UserReport.objects.create(
            reporter=self.victim2, reported_user=self.target,
            reason='spam', description='spam desc')

    def test_lists_only_my_own_reports(self):
        r = self.user_client.get(f'{BASE}/reports/mine/')
        self.assertEqual(r.status_code, 200)
        self.assertEqual([row['id'] for row in r.data], [self.mine.pk])

    def test_another_user_sees_only_their_own(self):
        r = self.other_client.get(f'{BASE}/reports/mine/')
        self.assertEqual([row['id'] for row in r.data], [self.theirs.pk])

    def test_user_with_no_reports_gets_empty_list(self):
        c = APIClient()
        c.force_authenticate(self.other)
        self.assertEqual(c.get(f'{BASE}/reports/mine/').data, [])

    def test_requires_authentication(self):
        self.assertIn(APIClient().get(f'{BASE}/reports/mine/').status_code, (401, 403))

    def test_never_exposes_reported_user_identity_admin_note_or_reviewer(self):
        self.mine.status = 'action_taken'
        self.mine.reviewed_by = self.admin
        self.mine.save()
        row = self.user_client.get(f'{BASE}/reports/mine/').data[0]
        for key in ('reported_user', 'reported_user_email', 'reported_user_name',
                    'admin_note', 'reviewed_by', 'reviewed_by_email', 'reviewed_by_name',
                    'severity', 'related_booking', 'related_message'):
            self.assertNotIn(key, row, key)
        blob = str(row)
        for secret in ('victim2', 'INTERNAL NOTE ABOUT VICTIM2', 'admin@test.com'):
            self.assertNotIn(secret, blob, secret)
        # the general outcome is fine to show — just never the specifics
        self.assertEqual(row['outcome'], 'action_taken')

    def test_outcome_code_per_status(self):
        cases = [
            ('pending', 'pending'),
            ('reviewed', 'reviewed_no_action'),
            ('action_taken', 'action_taken'),
            ('dismissed', 'dismissed'),
        ]
        for status, expected_outcome in cases:
            self.mine.status = status
            self.mine.save()
            row = self.user_client.get(f'{BASE}/reports/mine/').data[0]
            self.assertEqual(row['outcome'], expected_outcome, status)
            self.assertEqual(row['status'], status)

    def test_status_filter_and_invalid_value(self):
        self.assertEqual(len(self.user_client.get(f'{BASE}/reports/mine/?status=pending').data), 1)
        self.assertEqual(self.user_client.get(f'{BASE}/reports/mine/?status=action_taken').data, [])
        self.assertEqual(self.user_client.get(f'{BASE}/reports/mine/?status=nope').status_code, 400)

    def test_category_and_description_are_visible(self):
        row = self.user_client.get(f'{BASE}/reports/mine/').data[0]
        self.assertEqual(row['category'], 'harassment')
        self.assertEqual(row['description'], 'They kept messaging me after I said stop.')
        self.assertIn('created_at', row)


class ReportCreateEvidenceUrlTests(ModerationAPITestBase):
    """
    POST /admin-panel/reports/create/ — Part 8 added an optional
    `evidence_url`; severity must remain admin-only.
    """

    def setUp(self):
        super().setUp()
        self.client.force_authenticate(self.reporter)

    def _post(self, **overrides):
        payload = {'reported_user': self.target.pk, 'reason': 'spam', 'description': 'x'}
        payload.update(overrides)
        return self.client.post(f'{BASE}/reports/create/', payload, format='json')

    def test_evidence_url_is_optional_and_saved_when_valid(self):
        r = self._post(evidence_url='https://example.com/proof.png')
        self.assertEqual(r.status_code, 201, r.data)
        report = UserReport.objects.get(pk=r.data['id'])
        self.assertEqual(report.evidence_url, 'https://example.com/proof.png')

    def test_evidence_url_omitted_still_works(self):
        r = self._post()
        self.assertEqual(r.status_code, 201, r.data)
        self.assertEqual(UserReport.objects.get(pk=r.data['id']).evidence_url, '')

    def test_non_http_evidence_url_is_rejected(self):
        r = self._post(evidence_url='javascript:alert(1)')
        self.assertEqual(r.status_code, 400)
        self.assertEqual(UserReport.objects.count(), 0)

    def test_client_supplied_severity_is_ignored(self):
        r = self._post(severity='critical')
        self.assertEqual(r.status_code, 201, r.data)
        report = UserReport.objects.get(pk=r.data['id'])
        self.assertEqual(report.severity, 'medium')  # model default, untouched

    def test_cannot_report_self(self):
        r = self.client.post(f'{BASE}/reports/create/',
                             {'reported_user': self.reporter.pk, 'reason': 'spam'}, format='json')
        self.assertEqual(r.status_code, 400)


class MyModerationStatusTests(AppealTestBase):
    """
    GET /admin-panel/moderation-status/mine/ — the CURRENT user's own live
    status. `self.action` (from AppealTestBase) is an active
    restrict_messaging action against self.target with
    admin_note='INTERNAL ACTION NOTE', linked to self.report
    (admin_note='INTERNAL REPORT NOTE').
    """

    def test_reflects_active_restriction(self):
        r = self.user_client.get(f'{BASE}/moderation-status/mine/')
        self.assertEqual(r.status_code, 200)
        self.assertTrue(r.data['messaging_restricted'])
        self.assertFalse(r.data['booking_restricted'])
        self.assertFalse(r.data['is_suspended'])
        self.assertEqual(len(r.data['actions']), 1)
        row = r.data['actions'][0]
        self.assertEqual(row['id'], self.action.pk)
        self.assertEqual(row['action_type'], 'restrict_messaging')
        self.assertEqual(row['reason'], 'Spamming other users')
        self.assertEqual(row['status'], 'active')
        self.assertTrue(row['can_appeal'])
        self.assertFalse(row['has_pending_appeal'])

    def test_good_standing_for_user_with_no_actions(self):
        c = APIClient()
        c.force_authenticate(self.other)
        r = c.get(f'{BASE}/moderation-status/mine/')
        self.assertEqual(r.data['actions'], [])
        self.assertFalse(r.data['is_suspended'])
        self.assertFalse(r.data['messaging_restricted'])
        self.assertFalse(r.data['booking_restricted'])
        self.assertFalse(r.data['has_active_warning'])

    def test_never_shows_another_users_actions(self):
        self.make_action(user=self.victim2, action_type='restrict_booking', reason='victim2 reason')
        r = self.user_client.get(f'{BASE}/moderation-status/mine/')
        self.assertEqual([a['id'] for a in r.data['actions']], [self.action.pk])
        self.assertNotIn('victim2 reason', str(r.data))

    def test_pending_appeal_flips_can_appeal_flags(self):
        self.submit()  # creates a pending appeal against self.action, as self.target
        r = self.user_client.get(f'{BASE}/moderation-status/mine/')
        row = r.data['actions'][0]
        self.assertTrue(row['has_pending_appeal'])
        self.assertFalse(row['can_appeal'])

    def test_can_appeal_again_after_rejection(self):
        appeal_id = self.submit().data['id']
        self.decide(appeal_id, 'reject', decision_note='no')
        row = self.user_client.get(f'{BASE}/moderation-status/mine/').data['actions'][0]
        self.assertFalse(row['has_pending_appeal'])
        self.assertTrue(row['can_appeal'])          # still active, free to appeal again

    def test_approved_appeal_reverses_action_so_it_drops_out_of_status(self):
        appeal_id = self.submit().data['id']
        self.decide(appeal_id, 'approve')
        r = self.user_client.get(f'{BASE}/moderation-status/mine/')
        self.assertEqual(r.data['actions'], [])
        self.assertFalse(r.data['messaging_restricted'])

    def test_reversed_action_excluded(self):
        with self.captureOnCommitCallbacks(execute=True):
            self.client.post(f'{BASE}/moderation-actions/{self.action.pk}/reverse/',
                             {'reason': 'mistake'}, format='json')
        r = self.user_client.get(f'{BASE}/moderation-status/mine/')
        self.assertEqual(r.data['actions'], [])

    def test_never_exposes_admin_identity_report_link_or_notes(self):
        row = self.user_client.get(f'{BASE}/moderation-status/mine/').data['actions'][0]
        for key in ('performed_by', 'performed_by_email', 'performed_by_name',
                    'admin_note', 'report', 'reversed_by', 'reversal_reason'):
            self.assertNotIn(key, row, key)
        blob = str(self.user_client.get(f'{BASE}/moderation-status/mine/').data)
        for secret in ('INTERNAL ACTION NOTE', 'INTERNAL REPORT NOTE', 'admin@test.com', 'reporter@test.com'):
            self.assertNotIn(secret, blob, secret)

    def test_requires_authentication(self):
        self.assertIn(APIClient().get(f'{BASE}/moderation-status/mine/').status_code, (401, 403))

    def test_warning_is_listed_and_appealable(self):
        self.make_action(user=self.other, action_type='warning', reason='be nice')
        c = APIClient()
        c.force_authenticate(self.other)
        row = c.get(f'{BASE}/moderation-status/mine/').data['actions'][0]
        self.assertEqual(row['action_type'], 'warning')
        self.assertTrue(row['can_appeal'])
        self.assertTrue(c.get(f'{BASE}/moderation-status/mine/').data['has_active_warning'])

    def test_reflects_permanent_suspension_flags(self):
        self.make_action(user=self.other, action_type='suspend_permanent', reason='severe abuse')
        c = APIClient()
        c.force_authenticate(self.other)
        r = c.get(f'{BASE}/moderation-status/mine/')
        self.assertTrue(r.data['is_suspended'])
        self.assertTrue(r.data['is_permanently_suspended'])
        self.assertFalse(r.data['is_temporarily_suspended'])

    def test_temporary_suspension_includes_start_and_expiry(self):
        starts = timezone.now() - timedelta(hours=1)
        expires = timezone.now() + timedelta(days=2)
        self.make_action(user=self.other, action_type='suspend_temporary', reason='cooldown',
                         starts_at=starts, expires_at=expires)
        c = APIClient()
        c.force_authenticate(self.other)
        row = c.get(f'{BASE}/moderation-status/mine/').data['actions'][0]
        self.assertIsNotNone(row['starts_at'])
        self.assertIsNotNone(row['expires_at'])

    def test_expired_temporary_suspension_is_not_listed(self):
        self.make_action(
            user=self.other, action_type='suspend_temporary', reason='old',
            starts_at=timezone.now() - timedelta(days=5),
            expires_at=timezone.now() - timedelta(days=1))
        c = APIClient()
        c.force_authenticate(self.other)
        r = c.get(f'{BASE}/moderation-status/mine/')
        self.assertEqual(r.data['actions'], [])
        self.assertFalse(r.data['is_suspended'])