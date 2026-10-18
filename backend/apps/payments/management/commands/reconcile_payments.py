# apps/payments/management/commands/reconcile_payments.py

import logging
from datetime import timedelta
from django.core.management.base import BaseCommand
from django.utils import timezone
from django.db import transaction
from apps.payments.models import Payment, WalletTransaction
from apps.bookings.models import Booking
from apps.payments import paypal

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = 'Reconciles pending payments, gateway statuses, and ledger balances.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--minutes',
            type=int,
            default=30,
            help='Reconcile payments created at least this many minutes ago (default: 30)'
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Report inconsistencies without making modifications'
        )

    def handle(self, *args, **options):
        minutes = options['minutes']
        dry_run = options['dry_run']
        cutoff = timezone.now() - timedelta(minutes=minutes)

        self.stdout.write(self.style.NOTICE(
            f"Starting payment reconciliation (older than {minutes}m, dry_run={dry_run})..."
        ))

        pending_payments = Payment.objects.filter(status='pending', created_at__lte=cutoff)
        reconciled_count = 0
        failed_count = 0

        for payment in pending_payments:
            if not payment.paypal_order_id:
                continue

            self.stdout.write(f"Checking Payment #{payment.id} ({payment.order_id})...")
            try:
                # In sandbox / production, attempt capture or check status
                if payment.paypal_order_id.startswith('MOCK-') or not paypal.has_valid_credentials():
                    # For local testing, leave or mock-resolve
                    continue

                token = paypal.get_access_token()
                import requests
                url = f"{paypal.get_base_url()}/v2/checkout/orders/{payment.paypal_order_id}"
                resp = requests.get(url, headers={'Authorization': f'Bearer {token}'}, timeout=10)

                if resp.status_code == 200:
                    order_info = resp.json()
                    order_status = order_info.get('status')

                    if order_status == 'APPROVED':
                        self.stdout.write(self.style.SUCCESS(
                            f"Order {payment.paypal_order_id} was approved by buyer. Attempting capture..."
                        ))
                        if not dry_run:
                            capture_res = paypal.capture_order(payment.paypal_order_id)
                            with transaction.atomic():
                                payment.status = 'completed'
                                payment.paypal_capture_id = capture_res.get('capture_id', '')
                                payment.save()
                                if payment.purpose == 'booking' and payment.booking:
                                    payment.booking.payment_status = 'paid'
                                    payment.booking.save(update_fields=['payment_status'])
                            reconciled_count += 1

                    elif order_status in ('COMPLETED',):
                        self.stdout.write(self.style.SUCCESS(
                            f"Order {payment.paypal_order_id} already captured on gateway. Updating DB..."
                        ))
                        if not dry_run:
                            with transaction.atomic():
                                payment.status = 'completed'
                                payment.save(update_fields=['status'])
                                if payment.purpose == 'booking' and payment.booking:
                                    payment.booking.payment_status = 'paid'
                                    payment.booking.save(update_fields=['payment_status'])
                            reconciled_count += 1

                    elif order_status in ('VOIDED', 'EXPIRED'):
                        self.stdout.write(self.style.WARNING(
                            f"Order {payment.paypal_order_id} is {order_status}. Marking failed..."
                        ))
                        if not dry_run:
                            payment.status = 'failed'
                            payment.error_message = f"Gateway status: {order_status}"
                            payment.save(update_fields=['status', 'error_message'])
                        failed_count += 1

            except Exception as exc:
                self.stdout.write(self.style.ERROR(
                    f"Error reconciling payment #{payment.id}: {exc}"
                ))

        # Check completed bookings with paid status that miss ledger entry
        completed_paid_bookings = Booking.objects.filter(status='completed', payment_status='paid')
        ledger_fixed = 0
        for bkg in completed_paid_bookings:
            if bkg.total_price > 0 and not WalletTransaction.objects.filter(booking=bkg, transaction_type='credit').exists():
                self.stdout.write(f"Missing ledger credit for completed booking #{bkg.id}. Creating entry...")
                if not dry_run:
                    WalletTransaction.objects.create(
                        user=bkg.professional,
                        transaction_type='credit',
                        amount=bkg.total_price,
                        currency=bkg.currency,
                        status='completed',
                        booking=bkg,
                        description=f"Reconciled earnings for booking #{bkg.id}"
                    )
                ledger_fixed += 1

        self.stdout.write(self.style.SUCCESS(
            f"Reconciliation complete: {reconciled_count} payments captured/completed, "
            f"{failed_count} marked failed, {ledger_fixed} ledger entries synced."
        ))
