import json
from unittest import mock

from django.core.cache import cache
from django.http import JsonResponse
from django.test import TestCase, RequestFactory, override_settings

from apps.ai_engine import translation_rules as rules
from apps.ai_engine import translation_service as svc
from apps.ai_engine.middleware import ContentLocalizationMiddleware
from apps.ai_engine.models import LocalizedText
from apps.ai_engine.translation_providers import TranslationProvider, ProviderError

URDU = {'Karachi': 'کراچی', 'Sadia Chandio': 'سعدیہ چانڈیو', 'Nutrition': 'غذائیت',
        'Ramadan Special': 'رمضان اسپیشل', 'Healthy lifestyle is important.': 'صحت مند طرز زندگی اہم ہے۔'}


class FakeProvider(TranslationProvider):
    name = 'fake'
    calls = []
    fail = False

    def translate_batch(self, items, lang, kind, timeout):
        FakeProvider.calls.append((kind, list(items)))
        if FakeProvider.fail:
            raise ProviderError('boom')
        out = {}
        for i in items:
            if i in URDU:
                out[i] = URDU[i]
            else:                     # keep [[P0]] tokens; add an Urdu word to prove translation
                out[i] = 'اردو ' + i
        return out


BASE = dict(
    TRANSLATION_BACKGROUND=False,
    TRANSLATION_ENABLED=True,
    TRANSLATION_DAILY_NEW_LIMIT=1000,
    TRANSLATION_CLIENT_NEW_PER_MINUTE=1000,
    TRANSLATION_LANGUAGES=['ur', 'hi', 'ar', 'es', 'fr'],
    TRANSLATION_CHUNKS_PER_CALL=1,
)


@override_settings(**BASE)
class ServiceTests(TestCase):
    def setUp(self):
        cache.clear()
        FakeProvider.calls, FakeProvider.fail = [], False
        p = mock.patch('apps.ai_engine.translation_service.get_provider', return_value=FakeProvider())
        p.start(); self.addCleanup(p.stop)

    def loc(self, pairs, lang='ur', **kw):
        return svc.localize(pairs, lang, **kw)[0]

    def test_translates_stores_and_caches(self):
        r = self.loc([('city', 'Karachi')])
        self.assertEqual(r[('city', 'Karachi')], 'کراچی')
        self.assertEqual(LocalizedText.objects.count(), 1)
        n = len(FakeProvider.calls)
        r2 = self.loc([('city', 'Karachi')])                 # second access → cache only
        self.assertEqual(r2[('city', 'Karachi')], 'کراچی')
        self.assertEqual(len(FakeProvider.calls), n)

    def test_duplicates_translated_once(self):
        self.loc([('city', 'Karachi')] * 20 + [('name', 'Sadia Chandio')])
        sent = [t for _, items in FakeProvider.calls for t in items]
        self.assertEqual(sent.count('Karachi'), 1)

    def test_batched_single_call_per_kind(self):
        self.loc([('text', f'Hello number {i}') for i in range(10)] + [('name', 'Sadia Chandio')])
        self.assertEqual(len(FakeProvider.calls), 2)          # text batch + name batch

    def test_changed_original_is_new_translation(self):
        self.loc([('city', 'Karachi')])
        r = self.loc([('city', 'Karachi City')])
        self.assertNotEqual(r[('city', 'Karachi City')], 'کراچی')
        self.assertEqual(LocalizedText.objects.count(), 2)

    def test_manual_override_wins_and_is_never_overwritten(self):
        LocalizedText.objects.create(lang='ur', kind='category', source_key=svc.source_key('ur', 'Nutrition'),
                                     source='Nutrition', translated='غذائیات', status='manual')
        r = self.loc([('category', 'Nutrition')])
        self.assertEqual(r[('category', 'Nutrition')], 'غذائیات')
        self.assertEqual(FakeProvider.calls, [])
        svc._store('ur', 'category', svc.source_key('ur', 'Nutrition'), 'Nutrition', 'XXX')
        self.assertEqual(LocalizedText.objects.get().translated, 'غذائیات')

    def test_failure_returns_original_and_does_not_cache_failure(self):
        FakeProvider.fail = True
        r = self.loc([('text', 'Ramadan Special')])
        self.assertEqual(r[('text', 'Ramadan Special')], 'Ramadan Special')
        self.assertEqual(LocalizedText.objects.count(), 0)
        n = len(FakeProvider.calls)
        self.loc([('text', 'Ramadan Special')])               # negative cache: no hammering
        self.assertEqual(len(FakeProvider.calls), n)

    def test_provider_crash_never_raises(self):
        with mock.patch('apps.ai_engine.translation_service.get_provider', side_effect=RuntimeError('x')):
            r = self.loc([('text', 'Anything here')])
        self.assertEqual(r[('text', 'Anything here')], 'Anything here')

    def test_english_and_unsupported_untouched(self):
        self.assertEqual(self.loc([('text', 'Hello world')], 'en')[('text', 'Hello world')], 'Hello world')
        self.assertEqual(self.loc([('text', 'Hello world')], 'xx')[('text', 'Hello world')], 'Hello world')
        self.assertEqual(FakeProvider.calls, [])

    def test_urls_emails_numbers_preserved_inside_sentence(self):
        t = 'Call +92 300 1234567 or mail a.b@x.com, see https://x.com/a?b=1 now'
        r = self.loc([('text', t)])
        out = r[('text', t)]
        for keep in ('+92 300 1234567', 'a.b@x.com', 'https://x.com/a?b=1'):
            self.assertIn(keep, out)
        self.assertTrue(out.startswith('اردو'))

    def test_engine_dropping_token_falls_back_to_original(self):
        class Drop(FakeProvider):
            def translate_batch(self, items, lang, kind, timeout):
                return {i: 'اردو بغیر ٹوکن' for i in items}
        with mock.patch('apps.ai_engine.translation_service.get_provider', return_value=Drop()):
            t = 'Visit https://x.com today'
            self.assertEqual(self.loc([('text', t)])[('text', t)], t)

    def test_long_text_chunked(self):
        t = ('Healthy lifestyle is important. ' * 200).strip()
        r = self.loc([('text', t)])
        self.assertNotEqual(r[('text', t)], t)
        self.assertGreater(len(FakeProvider.calls), 1)

    def test_skip_rules(self):
        for v in ['https://a.com', 'a@b.com', '12345', '+92 300 1234567', 'PK', 'booking_confirmed',
                  '2026-10-09T10:00:00Z', 'photo.jpg', '#FF00AA', 'عربی متن']:
            self.assertFalse(rules.value_translatable(v, 'ur'), v)
        for v in ['Karachi', 'Sadia Chandio', 'Nutrition']:
            self.assertTrue(rules.value_translatable(v, 'ur'), v)

    def test_daily_cap_blocks_new_translations(self):
        with override_settings(TRANSLATION_DAILY_NEW_LIMIT=0):
            r = self.loc([('text', 'Never translated')])
        self.assertEqual(r[('text', 'Never translated')], 'Never translated')
        self.assertEqual(FakeProvider.calls, [])

    def test_prewarm_covers_all_languages(self):
        svc.prewarm([('category', 'Nutrition')], ['ur', 'hi'])
        self.assertEqual(set(LocalizedText.objects.values_list('lang', flat=True)), {'ur', 'hi'})


