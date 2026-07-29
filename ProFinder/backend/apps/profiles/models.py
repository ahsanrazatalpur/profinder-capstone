from django.db import models
from django.conf import settings

class UserProfile(models.Model):
    user       = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    full_name  = models.CharField(max_length=255, blank=True)
    photo_url  = models.URLField(blank=True)
    phone      = models.CharField(max_length=20, blank=True)
    city       = models.CharField(max_length=100, blank=True)
    latitude   = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude  = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.email} - Profile"


class ProfessionalProfile(models.Model):
    user             = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    bio              = models.TextField(blank=True)
    experience_years = models.IntegerField(default=0)
    hourly_rate      = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    is_verified      = models.BooleanField(default=False)
    created_at       = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.email} - Professional"