# PATH: backend/apps/profiles/models.py
# apps/profiles/models.py

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
    phone     = models.CharField(max_length=20, blank=True)
    gender    = models.CharField(max_length=10, choices=GENDER_CHOICES, blank=True)  # NEW — AI Search intent ("female dentist")
    city      = models.CharField(max_length=100, blank=True)
    area      = models.CharField(max_length=100, blank=True)   # NEW — mohalla/area
    country   = models.CharField(max_length=100, blank=True)   # NEW — Pakistan, India etc
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
    user             = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='professionalprofile')
    category         = models.ForeignKey('search.Category', on_delete=models.SET_NULL, null=True, blank=True)
    bio              = models.TextField(blank=True)
    photo_url        = CloudinaryField('image', blank=True, null=True)
    experience_years = models.IntegerField(default=0)
    hourly_rate      = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    is_verified      = models.BooleanField(default=False)
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