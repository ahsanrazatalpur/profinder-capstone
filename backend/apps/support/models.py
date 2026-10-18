# apps/support/models.py
#
# Help & Support foundation: Help Center content, versioned Privacy Policy,
# and support tickets.
#
# Design notes
#   * Long-form legal / help text lives in the database (not in ARB files) so it
#     can change without an app release.
#   * It is NEVER machine-translated: every translation row carries an explicit
#     `is_reviewed` flag, and `services.resolve_translation` falls back to English
#     for any language whose text has not been human-reviewed.
#   * Published policy versions are immutable (see PolicyVersion / PolicyTranslation).
#   * Works on SQLite and PostgreSQL alike (no Postgres-only features).

from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models
from django.utils import timezone


AUDIENCE_ALL = 'all'
AUDIENCE_CUSTOMER = 'customer'
AUDIENCE_PROFESSIONAL = 'professional'
AUDIENCE_CHOICES = [
    (AUDIENCE_ALL, 'Everyone'),
    (AUDIENCE_CUSTOMER, 'Customers'),
    (AUDIENCE_PROFESSIONAL, 'Professionals'),
]


# ─── Help Center ─────────────────────────────────────────────────────────────

class HelpCategory(models.Model):
    slug      = models.SlugField(max_length=80, unique=True)
    icon_key  = models.CharField(
        max_length=60, blank=True,
        help_text="Icon key mapped to a Material icon in the app, e.g. 'payments'.")
    audience  = models.CharField(max_length=15, choices=AUDIENCE_CHOICES, default=AUDIENCE_ALL)
    order     = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['order', 'slug']
        verbose_name_plural = 'help categories'

    def __str__(self):
        return self.slug


class HelpCategoryTranslation(models.Model):
    category    = models.ForeignKey(HelpCategory, on_delete=models.CASCADE, related_name='translations')
    language    = models.ForeignKey('admin_panel.Language', on_delete=models.CASCADE,
                                    related_name='+')
    title       = models.CharField(max_length=150)
    description = models.CharField(max_length=300, blank=True)
    is_reviewed = models.BooleanField(
        default=False, help_text="Only human-reviewed text is shown; otherwise English is used.")
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('category', 'language')

    def __str__(self):
        return f'{self.category.slug} [{self.language.code}]'


class HelpArticle(models.Model):
    category     = models.ForeignKey(HelpCategory, on_delete=models.CASCADE, related_name='articles')
    slug         = models.SlugField(max_length=120, unique=True)
    audience     = models.CharField(max_length=15, choices=AUDIENCE_CHOICES, default=AUDIENCE_ALL)
    order        = models.PositiveIntegerField(default=0)
    is_published = models.BooleanField(default=False)
    created_at   = models.DateTimeField(auto_now_add=True)
    updated_at   = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['category__order', 'order', 'slug']

    def __str__(self):
        return self.slug


class HelpArticleTranslation(models.Model):
    article     = models.ForeignKey(HelpArticle, on_delete=models.CASCADE, related_name='translations')
    language    = models.ForeignKey('admin_panel.Language', on_delete=models.CASCADE,
                                    related_name='+')
    title       = models.CharField(max_length=200)
    body        = models.TextField(help_text="Plain text with simple blank-line paragraphs / '- ' bullets.")
    # Lower-cased title + body, maintained in save(); searched with icontains so
    # search works identically on SQLite and PostgreSQL.
    search_text = models.TextField(blank=True, editable=False)
    is_reviewed = models.BooleanField(
        default=False, help_text="Only human-reviewed text is shown; otherwise English is used.")
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('article', 'language')

    def save(self, *args, **kwargs):
        self.search_text = f'{self.title}\n{self.body}'.lower()
        super().save(*args, **kwargs)

    def __str__(self):
        return f'{self.article.slug} [{self.language.code}]'


# ─── Policy documents (Privacy Policy, later Terms) ──────────────────────────

class PolicyDocument(models.Model):
    TYPE_PRIVACY = 'privacy'
    TYPE_TERMS = 'terms'
    TYPE_CHOICES = [(TYPE_PRIVACY, 'Privacy Policy'), (TYPE_TERMS, 'Terms of Service')]

    doc_type   = models.CharField(max_length=15, choices=TYPE_CHOICES, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.get_doc_type_display()


class PolicyVersion(models.Model):
    """A published version is immutable: content can never be edited, only
    superseded by a newer version (or archived)."""

    STATUS_DRAFT = 'draft'
    STATUS_PUBLISHED = 'published'
    STATUS_ARCHIVED = 'archived'
    STATUS_CHOICES = [
        (STATUS_DRAFT, 'Draft'),
        (STATUS_PUBLISHED, 'Published'),
        (STATUS_ARCHIVED, 'Archived'),
    ]

    document       = models.ForeignKey(PolicyDocument, on_delete=models.CASCADE, related_name='versions')
    version_number = models.PositiveIntegerField()
    status         = models.CharField(max_length=10, choices=STATUS_CHOICES, default=STATUS_DRAFT)
    effective_date = models.DateField(null=True, blank=True)
    change_summary = models.CharField(max_length=500, blank=True)
    published_at   = models.DateTimeField(null=True, blank=True)
    created_by     = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
                                       null=True, blank=True, related_name='+')
    created_at     = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('document', 'version_number')
        ordering = ['-version_number']

    def __str__(self):
        return f'{self.document} v{self.version_number} ({self.status})'

    @property
    def is_locked(self):
        return self.status in (self.STATUS_PUBLISHED, self.STATUS_ARCHIVED)

    def save(self, *args, **kwargs):
        if self.pk:
            old = PolicyVersion.objects.filter(pk=self.pk).first()
            if old and old.is_locked:
                # Only published -> archived is allowed; nothing else may change.
                allowed = (old.status == self.STATUS_PUBLISHED
                           and self.status == self.STATUS_ARCHIVED)
                same = (old.status == self.status)
                frozen_changed = (
                    old.document_id != self.document_id
                    or old.version_number != self.version_number
                    or old.effective_date != self.effective_date
                    or old.change_summary != self.change_summary
                    or old.published_at != self.published_at
                )
                if frozen_changed or not (allowed or same):
                    raise ValidationError('A published policy version is immutable.')
        if self.status == self.STATUS_PUBLISHED and self.published_at is None:
            self.published_at = timezone.now()
        super().save(*args, **kwargs)

    def delete(self, *args, **kwargs):
        if self.is_locked:
            raise ValidationError('A published policy version cannot be deleted.')
        return super().delete(*args, **kwargs)


