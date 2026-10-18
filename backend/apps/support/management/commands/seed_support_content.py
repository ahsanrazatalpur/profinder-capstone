# apps/support/management/commands/seed_support_content.py
#
# Usage:
#   python manage.py seed_support_content
#   python manage.py seed_support_content --refresh            # overwrite DRAFT policy text
#   python manage.py seed_support_content --create-languages   # create missing en/ur rows
#
# Safe to run repeatedly:
#   * never touches a PUBLISHED / ARCHIVED policy version (they are immutable);
#   * never overwrites existing help text, and never publishes anything;
#   * the policy is created as a DRAFT and Urdu is stored UNREVIEWED.

from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from apps.admin_panel.models import Language
from apps.support import seed_content as C
from apps.support.models import (
    HelpArticle, HelpArticleTranslation, HelpCategory, HelpCategoryTranslation,
    PolicyDocument, PolicyTranslation, PolicyVersion,
)


class Command(BaseCommand):
    help = 'Seed the draft Privacy Policy (EN + UR) and starter Help Center content.'

    def add_arguments(self, parser):
        parser.add_argument('--refresh', action='store_true',
                            help='Overwrite the text of an existing DRAFT policy version.')
        parser.add_argument('--create-languages', action='store_true',
                            help="Create missing 'en' / 'ur' Language rows (status=beta).")

    @transaction.atomic
    def handle(self, *args, **opts):
        langs = self._languages(opts['create_languages'])
        self._seed_policy(langs, opts['refresh'])
        self._seed_help(langs['en'])
        self.stdout.write(self.style.SUCCESS('Done. Nothing was published.'))

    # ── languages ────────────────────────────────────────────────────────────
    def _languages(self, create):
        wanted = {'en': ('English', False), 'ur': ('Urdu', True)}
        found = {}
        for code, (name, rtl) in wanted.items():
            lang = Language.objects.filter(code=code).first()
            if lang is None and create:
                lang = Language.objects.create(code=code, name=name, is_rtl=rtl)
                self.stdout.write(f'Created Language {code} (status=beta).')
            if lang is not None:
                found[code] = lang
        if 'en' not in found:
            raise CommandError("Language 'en' does not exist. Create it in the admin or "
                               "re-run with --create-languages.")
        if 'ur' not in found:
            self.stdout.write(self.style.WARNING("Language 'ur' not found: Urdu text skipped."))
        return found

    # ── policy ───────────────────────────────────────────────────────────────
    def _seed_policy(self, langs, refresh):
        doc, _ = PolicyDocument.objects.get_or_create(doc_type=PolicyDocument.TYPE_PRIVACY)
        version = doc.versions.order_by('-version_number').first()
        if version is None:
            version = PolicyVersion.objects.create(
                document=doc, version_number=1, change_summary=C.POLICY_CHANGE_SUMMARY)
            self.stdout.write('Created privacy policy v1 (draft).')
        elif version.is_locked:
            self.stdout.write(self.style.WARNING(
                f'Privacy policy v{version.version_number} is {version.status}: left untouched. '
                'Create a new version in the admin to change it.'))
            return

        texts = {'en': (C.POLICY_EN_TITLE, C.POLICY_EN_BODY, True),
                 'ur': (C.POLICY_UR_TITLE, C.POLICY_UR_BODY, False)}   # Urdu: NOT reviewed
        for code, (title, body, reviewed) in texts.items():
            lang = langs.get(code)
            if lang is None:
                continue
            row = PolicyTranslation.objects.filter(version=version, language=lang).first()
            if row is None:
                PolicyTranslation.objects.create(version=version, language=lang, title=title,
                                                 body=body, is_reviewed=reviewed)
                self.stdout.write(f'  policy [{code}] created.')
            elif refresh:
                row.title, row.body = title, body
                row.is_reviewed = reviewed
                row.save()
                self.stdout.write(f'  policy [{code}] refreshed.')

        left = sum(t.body.count(C.PLACEHOLDER_MARK) for t in version.translations.all())
        if left:
            self.stdout.write(self.style.WARNING(
                f'  {left} [PLACEHOLDER] marker(s) remain in the draft: fill them in the admin '
                'and have the text reviewed before publishing.'))

    # ── help center (English only, created unpublished) ──────────────────────
    def _seed_help(self, en):
        cats = {}
        for order, (slug, icon, audience, title, desc) in enumerate(C.HELP_CATEGORIES):
            cat, made = HelpCategory.objects.get_or_create(
                slug=slug, defaults={'icon_key': icon, 'audience': audience, 'order': order})
            cats[slug] = cat
            HelpCategoryTranslation.objects.get_or_create(
                category=cat, language=en,
                defaults={'title': title, 'description': desc, 'is_reviewed': True})
        created = 0
        for order, (slug, cat_slug, audience, title, body) in enumerate(C.HELP_ARTICLES):
            art, made = HelpArticle.objects.get_or_create(
                slug=slug, defaults={'category': cats[cat_slug], 'audience': audience,
                                     'order': order, 'is_published': False})
            created += made
            HelpArticleTranslation.objects.get_or_create(
                article=art, language=en,
                defaults={'title': title, 'body': body, 'is_reviewed': True})
        self.stdout.write(f'Help Center: {len(cats)} categories, {created} new article(s) '
                          '(unpublished: review and publish them in the admin).')
