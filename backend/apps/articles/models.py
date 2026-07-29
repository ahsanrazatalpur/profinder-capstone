# apps/articles/models.py

from django.db import models
from django.conf import settings
from django.utils.text import slugify
from django.utils import timezone


class ArticleCategory(models.Model):
    name       = models.CharField(max_length=100, unique=True)
    icon       = models.CharField(max_length=50, default='article')
    color      = models.CharField(max_length=7, default='#2563EB')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name_plural = 'Article categories'
        ordering = ['name']

    def __str__(self):
        return self.name


class Article(models.Model):
    title        = models.CharField(max_length=255)
    slug         = models.SlugField(max_length=280, unique=True, blank=True)
    summary      = models.CharField(max_length=300, blank=True)
    content      = models.TextField()
    cover_image  = models.URLField(blank=True)

    # ✅ editorial_label — "ProFinder Health Desk", "Legal Advisory" etc.
    # Admin ka naam nahi dikhana, professional byline dikhana hai
    editorial_label = models.CharField(
        max_length=100,
        default='ProFinder Editorial',
        help_text="e.g. 'ProFinder Health Desk', 'Legal Advisory Team'"
    )

    author       = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='articles')
    category     = models.ForeignKey(
        ArticleCategory, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='articles')

    is_published = models.BooleanField(default=False)
    is_archived  = models.BooleanField(default=False)  # Draft → Published → Archived
    views_count  = models.PositiveIntegerField(default=0)
    read_time    = models.PositiveIntegerField(default=1)

    published_at = models.DateTimeField(null=True, blank=True)
    created_at   = models.DateTimeField(auto_now_add=True)
    updated_at   = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-published_at', '-created_at']

    def __str__(self):
        status = '✅' if self.is_published else '📝'
        return f"{status} {self.title}"

    def save(self, *args, **kwargs):
        if not self.slug:
            base_slug = slugify(self.title)[:250] or 'article'
            slug, counter = base_slug, 1
            while Article.objects.filter(slug=slug).exclude(pk=self.pk).exists():
                counter += 1
                slug = f"{base_slug}-{counter}"
            self.slug = slug
        if self.is_published and not self.published_at:
            self.published_at = timezone.now()
        super().save(*args, **kwargs)


class ArticleView(models.Model):
    """
    Per-user / per-session article view log.
    Admin analytics ke liye — kon sa article kitna dekha gaya,
    kis category ko zyada interest hai.
    Anonymous views bhi track hoti hain (user=None).
    """
    article    = models.ForeignKey(
        Article, on_delete=models.CASCADE, related_name='view_logs')
    user       = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='article_views')
    session_key = models.CharField(max_length=64, blank=True)
    viewed_at   = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-viewed_at']

    def __str__(self):
        who = self.user.name if self.user else 'Guest'
        return f"{who} → {self.article.title[:40]}"