# apps/about_page/utils.py
"""
Snapshot / restore for the publish-and-version-history workflow, plus the
Cloudinary upload helper that gives us "automatic compression and WebP
optimization" without a Pillow processing pipeline: Cloudinary already
stores the original and can transform+cache a WebP/auto-quality derivative
on request, so we (a) ask it to eagerly generate one on upload, and (b)
always hand the frontend a transformed delivery URL, never the raw one.
"""

from django.db import transaction

import cloudinary.uploader

from apps.admin_panel.models import Language
from apps.about_page.models import (
    AboutSection, AboutSectionItem,
    AboutSectionTranslation, AboutSectionItemTranslation,
    AboutPageSEO,
)

# Cloudinary transformation applied to every About-page image on delivery:
# f_auto → best format for the requesting browser (WebP/AVIF where supported)
# q_auto → automatic perceptual-quality compression
OPTIMIZED_TRANSFORM = {'fetch_format': 'auto', 'quality': 'auto'}


def upload_about_image(file, folder='about_page'):
    """
    Uploads an image for the About Page CMS. Returns (public_id, secure_url)
    where secure_url already has the auto-format/auto-quality transform
    baked in, so every consumer (public API, admin preview) gets an
    optimized delivery URL for free.
    """
    result = cloudinary.uploader.upload(
        file, folder=folder, eager=[OPTIMIZED_TRANSFORM])
    if result.get('eager'):
        url = result['eager'][0]['secure_url']
    else:
        url = result['secure_url']
    return result['public_id'], url


def optimized_url(value):
    """
    Images are stored as plain URL strings that already came out of
    upload_about_image() (so they already carry the f_auto/q_auto
    transform) — this just guards against None/empty consistently
    wherever a model's `image` field is read.
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