# apps/support/tests_privacy_page.py
#
# Run with:  python manage.py test apps.support.tests_privacy_page

from django.test import TestCase

from apps.admin_panel.models import Language
from apps.support.models import PolicyDocument, PolicyTranslation, PolicyVersion


class PrivacyPageTests(TestCase):
    url = '/privacy/'

    @classmethod
    def setUpTestData(cls):
        cls.en, _ = Language.objects.get_or_create(code='en', defaults={'name': 'English'})
        cls.ur, _ = Language.objects.get_or_create(code='ur', defaults={'name': 'Urdu'})
        Language.objects.filter(code='ur').update(is_rtl=True)

    def _publish(self, en_body='# Data we collect\n\n- Email\n- Name\n\nPlain paragraph.',
                 ur_reviewed=False):
        doc, _ = PolicyDocument.objects.get_or_create(doc_type='privacy')
        v = PolicyVersion.objects.create(document=doc, version_number=1)
        PolicyTranslation.objects.create(version=v, language=self.en, title='Privacy Policy',
                                         body=en_body, is_reviewed=True)
        PolicyTranslation.objects.create(version=v, language=self.ur, title='رازداری کی پالیسی',
                                         body='# ڈیٹا', is_reviewed=ur_reviewed)
        v.status = 'published'
        v.save()

    def test_404_with_friendly_page_when_unpublished(self):
        r = self.client.get(self.url)
        self.assertEqual(r.status_code, 404)
        self.assertContains(r, 'not been published yet', status_code=404)

    def test_renders_headings_and_grouped_bullets(self):
        self._publish()
        r = self.client.get(self.url)
        self.assertEqual(r.status_code, 200)
        html = r.content.decode()
        self.assertIn('<h2>Data we collect</h2>', html)
        self.assertEqual(html.count('<ul>'), 1)            # two bullets -> ONE list
        self.assertIn('<li>Email</li>', html)

    def test_admin_text_is_escaped(self):
        self._publish(en_body='# <script>alert(1)</script>')
        html = self.client.get(self.url).content.decode()
        self.assertNotIn('<script>alert(1)</script>', html)
        self.assertIn('&lt;script&gt;', html)

    def test_unreviewed_urdu_shows_english_with_note_and_ltr(self):
        self._publish(ur_reviewed=False)
        r = self.client.get(self.url, {'lang': 'ur'})
        self.assertContains(r, 'Privacy Policy')
        self.assertContains(r, 'reviewed translation')
        self.assertNotContains(r, 'dir="rtl"')

    def test_reviewed_urdu_is_rtl(self):
        self._publish(ur_reviewed=True)
        r = self.client.get(self.url, {'lang': 'ur'})
        self.assertContains(r, 'dir="rtl"')
        self.assertContains(r, 'رازداری کی پالیسی')

    def test_unknown_lang_falls_back_to_english(self):
        self._publish()
        self.assertEqual(self.client.get(self.url, {'lang': 'zz'}).status_code, 200)

    def test_post_not_allowed(self):
        self.assertEqual(self.client.post(self.url).status_code, 405)
