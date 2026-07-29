from django.db import models
from django.conf import settings

class Payment(models.Model):
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('refunded', 'Refunded'),
    ]
    
    user      = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    amount    = models.DecimalField(max_digits=10, decimal_places=2)
    currency  = models.CharField(max_length=10, default='USD')
    stripe_id = models.CharField(max_length=255, blank=True)
    status    = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.email} - {self.amount} {self.currency} - {self.status}"


# ─── Withdrawal Request ────────────────────────────────────────────────
# Professional apni earnings withdraw karne ke liye request banata hai.
# NOTE: Ye abhi manual/admin-approved flow hai — koi real bank-transfer
# gateway (Stripe Payouts, wire transfer API, etc.) connected nahi hai.
# Admin panel se status 'approved'/'paid' karne par hi paisa asal mein
# professional ko bhejna hoga (offline ya jab gateway integrate ho).
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

    professional   = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='withdrawal_requests')
    amount         = models.DecimalField(max_digits=10, decimal_places=2)
    status         = models.CharField(max_length=20, choices=STATUS_CHOICES, default=PENDING)

    # Request ke waqt ka bank-details snapshot — agar professional baad
    # mein bank details badal de to purani requests ka record sahi rahe
    bank_account_name   = models.CharField(max_length=255, blank=True)
    bank_account_number = models.CharField(max_length=50, blank=True)
    bank_name            = models.CharField(max_length=255, blank=True)

    admin_note     = models.TextField(blank=True)
    requested_at   = models.DateTimeField(auto_now_add=True)
    processed_at   = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-requested_at']

    def __str__(self):
        return f"{self.professional.email} - ${self.amount} - {self.status}"