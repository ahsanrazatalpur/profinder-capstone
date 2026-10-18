# apps/bookings/models.py 

from django.db import models
from django.conf import settings


class Booking(models.Model):
    STATUS_CHOICES = [
        ('pending',   'Pending'),
        ('accepted',  'Accepted'),
        ('rejected',  'Rejected'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]

    customer      = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='bookings_made')
    professional  = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='bookings_received')
    date          = models.DateField()
    time          = models.TimeField()
    note          = models.TextField(blank=True)
    status        = models.CharField(
        max_length=20, choices=STATUS_CHOICES, default='pending')
    cancel_reason = models.TextField(blank=True)  # ✅ NEW — cancel reason
    cancelled_by  = models.CharField(             # ✅ NEW — who cancelled
        max_length=20, blank=True)                # 'customer' | 'professional' | 'admin'
    total_price   = models.DecimalField(
        max_digits=10, decimal_places=2, default=0.00)
    currency      = models.CharField(
        max_length=10, default='USD')
    payment_status = models.CharField(
        max_length=20,
        choices=[
            ('unpaid',   'Unpaid'),
            ('pending',  'Payment Pending'),
            ('paid',     'Paid'),
            ('refunded', 'Refunded'),
        ],
        default='unpaid',
        db_index=True
    )
    created_at    = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=['customer', 'status'], name='booking_cust_status_idx'),
            models.Index(fields=['professional', 'date'], name='booking_prof_date_idx'),
            models.Index(fields=['customer', '-created_at'], name='booking_cust_created_idx'),
            models.Index(fields=['professional', '-created_at'], name='booking_prof_created_idx'),
            models.Index(fields=['professional', 'date', 'time'], name='booking_slot_idx'),
        ]

    def __str__(self):
        return f"{self.customer.email} → {self.professional.email} - {self.date} - {self.status} [{self.payment_status}]"