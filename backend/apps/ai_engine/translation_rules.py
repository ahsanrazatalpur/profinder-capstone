# apps/ai_engine/translation_rules.py
#
# Pure, dependency-free rules that decide WHAT may be translated and HOW.
# Everything here is deterministic and unit-tested — no network, no DB.

import re

# ── Languages ────────────────────────────────────────────────────────────────
SCRIPT_RANGES = {
    'ur': r'\u0600-\u06FF', 'ar': r'\u0600-\u06FF', 'hi': r'\u0900-\u097F',
}


def norm_lang(value):
    """'UR', ' ur-PK ', 'ur_PK' → 'ur'. Empty/None → ''."""
    if not value:
        return ''
    return str(value).strip().lower().replace('_', '-').split('-')[0]


def _letters(text):
    return [c for c in text if c.isalpha()]


def in_target_script(text, lang):
    """True when most letters are already in the target language's script."""
    rng = SCRIPT_RANGES.get(lang)
    if not rng:
        return False
    letters = _letters(text)
    if not letters:
        return False
    hit = len(re.findall('[' + rng + ']', text))
    return hit / len(letters) >= 0.4


def has_latin(text):
    return bool(re.search(r'[A-Za-z]', text))


# ── Key rules (API field names) ──────────────────────────────────────────────
DENY_KEYS = {
    'id', 'pk', 'uuid', 'token', 'access', 'refresh', 'password', 'email', 'phone',
    'mobile', 'url', 'link', 'photo', 'image', 'avatar', 'slug', 'status', 'type',
    'role', 'code', 'color', 'colour', 'icon', 'currency', 'lang', 'language',
    'locale', 'key', 'username', 'handle', 'gender', 'date', 'time', 'timezone',
    'ip', 'hash', 'secret', 'fcm_token', 'created_at', 'updated_at', 'event',
    'action', 'trigger', 'audience', 'user_type', 'platform', 'mime_type',
    'detail', 'error', 'errors',   # framework / validation messages stay as-is
}
DENY_SUFFIXES = (
    '_id', '_ids', '_url', '_uri', '_at', '_on', '_token', '_code', '_key', '_slug',
    '_status', '_type', '_color', '_colour', '_icon', '_image', '_photo', '_email',
    '_phone', '_date', '_time', '_lang', '_language', '_hash', '_count', '_link',
)
DENY_PREFIXES = ('is_', 'has_', 'can_')
DENY_SUBSTRINGS = ('password', 'token', 'secret', 'stripe', 'bank', 'account_number')


def key_allowed(key):
    k = str(key or '').lower()
    if not k:
        return True                      # list items: decided by the parent key
    if k in DENY_KEYS or k.startswith(DENY_PREFIXES) or k.endswith(DENY_SUFFIXES):
        return False
    return not any(s in k for s in DENY_SUBSTRINGS)


_NAME_EXACT = {
    'name', 'full_name', 'first_name', 'last_name', 'display_name', 'user_name',
    'other_user_name', 'owner_name', 'author_name', 'company_name', 'company',
}
_CITY_EXACT = {
    'city', 'area', 'location', 'address', 'state', 'country', 'region', 'district',
    'locality', 'neighbourhood', 'neighborhood', 'location_label',
}
_CATEGORY_EXACT = {
    'category', 'category_name', 'subcategory', 'subcategory_name', 'profession',
    'specialization', 'tag', 'tags', 'skills', 'services',
}
_NOT_NAME = ('category', 'plan', 'file', 'section', 'bank', 'feature')


# A bare "name" field is ambiguous: a person ("Sadia Chandio"), a category
# ("Doctors & Healthcare"), a city ("Karachi") or a plan ("Premium"). Decide from
# the endpoint path and from sibling keys in the same JSON object.
_CATEGORY_PATH_HINTS = ('categor',)
_CITY_PATH_HINTS = ('/cities', '/countries')
_PLAN_PATH_HINTS = ('/plans', '/subscriptions')
_CATEGORY_SIBLINGS = {'icon', 'is_featured', 'parent', 'subcategories', 'slug'}
_PERSON_SIBLINGS = {'email', 'role', 'avatar', 'photo', 'profile_picture', 'rating', 'is_verified',
                    'experience_years', 'hourly_rate', 'user_id', 'phone'}


