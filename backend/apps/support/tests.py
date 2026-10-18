# apps/support/tests.py
#
# Run with:  python manage.py test apps.support.tests
# (the `apps` folder is a namespace package, so use the module label)

from types import SimpleNamespace
from unittest import mock

from django.core.exceptions import ValidationError
from django.http import JsonResponse
from django.test import RequestFactory, TestCase, override_settings

from apps.admin_panel.models import Language
from apps.ai_engine.middleware import ContentLocalizationMiddleware
from apps.support.models import (
    PolicyDocument, PolicyTranslation, PolicyVersion, SupportTicket,
    HelpArticle, HelpArticleTranslation, HelpCategory,
)
from apps.support.services import resolve_translation
from apps.users.models import User


class TranslationBypassTests(TestCase):
    """The machine-translation middleware must never touch /api/support/."""

    def setUp(self):
        self.rf = RequestFactory()
        payload = {'title': 'Privacy Policy', 'body': 'We collect your email address.'}
        self.mw = ContentLocalizationMiddleware(lambda request: JsonResponse(payload))

    def _eligible(self, path, lang='ur'):
        request = self.rf.get(path, HTTP_X_APP_LANGUAGE=lang)
        request.user = SimpleNamespace(is_authenticated=False)
        response = JsonResponse({'title': 'x'})
        with mock.patch('apps.ai_engine.middleware.svc.lang_supported', return_value=True):
            return self.mw._eligible(request, response)

    def test_control_path_is_still_translated(self):
        # Proves the harness works: a normal public API path IS eligible.
        self.assertEqual(self._eligible('/api/search/categories/'), 'ur')

    def test_support_paths_are_never_eligible(self):
        for path in ('/api/support/policy/privacy/', '/api/support/help/articles/',
                     '/api/support/tickets/', '/api/support/tickets/5/messages/'):
            with self.subTest(path=path):
                self.assertIsNone(self._eligible(path))

    def test_support_paths_stay_denied_even_if_settings_override_deny_list(self):
        with override_settings(TRANSLATION_DENY_PATHS=[]):
            mw = ContentLocalizationMiddleware(lambda r: JsonResponse({}))
        request = self.rf.get('/api/support/policy/privacy/', HTTP_X_APP_LANGUAGE='ur')
        request.user = SimpleNamespace(is_authenticated=False)
        with mock.patch('apps.ai_engine.middleware.svc.lang_supported', return_value=True):
            self.assertIsNone(mw._eligible(request, JsonResponse({'a': 'b'})))

    def test_response_body_is_not_modified_and_provider_not_called(self):
        request = self.rf.get('/api/support/policy/privacy/', HTTP_X_APP_LANGUAGE='ur')
        request.user = SimpleNamespace(is_authenticated=False)
        with mock.patch('apps.ai_engine.middleware.svc.lang_supported', return_value=True), \
             mock.patch('apps.ai_engine.middleware.svc.localize') as localize:
            response = self.mw(request)
        localize.assert_not_called()
        self.assertIn(b'We collect your email address.', response.content)


class ResolveTranslationTests(TestCase):
    def setUp(self):
        self.en = Language.objects.create(name='English', code='en')
        self.ur = Language.objects.create(name='Urdu', code='ur', is_rtl=True)
        self.doc = PolicyDocument.objects.create(doc_type='privacy')
        self.ver = PolicyVersion.objects.create(document=self.doc, version_number=1)

    def _rows(self, ur_reviewed):
        PolicyTranslation.objects.create(version=self.ver, language=self.en, title='Privacy', body='en', is_reviewed=False)
        PolicyTranslation.objects.create(version=self.ver, language=self.ur, title='پرائیویسی', body='ur', is_reviewed=ur_reviewed)
        return list(PolicyTranslation.objects.select_related('language').filter(version=self.ver))

    def test_reviewed_translation_is_served(self):
        row, lang, fallback = resolve_translation(self._rows(True), 'ur')
        self.assertEqual((row.body, lang, fallback), ('ur', 'ur', False))

    def test_unreviewed_translation_falls_back_to_english(self):
        row, lang, fallback = resolve_translation(self._rows(False), 'ur')
        self.assertEqual((row.body, lang, fallback), ('en', 'en', True))

    def test_english_is_never_a_fallback_for_english(self):
        row, lang, fallback = resolve_translation(self._rows(False), 'en-US')
        self.assertEqual((lang, fallback), ('en', False))

    def test_no_content_at_all(self):
        self.assertEqual(resolve_translation([], 'ur'), (None, None, True))


class PolicyImmutabilityTests(TestCase):
    def setUp(self):
        self.en = Language.objects.create(name='English', code='en')
        doc = PolicyDocument.objects.create(doc_type='privacy')
        self.ver = PolicyVersion.objects.create(document=doc, version_number=1)
        self.tr = PolicyTranslation.objects.create(version=self.ver, language=self.en, title='P', body='b')

    def test_draft_is_editable(self):
        self.tr.body = 'edited'
        self.tr.save()

    def test_publish_sets_timestamp_then_locks_everything(self):
        self.ver.status = 'published'
        self.ver.save()
        self.assertIsNotNone(self.ver.published_at)
        self.tr.body = 'tampered'
        with self.assertRaises(ValidationError):
            self.tr.save()
        with self.assertRaises(ValidationError):
            self.tr.delete()
        with self.assertRaises(ValidationError):
            self.ver.delete()
        self.ver.change_summary = 'tampered'
        with self.assertRaises(ValidationError):
            self.ver.save()

    def test_published_cannot_return_to_draft_but_can_archive(self):
        self.ver.status = 'published'
        self.ver.save()
        v = PolicyVersion.objects.get(pk=self.ver.pk)
        v.status = 'draft'
        with self.assertRaises(ValidationError):
            v.save()
        v = PolicyVersion.objects.get(pk=self.ver.pk)
        v.status = 'archived'
        v.save()


class TicketModelTests(TestCase):
    def test_reference_is_generated_from_pk(self):
        t = SupportTicket.objects.create(subject='Help', contact_email='a@b.co')
        t.refresh_from_db()
        self.assertEqual(t.reference, f'PF-{t.pk:06d}')

    def test_ticket_survives_user_deletion(self):
        u = User.objects.create_user(email='u@x.co', name='U', role='customer', password='pw12345678')
        t = SupportTicket.objects.create(user=u, role='customer', subject='Help')
        u.delete()
        t.refresh_from_db()
        self.assertIsNone(t.user)
        self.assertEqual(t.role, 'customer')


class HelpSearchTextTests(TestCase):
    def test_search_text_is_lowercased_title_and_body(self):
        en = Language.objects.create(name='English', code='en')
        cat = HelpCategory.objects.create(slug='bookings')
        art = HelpArticle.objects.create(category=cat, slug='cancel')
        tr = HelpArticleTranslation.objects.create(article=art, language=en, title='Cancel A Booking', body='Open My Bookings')
        self.assertIn('cancel a booking', tr.search_text)
        self.assertTrue(HelpArticleTranslation.objects.filter(search_text__icontains='my bookings').exists())
