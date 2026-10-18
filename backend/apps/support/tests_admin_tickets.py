# apps/support/tests_admin_tickets.py
#
# Run with:  python manage.py test apps.support.tests_admin_tickets

from unittest import mock

from django.core.cache import cache
from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from apps.support.models import SupportTicket, TicketEvent, TicketMessage
from apps.users.models import User

NOTIFY = 'apps.support.admin_views.notify_user'
EMAIL = 'apps.support.admin_views.send_brevo_email'
BASE = '/api/support/admin/tickets/'
USER_API = '/api/support/tickets/'


def make_user(email, role='customer', **kw):
    return User.objects.create_user(email=email, name=email.split('@')[0], role=role,
                                    password='Passw0rd!x', **kw)


@override_settings(PASSWORD_HASHERS=['django.contrib.auth.hashers.MD5PasswordHasher'])
class Base(TestCase):
    def setUp(self):
        cache.clear()
        self.admin = make_user('admin@example.com', 'admin')
        self.admin2 = make_user('admin2@example.com', 'admin')
        self.alice = make_user('alice@example.com', 'customer')
        self.pro = make_user('pro@example.com', 'professional')
        self.api = self.client_for(self.admin)

    def client_for(self, user):
        c = APIClient()
        c.force_authenticate(user)
        return c

    def ticket(self, user=None, status='open', body='help me', **kw):
        user = user if user is not None else self.alice
        t = SupportTicket.objects.create(user=user, role=user.role, subject=kw.pop('subject', 'S'),
                                         status=status, **kw)
        TicketMessage.objects.create(ticket=t, author=user, body=body)
        return t

    def guest_ticket(self, email='guest@example.com', **kw):
        t = SupportTicket.objects.create(user=None, role='guest', contact_email=email,
                                         subject=kw.pop('subject', 'Guest issue'), **kw)
        TicketMessage.objects.create(ticket=t, author=None, body='cannot log in')
        return t

    def reply(self, t, body='We are looking into it.', internal=False, client=None):
        with mock.patch(NOTIFY), mock.patch(EMAIL):
            return (client or self.api).post(f'{BASE}{t.pk}/reply/',
                                             {'body': body, 'internal': internal}, format='json')


class AccessTests(Base):
    def test_anonymous_gets_401_and_non_admins_get_403(self):
        t = self.ticket()
        urls = [('get', BASE), ('get', f'{BASE}summary/'), ('get', f'{BASE}{t.pk}/'),
                ('patch', f'{BASE}{t.pk}/'), ('post', f'{BASE}{t.pk}/reply/')]
        for who, expected in [(APIClient(), 401), (self.client_for(self.alice), 403),
                              (self.client_for(self.pro), 403)]:
            for method, url in urls:
                with self.subTest(url=url, method=method, expected=expected):
                    r = getattr(who, method)(url, {'status': 'closed', 'body': 'x'}, format='json')
                    self.assertEqual(r.status_code, expected)
        t.refresh_from_db()
        self.assertEqual((t.status, t.messages.count(), t.priority), ('open', 1, 'normal'))

    def test_missing_ticket_is_404_for_admin(self):
        self.assertEqual(self.api.get(f'{BASE}99999/').status_code, 404)


