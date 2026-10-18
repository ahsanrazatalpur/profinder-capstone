# apps/search/text_utils.py
#
# Script-independent text helpers for multilingual search. 100% offline/free.
#
#   normalize_text(s)  -> unicode-cleaned, lowercase, script-variants unified
#   to_latin(s)        -> best-effort Latin transliteration (any script)
#   phonetic_key(s)    -> consonant "skeleton" so spelling variants collide:
#                         wakeel / vakeel / wkeel / وکیل  -> "wkl"
#                         Muhammad / Mohammed / محمد       -> "mmd"
#   index_forms(s)     -> (latin, phonetic) pair stored in SearchIndex
#
# Arabic-script (Urdu/Arabic/Persian/Sindhi/Pashto) is transliterated with
# our own pronunciation-aware table, because generic libraries map e.g.
# ض -> "d" while Urdu speakers say "z" (Raza). Every other script falls back
# to `anyascii` (Hindi, Cyrillic, Greek, CJK, ...). Matching is deliberately
# fuzzy: this module maximises RECALL, the ranking layer restores precision.

import re
import unicodedata

try:                                    # soft dependency: Latin still works without it
    from anyascii import anyascii as _anyascii
except Exception:                       # pragma: no cover
    def _anyascii(s):
        return s

# ── Script-variant unification (same letter, different code points) ──────────
_UNIFY = {
    '\u064a': '\u06cc', '\u0649': '\u06cc', '\u06d0': '\u06cc',   # ي ى ې -> ی
    '\u0643': '\u06a9', '\u06aa': '\u06a9',                       # ك ڪ -> ک
    '\u0647': '\u06c1', '\u06be': '\u06c1', '\u06d5': '\u06c1',   # ه ھ ە -> ہ
    '\u06c2': '\u06c1', '\u06c3': '\u06c1',
    '\u0623': '\u0627', '\u0625': '\u0627', '\u0671': '\u0627',   # أ إ ٱ -> ا
    '\u06d3': '\u06d2',                                           # ۓ -> ے
}
# Arabic-Indic and Extended Arabic-Indic digits -> ASCII
_DIGITS = {ord(c): str(i) for i, c in enumerate('٠١٢٣٤٥٦٧٨٩')}
_DIGITS.update({ord(c): str(i) for i, c in enumerate('۰۱۲۳۴۵۶۷۸۹')})

# Devanagari letter + nukta (U+093C) -> Latin sound
_NUKTA = (
    ('\u0915\u093c', 'q'), ('\u0916\u093c', 'kh'), ('\u0917\u093c', 'gh'),
    ('\u091c\u093c', 'z'), ('\u095d', 'rh'), ('\u0921\u093c', 'r'),
    ('\u0922\u093c', 'rh'), ('\u092b\u093c', 'f'),
)

_ARABIC_RANGE = re.compile(r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]')
_DEV_RANGE    = re.compile(r'[\u0900-\u097F]')
_TATWEEL = '\u0640'
_ZW = dict.fromkeys(map(ord, '\u200b\u200c\u200d\u200e\u200f\u2060\ufeff'), None)


def has_arabic_script(s: str) -> bool:
    return bool(s) and bool(_ARABIC_RANGE.search(s))


def has_devanagari_script(s: str) -> bool:
    return bool(s) and bool(_DEV_RANGE.search(s))


def normalize_text(text: str) -> str:
    """NFKC, casefold, strip marks/tatweel/zero-width, unify Arabic variants."""
    if not text:
        return ''
    text = unicodedata.normalize('NFKC', str(text)).translate(_ZW)
    # Devanagari nukta letters carry a different sound (ज़ = z, फ़ = f, ...).
    # The nukta is a combining mark that gets stripped below, so convert first.
    for src, dst in _NUKTA:
        text = text.replace(src, dst)
    text = text.replace(_TATWEEL, '')
    text = ''.join(_UNIFY.get(c, c) for c in text).translate(_DIGITS)
    # drop combining marks (harakat, Latin accents, Devanagari nukta are kept
    # separate by NFKC so removing Mn is safe for matching purposes)
    text = ''.join(c for c in unicodedata.normalize('NFD', text)
                   if unicodedata.category(c) != 'Mn')
    # Replace punctuation/symbols/controls with a space, but KEEP letters,
    # digits and spacing combining marks (Devanagari matras like ा ी).
    # `\w` would wrongly treat those marks as separators.
    text = ''.join(
        c if unicodedata.category(c)[0] in 'LNM' else ' '
        for c in text.casefold()
    )
    return ' '.join(text.split())


