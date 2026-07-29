# apps/about_page/models.py
"""
About Page CMS.

Design intent
──────────────
Every one of the 16 sections in the spec (Hero Banner, Company Story,
Mission, Vision, Why Choose Us, How It Works, Statistics, Core Values,
Team Members, Investors & Partners, Certifications, Awards, Contact
Information, Social Media Links, App Information, Legal Links) is a row
in `AboutSection`, not a hardcoded model/field. That's what makes the
system modular: adding a 17th section later ("Press Mentions", say) is
an admin action (create a section with a new `section_key`), never a
migration or a code change. `SECTION_TYPE_CHOICES` below exists only to
drive nicer admin dropdowns/icons — it is deliberately not enforced as
the only legal values, so a `section_type='custom'` section still works
end-to-end through every view, serializer, and the Flutter renderer.

Sections that need repeatable sub-content (Why Choose Us cards, How It
Works steps, Statistics counters, Team Members, Investors & Partners,
Certifications, Awards, Core Values) attach unlimited `AboutSectionItem`
rows — one generic child model instead of eight near-identical ones.
`extra_data` (JSON) on both models absorbs section/item-specific fields
(e.g. a team member's LinkedIn handle, an award's year, a stat's
suffix like "+") without ever needing a schema change.

Multilingual content lives in separate translation tables keyed to the
existing `apps.admin_panel.Language` model (already used for the app's
translation system) rather than reinventing language management here.

Publishing is page-wide, not per-section: an admin edits sections in
Draft, and only a `publish` action snapshots the *entire* page
(sections + items + translations + SEO) into an `AboutPageVersion`.
Restoring a version replays that snapshot back onto the live tables —
so restore itself creates a new version rather than deleting history.
"""

from django.conf import settings
from django.db import models

from apps.admin_panel.models import Language


# ─── Choices ──────────────────────────────────────────────────────────────────

SECTION_TYPE_CHOICES = [
    ('hero_banner',         'Hero Banner'),
    ('company_story',       'Company Story'),
    ('mission',             'Mission'),
    ('vision',              'Vision'),
    ('why_choose_us',       'Why Choose Us'),
    ('how_it_works',        'How It Works'),
    ('statistics',          'Statistics'),
    ('core_values',         'Core Values'),
    ('team_members',        'Team Members'),
    ('investors_partners',  'Investors & Partners'),
    ('certifications',      'Certifications'),
    ('awards',               'Awards'),
    ('contact_info',        'Contact Information'),
    ('social_media',        'Social Media Links'),
    ('app_info',            'App Information'),
    ('legal_links',         'Legal Links'),
    ('custom',              'Custom Section'),
]

# Section types that render as a repeatable list of AboutSectionItem rows.
# Purely descriptive (used by the admin UI to decide whether to show the
# "Items" tab) — nothing in the backend actually blocks items on other
# section types, keeping the door open for future section designs.
COLLECTION_SECTION_TYPES = {
    'why_choose_us', 'how_it_works', 'statistics', 'core_values',
    'team_members', 'investors_partners', 'certifications', 'awards',
}

CTA_STYLE_CHOICES = [
    ('primary',   'Primary Button'),
    ('secondary', 'Secondary Button'),
    ('link',      'Text Link'),
]

PAGE_STATUS_CHOICES = [
    ('draft',       'Draft'),
    ('published',   'Published'),
    ('unpublished', 'Unpublished'),
]


# ─── Core content models ──────────────────────────────────────────────────────

class AboutSection(models.Model):
    """
    One editable block on the About page. Default-language content lives
    directly on this row; other languages live in AboutSectionTranslation.
    """
    section_type = models.CharField(
        max_length=40, choices=SECTION_TYPE_CHOICES, default='custom',
        help_text="Drives default icon/layout in the admin UI and the app renderer.")
    section_key = models.SlugField(
        max_length=80, unique=True,
        help_text="Stable identifier used by the app to know how to render this "
                  "section, e.g. 'hero_banner'. Never reused after deletion.")

    title       = models.CharField(max_length=255, blank=True)
    subtitle    = models.CharField(max_length=255, blank=True)
    description = models.TextField(
        blank=True, help_text="Rich HTML from the admin rich-text editor "
                              "(headings, paragraphs, bullet lists, links).")
    icon  = models.CharField(max_length=100, blank=True, help_text="Icon key, e.g. 'rocket_launch'.")
    # Stores the delivery URL returned by /admin/upload-image/ (already
    # f_auto/q_auto-optimized by Cloudinary) — a plain URL, not a
    # CloudinaryField, so the admin can PATCH it as ordinary JSON after
    # uploading once, instead of re-uploading a file on every save.
    image = models.URLField(max_length=500, blank=True, default='')

    cta_text  = models.CharField(max_length=100, blank=True)
    cta_url   = models.CharField(max_length=500, blank=True)
    cta_style = models.CharField(max_length=20, choices=CTA_STYLE_CHOICES, default='primary')

    # Section-specific structured data that doesn't warrant its own column,
    # e.g. contact_info's {phone, email, address, hours}, app_info's
    # {play_store_url, app_store_url, version, download_count}, or
    # legal_links' {items: [{label, url}, ...]}.
    extra_data = models.JSONField(default=dict, blank=True)

    is_enabled = models.BooleanField(default=True)
    order      = models.PositiveIntegerField(default=0)

    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='about_sections_created')
    updated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='about_sections_updated')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['order', 'id']
        indexes = [
            models.Index(fields=['order'], name='about_section_order_idx'),
            models.Index(fields=['is_enabled'], name='about_section_enabled_idx'),
        ]

    def __str__(self):
        state = '✅' if self.is_enabled else '⛔'
        return f"{state} [{self.order}] {self.get_section_type_display()} — {self.title or self.section_key}"

    def is_collection_type(self):
        return self.section_type in COLLECTION_SECTION_TYPES


