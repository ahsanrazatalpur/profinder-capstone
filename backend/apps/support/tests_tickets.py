# apps/support/tests_tickets.py
#
# Run with:  python manage.py test apps.support.tests_tickets

import datetime
from unittest import mock

from django.core.cache import cache
from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from apps.bookings.models import Booking
from apps.support.models import SupportTicket, TicketEvent, TicketMessage
from apps.users.models import User

NOTIFY = 'apps.support.ticket_views.notify_admins'
TICKETS = '/api/support/tickets/'
CONTACT = '/api/support/contact/'


def make_user(email, role='customer'):
    return User.objects.create_user(email=email, name=email.split('@')[0], role=role,
                                    password='Passw0rd!x')


def make_booking(customer, professional):
    return Booking.objects.create(customer=customer, professional=professional,
                                  date=datetime.date(2030, 1, 1), time=datetime.time(10, 0))


@override_settings(PASSWORD_HASHERS=['django.contrib.auth.hashers.MD5PasswordHasher'])
class Base(TestCase):
    def setUp(self):
        cache.clear()   # throttle counters live in the cache
        self.alice = make_user('alice@example.com', 'customer')
        self.bob = make_user('bob@example.com', 'customer')
        self.pro = make_user('pro@example.com', 'professional')
        self.admin = make_user('admin@example.com', 'admin')
        self.client = APIClient()
        self.client.force_authenticate(self.alice)

    def other(self, user):
        c = APIClient()
        c.force_authenticate(user)
        return c

    def payload(self, **kw):
        data = {'subject': 'Cannot withdraw', 'body': 'My withdrawal failed.', 'category': 'payment'}
        data.update(kw)
        return data

    def create(self, client=None, **kw):
        with mock.patch(NOTIFY):
            return (client or self.client).post(TICKETS, self.payload(**kw), format='json')

    def make_ticket(self, user=None, status='open', **kw):
        t = SupportTicket.objects.create(user=user or self.alice, role='customer',
                                         subject='S', status=status, **kw)
        TicketMessage.objects.create(ticket=t, author=user or self.alice, body='first')
        return t


class AuthTests(Base):
    def test_all_user_endpoints_require_login(self):
        anon = APIClient()
        t = self.make_ticket()
        for method, url in [('get', TICKETS), ('post', TICKETS),
                            ('get', f'{TICKETS}{t.pk}/'),
                            ('post', f'{TICKETS}{t.pk}/messages/'),
                            ('post', f'{TICKETS}{t.pk}/close/')]:
            with self.subTest(url=url, method=method):
                self.assertEqual(getattr(anon, method)(url, {}, format='json').status_code, 401)


