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
    Creates a server-side verified PayPal order for a booking.
    Payload: { "booking_id": 12, "currency": "USD" (optional display currency) }
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
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
            'available_balance': float(available_balance),
            'total_earned': float(credits_sum),
            'total_withdrawn': float(debits_sum),
            'pending_withdrawal': float(pending_withdrawals),
            'min_withdrawal': MIN_WITHDRAWAL_AMOUNT,
            'bank_on_file': bool(profile and profile.bank_account_number),
            'transactions': tx_history,
            'currency': curr,
            'currency_symbol': sym,
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
        from apps.profiles.models import ProfessionalProfile

        try:
            profile = ProfessionalProfile.objects.get(user=request.user)
        except ProfessionalProfile.DoesNotExist:
            return Response({'error': 'Complete your professional profile first.'}, status=status.HTTP_400_BAD_REQUEST)

        payout_method = request.data.get('payout_method', 'bank_transfer')
        paypal_email = (request.data.get('paypal_email') or '').strip()

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