# apps/support/tests_public_api.py
#
# Run with:  python manage.py test apps.support.tests_public_api

from datetime import date

from django.test import TestCase
from rest_framework.test import APIClient

from apps.admin_panel.models import Language
from apps.support.models import (
    HelpArticle, HelpArticleTranslation, HelpCategory, HelpCategoryTranslation,
    PolicyDocument, PolicyTranslation, PolicyVersion,
)
from apps.support.presenters import parse_blocks


class Base(TestCase):
    @classmethod
    def setUpTestData(cls):
        cls.en, _ = Language.objects.get_or_create(code='en', defaults={'name': 'English'})
        cls.ur, _ = Language.objects.get_or_create(
            code='ur', defaults={'name': 'Urdu', 'is_rtl': True})
        if not cls.ur.is_rtl:
            cls.ur.is_rtl = True
            cls.ur.save()

    def setUp(self):
        self.client = APIClient()


class ParseBlocksTests(TestCase):
    def test_headings_paragraphs_bullets(self):
        body = '# Title\n\nline one\nline two\n\n- a\n- b\n'
        self.assertEqual(parse_blocks(body), [
            {'type': 'heading', 'text': 'Title'},
            {'type': 'paragraph', 'text': 'line one line two'},
            {'type': 'bullet', 'text': 'a'},
            {'type': 'bullet', 'text': 'b'},
        ])

    def test_empty(self):
        self.assertEqual(parse_blocks(''), [])


class PrivacyPolicyApiTests(Base):
    url = '/api/support/policies/privacy/'

    def _doc(self):
        return PolicyDocument.objects.get_or_create(doc_type='privacy')[0]

    def _version(self, number, status, en_body='# H\n\nText'):
        v = PolicyVersion.objects.create(document=self._doc(), version_number=number,
                                         effective_date=date(2026, 10, 1))
        PolicyTranslation.objects.create(version=v, language=self.en, title=f'EN v{number}',
                                         body=en_body, is_reviewed=True)
        if status != 'draft':
            v.status = status
            v.save()
        return v

    def test_404_when_nothing_published(self):
        self._version(1, 'draft')
        self.assertEqual(self.client.get(self.url).status_code, 404)

    def test_draft_never_leaks_and_latest_published_wins(self):
        self._version(1, 'published')
        self._version(2, 'draft')
        r = self.client.get(self.url)
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data['version'], 1)
        self.assertEqual(r.data['title'], 'EN v1')

    def test_unreviewed_urdu_falls_back_to_english(self):
        v = PolicyVersion.objects.create(document=self._doc(), version_number=1)
        PolicyTranslation.objects.create(version=v, language=self.en, title='EN', body='x',
                                         is_reviewed=True)
        PolicyTranslation.objects.create(version=v, language=self.ur, title='UR', body='y',
                                         is_reviewed=False)
        v.status = 'published'
        v.save()
        r = self.client.get(self.url, {'lang': 'ur'})
        self.assertEqual(r.data['title'], 'EN')
        self.assertTrue(r.data['is_fallback'])
        self.assertEqual(r.data['language'], 'en')
        self.assertEqual(r.data['requested_language'], 'ur')

    def test_reviewed_urdu_is_served_with_rtl(self):
        v = PolicyVersion.objects.create(document=self._doc(), version_number=1)
        PolicyTranslation.objects.create(version=v, language=self.en, title='EN', body='x',
                                         is_reviewed=True)
        PolicyTranslation.objects.create(version=v, language=self.ur, title='UR', body='y',
                                         is_reviewed=True)
        v.status = 'published'
        v.save()
        r = self.client.get(self.url, {'lang': 'ur'})
        self.assertEqual(r.data['title'], 'UR')
        self.assertFalse(r.data['is_fallback'])
        self.assertTrue(r.data['is_rtl'])

    def test_bad_token_does_not_break_public_endpoint(self):
        self._version(1, 'published')
        r = self.client.get(self.url, HTTP_AUTHORIZATION='Bearer not-a-token')
        self.assertEqual(r.status_code, 200)