class CreateTests(Base):
    def test_create_ok(self):
        r = self.create()
        self.assertEqual(r.status_code, 201, r.content)
        t = SupportTicket.objects.get()
        self.assertEqual(t.user, self.alice)
        self.assertEqual(t.role, 'customer')
        self.assertRegex(t.reference, r'^PF-\d{6}$')
        self.assertEqual(r.data['reference'], t.reference)
        self.assertEqual(t.messages.count(), 1)
        self.assertEqual(t.events.get().action, 'created')
        self.assertEqual(len(r.data['messages']), 1)

    def test_references_are_unique(self):
        a = self.create().data['reference']
        b = self.create().data['reference']
        self.assertNotEqual(a, b)

    def test_validation(self):
        bad = [
            {'subject': ''}, {'subject': '   '}, {'subject': 'x' * 151},
            {'body': ''}, {'body': '   \n '}, {'body': 'x' * 5001},
            {'category': 'nope'},
        ]
        for kw in bad:
            with self.subTest(kw=list(kw.items())[0][0], val=str(list(kw.values())[0])[:10]):
                cache.clear()   # throttle counts invalid requests too
                self.assertEqual(self.create(**kw).status_code, 400)
        self.assertEqual(SupportTicket.objects.count(), 0)

    def test_max_length_body_accepted(self):
        self.assertEqual(self.create(body='x' * 5000).status_code, 201)

    def test_user_cannot_set_privileged_fields(self):
        r = self.create(status='closed', priority='high', assigned_to=self.admin.pk,
                        user=self.bob.pk, role='admin', reference='PF-999999')
        self.assertEqual(r.status_code, 201)
        t = SupportTicket.objects.get()
        self.assertEqual((t.status, t.priority, t.user, t.role), ('open', 'normal', self.alice, 'customer'))
        self.assertIsNone(t.assigned_to)
        self.assertNotEqual(t.reference, 'PF-999999')

    def test_related_booking_rules(self):
        mine = make_booking(self.alice, self.pro)
        theirs = make_booking(self.bob, self.pro)
        self.assertEqual(self.create(related_booking=mine.pk).status_code, 201)
        # the professional on the booking may also reference it
        self.assertEqual(self.create(client=self.other(self.pro), related_booking=mine.pk).status_code, 201)
        r_other = self.create(related_booking=theirs.pk)
        r_missing = self.create(related_booking=999999)
        self.assertEqual(r_other.status_code, 400)
        self.assertEqual(r_missing.status_code, 400)
        # identical answer: the id cannot be probed
        self.assertEqual(r_other.data, r_missing.data)

    def test_admins_are_notified_after_commit_and_failure_is_swallowed(self):
        with mock.patch(NOTIFY) as notify:
            with self.captureOnCommitCallbacks(execute=True):
                self.client.post(TICKETS, self.payload(), format='json')
        notify.assert_called_once()
        self.assertIn('PF-', notify.call_args.args[1])
        self.assertNotIn('My withdrawal failed.', notify.call_args.args[1])  # body not pushed

        with mock.patch(NOTIFY, side_effect=RuntimeError('fcm down')), \
                self.assertLogs('apps.support.ticket_views', 'ERROR'):
            with self.captureOnCommitCallbacks(execute=True):
                r = self.client.post(TICKETS, self.payload(), format='json')
        self.assertEqual(r.status_code, 201)

    def test_creation_is_atomic(self):
        with mock.patch('apps.support.ticket_views.TicketMessage.objects.create',
                        side_effect=RuntimeError('boom')):
            with self.assertRaises(RuntimeError):
                self.client.post(TICKETS, self.payload(), format='json')
        self.assertEqual(SupportTicket.objects.count(), 0)

    def test_open_ticket_cap(self):
        for _ in range(10):
            SupportTicket.objects.create(user=self.alice, subject='x')
        r = self.create()
        self.assertEqual(r.status_code, 429)
        self.assertEqual(r.data['code'], 'too_many_open_tickets')
        # closed ones do not count
        SupportTicket.objects.filter(user=self.alice).update(status='closed')
        self.assertEqual(self.create().status_code, 201)

    def test_create_is_throttled(self):
        codes = [self.create(subject=f's{i}').status_code for i in range(6)]
        self.assertEqual(codes[:5], [201] * 5)
        self.assertEqual(codes[5], 429)


class OwnershipTests(Base):
    def setUp(self):
        super().setUp()
        self.bobs = self.make_ticket(self.bob)

    def test_list_shows_only_own(self):
        mine = self.make_ticket(self.alice)
        r = self.client.get(TICKETS)
        self.assertEqual([t['id'] for t in r.data['results']], [mine.pk])

    def test_other_users_ticket_is_404_everywhere(self):
        t = self.bobs
        for method, url, body in [('get', f'{TICKETS}{t.pk}/', None),
                                  ('post', f'{TICKETS}{t.pk}/messages/', {'body': 'hi'}),
                                  ('post', f'{TICKETS}{t.pk}/close/', {})]:
            with self.subTest(url=url):
                self.assertEqual(getattr(self.client, method)(url, body, format='json').status_code, 404)
        t.refresh_from_db()
        self.assertEqual((t.status, t.messages.count()), ('open', 1))

    def test_missing_and_foreign_ids_are_indistinguishable(self):
        a = self.client.get(f'{TICKETS}{self.bobs.pk}/')
        b = self.client.get(f'{TICKETS}999999/')
        self.assertEqual((a.status_code, a.data), (b.status_code, b.data))

    def test_admin_role_gets_no_special_access_on_user_endpoints(self):
        admin = self.other(self.admin)
        self.assertEqual(admin.get(f'{TICKETS}{self.bobs.pk}/').status_code, 404)
        self.assertEqual(admin.get(TICKETS).data['results'], [])

    def test_ticket_survives_account_deletion_without_access(self):
        t = self.make_ticket(self.alice)
        self.alice.delete()
        t.refresh_from_db()
        self.assertIsNone(t.user)


