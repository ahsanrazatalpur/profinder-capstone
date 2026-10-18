# apps/support/web_views.py
#
# Step 2: public, server-rendered Privacy Policy page (GET /privacy/?lang=ur).
# Same DB source as the in-app screen (PolicyVersion -> latest PUBLISHED), so
# the website and the app can never disagree. Autoescaping is on: admin-entered
# text is never rendered as HTML.

from django.http import HttpResponseNotAllowed
from django.shortcuts import render

from apps.support.models import PolicyDocument, PolicyTranslation, PolicyVersion
from apps.support.presenters import present_policy
from apps.support.services import SOURCE_LANGUAGE

# (code, name written in that language) – the six app languages.
PAGE_LANGUAGES = [
    ('en', 'English'),
    ('ur', 'اردو'),
    ('hi', 'हिन्दी'),
    ('ar', 'العربية'),
    ('fr', 'Français'),
    ('es', 'Español'),
]
_CODES = {c for c, _ in PAGE_LANGUAGES}


def _group_blocks(blocks):
    """Merge consecutive bullets into one list so the template emits <ul>."""
    out = []
    for b in blocks:
        if b['type'] == 'bullet':
            if out and out[-1]['type'] == 'list':
                out[-1]['items'].append(b['text'])
            else:
                out.append({'type': 'list', 'items': [b['text']]})
        else:
            out.append(b)
    return out


def privacy_policy_page(request):
    if request.method not in ('GET', 'HEAD'):
        return HttpResponseNotAllowed(['GET', 'HEAD'])

    lang = (request.GET.get('lang') or SOURCE_LANGUAGE).split('-')[0].split('_')[0].lower()
    if lang not in _CODES:
        lang = SOURCE_LANGUAGE

    version = (
        PolicyVersion.objects
        .filter(document__doc_type=PolicyDocument.TYPE_PRIVACY,
                status=PolicyVersion.STATUS_PUBLISHED)
        .select_related('document')
        .prefetch_related('translations__language')
        .order_by('-version_number')
        .first()
    )
    data = present_policy(version, lang) if version else None
    if data is None:
        return render(request, 'support/privacy.html', {'available': False,
                                                         'languages': PAGE_LANGUAGES,
                                                         'active_lang': lang}, status=404)

    return render(request, 'support/privacy.html', {
        'available': True,
        'policy': data,
        'sections': _group_blocks(data['blocks']),
        'languages': PAGE_LANGUAGES,
        'active_lang': lang,
    })