class HelpCenterApiTests(Base):
    @classmethod
    def setUpTestData(cls):
        super().setUpTestData()
        cls.cat = HelpCategory.objects.create(slug='payments', icon_key='payments')
        HelpCategoryTranslation.objects.create(
            category=cls.cat, language=cls.en, title='Payments', is_reviewed=True)
        cls.pro_cat = HelpCategory.objects.create(slug='earnings', audience='professional')
        HelpCategoryTranslation.objects.create(
            category=cls.pro_cat, language=cls.en, title='Earnings', is_reviewed=True)
        cls.off_cat = HelpCategory.objects.create(slug='old', is_active=False)
        HelpCategoryTranslation.objects.create(
            category=cls.off_cat, language=cls.en, title='Old', is_reviewed=True)

        cls.a1 = cls._article('refund-policy', cls.cat, True, 'How refunds work',
                              'Refunds take 5 days.')
        cls.draft = cls._article('draft-art', cls.cat, False, 'Hidden draft', 'secret refunds')
        cls.pro_a = cls._article('withdraw', cls.pro_cat, True, 'Withdraw earnings',
                                 'Pro only text', audience='professional')
        HelpArticleTranslation.objects.create(
            article=cls.a1, language=cls.ur, title='UR title', body='رقم واپسی', is_reviewed=False)

    @classmethod
    def _article(cls, slug, cat, published, title, body, audience='all'):
        a = HelpArticle.objects.create(category=cat, slug=slug, is_published=published,
                                       audience=audience)
        HelpArticleTranslation.objects.create(article=a, language=cls.en, title=title, body=body,
                                              is_reviewed=True)
        return a

    def test_categories_guest_sees_only_all_audience_active(self):
        r = self.client.get('/api/support/help/categories/')
        self.assertEqual([c['slug'] for c in r.data['results']], ['payments'])
        self.assertEqual(r.data['results'][0]['article_count'], 1)   # draft not counted

    def test_categories_professional_audience_added(self):
        r = self.client.get('/api/support/help/categories/', {'audience': 'professional'})
        self.assertEqual({c['slug'] for c in r.data['results']}, {'payments', 'earnings'})

    def test_article_list_hides_drafts_and_other_audience(self):
        r = self.client.get('/api/support/help/articles/')
        self.assertEqual([a['slug'] for a in r.data['results']], ['refund-policy'])

    def test_search_matches_and_excludes_drafts(self):
        r = self.client.get('/api/support/help/articles/', {'q': 'REFUND'})
        self.assertEqual([a['slug'] for a in r.data['results']], ['refund-policy'])

    def test_search_does_not_match_unreviewed_translation_text(self):
        r = self.client.get('/api/support/help/articles/', {'q': 'رقم'})
        self.assertEqual(r.data['count'], 0)

    def test_search_too_short_returns_empty(self):
        r = self.client.get('/api/support/help/articles/', {'q': 'a'})
        self.assertEqual(r.data['count'], 0)

    def test_category_filter(self):
        r = self.client.get('/api/support/help/articles/', {'category': 'earnings'})
        self.assertEqual(r.data['count'], 0)                 # guest can't see professional audience
        r = self.client.get('/api/support/help/articles/',
                            {'category': 'earnings', 'audience': 'professional'})
        self.assertEqual(r.data['count'], 1)

    def test_detail_ok_draft_404_wrong_audience_404(self):
        ok = self.client.get('/api/support/help/articles/refund-policy/')
        self.assertEqual(ok.status_code, 200)
        self.assertEqual(ok.data['title'], 'How refunds work')
        self.assertIn('blocks', ok.data)
        self.assertEqual(self.client.get('/api/support/help/articles/draft-art/').status_code, 404)
        self.assertEqual(self.client.get('/api/support/help/articles/withdraw/').status_code, 404)

    def test_detail_unreviewed_urdu_is_english_fallback(self):
        r = self.client.get('/api/support/help/articles/refund-policy/', {'lang': 'ur'})
        self.assertEqual(r.data['title'], 'How refunds work')
        self.assertTrue(r.data['is_fallback'])
