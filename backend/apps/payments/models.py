# apps/payments/models.py

import uuid
from decimal import Decimal
from django.db import models
from django.conf import settings


class Payment(models.Model):
    STATUS_CHOICES = [
        ('pending',            'Pending'),
        ('processing',         'Processing'),
        ('approved',           'Approved'),
        ('completed',          'Completed'),
        ('failed',             'Failed'),
        ('cancelled',          'Cancelled'),
        ('refunded',           'Refunded'),
        ('partially_refunded', 'Partially Refunded'),
        ('disputed',           'Disputed'),
    ]

    PURPOSE_CHOICES = [
        ('booking',          'Booking Payment'),
        ('subscription',     'Subscription Payment'),
        ('featured_listing', 'Featured Listing Promotion'),
        ('other',            'Other Payment'),
    ]

    order_id = models.CharField(
        max_length=64, unique=True, null=True, blank=True, db_index=True,
        help_text="Internal unique order reference ID (e.g. PO-UUID)"
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='payments'
    )
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=10, default='PKR')
    purpose = models.CharField(
        max_length=30, choices=PURPOSE_CHOICES, default='booking', db_index=True
    )
    booking = models.ForeignKey(
        'bookings.Booking',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='payments'
    )
    subscription = models.ForeignKey(
        'subscriptions.Subscription',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='payments'
    )
    subscription_plan = models.ForeignKey(
        'subscriptions.SubscriptionPlan',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='payments'
    )

    gateway = models.CharField(max_length=50, default='paypal')
    stripe_id = models.CharField(max_length=255, blank=True)
    paypal_order_id = models.CharField(max_length=255, blank=True, db_index=True)
    paypal_capture_id = models.CharField(max_length=255, blank=True, db_index=True)
    paypal_payer_id = models.CharField(max_length=255, blank=True)
    paypal_payer_email = models.CharField(max_length=255, blank=True)
    idempotency_key = models.CharField(max_length=255, blank=True, db_index=True)
    approval_url = models.TextField(blank=True)
    safepay_tracker = models.CharField(max_length=120, unique=True, null=True, blank=True, db_index=True)
    safepay_environment = models.CharField(max_length=20, default='sandbox')

    # Local currency presentation snapshot
    local_amount = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    local_currency = models.CharField(max_length=10, blank=True, default='')
    exchange_rate = models.DecimalField(max_digits=14, decimal_places=6, null=True, blank=True)

    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending', db_index=True)
    error_message = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def save(self, *args, **kwargs):
        if not self.order_id:
            self.order_id = f"PO-{uuid.uuid4().hex[:12].upper()}"
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.order_id or self.id} - {self.user.email} - {self.amount} {self.currency} - {self.status}"


class WalletTransaction(models.Model):
    """
    Immutable double-entry-style financial ledger.
    Tracks all balance changes (credits from completed jobs, holds, debits from withdrawals).
    """
    TYPE_CHOICES = [
        ('credit',     'Credit / Earning'),
        ('debit',      'Debit / Withdrawal'),
        ('hold',       'Escrow Hold'),
        ('release',    'Escrow Release'),
        ('refund',     'Refund Debit'),
        ('adjustment', 'Admin Adjustment'),
    ]

    STATUS_CHOICES = [
        ('pending',            'Pending'),
        ('processing',         'Processing'),
        ('approved',           'Approved'),
        ('completed',          'Completed'),
        ('failed',             'Failed'),
        ('cancelled',          'Cancelled'),
        ('refunded',           'Refunded'),
        ('partially_refunded', 'Partially Refunded'),
        ('disputed',           'Disputed'),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='wallet_transactions'
    )
    transaction_type = models.CharField(max_length=20, choices=TYPE_CHOICES, db_index=True)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=10, default='PKR')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='completed', db_index=True)

    payment = models.ForeignKey(
        Payment,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='wallet_transactions'
    )
    booking = models.ForeignKey(
        'bookings.Booking',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='wallet_transactions'
    )
    withdrawal = models.ForeignKey(
        'WithdrawalRequest',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='wallet_transactions'
    )

    description = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.transaction_type}] {self.user.email} - {self.amount} {self.currency} ({self.status})"