class ListTests(Base):
    def test_list_shape_and_ordering(self):
        old = self.ticket(subject='old')
        new = self.ticket(subject='new')
        SupportTicket.objects.filter(pk=old.pk).update(last_activity_at='2020-01-01T00:00:00Z')
        r = self.api.get(BASE)
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data['count'], 2)
        self.assertEqual([t['subject'] for t in r.data['results']], ['new', 'old'])
        row = r.data['results'][0]
        self.assertEqual(row['requester']['email'], 'alice@example.com')
        self.assertTrue(row['needs_reply'])
        self.assertNotIn('messages', row)

    def test_filters(self):
        a = self.ticket(status='open', category='payment', priority='high')
        b = self.ticket(status='closed', category='account')
        c = self.ticket(status='resolved', assigned_to=self.admin)
        ids = lambda qs: sorted(t['id'] for t in self.api.get(BASE + qs).data['results'])
        self.assertEqual(ids('?status=open'), [a.pk])
        self.assertEqual(ids('?status=active'), [a.pk])
        self.assertEqual(ids('?status=closed'), [b.pk])
        self.assertEqual(ids('?category=payment'), [a.pk])
        self.assertEqual(ids('?priority=high'), [a.pk])
        self.assertEqual(ids('?assigned=me'), [c.pk])
        self.assertEqual(ids(f'?assigned={self.admin.pk}'), [c.pk])
        self.assertEqual(ids('?assigned=unassigned'), sorted([a.pk, b.pk]))

    def test_invalid_filters_are_400(self):
        for qs in ('?status=zzz', '?priority=zzz', '?category=zzz', '?assigned=abc',
                   '?limit=abc'):
            with self.subTest(qs=qs):
                self.assertEqual(self.api.get(BASE + qs).status_code, 400)

    def test_search(self):
        a = self.ticket(subject='Withdrawal failed')
        g = self.guest_ticket(email='lost.user@example.com')
        found = lambda q: sorted(t['id'] for t in self.api.get(BASE, {'q': q}).data['results'])
        self.assertEqual(found('withdrawal'), [a.pk])
        self.assertEqual(found(a.reference), [a.pk])
        self.assertEqual(found('lost.user'), [g.pk])
        self.assertEqual(found('alice@'), [a.pk])
        self.assertEqual(found('nothing-matches'), [])

    def test_paging(self):
        for i in range(5):
            self.ticket(subject=f't{i}')
        r = self.api.get(BASE, {'limit': 2, 'offset': 2})
        self.assertEqual((r.data['count'], len(r.data['results'])), (5, 2))
        self.assertEqual(len(self.api.get(BASE, {'limit': 9999}).data['results']), 5)  # capped, not an error

    def test_needs_reply_follows_the_last_public_message(self):
        t = self.ticket()
        self.assertEqual(self.api.get(BASE + '?needs_reply=1').data['count'], 1)
        self.reply(t)
        self.assertEqual(self.api.get(BASE + '?needs_reply=1').data['count'], 0)
        # an internal note does not change who is waiting
        self.reply(t, 'note', internal=True)
        self.assertEqual(self.api.get(BASE + '?needs_reply=1').data['count'], 0)
        # the user answers: back in the staff queue
        TicketMessage.objects.create(ticket=t, author=self.alice, body='more info')
        self.assertEqual(self.api.get(BASE + '?needs_reply=1').data['count'], 1)

    def test_summary_counts(self):
        self.ticket(status='open')
        self.ticket(status='awaiting_user', assigned_to=self.admin)
        self.ticket(status='closed')
        d = self.api.get(f'{BASE}summary/').data
        self.assertEqual((d['open'], d['awaiting_user'], d['closed'], d['resolved']), (1, 1, 1, 0))
        self.assertEqual((d['unassigned_active'], d['mine_active'], d['needs_reply']), (1, 1, 2))


class DetailTests(Base):
    def test_detail_includes_internal_notes_events_and_requester(self):
        t = self.ticket(platform='android', app_language='ur')
        self.reply(t, 'public answer')
        self.reply(t, 'SECRET note', internal=True)
        d = self.api.get(f'{BASE}{t.pk}/').data
        bodies = {m['body']: m for m in d['messages']}
        self.assertTrue(bodies['SECRET note']['is_internal'])
        self.assertFalse(bodies['public answer']['is_internal'])
        self.assertTrue(bodies['public answer']['is_staff'])
        self.assertEqual(bodies['public answer']['author_name'], 'admin')
        self.assertEqual([e['action'] for e in d['events']], ['staff_reply', 'internal_note'])
        self.assertEqual((d['platform'], d['app_language']), ('android', 'ur'))
        self.assertEqual(d['requester']['email'], 'alice@example.com')

    def test_guest_ticket_detail(self):
        d = self.api.get(f'{BASE}{self.guest_ticket().pk}/').data
        self.assertIsNone(d['requester'])
        self.assertEqual((d['role'], d['contact_email']), ('guest', 'guest@example.com'))


