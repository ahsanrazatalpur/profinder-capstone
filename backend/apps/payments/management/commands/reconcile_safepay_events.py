import os
import uuid
import logging
from datetime import timedelta
from django.utils import timezone
from django.core.management.base import BaseCommand
from django.core.cache import cache
from apps.payments.models import Payment, WebhookEventLog, CacheInvalidationOutbox
from apps.payments.safepay import SafepayGateway
from apps.payments.views import fulfill_payment_entitlement

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = "Reconciles pending Safepay webhook events, recovers unfulfilled payments, and processes cache invalidation outbox."

    def handle(self, *args, **options):
        now = timezone.now()
        gateway = SafepayGateway()

        self.stdout.write("Starting Safepay event & outbox reconciliation...")

        # 1. Reconcile Webhook Events
        pending_events = WebhookEventLog.objects.filter(
            status__in=['received', 'processing', 'retryable_failure'],
            provider='safepay'
        )

        reconciled_events = 0
        for event in pending_events:
            # Lease check to avoid concurrent worker conflicts
            if event.status == 'processing' and event.lease_expires_at and event.lease_expires_at > now:
                continue

            event.status = 'processing'
            event.lease_token = uuid.uuid4()
            event.lease_expires_at = now + timedelta(minutes=5)
            event.save(update_fields=['status', 'lease_token', 'lease_expires_at'])

            payload = event.sanitized_payload or {}
            tracker = (
                payload.get('data', {}).get('token') or
                payload.get('data', {}).get('tracker') or
                payload.get('token') or
                payload.get('tracker')
            )

            if not tracker:
                event.status = 'permanently_invalid'
                event.save(update_fields=['status'])
                continue

            payment = Payment.objects.filter(safepay_tracker=tracker).first()
            if not payment:
                event.status = 'quarantined_unknown_tracker'
                event.save(update_fields=['status'])
                continue

            try:
                res = gateway.query_reporter_status(tracker)
                if res.get('status') == 'completed' and res.get('captured'):
                    fulfill_payment_entitlement(payment)
                    event.status = 'completed'
                    reconciled_events += 1
                else:
                    event.retry_count += 1
                    if event.retry_count >= 10:
                        event.status = 'dead_letter'
                    else:
                        event.status = 'retryable_failure'
            except Exception as e:
                logger.error("Error reconciling event %s: %s", event.event_id, str(e))
                event.retry_count += 1
                if event.retry_count >= 10:
                    event.status = 'dead_letter'
                else:
                    event.status = 'retryable_failure'
                event.error_message = str(e)

            event.save(update_fields=['status', 'retry_count', 'error_message', 'updated_at'])

        self.stdout.write(f"Reconciled {reconciled_events} Safepay webhook event(s).")

        # 2. Reconcile Pending Payments Older Than 15 Minutes
        pending_payments = Payment.objects.filter(
            gateway='safepay',
            status='pending',
            created_at__lte=now - timedelta(minutes=15)
        )
        recovered_payments = 0
        for payment in pending_payments:
            if not payment.safepay_tracker:
                continue
            try:
                res = gateway.query_reporter_status(payment.safepay_tracker)
                if res.get('status') == 'completed' and res.get('captured'):
                    fulfill_payment_entitlement(payment)
                    recovered_payments += 1
            except Exception as e:
                logger.warning("Could not verify pending payment %s: %s", payment.order_id, str(e))

        self.stdout.write(f"Recovered {recovered_payments} pending payment(s).")

        # 3. Process Cache Invalidation Outbox
        pending_outbox = CacheInvalidationOutbox.objects.filter(processed=False)
        outbox_count = 0
        for item in pending_outbox:
            try:
                cache.delete(item.cache_key)
            except Exception:
                pass
            item.processed = True
            item.processed_at = timezone.now()
            item.save(update_fields=['processed', 'processed_at'])
            outbox_count += 1

        self.stdout.write(f"Processed {outbox_count} cache invalidation outbox item(s).")
        self.stdout.write(self.style.SUCCESS("Reconciliation completed successfully."))