class VisibilityTests(Base):
    def test_internal_notes_and_staff_identity_never_leak(self):
        t = self.make_ticket(self.alice, assigned_to=self.admin)
        TicketMessage.objects.create(ticket=t, author=self.admin, is_staff=True,
                                     body='Public reply from support')
        TicketMessage.objects.create(ticket=t, author=self.admin, is_staff=True, is_internal=True,
                                     body='SECRET internal note')
        TicketEvent.objects.create(ticket=t, actor=self.admin, action='assigned', detail='to admin')

        responses = [self.client.get(f'{TICKETS}{t.pk}/'), self.client.get(TICKETS),
                     self.client.post(f'{TICKETS}{t.pk}/messages/', {'body': 'thanks'}, format='json')]
        for r in responses:
            raw = r.content.decode()
            self.assertNotIn('SECRET', raw)
            self.assertNotIn('admin@example.com', raw)
            self.assertNotIn('assigned', raw)
            self.assertNotIn('priority', raw)
        detail = responses[0].data
        self.assertEqual([m['body'] for m in detail['messages']], ['first', 'Public reply from support'])
        for m in detail['messages']:
            self.assertEqual(set(m), {'id', 'body', 'is_staff', 'created_at'})

    def test_last_message_is_staff_ignores_internal_notes(self):
        t = self.make_ticket(self.alice)
        TicketMessage.objects.create(ticket=t, author=self.admin, is_staff=True, body='reply')
        self.assertTrue(self.client.get(TICKETS).data['results'][0]['last_message_is_staff'])
        TicketMessage.objects.create(ticket=t, author=self.admin, is_staff=True, is_internal=True,
                                     body='note')
        TicketMessage.objects.create(ticket=t, author=self.alice, body='thanks')
        self.assertFalse(self.client.get(TICKETS).data['results'][0]['last_message_is_staff'])


class ReplyAndCloseTests(Base):
    def reply(self, t, body='more info', client=None):
        with mock.patch(NOTIFY):
            return (client or self.client).post(f'{TICKETS}{t.pk}/messages/', {'body': body},
                                                format='json')

    def test_reply_appends_and_bumps_activity(self):
        t = self.make_ticket()
        before = t.last_activity_at
        r = self.reply(t)
        self.assertEqual(r.status_code, 201)
        self.assertEqual(t.messages.count(), 2)
        t.refresh_from_db()
        self.assertGreater(t.last_activity_at, before)
        self.assertEqual(t.status, 'open')

    def test_status_transitions_on_user_reply(self):
        for start, end in [('awaiting_user', 'open'), ('resolved', 'open'),
                           ('in_progress', 'in_progress'), ('open', 'open')]:
            with self.subTest(start=start):
                t = self.make_ticket(status=start)
                self.assertEqual(self.reply(t).status_code, 201)
                t.refresh_from_db()
                self.assertEqual(t.status, end)

    def test_reply_validation(self):
        t = self.make_ticket()
        for body in ('', '   ', 'x' * 5001):
            with self.subTest(len=len(body)):
                self.assertEqual(self.reply(t, body).status_code, 400)
        self.assertEqual(t.messages.count(), 1)

    def test_closed_ticket_rejects_replies(self):
        t = self.make_ticket(status='closed')
        r = self.reply(t)
        self.assertEqual((r.status_code, r.data['code']), (409, 'ticket_closed'))
        self.assertEqual(t.messages.count(), 1)

    def test_message_cap(self):
        t = self.make_ticket()
        TicketMessage.objects.bulk_create(
            [TicketMessage(ticket=t, author=self.alice, body='x') for _ in range(199)])
        r = self.reply(t)
        self.assertEqual((r.status_code, r.data['code']), (409, 'message_limit'))

    def test_reply_is_throttled(self):
        t = self.make_ticket()
        codes = [self.reply(t, f'm{i}').status_code for i in range(31)]
        self.assertEqual(codes[:30], [201] * 30)
        self.assertEqual(codes[30], 429)

    def test_close(self):
        t = self.make_ticket(status='in_progress')
        r = self.client.post(f'{TICKETS}{t.pk}/close/')
        self.assertEqual(r.status_code, 200)
        t.refresh_from_db()
        self.assertEqual(t.status, 'closed')
        self.assertIsNotNone(t.closed_at)
        self.assertTrue(t.events.filter(action='closed_by_user').exists())
        # idempotent: no second audit row, still 200
        self.assertEqual(self.client.post(f'{TICKETS}{t.pk}/close/').status_code, 200)
        self.assertEqual(t.events.filter(action='closed_by_user').count(), 1)
        self.assertEqual(self.reply(t).status_code, 409)


