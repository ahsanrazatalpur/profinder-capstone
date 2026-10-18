# apps/payments/models.py

import uuid
from decimal import Decimal
from django.db import models
from django.conf import settings


class Payment(models.Model):
    STATUS_CHOICES = [
        ('pending',   'Pending'),
        ('approved',  'Approved'),
        ('completed', 'Completed'),
        ('failed',    'Failed'),
        ('cancelled', 'Cancelled'),
        ('refunded',  'Refunded'),
    ]

    PURPOSE_CHOICES = [
        ('booking',      'Booking Payment'),
        ('subscription', 'Subscription Payment'),
        ('other',        'Other Payment'),
    ]

    order_id = models.CharField(
        max_length=64, unique=True, null=True, blank=True, db_index=True,
        help_text="Internal unique order reference ID (e.g. PO-UUID)"
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='payments'
    )
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=10, default='USD')
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
        ('pending',   'Pending'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
        ('failed',    'Failed'),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='wallet_transactions'
    )
    transaction_type = models.CharField(max_length=20, choices=TYPE_CHOICES, db_index=True)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=10, default='USD')
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
    currency = models.CharField(max_length=10, default='USD')
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
    base_currency = models.CharField(max_length=10, default='USD')
    target_currency = models.CharField(max_length=10, db_index=True, unique=True)
    rate = models.DecimalField(max_digits=14, decimal_places=6)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['target_currency']

    def __str__(self):
        return f"1 {self.base_currency} = {self.rate} {self.target_currency} (as of {self.updated_at.strftime('%Y-%m-%d %H:%M')})"