def kind_for_key(key, node=None, path=''):
    """name | city | category | text — decides transliterate vs translate.
    `node` (the JSON object holding the key) and `path` (request path) only
    matter for the ambiguous bare key "name"."""
    k = str(key or '').lower()
    if k == 'name':
        p = (path or '').lower()
        sib = set(node.keys()) if isinstance(node, dict) else set()
        if any(h in p for h in _CATEGORY_PATH_HINTS) or (sib & _CATEGORY_SIBLINGS and not sib & _PERSON_SIBLINGS):
            return 'category'
        if any(h in p for h in _CITY_PATH_HINTS):
            return 'city'
        if any(h in p for h in _PLAN_PATH_HINTS):
            return 'text'
        return 'name'
    if k in _CATEGORY_EXACT or k.endswith('_category'):
        return 'category'
    if k in _CITY_EXACT or k.endswith(('_city', '_location', '_country')):
        return 'city'
    if k in _NAME_EXACT:
        return 'name'
    if k.endswith('_name') and not any(x in k for x in _NOT_NAME):
        return 'name'
    return 'text'


# ── Value rules ──────────────────────────────────────────────────────────────
URL_RE    = re.compile(r'(?:https?://|www\.)[^\s<>"\']+', re.I)
EMAIL_RE  = re.compile(r'[\w.+-]+@[\w-]+(?:\.[\w-]+)+')
PHONE_RE  = re.compile(r'(?<![\w])\+?\d[\d\s().-]{6,}\d(?![\w])')
UUID_RE   = re.compile(r'\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b', re.I)

_WHOLE_SKIP = [
    re.compile(r'^\s*[\d\W_]*\s*$'),                                  # no letters at all
    re.compile(r'^(?:https?://|www\.)\S+$', re.I),                    # URL
    re.compile(r'^[\w.+-]+@[\w-]+(?:\.[\w-]+)+$'),                    # email
    re.compile(r'^\+?\d[\d\s().-]{5,}$'),                             # phone
    re.compile(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', re.I),
    re.compile(r'^#?[0-9a-fA-F]{6,8}$'),                              # hex colour / hash-ish
    re.compile(r'^\d{4}-\d{2}-\d{2}([T ][\d:.+\-Z]+)?$'),             # ISO date/time
    re.compile(r'^[A-Z0-9][A-Z0-9_\-./]{1,}$'),                       # CODES, PK, USD, ORD-123
    re.compile(r'^[a-z][a-z0-9]*(?:_[a-z0-9]+)+$'),                   # snake_case identifier
    re.compile(r'^[a-z]+(?:[A-Z][a-z0-9]*)+$'),                       # camelCase identifier
    re.compile(r'^[\w\-./\\]+\.(?:jpe?g|png|gif|webp|svg|pdf|docx?|xlsx?|mp[34]|m4a|wav|zip|json|dart|py)$', re.I),
    re.compile(r'^(?:/|\./|\.\./|[A-Za-z]:\\)[\w\-./\\]*$'),          # file path
]


def value_translatable(text, lang=None):
    if not isinstance(text, str):
        return False
    t = text.strip()
    if len(t) < 2:
        return False
    if any(p.match(t) for p in _WHOLE_SKIP):
        return False
    if lang and in_target_script(t, lang):
        return False
    if lang in SCRIPT_RANGES and not has_latin(t):
        return False                      # nothing in Latin script to convert
    return True


# ── Protect URLs / emails / phones inside sentences ──────────────────────────
_PROTECT = (UUID_RE, URL_RE, EMAIL_RE, PHONE_RE)


def protect(text):
    """Replace URLs/emails/phones/UUIDs with opaque tokens → (text, {token: original})."""
    mapping = {}

    def sub(m):
        tok = f'[[P{len(mapping)}]]'
        mapping[tok] = m.group(0)
        return tok

    for rx in _PROTECT:
        text = rx.sub(sub, text)
    return text, mapping


def restore(text, mapping):
    """Put originals back. Returns None if the engine dropped any token."""
    for tok, orig in mapping.items():
        if tok not in text:
            return None
        text = text.replace(tok, orig)
    return text


# ── Long text chunking ───────────────────────────────────────────────────────
_SPLIT_RE = re.compile(r'(?<=\n)|(?<=</p>)|(?<=</li>)|(?<=</h[1-6]>)|(?<=[.!?۔]\s)')


def chunk_text(text, size=1200):
    if len(text) <= size:
        return [text]
    chunks, cur = [], ''
    for piece in _SPLIT_RE.split(text):
        if cur and len(cur) + len(piece) > size:
            chunks.append(cur)
            cur = ''
        # a single piece longer than `size` is hard-cut
        while len(piece) > size:
            chunks.append(piece[:size])
            piece = piece[size:]
        cur += piece
    if cur:
        chunks.append(cur)
    return chunks