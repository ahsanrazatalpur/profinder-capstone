# apps/ai_engine/middleware.py
#
# Universal API-layer localization.
#
# When the Flutter app sends  X-App-Language: ur  (any non-source language),
# every eligible JSON response is walked once; every string value that is
# real display content is swapped for its cached translation. No per-model,
# per-serializer, per-screen or per-field code is needed — a brand-new field
# or model is covered automatically as long as it is returned by the API.
#
# What is NOT touched (see translation_rules.py for value/key rules):
#   • admin users (admin panel UI stays exactly as it is)
#   • auth, profile/edit-form endpoints, chat, payments (original must round-trip)
#   • non-GET requests (except read-style POSTs listed in TRANSLATION_POST_PATHS)
#   • ids, urls, emails, phones, codes, tokens, numbers, enums, dates ...
#
# Nothing is ever stored back to the original tables.

import json
import logging
import re

from django.conf import settings

from apps.ai_engine import translation_rules as rules
from apps.ai_engine import translation_service as svc

logger = logging.getLogger(__name__)

DEFAULT_DENY_PATHS = [
    r'^/api/users/',                          # login/register/me/language — edit forms, tokens
    r'^/api/messaging/',                      # private chat is never auto-translated
    r'^/api/payments/',
    r'^/api/profiles/(user|professional)/$',  # own profile = edit-form prefill (originals must round-trip)
    r'^/api/profiles/professional/(dashboard|analytics)/',
    r'^/api/profiles/(portfolio|certificates|gallery)/(\d+/)?$',   # own items (edit forms)
    r'^/api/profiles/admin/',
    r'^/api/articles/admin/',
    r'^/api/reviews/(mine|my-reviews)/',
    r'^/api/reviews/\d+/$',
    r'^/api/subscriptions/(cancel)/',
    # Admin-panel data feeds edit forms -> originals must round-trip. Only the two
    # public, customer-facing feeds (announcement + promo banner) are localized.
    r'^/api/admin-panel/(?!(announcements|promo-banners)/active/)',
]
DEFAULT_POST_PATHS = [r'^/api/ai/search/$']

# Never machine-translated, whatever TRANSLATION_DENY_PATHS says in settings.
# Help Center and Privacy Policy text is legal / support content that only
# human-reviewed translations may serve (see apps/support/services.py), and
# ticket text is private user<->staff conversation. These patterns are added on
# top of any settings override so a custom TRANSLATION_DENY_PATHS can never
# re-enable translation for them.
ALWAYS_DENY_PATHS = [r'^/api/support/']


def _api_user(request):
    """The real caller. Django's AuthenticationMiddleware only knows session users, so a
    JWT (Bearer) caller looks anonymous here -> admin accounts were NOT being detected
    and received translated data. Resolve the JWT ourselves (cached per request)."""
    if hasattr(request, '_i18n_user'):
        return request._i18n_user
    user = getattr(request, 'user', None)
    if not (user is not None and getattr(user, 'is_authenticated', False)):
        header = request.META.get('HTTP_AUTHORIZATION', '')
        if header.lower().startswith('bearer '):
            try:
                from rest_framework_simplejwt.authentication import JWTAuthentication
                auth = JWTAuthentication()
                token = auth.get_validated_token(header.split(' ', 1)[1].strip().encode())
                user = auth.get_user(token)
            except Exception:                                   # noqa: BLE001  bad token = guest
                pass
    request._i18n_user = user
    return user


def _compile(name, default):
    return [re.compile(p) for p in getattr(settings, name, default)]


class ContentLocalizationMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response
        self.deny = _compile('TRANSLATION_DENY_PATHS', DEFAULT_DENY_PATHS)
        self.deny += [re.compile(p) for p in ALWAYS_DENY_PATHS]
        self.post_ok = _compile('TRANSLATION_POST_PATHS', DEFAULT_POST_PATHS)

    def __call__(self, request):
        response = self.get_response(request)
        try:
            return self._localize_response(request, response)
        except Exception:                                   # noqa: BLE001
            logger.exception('[i18n] middleware failed — serving original response')
            return response

    # ── gate ─────────────────────────────────────────────────────────────────
    def _eligible(self, request, response):
        if not getattr(settings, 'TRANSLATION_ENABLED', True):
            return None
        if request.method not in ('GET', 'POST'):
            return None
        path = request.path
        if not path.startswith('/api/'):
            return None
        if request.method == 'POST' and not any(p.search(path) for p in self.post_ok):
            return None
        if any(p.search(path) for p in self.deny):
            return None
        if request.META.get('HTTP_X_NO_LOCALIZE'):
            return None
        lang = rules.norm_lang(request.META.get('HTTP_X_APP_LANGUAGE') or request.GET.get('lang'))
        if not svc.lang_supported(lang):
            return None
        if response.status_code != 200 or getattr(response, 'streaming', False):
            return None
        if 'application/json' not in response.get('Content-Type', ''):
            return None
        user = _api_user(request)
        if user is not None and getattr(user, 'is_authenticated', False):
            # Admin panel stays untranslated.
            if getattr(user, 'is_staff', False) or getattr(user, 'is_superuser', False) \
               or getattr(user, 'role', '') == 'admin':
                return None
        if len(response.content) > int(getattr(settings, 'TRANSLATION_MAX_RESPONSE_BYTES', 2_000_000)):
            return None
        return lang

    # ── walk ─────────────────────────────────────────────────────────────────
    @staticmethod
    def _collect(node, key, out, path='', depth=0):
        """Collect (container, slot, kind, text) for every translatable string."""
        if depth > 12:
            return
        if isinstance(node, dict):
            for k, v in node.items():
                if isinstance(v, str):
                    if rules.key_allowed(k) and rules.value_translatable(v):
                        out.append((node, k, rules.kind_for_key(k, node, path), v))
                elif isinstance(v, (dict, list)):
                    ContentLocalizationMiddleware._collect(v, k, out, path, depth + 1)
        elif isinstance(node, list):
            for i, v in enumerate(node):
                if isinstance(v, str):
                    if rules.key_allowed(key) and rules.value_translatable(v):
                        out.append((node, i, rules.kind_for_key(key, None, path), v))
                elif isinstance(v, (dict, list)):
                    ContentLocalizationMiddleware._collect(v, key, out, path, depth + 1)

    def _localize_response(self, request, response):
        lang = self._eligible(request, response)
        if not lang:
            return response
        try:
            data = json.loads(response.content)
        except ValueError:
            return response
        if not isinstance(data, (dict, list)):
            return response

        slots = []
        self._collect(data, '', slots, request.path)
        response['Vary'] = ', '.join(filter(None, [response.get('Vary'), 'X-App-Language']))
        if not slots:
            return response

        user = _api_user(request)
        client = f'u{user.pk}' if getattr(user, 'is_authenticated', False) \
            else 'ip' + (request.META.get('REMOTE_ADDR') or '?')
        max_new = min(int(getattr(settings, 'TRANSLATION_MAX_NEW_PER_REQUEST', 40)),
                      svc.client_budget_left(client))

        pairs = [(kind, text) for _, _, kind, text in slots]
        result, pending = svc.localize(pairs, lang, allow_new=True, max_new=max_new,
                                       content_ref=f'api:{request.path}')
        new_cost = len({p for p in pairs if result.get(p) != p[1]})
        if max_new:
            svc.spend_client(client, min(new_cost, max_new))

        changed = False
        for container, slot, kind, text in slots:
            tr = result.get((kind, text), text)
            if tr != text:
                container[slot] = tr
                changed = True

        if changed:
            body = json.dumps(data, ensure_ascii=False).encode('utf-8')
            response.content = body
            response['Content-Length'] = str(len(body))
        if pending:
            response['X-Translation-Pending'] = str(pending)
        return response