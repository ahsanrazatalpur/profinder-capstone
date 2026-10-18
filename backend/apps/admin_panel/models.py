# apps/admin_panel/models.py

from django.db import models
from django.conf import settings
from django.db.models import Q
from django.utils import timezone
from django.db.models.signals import post_delete


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
        # Trust & Safety Part 4 — moderation actions (see ModerationAction).
        ('moderation_action',   'Moderation Action Created'),
        ('moderation_reversed', 'Moderation Action Reversed'),
        # Trust & Safety Part 6 — appeals against moderation actions.
        ('appeal_approved',     'Appeal Approved'),
        ('appeal_rejected',     'Appeal Rejected'),
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

    NOTE: A report is an allegation only — it is never automatic proof of
    wrongdoing, and creating/receiving reports must never, by itself,
    trigger any automatic enforcement. Moderation actions, suspensions,
    bans, restrictions, appeals, and notifications are handled by later
    parts of the Trust & Safety system, not by this model.
    """
    # ── Category / reason ───────────────────────────────────────────────────
    # Existing codes ('spam', 'harassment', 'fraud', 'fake_profile',
    # 'inappropriate_content', 'other') are preserved as-is so existing
    # report rows and any code referencing these values keep working.
    # Only their display labels were tightened, plus new codes appended.
    REASON_CHOICES = [
        ('spam',                   'Spam'),
        ('harassment',             'Harassment or Abuse'),
        ('fraud',                  'Fraud / Scam'),
        ('fake_profile',           'Fake Profile / Identity'),
        ('inappropriate_content',  'Inappropriate Content'),
        ('payment_fraud',          'Payment Fraud'),
        ('off_platform_payment',   'Off-Platform Payment Request'),
        ('threats_safety',         'Threats / Safety Concern'),
        ('discrimination',         'Discrimination'),
        ('service_misconduct',     'Service-Related Misconduct'),
        ('other',                  'Other'),
    ]

    # ── Status workflow (unchanged values — kept fully backward compatible;
    # future moderation parts can extend this list without touching
    # existing rows, since it's a plain CharField choice set). ─────────────
    STATUS_CHOICES = [
        ('pending',      'Pending Review'),
        ('reviewed',     'Reviewed'),
        ('action_taken', 'Action Taken'),
        ('dismissed',    'Dismissed'),
    ]

    # ── Severity / priority ─────────────────────────────────────────────────
    SEVERITY_LOW      = 'low'
    SEVERITY_MEDIUM   = 'medium'
    SEVERITY_HIGH     = 'high'
    SEVERITY_CRITICAL = 'critical'
    SEVERITY_CHOICES = [
        (SEVERITY_LOW,      'Low'),
        (SEVERITY_MEDIUM,   'Medium'),
        (SEVERITY_HIGH,     'High'),
        (SEVERITY_CRITICAL, 'Critical'),
    ]

    # ── Core parties & category ─────────────────────────────────────────────
    reporter      = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='admin_reports_made')
    reported_user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='admin_reports_received')
    reason        = models.CharField(max_length=30, choices=REASON_CHOICES)
    description   = models.TextField(blank=True)

    # ── Workflow state ───────────────────────────────────────────────────────
    status        = models.CharField(
        max_length=20, choices=STATUS_CHOICES, default='pending')
    severity      = models.CharField(
        max_length=10, choices=SEVERITY_CHOICES, default=SEVERITY_MEDIUM,
        help_text="Moderation priority. Set by admins during review — "
                   "reports don't self-escalate based on volume.")

    # ── Evidence / reference information ────────────────────────────────────
    # Deliberately just a reference, not a blob: a link to an attachment
    # already stored via existing storage (e.g. a chat attachment URL,
    # media file URL, or external reference) rather than duplicating raw
    # files/content inside this table.
    evidence_url  = models.URLField(
        max_length=500, blank=True,
        help_text="Optional link/reference to supporting evidence "
                   "(e.g. an existing chat attachment or media URL).")

    # ── Optional related context ────────────────────────────────────────────
    # String references avoid a hard import dependency between apps.
    related_booking = models.ForeignKey(
        'bookings.Booking', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='trust_safety_reports',
        help_text="Booking/service this report relates to, if any.")
    related_message = models.ForeignKey(
        'messaging.Message', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='trust_safety_reports',
        help_text="Specific message this report is evidence against, if any.")

    # ── Admin review information ────────────────────────────────────────────
    admin_note    = models.TextField(blank=True)
    reviewed_by   = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='reports_reviewed')
    reviewed_at   = models.DateTimeField(null=True, blank=True)

    # ── Timestamps ───────────────────────────────────────────────────────────
    created_at    = models.DateTimeField(auto_now_add=True)
    updated_at    = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status'], name='report_status_idx'),
            models.Index(fields=['reported_user'], name='report_target_idx'),
            models.Index(fields=['severity'], name='report_severity_idx'),
        ]

    def __str__(self):
        return f"{self.reporter.email} → reported → {self.reported_user.email} ({self.reason})"


class ModerationAction(models.Model):
    """
    Trust & Safety: the actual administrative action record taken against a
    user — separate from UserReport (which is just an allegation). Creating
    a ModerationAction row here does NOT, by itself, enforce anything yet
    (it does not flip User.is_active, block messaging, etc.) — that
    enforcement layer is a later part. This part only establishes the
    audit-trail model: who did what, to whom, why, and for how long.
    """
    ACTION_WARNING              = 'warning'
    ACTION_RESTRICT_MESSAGING   = 'restrict_messaging'
    ACTION_RESTRICT_BOOKING     = 'restrict_booking'
    ACTION_SUSPEND_TEMPORARY    = 'suspend_temporary'
    ACTION_SUSPEND_PERMANENT    = 'suspend_permanent'
    ACTION_CHOICES = [
        (ACTION_WARNING,            'Warning'),
        (ACTION_RESTRICT_MESSAGING, 'Restrict Messaging'),
        (ACTION_RESTRICT_BOOKING,   'Restrict Booking'),
        (ACTION_SUSPEND_TEMPORARY,  'Temporary Suspension'),
        (ACTION_SUSPEND_PERMANENT,  'Permanent Suspension'),
    ]

    # ── What this action is about ───────────────────────────────────────────
    # Optional: an admin can act directly (e.g. off-platform evidence) even
    # when no UserReport exists yet.
    report        = models.ForeignKey(
        UserReport, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='moderation_actions',
        help_text="Report this action was taken in response to, if any. "
                   "Optional — admins can act directly without a report.")
    target_user   = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='moderation_actions_received',
        help_text="User this action is taken against. Always required.")
    performed_by  = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='moderation_actions_taken',
        help_text="Admin who performed the action, kept for auditability "
                   "even if that admin account is later removed.")

    # ── What was done and why ────────────────────────────────────────────────
    action_type   = models.CharField(max_length=30, choices=ACTION_CHOICES)
    reason        = models.TextField(
        help_text="Required rationale for this specific action.")
    admin_note    = models.TextField(
        blank=True, help_text="Optional additional internal note.")

    # ── Timing ───────────────────────────────────────────────────────────────
    starts_at     = models.DateTimeField(
        default=timezone.now,
        help_text="When this action takes/took effect.")
    expires_at    = models.DateTimeField(
        null=True, blank=True,
        help_text="Required for temporary suspensions; must be left blank "
                   "for permanent suspensions. Optional (usually blank) for "
                   "warnings and restrictions.")
    is_active     = models.BooleanField(
        default=True,
        help_text="Whether this action is currently in effect. Toggled by "
                   "admins (or, later, an expiry job) — not auto-managed yet.")

    # ── Reversal audit trail (Part 4) ────────────────────────────────────────
    # Reversing an action NEVER deletes it: is_active flips to False and the
    # who/when/why below is recorded, so the full history stays reviewable.
    # All four are written only by server-side logic (apps.admin_panel
    # .moderation.reverse_moderation_action), never taken from client input.
    reversed_at      = models.DateTimeField(null=True, blank=True)
    reversed_by      = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='moderation_actions_reversed',
        help_text="Admin who reversed this action, if it was reversed.")
    reversal_reason  = models.TextField(blank=True)
    legacy_ban_applied = models.BooleanField(
        default=False,
        help_text="True only when this record was created by the legacy "
                   "report 'ban_user' flow, which also set User.is_active=False. "
                   "Reversing such a record restores the account too, so the two "
                   "never disagree.")

    created_at    = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['target_user', 'is_active'], name='modaction_target_active_idx'),
            models.Index(fields=['is_active', 'expires_at'], name='modaction_active_expiry_idx'),
            models.Index(fields=['action_type'], name='modaction_type_idx'),
        ]
        constraints = [
            # Temporary suspensions must carry an expiry.
            models.CheckConstraint(
                condition=~Q(action_type='suspend_temporary') | Q(expires_at__isnull=False),
                name='modaction_temp_suspension_requires_expiry',
            ),
            # Permanent suspensions must NOT carry an expiry.
            models.CheckConstraint(
                condition=~Q(action_type='suspend_permanent') | Q(expires_at__isnull=True),
                name='modaction_permanent_suspension_no_expiry',
            ),
        ]

    def clean(self):
        from django.core.exceptions import ValidationError
        if self.action_type == self.ACTION_SUSPEND_TEMPORARY and not self.expires_at:
            raise ValidationError(
                {'expires_at': 'Temporary suspensions require an expiration timestamp.'})
        if self.action_type == self.ACTION_SUSPEND_PERMANENT and self.expires_at:
            raise ValidationError(
                {'expires_at': 'Permanent suspensions must not have an expiration timestamp.'})

    def __str__(self):
        return f"{self.get_action_type_display()} → {self.target_user.email} (by {self.performed_by.email if self.performed_by else 'system'})"


class Appeal(models.Model):
    """
    Trust & Safety: an affected user's request for an admin to re-examine a
    moderation action taken against THEM.

    An appeal is a request, never a verdict and never enforcement:
      * creating one changes nothing about the action (it stays in force
        while the appeal is pending);
      * only an admin decision changes anything, and only through the
        existing moderation logic (apps.admin_panel.appeals ->
        moderation.reverse_moderation_action) — this model has no side
        effects of its own.

    History is never deleted: a decided appeal keeps its row, the deciding
    admin, the internal note and both timestamps. `moderation_action` is
    PROTECT so an action that has an appeal on record can't be deleted out
    from under it.

    Every field below the "user input" block is written by server logic only;
    the submit serializer doesn't declare them, so a client can't set them.
    """
    STATUS_PENDING  = 'pending'
    STATUS_APPROVED = 'approved'
    STATUS_REJECTED = 'rejected'
    STATUS_CHOICES = [
        (STATUS_PENDING,  'Pending Review'),
        (STATUS_APPROVED, 'Approved'),
        (STATUS_REJECTED, 'Rejected'),
    ]

    # ── Who / what ───────────────────────────────────────────────────────────
    user              = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='moderation_appeals',
        help_text="The affected user who submitted the appeal. Always the "
                   "target of the moderation action.")
    moderation_action = models.ForeignKey(
        ModerationAction, on_delete=models.PROTECT,
        related_name='appeals',
        help_text="The action being appealed. Must belong to `user`.")
    report            = models.ForeignKey(
        UserReport, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='appeals',
        help_text="Report behind the appealed action, if any. Copied from the "
                   "action by the server at submission — never supplied by the "
                   "user, and never shown to the appealing user.")

    # ── User input ───────────────────────────────────────────────────────────
    reason            = models.TextField(
        help_text="The user's explanation of why the action should be reviewed.")
    evidence_url      = models.URLField(
        max_length=500, blank=True,
        help_text="Optional http(s) link to supporting evidence. A reference "
                   "only, mirroring UserReport.evidence_url.")

    # ── Server-controlled review state ───────────────────────────────────────
    status            = models.CharField(
        max_length=10, choices=STATUS_CHOICES, default=STATUS_PENDING)
    reviewed_by       = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='appeals_reviewed',
        help_text="Admin who approved/rejected it. Never shown to the user.")
    decision_note     = models.TextField(
        blank=True,
        help_text="INTERNAL admin note about the decision. Never exposed to "
                   "the appealing user or included in any notification.")
    created_at        = models.DateTimeField(auto_now_add=True)
    resolved_at       = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status', 'created_at'], name='appeal_status_created_idx'),
            models.Index(fields=['user', 'status'],        name='appeal_user_status_idx'),
        ]
        constraints = [
            # At most ONE pending appeal per action, enforced by the database
            # so it holds even if two requests race past the friendly check.
            models.UniqueConstraint(
                fields=['moderation_action'],
                condition=Q(status='pending'),
                name='appeal_one_pending_per_action',
            ),
            # Status and resolved_at can never disagree.
            models.CheckConstraint(
                condition=(Q(status='pending', resolved_at__isnull=True) |
                           (~Q(status='pending') & Q(resolved_at__isnull=False))),
                name='appeal_resolved_at_matches_status',
            ),
        ]

    def __str__(self):
        return f"Appeal #{self.pk} by {self.user.email} ({self.status})"


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


# ─── Content translations (generic) ───────────────────────────────────────────
# Ek hi table har admin-authored text ki translation rakhta hai (announcement,
# promo banner, aur aage category/article/city...). Naya translatable model
# add karna = sirf TRANSLATABLE_FIELDS mein ek entry — koi nayi table/migration
# nahi. Base (English) text parent row par hi rehta hai; translation na ho ya
# khali ho to wohi base text fallback ke taur par dikhta hai (About page jaisa).

TRANSLATABLE_FIELDS = {
    'announcement': ('title', 'message'),
    'promobanner':  ('title', 'description', 'button_text'),
    'category':     ('name',),
    'subcategory':  ('name',),
    'notificationbroadcast': ('title', 'message'),
}

DEFAULT_CONTENT_LANG = 'en'


def normalize_lang(value):
    """'UR', ' ur-PK ', 'ur_PK' → 'ur'. Khali/None → None."""
    if not value:
        return None
    code = str(value).strip().lower().replace('_', '-').split('-')[0]
    return code or None


class ContentTranslation(models.Model):
    model_label = models.CharField(
        max_length=40, help_text="Parent model ka naam, lowercase — e.g. 'announcement'.")
    object_id   = models.PositiveIntegerField()
    field       = models.CharField(max_length=40)
    language    = models.ForeignKey(
        Language, on_delete=models.CASCADE, related_name='content_translations')
    text        = models.TextField()
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('model_label', 'object_id', 'field', 'language')
        indexes = [
            models.Index(fields=['model_label', 'object_id'], name='content_tr_obj_idx'),
        ]

    def __str__(self):
        return f"[{self.language.code}] {self.model_label}#{self.object_id}.{self.field}"

    @classmethod
    def localize_rows(cls, label, rows, lang, prefix=None):
        """
        Public read path. `rows` = already-serialized dicts (each with 'id').
        Returns a NEW list. Ek hi DB query poori list ke liye.

        prefix=None  → translatable fields seedha replace hote hain (translation
                       ho to), warna base text rehta hai. (announcements, promos)
        prefix='localized_' → original field untouched rehta hai, aur har row
                       mein 'localized_<field>' hamesha milta hai (translation ya
                       base fallback). Categories ke liye — kyunke `name` search
                       aur purane client ke liye English hi rehna chahiye.
        """
        rows = [dict(r) for r in rows]
        fields = TRANSLATABLE_FIELDS.get(label)
        if not fields:
            return rows
        lang = normalize_lang(lang)
        found = {}
        if rows and lang and lang != DEFAULT_CONTENT_LANG:
            qs = cls.objects.filter(
                model_label=label,
                object_id__in=[r['id'] for r in rows],
                language__code__iexact=lang,
                field__in=fields,
            ).exclude(text='')
            for t in qs:
                found[(t.object_id, t.field)] = t.text
        for r in rows:
            for f in fields:
                text = found.get((r['id'], f))
                if prefix:
                    r[prefix + f] = text or r.get(f, '')
                elif text:
                    r[f] = text
        return rows

    @classmethod
    def for_object(cls, label, object_id):
        """
        Ek object ki saari translations: {'ur': {'title': .., 'message': ..}, ...}
        (lowercase language code). Ek hi DB query — broadcast/announcement push
        mein har receiver ke liye dobara query na karni pade.
        """
        out = {}
        qs = cls.objects.filter(
            model_label=label, object_id=object_id).select_related('language')
        for t in qs:
            out.setdefault(t.language.code.lower(), {})[t.field] = t.text
        return out

    @classmethod
    def attach_rows(cls, label, rows):
        """
        Admin read path. Har row mein 'translations' list lagata hai:
        [{'language': <id>, 'language_code': 'ur', 'title': ..., 'message': ...}]
        Ek hi DB query poori list ke liye.
        """
        rows = [dict(r) for r in rows]
        grouped = {}
        qs = cls.objects.filter(
            model_label=label, object_id__in=[r['id'] for r in rows],
        ).select_related('language')
        for t in qs:
            per_lang = grouped.setdefault(t.object_id, {})
            entry = per_lang.setdefault(t.language_id, {
                'language': t.language_id, 'language_code': t.language.code})
            entry[t.field] = t.text
        for r in rows:
            r['translations'] = list(grouped.get(r['id'], {}).values())
        return rows


def _delete_content_translations(sender, instance, **kwargs):
    """Parent delete hone par uski translations bhi saaf (generic FK nahi hai)."""
    ContentTranslation.objects.filter(
        model_label=sender._meta.model_name, object_id=instance.pk).delete()


for _model in (Announcement, PromoBanner, NotificationBroadcast):
    post_delete.connect(
        _delete_content_translations, sender=_model,
        dispatch_uid=f'content_tr_cleanup_{_model._meta.model_name}')

# search app ke models lazy string se connect — import cycle se bachne ke liye.
for _ref in ('search.Category', 'search.SubCategory'):
    post_delete.connect(
        _delete_content_translations, sender=_ref,
        dispatch_uid=f'content_tr_cleanup_{_ref}')