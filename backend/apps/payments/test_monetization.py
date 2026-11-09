# apps/payments/test_monetization.py

from decimal import Decimal
from datetime import timedelta
from django.test import TestCase
from django.utils import timezone
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status

from apps.payments.safepay import SafepayGateway, pkr_to_paisas, paisas_to_pkr
from apps.payments.models import Payment, WebhookEventLog, CacheInvalidationOutbox
from apps.subscriptions.models import (
    SubscriptionPlan,
    PlanFeature,
    Subscription,
    FeaturedPromotionPackage,
    FeaturedListingCampaign,
    CampaignAuditLog,
)
from apps.profiles.models import (
    UserProfile,
    ProfessionalProfile,
    GalleryImage,
    ProfessionalSecondaryCategory,
    StagedMedia,
)
from apps.admin_panel.models import DisplayAdCampaign
from apps.search.models import Category

User = get_user_model()


class MonetizationComprehensiveTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()

        # Seed Categories
        self.category_ac = Category.objects.create(name='AC Technician', slug='ac-technician')
        self.category_plumber = Category.objects.create(name='Plumber', slug='plumber')
        self.category_electrician = Category.objects.create(name='Electrician', slug='electrician')

        # Seed Plans
        self.plan_free = SubscriptionPlan.objects.create(
            name='Free',
            plan_type='professional',
            billing='free',
            price=Decimal('0.00'),
            currency='PKR',
            duration_days=0,
            is_active=True,
        )
        self.plan_pro_monthly = SubscriptionPlan.objects.create(
            name='Pro Monthly',
            plan_type='professional',
            billing='monthly',
            price=Decimal('499.00'),
            currency='PKR',
            duration_days=30,
            is_active=True,
        )
        self.plan_pro_yearly = SubscriptionPlan.objects.create(
            name='Pro Yearly',
            plan_type='professional',
            billing='yearly',
            price=Decimal('4999.00'),
            currency='PKR',
            duration_days=365,
            is_active=True,
        )

        # Seed Featured Packages
        self.pkg_7d = FeaturedPromotionPackage.objects.create(
            name='Featured 7 Days',
            duration_days=7,
            price=Decimal('99.00'),
            currency='PKR',
            is_active=True,
        )
        self.pkg_15d = FeaturedPromotionPackage.objects.create(
            name='Featured 15 Days',
            duration_days=15,
            price=Decimal('199.00'),
            currency='PKR',
            is_active=True,
        )
        self.pkg_30d = FeaturedPromotionPackage.objects.create(
            name='Featured 30 Days',
            duration_days=30,
            price=Decimal('349.00'),
            currency='PKR',
            is_active=True,
        )

        # Users
        self.pro_user = User.objects.create_user(
            email='pro_test@example.com',
            password='password123',
            name='Ahmed Khan',
            role='professional',
        )
        self.pro_profile = ProfessionalProfile.objects.create(
            user=self.pro_user,
            category=self.category_ac,
            bio='Expert AC Technician in Lahore',
            hourly_rate=Decimal('1500.00'),
            is_verified=True,
            average_rating=Decimal('4.9'),
        )
        self.pro_user_profile = UserProfile.objects.create(
            user=self.pro_user,
            full_name='Ahmed Khan',
            city='Lahore',
            country='Pakistan',
        )

    # ── 1. Decimal & Paisas Conversion ─────────────────────────────────────────

    def test_paisas_conversion_precision(self):
        self.assertEqual(pkr_to_paisas(Decimal('499.00')), 49900)
        self.assertEqual(pkr_to_paisas(Decimal('4999.00')), 499900)
        self.assertEqual(pkr_to_paisas(Decimal('99.00')), 9900)
        self.assertEqual(pkr_to_paisas(Decimal('199.00')), 19900)
        self.assertEqual(pkr_to_paisas(Decimal('349.00')), 34900)
        self.assertEqual(paisas_to_pkr(49900), Decimal('499.00'))
        self.assertEqual(paisas_to_pkr(9900), Decimal('99.00'))

    # ── 2. Safepay Checkout Initialization ────────────────────────────────────

    def test_pro_subscription_checkout_initialize(self):
        self.client.force_authenticate(user=self.pro_user)
        payload = {
            'purpose': 'subscription',
            'plan_id': self.plan_pro_monthly.id,
            'redirect_url': 'profinder://payment-success',
            'cancel_url': 'profinder://payment-cancel',
        }
        resp = self.client.post('/api/payments/checkout/initialize/', payload, format='json')
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(resp.data['amount'], '499.00')
        self.assertEqual(resp.data['currency'], 'PKR')
        self.assertTrue(resp.data['safepay_tracker'].startswith('track_'))
        self.assertIn('beacon=', resp.data['checkout_url'])

        # Verify DB Payment row
        payment = Payment.objects.get(safepay_tracker=resp.data['safepay_tracker'])
        self.assertEqual(payment.amount, Decimal('499.00'))
        self.assertEqual(payment.status, 'pending')
        self.assertEqual(payment.purpose, 'subscription')

    def test_safepay_initialize_with_raast_and_card_payment_methods(self):
        self.client.force_authenticate(user=self.pro_user)

        # 1. Raast Instant Pay
        raast_payload = {
            'purpose': 'subscription',
            'plan_id': self.plan_pro_monthly.id,
            'payment_method': 'raast',
        }
        res_raast = self.client.post('/api/payments/checkout/initialize/', raast_payload, format='json')
        self.assertEqual(res_raast.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res_raast.data['payment_method'], 'raast')
        self.assertIn('components', res_raast.data['checkout_url'])
        self.assertEqual(len(res_raast.data['supported_methods']), 3)

        # 2. Card Payment
        card_payload = {
            'purpose': 'subscription',
            'plan_id': self.plan_pro_monthly.id,
            'payment_method': 'card',
        }
        res_card = self.client.post('/api/payments/checkout/initialize/', card_payload, format='json')
        self.assertEqual(res_card.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res_card.data['payment_method'], 'card')
        self.assertIn('components', res_card.data['checkout_url'])

    def test_featured_promotion_checkout_initialize(self):
        self.client.force_authenticate(user=self.pro_user)
        payload = {
            'purpose': 'featured_listing',
            'package_id': self.pkg_7d.id,
            'category_id': self.category_ac.id,
        }
        resp = self.client.post('/api/payments/checkout/initialize/', payload, format='json')
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(resp.data['amount'], '99.00')
        self.assertEqual(resp.data['duration_days'], 7)

        # Verify Campaign created as inactive pending payment
        campaign = FeaturedListingCampaign.objects.get(payment__safepay_tracker=resp.data['safepay_tracker'])
        self.assertFalse(campaign.is_active)
        self.assertEqual(campaign.duration_days, 7)

    # ── 3. Reporter API Status Verification & Entitlement Grant ──────────────

    def test_safepay_verify_and_fulfill_subscription(self):
        self.client.force_authenticate(user=self.pro_user)
        # Create pending payment
        payment = Payment.objects.create(
            user=self.pro_user,
            amount=Decimal('499.00'),
            currency='PKR',
            purpose='subscription',
            subscription_plan=self.plan_pro_monthly,
            gateway='safepay',
            safepay_tracker='track_mock_verify123',
            status='pending',
        )

        resp = self.client.get(f'/api/payments/verify-status/?order_id={payment.order_id}')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['status'], 'completed')

        # Check subscription was activated
        payment.refresh_from_db()
        self.assertEqual(payment.status, 'completed')
        self.assertIsNotNone(payment.updated_at)

        sub = Subscription.objects.filter(user=self.pro_user, status='active').first()
        self.assertIsNotNone(sub)
        self.assertEqual(sub.plan, self.plan_pro_monthly)
        self.assertTrue(sub.is_valid())

    def test_safepay_verify_and_fulfill_featured_campaign(self):
        self.client.force_authenticate(user=self.pro_user)
        payment = Payment.objects.create(
            user=self.pro_user,
            amount=Decimal('99.00'),
            currency='PKR',
            purpose='featured_listing',
            gateway='safepay',
            safepay_tracker='track_mock_feat123',
            status='pending',
        )
        campaign = FeaturedListingCampaign.objects.create(
            professional=self.pro_profile,
            category=self.category_ac,
            package=self.pkg_7d,
            duration_days=7,
            payment=payment,
            is_active=False,
        )

        resp = self.client.get(f'/api/payments/verify-status/?order_id={payment.order_id}')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['status'], 'completed')

        campaign.refresh_from_db()
        self.assertTrue(campaign.is_active)
        self.assertTrue(campaign.is_currently_running())
        self.assertIsNotNone(campaign.start_date)
        self.assertIsNotNone(campaign.end_date)

        # Check Audit Log was recorded
        audit = CampaignAuditLog.objects.filter(campaign=campaign).first()
        self.assertIsNotNone(audit)
        self.assertEqual(audit.action, 'activated')

    # ── 4. Webhook Ingestion & Tampering Protection ───────────────────────────

    def test_webhook_invalid_signature_tampering(self):
        payload = b'{"id": "evt_tampered_1", "data": {"token": "track_test"}}'
        resp = self.client.post(
            '/api/payments/webhook/safepay/',
            data=payload,
            content_type='application/json',
            HTTP_X_SFPY_SIGNATURE='bad_invalid_signature',
        )
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        # Check tampering logged in WebhookEventLog
        log_entry = WebhookEventLog.objects.filter(event_id='evt_tampered_1').first()
        self.assertIsNotNone(log_entry)
        self.assertEqual(log_entry.status, 'payload_tampering_conflict')

    def test_webhook_valid_signature_and_deduplication(self):
        import hmac
        import hashlib
        from django.conf import settings

        payment = Payment.objects.create(
            user=self.pro_user,
            amount=Decimal('499.00'),
            currency='PKR',
            purpose='subscription',
            subscription_plan=self.plan_pro_monthly,
            gateway='safepay',
            safepay_tracker='track_mock_hook456',
            status='pending',
        )

        payload = b'{"id": "evt_safepay_unique_101", "data": {"token": "track_mock_hook456"}}'
        secret = getattr(settings, 'SAFEPAY_WEBHOOK_SECRET', '')
        valid_signature = hmac.new(secret.encode('utf-8'), payload, hashlib.sha256).hexdigest()

        resp1 = self.client.post(
            '/api/payments/webhook/safepay/',
            data=payload,
            content_type='application/json',
            HTTP_X_SFPY_SIGNATURE=valid_signature,
        )
        self.assertEqual(resp1.status_code, status.HTTP_200_OK)

        # Second delivery (duplicate replay)
        resp2 = self.client.post(
            '/api/payments/webhook/safepay/',
            data=payload,
            content_type='application/json',
            HTTP_X_SFPY_SIGNATURE=valid_signature,
        )
        self.assertEqual(resp2.status_code, status.HTTP_200_OK)
        self.assertEqual(resp2.data['status'], 'duplicate_ignored')

    # ── 5. Gallery Quota Enforcement (10 Free vs 30 Pro) ─────────────────────

    def test_gallery_quota_free_user_enforced(self):
        self.client.force_authenticate(user=self.pro_user)
        # Free professional: currently has 0 active Pro subscription
        # Prepopulate 10 images
        for i in range(10):
            GalleryImage.objects.create(
                professional=self.pro_user,
                image=f'http://example.com/photo_{i}.jpg'
            )

        # Attempt to upload 11th image via Stage endpoint
        stage_resp = self.client.post('/api/profiles/gallery/stage/')
        self.assertEqual(stage_resp.status_code, status.HTTP_403_FORBIDDEN)
        self.assertEqual(stage_resp.data['error'], 'gallery_quota_exceeded')
        self.assertEqual(stage_resp.data['limit'], 10)

    def test_gallery_quota_pro_user_allows_up_to_30(self):
        self.client.force_authenticate(user=self.pro_user)
        # Activate Pro subscription
        Subscription.objects.create(
            user=self.pro_user,
            plan=self.plan_pro_monthly,
            status='active',
            end_date=timezone.now() + timedelta(days=30),
        )

        # Prepopulate 10 images
        for i in range(10):
            GalleryImage.objects.create(
                professional=self.pro_user,
                image=f'http://example.com/photo_{i}.jpg'
            )

        # 11th image staging should SUCCEED for Pro user!
        stage_resp = self.client.post('/api/profiles/gallery/stage/')
        self.assertEqual(stage_resp.status_code, status.HTTP_201_CREATED)
        self.assertIn('public_id', stage_resp.data)

        # Commit staged image
        commit_resp = self.client.post('/api/profiles/gallery/commit/', {
            'public_id': stage_resp.data['public_id'],
            'upload_lease_token': stage_resp.data['upload_lease_token'],
            'image_url': 'http://example.com/photo_11.jpg',
        })
        self.assertEqual(commit_resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(GalleryImage.objects.filter(professional=self.pro_user).count(), 11)

    # ── 6. Secondary Category Limit (0 Free vs Max 2 Pro) ────────────────────

    def test_secondary_category_free_user_blocked(self):
        self.client.force_authenticate(user=self.pro_user)
        # Free user attempting to add secondary category
        resp = self.client.post('/api/profiles/secondary-categories/', {'category': self.category_plumber.id})
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)
        self.assertEqual(resp.data['error'], 'pro_required')

    def test_secondary_category_pro_user_allows_max_2(self):
        self.client.force_authenticate(user=self.pro_user)
        # Activate Pro subscription
        Subscription.objects.create(
            user=self.pro_user,
            plan=self.plan_pro_monthly,
            status='active',
            end_date=timezone.now() + timedelta(days=30),
        )

        # Add 1st secondary category (Plumber) -> Success
        resp1 = self.client.post('/api/profiles/secondary-categories/', {'category': self.category_plumber.id})
        self.assertEqual(resp1.status_code, status.HTTP_201_CREATED)

        # Add 2nd secondary category (Electrician) -> Success
        resp2 = self.client.post('/api/profiles/secondary-categories/', {'category': self.category_electrician.id})
        self.assertEqual(resp2.status_code, status.HTTP_201_CREATED)

        # Add 3rd secondary category -> Blocked by max 2 limit
        cat_carpenter = Category.objects.create(name='Carpenter', slug='carpenter')
        resp3 = self.client.post('/api/profiles/secondary-categories/', {'category': cat_carpenter.id})
        self.assertEqual(resp3.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(resp3.data['error'], 'limit_reached')

    # ── 7. Display Ad Serving and Impression/Click Tracking ──────────────────

    def test_display_ad_serve_and_track_clicks(self):
        now = timezone.now()
        ad = DisplayAdCampaign.objects.create(
            title='Orient DC Inverter Sale',
            advertiser_name='Orient Electronics',
            contact_phone_or_whatsapp='03001234567',
            placement_slot='homepage_masthead',
            desktop_banner_url='https://example.com/orient_desktop.jpg',
            mobile_banner_url='https://example.com/orient_mobile.jpg',
            destination_url='https://orient.com.pk/inverters',
            alt_text='Orient DC Inverter 50% Off',
            payment_verified_by_admin=True,
            is_approved=True,
            is_active=True,
            start_datetime=now - timedelta(days=1),
            end_datetime=now + timedelta(days=10),
        )

        # Public ad serve
        resp = self.client.get('/api/admin-panel/ads/serve/?placement=homepage_masthead')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertIsNotNone(resp.data['ad'])
        self.assertEqual(resp.data['ad']['id'], ad.id)

        # Verify impression was atomically incremented
        ad.refresh_from_db()
        self.assertEqual(ad.raw_impressions_count, 1)

        # Track click
        click_resp = self.client.post(f'/api/admin-panel/ads/{ad.id}/click/')
        self.assertEqual(click_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(click_resp.data['destination_url'], 'https://orient.com.pk/inverters')

        ad.refresh_from_db()
        self.assertEqual(ad.raw_clicks_count, 1)
