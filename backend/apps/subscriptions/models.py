# apps/subscriptions/models.py


from django.db import models
from django.conf import settings


class SubscriptionPlan(models.Model):
    """
    Customer aur Professional dono ke liye plans.
    type field se pata chalega ye plan kiske liye hai.
    """
    PLAN_TYPE_CHOICES = [
        ('customer',     'Customer'),
        ('professional', 'Professional'),
    ]
    BILLING_CHOICES = [
        ('free',    'Free'),
        ('monthly', 'Monthly'),
        ('yearly',  'Yearly'),
    ]

    name         = models.CharField(max_length=100)           # e.g. "Free", "Premium Monthly"
    plan_type    = models.CharField(max_length=20, choices=PLAN_TYPE_CHOICES)
    billing      = models.CharField(max_length=20, choices=BILLING_CHOICES, default='free')
    price        = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    currency     = models.CharField(max_length=10, default='PKR')
    duration_days= models.IntegerField(default=0)             # 0 = forever (free plan)
    is_active    = models.BooleanField(default=True)          # Admin disable kar sakta hai
    created_at   = models.DateTimeField(auto_now_add=True)
    updated_at   = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['plan_type', 'price']

    def __str__(self):
        return f"[{self.plan_type}] {self.name} — {self.currency} {self.price}"

    def get_feature(self, key, default=None):
        """Kisi bhi feature ki value shortcut se lo."""
        try:
            return self.features.get(key=key).value
        except PlanFeature.DoesNotExist:
            return default


class PlanFeature(models.Model):
    """
    Har plan ki har limit/feature yahan DB mein store hogi.
    Admin kabhi bhi change kar sakta hai — no hardcoding.

    Keys used in system:
    ── Customer ──────────────────────────────────────────────
    ai_search_limit      : int  — daily AI searches (0=unlimited)
    message_send_limit   : int  — daily messages (0=unlimited)
    ads_enabled          : bool — 1=ads dikhao, 0=hide
    priority_support     : bool
    premium_badge        : bool
    ── Professional ──────────────────────────────────────────
    booking_limit        : int  — monthly bookings (0=unlimited)
    portfolio_limit      : int  — max portfolio images (0=unlimited)
    service_limit        : int  — max services (0=unlimited)
    message_send_limit   : int  — daily messages (0=unlimited)
    ads_enabled          : bool
    featured_profile     : bool
    priority_ranking     : bool
    premium_badge        : bool
    """
    FEATURE_TYPE_CHOICES = [
        ('int',  'Integer'),
        ('bool', 'Boolean'),
        ('str',  'String'),
    ]

    plan         = models.ForeignKey(
        SubscriptionPlan, on_delete=models.CASCADE, related_name='features')
    key          = models.CharField(max_length=100)   # e.g. 'ai_search_limit'
    value        = models.CharField(max_length=255)   # stored as string, cast on use
    feature_type = models.CharField(
        max_length=10, choices=FEATURE_TYPE_CHOICES, default='int')
    label        = models.CharField(max_length=255, blank=True)  # human readable

    class Meta:
        unique_together = ('plan', 'key')

    def __str__(self):
        return f"{self.plan.name} | {self.key} = {self.value}"

    def as_int(self):
        try:
            return int(self.value)
        except (ValueError, TypeError):
            return 0

    def as_bool(self):
        return str(self.value).lower() in ('1', 'true', 'yes')


class Subscription(models.Model):
    """
    User (customer ya professional) ka active plan.
    """
    STATUS_CHOICES = [
        ('active',    'Active'),
        ('expired',   'Expired'),
        ('cancelled', 'Cancelled'),
    ]

    user       = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='subscriptions'
    )
    plan       = models.ForeignKey(SubscriptionPlan, on_delete=models.CASCADE)
    status     = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    start_date = models.DateTimeField(auto_now_add=True)
    end_date   = models.DateTimeField(null=True, blank=True)  # null = forever (free)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-start_date']

    def __str__(self):
        return f"{self.user.email} — {self.plan.name} [{self.status}]"

    def is_valid(self):
        """Active hai aur expire nahi hua."""
        from django.utils import timezone
        if self.status != 'active':
            return False
        if self.end_date and self.end_date < timezone.now():
            return False
        return True
