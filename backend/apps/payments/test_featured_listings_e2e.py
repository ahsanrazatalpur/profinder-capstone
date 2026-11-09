# apps/payments/test_featured_listings_e2e.py

import sys
from decimal import Decimal
from datetime import timedelta
from unittest.mock import patch, MagicMock

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

from django.test import TestCase
from django.utils import timezone
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status

from apps.subscriptions.models import (
    FeaturedPromotionPackage,
    FeaturedListingCampaign,
    CampaignAuditLog,
    SubscriptionPlan,
    Subscription,
)
from apps.payments.models import Payment
from apps.payments.views import (
    fulfill_payment_entitlement,
    sweep_expired_campaigns,
)
from apps.profiles.models import ProfessionalProfile, UserProfile
from apps.search.models import Category

User = get_user_model()


class FeaturedListingsE2ETestCase(TestCase):
    """
    Comprehensive End-to-End Test Suite for ProFinder's Featured Listing
    Monetization System using the existing Safepay integration.
    Covers all 14 required security, pricing, lifecycle, and ranking scenarios.
    """

    def setUp(self):
        self.client = APIClient()

        # 1. Categories
        self.cat_electrician = Category.objects.create(name='Electricians', slug='electricians')
        self.cat_doctor = Category.objects.create(name='Doctors', slug='doctors')

        # 2. Featured Packages (Rs. 99 / 7d, Rs. 199 / 15d, Rs. 349 / 30d)
        self.pkg_7d, _ = FeaturedPromotionPackage.objects.get_or_create(
            duration_days=7,
            defaults={'name': 'Featured 7 Days', 'price': Decimal('99.00'), 'currency': 'PKR', 'is_active': True}
        )
        self.pkg_15d, _ = FeaturedPromotionPackage.objects.get_or_create(
            duration_days=15,
            defaults={'name': 'Featured 15 Days', 'price': Decimal('199.00'), 'currency': 'PKR', 'is_active': True}
        )
        self.pkg_30d, _ = FeaturedPromotionPackage.objects.get_or_create(
            duration_days=30,
            defaults={'name': 'Featured 30 Days', 'price': Decimal('349.00'), 'currency': 'PKR', 'is_active': True}
        )

        # 3. Subscription Plans (Free vs Pro)
        self.plan_free, _ = SubscriptionPlan.objects.get_or_create(
            name='Professional Free',
            plan_type='professional',
            billing='free',
            price=Decimal('0.00'),
            defaults={'currency': 'PKR', 'is_active': True}
        )
        self.plan_pro, _ = SubscriptionPlan.objects.get_or_create(
            name='Professional Pro Monthly',
            plan_type='professional',
            billing='monthly',
            price=Decimal('499.00'),
            defaults={'currency': 'PKR', 'is_active': True}
        )

        # 4. Free Professional User
        self.free_user = User.objects.create_user(
            email='free_pro@profinder.test',
            password='TestPassword123!',
            name='Ali Electrician',
            role='professional',
        )
        self.free_profile = ProfessionalProfile.objects.create(
            user=self.free_user,
            category=self.cat_electrician,
            hourly_rate=Decimal('500.00'),
            experience_years=5,
            is_available=True,
        )
        self.free_user_profile = UserProfile.objects.create(
            user=self.free_user,
            full_name='Ali Electrician',
            city='Lahore',
        )
        Subscription.objects.create(
            user=self.free_user,
            plan=self.plan_free,
            status='active',
            end_date=None,
        )

        # 5. Pro Professional User
        self.pro_user = User.objects.create_user(
            email='pro_pro@profinder.test',
            password='TestPassword123!',
            name='Tariq Electrician Pro',
            role='professional',
        )
        self.pro_profile = ProfessionalProfile.objects.create(
            user=self.pro_user,
            category=self.cat_electrician,
            hourly_rate=Decimal('1200.00'),
            experience_years=10,
            is_available=True,
        )
        self.pro_user_profile = UserProfile.objects.create(
            user=self.pro_user,
            full_name='Tariq Electrician Pro',
            city='Lahore',
        )
        Subscription.objects.create(
            user=self.pro_user,
            plan=self.plan_pro,
            status='active',
            end_date=timezone.now() + timedelta(days=30),
        )

        # 6. Customer User
        self.customer_user = User.objects.create_user(
            email='customer@profinder.test',
            password='TestPassword123!',
            name='Bilal Customer',
            role='customer',
        )
        UserProfile.objects.create(
            user=self.customer_user,
            full_name='Bilal Customer',
            city='Lahore',
        )

    # ──────────────────────────────────────────────────────────────────────────
    # SCENARIOS 1, 2, 3: Exact Package Pricing on Backend
    # ──────────────────────────────────────────────────────────────────────────

    @patch('apps.payments.safepay.SafepayGateway.create_order')
    @patch('apps.payments.safepay.SafepayGateway.create_passport_token')
    def test_01_rs_99_payment_package_7_days(self, mock_passport, mock_order):
        mock_order.return_value = {'tracker': 'track_test_99_7d'}
        mock_passport.return_value = 'v1_test_token'

        self.client.force_authenticate(user=self.free_user)
        res = self.client.post('/api/payments/checkout/initialize/', {
            'purpose': 'featured_listing',
            'package_id': self.pkg_7d.id,
            'category_id': self.cat_electrician.id,
        })
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        data = res.data
        self.assertEqual(data['amount'], '99.00')
        self.assertEqual(data['currency'], 'PKR')
        self.assertEqual(data['duration_days'], 7)

        # Check DB payment
        payment = Payment.objects.get(safepay_tracker='track_test_99_7d')
        self.assertEqual(payment.amount, Decimal('99.00'))
        self.assertEqual(payment.purpose, 'featured_listing')
        self.assertEqual(payment.status, 'pending')

        # Check DB campaign
        camp = FeaturedListingCampaign.objects.get(payment=payment)
        self.assertEqual(camp.duration_days, 7)
        self.assertFalse(camp.is_active)
        self.assertFalse(camp.is_currently_running())

    @patch('apps.payments.safepay.SafepayGateway.create_order')
    @patch('apps.payments.safepay.SafepayGateway.create_passport_token')
    def test_02_rs_199_payment_package_15_days(self, mock_passport, mock_order):
        mock_order.return_value = {'tracker': 'track_test_199_15d'}
        mock_passport.return_value = 'v1_test_token'

        self.client.force_authenticate(user=self.free_user)
        res = self.client.post('/api/payments/checkout/initialize/', {
            'purpose': 'featured_listing',
            'package_id': self.pkg_15d.id,
            'category_id': self.cat_electrician.id,
        })
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data['amount'], '199.00')
        self.assertEqual(res.data['duration_days'], 15)

    @patch('apps.payments.safepay.SafepayGateway.create_order')
    @patch('apps.payments.safepay.SafepayGateway.create_passport_token')
    def test_03_rs_349_payment_package_30_days(self, mock_passport, mock_order):
        mock_order.return_value = {'tracker': 'track_test_349_30d'}
        mock_passport.return_value = 'v1_test_token'

        self.client.force_authenticate(user=self.pro_user)
        res = self.client.post('/api/payments/checkout/initialize/', {
            'purpose': 'featured_listing',
            'package_id': self.pkg_30d.id,
            'category_id': self.cat_electrician.id,
        })
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data['amount'], '349.00')
        self.assertEqual(res.data['duration_days'], 30)

    # ──────────────────────────────────────────────────────────────────────────
    # SCENARIOS 4, 5, 6, 7: Payment Lifecycle States
    # ──────────────────────────────────────────────────────────────────────────

    @patch('apps.payments.safepay.SafepayGateway.query_reporter_status')
    def test_04_successful_payment_verification_and_activation(self, mock_reporter):
        mock_reporter.return_value = {'status': 'completed', 'state': 'TRACKER_COMPLETED', 'captured': True}

        # Create pending payment and campaign
        payment = Payment.objects.create(
            user=self.free_user,
            amount=Decimal('99.00'),
            currency='PKR',
            purpose='featured_listing',
            gateway='safepay',
            safepay_tracker='track_success_test_4',
            status='pending',
        )
        camp = FeaturedListingCampaign.objects.create(
            professional=self.free_profile,
            category=self.cat_electrician,
            package=self.pkg_7d,
            duration_days=7,
            payment=payment,
            is_active=False,
        )

        self.client.force_authenticate(user=self.free_user)
        res = self.client.get(f'/api/payments/verify-status/?tracker={payment.safepay_tracker}')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['status'], 'completed')

        payment.refresh_from_db()
        camp.refresh_from_db()

        self.assertEqual(payment.status, 'completed')
        self.assertTrue(camp.is_active)
        self.assertTrue(camp.is_currently_running())
        self.assertIsNotNone(camp.start_date)
        self.assertIsNotNone(camp.end_date)
        # Check exactly 7 days
        diff = camp.end_date - camp.start_date
        self.assertEqual(diff.days, 7)

        # Check Audit Log
        log = CampaignAuditLog.objects.filter(campaign=camp, action='activated').first()
        self.assertIsNotNone(log)
        self.assertEqual(log.new_state, 'active')

    @patch('apps.payments.safepay.SafepayGateway.query_reporter_status')
    def test_05_failed_payment_does_not_activate(self, mock_reporter):
        mock_reporter.return_value = {'status': 'failed', 'state': 'FAILED', 'captured': False}

        payment = Payment.objects.create(
            user=self.free_user,
            amount=Decimal('99.00'),
            currency='PKR',
            purpose='featured_listing',
            gateway='safepay',
            safepay_tracker='track_failed_test_5',
            status='pending',
        )
        camp = FeaturedListingCampaign.objects.create(
            professional=self.free_profile,
            category=self.cat_electrician,
            package=self.pkg_7d,
            duration_days=7,
            payment=payment,
            is_active=False,
        )

        self.client.force_authenticate(user=self.free_user)
        res = self.client.get(f'/api/payments/verify-status/?tracker={payment.safepay_tracker}')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['status'], 'failed')

        camp.refresh_from_db()
        self.assertFalse(camp.is_active)
        self.assertFalse(camp.is_currently_running())

    @patch('apps.payments.safepay.SafepayGateway.query_reporter_status')
    def test_06_cancelled_checkout_does_not_activate(self, mock_reporter):
        mock_reporter.return_value = {'status': 'cancelled', 'state': 'CANCELLED', 'captured': False}

        payment = Payment.objects.create(
            user=self.free_user,
            amount=Decimal('199.00'),
            currency='PKR',
            purpose='featured_listing',
            gateway='safepay',
            safepay_tracker='track_cancelled_test_6',
            status='pending',
        )
        camp = FeaturedListingCampaign.objects.create(
            professional=self.free_profile,
            category=self.cat_electrician,
            package=self.pkg_15d,
            duration_days=15,
            payment=payment,
            is_active=False,
        )

        self.client.force_authenticate(user=self.free_user)
        res = self.client.get(f'/api/payments/verify-status/?tracker={payment.safepay_tracker}')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['status'], 'cancelled')

        camp.refresh_from_db()
        self.assertFalse(camp.is_active)
        self.assertFalse(camp.is_currently_running())

    @patch('apps.payments.safepay.SafepayGateway.query_reporter_status')
    def test_07_pending_payment_leaves_campaign_inactive(self, mock_reporter):
        mock_reporter.return_value = {'status': 'pending', 'state': 'PENDING', 'captured': False}

        payment = Payment.objects.create(
            user=self.free_user,
            amount=Decimal('349.00'),
            currency='PKR',
            purpose='featured_listing',
            gateway='safepay',
            safepay_tracker='track_pending_test_7',
            status='pending',
        )
        camp = FeaturedListingCampaign.objects.create(
            professional=self.free_profile,
            category=self.cat_electrician,
            package=self.pkg_30d,
            duration_days=30,
            payment=payment,
            is_active=False,
        )

        self.client.force_authenticate(user=self.free_user)
        res = self.client.get(f'/api/payments/verify-status/?tracker={payment.safepay_tracker}')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['status'], 'pending')

        camp.refresh_from_db()
        self.assertFalse(camp.is_active)
        self.assertFalse(camp.is_currently_running())

    # ──────────────────────────────────────────────────────────────────────────
    # SCENARIOS 8, 9: Idempotency & Invalid Reference Handling
    # ──────────────────────────────────────────────────────────────────────────

    def test_08_duplicate_activation_idempotency(self):
        payment = Payment.objects.create(
            user=self.free_user,
            amount=Decimal('99.00'),
            currency='PKR',
            purpose='featured_listing',
            gateway='safepay',
            safepay_tracker='track_idempotent_test_8',
            status='pending',
        )
        camp = FeaturedListingCampaign.objects.create(
            professional=self.free_profile,
            category=self.cat_electrician,
            package=self.pkg_7d,
            duration_days=7,
            payment=payment,
            is_active=False,
        )

        # First fulfillment
        res1 = fulfill_payment_entitlement(payment)
        self.assertTrue(res1)
        camp.refresh_from_db()
        first_end_date = camp.end_date

        # Second fulfillment (duplicate webhook / callback)
        payment.refresh_from_db()
        res2 = fulfill_payment_entitlement(payment)
        self.assertTrue(res2)
        camp.refresh_from_db()

        # End date must NOT have been pushed forward or duplicated
        self.assertEqual(camp.end_date, first_end_date)
        self.assertEqual(CampaignAuditLog.objects.filter(campaign=camp, action='activated').count(), 1)

    def test_09_invalid_payment_reference(self):
        self.client.force_authenticate(user=self.free_user)
        res = self.client.get('/api/payments/verify-status/?tracker=track_non_existent_404')
        self.assertEqual(res.status_code, status.HTTP_404_NOT_FOUND)

    # ──────────────────────────────────────────────────────────────────────────
    # SCENARIOS 10, 11: Authorization & Price Tampering Defense
    # ──────────────────────────────────────────────────────────────────────────

    def test_10_unauthorized_purchase_requests(self):
        # A. Unauthenticated
        res1 = self.client.post('/api/payments/checkout/initialize/', {
            'purpose': 'featured_listing',
            'package_id': self.pkg_7d.id,
            'category_id': self.cat_electrician.id,
        })
        self.assertEqual(res1.status_code, status.HTTP_401_UNAUTHORIZED)

        # B. Customer role attempting to purchase professional promotion
        self.client.force_authenticate(user=self.customer_user)
        res2 = self.client.post('/api/payments/checkout/initialize/', {
            'purpose': 'featured_listing',
            'package_id': self.pkg_7d.id,
            'category_id': self.cat_electrician.id,
        })
        self.assertEqual(res2.status_code, status.HTTP_403_FORBIDDEN)

    @patch('apps.payments.safepay.SafepayGateway.create_order')
    @patch('apps.payments.safepay.SafepayGateway.create_passport_token')
    def test_11_client_side_price_tampering_ignored(self, mock_passport, mock_order):
        mock_order.return_value = {'tracker': 'track_tamper_defense'}
        mock_passport.return_value = 'v1_test_token'

        self.client.force_authenticate(user=self.free_user)
        # Malicious client sends price=1.00 or amount=5.00
        res = self.client.post('/api/payments/checkout/initialize/', {
            'purpose': 'featured_listing',
            'package_id': self.pkg_7d.id,
            'category_id': self.cat_electrician.id,
            'price': '1.00',
            'amount': '5.00',
        })
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        # Server must strictly charge Rs. 99.00 from DB
        self.assertEqual(res.data['amount'], '99.00')

        payment = Payment.objects.get(safepay_tracker='track_tamper_defense')
        self.assertEqual(payment.amount, Decimal('99.00'))

    # ──────────────────────────────────────────────────────────────────────────
    # SCENARIOS 12, 13, 14: Expiry & Free/Pro Independence
    # ──────────────────────────────────────────────────────────────────────────

    def test_12_automatic_promotion_expiry_sweep(self):
        payment = Payment.objects.create(
            user=self.free_user,
            amount=Decimal('99.00'),
            currency='PKR',
            purpose='featured_listing',
            status='completed',
        )
        # Campaign that expired yesterday
        yesterday = timezone.now() - timedelta(days=1)
        camp = FeaturedListingCampaign.objects.create(
            professional=self.free_profile,
            category=self.cat_electrician,
            package=self.pkg_7d,
            duration_days=7,
            payment=payment,
            start_date=yesterday - timedelta(days=7),
            end_date=yesterday,
            is_active=True,
        )

        self.assertFalse(camp.is_currently_running())

        # Run sweep
        swept = sweep_expired_campaigns()
        self.assertGreaterEqual(swept, 1)

        camp.refresh_from_db()
        self.assertFalse(camp.is_active)

        # Audit log verification
        audit = CampaignAuditLog.objects.filter(campaign=camp, action='expired').first()
        self.assertIsNotNone(audit)
        self.assertEqual(audit.new_state, 'expired')

    @patch('apps.payments.safepay.SafepayGateway.create_order')
    @patch('apps.payments.safepay.SafepayGateway.create_passport_token')
    def test_13_free_professional_can_purchase_featured_promotion(self, mock_passport, mock_order):
        mock_order.return_value = {'tracker': 'track_free_pro_featured'}
        mock_passport.return_value = 'v1_token'

        self.client.force_authenticate(user=self.free_user)
        res = self.client.post('/api/payments/checkout/initialize/', {
            'purpose': 'featured_listing',
            'package_id': self.pkg_7d.id,
            'category_id': self.cat_electrician.id,
        })
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data['amount'], '99.00')

    @patch('apps.payments.safepay.SafepayGateway.create_order')
    @patch('apps.payments.safepay.SafepayGateway.create_passport_token')
    def test_14_pro_professional_can_purchase_featured_promotion(self, mock_passport, mock_order):
        mock_order.return_value = {'tracker': 'track_pro_pro_featured'}
        mock_passport.return_value = 'v1_token'

        self.client.force_authenticate(user=self.pro_user)
        res = self.client.post('/api/payments/checkout/initialize/', {
            'purpose': 'featured_listing',
            'package_id': self.pkg_30d.id,
            'category_id': self.cat_electrician.id,
        })
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data['amount'], '349.00')

    # ──────────────────────────────────────────────────────────────────────────
    # SCENARIO 15: Search Integration & Strict Relevance Verification
    # ──────────────────────────────────────────────────────────────────────────

    def test_15_featured_professional_strict_category_relevance_in_search(self):
        # Activate featured campaign for Ali (Electrician)
        payment = Payment.objects.create(
            user=self.free_user,
            amount=Decimal('99.00'),
            currency='PKR',
            purpose='featured_listing',
            status='completed',
        )
        now = timezone.now()
        FeaturedListingCampaign.objects.create(
            professional=self.free_profile,
            category=self.cat_electrician,
            package=self.pkg_7d,
            duration_days=7,
            payment=payment,
            start_date=now - timedelta(hours=1),
            end_date=now + timedelta(days=6, hours=23),
            is_active=True,
        )

        # 1. Searching "Electrician" in Normal Search should return Ali with is_featured=True
        res_elec = self.client.get('/api/search/?q=Electrician')
        self.assertEqual(res_elec.status_code, status.HTTP_200_OK)
        results = res_elec.data.get('results', [])
        ali_match = next((r for r in results if r['id'] == str(self.free_user.id)), None)
        self.assertIsNotNone(ali_match, "Ali Electrician should appear in Electrician search")
        self.assertTrue(ali_match['is_featured'], "Ali should have is_featured=True")

        # 2. Searching "Doctor" in Normal Search must NEVER return Ali even though he is featured!
        res_doc = self.client.get('/api/search/?q=Doctor')
        self.assertEqual(res_doc.status_code, status.HTTP_200_OK)
        doc_results = res_doc.data.get('results', [])
        ali_in_doc = next((r for r in doc_results if r['id'] == str(self.free_user.id)), None)
        self.assertIsNone(ali_in_doc, "Electrician MUST NOT appear in Doctor search results under any circumstance")
