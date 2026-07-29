# apps/admin_panel/models.py

from django.db import models
from django.conf import settings


class AdminLog(models.Model):
    ACTION_CHOICES = [
        ('verify',          'Verify Professional'),
        ('ban',             'Ban User'),
        ('unban',           'Unban User'),
        ('delete',          'Delete Content'),
        ('approve',         'Approve Portfolio'),
        ('reject',          'Reject Portfolio'),
        ('cancel_booking',  'Cancel Booking'),
        ('create_banner',   'Create Banner'),
        ('edit_banner',     'Edit Banner'),
        ('remind',          'Send Reminder'),
        ('report_reviewed', 'Report Reviewed'),
        ('report_dismissed','Report Dismissed'),
    ]
    admin       = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='admin_logs')
    action      = models.CharField(max_length=20, choices=ACTION_CHOICES)
    target_user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='admin_actions', null=True, blank=True)
    note        = models.TextField(blank=True)
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        target = self.target_user.email if self.target_user else 'N/A'
        return f"{self.admin.email} → {self.action} → {target}"


class Complaint(models.Model):
    """
    Service/booking-dispute complaints — distinct from UserReport (which is
    user-safety/Trust&Safety). A complaint is about a specific job going
    wrong (no-show, bad service, payment dispute), not about the person's
    conduct in general.
    """
    CATEGORY_CHOICES = [
        ('service_quality',  'Service Quality'),
        ('no_show',          'No Show'),
        ('payment_dispute',  'Payment Dispute'),
        ('other',            'Other'),
    ]
    STATUS_CHOICES = [
        ('open',        'Open'),
        ('in_progress', 'In Progress'),
        ('resolved',    'Resolved'),
        ('rejected',    'Rejected'),
    ]

    complainant  = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='complaints_made')
    against      = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='complaints_received')
    booking      = models.ForeignKey(
        'bookings.Booking', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='complaints')

    category     = models.CharField(max_length=30, choices=CATEGORY_CHOICES)
    description  = models.TextField()
    status       = models.CharField(max_length=20, choices=STATUS_CHOICES, default='open')

    assigned_to      = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='complaints_assigned')
    resolution_note  = models.TextField(blank=True)
    resolved_at      = models.DateTimeField(null=True, blank=True)

    created_at   = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status'], name='complaint_status_idx'),
        ]

    def __str__(self):
        return f"{self.complainant.email} → {self.against.email} ({self.category})"


class NotificationBroadcast(models.Model):
    """
    Admin-composed broadcast notifications — distinct from the per-user
    `Notification` model in apps.notifications (which is the individual
    inbox row). One NotificationBroadcast fans out into many individual
    Notification rows (one per targeted user) when sent.

    Scheduling note: this stores intent (scheduled_at) — actual dispatch
    at that time needs a periodic task runner (cron/celery beat) calling
    the `send_scheduled_broadcasts` management command, since this project
    doesn't have one wired up yet. "Send Now" works immediately without
    any extra infra.
    """
    AUDIENCE_CHOICES = [
        ('all',           'All Users'),
        ('customers',     'Customers'),
        ('professionals', 'Professionals'),
        ('specific',      'Specific User'),
    ]
    STATUS_CHOICES = [
        ('scheduled', 'Scheduled'),
        ('sent',      'Sent'),
        ('cancelled', 'Cancelled'),
        ('failed',    'Failed'),
    ]

    title        = models.CharField(max_length=255)
    message      = models.TextField()
    audience     = models.CharField(max_length=20, choices=AUDIENCE_CHOICES, default='all')
    specific_user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='targeted_broadcasts')

    status       = models.CharField(max_length=20, choices=STATUS_CHOICES, default='scheduled')
    scheduled_at = models.DateTimeField(null=True, blank=True)  # null = send immediately
    sent_at      = models.DateTimeField(null=True, blank=True)

    sent_count   = models.PositiveIntegerField(default=0)
    opened_count = models.PositiveIntegerField(default=0)  # best-effort, see AdminNotificationListView

    created_by   = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='broadcasts_created')
    created_at   = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.title} → {self.get_audience_display()} ({self.status})"


