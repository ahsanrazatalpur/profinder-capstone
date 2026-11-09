# PATH: backend/apps/profiles/models.py
# apps/profiles/models.py

import uuid
from django.db import models
from django.conf import settings
from cloudinary.models import CloudinaryField
from django.contrib.postgres.indexes import GinIndex


class UserProfile(models.Model):
    GENDER_CHOICES = [
        ('male',   'Male'),
        ('female', 'Female'),
        ('other',  'Other'),
    ]

    user      = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='userprofile')
    full_name = models.CharField(max_length=255, blank=True)
    photo_url = CloudinaryField('image', blank=True, null=True)
    phone           = models.CharField(max_length=20, blank=True)
    whatsapp_number = models.CharField(max_length=20, blank=True, default='')
    gender    = models.CharField(max_length=10, choices=GENDER_CHOICES, blank=True)  # NEW — AI Search intent ("female dentist")
    city      = models.CharField(max_length=100, blank=True)
    area      = models.CharField(max_length=100, blank=True)   # NEW — mohalla/area
    country   = models.CharField(max_length=100, blank=True, default='Pakistan')   # Pakistan National Focus
    latitude  = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)

    def __str__(self):
        return f"{self.user.email} - Profile"

    class Meta:
        indexes = [
            # City / Area / Country — Normal Search location fields
            GinIndex(fields=['city'],    name='profile_city_trgm_idx',    opclasses=['gin_trgm_ops']),
            GinIndex(fields=['area'],    name='profile_area_trgm_idx',    opclasses=['gin_trgm_ops']),
            GinIndex(fields=['country'], name='profile_country_trgm_idx', opclasses=['gin_trgm_ops']),
        ]


class ProfessionalProfile(models.Model):
    PRICING_UNIT_CHOICES = [
        ('per_hour',         'Per Hour'),
        ('per_day',          'Per Day'),
        ('per_visit',        'Per Visit'),
        ('per_session',      'Per Session'),
        ('per_service',      'Per Service'),
        ('per_consultation', 'Per Consultation'),
        ('per_project',      'Per Project'),
        ('per_month',        'Per Month'),
        ('fixed_price',      'Fixed Price'),
        ('starting_from',    'Starting From'),
        ('negotiable',       'Negotiable'),
        ('free_consultation','Free Consultation'),
        ('custom',           'Custom Unit'),
    ]

    user             = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='professionalprofile')
    slug             = models.SlugField(max_length=255, unique=True, blank=True, null=True)
    category         = models.ForeignKey('search.Category', on_delete=models.SET_NULL, null=True, blank=True)
    bio              = models.TextField(blank=True)
    photo_url        = CloudinaryField('image', blank=True, null=True)
    experience_years = models.IntegerField(default=0)
    hourly_rate      = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    pricing_unit     = models.CharField(max_length=30, choices=PRICING_UNIT_CHOICES, default='per_service')
    custom_pricing_unit = models.CharField(max_length=50, blank=True, default='')
    custom_pricing_unit_approved = models.BooleanField(default=False)
    is_verified      = models.BooleanField(default=False)
    identity_verified = models.BooleanField(default=False)
    credentials_verified = models.BooleanField(default=False)
    average_rating   = models.DecimalField(max_digits=3, decimal_places=1, default=0.0)
    cnic_url         = CloudinaryField('image', blank=True, null=True)
    license_url      = CloudinaryField('image', blank=True, null=True)

    # ✅ NEW — Professional Dashboard "Availability" toggle ke liye.
    # False hone par booking requests nahi aate (search/booking flow isko
    # respect karega jab wahan integrate ho).
    is_available     = models.BooleanField(default=True)

    # ✅ NEW — Wallet withdrawal ke liye. Professional ye ek baar set karta
    # hai (Bank Details section), phir har withdrawal request isi account
    # ka reference use karti hai.
    bank_account_name   = models.CharField(max_length=255, blank=True)
    bank_account_number = models.CharField(max_length=50, blank=True)
    bank_name            = models.CharField(max_length=255, blank=True)

    # ── NEW SEARCH FIELDS ─────────────────────────────────────────────────────
    specialization = models.CharField(max_length=255, blank=True)   # e.g. "Cardiologist", "Civil Engineer"
    skills         = models.TextField(blank=True)                    # comma-sep: "Python, Django, REST API"
    company_name   = models.CharField(max_length=255, blank=True)   # e.g. "Ali Medical Center"
    services       = models.TextField(blank=True)                    # "Home visits, Online consult"
    tags           = models.CharField(max_length=500, blank=True)   # "fast, affordable, reliable"

    # ✅ NEW — Professional Profile screen: Languages, Education, Working Hours
    languages            = models.TextField(blank=True)              # comma-sep, same pattern as skills
    education            = models.TextField(blank=True)              # free-text, e.g. "BSc Computer Science, XYZ University"
    working_hours_start  = models.CharField(max_length=5, blank=True, default='09:00')  # "HH:MM" 24-hr
    working_hours_end    = models.CharField(max_length=5, blank=True, default='18:00')  # "HH:MM" 24-hr
    whatsapp_number      = models.CharField(max_length=20, blank=True, default='')
    custom_profession    = models.CharField(max_length=100, blank=True, default='')
    custom_profession_approved = models.BooleanField(default=False)
    working_days         = models.CharField(max_length=100, blank=True, default='Mon,Tue,Wed,Thu,Fri,Sat')

    def save(self, *args, **kwargs):
        if not self.slug:
            from apps.seo_web.slug_utils import generate_unique_slug
            user_name = self.user.name if self.user else 'pro'
            spec = self.specialization or (self.category.name if self.category else '')
            city = ''
            if hasattr(self.user, 'userprofile') and self.user.userprofile.city:
                city = self.user.userprofile.city
            base = f"{user_name} {spec} {city}".strip()
            self.slug = generate_unique_slug(ProfessionalProfile, base, instance_id=self.id)
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.user.email} - Professional"

    def update_verification(self):
        has_approved = self.user.portfolio.filter(is_approved=True).exists()
        if has_approved and not self.is_verified:
            self.is_verified = True
            self.save(update_fields=['is_verified'])

    class Meta:
        indexes = [
            # Normal Search keyword fields — trigram GIN indexes make
            # icontains() queries index-scans instead of full table scans.
            GinIndex(fields=['specialization'], name='prof_specialization_trgm_idx', opclasses=['gin_trgm_ops']),
            GinIndex(fields=['skills'],         name='prof_skills_trgm_idx',         opclasses=['gin_trgm_ops']),
            GinIndex(fields=['company_name'],   name='prof_company_trgm_idx',        opclasses=['gin_trgm_ops']),
            GinIndex(fields=['services'],       name='prof_services_trgm_idx',       opclasses=['gin_trgm_ops']),
            GinIndex(fields=['tags'],           name='prof_tags_trgm_idx',           opclasses=['gin_trgm_ops']),
            GinIndex(fields=['bio'],            name='prof_bio_trgm_idx',            opclasses=['gin_trgm_ops']),
            models.Index(fields=['hourly_rate']),
            models.Index(fields=['average_rating']),
        ]


