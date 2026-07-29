# apps/search/models.py

from django.db import models
from django.conf import settings


class Category(models.Model):
    # order field — higher professions (Doctors, Lawyers) come first
    ORDER_CHOICES = [
        (1,  'Doctors & Healthcare'),
        (2,  'Lawyers & Legal'),
        (3,  'Engineers'),
        (4,  'Architects'),
        (5,  'Accountants & Finance'),
        (6,  'IT & Tech'),
        (7,  'Tutors & Education'),
        (8,  'Plumbers'),
        (9,  'Electricians'),
        (10, 'Cleaners'),
        (11, 'Carpenters'),
        (12, 'Painters'),
        (13, 'Other'),
    ]
    name       = models.CharField(max_length=100)
    icon       = models.CharField(max_length=100, blank=True)
    order      = models.IntegerField(default=99)  # Lower = shown first
    # Admin-controlled "Featured Categories" flag — Guest Home shows only
    # is_featured=True categories (max 6), never a random/arbitrary subset.
    is_featured = models.BooleanField(default=False)
    parent     = models.ForeignKey(
        'self', on_delete=models.CASCADE, null=True, blank=True
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['order', 'name']  # Auto sort by order

    def __str__(self):
        return self.name


class SubCategory(models.Model):
    category   = models.ForeignKey(Category, on_delete=models.CASCADE)
    name       = models.CharField(max_length=100)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.category.name} → {self.name}"


# ✅ NEW — server-side favourites. Previously favourites only lived on-device
# (SharedPreferences in favorites_store.dart), which meant they couldn't be
# used as a signal anywhere server-side (e.g. "Trending" scoring) and didn't
# sync across a customer's devices. This mirrors that store's shape closely
# so the Flutter side can add backend sync without changing its public API.
class Favorite(models.Model):
    customer     = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='favorites')
    professional = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='favorited_by')
    created_at   = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('customer', 'professional')
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.customer.email} ♥ {self.professional.email}"