# apps/support/tests_admin_content.py
#
# Run with:  python manage.py test apps.support.tests_admin_content

from django.core.cache import cache
from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from apps.admin_panel.models import Language
from apps.support.models import (
    HelpArticle, HelpArticleTranslation, HelpCategory, HelpCategoryTranslation,
    PolicyDocument, PolicyTranslation, PolicyVersion,
)
from apps.users.models import User

POLICY = '/api/support/admin/policy/'
ARTICLES = '/api/support/admin/help/articles/'


def make_user(email, role):
    return User.objects.create_user(email=email, name=email.split('@')[0], role=role,
                                    password='Passw0rd!x')


@override_settings(PASSWORD_HASHERS=['django.contrib.auth.hashers.MD5PasswordHasher'])
class Base(TestCase):
    def setUp(self):
        cache.clear()
        self.en = Language.objects.get_or_create(code='en', defaults={'name': 'English'})[0]
        self.ur = Language.objects.get_or_create(code='ur', defaults={'name': 'Urdu', 'is_rtl': True})[0]
        self.admin = make_user('admin@example.com', 'admin')
        self.customer = make_user('cust@example.com', 'customer')
        self.api = self.client_for(self.admin)

    def client_for(self, user):
        c = APIClient()
        c.force_authenticate(user)
        return c

    def draft(self, body='Hello policy.', title='Privacy Policy', number=1):
        doc, _ = PolicyDocument.objects.get_or_create(doc_type='privacy')
        v = PolicyVersion.objects.create(document=doc, version_number=number)
        PolicyTranslation.objects.create(version=v, language=self.en, title=title, body=body,
                                         is_reviewed=True)
        return v

    def category(self, slug='account'):
        c, made = HelpCategory.objects.get_or_create(slug=slug)
        if made:
            HelpCategoryTranslation.objects.create(category=c, language=self.en, title='Account')
        return c

    def article(self, cat=None, slug='reset', published=False, title='Reset password',
                body='Tap forgot password.'):
        cat = cat or self.category()
        a = HelpArticle.objects.create(category=cat, slug=slug, is_published=published)
        HelpArticleTranslation.objects.create(article=a, language=self.en, title=title,
                                              body=body, is_reviewed=True)
        return a


class AccessTests(Base):
    def test_anonymous_gets_401_and_non_admins_get_403(self):
        v = self.draft()
        a = self.article()
        urls = [POLICY, f'{POLICY}{v.pk}/', ARTICLES, f'{ARTICLES}{a.pk}/',
                '/api/support/admin/help/categories/']
        for url in urls:
            self.assertEqual(APIClient().get(url).status_code, 401, url)
            self.assertEqual(self.client_for(self.customer).get(url).status_code, 403, url)
        self.assertEqual(self.client_for(self.customer).post(f'{POLICY}{v.pk}/publish/').status_code, 403)
        self.assertEqual(self.client_for(self.customer).patch(f'{ARTICLES}{a.pk}/', {'title': 'x'},
                                                              format='json').status_code, 403)
        v.refresh_from_db()
        self.assertEqual(v.status, 'draft')


class PolicyTests(Base):
    def test_list_and_detail_show_english_text_and_placeholder_count(self):
        v = self.draft(body='Run by [PLACEHOLDER: NAME] at [PLACEHOLDER: ADDRESS].')
        r = self.api.get(POLICY)
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data['results'][0]['placeholders_left'], 2)
        d = self.api.get(f'{POLICY}{v.pk}/').data
        self.assertIn('[PLACEHOLDER: NAME]', d['body'])
        self.assertFalse(d['is_locked'])

    def test_edit_draft_saves_text_and_keeps_other_languages(self):
        v = self.draft()
        PolicyTranslation.objects.create(version=v, language=self.ur, title='u', body='u',
                                         is_reviewed=False)
        r = self.api.patch(f'{POLICY}{v.pk}/', {'body': 'New text', 'title': 'Privacy',
                                                'change_summary': 'Fixed', 'effective_date': '2026-11-01'},
                           format='json')
        self.assertEqual(r.status_code, 200, r.data)
        row = PolicyTranslation.objects.get(version=v, language=self.en)
        self.assertEqual((row.body, row.title), ('New text', 'Privacy'))
        v.refresh_from_db()
        self.assertEqual(str(v.effective_date), '2026-11-01')
        ur = PolicyTranslation.objects.get(version=v, language=self.ur)
        self.assertEqual(ur.body, 'u')
        self.assertFalse(ur.is_reviewed)

    def test_edit_validation(self):
        v = self.draft()
        for payload in ({'body': '   '}, {'title': ''}, {'body': 'x' * 60001},
                        {'effective_date': 'tomorrow'}, {'body': 5}):
            r = self.api.patch(f'{POLICY}{v.pk}/', payload, format='json')
            self.assertEqual(r.status_code, 400, payload)
        self.assertEqual(PolicyTranslation.objects.get(version=v, language=self.en).body, 'Hello policy.')

    def test_cannot_publish_with_placeholders(self):
        v = self.draft(body='Contact [PLACEHOLDER: SUPPORT EMAIL].')
        r = self.api.post(f'{POLICY}{v.pk}/publish/')
        self.assertEqual(r.status_code, 400)
        v.refresh_from_db()
        self.assertEqual(v.status, 'draft')

    def test_publish_sets_status_date_and_archives_old_version(self):
        old = self.draft(body='Old text', number=1)
        self.assertEqual(self.api.post(f'{POLICY}{old.pk}/publish/').status_code, 200)
        new = self.api.post(POLICY).data
        self.assertEqual(new['version'], 2)
        self.assertEqual(new['body'], 'Old text')  # copied from the previous version
        r = self.api.post(f'{POLICY}{new["id"]}/publish/')
        self.assertEqual(r.status_code, 200, r.data)
        old.refresh_from_db()
        self.assertEqual(old.status, 'archived')
        self.assertEqual(r.data['status'], 'published')
        self.assertIsNotNone(r.data['effective_date'])
        self.assertEqual(PolicyVersion.objects.filter(status='published').count(), 1)

    def test_published_version_is_locked_over_the_api(self):
        v = self.draft()
        self.api.post(f'{POLICY}{v.pk}/publish/')
        r = self.api.patch(f'{POLICY}{v.pk}/', {'body': 'sneaky'}, format='json')
        self.assertEqual(r.status_code, 409)
        self.assertEqual(self.api.post(f'{POLICY}{v.pk}/publish/').status_code, 409)
        self.assertEqual(PolicyTranslation.objects.get(version=v, language=self.en).body, 'Hello policy.')

    def test_new_version_needs_no_open_draft_and_first_one_works_from_nothing(self):
        r = self.api.post(POLICY)
        self.assertEqual(r.status_code, 201)
        self.assertEqual(r.data['version'], 1)
        self.assertEqual(self.api.post(POLICY).status_code, 409)  # draft already exists

    def test_public_endpoint_serves_what_was_published(self):
        v = self.draft(body='# Title\n\nPublic text.')
        self.assertEqual(APIClient().get('/api/support/policies/privacy/').status_code, 404)
        self.api.post(f'{POLICY}{v.pk}/publish/')
        r = APIClient().get('/api/support/policies/privacy/?lang=en')
        self.assertEqual(r.status_code, 200)
        self.assertIn('Public text.', r.data['body'])


