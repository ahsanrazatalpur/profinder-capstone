# apps/ai_engine/management/commands/translate_backfill.py
#
# One-time (and safe to re-run) pre-translation of EXISTING content: names, cities,
# categories, magazine, announcements, banners... into every supported language, so
# the app shows them translated on the very first open instead of English-first.
#
#   python manage.py translate_backfill                  # all languages
#   python manage.py translate_backfill --lang ur hi     # only these
#   python manage.py translate_backfill --dry-run        # just count what is missing
#
# Already-cached strings are skipped (no repeated engine calls). Strings the engine
# fails on are reported and simply retried the next time you run it.

import time

from django.apps import apps as django_apps
from django.conf import settings
from django.core.management.base import BaseCommand

from apps.ai_engine import signals
from apps.ai_engine import translation_rules as rules
from apps.ai_engine import translation_service as svc


class Command(BaseCommand):
    help = 'Pre-translate all existing dynamic content (cached permanently, originals untouched).'

    def add_arguments(self, parser):
        parser.add_argument('--lang', nargs='*', default=None, help='e.g. ur hi (default: all supported)')
        parser.add_argument('--batch', type=int, default=15, help='strings per engine call')
        parser.add_argument('--sleep', type=float, default=4.0, help='seconds between calls (rate limit)')
        parser.add_argument('--dry-run', action='store_true')

    def handle(self, *args, **opts):
        apps_ok = getattr(settings, 'TRANSLATION_PREWARM_APPS', signals.DEFAULT_APPS)
        excl = getattr(settings, 'TRANSLATION_PREWARM_EXCLUDE', signals.DEFAULT_EXCLUDE_MODELS)

        pairs = set()
        for model in django_apps.get_models():
            meta = model._meta
            if meta.app_label not in apps_ok or f'{meta.app_label}.{meta.object_name}' in excl:
                continue
            try:
                for inst in model.objects.all().iterator():
                    pairs.update(signals.collect_pairs(inst))
            except Exception as e:                                   # noqa: BLE001
                self.stderr.write(f'skip {meta.label}: {e}')
        pairs = sorted(pairs)
        self.stdout.write(f'{len(pairs)} unique strings found in the database')

        langs = [rules.norm_lang(l) for l in (opts['lang'] or sorted(svc.supported_languages()))]
        langs = [l for l in langs if svc.lang_supported(l)]
        total_new = total_fail = 0

        for lang in langs:
            cached = svc.lookup_cached(pairs, lang)
            missing = [p for p in pairs if p not in cached]
            self.stdout.write(f'[{lang}] cached={len(cached)} missing={len(missing)}')
            if opts['dry_run'] or not missing:
                continue
            # short strings first (many per call), long ones (articles) one by one
            missing.sort(key=lambda p: (len(p[1]) > 600, p[0]))
            step = max(opts['batch'], 1)
            for i in range(0, len(missing), step):
                part = missing[i:i + step]
                res, pending = svc.localize(part, lang, allow_new=True, budget=90, max_new=10 ** 6,
                                            content_ref='backfill')
                ok = sum(1 for p in part if res.get(p) != p[1])
                total_new += ok
                total_fail += len(part) - ok
                self.stdout.write(f'  [{lang}] {i + len(part)}/{len(missing)}  ok={ok} failed={len(part) - ok}')
                time.sleep(opts['sleep'])

        self.stdout.write(self.style.SUCCESS(f'done: translated={total_new} failed={total_fail}'))
        if total_fail:
            self.stdout.write('Failed strings stay in English; run the command again later '
                              '(usually an engine rate-limit / quota issue).')
