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
    created_at    = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.customer.email} → {self.professional.email} - {self.date} - {self.status}"