class Country(models.Model):
    """
    Content Management → Countries. Master list — lets admin enable a
    country for onboarding *before* any user has one on their profile
    (UserProfile.country stays free-text; this table is the canonical
    reference + activation switch, not a hard FK — merging typos into a
    canonical spelling happens via AdminCountryMergeView).
    """
    STATUS_CHOICES = [('active', 'Active'), ('coming_soon', 'Coming Soon')]

    name       = models.CharField(max_length=100, unique=True)
    status     = models.CharField(max_length=15, choices=STATUS_CHOICES, default='coming_soon')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return self.name


class City(models.Model):
    """Content Management → Cities. Nested under a Country (design spec:
    'a city without its country context is meaningless')."""
    STATUS_CHOICES = [('active', 'Active'), ('coming_soon', 'Coming Soon')]

    name       = models.CharField(max_length=100)
    country    = models.ForeignKey(Country, on_delete=models.CASCADE, related_name='cities')
    status     = models.CharField(max_length=15, choices=STATUS_CHOICES, default='coming_soon')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['name']
        unique_together = ('name', 'country')

    def __str__(self):
        return f"{self.name}, {self.country.name}"


class Announcement(models.Model):
    """
    Content Management → Announcements. Platform-wide in-app messages
    (maintenance notice, policy update) — persistent state, unlike
    Notifications (push, fire-and-forget). Type drives visual severity
    automatically on the frontend (info=blue, warning=amber, maintenance=red).
    """
    TYPE_CHOICES = [
        ('info',        'Info'),
        ('warning',     'Warning'),
        ('maintenance', 'Maintenance'),
    ]
    AUDIENCE_CHOICES = [
        ('all',           'All Users'),
        ('customers',     'Customers'),
        ('professionals', 'Professionals'),
    ]

    title      = models.CharField(max_length=255)
    message    = models.TextField()
    type       = models.CharField(max_length=15, choices=TYPE_CHOICES, default='info')
    audience   = models.CharField(max_length=20, choices=AUDIENCE_CHOICES, default='all')
    is_active  = models.BooleanField(default=True)
    start_date = models.DateTimeField(null=True, blank=True)
    end_date   = models.DateTimeField(null=True, blank=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='announcements_created')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.type}] {self.title}"


class Language(models.Model):
    """
    Content Management → Languages. A language only reaches 'active' once
    100% of TranslationKeys have non-empty text — enforced in the view,
    not here, so the admin gets a clear error message instead of a silent
    DB constraint failure.
    """
    STATUS_CHOICES = [
        ('active',   'Active'),
        ('beta',     'Beta'),
        ('disabled', 'Disabled'),
    ]

    name       = models.CharField(max_length=50)
    code       = models.CharField(max_length=10, unique=True)  # e.g. 'en', 'ur'
    is_rtl     = models.BooleanField(default=False)
    status     = models.CharField(max_length=10, choices=STATUS_CHOICES, default='beta')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return f"{self.name} ({self.code})"


class TranslationKey(models.Model):
    """
    A single translatable string identifier used across the app, e.g.
    'home.welcome_message'. Language-independent — one row per phrase,
    however many languages exist.
    """
    key         = models.CharField(max_length=255, unique=True)
    description = models.CharField(max_length=255, blank=True)  # context for translators
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['key']

    def __str__(self):
        return self.key


