# python manage.py generate_aliases --languages ur,hi,ar,fr,es,bn,tr [--dry-run]
#
# One-time (or occasional) job: asks Gemini for the words people use for each
# profession in the given languages and stores them in SearchAlias. Search
# itself never calls Gemini, so the free-tier quota only matters while this
# command runs. Safe to re-run: existing aliases are skipped. Review the rows
# in the admin panel afterwards (source = "gemini"); untick is_active to drop one.
import json
import re

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError

from apps.search.alias_seed import SEED_ALIASES
from apps.search.aliases import reload_aliases
from apps.search.models import SearchAlias
from apps.search.text_utils import normalize_text


class Command(BaseCommand):
    help = 'Generate profession aliases for more languages with Gemini (stored in DB).'

    def add_arguments(self, parser):
        parser.add_argument('--languages', default='ur,hi,ar,fr,es',
                            help='comma-separated language codes, e.g. ur,hi,ar,fr,es,bn,tr')
        parser.add_argument('--dry-run', action='store_true')

    def handle(self, *args, **opts):
        from google import genai
        from google.genai import types as genai_types
        from apps.ai_engine.views import _gemini_api_key

        api_key = _gemini_api_key()
        if not api_key:
            raise CommandError('GEMINI_API_KEY is not configured')
        models = [m.strip() for m in str(getattr(settings, 'TRANSLATION_GEMINI_MODEL',
                  'models/gemini-flash-latest')).split(',') if m.strip()]
        client = genai.Client(api_key=api_key,
                              http_options=genai_types.HttpOptions(timeout=60000))
        professions = sorted(SEED_ALIASES)
        existing = set(SearchAlias.objects.values_list('alias', 'canonical'))
        added = 0

        for lang in [l.strip() for l in opts['languages'].split(',') if l.strip()]:
            prompt = (
                f'For each profession below give up to 4 common words or short phrases that '
                f'people in language "{lang}" type when searching for that profession, written '
                f'in the language\'s native script AND (if it is not Latin-based) one common '
                f'Latin-letter spelling. Return ONLY a JSON object mapping each profession to a '
                f'list of strings. No commentary, no markdown.\n'
                f'Professions: {json.dumps(professions)}'
            )
            resp, err = None, None
            for model in models:
                try:
                    resp = client.models.generate_content(model=model, contents=prompt)
                    break
                except Exception as e:                      # noqa: BLE001
                    err = e
            if resp is None:
                self.stderr.write(f'[{lang}] Gemini failed: {str(err)[:160]}')
                continue
            raw = re.sub(r'^```json\s*|^```\s*|```$', '', (resp.text or '').strip(),
                         flags=re.MULTILINE).strip()
            try:
                data = json.loads(raw)
            except ValueError:
                self.stderr.write(f'[{lang}] could not parse response')
                continue
            for canon, words in (data or {}).items():
                canon = str(canon).strip().lower()
                if canon not in SEED_ALIASES or not isinstance(words, list):
                    continue                                # ignore anything unexpected
                for w in words:
                    w = str(w).strip()[:100]
                    if not normalize_text(w) or (w, canon) in existing:
                        continue
                    existing.add((w, canon))
                    added += 1
                    if not opts['dry_run']:
                        SearchAlias.objects.get_or_create(
                            alias=w, canonical=canon,
                            defaults={'language': lang[:10], 'source': 'gemini'})
            self.stdout.write(f'[{lang}] done')

        reload_aliases()
        self.stdout.write(self.style.SUCCESS(
            f'{"Would add" if opts["dry_run"] else "Added"} {added} aliases.'))
