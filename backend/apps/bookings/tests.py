from django.test import TestCase

# ═══════════════════════════════════════════════════════════════════════════
# Trust & Safety Part 9 (security pass) — regression tests for the
# booking-creation enforcement gap. apps/admin_panel/enforcement.py existed
# and was unit-tested since Part 3, but nothing ever called it from here, so
# a booking-restricted or suspended customer could still create bookings via
# a direct API call. See the fix + comment in BookingView.post.
# ═══════════════════════════════════════════════════════════════════════════
from datetime import date, time as dtime

from rest_framework.test import APIClient

from apps.admin_panel.models import ModerationAction
from apps.users.models import User
from apps.bookings.models import Booking


class BookingEnforcementTests(TestCase):
    def setUp(self):
        self.customer = User.objects.create_user(
            email='cust@test.com', name='Cust', role='customer', password='pass1234')
        self.professional = User.objects.create_user(
            email='pro@test.com', name='Pro', role='professional', password='pass1234')
        self.admin = User.objects.create_user(
            email='admin@test.com', name='Admin', role='admin', password='pass1234')
        self.client_api = APIClient()
        self.client_api.force_authenticate(self.customer)

    def _post(self):
        return self.client_api.post('/api/bookings/', {
            'professional': self.professional.pk,
            'date': str(date(2026, 12, 1)),
            'time': '10:00:00',
        }, format='json')

    def test_unrestricted_customer_can_book(self):
        r = self._post()
        self.assertEqual(r.status_code, 201, r.data)

    def test_booking_restricted_customer_is_blocked_server_side(self):
        ModerationAction.objects.create(
            target_user=self.customer, performed_by=self.admin,
            action_type='restrict_booking', reason='abuse')
        r = self._post()
        self.assertEqual(r.status_code, 403, r.data)
        self.assertEqual(r.data.get('code'), 'booking_restricted')
        self.assertEqual(Booking.objects.count(), 0)

    def test_suspended_customer_is_blocked_server_side(self):
        ModerationAction.objects.create(
            target_user=self.customer, performed_by=self.admin,
            action_type='suspend_permanent', reason='severe abuse')
        r = self._post()
        self.assertEqual(r.status_code, 403, r.data)
        self.assertEqual(Booking.objects.count(), 0)

    def test_restriction_on_professional_does_not_block_customer_booking(self):
        """Only the acting customer's own restrictions apply to their own request."""
        ModerationAction.objects.create(
            target_user=self.professional, performed_by=self.admin,
            action_type='restrict_booking', reason='unrelated')
        r = self._post()
        self.assertEqual(r.status_code, 201, r.data)

    def test_reversed_restriction_no_longer_blocks(self):
        action = ModerationAction.objects.create(
            target_user=self.customer, performed_by=self.admin,
            action_type='restrict_booking', reason='abuse')
        action.is_active = False
        action.save()
        r = self._post()
        self.assertEqual(r.status_code, 201, r.data)

    def test_messaging_restriction_does_not_block_booking(self):
        """Restrictions are scoped to their own feature only."""
        ModerationAction.objects.create(
            target_user=self.customer, performed_by=self.admin,
            action_type='restrict_messaging', reason='unrelated')
        r = self._post()
        self.assertEqual(r.status_code, 201, r.data)

    def test_booking_slot_conflict_prevention(self):
        # First booking reserves 2026-12-01 at 10:00:00
        r1 = self._post()
        self.assertEqual(r1.status_code, 201)

        # Another customer attempts to reserve the exact same slot
        other_customer = User.objects.create_user(
            email='other_cust@test.com', name='Other', role='customer', password='pass'
        )
        self.client_api.force_authenticate(other_customer)
        r2 = self.client_api.post('/api/bookings/', {
            'professional': self.professional.pk,
            'date': str(date(2026, 12, 1)),
            'time': '10:00:00',
        }, format='json')
        self.assertEqual(r2.status_code, 409)
        self.assertIn('already reserved', r2.data.get('error', '').lower())

    def test_unavailable_professional_cannot_be_booked(self):
        from apps.profiles.models import ProfessionalProfile
        prof_profile, _ = ProfessionalProfile.objects.get_or_create(user=self.professional)
        prof_profile.is_available = False
        prof_profile.save()

        r = self._post()
        self.assertEqual(r.status_code, 400)
        self.assertIn('unavailable', r.data.get('error', '').lower())