class PolicyTranslation(models.Model):
    version     = models.ForeignKey(PolicyVersion, on_delete=models.CASCADE, related_name='translations')
    language    = models.ForeignKey('admin_panel.Language', on_delete=models.CASCADE,
                                    related_name='+')
    title       = models.CharField(max_length=200)
    body        = models.TextField(help_text="Plain text: '# ' headings, blank-line paragraphs, '- ' bullets.")
    is_reviewed = models.BooleanField(
        default=False, help_text="Only human-reviewed text is shown; otherwise English is used.")
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('version', 'language')

    def __str__(self):
        return f'{self.version} [{self.language.code}]'

    def save(self, *args, **kwargs):
        if self.version.is_locked:
            raise ValidationError('Translations of a published policy version are immutable.')
        super().save(*args, **kwargs)

    def delete(self, *args, **kwargs):
        if self.version.is_locked:
            raise ValidationError('Translations of a published policy version are immutable.')
        return super().delete(*args, **kwargs)


# ─── Support tickets ─────────────────────────────────────────────────────────

class SupportTicket(models.Model):
    STATUS_OPEN = 'open'
    STATUS_IN_PROGRESS = 'in_progress'
    STATUS_AWAITING_USER = 'awaiting_user'
    STATUS_RESOLVED = 'resolved'
    STATUS_CLOSED = 'closed'
    STATUS_CHOICES = [
        (STATUS_OPEN, 'Open'),
        (STATUS_IN_PROGRESS, 'In progress'),
        (STATUS_AWAITING_USER, 'Awaiting user'),
        (STATUS_RESOLVED, 'Resolved'),
        (STATUS_CLOSED, 'Closed'),
    ]

    PRIORITY_CHOICES = [('low', 'Low'), ('normal', 'Normal'), ('high', 'High')]

    CATEGORY_CHOICES = [
        ('account', 'Account'),
        ('booking', 'Booking'),
        ('payment', 'Payment / withdrawal'),
        ('verification', 'Verification'),
        ('technical', 'Technical problem'),
        ('privacy', 'Privacy / data request'),
        ('feedback', 'Feedback'),
        ('other', 'Other'),
    ]

    # Generated from the primary key right after the first save, e.g. "PF-000123".
    reference   = models.CharField(max_length=20, unique=True, null=True, blank=True, editable=False)

    # SET_NULL so deleting an account never destroys the support record;
    # role / email snapshot keep it understandable for staff afterwards.
    user        = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
                                    null=True, blank=True, related_name='support_tickets')
    role        = models.CharField(max_length=20, blank=True)

    # Guest (logged-out) submissions: contact email supplied by the sender.
    contact_email = models.EmailField(blank=True)

    category    = models.CharField(max_length=20, choices=CATEGORY_CHOICES, default='other')
    subject     = models.CharField(max_length=150)
    status      = models.CharField(max_length=15, choices=STATUS_CHOICES, default=STATUS_OPEN, db_index=True)
    priority    = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='normal')
    assigned_to = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
                                    null=True, blank=True, related_name='assigned_support_tickets')
    related_booking = models.ForeignKey('bookings.Booking', on_delete=models.SET_NULL,
                                        null=True, blank=True, related_name='+')

    platform     = models.CharField(max_length=20, blank=True)
    app_version  = models.CharField(max_length=20, blank=True)
    app_language = models.CharField(max_length=10, blank=True)

    created_at       = models.DateTimeField(auto_now_add=True)
    updated_at       = models.DateTimeField(auto_now=True)
    last_activity_at = models.DateTimeField(default=timezone.now, db_index=True)
    closed_at        = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-last_activity_at']
        indexes = [models.Index(fields=['user', '-last_activity_at'], name='ticket_user_activity_idx')]

    def __str__(self):
        return f'{self.reference or "PF-?"} {self.subject[:40]}'

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        if not self.reference:
            self.reference = f'PF-{self.pk:06d}'
            SupportTicket.objects.filter(pk=self.pk).update(reference=self.reference)


class TicketMessage(models.Model):
    ticket      = models.ForeignKey(SupportTicket, on_delete=models.CASCADE, related_name='messages')
    author      = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
                                    null=True, blank=True, related_name='+')
    is_staff    = models.BooleanField(default=False)
    # Staff-only note: must never be serialized to the ticket owner.
    is_internal = models.BooleanField(default=False)
    body        = models.TextField(max_length=5000)
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f'{self.ticket.reference} #{self.pk}'


class TicketEvent(models.Model):
    """Audit trail (status changes, assignment, ...). Kept separate from
    admin_panel.AdminLog so that model's action choices stay untouched."""
    ticket     = models.ForeignKey(SupportTicket, on_delete=models.CASCADE, related_name='events')
    actor      = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
                                   null=True, blank=True, related_name='+')
    action     = models.CharField(max_length=40)
    detail     = models.CharField(max_length=300, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']