class ReplyTests(Base):
    def test_public_reply_marks_awaiting_user_assigns_and_notifies(self):
        t = self.ticket()
        before = t.last_activity_at
        with mock.patch(NOTIFY) as notify, mock.patch(EMAIL) as email:
            with self.captureOnCommitCallbacks(execute=True):
                r = self.api.post(f'{BASE}{t.pk}/reply/', {'body': 'On it.'}, format='json')
        self.assertEqual(r.status_code, 201)
        t.refresh_from_db()
        self.assertEqual((t.status, t.assigned_to), ('awaiting_user', self.admin))
        self.assertGreater(t.last_activity_at, before)
        notify.assert_called_once()
        self.assertEqual(notify.call_args.args[0], self.alice)
        self.assertNotIn('On it.', notify.call_args.args[2])     # text is not pushed
        email.assert_not_called()                                # registered users: push only

    def test_existing_assignee_is_kept(self):
        t = self.ticket(assigned_to=self.admin2)
        self.reply(t)
        t.refresh_from_db()
        self.assertEqual(t.assigned_to, self.admin2)

    def test_status_after_public_reply(self):
        for start, end in [('open', 'awaiting_user'), ('in_progress', 'awaiting_user'),
                           ('awaiting_user', 'awaiting_user'), ('resolved', 'resolved')]:
            with self.subTest(start=start):
                t = self.ticket(status=start)
                self.assertEqual(self.reply(t).status_code, 201)
                t.refresh_from_db()
                self.assertEqual(t.status, end)

    def test_owner_sees_the_staff_reply_but_never_the_internal_note(self):
        t = self.ticket()
        self.reply(t, 'Public answer')
        self.reply(t, 'SECRET note', internal=True)
        r = self.client_for(self.alice).get(f'{USER_API}{t.pk}/')
        raw = r.content.decode()
        self.assertIn('Public answer', raw)
        self.assertNotIn('SECRET', raw)
        self.assertNotIn('admin@example.com', raw)
        listing = self.client_for(self.alice).get(USER_API).data['results'][0]
        self.assertTrue(listing['last_message_is_staff'])
        self.assertEqual(listing['status'], 'awaiting_user')

    def test_internal_note_has_no_side_effects(self):
        t = self.ticket()
        before = (t.status, t.last_activity_at, t.assigned_to_id)
        with mock.patch(NOTIFY) as notify, mock.patch(EMAIL) as email:
            with self.captureOnCommitCallbacks(execute=True):
                r = self.api.post(f'{BASE}{t.pk}/reply/',
                                  {'body': 'private', 'internal': True}, format='json')
        self.assertEqual(r.status_code, 201)
        t.refresh_from_db()
        self.assertEqual((t.status, t.last_activity_at, t.assigned_to_id), before)
        notify.assert_not_called()
        email.assert_not_called()
        self.assertTrue(t.messages.filter(is_internal=True, is_staff=True).exists())

    def test_closed_ticket_rejects_public_reply_but_allows_internal_note(self):
        t = self.ticket(status='closed')
        r = self.reply(t)
        self.assertEqual((r.status_code, r.data['code']), (409, 'ticket_closed'))
        self.assertEqual(t.messages.count(), 1)
        self.assertEqual(self.reply(t, 'note', internal=True).status_code, 201)

    def test_validation(self):
        t = self.ticket()
        for body in ('', '   ', 'x' * 5001):
            with self.subTest(len=len(body)):
                self.assertEqual(self.reply(t, body).status_code, 400)
        self.assertEqual(t.messages.count(), 1)

    def test_guest_reply_is_emailed_with_escaped_html(self):
        t = self.guest_ticket()
        with mock.patch(NOTIFY) as notify, mock.patch(EMAIL) as email:
            with self.captureOnCommitCallbacks(execute=True):
                r = self.api.post(f'{BASE}{t.pk}/reply/',
                                  {'body': 'Try <b>resetting</b> your password.'}, format='json')
        self.assertEqual(r.status_code, 201)
        notify.assert_not_called()
        email.assert_called_once()
        to, _name, subject, html, text = email.call_args.args
        self.assertEqual(to, 'guest@example.com')
        self.assertIn(t.reference, subject)
        self.assertIn('&lt;b&gt;', html)
        self.assertNotIn('<b>resetting', html)
        self.assertIn('<b>resetting</b>', text)       # plain text part stays literal

    def test_notification_failures_never_fail_the_reply(self):
        t = self.ticket()
        g = self.guest_ticket()
        with mock.patch(NOTIFY, side_effect=RuntimeError('fcm')), \
                mock.patch(EMAIL, side_effect=RuntimeError('brevo')), \
                self.assertLogs('apps.support.admin_views', 'ERROR'):
            with self.captureOnCommitCallbacks(execute=True):
                r1 = self.api.post(f'{BASE}{t.pk}/reply/', {'body': 'a'}, format='json')
                r2 = self.api.post(f'{BASE}{g.pk}/reply/', {'body': 'b'}, format='json')
        self.assertEqual((r1.status_code, r2.status_code), (201, 201))


