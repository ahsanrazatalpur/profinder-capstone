# apps/search/indexing.py
#
# Builds / refreshes SearchIndex rows. Called from signals (on every profile
# save) and from the `build_search_index` management command (backfill).

import logging

from apps.search.text_utils import index_forms, normalize_text

log = logging.getLogger(__name__)


def _field_values(user):
    """All searchable text for one professional, as a list of raw strings."""
    prof = getattr(user, 'professionalprofile', None)
    up = getattr(user, 'userprofile', None)
    vals = [user.name or '']
    if prof is not None:
        cat = prof.category
        vals += [
            cat.name if cat else '',
            prof.specialization, prof.skills, prof.company_name,
            prof.services, prof.tags,
        ]
    if up is not None:
        vals += [up.full_name, up.city, up.area, up.country]
    return [v for v in vals if v]


def build_index_for_user(user):
    """Create/update (or delete, for non-professionals) the row for `user`."""
    from apps.search.models import SearchIndex

    if user.role != 'professional' or not user.is_active:
        SearchIndex.objects.filter(user_id=user.pk).delete()
        return None

    raw = ' | '.join(_field_values(user))
    native = normalize_text(raw)
    latin, phon = index_forms(raw)
    name_latin, name_phon = index_forms(user.name or '')

    obj, _ = SearchIndex.objects.update_or_create(
        user_id=user.pk,
        defaults={
            'native_text':   native,
            'latin_text':    latin,
            'phonetic_text': f' {phon} ' if phon else '',
            'name_latin':    name_latin[:300],
            'name_phonetic': name_phon[:300],
        },
    )
    return obj
