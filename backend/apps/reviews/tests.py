# apps/reviews/tests.py

from datetime import date, time
from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status

from apps.reviews.models import Review
from apps.bookings.models import Booking
from apps.profiles.models import ProfessionalProfile
from apps.search.models import Category

User = get_user_model()


class ReviewSystemTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()

        self.category = Category.objects.create(name='Plumber')

        self.customer = User.objects.create_user(
            email='customer_rev@example.com',
            password='password123',
            name='Reviewer Customer',
            role='customer',
        )

        self.unrelated_customer = User.objects.create_user(
            email='stranger@example.com',
            password='password123',
            name='Stranger Customer',
            role='customer',
        )

        self.pro_user = User.objects.create_user(
            email='pro_rev@example.com',
            password='password123',
            name='Reviewee Pro',
            role='professional',
        )
        self.pro_profile = ProfessionalProfile.objects.create(
            user=self.pro_user,
            category=self.category,
            hourly_rate=40.00,
            average_rating=0.0,
        )

        # Valid completed booking for self.customer
        self.completed_booking = Booking.objects.create(
            customer=self.customer,
            professional=self.pro_user,
            date=date.today(),
            time=time(11, 0),
            status='completed',
            total_price=40.00,
            payment_status='paid',
        )

    def test_unrelated_customer_cannot_review_without_booking(self):
        self.client.force_authenticate(user=self.unrelated_customer)
        res = self.client.post(f'/api/reviews/professionals/{self.pro_user.id}/reviews/', {
            'rating': 5,
            'comment': 'I never hired them but I want to review!',
        })
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
        self.assertIn('only review professionals with whom you have booked', res.data.get('error', ''))

    def test_verified_customer_can_review(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post(f'/api/reviews/professionals/{self.pro_user.id}/reviews/', {
            'rating': 5,
            'comment': 'Outstanding plumbing service!',
        })
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertTrue(res.data.get('is_verified_service'))

        # Check average rating updated on profile
        self.pro_profile.refresh_from_db()
        self.assertEqual(float(self.pro_profile.average_rating), 5.0)

    def test_cannot_review_oneself(self):
        self.client.force_authenticate(user=self.pro_user)
        res = self.client.post(f'/api/reviews/professionals/{self.pro_user.id}/reviews/', {
            'rating': 5,
            'comment': 'I am the best!',
        })
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('cannot review yourself', res.data.get('error', '').lower())

    def test_cannot_submit_duplicate_review(self):
        self.client.force_authenticate(user=self.customer)
        # First review succeeds
        res1 = self.client.post(f'/api/reviews/professionals/{self.pro_user.id}/reviews/', {
            'rating': 4,
            'comment': 'Great job!',
        })
        self.assertEqual(res1.status_code, status.HTTP_201_CREATED)

        # Second review must fail
        res2 = self.client.post(f'/api/reviews/professionals/{self.pro_user.id}/reviews/', {
            'rating': 5,
            'comment': 'Trying to review again',
        })
        self.assertEqual(res2.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('already reviewed', res2.data.get('error', '').lower())
