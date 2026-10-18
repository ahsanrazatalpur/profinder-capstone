# apps/about_page/utils.py
"""
Snapshot / restore for the publish-and-version-history workflow, plus the
image upload helper for the About Page CMS.

✅ CHANGED: images now save to LOCAL DISK (MEDIA_ROOT/about_page/) instead
of Cloudinary. Cloudinary needs an outbound HTTPS call to api.cloudinary.com
on every upload — PythonAnywhere's Free plan blocks all outbound internet
access except a small whitelist, so every upload was failing with
"Connection refused". Local storage needs zero external network access —
same approach already used for chat attachments — so it works on Free
plan too. Trade-off: no automatic WebP/auto-quality transform anymore
(that was a Cloudinary feature); files are served as-is.
"""

import os
import uuid

from django.conf import settings
from django.core.files.storage import FileSystemStorage
from django.db import transaction

from apps.admin_panel.models import Language
from apps.about_page.models import (
    AboutSection, AboutSectionItem,
    AboutSectionTranslation, AboutSectionItemTranslation,
    AboutPageSEO,
)

ABOUT_IMAGE_SUBDIR = 'about_page'
_storage = FileSystemStorage(
    location=os.path.join(settings.MEDIA_ROOT, ABOUT_IMAGE_SUBDIR),
    base_url=settings.MEDIA_URL + ABOUT_IMAGE_SUBDIR + '/',
)


def upload_about_image(file, request=None):
    """
    Saves an uploaded image to local disk (MEDIA_ROOT/about_page/) and
    returns (filename, url). `url` is an ABSOLUTE URL (built from the
    current request) because AboutSection.image / AboutSectionItem.image
    are URLField — DRF's URLField rejects relative paths like
    "/media/about_page/x.jpg" as invalid, so we must return a full
    "https://host/media/about_page/x.jpg" here.
    """
    ext = os.path.splitext(file.name)[1].lower() or '.jpg'
    filename = f'{uuid.uuid4().hex}{ext}'
    saved_name = _storage.save(filename, file)
    relative_url = _storage.url(saved_name)  # e.g. /media/about_page/abcd1234.jpg

    if request is not None:
        url = request.build_absolute_uri(relative_url)
    else:
        url = relative_url
    return saved_name, url


def optimized_url(value):
    """
    Images are stored as plain URL strings. Kept as a passthrough (name
    unchanged) so callers/serializers don't need to change — previously
    this assumed a Cloudinary URL that already carried transforms; now
    it's just whatever upload_about_image() returned.
    """
    return value or ''


# ─── Snapshot (used on Publish and before Restore) ─────────────────────────────

def build_snapshot():
    """Serialize the entire live About Page state into a plain dict."""
    sections = []
    for section in AboutSection.objects.prefetch_related(
            'items__translations', 'translations').order_by('order', 'id'):
        sections.append({
            'section_type': section.section_type,
            'section_key':  section.section_key,
            'title':        section.title,
            'subtitle':     section.subtitle,
            'description':  section.description,
            'icon':         section.icon,
            'image':        optimized_url(section.image),
            'cta_text':     section.cta_text,
            'cta_url':      section.cta_url,
            'cta_style':    section.cta_style,
            'extra_data':   section.extra_data,
            'is_enabled':   section.is_enabled,
            'order':        section.order,
            'translations': [
                {
                    'language_code': t.language.code,
                    'title': t.title, 'subtitle': t.subtitle,
                    'description': t.description, 'cta_text': t.cta_text,
                }
                for t in section.translations.all()
            ],
            'items': [
                {
                    'title': i.title, 'subtitle': i.subtitle,
                    'description': i.description, 'icon': i.icon,
                    'image': optimized_url(i.image),
                    'value': i.value, 'link_url': i.link_url,
                    'extra_data': i.extra_data,
                    'is_enabled': i.is_enabled, 'order': i.order,
                    'translations': [
                        {
                            'language_code': t.language.code,
                            'title': t.title, 'subtitle': t.subtitle,
                            'description': t.description, 'value': t.value,
                        }
                        for t in i.translations.all()
                    ],
                }
                for i in section.items.all()
            ],
        })

    seo = AboutPageSEO.load()
    seo_data = {
        'meta_title': seo.meta_title,
        'meta_description': seo.meta_description,
        'meta_keywords': seo.meta_keywords,
        'og_image': optimized_url(seo.og_image),
    }

    return {'sections': sections, 'seo': seo_data}


@transaction.atomic
def restore_snapshot(snapshot):
    """
    Replace the live About Page state with the given snapshot. Deletes and
    recreates sections/items/translations — safe because the *previous*
    live state is itself preserved as a version before this ever runs
    (see views.AboutPageVersionRestoreView).
    """
    language_by_code = {l.code: l for l in Language.objects.all()}

    AboutSection.objects.all().delete()  # cascades to items + translations

    for s in snapshot.get('sections', []):
        section = AboutSection.objects.create(
            section_type=s.get('section_type', 'custom'),
            section_key=s['section_key'],
            title=s.get('title', ''),
            subtitle=s.get('subtitle', ''),
            description=s.get('description', ''),
            icon=s.get('icon', ''),
            image=s.get('image', ''),
            cta_text=s.get('cta_text', ''),
            cta_url=s.get('cta_url', ''),
            cta_style=s.get('cta_style', 'primary'),
            extra_data=s.get('extra_data', {}),
            is_enabled=s.get('is_enabled', True),
            order=s.get('order', 0),
        )
        for t in s.get('translations', []):
            lang = language_by_code.get(t['language_code'])
            if not lang:
                continue
            AboutSectionTranslation.objects.create(
                section=section, language=lang,
                title=t.get('title', ''), subtitle=t.get('subtitle', ''),
                description=t.get('description', ''), cta_text=t.get('cta_text', ''),
            )
        for i in s.get('items', []):
            item = AboutSectionItem.objects.create(
                section=section,
                title=i.get('title', ''), subtitle=i.get('subtitle', ''),
                description=i.get('description', ''), icon=i.get('icon', ''),
                image=i.get('image', ''),
                value=i.get('value', ''), link_url=i.get('link_url', ''),
                extra_data=i.get('extra_data', {}),
                is_enabled=i.get('is_enabled', True), order=i.get('order', 0),
            )
            for t in i.get('translations', []):
                lang = language_by_code.get(t['language_code'])
                if not lang:
                    continue
                AboutSectionItemTranslation.objects.create(
                    item=item, language=lang,
                    title=t.get('title', ''), subtitle=t.get('subtitle', ''),
                    description=t.get('description', ''), value=t.get('value', ''),
                )

    seo_data = snapshot.get('seo', {})
    seo = AboutPageSEO.load()
    seo.meta_title = seo_data.get('meta_title', '')
    seo.meta_description = seo_data.get('meta_description', '')
    seo.meta_keywords = seo_data.get('meta_keywords', '')
    seo.og_image = seo_data.get('og_image', '')
    seo.save()