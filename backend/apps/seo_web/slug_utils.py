import re
import unicodedata
from django.utils.text import slugify
from .models import SlugRedirect


def clean_slug_text(text: str) -> str:
    """
    Normalizes text for slugification.
    Replaces '&', '/', '+' with hyphens, strips accents, and cleans whitespace.
    """
    if not text:
        return ''
    text = str(text).strip()
    text = text.replace('&', ' and ').replace('/', ' ').replace('+', ' and ')
    # Normalize unicode
    text = unicodedata.normalize('NFKD', text)
    # Slugify with allow_unicode=False for clean ASCII URLs (best for search bots & universal URLs)
    slug = slugify(text, allow_unicode=False)
    if not slug:
        # Fallback if text was purely non-ASCII and slugify emptied it
        slug = slugify(text, allow_unicode=True)
    return slug.strip('-')


def generate_unique_slug(model_class, base_str: str, instance_id=None, slug_field='slug', max_length=200) -> str:
    """
    Generates a unique, URL-safe slug for a model instance.
    If 'base_str' resolves to 'doctors', and 'doctors' exists, tries 'doctors-2', 'doctors-3', etc.
    """
    raw_slug = clean_slug_text(base_str)
    if not raw_slug:
        raw_slug = f"item-{instance_id or 'pro'}"

    # Trim to max_length allowing headroom for -suffix
    raw_slug = raw_slug[:max_length - 8].rstrip('-')
    candidate = raw_slug

    counter = 1
    qs = model_class.objects.all()
    if instance_id:
        qs = qs.exclude(pk=instance_id)

    while qs.filter(**{slug_field: candidate}).exists():
        counter += 1
        candidate = f"{raw_slug}-{counter}"

    return candidate


def track_slug_change(old_path: str, new_path: str):
    """
    Records a 301 redirect if an existing URL path changes.
    """
    if not old_path or not new_path or old_path == new_path:
        return
    # Avoid redirect loops
    if SlugRedirect.objects.filter(old_path=new_path, new_path=old_path).exists():
        return
    SlugRedirect.objects.update_or_create(
        old_path=old_path,
        defaults={'new_path': new_path, 'status_code': 301}
    )
