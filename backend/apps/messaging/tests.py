# apps/messaging/tests.py
#
# Trust & Safety Part 9 (security pass) — this app previously had NO test
# file at all. Adding targeted regression tests only for the enforcement
# gap found and fixed in this pass (MessageListView.post never checked a
# messaging restriction / suspension — see the fix + comment there), not a
# full test suite for the messaging app in general.

from django.test import TestCase
from rest_framework.test import APIClient

from apps.admin_panel.models import ModerationAction
from apps.messaging.models import Conversation, Message, BlockedUser
from apps.users.models import User


class MessageSendEnforcementTests(TestCase):
    def setUp(self):
        self.customer = User.objects.create_user(
            email='cust@test.com', name='Cust', role='customer', password='pass1234')
        self.professional = User.objects.create_user(
            email='pro@test.com', name='Pro', role='professional', password='pass1234')
        self.admin = User.objects.create_user(
            email='admin@test.com', name='Admin', role='admin', password='pass1234')
        self.conversation = Conversation.objects.create(
            customer=self.customer, professional=self.professional)

        self.client_api = APIClient()
        self.client_api.force_authenticate(self.customer)

    def _post(self, text='hello'):
        return self.client_api.post(
            f'/api/messaging/conversations/{self.conversation.pk}/messages/',
            {'text': text}, format='json')

    def test_unrestricted_user_can_send(self):
        r = self._post()
        self.assertEqual(r.status_code, 201, r.data)
        self.assertEqual(Message.objects.count(), 1)

    def test_messaging_restricted_user_is_blocked_server_side(self):
        ModerationAction.objects.create(
            target_user=self.customer, performed_by=self.admin,
            action_type='restrict_messaging', reason='spam')
        r = self._post()
        self.assertEqual(r.status_code, 403, r.data)
        self.assertEqual(r.data.get('code'), 'messaging_restricted')
        self.assertEqual(Message.objects.count(), 0)

    def test_suspended_user_is_blocked_server_side(self):
        ModerationAction.objects.create(
            target_user=self.customer, performed_by=self.admin,
            action_type='suspend_permanent', reason='abuse')
        r = self._post()
        self.assertEqual(r.status_code, 403, r.data)
        self.assertEqual(Message.objects.count(), 0)

    def test_booking_restriction_does_not_block_messaging(self):
        ModerationAction.objects.create(
            target_user=self.customer, performed_by=self.admin,
            action_type='restrict_booking', reason='unrelated')
        r = self._post()
        self.assertEqual(r.status_code, 201, r.data)

    def test_restriction_on_other_party_does_not_block_my_sending(self):
        ModerationAction.objects.create(
            target_user=self.professional, performed_by=self.admin,
            action_type='restrict_messaging', reason='unrelated')
        r = self._post()
        self.assertEqual(r.status_code, 201, r.data)

    def test_block_check_and_moderation_check_are_independent(self):
        """
        Blocking and moderation restriction are two separate reasons a send
        can be rejected — one existing (block), one newly added (this pass).
        Confirms adding the moderation check didn't disturb the existing
        block check's own error code.
        """
        BlockedUser.objects.create(blocker=self.professional, blocked=self.customer)
        r = self._post()
        self.assertEqual(r.status_code, 403)
        self.assertEqual(r.data.get('code'), 'blocked')  # block wins/first, not conflated with restriction


class LegacyReportUrlRemovedTests(TestCase):
    """
    Trust & Safety Part 10 (final audit) — apps.messaging's own report
    endpoint silently wrote into a table no admin screen reads, so a report
    submitted there vanished with a success response. The route is removed;
    this pins that down so it can't quietly come back.
    """

    def test_legacy_messaging_reports_endpoint_is_gone(self):
        user = User.objects.create_user(
            email='someone@test.com', name='Someone', role='customer', password='pass1234')
        client = APIClient()
        client.force_authenticate(user)
        r = client.post('/api/messaging/reports/', {'reported': 1, 'reason': 'spam'}, format='json')
        self.assertEqual(r.status_code, 404)