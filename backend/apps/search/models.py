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


# Cross-script / typo-tolerant search index (one row per professional).
# Built by apps.search.indexing from name, category, specialization, skills,
# company, services, tags, city, area, country. Three searchable forms:
#   native_text   - unicode-normalised original script
#   latin_text    - transliterated to Latin (any script -> ascii)
#   phonetic_text - consonant skeleton, space-padded (" wkl md ") so a whole
#                   token can be matched with a trigram-indexed icontains
# name_latin / name_phonetic keep the NAME alone so ranking can boost it.
# (Trigram GIN indexes are created in migration 0005 on PostgreSQL only, so
#  the app keeps working on SQLite for local dev.)
class SearchIndex(models.Model):
    user          = models.OneToOneField(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='search_index')
    native_text   = models.TextField(blank=True, default='')
    latin_text    = models.TextField(blank=True, default='')
    phonetic_text = models.TextField(blank=True, default='')
    name_latin    = models.CharField(max_length=300, blank=True, default='')
    name_phonetic = models.CharField(max_length=300, blank=True, default='')
    updated_at    = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"SearchIndex<{self.user_id}>"


# Admin-editable extra aliases: "what people type" -> canonical English
# profession word. Spelling variants of an alias are matched phonetically, so
# add ONE spelling per language/script. Built-in seed lives in alias_seed.py.
class SearchAlias(models.Model):
    alias      = models.CharField(max_length=100)
    canonical  = models.CharField(max_length=100, help_text='English profession word, e.g. lawyer')
    language   = models.CharField(max_length=10, blank=True, default='')
    source     = models.CharField(max_length=20, blank=True, default='manual')  # manual / gemini
    is_active  = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [('alias', 'canonical')]
        indexes = [
            models.Index(fields=['is_active'], name='search_alias_active_idx'),
        ]

    def __str__(self):
        return f"{self.alias} -> {self.canonical}"