class AboutSectionItem(models.Model):
    """
    One card/step/counter/member/partner/certification/award/value inside
    a collection-type AboutSection. Generic on purpose — see module
    docstring for why one model covers all eight collection kinds.
    """
    section = models.ForeignKey(
        AboutSection, on_delete=models.CASCADE, related_name='items')

    title       = models.CharField(max_length=255, blank=True)
    subtitle    = models.CharField(max_length=255, blank=True)
    description = models.TextField(blank=True)
    icon        = models.CharField(max_length=100, blank=True)
    image       = models.URLField(max_length=500, blank=True, default='')

    # Used differently per section type: a Statistics counter's number
    # ("25000"), a Statistics counter's suffix lives in extra_data.suffix.
    value    = models.CharField(max_length=100, blank=True)
    link_url = models.CharField(
        max_length=500, blank=True,
        help_text="Team member social profile, partner site, certification "
                  "verification link, etc.")

    # e.g. team member {designation, linkedin, twitter}; award {year,
    # issuer}; certification {issued_date, expiry_date, credential_id}.
    extra_data = models.JSONField(default=dict, blank=True)

    is_enabled = models.BooleanField(default=True)
    order      = models.PositiveIntegerField(default=0)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['order', 'id']
        indexes = [
            models.Index(fields=['section', 'order'], name='about_item_order_idx'),
        ]

    def __str__(self):
        state = '✅' if self.is_enabled else '⛔'
        return f"{state} [{self.section.section_key}] {self.title or self.id}"


# ─── Multilingual overlays ─────────────────────────────────────────────────────

class AboutSectionTranslation(models.Model):
    """Per-language override of an AboutSection's text fields."""
    section  = models.ForeignKey(
        AboutSection, on_delete=models.CASCADE, related_name='translations')
    language = models.ForeignKey(
        Language, on_delete=models.CASCADE, related_name='about_section_translations')

    title       = models.CharField(max_length=255, blank=True)
    subtitle    = models.CharField(max_length=255, blank=True)
    description = models.TextField(blank=True)
    cta_text    = models.CharField(max_length=100, blank=True)

    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('section', 'language')

    def __str__(self):
        return f"[{self.language.code}] {self.section.section_key}"


class AboutSectionItemTranslation(models.Model):
    """Per-language override of an AboutSectionItem's text fields."""
    item     = models.ForeignKey(
        AboutSectionItem, on_delete=models.CASCADE, related_name='translations')
    language = models.ForeignKey(
        Language, on_delete=models.CASCADE, related_name='about_item_translations')

    title       = models.CharField(max_length=255, blank=True)
    subtitle    = models.CharField(max_length=255, blank=True)
    description = models.TextField(blank=True)
    value       = models.CharField(max_length=100, blank=True)

    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('item', 'language')

    def __str__(self):
        return f"[{self.language.code}] item#{self.item_id}"


# ─── SEO ──────────────────────────────────────────────────────────────────────

class AboutPageSEO(models.Model):
    """
    Page-wide SEO metadata. Singleton — always pk=1, enforced in save().
    """
    meta_title       = models.CharField(max_length=255, blank=True)
    meta_description = models.CharField(max_length=500, blank=True)
    meta_keywords    = models.CharField(max_length=500, blank=True, help_text="Comma-separated.")
    og_image         = models.URLField(max_length=500, blank=True, default='')

    updated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='about_seo_updates')
    updated_at = models.DateTimeField(auto_now=True)

    def save(self, *args, **kwargs):
        self.pk = 1
        super().save(*args, **kwargs)

    def delete(self, *args, **kwargs):
        pass  # singleton — never actually delete

    @classmethod
    def load(cls):
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj

    def __str__(self):
        return 'About Page SEO'


# ─── Publish workflow ──────────────────────────────────────────────────────────

class AboutPageStatus(models.Model):
    """
    Current publish state of the page as a whole. Singleton — always pk=1.
    """
    status        = models.CharField(max_length=15, choices=PAGE_STATUS_CHOICES, default='draft')
    published_at  = models.DateTimeField(null=True, blank=True)
    published_by  = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='about_page_publishes')
    current_version = models.ForeignKey(
        'AboutPageVersion', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='+')

    def save(self, *args, **kwargs):
        self.pk = 1
        super().save(*args, **kwargs)

    def delete(self, *args, **kwargs):
        pass

    @classmethod
    def load(cls):
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj

    def __str__(self):
        return f"About Page — {self.get_status_display()}"


class AboutPageVersion(models.Model):
    """
    A full snapshot of the page (sections + items + translations + SEO),
    taken on every Publish and every Restore. `snapshot` is the complete
    serialized state needed to reconstruct the page — see
    services.build_snapshot() / services.restore_snapshot().
    """
    version_number = models.PositiveIntegerField()
    snapshot       = models.JSONField()
    label          = models.CharField(
        max_length=255, blank=True,
        help_text="Optional admin note, e.g. 'Added 3 new team members'.")
    is_restore_of  = models.ForeignKey(
        'self', on_delete=models.SET_NULL, null=True, blank=True, related_name='restores')

    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='about_page_versions_created')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-version_number']

    def __str__(self):
        return f"v{self.version_number} ({self.created_at:%Y-%m-%d %H:%M})"