@override_settings(**BASE)
class MiddlewareTests(TestCase):
    def setUp(self):
        cache.clear()
        FakeProvider.calls, FakeProvider.fail = [], False
        p = mock.patch('apps.ai_engine.translation_service.get_provider', return_value=FakeProvider())
        p.start(); self.addCleanup(p.stop)
        self.rf = RequestFactory()

    def run_mw(self, path, payload, lang='ur', user=None, method='get', **extra):
        mw = ContentLocalizationMiddleware(lambda r: JsonResponse(payload, safe=False))
        req = getattr(self.rf, method)(path, HTTP_X_APP_LANGUAGE=lang, **extra)
        if user is not None:
            req.user = user
        resp = mw(req)
        return resp, json.loads(resp.content)

    PAYLOAD = {'results': [
        {'id': 7, 'name': 'Sadia Chandio', 'city': 'Karachi', 'category_name': 'Nutrition',
         'photo': 'https://x.com/a.jpg', 'email': 'a@b.com', 'status': 'pending',
         'title': 'Ramadan Special', 'rating': 4.5, 'created_at': '2026-10-09T10:00:00Z',
         'tags': ['Nutrition', 'Karachi']}]}

    def test_new_fields_translated_without_any_code(self):
        payload = {'brand_new_headline': 'Ramadan Special', 'brandNewThing': {'subtitle': 'Healthy lifestyle is important.'}}
        _, d = self.run_mw('/api/anything/new/', payload)
        self.assertEqual(d['brand_new_headline'], 'رمضان اسپیشل')
        self.assertEqual(d['brandNewThing']['subtitle'], 'صحت مند طرز زندگی اہم ہے۔')

    def test_generic_payload_and_originals_of_technical_fields_kept(self):
        _, d = self.run_mw('/api/search/professionals/', self.PAYLOAD)
        r = d['results'][0]
        self.assertEqual((r['name'], r['city'], r['category_name'], r['title']),
                         ('سعدیہ چانڈیو', 'کراچی', 'غذائیت', 'رمضان اسپیشل'))
        self.assertEqual(r['tags'], ['غذائیت', 'کراچی'])
        self.assertEqual((r['id'], r['photo'], r['email'], r['status'], r['rating'], r['created_at']),
                         (7, 'https://x.com/a.jpg', 'a@b.com', 'pending', 4.5, '2026-10-09T10:00:00Z'))

    def test_kind_routing_name_is_transliteration_batch(self):
        self.run_mw('/api/search/professionals/', self.PAYLOAD)
        kinds = {k for k, _ in FakeProvider.calls}
        self.assertEqual(kinds, {'name', 'city', 'category', 'text'})

    def test_bare_name_field_is_category_on_category_endpoint_and_person_elsewhere(self):
        self.run_mw('/api/search/categories/', [{'id': 1, 'name': 'Nutrition', 'icon': 'x', 'parent': None}])
        self.assertEqual({k for k, _ in FakeProvider.calls}, {'category'})
        FakeProvider.calls.clear()
        self.run_mw('/api/search/professionals/', {'results': [{'id': 1, 'name': 'Sadia Chandio', 'rating': 4}]})
        self.assertEqual({k for k, _ in FakeProvider.calls}, {'name'})
        FakeProvider.calls.clear()
        self.run_mw('/api/anything/new/', [{'name': 'Physiotherapy', 'icon': 'x', 'is_featured': False}])
        self.assertEqual({k for k, _ in FakeProvider.calls}, {'category'})

    def test_english_untouched(self):
        resp, d = self.run_mw('/api/search/professionals/', self.PAYLOAD, lang='en')
        self.assertEqual(d, self.PAYLOAD); self.assertEqual(FakeProvider.calls, [])

    def test_admin_user_untouched(self):
        admin = mock.Mock(is_authenticated=True, is_staff=False, is_superuser=False, role='admin')
        _, d = self.run_mw('/api/admin-panel/users/', self.PAYLOAD, user=admin)
        self.assertEqual(d, self.PAYLOAD)

    def test_staff_user_untouched(self):
        u = mock.Mock(is_authenticated=True, is_staff=True, is_superuser=False, role='customer')
        _, d = self.run_mw('/api/search/professionals/', self.PAYLOAD, user=u)
        self.assertEqual(d, self.PAYLOAD)

    def test_edit_form_chat_auth_paths_untouched(self):
        for p in ['/api/profiles/professional/', '/api/profiles/user/', '/api/users/me/',
                  '/api/messaging/conversations/', '/api/profiles/portfolio/', '/api/reviews/mine/',
                  '/api/payments/wallet/']:
            _, d = self.run_mw(p, self.PAYLOAD)
            self.assertEqual(d, self.PAYLOAD, p)

    def test_public_profile_still_translated(self):
        _, d = self.run_mw('/api/profiles/professional/12/', self.PAYLOAD)
        self.assertEqual(d['results'][0]['city'], 'کراچی')

    def test_writes_untouched(self):
        for m in ('post', 'put', 'patch', 'delete'):
            _, d = self.run_mw('/api/bookings/', self.PAYLOAD, method=m)
            self.assertEqual(d, self.PAYLOAD, m)

    def test_ai_search_post_allowed(self):
        _, d = self.run_mw('/api/ai/search/', self.PAYLOAD, method='post')
        self.assertEqual(d['results'][0]['city'], 'کراچی')

    def test_failure_serves_original_json(self):
        FakeProvider.fail = True
        _, d = self.run_mw('/api/search/professionals/', self.PAYLOAD)
        self.assertEqual(d, self.PAYLOAD)

    def test_content_length_matches(self):
        resp, _ = self.run_mw('/api/search/professionals/', self.PAYLOAD)
        self.assertEqual(int(resp['Content-Length']), len(resp.content))

    def test_repeated_requests_hit_cache_only(self):
        self.run_mw('/api/search/professionals/', self.PAYLOAD)
        n = len(FakeProvider.calls)
        self.run_mw('/api/search/professionals/', self.PAYLOAD)
        self.assertEqual(len(FakeProvider.calls), n)

    def test_non_json_and_non_api_untouched(self):
        mw = ContentLocalizationMiddleware(lambda r: JsonResponse(self.PAYLOAD))
        req = self.rf.get('/health/', HTTP_X_APP_LANGUAGE='ur')
        self.assertEqual(json.loads(mw(req).content), self.PAYLOAD)

    def test_per_request_cap_limits_new_translations(self):
        with override_settings(TRANSLATION_MAX_NEW_PER_REQUEST=2):
            payload = {'items': [{'title': f'Brand new title {i}'} for i in range(6)]}
            _, d = self.run_mw('/api/search/x/', payload)
        translated = [i for i in d['items'] if i['title'].startswith('اردو')]
        self.assertLessEqual(len(translated), 2)