# ── Arabic-script -> Latin (Urdu pronunciation) ──────────────────────────────
_AR2LAT = {
    'ا': 'a', 'آ': 'a', 'ء': '', 'ئ': 'y', 'ؤ': 'w',
    'ب': 'b', 'پ': 'p', 'ت': 't', 'ٹ': 't', 'ث': 's',
    'ج': 'j', 'چ': 'ch', 'ح': 'h', 'خ': 'kh',
    'د': 'd', 'ڈ': 'd', 'ذ': 'z', 'ر': 'r', 'ڑ': 'r', 'ز': 'z', 'ژ': 'zh',
    'س': 's', 'ش': 'sh', 'ص': 's', 'ض': 'z', 'ط': 't', 'ظ': 'z',
    'ع': 'a', 'غ': 'gh', 'ف': 'f', 'ق': 'q', 'ک': 'k', 'گ': 'g',
    'ل': 'l', 'م': 'm', 'ن': 'n', 'ں': 'n', 'ہ': 'h',
    'ی': 'y', 'ے': 'e',
    # Sindhi / Pashto / Persian extras
    'ڻ': 'n', 'ڙ': 'r', 'ڏ': 'd', 'ڌ': 'd', 'ڍ': 'd', 'ڊ': 'd', 'ٺ': 't',
    'ٽ': 't', 'ڦ': 'f', 'ڀ': 'b', 'ڄ': 'j', 'ڃ': 'n', 'ڇ': 'ch', 'ڱ': 'ng',
    'ګ': 'g', 'ږ': 'zh', 'ښ': 'sh', 'ډ': 'd', 'ړ': 'r', 'ڼ': 'n', 'ۍ': 'y',
    'ټ': 't', 'څ': 'ts', 'ځ': 'dz',
}


# ── Devanagari-script -> Latin fallback table ────────────────────────────────
_DEV2LAT = {
    'अ': 'a', 'आ': 'aa', 'इ': 'i', 'ई': 'ee', 'उ': 'u', 'ऊ': 'oo', 'ऋ': 'ri',
    'ए': 'e', 'ऐ': 'ai', 'ओ': 'o', 'औ': 'au',
    'क': 'k', 'ख': 'kh', 'ग': 'g', 'घ': 'gh', 'ङ': 'ng',
    'च': 'ch', 'छ': 'chh', 'ज': 'j', 'झ': 'jh', 'ञ': 'ny',
    'ट': 't', 'ठ': 'th', 'ड': 'd', 'ढ': 'dh', 'ण': 'n',
    'त': 't', 'थ': 'th', 'द': 'd', 'ध': 'dh', 'न': 'n',
    'प': 'p', 'फ': 'ph', 'ब': 'b', 'भ': 'bh', 'म': 'm',
    'य': 'y', 'र': 'r', 'ल': 'l', 'व': 'v',
    'श': 'sh', 'ष': 'sh', 'स': 's', 'ह': 'h',
    'ा': 'a', 'ि': 'i', 'ी': 'ee', 'ु': 'u', 'ू': 'oo', 'ृ': 'ri',
    'े': 'e', 'ै': 'ai', 'ो': 'o', 'ौ': 'au', '्': '', 'ं': 'n', 'ँ': 'n', 'ः': 'h',
}


def _arabic_word_to_latin(word: str) -> str:
    out = []
    n = len(word)
    for i, ch in enumerate(word):
        if ch == 'و':
            # word-initial و (وکیل / waqar) is a consonant, elsewhere a vowel
            out.append('w' if i == 0 else 'u')
        elif ch == 'ی' and i == 0:
            out.append('y')
        elif ch == 'ا' and i == 0 and n > 1:
            out.append('a')
        else:
            out.append(_AR2LAT.get(ch, ''))
    return ''.join(out)


def to_latin(text: str) -> str:
    """Normalise then transliterate any script to lowercase ASCII words."""
    text = normalize_text(text)
    if not text:
        return ''
    words = []
    for w in text.split():
        if has_arabic_script(w):
            lat = _arabic_word_to_latin(w)
            # any leftover non-Arabic chars in a mixed token
            lat = ''.join(c if c.isascii() else _anyascii(c) for c in lat)
        elif has_devanagari_script(w):
            lat = _anyascii(w)
            if not lat.isascii() or lat == w:
                lat = ''.join(_DEV2LAT.get(c, c) for c in w)
        elif w.isascii():
            lat = w
        else:
            lat = _anyascii(w)
        lat = re.sub(r'[^a-z0-9]', '', lat.lower())
        if lat:
            words.append(lat)
    return ' '.join(words)


# ── Phonetic key ─────────────────────────────────────────────────────────────
_DIGRAPHS = (
    ('sh', 's'), ('ch', 'c'), ('kh', 'k'), ('gh', 'g'), ('ph', 'f'),
    ('th', 't'), ('dh', 'd'), ('bh', 'b'), ('jh', 'j'), ('zh', 'z'),
    ('ts', 's'), ('dz', 'z'), ('ng', 'n'),
)
_CLASS = {'q': 'k', 'c': 'k', 'x': 'k', 'v': 'w', 'z': 's'}
_VOWELS = set('aeiouyh')


def _phonetic_word(w: str) -> str:
    for a, b in _DIGRAPHS:
        w = w.replace(a, b)
    out = []
    for c in w:
        if c in _VOWELS or not c.isalnum():
            continue
        c = _CLASS.get(c, c)
        if not out or out[-1] != c:          # collapse doubled consonants
            out.append(c)
    return ''.join(out)


def phonetic_key(text: str) -> str:
    """Space-separated phonetic key per word (digits kept as-is)."""
    keys = [_phonetic_word(w) for w in to_latin(text).split()]
    return ' '.join(k for k in keys if k)


def index_forms(text: str) -> tuple:
    """(latin, phonetic) forms stored in SearchIndex for one blob of text."""
    lat = to_latin(text)
    return lat, ' '.join(k for k in (_phonetic_word(w) for w in lat.split()) if k)