class GuestContactTests(Base):
    def setUp(self):
        super().setUp()
        self.guest = APIClient()    # no credentials

    def send(self, client=None, **kw):
        data = {'email': 'Guest@Example.com', 'subject': 'Help me', 'body': 'I cannot log in.',
                'category': 'account'}
        data.update(kw)
        with mock.patch(NOTIFY):
            return (client or self.guest).post(CONTACT, data, format='json')

    def test_creates_guest_ticket(self):
        r = self.send()
        self.assertEqual(r.status_code, 201, r.content)
        t = SupportTicket.objects.get()
        self.assertIsNone(t.user)
        self.assertEqual((t.role, t.contact_email), ('guest', 'guest@example.com'))
        self.assertEqual(r.data, {'status': 'received', 'reference': t.reference})
        self.assertEqual(t.messages.get().body, 'I cannot log in.')

    def test_honeypot_stores_nothing(self):
        r = self.send(website='http://spam.example')
        self.assertEqual(r.status_code, 201)
        self.assertIsNone(r.data['reference'])
        self.assertEqual(SupportTicket.objects.count(), 0)

    def test_validation(self):
        for kw in ({'email': 'not-an-email'}, {'email': ''}, {'subject': ' '}, {'body': ''},
                   {'body': 'x' * 5001}, {'category': 'zzz'}):
            with self.subTest(kw=str(kw)[:40]):
                cache.clear()   # throttle counts invalid requests too
                self.assertEqual(self.send(**kw).status_code, 400)
        self.assertEqual(SupportTicket.objects.count(), 0)

    def test_per_email_daily_cap(self):
        for _ in range(3):
            self.assertEqual(self.send().status_code, 201)
        cache.clear()   # isolate the per-address cap from the per-IP throttle
        r = self.send()
        self.assertEqual((r.status_code, r.data['code']), (429, 'too_many_requests'))
        # a different address is not affected by that cap
        self.assertEqual(self.send(email='other@example.com').status_code, 201)

    def test_endpoint_is_throttled_per_client(self):
        codes = [self.send(email=f'u{i}@example.com').status_code for i in range(4)]
        self.assertEqual(codes, [201, 201, 201, 429])

    def test_bad_token_does_not_block_guests(self):
        c = APIClient()
        c.credentials(HTTP_AUTHORIZATION='Bearer garbage.token.value')
        self.assertEqual(self.send(client=c).status_code, 201)

    def test_guest_cannot_read_anything(self):
        self.send()
        t = SupportTicket.objects.get()
        self.assertEqual(self.guest.get(f'{TICKETS}{t.pk}/').status_code, 401)
        self.assertEqual(self.guest.get(TICKETS).status_code, 401)
