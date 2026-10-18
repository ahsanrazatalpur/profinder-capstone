from django.test import SimpleTestCase, TestCase, override_settings
from rest_framework.test import APIClient

from apps.notifications.models import Notification
from apps.notifications.serializers import resolve_target_type
from apps.users.models import User

CLEAR = '/api/notifications/clear/'


class ResolveTargetTypeTests(SimpleTestCase):
    def test_typed_notifications_keep_their_type(self):
        for t in ('payment', 'review', 'subscription', 'report'):
            self.assertEqual(resolve_target_type(t, 'Anything', 'Anything'), t)

    def test_booking_from_title(self):
        self.assertEqual(
            resolve_target_type('general', 'Booking Accepted! \u2705', 'x'), 'booking')
        self.assertEqual(
            resolve_target_type('general', 'New Booking Request \U0001F4C5', 'x'), 'booking')

    def test_booking_from_message_when_title_has_no_keyword(self):
        self.assertEqual(
            resolve_target_type(
                'general', 'Something', 'Booking #12 | 03 May 2026 at 10:00 AM'),
            'booking')

    def test_support_notifications(self):
        self.assertEqual(resolve_target_type('general', 'Support reply', 'PF-000001: new reply'), 'support')
        self.assertEqual(resolve_target_type('general', 'Support ticket resolved', 'x'), 'support')

    def test_admin_notifications(self):
        self.assertEqual(
            resolve_target_type('general', 'New Professional Signup', 'x (x@y.com) registered as a professional.'),
            'professional_signup')
        self.assertEqual(resolve_target_type('report', 'New Report Submitted', 'x'), 'report')
        self.assertEqual(resolve_target_type('report', 'New Appeal Submitted', 'x'), 'appeal')
        self.assertEqual(resolve_target_type('general', 'Booking Cancelled \u274c', 'x'), 'booking')
        for title in ('New support ticket', 'Support ticket reply', 'New guest support request'):
            self.assertEqual(resolve_target_type('general', title, 'PF-000001: x'), 'support')

    def test_plain_general(self):
        self.assertEqual(resolve_target_type('general', 'Welcome', 'Hello'), 'general')
        self.assertEqual(resolve_target_type('general', None, None), 'general')


@override_settings(PASSWORD_HASHERS=['django.contrib.auth.hashers.MD5PasswordHasher'])
class ClearNotificationsTests(TestCase):
    def setUp(self):
        self.alice = User.objects.create_user(
            email='alice@example.com', name='alice', role='customer', password='Passw0rd!x')
        self.bob = User.objects.create_user(
            email='bob@example.com', name='bob', role='customer', password='Passw0rd!x')
        for n in range(3):
            Notification.objects.create(user=self.alice, title=f'A{n}', message='m')
        Notification.objects.create(user=self.bob, title='B0', message='m')
        self.client = APIClient()

    def test_requires_login(self):
        res = self.client.delete(CLEAR)
        self.assertEqual(res.status_code, 401)
        self.assertEqual(Notification.objects.count(), 4)

    def test_clears_only_my_notifications(self):
        self.client.force_authenticate(self.alice)
        res = self.client.delete(CLEAR)
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data['deleted'], 3)
        self.assertFalse(Notification.objects.filter(user=self.alice).exists())
        self.assertEqual(Notification.objects.filter(user=self.bob).count(), 1)

    def test_clear_when_already_empty(self):
        self.client.force_authenticate(self.bob)
        self.client.delete(CLEAR)
        res = self.client.delete(CLEAR)
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data['deleted'], 0)

    def test_list_includes_target_type(self):
        Notification.objects.create(user=self.alice, title='Support reply', message='PF-1', type='general')
        self.client.force_authenticate(self.alice)
        res = self.client.get('/api/notifications/')
        self.assertEqual(res.status_code, 200)
        self.assertIn('support', [n['target_type'] for n in res.data])