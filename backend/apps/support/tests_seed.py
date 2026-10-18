# apps/support/tests_seed.py
#
# Run with:  python manage.py test apps.support.tests_seed

from io import StringIO

from django.core.management import call_command
from django.core.management.base import CommandError
from django.test import TestCase

from apps.admin_panel.models import Language
from apps.support.models import (
    HelpArticle, PolicyDocument, PolicyTranslation, PolicyVersion,
)


def seed(*args):
    out = StringIO()
    call_command('seed_support_content', *args, stdout=out)
    return out.getvalue()


class SeedCommandTests(TestCase):
    def setUp(self):
        Language.objects.get_or_create(code='en', defaults={'name': 'English'})
        Language.objects.get_or_create(code='ur', defaults={'name': 'Urdu', 'is_rtl': True})

    def _version(self):
        return PolicyDocument.objects.get(doc_type='privacy').versions.get()

    def test_creates_draft_policy_with_unreviewed_urdu(self):
        seed()
        v = self._version()
        self.assertEqual(v.status, 'draft')
        self.assertIsNone(v.published_at)
        en = v.translations.get(language__code='en')
        ur = v.translations.get(language__code='ur')
        self.assertTrue(en.is_reviewed)
        self.assertFalse(ur.is_reviewed)              # AI draft must never be auto-reviewed
        self.assertIn('[PLACEHOLDER', en.body)

    def test_nothing_is_published_and_public_api_stays_404(self):
        seed()
        self.assertFalse(HelpArticle.objects.filter(is_published=True).exists())
        self.assertEqual(self.client.get('/api/support/policies/privacy/').status_code, 404)

    def test_idempotent(self):
        seed()
        seed()
        self.assertEqual(PolicyVersion.objects.count(), 1)
        self.assertEqual(PolicyTranslation.objects.count(), 2)

    def test_does_not_overwrite_admin_edits_without_refresh(self):
        seed()
        t = self._version().translations.get(language__code='en')
        t.body = 'edited by admin'
        t.save()
        seed()
        t.refresh_from_db()
        self.assertEqual(t.body, 'edited by admin')
        seed('--refresh')
        t.refresh_from_db()
        self.assertIn('[PLACEHOLDER', t.body)

    def test_published_version_is_never_touched(self):
        seed()
        v = self._version()
        v.status = 'published'
        v.save()
        out = seed('--refresh')
        self.assertIn('left untouched', out)
        self.assertEqual(PolicyVersion.objects.count(), 1)

    def test_missing_english_is_a_clear_error(self):
        Language.objects.all().delete()
        with self.assertRaises(CommandError):
            seed()

    def test_create_languages_flag(self):
        Language.objects.all().delete()
        seed('--create-languages')
        self.assertEqual(set(Language.objects.values_list('code', flat=True)), {'en', 'ur'})

    def test_missing_urdu_is_skipped_not_fatal(self):
        Language.objects.filter(code='ur').delete()
        seed()
        self.assertEqual(self._version().translations.count(), 1)

    def test_seed_text_markers_parse_to_blocks(self):
        from apps.support.presenters import parse_blocks
        from apps.support import seed_content as C
        kinds = {b['type'] for b in parse_blocks(C.POLICY_EN_BODY)}
        self.assertEqual(kinds, {'heading', 'paragraph', 'bullet'})