class WithdrawalRequest(models.Model):
    PENDING  = 'pending'
    APPROVED = 'approved'
    REJECTED = 'rejected'
    PAID     = 'paid'
    STATUS_CHOICES = [
        (PENDING,  'Pending'),
        (APPROVED, 'Approved'),
        (REJECTED, 'Rejected'),
        (PAID,     'Paid'),
    ]

    METHOD_CHOICES = [
        ('bank_transfer', 'Bank Transfer'),
        ('paypal',        'PayPal Payout'),
    ]

    professional = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='withdrawal_requests'
    )
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=10, default='PKR')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=PENDING, db_index=True)
    payout_method = models.CharField(max_length=30, choices=METHOD_CHOICES, default='bank_transfer')
    paypal_email = models.CharField(max_length=255, blank=True)

    # Bank details snapshot
    bank_account_name = models.CharField(max_length=255, blank=True)
    bank_account_number = models.CharField(max_length=50, blank=True)
    bank_name = models.CharField(max_length=255, blank=True)

    admin_note = models.TextField(blank=True)
    requested_at = models.DateTimeField(auto_now_add=True)
    processed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-requested_at']

    def __str__(self):
        return f"{self.professional.email} - {self.amount} {self.currency} - {self.status}"


class ExchangeRateCache(models.Model):
    """
    Cached exchange rates against base currency (default USD).
    """
    base_currency = models.CharField(max_length=10, default='PKR')
    target_currency = models.CharField(max_length=10, db_index=True, unique=True)
    rate = models.DecimalField(max_digits=14, decimal_places=6)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['target_currency']

    def __str__(self):
        return f"1 {self.base_currency} = {self.rate} {self.target_currency} (as of {self.updated_at.strftime('%Y-%m-%d %H:%M')})"

class WebhookEventLog(models.Model):
    STATUS_CHOICES = [
        ('received',                     'Received'),
        ('processing',                   'Processing'),
        ('completed',                    'Completed'),
        ('retryable_failure',            'Retryable Failure'),
        ('dead_letter',                  'Dead Letter'),
        ('quarantined_unknown_tracker',  'Quarantined Unknown Tracker'),
        ('payload_tampering_conflict',   'Payload Tampering Conflict'),
        ('permanently_invalid',          'Permanently Invalid'),
    ]
    provider = models.CharField(max_length=30, default='safepay')
    event_id = models.CharField(max_length=150, db_index=True)
    delivery_fingerprint = models.CharField(max_length=64, blank=True, db_index=True)
    event_type = models.CharField(max_length=80, blank=True)
    status = models.CharField(max_length=40, choices=STATUS_CHOICES, default='received', db_index=True)
    lease_token = models.UUIDField(null=True, blank=True, db_index=True)
    lease_expires_at = models.DateTimeField(null=True, blank=True, db_index=True)
    retry_count = models.PositiveSmallIntegerField(default=0)
    retry_at = models.DateTimeField(null=True, blank=True, db_index=True)
    sanitized_payload = models.JSONField(null=True, blank=True)
    error_message = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('provider', 'event_id')
        indexes = [
            models.Index(fields=['provider', 'event_id']),
            models.Index(fields=['status', 'lease_expires_at']),
            models.Index(fields=['status', 'retry_at']),
        ]

    def __str__(self):
        return f"[{self.provider}] {self.event_id} ({self.status})"


class CacheInvalidationOutbox(models.Model):
    cache_key = models.CharField(max_length=255, db_index=True)
    action = models.CharField(max_length=30, default='incr')
    processed = models.BooleanField(default=False, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    processed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f"{self.cache_key} [{self.action}] - {'Done' if self.processed else 'Pending'}"
