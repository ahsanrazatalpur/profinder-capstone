# apps/payments/views.py

import logging
from decimal import Decimal
from datetime import timedelta
from django.utils import timezone
from django.db import transaction
from django.db.models import Sum, Q
from django.conf import settings
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.contrib.auth import get_user_model

User = get_user_model()

from apps.payments.models import Payment, WithdrawalRequest, WalletTransaction, ExchangeRateCache
from apps.payments.serializers import (
    PaymentSerializer,
    WithdrawalRequestSerializer,
    WalletTransactionSerializer,
    ExchangeRateCacheSerializer,
)
from apps.payments import paypal
from apps.payments.exchange import (
    get_base_currency,
    convert_currency,
    format_currency_amount,
    SUPPORTED_CURRENCIES,
    COUNTRY_CURRENCY_MAP,
    refresh_exchange_rates,
)
from apps.notifications.utils import notify_user

logger = logging.getLogger(__name__)

MIN_WITHDRAWAL_AMOUNT = getattr(settings, 'MIN_WITHDRAWAL_AMOUNT', 20.0)


# ─── 1. Payment History & Orders ──────────────────────────────────────────────

class PaymentView(APIView):
    """
    GET /api/payments/
    Lists current user's payment history.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        payments = Payment.objects.filter(user=request.user).order_by('-created_at')
        serializer = PaymentSerializer(payments, many=True)
        return Response(serializer.data)


# ─── 2. Create Booking Checkout ───────────────────────────────────────────────

class CreateBookingPaymentView(APIView):
    """
    POST /api/payments/booking/create/
    Disabled: ProFinder is a discovery and inquiry marketplace.
    Direct dealings and offline payments only.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        return Response({
            'error': 'service_payments_disabled',
            'message': 'ProFinder is a discovery and service inquiry marketplace. We do not process payments for professional services. Customers and professionals agree upon terms and settle payments directly without platform fees or escrow.'
        }, status=status.HTTP_400_BAD_REQUEST)

    def _disabled_post(self, request):
        from apps.bookings.models import Booking

        booking_id = request.data.get('booking_id')
        display_curr = (request.data.get('currency') or 'USD').upper()
        return_url = request.data.get('return_url') or ''
        cancel_url = request.data.get('cancel_url') or ''

        if not booking_id:
            return Response({'error': 'booking_id is required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            booking = Booking.objects.get(id=booking_id, customer=request.user)
        except Booking.DoesNotExist:
            return Response({'error': 'Booking not found or not owned by user.'}, status=status.HTTP_404_NOT_FOUND)

        if booking.payment_status == 'paid':
            return Response({'error': 'This booking has already been paid for.'}, status=status.HTTP_400_BAD_REQUEST)

        # Authoritative server-side price check
        amount_usd = booking.total_price
        if not amount_usd or amount_usd <= Decimal('0.00'):
            # If booking price was unset, snapshot from professional hourly rate
            prof_profile = getattr(booking.professional, 'professionalprofile', None)
            amount_usd = Decimal(str(prof_profile.hourly_rate if prof_profile and prof_profile.hourly_rate else 10.0))
            booking.total_price = amount_usd
            booking.save(update_fields=['total_price'])

        # Calculate local currency display
        local_amount, rate = convert_currency(amount_usd, from_currency='USD', to_currency=display_curr)

        # Create PayPal Order
        settlement_curr = get_base_currency()
        try:
            order_data = paypal.create_order(
                amount=amount_usd,
                currency=settlement_curr,
                return_url=return_url,
                cancel_url=cancel_url,
                custom_id=f"BKG-{booking.id}",
                description=f"ProFinder Booking - {booking.professional.name}",
            )
        except Exception as exc:
            logger.error("PayPal order creation failed: %s", exc)
            return Response({'error': f'Failed to create checkout order: {exc}'}, status=status.HTTP_502_BAD_GATEWAY)

        # Persist payment record
        payment = Payment.objects.create(
            user=request.user,
            amount=amount_usd,
            currency=settlement_curr,
            purpose='booking',
            booking=booking,
            gateway='paypal',
            paypal_order_id=order_data.get('id', ''),
            approval_url=order_data.get('approval_url', ''),
            local_amount=local_amount,
            local_currency=display_curr,
            exchange_rate=rate,
            status='pending',
        )

        booking.payment_status = 'pending'
        booking.save(update_fields=['payment_status'])

        return Response({
            'order_id': payment.order_id,
            'payment_id': payment.id,
            'paypal_order_id': payment.paypal_order_id,
            'approval_url': payment.approval_url,
            'amount': str(payment.amount),
            'currency': payment.currency,
            'local_amount': str(local_amount),
            'local_currency': display_curr,
            'display_formatted': format_currency_amount(local_amount, display_curr),
        }, status=status.HTTP_201_CREATED)


# ─── 3. Create Subscription Checkout ──────────────────────────────────────────

class CreateSubscriptionPaymentView(APIView):
    """
    POST /api/payments/subscription/create/
    Creates a server-side verified PayPal order for a subscription plan.
    Payload: { "plan_id": 2, "currency": "USD" (optional display currency) }
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        from apps.subscriptions.models import SubscriptionPlan, Subscription

        plan_id = request.data.get('plan_id')
        display_curr = (request.data.get('currency') or 'USD').upper()
        return_url = request.data.get('return_url') or ''
        cancel_url = request.data.get('cancel_url') or ''

        if not plan_id:
            return Response({'error': 'plan_id is required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            plan = SubscriptionPlan.objects.get(id=plan_id, is_active=True)
        except SubscriptionPlan.DoesNotExist:
            return Response({'error': 'Subscription plan not found or inactive.'}, status=status.HTTP_404_NOT_FOUND)

        if plan.plan_type != request.user.role:
            return Response({'error': f'This plan is for {plan.plan_type}s only.'}, status=status.HTTP_400_BAD_REQUEST)

        # Free plans activate immediately without payment
        if plan.billing == 'free' or plan.price <= Decimal('0.00'):
            with transaction.atomic():
                Subscription.objects.filter(user=request.user, status='active').update(status='cancelled')
                sub = Subscription.objects.create(
                    user=request.user,
                    plan=plan,
                    status='active',
                    end_date=None,
                )
            return Response({
                'status': 'completed',
                'is_free': True,
                'plan_name': plan.name,
                'message': f'Successfully activated {plan.name} plan.',
            }, status=status.HTTP_200_OK)

        # Convert plan price to settlement USD if needed
        plan_amount = Decimal(str(plan.price))
        amount_usd, _ = convert_currency(plan_amount, from_currency=plan.currency or 'USD', to_currency='USD')
        local_amount, rate = convert_currency(amount_usd, from_currency='USD', to_currency=display_curr)

        settlement_curr = get_base_currency()
        try:
            order_data = paypal.create_order(
                amount=amount_usd,
                currency=settlement_curr,
                return_url=return_url,
                cancel_url=cancel_url,
                custom_id=f"SUB-{plan.id}-{request.user.id}",
                description=f"ProFinder {plan.name} ({plan.billing})",
            )
        except Exception as exc:
            logger.error("PayPal order creation failed for subscription: %s", exc)
            return Response({'error': f'Failed to create checkout order: {exc}'}, status=status.HTTP_502_BAD_GATEWAY)

        payment = Payment.objects.create(
            user=request.user,
            amount=amount_usd,
            currency=settlement_curr,
            purpose='subscription',
            subscription_plan=plan,
            gateway='paypal',
            paypal_order_id=order_data.get('id', ''),
            approval_url=order_data.get('approval_url', ''),
            local_amount=local_amount,
            local_currency=display_curr,
            exchange_rate=rate,
            status='pending',
        )

        return Response({
            'order_id': payment.order_id,
            'payment_id': payment.id,
            'paypal_order_id': payment.paypal_order_id,
            'approval_url': payment.approval_url,
            'amount': str(payment.amount),
            'currency': payment.currency,
            'local_amount': str(local_amount),
            'local_currency': display_curr,
            'display_formatted': format_currency_amount(local_amount, display_curr),
        }, status=status.HTTP_201_CREATED)


# ─── 4. Capture Payment Endpoint ──────────────────────────────────────────────

class CapturePaymentView(APIView):
    """
    POST /api/payments/capture/
    Captures an approved PayPal order and fulfills the purchase.
    Payload: { "paypal_order_id": "..." } or { "order_id": "PO-..." }
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        from apps.subscriptions.models import Subscription

        paypal_order_id = request.data.get('paypal_order_id')
        order_id = request.data.get('order_id')

        payment = None
        if paypal_order_id:
            payment = Payment.objects.filter(paypal_order_id=paypal_order_id).first()
        elif order_id:
            payment = Payment.objects.filter(order_id=order_id).first()

        if not payment:
            return Response({'error': 'Payment order not found.'}, status=status.HTTP_404_NOT_FOUND)

        # Authorize: Only the payment owner (or staff admin) can capture the order
        if payment.user != request.user and not getattr(request.user, 'is_staff', False):
            return Response(
                {'error': 'You are not authorized to operate on this payment order.'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Idempotent return if already completed
        if payment.status == 'completed':
            return Response({
                'status': 'completed',
                'order_id': payment.order_id,
                'message': 'Payment already processed successfully.',
            }, status=status.HTTP_200_OK)

        # Prevent capturing failed or refunded payments
        if payment.status != 'pending':
            return Response(
                {'error': f'Payment order is in {payment.status} state and cannot be captured.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Execute PayPal capture
        try:
            capture_res = paypal.capture_order(payment.paypal_order_id)
        except Exception as exc:
            logger.error("Capture failed for payment %s: %s", payment.order_id, exc)
            payment.status = 'failed'
            payment.error_message = str(exc)
            payment.save(update_fields=['status', 'error_message', 'updated_at'])
            return Response({'error': f'Capture failed: {exc}'}, status=status.HTTP_400_BAD_REQUEST)

        # Fulfill purchase atomically
        with transaction.atomic():
            payment.status = 'completed'
            payment.paypal_capture_id = capture_res.get('capture_id', '')
            payment.paypal_payer_id = capture_res.get('payer_id', '')
            payment.paypal_payer_email = capture_res.get('payer_email', '')
            payment.save()

            if payment.purpose == 'booking' and payment.booking:
                booking = payment.booking
                booking.payment_status = 'paid'
                booking.save(update_fields=['payment_status'])

                # If booking is already completed, credit professional immediately
                if booking.status == 'completed':
                    if not WalletTransaction.objects.filter(booking=booking, transaction_type='credit').exists():
                        WalletTransaction.objects.create(
                            user=booking.professional,
                            transaction_type='credit',
                            amount=booking.total_price,
                            currency=booking.currency,
                            status='completed',
                            payment=payment,
                            booking=booking,
                            description=f"Payment received for completed service with {getattr(booking.customer, 'name', 'customer')}",
                        )

                # Send notifications
                prof_name = getattr(booking.professional, 'name', '').strip() or 'the professional'
                customer_name = getattr(payment.user, 'name', '').strip() or 'A customer'
                notify_user(
                    user=payment.user,
                    title='Payment Confirmed ✅',
                    message=f"Your payment of {payment.amount} {payment.currency} to {prof_name} was successful.",
                    notif_type='payment'
                )
                notify_user(
                    user=booking.professional,
                    title='Booking Paid 💳',
                    message=f"{customer_name} has paid {payment.amount} {payment.currency} for your service.",
                    notif_type='payment'
                )

            elif payment.purpose == 'subscription' and payment.subscription_plan:
                plan = payment.subscription_plan
                # Cancel existing active plans
                Subscription.objects.filter(user=payment.user, status='active').update(status='cancelled')

                end_date = None
                if plan.duration_days > 0:
                    end_date = timezone.now() + timedelta(days=plan.duration_days)

                sub = Subscription.objects.create(
                    user=payment.user,
                    plan=plan,
                    status='active',
                    end_date=end_date,
                )
                payment.subscription = sub
                payment.save(update_fields=['subscription'])

                notify_user(
                    user=payment.user,
                    title='Subscription Activated 🌟',
                    message=f"Your {plan.name} subscription is now active!",
                    notif_type='subscription'
                )

        return Response({
            'status': 'completed',
            'order_id': payment.order_id,
            'payment_id': payment.id,
            'capture_id': payment.paypal_capture_id,
            'message': 'Payment captured and fulfilled successfully.',
        }, status=status.HTTP_200_OK)


# ─── 5. PayPal Webhook ────────────────────────────────────────────────────────

class PayPalWebhookView(APIView):
    """
    POST /api/payments/webhook/
    Asynchronous webhook listener for PayPal events.
    Verifies signature and processes events idempotently.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        headers = {k.upper(): v for k, v in request.headers.items()}
        body = request.data

        # Verify signature
        if not paypal.verify_webhook_signature(headers, body):
            logger.warning("PayPal webhook signature verification failed.")
            return Response({'error': 'Invalid webhook signature'}, status=status.HTTP_400_BAD_REQUEST)

        event_type = body.get('event_type')
        resource = body.get('resource', {})
        logger.info("Received PayPal webhook: %s", event_type)

        if event_type == 'PAYMENT.CAPTURE.COMPLETED':
            capture_id = resource.get('id')
            custom_id = resource.get('custom_id')

            payment = Payment.objects.filter(
                Q(paypal_capture_id=capture_id) | Q(paypal_order_id=custom_id)
            ).first()

            if payment and payment.status != 'completed':
                with transaction.atomic():
                    payment.status = 'completed'
                    payment.paypal_capture_id = capture_id
                    payment.save()

                    if payment.purpose == 'booking' and payment.booking:
                        payment.booking.payment_status = 'paid'
                        payment.booking.save(update_fields=['payment_status'])

        elif event_type == 'PAYMENT.CAPTURE.REFUNDED':
            capture_id = resource.get('id')
            payment = Payment.objects.filter(paypal_capture_id=capture_id).first()
            if payment:
                payment.status = 'refunded'
                payment.save(update_fields=['status'])
                if payment.booking:
                    payment.booking.payment_status = 'refunded'
                    payment.booking.save(update_fields=['payment_status'])

        return Response({'status': 'received'}, status=status.HTTP_200_OK)


# ─── 6. Professional Wallet & Ledger ──────────────────────────────────────────

class WalletSummaryView(APIView):
    """
    GET /api/payments/wallet/
    Returns real balance and transaction history from financial ledger.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from apps.profiles.models import ProfessionalProfile
        user = request.user

        try:
            profile = ProfessionalProfile.objects.get(user=user)
        except ProfessionalProfile.DoesNotExist:
            profile = None

        # Ledger calculations:
        # Credits: completed earnings
        credits_sum = WalletTransaction.objects.filter(
            user=user,
            transaction_type='credit',
            status='completed'
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0.00')

        # Debits: completed payouts
        debits_sum = WalletTransaction.objects.filter(
            user=user,
            transaction_type='debit',
            status='completed'
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0.00')

        # Pending withdrawals
        pending_withdrawals = WithdrawalRequest.objects.filter(
            professional=user,
            status='pending'
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0.00')

        # Available balance
        available_balance = max(Decimal('0.00'), credits_sum - debits_sum - pending_withdrawals)

        # Build unified chronological history
        ledger_txs = WalletTransaction.objects.filter(user=user).order_by('-created_at')[:30]
        tx_history = []
        for tx in ledger_txs:
            tx_history.append({
                'id': tx.id,
                'type': tx.transaction_type,
                'amount': float(tx.amount),
                'currency': tx.currency,
                'status': tx.status,
                'label': tx.description,
                'date': tx.created_at.date().isoformat() if tx.created_at else None,
            })

        # Also include any pending withdrawal requests not yet represented in completed debits
        pending_reqs = WithdrawalRequest.objects.filter(professional=user, status='pending')
        for req in pending_reqs:
            tx_history.append({
                'id': f"w-{req.id}",
                'type': 'debit',
                'amount': float(req.amount),
                'currency': req.currency,
                'status': 'pending',
                'label': f"Withdrawal ({req.payout_method})",
                'date': req.requested_at.date().isoformat() if req.requested_at else None,
            })

        tx_history.sort(key=lambda x: x.get('date') or '', reverse=True)

        from apps.payments.exchange import resolve_currency_for_user
        up = getattr(user, 'userprofile', None)
        curr, sym = resolve_currency_for_user(
            country=getattr(up, 'country', None),
            city=getattr(up, 'city', None)
        )

        return Response({
            'available_balance': 0.0,
            'total_earned': 0.0,
            'total_withdrawn': 0.0,
            'pending_withdrawal': 0.0,
            'min_withdrawal': 0.0,
            'bank_on_file': bool(profile and profile.bank_account_number),
            'transactions': [],
            'currency': curr,
            'currency_symbol': sym,
            'is_direct_payment_model': True,
            'notice': 'ProFinder operates on a direct dealing model. All payments for services are settled directly between clients and professionals outside the app.',
        })


# ─── 7. Withdrawal Request ───────────────────────────────────────────────────

class WithdrawalRequestView(APIView):
    """
    GET  /api/payments/withdrawals/
    POST /api/payments/withdrawals/
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        withdrawals = WithdrawalRequest.objects.filter(professional=request.user).order_by('-requested_at')
        return Response(WithdrawalRequestSerializer(withdrawals, many=True).data)

    def post(self, request):
        return Response({
            'error': 'withdrawals_not_applicable',
            'message': 'ProFinder does not hold funds or deduct commissions from professional service fees. Service payments are received directly by professionals.'
        }, status=status.HTTP_400_BAD_REQUEST)

    def _disabled_post(self, request):
        from apps.profiles.models import ProfessionalProfile

        try:
            profile = ProfessionalProfile.objects.get(user=request.user)
        except ProfessionalProfile.DoesNotExist:
            return Response({'error': 'Complete your professional profile first.'}, status=status.HTTP_400_BAD_REQUEST)

        payout_method = request.data.get('payout_method', 'bank_transfer')
        paypal_email = (request.data.get('paypal_email') or '').strip()

        return Response({
            'error': 'ProFinder operates on a 100% direct client settlement model (Cash, Raast, Direct Bank Transfer). ProFinder charges 0% commission on service jobs and does not process payouts or withdrawals.'
        }, status=status.HTTP_400_BAD_REQUEST)

        # Legacy logic disabled under Direct Settlement Business Model
        if payout_method == 'paypal' and not paypal_email:
            return Response({'error': 'PayPal payout email is required.'}, status=status.HTTP_400_BAD_REQUEST)
        elif payout_method == 'bank_transfer' and not profile.bank_account_number:
            return Response({'error': 'Add your bank details in profile before requesting a withdrawal.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            amount = Decimal(str(request.data.get('amount', 0)))
        except (TypeError, ValueError):
            return Response({'error': 'Invalid withdrawal amount.'}, status=status.HTTP_400_BAD_REQUEST)

        if amount < Decimal(str(MIN_WITHDRAWAL_AMOUNT)):
            return Response({'error': f'Minimum withdrawal amount is ${MIN_WITHDRAWAL_AMOUNT:.2f}.'}, status=status.HTTP_400_BAD_REQUEST)

        # Server-side authoritative ledger balance calculation inside atomic transaction
        with transaction.atomic():
            User.objects.select_for_update().get(id=request.user.id)

            credits_sum = WalletTransaction.objects.filter(
                user=request.user,
                transaction_type='credit',
                status='completed'
            ).aggregate(total=Sum('amount'))['total'] or Decimal('0.00')

            debits_sum = WalletTransaction.objects.filter(
                user=request.user,
                transaction_type='debit',
                status='completed'
            ).aggregate(total=Sum('amount'))['total'] or Decimal('0.00')

            pending_withdrawals = WithdrawalRequest.objects.filter(
                professional=request.user,
                status='pending'
            ).aggregate(total=Sum('amount'))['total'] or Decimal('0.00')

            available = credits_sum - debits_sum - pending_withdrawals
            if amount > available:
                return Response({'error': f'Amount exceeds your available balance (${available:.2f}).'}, status=status.HTTP_400_BAD_REQUEST)

            withdrawal = WithdrawalRequest.objects.create(
                professional=request.user,
                amount=amount,
                currency='USD',
                status='pending',
                payout_method=payout_method,
                paypal_email=paypal_email,
                bank_account_name=profile.bank_account_name,
                bank_account_number=profile.bank_account_number,
                bank_name=profile.bank_name,
            )

            return Response(WithdrawalRequestSerializer(withdrawal).data, status=status.HTTP_201_CREATED)


# ─── 8. Currencies and Exchange Rates Endpoints ──────────────────────────────

class CurrencyListView(APIView):
    """
    GET /api/payments/currencies/
    Returns supported ISO currencies, symbols, and country-to-currency mapping.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        return Response({
            'base_currency': get_base_currency(),
            'currencies': SUPPORTED_CURRENCIES,
            'countries': COUNTRY_CURRENCY_MAP,
        })


class ExchangeRatesView(APIView):
    """
    GET /api/payments/exchange-rates/
    Returns cached live exchange rates relative to USD.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        refresh_exchange_rates()
        rates = ExchangeRateCache.objects.all()
        return Response({
            'base_currency': get_base_currency(),
            'rates': ExchangeRateCacheSerializer(rates, many=True).data,
        })

# ─── 9. Safepay Integration & Entitlement Fulfillment ─────────────────────────

from apps.payments.safepay import SafepayGateway, pkr_to_paisas, paisas_to_pkr
from apps.payments.models import WebhookEventLog, CacheInvalidationOutbox
from apps.subscriptions.models import (
    SubscriptionPlan,
    Subscription,
    FeaturedPromotionPackage,
    FeaturedListingCampaign,
    CampaignAuditLog,
)
from apps.profiles.models import ProfessionalProfile, ProfessionalSecondaryCategory
from apps.search.models import Category
import hashlib
import json


def fulfill_payment_entitlement(payment: Payment) -> bool:
    """
    Authoritative, idempotent fulfillment of monetization entitlements.
    Guarantees that subscriptions and featured campaigns are only activated once.
    """
    if payment.status == 'completed':
        return True

    with transaction.atomic():
        payment = Payment.objects.select_for_update().get(id=payment.id)
        if payment.status == 'completed':
            return True

        now = timezone.now()
        payment.status = 'completed'
        payment.save(update_fields=['status', 'updated_at'])

        if payment.purpose == 'subscription':
            plan = payment.subscription_plan
            if not plan:
                logger.error("Payment %s has no subscription_plan attached", payment.order_id)
                return False

            # Cancel previous active subscriptions for this user
            Subscription.objects.filter(user=payment.user, status='active').update(status='cancelled')

            duration_days = plan.duration_days if plan.duration_days > 0 else 30
            end_date = now + timedelta(days=duration_days)

            sub = Subscription.objects.create(
                user=payment.user,
                plan=plan,
                status='active',
                start_date=now,
                end_date=end_date,
            )
            payment.subscription = sub
            payment.save(update_fields=['subscription'])

            # Reactivate any secondary categories that were deactivated during Free period
            pp = getattr(payment.user, 'professionalprofile', None)
            if pp:
                ProfessionalSecondaryCategory.objects.filter(
                    professional_profile=pp, is_active=False
                ).update(is_active=True)

            # Invalidate cache outbox
            CacheInvalidationOutbox.objects.create(
                cache_key=f"pro_sub:{payment.user_id}",
                action="invalidate"
            )

            notify_user(
                user=payment.user,
                title="Professional Pro Active 🌟",
                message=f"Your {plan.name} subscription is active until {end_date.strftime('%d %b %Y')}.",
                notif_type="subscription"
            )

        elif payment.purpose == 'featured_listing':
            campaign = getattr(payment, 'featured_campaign', None)
            if not campaign:
                campaign = FeaturedListingCampaign.objects.filter(payment=payment).first()

            if campaign:
                campaign.start_date = now
                campaign.end_date = now + timedelta(days=campaign.duration_days)
                campaign.is_active = True
                campaign.save(update_fields=['start_date', 'end_date', 'is_active', 'updated_at'])

                CampaignAuditLog.objects.create(
                    campaign=campaign,
                    action='activated',
                    previous_state='inactive',
                    new_state='active',
                    actor=payment.user,
                    reason='Safepay payment verified and captured'
                )

                # Invalidate category featured cache outbox
                CacheInvalidationOutbox.objects.create(
                    cache_key=f"featured_cat:{campaign.category_id}",
                    action="incr"
                )

                notify_user(
                    user=payment.user,
                    title="Featured Listing Activated 🚀",
                    message=f"Your profile is featured in {campaign.category.name} for {campaign.duration_days} days.",
                    notif_type="promotion"
                )

    return True


def sweep_expired_campaigns():
    """
    Marks campaigns that have passed their end_date as is_active=False and logs audit.
    Returns the count of swept campaigns.
    """
    now = timezone.now()
    expired_camps = FeaturedListingCampaign.objects.filter(
        is_active=True,
        end_date__lt=now
    )
    count = 0
    for camp in expired_camps:
        camp.is_active = False
        camp.save(update_fields=['is_active', 'updated_at'])
        CampaignAuditLog.objects.create(
            campaign=camp,
            action='expired',
            previous_state='active',
            new_state='expired',
            reason='Campaign reached duration expiry date'
        )
        count += 1
    return count


class FeaturedPromotionPackagesListView(APIView):
    """
    GET /api/payments/featured/packages/
    Lists available featured promotion packages with clear pricing and benefits.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        packages = FeaturedPromotionPackage.objects.filter(is_active=True).order_by('duration_days')
        BENEFITS = {
            7: [
                'Pinned at top of category search results for 7 days',
                'Distinct Amber "Featured" badge',
                'Higher visibility in Normal and AI Search',
                'Priority ranking over regular listings',
            ],
            15: [
                'Pinned at top of category search results for 15 days',
                'Distinct Amber "Featured" badge',
                'Higher visibility in Normal and AI Search',
                'Priority ranking over regular listings',
                'Best value for bi-weekly campaigns',
            ],
            30: [
                'Pinned at top of category search results for 30 days',
                'Distinct Amber "Featured" badge',
                'Higher visibility in Normal and AI Search',
                'Priority ranking over regular listings',
                'Maximum exposure & customer inquiries',
            ],
        }
        data = [
            {
                'id': p.id,
                'name': p.name,
                'duration_days': p.duration_days,
                'price': str(p.price),
                'currency': p.currency,
                'formatted_price': f"{p.currency} {p.price:,.0f}",
                'is_active': p.is_active,
                'benefits': BENEFITS.get(p.duration_days, [
                    f'Featured placement for {p.duration_days} days',
                    'Distinct Amber "Featured" badge',
                    'Priority search placement',
                ]),
                'disclosure': 'Featured placement is a promotional listing and does not imply identity verification.',
            }
            for p in packages
        ]
        return Response(data)


class ProfessionalFeaturedStatusView(APIView):
    """
    GET /api/payments/featured/status/
    Returns the current professional's featured promotion status, active campaign, and purchase history.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role != 'professional':
            return Response({'error': 'Only professionals have featured promotion status.'}, status=status.HTTP_403_FORBIDDEN)

        try:
            prof_profile = request.user.professionalprofile
        except Exception:
            return Response({'error': 'Professional profile required.'}, status=status.HTTP_404_NOT_FOUND)

        # Run sweep to ensure any past-due campaign is marked inactive
        sweep_expired_campaigns()

        now = timezone.now()
        active_camp = FeaturedListingCampaign.objects.filter(
            professional=prof_profile,
            is_active=True,
            start_date__lte=now,
            end_date__gte=now,
            payment__status='completed'
        ).select_related('package', 'category', 'payment').first()

        active_data = None
        if active_camp:
            remaining = active_camp.end_date - now
            remaining_days = max(0, remaining.days)
            remaining_hours = max(0, int(remaining.total_seconds() // 3600))
            active_data = {
                'id': active_camp.id,
                'package_name': active_camp.package.name if active_camp.package else f"{active_camp.duration_days} Days Promotion",
                'duration_days': active_camp.duration_days,
                'category_id': active_camp.category_id,
                'category_name': active_camp.category.name if active_camp.category else '',
                'start_date': active_camp.start_date.isoformat() if active_camp.start_date else None,
                'end_date': active_camp.end_date.isoformat() if active_camp.end_date else None,
                'start_date_formatted': active_camp.start_date.strftime('%d %b %Y, %I:%M %p') if active_camp.start_date else None,
                'end_date_formatted': active_camp.end_date.strftime('%d %b %Y, %I:%M %p') if active_camp.end_date else None,
                'remaining_days': remaining_days,
                'remaining_hours': remaining_hours,
                'payment_status': active_camp.payment.status if active_camp.payment else 'completed',
                'order_id': active_camp.payment.order_id if active_camp.payment else None,
                'safepay_tracker': active_camp.payment.safepay_tracker if active_camp.payment else None,
                'amount': str(active_camp.payment.amount) if active_camp.payment else str(active_camp.package.price if active_camp.package else 0),
                'currency': active_camp.payment.currency if active_camp.payment else 'PKR',
            }

        # Past campaigns history
        campaigns_qs = FeaturedListingCampaign.objects.filter(
            professional=prof_profile
        ).select_related('package', 'category', 'payment').order_by('-created_at')[:10]

        history = []
        for c in campaigns_qs:
            history.append({
                'id': c.id,
                'package_name': c.package.name if c.package else f"{c.duration_days} Days Promotion",
                'duration_days': c.duration_days,
                'category_name': c.category.name if c.category else '',
                'start_date': c.start_date.strftime('%d %b %Y') if c.start_date else None,
                'end_date': c.end_date.strftime('%d %b %Y') if c.end_date else None,
                'is_active': c.is_currently_running(),
                'payment_status': c.payment.status if c.payment else 'unknown',
                'amount': str(c.payment.amount) if c.payment else '0',
                'order_id': c.payment.order_id if c.payment else None,
                'created_at': c.created_at.strftime('%d %b %Y, %I:%M %p'),
            })

        default_cat_id = prof_profile.category_id
        default_cat_name = prof_profile.category.name if prof_profile.category else 'Your Category'

        return Response({
            'has_active_promotion': bool(active_data),
            'can_promote': active_data is None,
            'active_campaign': active_data,
            'history': history,
            'default_category_id': default_cat_id,
            'default_category_name': default_cat_name,
        })


class SafepayInitializeCheckoutView(APIView):
    """
    POST /api/payments/checkout/initialize/
    Initiates a verified checkout with Safepay for Subscriptions or Featured Promotions.
    All amounts are looked up exclusively from the DB; client amounts are ignored.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        purpose = request.data.get('purpose')
        redirect_url = request.data.get('redirect_url')
        cancel_url = request.data.get('cancel_url')

        if purpose not in ('subscription', 'featured_listing'):
            return Response(
                {'error': 'Invalid purpose. Must be "subscription" or "featured_listing".'},
                status=status.HTTP_400_BAD_REQUEST
            )

        gateway = SafepayGateway()

        if purpose == 'subscription':
            plan_id = request.data.get('plan_id')
            if not plan_id:
                return Response({'error': 'plan_id is required.'}, status=status.HTTP_400_BAD_REQUEST)

            try:
                plan = SubscriptionPlan.objects.get(id=plan_id, is_active=True)
            except SubscriptionPlan.DoesNotExist:
                return Response({'error': 'Subscription plan not found or inactive.'}, status=status.HTTP_404_NOT_FOUND)

            if plan.plan_type != request.user.role:
                return Response({'error': f'This plan is for {plan.plan_type}s only.'}, status=status.HTTP_400_BAD_REQUEST)

            # Free plan immediate activation without payment
            if plan.billing == 'free' or plan.price <= Decimal('0.00'):
                with transaction.atomic():
                    Subscription.objects.filter(user=request.user, status='active').update(status='cancelled')
                    sub = Subscription.objects.create(
                        user=request.user,
                        plan=plan,
                        status='active',
                        end_date=None,
                    )
                return Response({
                    'status': 'completed',
                    'is_free': True,
                    'plan_name': plan.name,
                    'message': f'Successfully activated {plan.name} plan.',
                }, status=status.HTTP_200_OK)

            price = plan.price
            amount_pkr = int(round(float(price)))

            payment_method = (request.data.get('payment_method') or 'all').strip().lower()
            intent = 'RAAST' if payment_method == 'raast' else ('CYBERSOURCE' if payment_method == 'card' else None)

            try:
                order_result = gateway.create_order(amount=amount_pkr, currency='PKR', intent=intent)
                tracker = order_result['tracker']
                tbt = gateway.create_passport_token()
                checkout_url = gateway.build_express_checkout_url(
                    tracker=tracker,
                    tbt=tbt,
                    source='custom',
                    redirect_url=redirect_url,
                    cancel_url=cancel_url,
                )
            except Exception as exc:
                logger.error("Safepay checkout initialization failed: %s", exc)
                return Response({'error': f'Failed to initialize checkout: {str(exc)}'}, status=status.HTTP_502_BAD_GATEWAY)

            payment = Payment.objects.create(
                user=request.user,
                amount=price,
                currency='PKR',
                purpose='subscription',
                subscription_plan=plan,
                gateway='safepay',
                safepay_tracker=tracker,
                safepay_environment=gateway.environment,
                approval_url=checkout_url,
                local_amount=price,
                local_currency='PKR',
                exchange_rate=Decimal('1.00'),
                status='pending',
            )

            return Response({
                'order_id': payment.order_id,
                'payment_id': payment.id,
                'safepay_tracker': tracker,
                'checkout_url': checkout_url,
                'amount': str(payment.amount),
                'currency': payment.currency,
                'purpose': purpose,
                'payment_method': payment_method,
                'supported_methods': [
                    {'id': 'all', 'name': 'All Payment Methods (Cards, Raast QR & RTP, Wallets)'},
                    {'id': 'raast', 'name': 'Raast Instant Payment (Dynamic QR & RTP)'},
                    {'id': 'card', 'name': 'Debit / Credit Card (Visa, Mastercard, PayPak)'},
                ],
            }, status=status.HTTP_201_CREATED)

        elif purpose == 'featured_listing':
            if request.user.role != 'professional':
                return Response({'error': 'Only professionals can purchase featured promotions.'}, status=status.HTTP_403_FORBIDDEN)

            try:
                prof_profile = request.user.professionalprofile
            except Exception:
                return Response({'error': 'Professional profile required.'}, status=status.HTTP_404_NOT_FOUND)

            # Automatically sweep any expired campaigns first
            sweep_expired_campaigns()

            # Prevent duplicate overlapping active promotions
            now = timezone.now()
            existing_active = FeaturedListingCampaign.objects.filter(
                professional=prof_profile,
                is_active=True,
                start_date__lte=now,
                end_date__gte=now,
                payment__status='completed',
            ).first()
            if existing_active:
                cat_name = existing_active.category.name if existing_active.category else 'your category'
                expiry_str = existing_active.end_date.strftime('%d %b %Y') if existing_active.end_date else 'soon'
                return Response({
                    'error': f'You already have an active Featured Listing in {cat_name} running until {expiry_str}. You can promote again after it expires.'
                }, status=status.HTTP_400_BAD_REQUEST)

            package_id = request.data.get('package_id')
            category_id = request.data.get('category_id')

            # Default to professional's primary category if omitted
            if not category_id and prof_profile.category_id:
                category_id = prof_profile.category_id

            if not package_id or not category_id:
                return Response({'error': 'package_id and category_id are required.'}, status=status.HTTP_400_BAD_REQUEST)

            try:
                pkg = FeaturedPromotionPackage.objects.get(id=package_id, is_active=True)
            except FeaturedPromotionPackage.DoesNotExist:
                return Response({'error': 'Featured package not found or inactive.'}, status=status.HTTP_404_NOT_FOUND)

            try:
                category = Category.objects.get(id=category_id)
            except Category.DoesNotExist:
                return Response({'error': 'Category not found.'}, status=status.HTTP_404_NOT_FOUND)

            # Strict relevance validation:
            # Professional must belong to this category (primary or secondary)
            is_primary = (prof_profile.category_id == category.id)
            is_secondary = ProfessionalSecondaryCategory.objects.filter(
                professional_profile=prof_profile, category=category
            ).exists()
            if not (is_primary or is_secondary):
                primary_name = prof_profile.category.name if prof_profile.category else 'none'
                return Response({
                    'error': f'You can only promote your profile in categories registered to your profile ({primary_name}).'
                }, status=status.HTTP_400_BAD_REQUEST)

            price = pkg.price
            amount_pkr = int(round(float(price)))

            payment_method = (request.data.get('payment_method') or 'all').strip().lower()
            intent = 'RAAST' if payment_method == 'raast' else ('CYBERSOURCE' if payment_method == 'card' else None)

            try:
                order_result = gateway.create_order(amount=amount_pkr, currency='PKR', intent=intent)
                tracker = order_result['tracker']
                tbt = gateway.create_passport_token()
                checkout_url = gateway.build_express_checkout_url(
                    tracker=tracker,
                    tbt=tbt,
                    source='custom',
                    redirect_url=redirect_url,
                    cancel_url=cancel_url,
                )
            except Exception as exc:
                logger.error("Safepay checkout initialization failed: %s", exc)
                return Response({'error': f'Failed to initialize checkout: {str(exc)}'}, status=status.HTTP_502_BAD_GATEWAY)

            with transaction.atomic():
                payment = Payment.objects.create(
                    user=request.user,
                    amount=price,
                    currency='PKR',
                    purpose='featured_listing',
                    gateway='safepay',
                    safepay_tracker=tracker,
                    safepay_environment=gateway.environment,
                    approval_url=checkout_url,
                    local_amount=price,
                    local_currency='PKR',
                    exchange_rate=Decimal('1.00'),
                    status='pending',
                )

                FeaturedListingCampaign.objects.create(
                    professional=prof_profile,
                    category=category,
                    package=pkg,
                    duration_days=pkg.duration_days,
                    payment=payment,
                    is_active=False,
                )

            return Response({
                'order_id': payment.order_id,
                'payment_id': payment.id,
                'safepay_tracker': tracker,
                'checkout_url': checkout_url,
                'amount': str(payment.amount),
                'currency': payment.currency,
                'purpose': purpose,
                'duration_days': pkg.duration_days,
            }, status=status.HTTP_201_CREATED)


class SafepayVerifyPaymentView(APIView):
    """
    GET /api/payments/verify-status/?order_id=PO-... or ?tracker=track_...
    Authoritatively queries Safepay Reporter API to verify payment capture and grants entitlement.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        order_id = request.query_params.get('order_id')
        tracker = request.query_params.get('tracker')

        if not order_id and not tracker:
            return Response({'error': 'order_id or tracker parameter is required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            if order_id:
                payment = Payment.objects.get(order_id=order_id, user=request.user)
            else:
                payment = Payment.objects.get(safepay_tracker=tracker, user=request.user)
        except Payment.DoesNotExist:
            return Response({'error': 'Payment record not found.'}, status=status.HTTP_404_NOT_FOUND)

        if payment.status == 'completed':
            return Response({
                'status': 'completed',
                'order_id': payment.order_id,
                'purpose': payment.purpose,
                'message': 'Payment already verified and completed.',
            })

        if not payment.safepay_tracker:
            return Response({'error': 'Payment has no associated Safepay tracker.'}, status=status.HTTP_400_BAD_REQUEST)

        gateway = SafepayGateway()
        try:
            reporter_res = gateway.query_reporter_status(payment.safepay_tracker)
        except Exception as exc:
            logger.error("Reporter query error for payment %s: %s", payment.order_id, exc)
            return Response({'error': f'Failed to query Safepay Reporter API: {str(exc)}'}, status=status.HTTP_502_BAD_GATEWAY)

        SUCCESS_STATES = {'TRACKER_ENDED', 'TRACKER_COMPLETED', 'COMPLETED', 'PAID', 'CAPTURED', 'SUCCESS'}
        reporter_state = str(reporter_res.get('state') or reporter_res.get('status') or '').strip().upper()
        is_success = (
            reporter_res.get('status') == 'completed' or
            reporter_state in SUCCESS_STATES or
            bool(reporter_res.get('captured'))
        )

        if is_success:
            fulfill_payment_entitlement(payment)
            payment.refresh_from_db()
            logger.info("Safepay payment %s verified and entitlement fulfilled via verify-status (state: %s).", payment.order_id, reporter_state)
            return Response({
                'status': 'completed',
                'order_id': payment.order_id,
                'purpose': payment.purpose,
                'message': 'Payment verified and entitlement granted successfully.',
            })
        else:
            current_state = reporter_res.get('state') or reporter_res.get('status') or 'pending'
            logger.info("Safepay payment %s verify-status check: state is %s", payment.order_id, current_state)
            return Response({
                'status': current_state.lower(),
                'order_id': payment.order_id,
                'purpose': payment.purpose,
                'message': f'Payment is currently {current_state}.',
            })


class SafepayWebhookView(APIView):
    """
    POST /api/payments/webhook/safepay/
    Durable webhook ingestion endpoint:
      1. HMAC-SHA256 signature verification.
      2. Durable event deduplication in WebhookEventLog.
      3. Immediate HTTP 200 OK acknowledgement.
      4. Reporter API verification before entitlement grant.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        raw_body = request.body
        signature = (
            request.headers.get('X-SFPY-SIGNATURE') or
            request.headers.get('x-sfpy-signature') or
            request.headers.get('X-Safepay-Signature') or
            request.headers.get('x-safepay-signature') or
            request.META.get('HTTP_X_SFPY_SIGNATURE') or
            request.META.get('HTTP_X_SAFEPAY_SIGNATURE') or
            ''
        )

        gateway = SafepayGateway()
        is_valid_sig = gateway.verify_webhook_signature(raw_body, signature)

        delivery_fingerprint = hashlib.sha256(raw_body).hexdigest()

        try:
            payload = json.loads(raw_body.decode('utf-8')) if raw_body else {}
        except Exception:
            payload = {}

        event_id = payload.get('id') or payload.get('event_id') or f"evt_{delivery_fingerprint[:24]}"
        event_type = payload.get('type') or payload.get('event') or payload.get('event_type') or 'payment.completed'

        logger.info(
            "Safepay webhook received. Event: %s, EventID: %s, Fingerprint: %s",
            event_type, event_id, delivery_fingerprint[:12]
        )

        if not is_valid_sig:
            logger.warning("Safepay webhook signature validation failed. Fingerprint: %s", delivery_fingerprint[:12])
            WebhookEventLog.objects.create(
                provider='safepay',
                event_id=event_id,
                delivery_fingerprint=delivery_fingerprint,
                event_type=event_type,
                status='payload_tampering_conflict',
                sanitized_payload={'raw_length': len(raw_body)},
                error_message='Invalid HMAC-SHA256 signature',
            )
            return Response({'error': 'Invalid webhook signature.'}, status=status.HTTP_400_BAD_REQUEST)

        logger.info("Safepay webhook signature verified successfully for event %s", event_id)

        # Durable deduplication check
        existing_log = WebhookEventLog.objects.filter(provider='safepay', event_id=event_id).first()
        if existing_log:
            logger.info("Safepay duplicate webhook ignored for event %s", event_id)
            return Response({'status': 'duplicate_ignored'}, status=status.HTTP_200_OK)

        log_entry = WebhookEventLog.objects.create(
            provider='safepay',
            event_id=event_id,
            delivery_fingerprint=delivery_fingerprint,
            event_type=event_type,
            status='received',
            sanitized_payload=payload,
        )

        # Retrieve tracker token safely
        data_obj = payload.get('data') if isinstance(payload.get('data'), dict) else {}
        tracker_inner = data_obj.get('tracker')
        tracker_token_from_inner = tracker_inner.get('token') if isinstance(tracker_inner, dict) else tracker_inner

        tracker = (
            data_obj.get('token') or
            tracker_token_from_inner or
            payload.get('token') or
            payload.get('tracker')
        )

        # Check payload state as well
        payload_state = str(
            (tracker_inner.get('state') if isinstance(tracker_inner, dict) else None) or
            data_obj.get('state') or
            data_obj.get('status') or
            payload.get('state') or
            ''
        ).strip().upper()

        PAYLOAD_SUCCESS_STATES = {'TRACKER_ENDED', 'TRACKER_COMPLETED', 'COMPLETED', 'PAID', 'CAPTURED', 'SUCCESS'}
        is_payload_success = (
            event_type in ('payment.completed', 'payment:created') or
            payload_state in PAYLOAD_SUCCESS_STATES
        )

        if tracker:
            payment = Payment.objects.filter(safepay_tracker=tracker).first()
            if payment:
                logger.info(
                    "Safepay webhook matched Payment: OrderID: %s, User: %s, Amount: %s",
                    payment.order_id, payment.user.email, payment.amount
                )
                log_entry.status = 'processing'
                log_entry.save(update_fields=['status'])
                try:
                    reporter_res = gateway.query_reporter_status(tracker)
                    reporter_success = reporter_res.get('status') == 'completed' and reporter_res.get('captured')
                    if reporter_success or is_payload_success:
                        fulfill_payment_entitlement(payment)
                        log_entry.status = 'completed'
                        logger.info("Safepay webhook successfully fulfilled entitlement for payment %s", payment.order_id)
                    else:
                        log_entry.status = 'retryable_failure'
                        logger.warning("Safepay webhook payment %s not in completed state yet: %s", payment.order_id, reporter_res)
                except Exception as exc:
                    if is_payload_success:
                        fulfill_payment_entitlement(payment)
                        log_entry.status = 'completed'
                        logger.info("Safepay webhook fulfilled via verified payload despite Reporter query error: %s", exc)
                    else:
                        logger.error("Error during webhook Reporter query for tracker %s: %s", tracker, exc)
                        log_entry.status = 'retryable_failure'
                        log_entry.error_message = str(exc)
                log_entry.save(update_fields=['status', 'error_message'])
            else:
                logger.warning("Safepay webhook received tracker %s with no matching Payment record.", tracker)
                log_entry.status = 'quarantined_unknown_tracker'
                log_entry.save(update_fields=['status'])

        return Response({'status': 'received'}, status=status.HTTP_200_OK)