class TranslationString(models.Model):
    """The actual translated text for one (language, key) pair."""
    language   = models.ForeignKey(Language, on_delete=models.CASCADE, related_name='translations')
    key        = models.ForeignKey(TranslationKey, on_delete=models.CASCADE, related_name='translations')
    text       = models.TextField(blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('language', 'key')

    def __str__(self):
        return f"[{self.language.code}] {self.key.key}"


class UserReport(models.Model):
    """
    Trust & Safety: koi bhi authenticated user (customer/professional) kisi
    dusre user ko report kar sakta hai (spam, harassment, fraud, fake profile,
    etc.). Admin panel ke "Reported Users" card + screen isi model se
    populate hote hain.
    """
    REASON_CHOICES = [
        ('spam',                   'Spam'),
        ('harassment',             'Harassment or Abuse'),
        ('fraud',                  'Fraud or Scam'),
        ('fake_profile',           'Fake Profile'),
        ('inappropriate_content',  'Inappropriate Content'),
        ('other',                  'Other'),
    ]
    STATUS_CHOICES = [
        ('pending',      'Pending Review'),
        ('reviewed',     'Reviewed'),
        ('action_taken', 'Action Taken'),
        ('dismissed',    'Dismissed'),
    ]

    reporter      = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='admin_reports_made')
    reported_user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='admin_reports_received')
    reason        = models.CharField(max_length=30, choices=REASON_CHOICES)
    description   = models.TextField(blank=True)
    status        = models.CharField(
        max_length=20, choices=STATUS_CHOICES, default='pending')

    admin_note    = models.TextField(blank=True)
    reviewed_by   = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='reports_reviewed')
    reviewed_at   = models.DateTimeField(null=True, blank=True)

    created_at    = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status'], name='report_status_idx'),
            models.Index(fields=['reported_user'], name='report_target_idx'),
        ]

    def __str__(self):
        return f"{self.reporter.email} → reported → {self.reported_user.email} ({self.reason})"


class PromoBanner(models.Model):
    """
    Admin panel se popup advertisements manage karo.
    Fully configurable per document requirements.
    """
    # ── Target Audience ───────────────────────────────────────────────────────
    TARGET_CHOICES = [
        ('everyone',          'Everyone'),
        ('guest',             'Guest Only'),
        ('free_customer',     'Free Customer'),
        ('premium_customer',  'Premium Customer'),
        ('free_professional', 'Free Professional'),
        ('premium_professional', 'Premium Professional'),
        ('all_customers',     'All Customers'),
        ('all_professionals', 'All Professionals'),
    ]

    # ── Trigger ───────────────────────────────────────────────────────────────
    TRIGGER_CHOICES = [
        ('app_open',      'App Open'),
        ('home',          'Home Page'),
        ('search',        'Search Page'),
        ('ai_search',     'AI Search'),
        ('booking',       'Booking'),
        ('login',         'After Login'),
        ('every_x_days',  'Every X Days'),
    ]

    # ── Button Link Type ──────────────────────────────────────────────────────
    LINK_TYPE_CHOICES = [
        ('subscription',   'Subscription Page'),
        ('category',       'Specific Category'),
        ('external_url',   'External URL'),
        ('offer',          'Offer Page'),
        ('none',           'No Action'),
    ]

    title         = models.CharField(max_length=200)
    description   = models.TextField()
    image_url     = models.URLField(blank=True)          # optional banner image
    button_text   = models.CharField(max_length=100, default='Get Premium')
    button_link_type = models.CharField(
        max_length=20, choices=LINK_TYPE_CHOICES, default='subscription')
    button_link_value = models.CharField(
        max_length=500, blank=True)                      # URL / category_id / etc.

    target_audience = models.CharField(
        max_length=30, choices=TARGET_CHOICES, default='everyone')
    trigger         = models.CharField(
        max_length=20, choices=TRIGGER_CHOICES, default='home')
    trigger_x_days  = models.IntegerField(
        default=3,
        help_text="trigger=every_x_days hone par: har X din baad show karo")

    is_active  = models.BooleanField(default=False)
    priority   = models.IntegerField(default=0, help_text="High = pehle dikhao")
    start_date = models.DateTimeField(null=True, blank=True)
    end_date   = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-priority', '-updated_at']

    def __str__(self):
        status_icon = '✅' if self.is_active else '❌'
        return f"{status_icon} [{self.target_audience}] {self.title}"

    def is_currently_active(self):
        """Schedule check karta hai — active hai aur schedule ke andar hai."""
        from django.utils import timezone
        if not self.is_active:
            return False
        now = timezone.now()
        if self.start_date and now < self.start_date:
            return False
        if self.end_date and now > self.end_date:
            return False
        return True