class ArticleTests(Base):
    def test_create_starts_unpublished_with_unique_slug(self):
        cat = self.category()
        payload = {'title': 'How do I pay?', 'body': 'Use the Pay button.', 'category_id': cat.pk}
        a = self.api.post(ARTICLES, payload, format='json')
        b = self.api.post(ARTICLES, payload, format='json')
        self.assertEqual(a.status_code, 201, a.data)
        self.assertFalse(a.data['is_published'])
        self.assertEqual(a.data['slug'], 'how-do-i-pay')
        self.assertEqual(b.data['slug'], 'how-do-i-pay-2')

    def test_create_validation(self):
        cat = self.category()
        bad = [{'title': '', 'body': 'x', 'category_id': cat.pk},
               {'title': 'x', 'body': '', 'category_id': cat.pk},
               {'title': 'x', 'body': 'y'},
               {'title': 'x', 'body': 'y', 'category_id': 9999},
               {'title': 'x', 'body': 'y', 'category_id': cat.pk, 'audience': 'robots'}]
        for payload in bad:
            self.assertEqual(self.api.post(ARTICLES, payload, format='json').status_code, 400, payload)
        self.assertEqual(HelpArticle.objects.count(), 0)

    def test_publish_makes_it_visible_in_the_public_api_and_unpublish_hides_it(self):
        a = self.article()
        pub = lambda: [x['slug'] for x in APIClient().get('/api/support/help/articles/').data['results']] \
            if isinstance(APIClient().get('/api/support/help/articles/').data, dict) \
            else [x['slug'] for x in APIClient().get('/api/support/help/articles/').data]
        self.assertNotIn('reset', pub())
        r = self.api.patch(f'{ARTICLES}{a.pk}/', {'is_published': True}, format='json')
        self.assertEqual(r.status_code, 200, r.data)
        self.assertIn('reset', pub())
        self.api.patch(f'{ARTICLES}{a.pk}/', {'is_published': False}, format='json')
        self.assertNotIn('reset', pub())

    def test_edit_updates_text_and_search_index(self):
        a = self.article()
        r = self.api.patch(f'{ARTICLES}{a.pk}/', {'title': 'Withdraw money', 'body': 'Open Wallet.',
                                                  'audience': 'professional'}, format='json')
        self.assertEqual(r.status_code, 200, r.data)
        row = HelpArticleTranslation.objects.get(article=a, language=self.en)
        self.assertEqual(row.title, 'Withdraw money')
        self.assertIn('wallet', row.search_text)
        a.refresh_from_db()
        self.assertEqual(a.audience, 'professional')

    def test_edit_validation_and_cannot_publish_empty(self):
        a = self.article()
        for payload in ({'title': ''}, {'body': 'x' * 20001}, {'audience': 'x'},
                        {'is_published': 'yes'}, {'category_id': 424242}, {'order': 'first'}):
            self.assertEqual(self.api.patch(f'{ARTICLES}{a.pk}/', payload, format='json').status_code,
                             400, payload)

    def test_filters_and_search(self):
        self.article(slug='a', published=True, title='Alpha payments', body='x')
        self.article(slug='b', published=False, title='Beta', body='money')
        slugs = lambda qs: sorted(x['slug'] for x in self.api.get(ARTICLES + qs).data['results'])
        self.assertEqual(slugs(''), ['a', 'b'])
        self.assertEqual(slugs('?published=true'), ['a'])
        self.assertEqual(slugs('?published=false'), ['b'])
        self.assertEqual(slugs('?q=MONEY'), ['b'])

    def test_delete_only_when_unpublished(self):
        a = self.article(published=True)
        self.assertEqual(self.api.delete(f'{ARTICLES}{a.pk}/').status_code, 409)
        self.api.patch(f'{ARTICLES}{a.pk}/', {'is_published': False}, format='json')
        self.assertEqual(self.api.delete(f'{ARTICLES}{a.pk}/').status_code, 204)
        self.assertFalse(HelpArticle.objects.exists())

    def test_category_list(self):
        self.category('billing')
        r = self.api.get('/api/support/admin/help/categories/')
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data['results'][0]['title'], 'Account')
