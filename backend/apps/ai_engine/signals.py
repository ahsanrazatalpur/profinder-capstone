# apps/ai_engine/signals.py
#
# Generic pre-warm: whenever ANY model in an allow-listed app is saved, its
# human-readable text fields are translated into every supported language in
# the background — so by the time a user opens the app, the translation is
# already cached and the API middleware returns it instantly.
#
# No per-model code: fields are discovered from the model definition. Adding a
# new model/field in those apps is picked up automatically.

import logging

from django.conf import settings
from django.db import models, transaction
from django.db.models.signals import post_save

from apps.ai_engine import translation_rules as rules
from apps.ai_engine import translation_service as svc

logger = logging.getLogger(__name__)

DEFAULT_APPS = ['users', 'profiles', 'search', 'reviews', 'articles',
                'notifications', 'admin_panel', 'about_page', 'subscriptions']
# Private / moderation / financial / technical models never pre-translated.
DEFAULT_EXCLUDE_MODELS = {
    'ai_engine.LocalizedText', 'ai_engine.SearchHistory', 'ai_engine.AIRecommendation',
    'admin_panel.AdminLog', 'admin_panel.Complaint', 'admin_panel.UserReport',
    'admin_panel.ModerationAction', 'admin_panel.Appeal', 'admin_panel.ContentTranslation',
    'admin_panel.Language', 'admin_panel.TranslationKey', 'admin_panel.TranslationString',
    'about_page.AboutSectionTranslation', 'about_page.AboutSectionItemTranslation',
    'about_page.AboutPageSEO', 'about_page.AboutPageVersion',
    'reviews.ReviewReport', 'profiles.ProfileView', 'articles.ArticleView',
}
_SKIP_FIELD_TYPES = (models.EmailField, models.URLField, models.SlugField,
                     models.FileField, models.GenericIPAddressField)


def _fields_to_translate(model):
    for f in model._meta.get_fields():
        if not isinstance(f, (models.CharField, models.TextField)):
            continue
        if isinstance(f, _SKIP_FIELD_TYPES) or f.choices or not f.editable or f.primary_key:
            continue
        if not rules.key_allowed(f.name) or f.name in ('note', 'admin_note') or 'note' in f.name:
            continue
        yield f


def kind_for_field(model, field_name):
    """Same decision the API middleware makes, but from the model definition."""
    if field_name == 'name':
        m = model.__name__.lower()
        if 'categor' in m:
            return 'category'
        if m in ('city', 'country'):
            return 'city'
        if m in ('user', 'userprofile', 'professionalprofile'):
            return 'name'
        if 'plan' in m:
            return 'text'
    return rules.kind_for_key(field_name)


def collect_pairs(instance):
    pairs = []
    for f in _fields_to_translate(type(instance)):
        val = getattr(instance, f.name, None)
        if isinstance(val, str) and rules.value_translatable(val):
            pairs.append((kind_for_field(type(instance), f.name), val.strip()))
    return pairs


def _on_save(sender, instance, created=False, raw=False, **kwargs):
    if raw or not getattr(settings, 'TRANSLATION_ENABLED', True):
        return
    meta = sender._meta
    apps_ok = getattr(settings, 'TRANSLATION_PREWARM_APPS', DEFAULT_APPS)
    excl = getattr(settings, 'TRANSLATION_PREWARM_EXCLUDE', DEFAULT_EXCLUDE_MODELS)
    if meta.app_label not in apps_ok or f'{meta.app_label}.{meta.object_name}' in excl:
        return
    try:
        pairs = collect_pairs(instance)
        if not pairs:
            return
        ref = f'{meta.app_label}.{meta.object_name}'
        transaction.on_commit(lambda: svc.prewarm(pairs, content_ref=ref))
    except Exception:                                        # noqa: BLE001
        logger.exception('[i18n] prewarm hook failed (ignored)')


def connect():
    post_save.connect(_on_save, dispatch_uid='ai_engine_i18n_prewarm')