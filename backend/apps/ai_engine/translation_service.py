# apps/ai_engine/translation_service.py
#
# THE one place translation happens. Callers (API middleware, signals, the
# /ai/localize/ endpoint) hand it (kind, text) pairs and get back the best
# available text for the requested language.
#
# Priority for every string:
#   1. manual / admin-approved   (LocalizedText.status == 'manual')
#   2. cached automatic          (LocalizedText.status == 'auto')
#   3. fresh automatic           (provider call → stored permanently)
#   4. the original text         (ALWAYS the fallback — never null, never raises)

import hashlib
import logging
import threading
import time
from concurrent.futures import ThreadPoolExecutor, TimeoutError as FutTimeout
from datetime import date

from django.conf import settings
from django.core.cache import cache
from django.db import IntegrityError, close_old_connections

from apps.ai_engine import translation_rules as rules
from apps.ai_engine.models import LocalizedText
from apps.ai_engine.translation_providers import (
    LANG_NAMES, ProviderError, get_provider,
)

logger = logging.getLogger(__name__)

KINDS = ('name', 'city', 'category', 'text')
_POOL = ThreadPoolExecutor(max_workers=3, thread_name_prefix='i18n')
_inflight_lock = threading.Lock()
_inflight = set()          # keys currently being translated (avoid duplicate work)


# ── settings helpers ─────────────────────────────────────────────────────────
def _cfg(name, default):
    return getattr(settings, name, default)


def supported_languages():
    langs = _cfg('TRANSLATION_LANGUAGES', None)
    return set(langs) if langs else set(LANG_NAMES)


def lang_supported(lang):
    return lang in supported_languages() and lang != _cfg('TRANSLATION_SOURCE_LANGUAGE', 'en')


def source_key(lang, text, source_lang=None):
    """Deterministic key: same (source_lang, target, text) ⇒ same key. Any edit to
    the original text ⇒ different key ⇒ the old translation can never be shown."""
    src = source_lang or _cfg('TRANSLATION_SOURCE_LANGUAGE', 'en')
    return hashlib.sha1(f'{src}|{lang}|{text.strip()}'.encode('utf-8')).hexdigest()


# ── abuse protection ─────────────────────────────────────────────────────────
def _daily_budget_left():
    cap = int(_cfg('TRANSLATION_DAILY_NEW_LIMIT', 5000))
    used = cache.get(f'i18n:daily:{date.today()}', 0)
    return max(cap - used, 0)


def _spend_daily(n):
    k = f'i18n:daily:{date.today()}'
    try:
        cache.add(k, 0, 90000)
        cache.incr(k, n)
    except Exception:                                          # noqa: BLE001
        pass


def client_budget_left(client_id):
    """Per-client new-translation allowance per minute (stops scripted floods)."""
    cap = int(_cfg('TRANSLATION_CLIENT_NEW_PER_MINUTE', 120))
    return max(cap - cache.get(f'i18n:client:{client_id}', 0), 0)


def spend_client(client_id, n):
    k = f'i18n:client:{client_id}'
    try:
        cache.add(k, 0, 60)
        cache.incr(k, n)
    except Exception:                                          # noqa: BLE001
        pass


# ── core ─────────────────────────────────────────────────────────────────────
def _translate_one(provider, text, lang, kind, timeout):
    """Translate a single (possibly long) string. Returns str or None.
    Chunks are sent to the engine in GROUPS (one call per ~6 chunks) instead of one call
    per chunk: a long article used to need 4-8 sequential engine calls and almost always
    ran out of time / hit the rate limit, leaving the body in English."""
    chunks = rules.chunk_text(text, int(_cfg('TRANSLATION_CHUNK_SIZE', 1200)))
    plan, to_send = [], []
    for ch in chunks:
        lead = ch[:len(ch) - len(ch.lstrip())]
        trail = ch[len(ch.rstrip()):]
        core = ch.strip()
        if not rules.value_translatable(core, lang):
            plan.append((ch, None))
            continue
        prot, mapping = rules.protect(core)
        plan.append(((lead, trail, core, prot, mapping), True))
        to_send.append(prot)
    if not to_send:
        return text
    group = int(_cfg('TRANSLATION_CHUNKS_PER_CALL', 6))
    res = {}
    for i in range(0, len(to_send), group):
        part = list(dict.fromkeys(to_send[i:i + group]))
        res.update(provider.translate_batch(part, lang, kind, float(timeout) * 3))
    out = []
    for item, flag in plan:
        if flag is None:
            out.append(item)
            continue
        lead, trail, core, prot, mapping = item
        tr = res.get(prot)
        tr = rules.restore(tr, mapping) if tr else None
        if tr is None or len(tr) > len(core) * 6 + 80:         # dropped token / runaway output
            return None
        out.append(lead + tr + trail)
    return ''.join(out)


