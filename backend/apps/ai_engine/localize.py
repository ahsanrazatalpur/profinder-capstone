# apps/ai_engine/localize.py — thin compatibility wrapper.
# All logic now lives in translation_service.py (single central service).
from apps.ai_engine import translation_service as svc
from apps.ai_engine.translation_service import KINDS            # noqa: F401
from apps.ai_engine.translation_providers import LANG_NAMES     # noqa: F401

MAX_ITEMS = 40
MAX_LEN = 500


def localize_texts(texts, lang, kind):
    """{original: localized} — originals returned when anything goes wrong."""
    res, _ = svc.localize([(kind, t) for t in texts], lang, allow_new=True)
    return {t: res.get((kind if kind in KINDS else 'text', t), t) for t in texts}