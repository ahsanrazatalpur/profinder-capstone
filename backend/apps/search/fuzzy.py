# apps/search/fuzzy.py
#
# Query side of the cross-script search: candidate retrieval + score bonus.
#
#   query_tokens(text)      -> [(latin, phonetic), ...] for meaningful tokens
#   fuzzy_filter_q(tokens)  -> Q to OR into the existing keyword filter
#   fuzzy_bonus(idx, toks)  -> (name_bonus, other_bonus) for ranking
#
# PostgreSQL: pg_trgm word-similarity + padded phonetic token match, both
# served by the GIN indexes from migration 0005.
# Other DBs (SQLite dev): a bounded in-Python scan with rapidfuzz.

from django.db import connection
from django.db.models import Q

from apps.search.text_utils import index_forms

try:
    from rapidfuzz import fuzz as _fuzz

    def _ratio(a, b):
        return _fuzz.ratio(a, b)
except Exception:                                # pragma: no cover
    from difflib import SequenceMatcher

    def _ratio(a, b):
        return 100.0 * SequenceMatcher(None, a, b).ratio()

MIN_LATIN_LEN = 3          # shorter tokens are too noisy for fuzzy retrieval
MIN_PHON_LEN = 2
PY_SCAN_LIMIT = 5000       # safety cap for the non-PostgreSQL fallback
NAME_SIM_FLOOR = 70        # similarity below this earns no bonus


def query_tokens(text):
    """[(latin, phonetic)] for each usable token of `text`, de-duplicated."""
    lat, _ = index_forms(text)
    out, seen = [], set()
    for w in lat.split():
        if len(w) < MIN_LATIN_LEN or w in seen:
            continue
        seen.add(w)
        _, ph = index_forms(w)
        out.append((w, ph))
    return out


def _pg_q(tokens):
    q = Q()
    for lat, ph in tokens:
        q |= Q(search_index__latin_text__trigram_word_similar=lat)
        q |= Q(search_index__latin_text__icontains=lat)
        if len(ph) >= MIN_PHON_LEN:
            q |= Q(search_index__phonetic_text__icontains=f' {ph} ')
    return q


def _py_q(tokens):
    from apps.search.models import SearchIndex
    ids = []
    rows = SearchIndex.objects.values_list('user_id', 'latin_text', 'phonetic_text')[:PY_SCAN_LIMIT]
    for uid, latin, phon in rows:
        words = set(latin.split())
        phons = set(phon.split())
        for lat, ph in tokens:
            if (lat in latin or (len(ph) >= MIN_PHON_LEN and ph in phons)
                    or any(_ratio(lat, w) >= 80 for w in words)):
                ids.append(uid)
                break
    return Q(pk__in=ids) if ids else Q(pk__in=[])


def fuzzy_filter_q(tokens):
    """Q (on the User queryset) matching professionals similar to `tokens`."""
    if not tokens:
        return Q(pk__in=[])
    if connection.vendor == 'postgresql':
        return _pg_q(tokens)
    return _py_q(tokens)


def _best_sim(tok, words, phons=()):
    lat, ph = tok
    best = 0.0
    for w in words:
        best = max(best, _ratio(lat, w))
    if len(ph) >= MIN_PHON_LEN and ph in phons:
        best = max(best, 90.0)
    return best


def fuzzy_bonus(idx, tokens):
    """(name_bonus 0-160, other_bonus 0-60) from a SearchIndex row."""
    if idx is None or not tokens:
        return 0.0, 0.0
    name_words = idx.name_latin.split()
    name_phons = set(idx.name_phonetic.split())
    all_words = set(idx.latin_text.replace('|', ' ').split())
    all_phons = set(idx.phonetic_text.split())

    name_sim = max((_best_sim(t, name_words, name_phons) for t in tokens), default=0.0)
    other_sim = max((_best_sim(t, all_words, all_phons) for t in tokens), default=0.0)

    def scale(sim, top):
        if sim < NAME_SIM_FLOOR:
            return 0.0
        return top * min(1.0, (sim - NAME_SIM_FLOOR) / (100 - NAME_SIM_FLOOR))

    return scale(name_sim, 160.0), scale(other_sim, 60.0)