class UpdateTests(Base):
    def patch(self, t, **data):
        with mock.patch(NOTIFY):
            return self.api.patch(f'{BASE}{t.pk}/', data, format='json')

    def test_status_priority_and_assignee_are_recorded(self):
        t = self.ticket()
        r = self.patch(t, status='in_progress', priority='high', assigned_to='me')
        self.assertEqual(r.status_code, 200, r.content)
        t.refresh_from_db()
        self.assertEqual((t.status, t.priority, t.assigned_to), ('in_progress', 'high', self.admin))
        self.assertEqual(sorted(e.action for e in t.events.all()),
                         ['assigned', 'priority_changed', 'status_changed'])
        self.assertEqual(r.data['status'], 'in_progress')

    def test_noop_changes_write_nothing(self):
        t = self.ticket()
        self.patch(t, status='open', priority='normal', assigned_to=None)
        self.assertEqual(t.events.count(), 0)

    def test_assign_to_other_admin_and_unassign(self):
        t = self.ticket()
        self.assertEqual(self.patch(t, assigned_to=self.admin2.pk).status_code, 200)
        t.refresh_from_db()
        self.assertEqual(t.assigned_to, self.admin2)
        self.patch(t, assigned_to=None)
        t.refresh_from_db()
        self.assertIsNone(t.assigned_to)

    def test_assignee_must_be_an_active_admin(self):
        t = self.ticket()
        inactive = make_user('gone@example.com', 'admin')
        User.objects.filter(pk=inactive.pk).update(is_active=False)
        for bad in (self.alice.pk, inactive.pk, 99999, 'someone', True, 1.5):
            with self.subTest(bad=bad):
                self.assertEqual(self.patch(t, assigned_to=bad).status_code, 400)
        t.refresh_from_db()
        self.assertIsNone(t.assigned_to)

    def test_closing_and_reopening_manage_closed_at(self):
        t = self.ticket()
        self.patch(t, status='closed')
        t.refresh_from_db()
        self.assertIsNotNone(t.closed_at)
        self.patch(t, status='open')
        t.refresh_from_db()
        self.assertIsNone(t.closed_at)
        # a reopened ticket accepts user replies again
        r = self.client_for(self.alice).post(f'{USER_API}{t.pk}/messages/', {'body': 'hi'}, format='json')
        self.assertEqual(r.status_code, 201)

    def test_user_is_told_when_resolved_or_closed_but_not_for_other_changes(self):
        t = self.ticket()
        with mock.patch(NOTIFY) as notify:
            with self.captureOnCommitCallbacks(execute=True):
                self.api.patch(f'{BASE}{t.pk}/', {'status': 'in_progress'}, format='json')
                self.api.patch(f'{BASE}{t.pk}/', {'priority': 'high'}, format='json')
        notify.assert_not_called()
        with mock.patch(NOTIFY) as notify:
            with self.captureOnCommitCallbacks(execute=True):
                self.api.patch(f'{BASE}{t.pk}/', {'status': 'resolved'}, format='json')
        notify.assert_called_once()

    def test_invalid_values_and_empty_body(self):
        t = self.ticket()
        for data in ({'status': 'zzz'}, {'priority': 'urgent'}, {}):
            with self.subTest(data=data):
                self.assertEqual(self.patch(t, **data).status_code, 400)
        t.refresh_from_db()
        self.assertEqual((t.status, t.priority), ('open', 'normal'))

    def test_staff_only_fields_are_not_writable_by_other_keys(self):
        t = self.ticket()
        self.patch(t, status='in_progress', reference='PF-999999', user=self.pro.pk, role='admin')
        t.refresh_from_db()
        self.assertEqual((t.user, t.role), (self.alice, 'customer'))
        self.assertNotEqual(t.reference, 'PF-999999')
