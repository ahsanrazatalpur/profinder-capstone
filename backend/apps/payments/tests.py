# apps/payments/tests.py

from decimal import Decimal
from datetime import date, time
from django.test import TestCase
from django.core.management import call_command
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status

from apps.payments.models import Payment, WalletTransaction, WithdrawalRequest, ExchangeRateCache
from apps.payments.exchange import (
    convert_currency,
    format_currency_amount,
    get_exchange_rate,
    refresh_exchange_rates,
)
from apps.payments import paypal
from apps.bookings.models import Booking
from apps.profiles.models import ProfessionalProfile
from apps.search.models import Category
from apps.subscriptions.models import SubscriptionPlan, Subscription

User = get_user_model()


class PaymentSystemTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()

        # Create Category
        self.category = Category.objects.create(name='Electrician')

        # Customer User
        self.customer = User.objects.create_user(
            email='customer@example.com',
            password='password123',
            name='Customer User',
            role='customer',
        )

        # Professional User
        self.pro_user = User.objects.create_user(
            email='pro@example.com',
            password='password123',
            name='Pro Electrician',
            role='professional',
        )
        self.pro_profile = ProfessionalProfile.objects.create(
            user=self.pro_user,
            category=self.category,
            hourly_rate=50.00,
            bank_account_name='Pro Electrician',
            bank_account_number='PK1234567890',
            bank_name='Standard Chartered',
        )

        # Admin User
        self.admin_user = User.objects.create_superuser(
            email='admin@example.com',
            password='adminpassword',
            name='Admin User',
            role='admin',
        )

        # Subscription Plans
        self.free_plan = SubscriptionPlan.objects.create(
            name='Free Starter',
            plan_type='customer',
            billing='free',
            price=Decimal('0.00'),
            currency='USD',
            duration_days=0,
            is_active=True,
        )
        self.paid_plan = SubscriptionPlan.objects.create(
            name='Pro Monthly',
            plan_type='professional',
            billing='monthly',
            price=Decimal('29.00'),
            currency='USD',
            duration_days=30,
            is_active=True,
        )

        # A sample booking
        self.booking = Booking.objects.create(
            customer=self.customer,
            professional=self.pro_user,
            date=date.today(),
            time=time(14, 0),
            note='Need home wiring fixed',
            status='accepted',
            total_price=Decimal('50.00'),
            currency='USD',
            payment_status='unpaid',
        )

    # ─── 1. Exchange Rate Tests ───────────────────────────────────────────────

    def test_exchange_rate_calculations(self):
        # Base conversion: USD to USD must be 1.0
        rate = get_exchange_rate('USD', 'USD')
        self.assertEqual(rate, Decimal('1.0'))

        # Convert 100 USD to PKR using fallback / cache
        converted, rate = convert_currency(Decimal('100.00'), 'USD', 'PKR')
        self.assertGreater(converted, Decimal('1000.00'))
        self.assertGreater(rate, Decimal('10.0'))

        # Format currency amounts
        formatted_usd = format_currency_amount(Decimal('49.99'), 'USD')
        self.assertEqual(formatted_usd, '$ 49.99')

        formatted_pkr = format_currency_amount(Decimal('15000'), 'PKR')
        self.assertTrue('15,000' in formatted_pkr)

    # ─── 2. PayPal Client Helper Tests ────────────────────────────────────────

    def test_paypal_mock_flow(self):
        # Order creation
        order = paypal.create_order(
            amount=Decimal('50.00'),
            currency='USD',
            custom_id='TEST-1',
            description='Test Booking',
        )
        self.assertTrue(order['id'].startswith('MOCK-PAYPAL-'))
        self.assertIn('token=', order['approval_url'])

        # Order capture
        capture = paypal.capture_order(order['id'])
        self.assertEqual(capture['status'], 'COMPLETED')
        self.assertTrue(capture['capture_id'].startswith('MOCK-CAP-'))

        # Webhook signature validation fallback
        valid = paypal.verify_webhook_signature({}, {})
        self.assertTrue(valid)

    # ─── 3. Booking Payment Flow ──────────────────────────────────────────────

    def test_create_and_capture_booking_payment(self):
        self.client.force_authenticate(user=self.customer)

        # 1. Create checkout order
        res = self.client.post('/api/payments/booking/create/', {
            'booking_id': self.booking.id,
            'currency': 'USD',
        })
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertIn('approval_url', res.data)
        self.assertIn('order_id', res.data)
        self.assertEqual(res.data['amount'], '50.00')

        payment_order_id = res.data['order_id']
        paypal_id = res.data['paypal_order_id']

        # Verify booking status became 'pending'
        self.booking.refresh_from_db()
        self.assertEqual(self.booking.payment_status, 'pending')

        # 2. Capture payment
        cap_res = self.client.post('/api/payments/capture/', {
            'order_id': payment_order_id,
            'paypal_order_id': paypal_id,
        })
        self.assertEqual(cap_res.status_code, status.HTTP_200_OK)
        self.assertEqual(cap_res.data['status'], 'completed')

        # Verify booking is now marked paid
        self.booking.refresh_from_db()
        self.assertEqual(self.booking.payment_status, 'paid')

        # 3. Idempotent second capture should succeed without error
        cap_res_dup = self.client.post('/api/payments/capture/', {
            'order_id': payment_order_id,
        })
        self.assertEqual(cap_res_dup.status_code, status.HTTP_200_OK)
        self.assertEqual(cap_res_dup.data['status'], 'completed')

    def test_booking_payment_ownership_validation(self):
        # Another user cannot pay for someone else's booking
        other_user = User.objects.create_user(
            email='other@example.com', password='password', name='Other', role='customer'
        )
        self.client.force_authenticate(user=other_user)

        res = self.client.post('/api/payments/booking/create/', {
            'booking_id': self.booking.id,
        })
        self.assertEqual(res.status_code, status.HTTP_404_NOT_FOUND)

    def test_capture_payment_idor_prevention(self):
        # Customer creates checkout order
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/payments/booking/create/', {
            'booking_id': self.booking.id,
            'currency': 'USD',
        })
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        order_id = res.data['order_id']
        paypal_id = res.data['paypal_order_id']

        # An attacker user attempts to capture customer's payment order
        attacker = User.objects.create_user(
            email='attacker@example.com', password='password123', name='Attacker', role='customer'
        )
        self.client.force_authenticate(user=attacker)
        capture_attempt = self.client.post('/api/payments/capture/', {
            'order_id': order_id,
            'paypal_order_id': paypal_id,
        })
        self.assertEqual(capture_attempt.status_code, status.HTTP_403_FORBIDDEN)
        self.assertIn('not authorized', capture_attempt.data.get('error', '').lower())

    def test_capture_payment_invalid_state_rejection(self):
        # Payment in failed status cannot be captured
        payment = Payment.objects.create(
            user=self.customer,
            amount=Decimal('50.00'),
            currency='USD',
            purpose='booking',
            booking=self.booking,
            status='failed',
            paypal_order_id='MOCK-FAILED-1',
        )
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/payments/capture/', {
            'order_id': payment.order_id,
        })
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('cannot be captured', res.data.get('error', ''))

    # ─── 4. Subscription Payment Flow ─────────────────────────────────────────

    def test_free_subscription_activates_immediately(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/payments/subscription/create/', {
            'plan_id': self.free_plan.id,
        })
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(res.data.get('is_free'))

        # Verify active subscription created in DB
        active_sub = Subscription.objects.filter(user=self.customer, status='active').first()
        self.assertIsNotNone(active_sub)
        self.assertEqual(active_sub.plan, self.free_plan)

    def test_paid_subscription_requires_payment(self):
        self.client.force_authenticate(user=self.pro_user)

        # Direct legacy activation must be blocked (HTTP 402)
        direct_res = self.client.post('/api/subscriptions/', {'plan': self.paid_plan.id})
        self.assertEqual(direct_res.status_code, status.HTTP_402_PAYMENT_REQUIRED)

        # Proper checkout flow
        res = self.client.post('/api/payments/subscription/create/', {
            'plan_id': self.paid_plan.id,
            'currency': 'USD',
        })
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertIn('approval_url', res.data)

        # Capture paid subscription
        cap_res = self.client.post('/api/payments/capture/', {
            'order_id': res.data['order_id'],
            'paypal_order_id': res.data['paypal_order_id'],
        })
        self.assertEqual(cap_res.status_code, status.HTTP_200_OK)

        active_sub = Subscription.objects.filter(user=self.pro_user, status='active').first()
        self.assertIsNotNone(active_sub)
        self.assertEqual(active_sub.plan, self.paid_plan)

    # ─── 5. Professional Financial Ledger & Wallet ────────────────────────────

    def test_wallet_ledger_and_withdrawals(self):
        # Initially, wallet balance should be 0.0
        self.client.force_authenticate(user=self.pro_user)
        wallet_res = self.client.get('/api/payments/wallet/')
        self.assertEqual(wallet_res.status_code, status.HTTP_200_OK)
        self.assertEqual(wallet_res.data['available_balance'], 0.0)

        # Credit professional with $100 via completed jobs in ledger
        WalletTransaction.objects.create(
            user=self.pro_user,
            transaction_type='credit',
            amount=Decimal('100.00'),
            currency='USD',
            status='completed',
            description='Completed booking job',
        )

        wallet_res = self.client.get('/api/payments/wallet/')
        self.assertEqual(wallet_res.data['available_balance'], 100.0)
        self.assertEqual(wallet_res.data['total_earned'], 100.0)

        # Attempt withdrawal below minimum ($20) -> must fail
        bad_req = self.client.post('/api/payments/withdrawals/', {'amount': 10})
        self.assertEqual(bad_req.status_code, status.HTTP_400_BAD_REQUEST)

        # Attempt withdrawal exceeding available balance -> must fail
        exceed_req = self.client.post('/api/payments/withdrawals/', {'amount': 150})
        self.assertEqual(exceed_req.status_code, status.HTTP_400_BAD_REQUEST)

        # Successful Bank withdrawal request of $40
        good_req = self.client.post('/api/payments/withdrawals/', {
            'amount': 40,
            'payout_method': 'bank_transfer',
        })
        self.assertEqual(good_req.status_code, status.HTTP_201_CREATED)

        # Available balance is now $100 - $40 (pending) = $60
        wallet_res2 = self.client.get('/api/payments/wallet/')
        self.assertEqual(wallet_res2.data['available_balance'], 60.0)
        self.assertEqual(wallet_res2.data['pending_withdrawal'], 40.0)

        # Successful PayPal withdrawal of $30
        paypal_req = self.client.post('/api/payments/withdrawals/', {
            'amount': 30,
            'payout_method': 'paypal',
            'paypal_email': 'pro@paypal.com',
        })
        self.assertEqual(paypal_req.status_code, status.HTTP_201_CREATED)

        # Available balance is now $100 - $40 - $30 = $30
        wallet_res3 = self.client.get('/api/payments/wallet/')
        self.assertEqual(wallet_res3.data['available_balance'], 30.0)

    # ─── 6. Admin Refund & Ledger Reversal ────────────────────────────────────

    def test_admin_refund_and_ledger_reversal(self):
        # Create completed payment for booking
        payment = Payment.objects.create(
            user=self.customer,
            amount=Decimal('50.00'),
            currency='USD',
            purpose='booking',
            booking=self.booking,
            status='completed',
            paypal_capture_id='MOCK-CAP-REF123',
        )
        self.booking.payment_status = 'paid'
        self.booking.status = 'completed'
        self.booking.save()

        # Professional received credit on completion
        WalletTransaction.objects.create(
            user=self.pro_user,
            transaction_type='credit',
            amount=Decimal('50.00'),
            currency='USD',
            status='completed',
            booking=self.booking,
            payment=payment,
            description='Booking completed earnings',
        )

        self.client.force_authenticate(user=self.admin_user)
        ref_res = self.client.patch(f'/api/admin-panel/payments/{payment.id}/refund/', {
            'reason': 'Customer dissatisfaction resolved by dispute',
        })
        self.assertEqual(ref_res.status_code, status.HTTP_200_OK)

        # Verify payment and booking updated to refunded
        payment.refresh_from_db()
        self.assertEqual(payment.status, 'refunded')
        self.booking.refresh_from_db()
        self.assertEqual(self.booking.payment_status, 'refunded')

        # Verify refund debit transaction was created in ledger
        refund_tx = WalletTransaction.objects.filter(
            booking=self.booking, transaction_type='refund'
        ).first()
        self.assertIsNotNone(refund_tx)
        self.assertEqual(refund_tx.amount, Decimal('50.00'))

    # ─── 7. Management Command ────────────────────────────────────────────────

    def test_reconcile_payments_command(self):
        call_command('reconcile_payments', '--dry-run')