def _translate_and_store(kind, texts, lang, timeout, content_ref=''):
    """Runs in the worker pool: translate `texts`, persist good results.
    Never raises. Returns {text: translated} for what succeeded."""
    done = {}
    try:
        provider = get_provider()
        short = [t for t in texts if len(t) <= int(_cfg('TRANSLATION_CHUNK_SIZE', 1200))]
        long_ = [t for t in texts if t not in short]

        # short strings → ONE batched provider call
        pairs = {}
        if short:
            prot = {t: rules.protect(t.strip()) for t in short}
            try:
                res = provider.translate_batch([p for p, _ in prot.values()], lang, kind, timeout)
                for t, (p, mapping) in prot.items():
                    tr = res.get(p)
                    tr = rules.restore(tr, mapping) if tr else None
                    if tr and len(tr) <= len(t) * 6 + 80:
                        pairs[t] = tr
            except Exception as e:                             # noqa: BLE001
                logger.warning('[i18n] batch failed (lang=%s kind=%s): %s', lang, kind, e)
        for t in long_:
            try:
                tr = _translate_one(provider, t, lang, kind, timeout)
                if tr:
                    pairs[t] = tr
            except Exception as e:                             # noqa: BLE001
                logger.warning('[i18n] long text failed: %s', e)

        _spend_daily(len(texts))
        for t in texts:
            tr = pairs.get(t)
            key = source_key(lang, t)
            if not tr or (tr.strip() == t.strip() and rules.has_latin(tr) and lang in rules.SCRIPT_RANGES):
                # engine returned nothing useful → remember the failure briefly so
                # we don't hammer it; the original keeps being shown meanwhile.
                cache.set(f'i18n:fail:{lang}:{kind}:{key}', 1, int(_cfg('TRANSLATION_FAIL_TTL', 600)))
                continue
            _store(lang, kind, key, t, tr, content_ref)
            done[t] = tr
    except Exception:                                          # noqa: BLE001
        logger.exception('[i18n] _translate_and_store crashed')
    finally:
        with _inflight_lock:
            for t in texts:
                _inflight.discard((lang, kind, source_key(lang, t)))
        close_old_connections()
    return done


def _store(lang, kind, key, source, translated, content_ref=''):
    try:
        row, created = LocalizedText.objects.get_or_create(
            lang=lang, kind=kind, source_key=key,
            defaults={'source': source.strip(), 'translated': translated,
                      'source_lang': _cfg('TRANSLATION_SOURCE_LANGUAGE', 'en'),
                      'status': LocalizedText.STATUS_AUTO, 'content_ref': content_ref[:120]})
        if not created and row.status != LocalizedText.STATUS_MANUAL and row.translated != translated:
            row.translated = translated      # manual rows are NEVER overwritten
            row.save(update_fields=['translated', 'updated_at'])
    except IntegrityError:
        pass                                  # concurrent writer won — fine
    except Exception:                         # noqa: BLE001
        logger.exception('[i18n] could not store translation')


def _submit(fn, *args, **kwargs):
    """Background by default; inline when TRANSLATION_BACKGROUND=False (tests)."""
    class _Done:
        def __init__(self, v): self._v = v
        def result(self, timeout=None): return self._v

    if not _cfg('TRANSLATION_BACKGROUND', True):
        return _Done(fn(*args, **kwargs))
    try:
        return _POOL.submit(fn, *args, **kwargs)
    except RuntimeError:
        # Gracefully handle interpreter shutdown or pool closure without crashing
        try:
            return _Done(fn(*args, **kwargs))
        except Exception:
            return _Done({})


