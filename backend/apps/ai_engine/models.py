from django.db import models
from django.conf import settings

class AIRecommendation(models.Model):
    user         = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='recommendations')
    professional = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='recommended_to')
    score        = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    reason       = models.TextField(blank=True)
    created_at   = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.email} → {self.professional.email} - {self.score}"


class SearchHistory(models.Model):
    user       = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    query      = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.email} - {self.query}"

class LocalizedText(models.Model):
    """
    Central translation store for ALL dynamic content (names, cities, categories,
    titles, descriptions, notification text, reviews ...).

    The ORIGINAL text always stays on its own table — this table only holds
    derived translations, so nothing is ever overwritten or lost.

    Key       : (lang, kind, source_key)  where source_key = sha1(source_lang|lang|text)
                → editing the original text produces a new key, so a stale
                translation can never be shown for changed content.
    Priority  : status 'manual' (admin-approved) is never overwritten by automation.
    """
    STATUS_AUTO   = 'auto'
    STATUS_MANUAL = 'manual'
    STATUS_CHOICES = [(STATUS_AUTO, 'Automatic'), (STATUS_MANUAL, 'Manual (admin-approved)')]

    lang        = models.CharField(max_length=10)                  # target language
    source_lang = models.CharField(max_length=10, default='en')
    kind        = models.CharField(max_length=20)                  # name | city | category | text
    source_key  = models.CharField(max_length=64)
    source      = models.TextField()                               # original text (copy, for lookup/admin)
    translated  = models.TextField()
    status      = models.CharField(max_length=10, choices=STATUS_CHOICES, default=STATUS_AUTO)
    content_ref = models.CharField(max_length=120, blank=True, default='',
                                   help_text="Optional origin, e.g. 'search.Category.name'")
    version     = models.PositiveSmallIntegerField(default=1)
    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('lang', 'kind', 'source_key')
        indexes = [models.Index(fields=['lang', 'source_key'], name='loctext_lang_key_idx')]

    def __str__(self):
        return f"[{self.lang}/{self.kind}/{self.status}] {self.source[:30]} → {self.translated[:30]}"