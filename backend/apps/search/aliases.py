# apps/search/aliases.py
#
# Language-independent profession-word lookup.
#
#   alias_lookup(word, known_english) -> canonical English profession | None
#   translate_phrases(text)           -> replaces multi-word aliases in text
#   translate_cities(text)            -> replaces multi-script city aliases
#   reload_aliases()                  -> drop the cache (admin edits call this)
#
# Sources: built-in SEED_ALIASES + active rows of the SearchAlias table.
# A word matches when its phonetic key equals an alias key AND its Latin
# transliteration is reasonably close to that alias (guards against English
# words that merely share a consonant skeleton, e.g. "weekly" vs "wakeel").

import re
import threading
import time

from apps.search.alias_seed import SEED_ALIASES, CITY_ALIASES
from apps.search.text_utils import index_forms, normalize_text

try:
    from rapidfuzz import fuzz as _fuzz, process as _process

    def _ratio(a, b):
        return _fuzz.ratio(a, b)
except Exception:                                   # pragma: no cover
    from difflib import SequenceMatcher
    _process = None

    def _ratio(a, b):
        return 100.0 * SequenceMatcher(None, a, b).ratio()

CACHE_TTL = 300            # seconds before DB aliases are re-read
MIN_KEY_LEN = 3            # shorter phonetic keys are too ambiguous
LATIN_MIN_RATIO = 70       # Latin-script words must look like the alias
FOREIGN_MIN_RATIO = 55     # other scripts: transliteration is approximate
NEAR_KEY_RATIO = 80        # one-letter slip in the phonetic key (typo)

_lock = threading.Lock()
_state = {'at': 0.0, 'direct': {}, 'phrases': [], 'by_key': {}, 'keys': []}


def _db_aliases():
    try:
        from apps.search.models import SearchAlias
        return list(SearchAlias.objects.filter(is_active=True)
                    .values_list('alias', 'canonical'))
    except Exception:                               # table missing (pre-migrate) etc.
        return []


def _build():
    pairs = [(a, c) for c, lst in SEED_ALIASES.items() for a in [c, *lst]]  # canonical word is its own alias
    pairs += _db_aliases()
    direct, phrases, by_key = {}, [], {}
    for alias, canon in pairs:
        norm = normalize_text(alias)
        canon = (canon or '').strip().lower()
        if not norm or not canon:
            continue
        direct[norm] = canon
        if ' ' in norm:
            phrases.append((norm, canon))
            continue
        latin, key = index_forms(norm)
        if len(key) >= MIN_KEY_LEN:
            by_key.setdefault(key, []).append((latin, canon))
    phrases.sort(key=lambda p: len(p[0]), reverse=True)
    return direct, phrases, by_key


def _ensure():
    now = time.time()
    if now - _state['at'] < CACHE_TTL and _state['direct']:
        return _state
    with _lock:
        if now - _state['at'] >= CACHE_TTL or not _state['direct']:
            direct, phrases, by_key = _build()
            _state.update(at=now, direct=direct, phrases=phrases,
                          by_key=by_key, keys=list(by_key))
    return _state


def reload_aliases():
    _state['at'] = 0.0


def translate_phrases(text):
    """Replace multi-word aliases (e.g. 'ماہر نفسیات') inside `text`."""
    st = _ensure()
    if not text or not st['phrases']:
        return text
    norm = normalize_text(text)
    for phrase, canon in st['phrases']:
        if phrase in norm:
            norm = re.sub(rf'(?<!\S){re.escape(phrase)}(?!\S)', canon, norm)
    return norm if norm != normalize_text(text) else text


def translate_cities(text):
    """Replace city names written in non-Latin or alternate scripts with English canonical."""
    if not text:
        return text
    result = text
    # Longest city names first
    for alias, canon in sorted(CITY_ALIASES.items(), key=lambda x: len(x[0]), reverse=True):
        if alias in result:
            result = re.sub(rf'(?<!\S){re.escape(alias)}(?!\S)', canon, result, flags=re.IGNORECASE)
    return result


def alias_lookup(word, known_english=()):
    """Canonical English profession for `word`, or None."""
    st = _ensure()
    norm = normalize_text(word)
    if not norm or ' ' in norm:
        return None
    if norm in st['direct']:
        return st['direct'][norm]
    if norm.isascii() and (norm in known_english or len(norm) < 4):
        return None                                  # real English word / too short

    latin, key = index_forms(norm)
    if len(key) < MIN_KEY_LEN:
        return None
    min_ratio = LATIN_MIN_RATIO if norm.isascii() else FOREIGN_MIN_RATIO

    cands = st['by_key'].get(key)
    if not cands and len(key) >= 4 and st['keys']:
        if _process is not None:
            # several near keys, not just the closest
            hits = _process.extract(key, st['keys'], scorer=_fuzz.ratio,
                                    score_cutoff=NEAR_KEY_RATIO, limit=6)
            cands = [c for h in hits for c in st['by_key'].get(h[0], ())] or None
        else:
            from difflib import get_close_matches
            close = get_close_matches(key, st['keys'], n=6, cutoff=0.75)
            cands = [c for k in close for c in st['by_key'].get(k, ())] or None
    if not cands:
        return None

    best, best_r = None, 0.0
    for alias_latin, canon in cands:
        r = _ratio(latin, alias_latin)
        if r > best_r:
            best, best_r = canon, r
    return best if best_r >= min_ratio else None