def lookup_cached(pairs, lang):
    """DB-only. {(kind, text): translated} for every pair that has a stored row."""
    if not pairs:
        return {}
    keys = {(k, t): source_key(lang, t) for k, t in pairs}
    rows = LocalizedText.objects.filter(lang=lang, source_key__in=set(keys.values()))
    by = {(r.kind, r.source_key): r.translated for r in rows}
    return {kt: by[(kt[0], key)] for kt, key in keys.items() if (kt[0], key) in by}


def localize(pairs, lang, *, allow_new=True, budget=None, max_new=None, content_ref=''):
    """
    pairs  : iterable of (kind, text)
    returns: (result, pending) where
             result  = {(kind, text): best_text}  — EVERY input is present,
                       falling back to the original text,
             pending = number of strings still being translated in the background.
    Never raises.
    """
    pairs = list(dict.fromkeys((k if k in KINDS else 'text', t) for k, t in pairs if isinstance(t, str)))
    result = {kt: kt[1] for kt in pairs}
    pending = 0
    try:
        lang = rules.norm_lang(lang)
        if not lang_supported(lang):
            return result, 0
        maxlen = int(_cfg('TRANSLATION_MAX_TEXT_LENGTH', 20000))
        cand = [(k, t) for k, t in pairs if rules.value_translatable(t, lang) and len(t) <= maxlen]
        if not cand:
            return result, 0

        hit = lookup_cached(cand, lang)
        for kt, tr in hit.items():
            result[kt] = tr

        missing = [kt for kt in cand if kt not in hit]
        if not missing or not allow_new:
            return result, 0

        # drop recently-failed + already in flight
        todo = []
        with _inflight_lock:
            for kind, text in missing:
                key = source_key(lang, text)
                if cache.get(f'i18n:fail:{lang}:{kind}:{key}'):
                    continue
                if (lang, kind, key) in _inflight:
                    pending += 1
                    continue
                todo.append((kind, text, key))
            allowance = min(_daily_budget_left(), max_new if max_new is not None else 10 ** 9)
            todo = todo[:allowance]
            for kind, text, key in todo:
                _inflight.add((lang, kind, key))
        if not todo:
            return result, pending

        # group per kind, one provider call per (kind) batch
        groups = {}
        for kind, text, _ in todo:
            groups.setdefault(kind, []).append(text)

        timeout = float(_cfg('TRANSLATION_PROVIDER_TIMEOUT', 20))
        wait = float(budget if budget is not None else _cfg('TRANSLATION_SYNC_BUDGET_SECONDS', 2.5))
        futures = {kind: _submit(_translate_and_store, kind, texts, lang, timeout, content_ref)
                   for kind, texts in groups.items()}
        # ONE shared deadline for all kinds (they already run in parallel), instead of
        # waiting `wait` seconds separately per kind.
        deadline = time.monotonic() + max(wait, 0.0)
        for kind, fut in futures.items():
            try:
                done = fut.result(timeout=max(deadline - time.monotonic(), 0.0))
                for t, tr in done.items():
                    result[(kind, t)] = tr
                pending += len([t for t in groups[kind] if t not in done])
            except FutTimeout:
                pending += len(groups[kind])         # keeps running; saved when finished
            except Exception:                         # noqa: BLE001
                logger.exception('[i18n] future failed')
        return result, pending
    except Exception:                                 # noqa: BLE001
        logger.exception('[i18n] localize() failed — returning originals')
        return result, pending


def prewarm(pairs, languages=None, content_ref=''):
    """Fire-and-forget: translate NEW content into every language before any user asks."""
    langs = [l for l in (languages or sorted(supported_languages())) if lang_supported(l)]
    pairs = [(k, t) for k, t in pairs if rules.value_translatable(t)]
    if not pairs or not langs:
        return

    def run():
        try:
            for lang in langs:
                localize(pairs, lang, allow_new=True, budget=0, content_ref=content_ref)
        finally:
            close_old_connections()

    if _cfg('TRANSLATION_BACKGROUND', True):
        _POOL.submit(run)
    else:
        run()