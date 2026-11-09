from django.db import models


class SlugRedirect(models.Model):
    """
    Tracks historical slug / path changes for permanent HTTP 301 redirection.
    Prevents broken external links and preserves Google/Bing search indexing equity.
    """
    old_path = models.CharField(max_length=255, unique=True, db_index=True)
    new_path = models.CharField(max_length=255)
    status_code = models.PositiveSmallIntegerField(default=301)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Slug Redirect'
        verbose_name_plural = 'Slug Redirects'

    def __str__(self):
        return f"{self.old_path} -> {self.new_path} ({self.status_code})"


class ServiceListing(models.Model):
    """
    Curated indexable service landing entity with canonical slug,
    linking category, optional city, search keywords, and descriptive copy.
    """
    title = models.CharField(max_length=255)
    slug = models.SlugField(max_length=255, unique=True, db_index=True)
    category = models.ForeignKey(
        'search.Category',
        on_delete=models.CASCADE,
        related_name='service_listings'
    )
    city = models.ForeignKey(
        'admin_panel.City',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='service_listings'
    )
    profession_key = models.CharField(
        max_length=100,
        blank=True,
        help_text='Key in PROFESSION_MAPPINGS e.g. doctors, electricians'
    )
    short_description = models.TextField(blank=True)
    full_content = models.TextField(blank=True)
    faq_data = models.JSONField(default=list, blank=True)
    is_active = models.BooleanField(default=True, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['title']
        verbose_name = 'Service Listing'
        verbose_name_plural = 'Service Listings'

    def __str__(self):
        return self.title

    def save(self, *args, **kwargs):
        if not self.slug:
            from apps.seo_web.slug_utils import generate_unique_slug
            self.slug = generate_unique_slug(ServiceListing, self.title, instance_id=self.id)
        super().save(*args, **kwargs)