class Portfolio(models.Model):
    PENDING  = 'pending'
    APPROVED = 'approved'
    REJECTED = 'rejected'
    STATUS_CHOICES = [(PENDING, 'Pending'), (APPROVED, 'Approved'), (REJECTED, 'Rejected')]

    professional = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='portfolio')
    title        = models.CharField(max_length=255)
    description  = models.TextField(blank=True)
    image_url    = CloudinaryField('image', blank=True, null=True)
    created_at   = models.DateTimeField(auto_now_add=True)
    status       = models.CharField(max_length=20, choices=STATUS_CHOICES, default=PENDING)
    admin_note   = models.TextField(blank=True)
    reviewed_at  = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"{self.professional.email} - {self.title} [{self.status}]"


# ✅ NEW — Certificates: distinct from Portfolio (professional qualifications/
# training certs, not work-sample photos). No admin-approval workflow —
# professional manages these themselves.
class Certificate(models.Model):
    professional         = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='certificates')
    title                = models.CharField(max_length=255)
    issuing_organization = models.CharField(max_length=255, blank=True)
    issue_date           = models.DateField(null=True, blank=True)
    certificate_image    = CloudinaryField('image', blank=True, null=True)
    created_at            = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.professional.email} - {self.title}"

    class Meta:
        ordering = ['-created_at']


# ✅ NEW — Gallery: simple photo-only uploads, no title/description/approval.
# Distinct from Portfolio (work-samples with admin review) per the
# Professional Profile spec ("Gallery" vs "Portfolio").
class GalleryImage(models.Model):
    professional = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='gallery_images')
    image        = CloudinaryField('image')
    cloudinary_public_id = models.CharField(max_length=255, unique=True, null=True, blank=True, db_index=True)
    created_at   = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.professional.email} - gallery #{self.id}"

    class Meta:
        ordering = ['-created_at']


# ✅ NEW — Analytics: logs every time someone views a professional's public
# profile. Used to compute "Profile Views" (total rows) and "Visitors"
# (distinct viewers) on the Analytics dashboard.
class ProfileView(models.Model):
    professional = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='profile_views')
    viewer       = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='profile_views_made')
    created_at   = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"View of {self.professional.email} at {self.created_at}"


class ProfessionalSecondaryCategory(models.Model):
    """
    Pro subscribers can list in up to 2 secondary categories (total 3).
    is_active controls search visibility and enables non-destructive downgrade.
    """
    professional_profile = models.ForeignKey(
        'profiles.ProfessionalProfile',
        on_delete=models.CASCADE,
        related_name='secondary_categories'
    )
    category = models.ForeignKey(
        'search.Category',
        on_delete=models.CASCADE,
        related_name='secondary_professionals'
    )
    is_active = models.BooleanField(default=True, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('professional_profile', 'category')
        verbose_name = "Professional Secondary Category"
        verbose_name_plural = "Professional Secondary Categories"

    def __str__(self):
        return f"{self.professional_profile} - {self.category.name} ({'Active' if self.is_active else 'Inactive'})"


class StagedMedia(models.Model):
    """
    Durable staging for Cloudinary media uploads.
    Prevents orphan assets via preallocated IDs, upload lease heartbeats,
    fencing checks at commit, and background sweeper cleanup.
    """
    STATUS_CHOICES = [
        ('preallocated', 'Preallocated'),
        ('uploaded',     'Uploaded'),
        ('committed',    'Committed'),
        ('cleaning',     'Cleaning'),
        ('cleanup_failed','Cleanup Failed'),
    ]
    public_id = models.CharField(max_length=255, unique=True, db_index=True)
    professional = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='staged_media'
    )
    upload_lease_token = models.UUIDField(default=uuid.uuid4, db_index=True)
    lease_expires_at = models.DateTimeField(db_index=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='preallocated', db_index=True)
    cleanup_lease_token = models.UUIDField(null=True, blank=True)
    cleanup_retries = models.PositiveSmallIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status', 'lease_expires_at']),
        ]

    def __str__(self):
        return f"{self.public_id} ({self.status}) for {self.professional.email}"