@override_settings(**BASE)
class PrewarmSignalTests(TestCase):
    def setUp(self):
        cache.clear()
        FakeProvider.calls, FakeProvider.fail = [], False
        p = mock.patch('apps.ai_engine.translation_service.get_provider', return_value=FakeProvider())
        p.start(); self.addCleanup(p.stop)

    def test_new_category_is_prewarmed_for_all_languages(self):
        from apps.search.models import Category
        with self.captureOnCommitCallbacks(execute=True):
            Category.objects.create(name='Nutrition')
        langs = set(LocalizedText.objects.filter(source='Nutrition').values_list('lang', flat=True))
        self.assertEqual(langs, {'ur', 'hi', 'ar', 'es', 'fr'})

    def test_private_models_not_prewarmed(self):
        from apps.admin_panel.models import AdminLog
        from apps.ai_engine.signals import DEFAULT_EXCLUDE_MODELS
        self.assertIn('admin_panel.AdminLog', DEFAULT_EXCLUDE_MODELS)
        self.assertEqual(FakeProvider.calls, [])


@override_settings(**BASE)
class EndToEndTests(TestCase):
    """Real URL routing + real DRF views + real middleware (only the engine is faked)."""

    def setUp(self):
        cache.clear()
        FakeProvider.calls, FakeProvider.fail = [], False
        p = mock.patch('apps.ai_engine.translation_service.get_provider', return_value=FakeProvider())
        p.start(); self.addCleanup(p.stop)

    def test_new_category_appears_translated_in_user_api_without_flutter_changes(self):
        from rest_framework.test import APIClient
        from apps.search.models import Category
        with self.captureOnCommitCallbacks(execute=True):
            Category.objects.create(name='Nutrition')           # "admin adds a new category"
        c = APIClient()
        r = c.get('/api/search/categories/', HTTP_X_APP_LANGUAGE='ur')
        self.assertEqual(r.status_code, 200)
        names = [x['name'] for x in r.json()]
        self.assertIn('غذائیت', names)
        en = c.get('/api/search/categories/').json()
        self.assertIn('Nutrition', [x['name'] for x in en])      # original untouched in DB/API

    def test_new_announcement_translated(self):
        from rest_framework.test import APIClient
        from apps.admin_panel.models import Announcement
        with self.captureOnCommitCallbacks(execute=True):
            Announcement.objects.create(title='Ramadan Special', message='Healthy lifestyle is important.')
        r = APIClient().get('/api/admin-panel/announcements/active/', HTTP_X_APP_LANGUAGE='ur')
        self.assertEqual(r.status_code, 200, r.content[:200])
        self.assertIn('رمضان اسپیشل', r.content.decode())
        self.assertEqual(Announcement.objects.get().title, 'Ramadan Special')

    def test_admin_user_gets_original_admin_panel_data(self):
        from rest_framework.test import APIClient
        from apps.users.models import User
        from apps.search.models import Category
        with self.captureOnCommitCallbacks(execute=True):
            Category.objects.create(name='Nutrition')
        admin = User.objects.create_user(email='a@a.com', password='x', name='Admin', role='admin')
        c = APIClient(); c.force_authenticate(admin)
        r = c.get('/api/search/categories/', HTTP_X_APP_LANGUAGE='ur')
        self.assertIn('Nutrition', [x['name'] for x in r.json()])

    def test_localize_endpoint_requires_auth_and_limits(self):
        from rest_framework.test import APIClient
        c = APIClient()
        self.assertEqual(c.post('/api/ai/localize/', {'lang': 'ur', 'items': []}, format='json').status_code, 401)
        from apps.users.models import User
        u = User.objects.create_user(email='u@u.com', password='x', name='U', role='customer')
        c.force_authenticate(u)
        big = [{'text': f'Item number {i}', 'kind': 'text'} for i in range(41)]
        self.assertEqual(c.post('/api/ai/localize/', {'lang': 'ur', 'items': big}, format='json').status_code, 400)
        ok = c.post('/api/ai/localize/', {'lang': 'ur', 'items': [{'text': 'Karachi', 'kind': 'city'}]}, format='json')
        self.assertEqual(ok.json()['translations']['city']['Karachi'], 'کراچی')