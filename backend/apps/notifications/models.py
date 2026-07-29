from django.db import models
from django.conf import settings

class Notification(models.Model):

    TYPE_CHOICES = [
        ('payment', 'Payment'),
        ('review', 'Review'),
        ('subscription', 'Subscription'),
        ('general', 'General'),
    ]

    user      = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    title     = models.CharField(max_length=255)
    message   = models.TextField()
    type      = models.CharField(max_length=20, choices=TYPE_CHOICES, default='general')
    is_read   = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.email} - {self.title}"