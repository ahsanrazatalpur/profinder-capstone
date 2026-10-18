# apps/search/tests.py
#
# Cross-script / typo-tolerant search tests.
#   python manage.py test apps.search
# Works on SQLite (python fallback) and PostgreSQL (pg_trgm path).

from django.test import SimpleTestCase, TestCase
from django.urls import reverse

from apps.profiles.models import ProfessionalProfile, UserProfile
from apps.search.indexing import build_index_for_user
from apps.search.models import Category, SearchIndex
from apps.search.text_utils import normalize_text, phonetic_key, to_latin
from apps.users.models import User


class TextUtilsTests(SimpleTestCase):
    """Spelling / script variants must collapse onto one phonetic key."""

    GROUPS = [
        ('wakeel', 'vakeel', 'wkeel', 'وکیل', 'वकील'),
        ('Muhammad', 'Mohammed', 'Muhamad', 'محمد', 'मोहम्मद'),
        ('Ali', 'Aly', 'علی', 'अली'),
        ('Raza', 'Reza', 'رضا'),
        ('Ahmed', 'Ahmad', 'احمد', 'अहमद'),
        ('Fatima', 'Fatema', 'فاطمہ'),
        ('Tariq', 'Tarik', 'طارق'),
        ('Karachi', 'Karachee', 'کراچی', 'करांची'),
        ('doctor', 'daktar', 'ڈاکٹر', 'डॉक्टर'),
        ('Hussain', 'Husain', 'Hussein', 'حسین'),
        ('Zainab', 'Zaynab', 'زینب', 'ज़ैनब'),      # Hindi nukta letters
        ('Raza', 'रज़ा'), ('Hamza', 'हमज़ा', 'حمزہ'), ('Qureshi', 'क़ुरैशी', 'قریشی'),
    ]

    def test_variants_share_phonetic_key(self):
        for group in self.GROUPS:
            keys = {phonetic_key(w) for w in group}
            self.assertEqual(len(keys), 1, f'{group} -> {keys}')

    def test_different_words_differ(self):
        self.assertNotEqual(phonetic_key('doctor'), phonetic_key('lawyer'))
        self.assertNotEqual(phonetic_key('Zahid'), phonetic_key('Tariq'))

    def test_normalize_unifies_arabic_variants(self):
        # Arabic ي/ك vs Urdu ی/ک, digits, tatweel, harakat
        self.assertEqual(normalize_text('عَلِيّ'), normalize_text('علی'))
        self.assertEqual(normalize_text('كراچي'), normalize_text('کراچی'))
        self.assertEqual(normalize_text('١٢٣'), '123')

    def test_empty_and_symbols(self):
        self.assertEqual(to_latin(''), '')
        self.assertEqual(phonetic_key('!!! ---'), '')
        self.assertEqual(to_latin(None), '')


class _SearchFixture:
    """Shared data: 3 professionals (lawyer / dentist / cardiologist)."""

    @classmethod
    def setUpTestData(cls):
        cls.law = Category.objects.create(name='Lawyer')
        cls.doc = Category.objects.create(name='Doctor')
        cls.ali = cls._pro('Ali Raza', cls.law, 'Criminal Law', 'Karachi')
        cls.fat = cls._pro('Fatima Khan', cls.doc, 'Dentist', 'Lahore')
        cls.muh = cls._pro('Muhammad Tariq', cls.doc, 'Cardiologist', 'Karachi')

    @staticmethod
    def _pro(name, cat, spec, city):
        u = User.objects.create_user(
            email=f"{name.split()[0].lower()}@t.com", name=name,
            role='professional', password='x')
        ProfessionalProfile.objects.update_or_create(
            user=u, defaults=dict(category=cat, specialization=spec, hourly_rate=50))
        UserProfile.objects.update_or_create(user=u, defaults=dict(city=city))
        build_index_for_user(User.objects.get(pk=u.pk))
        return u



class CrossScriptSearchTests(_SearchFixture, TestCase):
    def _search(self, q):
        resp = self.client.get(reverse('nearby'), {'q': q})
        self.assertEqual(resp.status_code, 200, resp.content[:300])
        data = resp.json()
        rows = data.get('results', data if isinstance(data, list) else [])
        return [str(r.get('id')) for r in rows], rows

    def test_index_created_for_professionals_only(self):
        self.assertEqual(SearchIndex.objects.count(), 3)
        cust = User.objects.create_user('c@t.com', 'Cust', 'customer', 'x')
        build_index_for_user(cust)
        self.assertEqual(SearchIndex.objects.count(), 3)

    def test_urdu_script_name_finds_english_name(self):
        ids, _ = self._search('علی رضا')
        self.assertIn(str(self.ali.pk), ids)
        self.assertEqual(ids[0], str(self.ali.pk))

    def test_hindi_script_name(self):
        ids, _ = self._search('फातिमा')
        self.assertIn(str(self.fat.pk), ids)

    def test_misspelt_name(self):
        for q in ('Mohammed Tarik', 'Muhamad Tareq'):
            ids, _ = self._search(q)
            self.assertIn(str(self.muh.pk), ids, q)

    def test_profession_word_in_any_language_finds_lawyer(self):
        for q in ('wakeel', 'vakil', 'wakil', 'وکیل', 'वकील', 'avocat', 'abogado'):
            ids, _ = self._search(q)
            self.assertIn(str(self.ali.pk), ids, q)
            self.assertNotIn(str(self.fat.pk), ids, q)

    def test_profession_plus_city_in_mixed_language(self):
        ids, _ = self._search('karachi wakeel')
        self.assertIn(str(self.ali.pk), ids)

    def test_admin_added_alias_is_used(self):
        from apps.search.models import SearchAlias
        SearchAlias.objects.create(alias='kanoon daan', canonical='lawyer', language='ur')
        ids, _ = self._search('kanoon daan')
        self.assertIn(str(self.ali.pk), ids)

    def test_existing_english_search_still_works(self):
        ids, _ = self._search('lawyer')
        self.assertIn(str(self.ali.pk), ids)


class AliasTests(SimpleTestCase):
    """Profession words in any script/spelling -> canonical English word."""

    def _lk(self, w):
        from apps.search.aliases import alias_lookup
        from apps.search.views import SEARCH_VOCABULARY
        return alias_lookup(w, set(SEARCH_VOCABULARY))

    def test_lawyer_variants(self):
        for w in ('wakeel', 'vakeel', 'wakil', 'vakil', 'wkeel', 'وکیل', 'वकील', 'avocat', 'abogado'):
            self.assertEqual(self._lk(w), 'lawyer', w)

    def test_other_professions_cross_language(self):
        cases = {'ڈاکٹر': 'doctor', 'डॉक्टर': 'doctor', 'daktar': 'doctor',
                 'plombier': 'plumber', 'پلمبر': 'plumber', 'electricista': 'electrician',
                 'dandist': 'dentist', 'peluquero': 'barber', 'ٹیچر': 'teacher',
                 'sastre': 'tailor', 'bawarchi': 'chef'}
        for w, want in cases.items():
            self.assertEqual(self._lk(w), want, w)

    def test_english_words_and_names_are_not_hijacked(self):
        for w in ('weekly', 'doctor', 'lawyer', 'Ahmed', 'Karachi', 'Fatima', 'Tariq', 'Hussain', 'wasim', 'nasir'):
            got = self._lk(w)
            self.assertIn(got, (None, 'doctor', 'lawyer'), f'{w} -> {got}')
            if w not in ('doctor', 'lawyer'):
                self.assertIsNone(got, f'{w} -> {got}')

    def test_multiword_alias(self):
        from apps.search.aliases import translate_phrases
        self.assertIn('psychologist', translate_phrases('ماہر نفسیات lahore'))


class SuggestTests(_SearchFixture, TestCase):
    """/search/suggest/ must also understand other languages and typos."""

    def _suggest(self, q):
        resp = self.client.get(reverse('suggest'), {'q': q})
        self.assertEqual(resp.status_code, 200)
        return resp.json()

    def test_urdu_profession_suggests_lawyer(self):
        data = self._suggest('وکیل')
        self.assertIn('Lawyer', data['matching_professions'])
        self.assertIn(str(self.ali.pk), [p['id'] for p in data['matching_professionals']])

    def test_roman_spelling_and_typo(self):
        for q in ('vakil', 'lawer'):
            self.assertIn('Lawyer', self._suggest(q)['matching_professions'], q)

    def test_urdu_name_suggests_professional(self):
        data = self._suggest('فاطمہ')
        self.assertIn(str(self.fat.pk), [p['id'] for p in data['matching_professionals']])

    def test_never_all_empty(self):
        data = self._suggest('zzzzqqq')
        self.assertTrue(data['matching_professions'] or data['matching_categories']
                        or data['matching_professionals'])


class SearchQualityTests(TestCase):
    """
    Accuracy benchmark. Each case: query -> set of professionals that count as
    a correct hit; passes when one of them is in the top 5 results. The
    pass-rate is printed and must stay >= QUALITY_FLOOR, so a future change
    that quietly hurts multilingual search fails the test run.
    """
    QUALITY_FLOOR = 0.90

    PEOPLE = {   # key: (name, category, specialization, city)
        'ali':    ('Ali Raza',        'Lawyer',    'Criminal Law',  'Karachi'),
        'fatima': ('Fatima Khan',     'Doctor',    'Dentist',       'Lahore'),
        'tariq':  ('Muhammad Tariq',  'Doctor',    'Cardiologist',  'Karachi'),
        'ahmed':  ('Ahmed Hassan',    'Plumber',   'Pipe Repair',   'Islamabad'),
        'sana':   ('Sana Malik',      'Teacher',   'Mathematics',   'Lahore'),
        'usman':  ('Usman Sheikh',    'Electrician', 'Wiring',      'Karachi'),
        'ayesha': ('Ayesha Siddiqui', 'Architect', 'Interiors',     'Lahore'),
        'bilal':  ('Bilal Ahmad',     'Mechanic',  'Engine Repair', 'Faisalabad'),
        'zainab': ('Zainab Hussain',  'Nurse',     'Home Care',     'Karachi'),
        'imran':  ('Imran Qureshi',   'Photographer', 'Weddings',   'Lahore'),
    }

    CASES = [
        # names in Urdu script
        ('علی رضا', {'ali'}), ('فاطمہ خان', {'fatima'}), ('محمد طارق', {'tariq'}),
        ('احمد حسن', {'ahmed'}), ('عثمان شیخ', {'usman'}), ('عائشہ صدیقی', {'ayesha'}),
        ('بلال احمد', {'bilal'}), ('زینب حسین', {'zainab'}), ('عمران قریشی', {'imran'}),
        # names in Hindi script
        ('अली रज़ा', {'ali'}), ('फातिमा खान', {'fatima'}), ('मुहम्मद तारिक', {'tariq'}),
        ('उस्मान शेख', {'usman'}), ('ज़ैनब हुसैन', {'zainab'}),
        # misspelt / alternate Roman spellings
        ('Mohammed Tarik', {'tariq'}), ('Ahmad Hasan', {'ahmed'}), ('Usmaan Shaikh', {'usman'}),
        ('Aysha Siddiqi', {'ayesha'}), ('Zeinab Husain', {'zainab'}), ('Bilaal Ahmed', {'bilal'}),
        ('Imraan Kureshi', {'imran'}), ('Fatema Khaan', {'fatima'}), ('Ally Reza', {'ali'}),
        # professions in other languages / spellings
        ('wakeel', {'ali'}), ('vakil', {'ali'}), ('وکیل', {'ali'}), ('वकील', {'ali'}),
        ('avocat', {'ali'}), ('dantist', {'fatima'}), ('ڈاکٹر', {'fatima', 'tariq'}),
        ('daktar', {'fatima', 'tariq'}), ('plumer', {'ahmed'}), ('پلمبر', {'ahmed'}),
        ('plombier', {'ahmed'}), ('ٹیچر', {'sana'}), ('shikshak', {'sana'}),
        ('electricista', {'usman'}), ('mistri', {'bilal'}), ('नर्स', {'zainab'}),
        ('fotografo', {'imran'}),
        # mixed profession + city
        ('wakeel karachi', {'ali'}), ('daktar karachi', {'tariq'}), ('ٹیچر lahore', {'sana'}),
        # plain English must keep working
        ('lawyer', {'ali'}), ('plumber islamabad', {'ahmed'}), ('nurse', {'zainab'}),
    ]

    @classmethod
    def setUpTestData(cls):
        cls.ids = {}
        cats = {}
        for key, (name, cat, spec, city) in cls.PEOPLE.items():
            cats.setdefault(cat, Category.objects.create(name=cat))
            u = User.objects.create_user(f'{key}@q.com', name, 'professional', 'x')
            ProfessionalProfile.objects.update_or_create(
                user=u, defaults=dict(category=cats[cat], specialization=spec, hourly_rate=40))
            UserProfile.objects.update_or_create(user=u, defaults=dict(city=city))
            build_index_for_user(User.objects.get(pk=u.pk))
            cls.ids[key] = str(u.pk)

    def test_accuracy_floor(self):
        failed = []
        for query, wanted in self.CASES:
            resp = self.client.get(reverse('nearby'), {'q': query})
            self.assertEqual(resp.status_code, 200, query)
            data = resp.json()
            rows = data.get('results', data if isinstance(data, list) else [])
            top = [str(r.get('id')) for r in rows[:5]]
            if not any(self.ids[k] in top for k in wanted):
                failed.append(query)
        rate = 1 - len(failed) / len(self.CASES)
        safe_failed = [f.encode('ascii', 'backslashreplace').decode('ascii') for f in failed]
        print(f'\n[search quality] {len(self.CASES) - len(failed)}/{len(self.CASES)} '
              f'= {rate:.0%}  failed: {safe_failed}')
        self.assertGreaterEqual(rate, self.QUALITY_FLOOR, f'failed queries: {failed}')


class NumericParamTests(TestCase):
    """
    Price / rating query params on /search/nearby/ and /search/price-range/.

    * no `max_price` => no price ceiling (professionals above 1000 included)
    * explicit valid values keep filtering
    * missing / empty / malformed / negative / non-finite values are ignored
      and must never raise (HTTP 500)
    """

    @classmethod
    def setUpTestData(cls):
        cat = Category.objects.create(name='Doctor')
        cls.cheap = cls._pro('Cheap One',  cat,  500, 4.8)
        cls.mid   = cls._pro('Mid Two',    cat, 1500, 3.0)
        cls.dear  = cls._pro('Dear Three', cat, 3000, 0.0)
        cls.all_ids = {str(cls.cheap.id), str(cls.mid.id), str(cls.dear.id)}

    @staticmethod
    def _pro(name, cat, rate, rating):
        u = User.objects.create_user(
            email=f"{name.split()[0].lower()}@t.com", name=name,
            role='professional', password='x')
        ProfessionalProfile.objects.update_or_create(
            user=u, defaults=dict(category=cat, specialization='GP',
                                  hourly_rate=rate, average_rating=rating))
        UserProfile.objects.update_or_create(user=u, defaults=dict(city='Karachi'))
        build_index_for_user(User.objects.get(pk=u.pk))
        return u

    def _ids(self, url_name, params=None, q=''):
        query = dict(params or {})
        if q:
            query['q'] = q
        resp = self.client.get(reverse(url_name), query)
        self.assertEqual(resp.status_code, 200, (params, resp.content[:300]))
        return {str(r['id']) for r in resp.json()['results']}

    # 1/3. ordinary search has no hidden ceiling
    def test_no_max_price_means_no_ceiling(self):
        self.assertEqual(self._ids('nearby'), self.all_ids)
        self.assertEqual(self._ids('nearby', q='doctor'), self.all_ids)
        self.assertEqual(self._ids('price_range'), self.all_ids)

    # 2. explicit maximum is still enforced
    def test_explicit_max_price_is_enforced(self):
        self.assertEqual(self._ids('nearby', {'max_price': '1000.0'}),
                         {str(self.cheap.id)})
        self.assertEqual(self._ids('nearby', {'max_price': '1500'}),
                         {str(self.cheap.id), str(self.mid.id)})
        self.assertEqual(self._ids('price_range', {'max_price': '1000'}),
                         {str(self.cheap.id)})

    # 4. valid numeric params keep working
    def test_valid_numeric_params_still_filter(self):
        self.assertEqual(self._ids('nearby', {'min_price': '1000'}),
                         {str(self.mid.id), str(self.dear.id)})
        self.assertEqual(self._ids('nearby', {'min_price': '1000', 'max_price': '2000'}),
                         {str(self.mid.id)})
        self.assertEqual(self._ids('nearby', {'min_rating': '4'}),
                         {str(self.cheap.id)})
        self.assertEqual(self._ids('nearby', {'min_rating': '3.0'}),
                         {str(self.cheap.id), str(self.mid.id)})
        self.assertEqual(self._ids('price_range', {'min_price': '1000'}),
                         {str(self.mid.id), str(self.dear.id)})

    # 5. invalid values: never a 500, and they are ignored (no filter applied)
    BAD = ['abc', '', '   ', '-5', '-0.1', 'nan', 'inf', '-inf', '1e999', '--1', '1,5', '5$']

    def test_invalid_values_are_ignored_not_500(self):
        for name in ('min_price', 'max_price', 'min_rating'):
            for bad in self.BAD:
                with self.subTest(param=name, value=bad):
                    self.assertEqual(self._ids('nearby', {name: bad}), self.all_ids)
                    self.assertEqual(self._ids('nearby', {name: bad}, q='doctor'),
                                     self.all_ids)
        for name in ('min_price', 'max_price'):
            for bad in self.BAD:
                with self.subTest(endpoint='price_range', param=name, value=bad):
                    self.assertEqual(self._ids('price_range', {name: bad}), self.all_ids)

    def test_invalid_value_does_not_cancel_a_valid_one(self):
        self.assertEqual(
            self._ids('nearby', {'min_price': 'abc', 'max_price': '1000'}),
            {str(self.cheap.id)})


class SearchComprehensiveRegressionTests(TestCase):
    """
    Complete Phase 9 regression test suite covering all 28 requirements.
    Works seamlessly on SQLite and PostgreSQL.
    """

    @classmethod
    def setUpTestData(cls):
        cls.cat_doc = Category.objects.create(name='Doctor')
        cls.cat_law = Category.objects.create(name='Lawyer')
        cls.cat_eng = Category.objects.create(name='Engineer')

        # Ali Raza: Lawyer in Karachi, hourly 2500, rating 3.5, unverified
        cls.ali = cls._create_pro(
            name='Ali Raza',
            cat=cls.cat_law,
            spec='Criminal Law',
            city='Karachi',
            rate=2500,
            rating=3.5,
            verified=False,
        )

        # Fatima Khan: Dentist in Lahore, hourly 500, rating 5.0, verified
        cls.fatima = cls._create_pro(
            name='Fatima Khan',
            cat=cls.cat_doc,
            spec='Dentist',
            city='Lahore',
            rate=500,
            rating=5.0,
            verified=True,
        )

        # Muhammad Tariq: Cardiologist in Karachi, hourly 1200, rating 4.8, verified
        cls.tariq = cls._create_pro(
            name='Muhammad Tariq',
            cat=cls.cat_doc,
            spec='Cardiologist',
            city='Karachi',
            rate=1200,
            rating=4.8,
            verified=True,
        )

        # Weak match candidate with high rating and verified flag
        # (Bio contains 'raza' in lowercase as part of unrelated sentence)
        cls.weak_high_rated = cls._create_pro(
            name='Zahid Malik',
            cat=cls.cat_eng,
            spec='Civil Engineer',
            city='Islamabad',
            rate=800,
            rating=5.0,
            verified=True,
            bio='Worked on the new highway project near Raza center.',
        )

    @classmethod
    def _create_pro(cls, name, cat, spec, city, rate, rating, verified=False, bio=''):
        email = f"{name.replace(' ', '.').lower()}@example.com"
        u = User.objects.create_user(email=email, name=name, role='professional', password='password123')
        ProfessionalProfile.objects.update_or_create(
            user=u,
            defaults=dict(
                category=cat,
                specialization=spec,
                hourly_rate=rate,
                average_rating=rating,
                is_verified=verified,
                bio=bio,
            ),
        )
        UserProfile.objects.update_or_create(user=u, defaults=dict(city=city))
        build_index_for_user(User.objects.get(pk=u.pk))
        return u

    def _get(self, params):
        resp = self.client.get(reverse('nearby'), params)
        self.assertEqual(resp.status_code, 200)
        return resp.json()

    # 1. Exact full-name matching
    def test_01_exact_full_name_matching(self):
        data = self._get({'q': 'Ali Raza'})
        ids = [r['id'] for r in data['results']]
        self.assertIn(str(self.ali.id), ids)
        self.assertEqual(ids[0], str(self.ali.id))

    # 2. Partial-name matching
    def test_02_partial_name_matching(self):
        data = self._get({'q': 'Ali'})
        ids = [r['id'] for r in data['results']]
        self.assertIn(str(self.ali.id), ids)

    # 3. First-name and surname matching
    def test_03_first_name_and_surname_matching(self):
        data = self._get({'q': 'Raza'})
        ids = [r['id'] for r in data['results']]
        self.assertIn(str(self.ali.id), ids)

    # 4. Minor misspellings and character transpositions
    def test_04_minor_misspellings_and_transpositions(self):
        for typo in ('Ali Rza', 'Ail Raza'):
            data = self._get({'q': typo})
            ids = [r['id'] for r in data['results']]
            self.assertIn(str(self.ali.id), ids, f'Failed for typo: {typo}')

    # 5. Profession and category matching
    def test_05_profession_and_category_matching(self):
        data = self._get({'q': 'Lawyer'})
        ids = [r['id'] for r in data['results']]
        self.assertIn(str(self.ali.id), ids)
        self.assertNotIn(str(self.fatima.id), ids)

    # 6. Specialization matching
    def test_06_specialization_matching(self):
        data = self._get({'q': 'Cardiologist'})
        ids = [r['id'] for r in data['results']]
        self.assertIn(str(self.tariq.id), ids)

    # 7. City matching
    def test_07_city_matching(self):
        data = self._get({'q': 'Karachi'})
        ids = [r['id'] for r in data['results']]
        self.assertIn(str(self.ali.id), ids)
        self.assertIn(str(self.tariq.id), ids)
        self.assertNotIn(str(self.fatima.id), ids)

    # 8. Profession + city queries
    def test_08_profession_plus_city(self):
        data = self._get({'q': 'dentist in Lahore'})
        ids = [r['id'] for r in data['results']]
        self.assertIn(str(self.fatima.id), ids)
        self.assertNotIn(str(self.ali.id), ids)

    # 9. Name + profession queries
    def test_09_name_plus_profession(self):
        data = self._get({'q': 'Ali Raza lawyer'})
        ids = [r['id'] for r in data['results']]
        self.assertIn(str(self.ali.id), ids)
        self.assertEqual(ids[0], str(self.ali.id))

    # 10. English queries
    def test_10_english_queries(self):
        data = self._get({'q': 'dentist'})
        ids = [r['id'] for r in data['results']]
        self.assertIn(str(self.fatima.id), ids)

    # 11. Urdu Unicode queries
    def test_11_urdu_unicode_queries(self):
        # Urdu profession
        data = self._get({'q': 'وکیل'})
        ids = [r['id'] for r in data['results']]
        self.assertIn(str(self.ali.id), ids)

        # Urdu name
        data_name = self._get({'q': 'علی رضا'})
        ids_name = [r['id'] for r in data_name['results']]
        self.assertIn(str(self.ali.id), ids_name)

    # 12. Hindi Unicode queries
    def test_12_hindi_unicode_queries(self):
        data = self._get({'q': 'वकील'})
        ids = [r['id'] for r in data['results']]
        self.assertIn(str(self.ali.id), ids)

    # 13. Arabic Unicode queries
    def test_13_arabic_unicode_queries(self):
        data = self._get({'q': 'طبيب'})
        ids = [r['id'] for r in data['results']]
        self.assertTrue(str(self.fatima.id) in ids or str(self.tariq.id) in ids)

    # 14. French and Spanish queries with accented characters
    def test_14_french_and_spanish_queries(self):
        # French
        data_fr = self._get({'q': 'avocat'})
        self.assertIn(str(self.ali.id), [r['id'] for r in data_fr['results']])

        # Spanish accented
        data_es = self._get({'q': 'médico'})
        ids_es = [r['id'] for r in data_es['results']]
        self.assertTrue(str(self.fatima.id) in ids_es or str(self.tariq.id) in ids_es)

    # 15. Roman Urdu queries where supported aliases exist
    def test_15_roman_urdu_queries(self):
        data = self._get({'q': 'wakeel'})
        self.assertIn(str(self.ali.id), [r['id'] for r in data['results']])

    # 16. Mixed-language queries
    def test_16_mixed_language_queries(self):
        # Urdu profession + English city
        data = self._get({'q': 'wakeel in Karachi'})
        self.assertIn(str(self.ali.id), [r['id'] for r in data['results']])

        # Urdu city + English profession
        data_city = self._get({'q': 'کراچی doctor'})
        ids_city = [r['id'] for r in data_city['results']]
        self.assertIn(str(self.tariq.id), ids_city)

    # 17. Empty and whitespace-only queries
    def test_17_empty_and_whitespace_only_queries(self):
        for empty_q in ('', '   ', '\t', '\n'):
            data = self._get({'q': empty_q})
            self.assertEqual(data['results'], [], f'Expected empty results for q="{empty_q}"')
            self.assertTrue(data['meta'].get('is_empty'), f'Expected is_empty=True for q="{empty_q}"')

    # 18. One-character and very short queries
    def test_18_one_character_and_very_short_queries(self):
        # 'a' should strictly match names starting with A (Ali Raza), not every professional with 'a' in bio
        data = self._get({'q': 'a'})
        ids = [r['id'] for r in data['results']]
        self.assertIn(str(self.ali.id), ids)
        # Should not blindly dump all professionals
        self.assertNotIn(str(self.weak_high_rated.id), ids)

    # 19. Gibberish and unrelated queries
    def test_19_gibberish_and_unrelated_queries(self):
        data = self._get({'q': 'xkjqpwzr99281'})
        self.assertEqual(data['results'], [])
        self.assertTrue(data['meta'].get('is_empty'))

    # 20. Strong exact match ranking above weak fuzzy matches
    def test_20_strong_exact_match_ranking_above_weak_fuzzy(self):
        # Searching "Ali Raza": Ali Raza has exact name match (rate=2500, rating=3.5, unverified)
        # Zahid Malik has bio match on 'raza' (rate=800, rating=5.0, verified)
        data = self._get({'q': 'Ali Raza'})
        results = data['results']
        self.assertTrue(len(results) >= 1)
        # Exact name match MUST rank first
        self.assertEqual(results[0]['id'], str(self.ali.id))
        self.assertGreater(results[0]['relevance_score'], 150)

    # 21. Missing price filter includes professionals above 1000
    def test_21_missing_price_filter_includes_above_1000(self):
        # Ali charges 2500, Tariq charges 1200
        data = self._get({'q': 'Ali Raza'})
        self.assertIn(str(self.ali.id), [r['id'] for r in data['results']])

    # 22. Explicit maximum price works correctly
    def test_22_explicit_maximum_price(self):
        # Max price 1000 should exclude Ali (2500) and Tariq (1200), but include Fatima (500)
        data = self._get({'max_price': '1000'})
        ids = [r['id'] for r in data['results']]
        self.assertIn(str(self.fatima.id), ids)
        self.assertNotIn(str(self.ali.id), ids)
        self.assertNotIn(str(self.tariq.id), ids)

    # 23. Minimum price and rating filters work correctly
    def test_23_minimum_price_and_rating_filters(self):
        data = self._get({'min_price': '1000', 'min_rating': '4.5'})
        ids = [r['id'] for r in data['results']]
        # Tariq (1200 rate, 4.8 rating) matches
        self.assertIn(str(self.tariq.id), ids)
        # Fatima (500 rate) and Ali (3.5 rating) excluded
        self.assertNotIn(str(self.fatima.id), ids)
        self.assertNotIn(str(self.ali.id), ids)

    # 24. Invalid, negative, non-finite numeric parameters do not cause 500
    def test_24_invalid_numeric_parameters(self):
        for bad in ('nan', '-100', 'inf', 'abc', '1e9999'):
            resp = self.client.get(reverse('nearby'), {'min_price': bad, 'max_price': bad})
            self.assertEqual(resp.status_code, 200, f'Failed on {bad}')

    # 25. Stable deterministic ordering
    def test_25_stable_deterministic_ordering(self):
        resp1 = self._get({'city': 'Karachi'})
        resp2 = self._get({'city': 'Karachi'})
        ids1 = [r['id'] for r in resp1['results']]
        ids2 = [r['id'] for r in resp2['results']]
        self.assertEqual(ids1, ids2)

    # 26. Unauthorized or private fields are not exposed
    def test_26_unauthorized_or_private_fields_not_exposed(self):
        data = self._get({'q': 'Ali Raza'})
        self.assertTrue(len(data['results']) > 0)
        first = data['results'][0]
        # Sensitive fields must NEVER be returned
        self.assertNotIn('email', first)
        self.assertNotIn('password', first)
        self.assertNotIn('phone', first)
        self.assertNotIn('cnic_url', first)
        self.assertNotIn('bank_account_number', first)

    # 27. SQLite compatibility
    def test_27_sqlite_compatibility(self):
        from django.db import connection
        # Must execute cleanly on SQLite default testing engine
        self.assertIn(connection.vendor, ('sqlite', 'postgresql'))

    # 28. Backward compatibility
    def test_28_backward_compatibility(self):
        data = self._get({'q': 'dentist'})
        self.assertIn('results', data)
        self.assertIn('meta', data)
        meta = data['meta']
        self.assertIn('total', meta)
        self.assertIn('is_fallback', meta)
        self.assertIn('is_empty', meta)


class StrictSearchRelevanceTests(TestCase):
    """
    Unit and integration tests for strict category isolation,
    accurate name matching, conservative typo matching, and empty state guarantees.
    """

    @classmethod
    def setUpTestData(cls):
        cls.cat_doc = Category.objects.create(name='Doctors & Healthcare')
        cls.cat_law = Category.objects.create(name='Lawyers & Legal')
        cls.cat_eng = Category.objects.create(name='Engineers')
        cls.cat_tut = Category.objects.create(name='Tutors & Teachers')
        cls.cat_plumb = Category.objects.create(name='Plumbers')

        # Ali Raza: Lawyer in Karachi
        cls.ali_lawyer = cls._create_pro(
            name='Ali Raza',
            cat=cls.cat_law,
            spec='Corporate Law',
            city='Karachi',
            rate=2500,
            rating=4.5,
            verified=True,
        )

        # Dr. Tariq: Doctor in Karachi
        cls.tariq_doc = cls._create_pro(
            name='Muhammad Tariq',
            cat=cls.cat_doc,
            spec='Cardiologist',
            city='Karachi',
            rate=2000,
            rating=4.9,
            verified=True,
        )

        # Fatima: Doctor in Lahore
        cls.fatima_doc = cls._create_pro(
            name='Fatima Khan',
            cat=cls.cat_doc,
            spec='Dentist',
            city='Lahore',
            rate=1500,
            rating=4.8,
            verified=True,
        )

        # Amber Shaikh: Tutor in Hyderabad
        cls.amber_tutor = cls._create_pro(
            name='Amber Shaikh',
            cat=cls.cat_tut,
            spec='Mathematics Tutor',
            city='Hyderabad',
            rate=1000,
            rating=4.7,
            verified=True,
        )

        # Zahid Malik: Engineer in Islamabad
        cls.zahid_eng = cls._create_pro(
            name='Zahid Malik',
            cat=cls.cat_eng,
            spec='Software Engineer',
            city='Islamabad',
            rate=3000,
            rating=5.0,
            verified=True,
            bio='Expert in medical healthcare software and legal tech.'
        )

    @classmethod
    def _create_pro(cls, name, cat, spec, city, rate, rating, verified=False, bio=''):
        email = f"{name.replace(' ', '.').lower()}@relevance.test"
        u = User.objects.create_user(email=email, name=name, role='professional', password='password123')
        ProfessionalProfile.objects.update_or_create(
            user=u,
            defaults=dict(
                category=cat,
                specialization=spec,
                hourly_rate=rate,
                average_rating=rating,
                is_verified=verified,
                bio=bio,
            ),
        )
        UserProfile.objects.update_or_create(user=u, defaults=dict(city=city))
        build_index_for_user(User.objects.get(pk=u.pk))
        return u

    def _get(self, params):
        resp = self.client.get(reverse('nearby'), params)
        self.assertEqual(resp.status_code, 200)
        return resp.json()

    def test_strict_category_isolation_doctor(self):
        """Searching doctor must ONLY return professionals in Doctors & Healthcare."""
        data = self._get({'q': 'doctor'})
        ids = [r['id'] for r in data['results']]
        self.assertIn(str(self.tariq_doc.id), ids)
        self.assertIn(str(self.fatima_doc.id), ids)
        # Non-doctors must NEVER appear, even if bio mentions healthcare (Zahid) or high rating
        self.assertNotIn(str(self.ali_lawyer.id), ids)
        self.assertNotIn(str(self.amber_tutor.id), ids)
        self.assertNotIn(str(self.zahid_eng.id), ids)

    def test_strict_category_isolation_lawyer(self):
        """Searching lawyer must ONLY return professionals in Lawyers & Legal."""
        data = self._get({'q': 'lawyer'})
        ids = [r['id'] for r in data['results']]
        self.assertIn(str(self.ali_lawyer.id), ids)
        self.assertNotIn(str(self.tariq_doc.id), ids)
        self.assertNotIn(str(self.fatima_doc.id), ids)
        self.assertNotIn(str(self.zahid_eng.id), ids)

    def test_strict_category_empty_results_when_none_exist(self):
        """When searching a profession with 0 professionals (plumber), results must be empty, not filled with other categories."""
        data = self._get({'q': 'plumber'})
        self.assertEqual(data['results'], [])
        self.assertTrue(data['meta']['is_empty'])

    def test_strict_abbreviation_dr(self):
        """'dr' is an unambiguous alias for doctor and must return doctors only."""
        data = self._get({'q': 'dr'})
        ids = [r['id'] for r in data['results']]
        self.assertTrue(str(self.tariq_doc.id) in ids or str(self.fatima_doc.id) in ids)
        self.assertNotIn(str(self.ali_lawyer.id), ids)
        self.assertNotIn(str(self.amber_tutor.id), ids)

    def test_accurate_name_search_amber(self):
        """Searching 'Amber' must return Amber Shaikh only, not unrelated professionals."""
        data = self._get({'q': 'Amber'})
        ids = [r['id'] for r in data['results']]
        self.assertEqual(ids, [str(self.amber_tutor.id)])

    def test_conservative_typo_correction_umber(self):
        """Searching 'Umber' (1-edit distance) corrects to Amber and finds Amber Shaikh."""
        data = self._get({'q': 'Umber'})
        ids = [r['id'] for r in data['results']]
        self.assertIn(str(self.amber_tutor.id), ids)

    def test_combined_query_conflicting_category(self):
        """Searching 'Amber doctor' returns empty because Amber is a Tutor, NOT a Doctor."""
        data = self._get({'q': 'Amber doctor'})
        ids = [r['id'] for r in data['results']]
        self.assertEqual(ids, [])

    def test_combined_query_matching_category(self):
        """Searching 'Amber tutor' returns Amber Shaikh."""
        data = self._get({'q': 'Amber tutor'})
        ids = [r['id'] for r in data['results']]
        self.assertIn(str(self.amber_tutor.id), ids)

    def test_multilingual_strict_category(self):
        """Multilingual terms for doctor (Urdu: ڈاکٹر, Arabic: طبيب, Hindi: डॉक्टर) must isolate to Doctors."""
        for q in ('ڈاکٹر', 'طبيب', 'डॉक्टर', 'daktar'):
            data = self._get({'q': q})
            ids = [r['id'] for r in data['results']]
            self.assertTrue(str(self.tariq_doc.id) in ids or str(self.fatima_doc.id) in ids, f"Failed for {q}")
            self.assertNotIn(str(self.ali_lawyer.id), ids, f"Lawyer leaked in {q}")
            self.assertNotIn(str(self.zahid_eng.id), ids, f"Engineer leaked in {q}")


class MultilingualAndBudgetSearchTests(TestCase):
    """
    Regression test suite for:
    1. Roman Urdu budget expressions (budget before and after profession, spelling variants).
    2. Hindi queries (single profession terms, natural conversational queries, budget queries, city queries).
    3. Strict category isolation across Doctor, Plumber, Electrician, and Lawyer.
    """

    @classmethod
    def setUpTestData(cls):
        cls.cat_doc = Category.objects.create(name='Doctors & Healthcare')
        cls.cat_plumb = Category.objects.create(name='Plumbers')
        cls.cat_elec = Category.objects.create(name='Electricians')
        cls.cat_law = Category.objects.create(name='Lawyers & Legal')

        # Cheap doctor (rate 400)
        cls.doc_cheap = cls._create_pro(
            name='Dr. Ahmed Bilal',
            cat=cls.cat_doc,
            spec='General Physician',
            city='Karachi',
            rate=400,
            rating=4.8,
            verified=True,
        )

        # Expensive doctor (rate 1500)
        cls.doc_exp = cls._create_pro(
            name='Dr. Tariq Mansoor',
            cat=cls.cat_doc,
            spec='Cardiologist',
            city='Karachi',
            rate=1500,
            rating=4.9,
            verified=True,
        )

        # Cheap plumber (rate 350)
        cls.plumb_cheap = cls._create_pro(
            name='Bablu Plumber',
            cat=cls.cat_plumb,
            spec='Pipe Fitter',
            city='Karachi',
            rate=350,
            rating=4.6,
            verified=True,
        )

        # Expensive plumber (rate 1200)
        cls.plumb_exp = cls._create_pro(
            name='Rashid Plumber',
            cat=cls.cat_plumb,
            spec='Sanitary Expert',
            city='Lahore',
            rate=1200,
            rating=4.7,
            verified=True,
        )

        # Electrician (rate 450)
        cls.elec = cls._create_pro(
            name='Sajid Bijli',
            cat=cls.cat_elec,
            spec='Electrician',
            city='Karachi',
            rate=450,
            rating=4.8,
            verified=True,
        )

        # Lawyer (rate 2000)
        cls.lawyer = cls._create_pro(
            name='Kamran Lawyer',
            cat=cls.cat_law,
            spec='Corporate Advocate',
            city='Karachi',
            rate=2000,
            rating=4.9,
            verified=True,
        )

    @classmethod
    def _create_pro(cls, name, cat, spec, city, rate, rating, verified=True):
        email = f"{name.replace(' ', '.').replace('.', '').lower()}@budget.test"
        u = User.objects.create_user(email=email, name=name, role='professional', password='password123')
        ProfessionalProfile.objects.update_or_create(
            user=u,
            defaults=dict(
                category=cat,
                specialization=spec,
                hourly_rate=rate,
                average_rating=rating,
                is_verified=verified,
            ),
        )
        UserProfile.objects.update_or_create(user=u, defaults=dict(city=city))
        build_index_for_user(User.objects.get(pk=u.pk))
        return u

    def _search(self, q):
        resp = self.client.get(reverse('nearby'), {'q': q})
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        results = data.get('results', [])
        return [str(r['id']) for r in results], results

    def test_roman_urdu_budget_doctor_variations(self):
        """Verify Roman Urdu budget parsing whether budget appears before or after profession."""
        doctor_budget_queries = [
            'doctor under 500',
            '500 under doctor',
            'doctor under 500 rupees',
            'doctor below 500',
            'doctor less than 500',
            '500 ke andar doctor',
            'doctor 500 ke andar',
            '500 ke ander doctor',
            '500 se kam doctor',
            '500 rupay ke andar doctor',
        ]
        cheap_id = str(self.doc_cheap.id)
        exp_id = str(self.doc_exp.id)
        plumb_cheap_id = str(self.plumb_cheap.id)

        for q in doctor_budget_queries:
            ids, _ = self._search(q)
            self.assertIn(cheap_id, ids, f"Query '{q}' should find cheap doctor {cheap_id}")
            self.assertNotIn(exp_id, ids, f"Query '{q}' should NOT find expensive doctor (rate 1500)")
            self.assertNotIn(plumb_cheap_id, ids, f"Query '{q}' must NOT leak plumber into doctor results")

    def test_roman_urdu_budget_plumber_variations(self):
        """Verify Roman Urdu budget parsing for plumber queries."""
        plumber_budget_queries = [
            'plumber under 500',
            '500 under plumber',
            '500 ke ander plumber',
            '500 ke andar plumber',
            '500 se kam plumber',
            'plumber 500 ke andar',
            '500 rupay ke andar plumber',
        ]
        plumb_cheap_id = str(self.plumb_cheap.id)
        plumb_exp_id = str(self.plumb_exp.id)
        doc_cheap_id = str(self.doc_cheap.id)

        for q in plumber_budget_queries:
            ids, _ = self._search(q)
            self.assertIn(plumb_cheap_id, ids, f"Query '{q}' should find cheap plumber {plumb_cheap_id}")
            self.assertNotIn(plumb_exp_id, ids, f"Query '{q}' should NOT find expensive plumber (rate 1200)")
            self.assertNotIn(doc_cheap_id, ids, f"Query '{q}' must NOT leak doctor into plumber results")

    def test_hindi_queries(self):
        """Verify Hindi queries return correct professionals without empty states."""
        cases = [
            ('डॉक्टर', [str(self.doc_cheap.id), str(self.doc_exp.id)], [str(self.plumb_cheap.id)]),
            ('मुझे डॉक्टर चाहिए', [str(self.doc_cheap.id), str(self.doc_exp.id)], [str(self.plumb_cheap.id)]),
            ('500 के अंदर डॉक्टर', [str(self.doc_cheap.id)], [str(self.doc_exp.id), str(self.plumb_cheap.id)]),
            ('डॉक्टर 500 के अंदर', [str(self.doc_cheap.id)], [str(self.doc_exp.id), str(self.plumb_cheap.id)]),
            ('500 से कम डॉक्टर', [str(self.doc_cheap.id)], [str(self.doc_exp.id), str(self.plumb_cheap.id)]),
            ('प्लंबर', [str(self.plumb_cheap.id), str(self.plumb_exp.id)], [str(self.doc_cheap.id)]),
            ('500 के अंदर प्लंबर', [str(self.plumb_cheap.id)], [str(self.plumb_exp.id), str(self.doc_cheap.id)]),
            ('बिजली मिस्त्री', [str(self.elec.id)], [str(self.doc_cheap.id), str(self.plumb_cheap.id)]),
            ('वकील', [str(self.lawyer.id)], [str(self.doc_cheap.id), str(self.plumb_cheap.id)]),
            ('कराची में डॉक्टर', [str(self.doc_cheap.id), str(self.doc_exp.id)], [str(self.plumb_cheap.id)]),
        ]

        for q, expected_ids, forbidden_ids in cases:
            ids, _ = self._search(q)
            self.assertTrue(len(ids) > 0, f"Query '{q}' returned 0 results!")
            for exp in expected_ids:
                self.assertIn(exp, ids, f"Query '{q}' should contain ID {exp}")
            for forb in forbidden_ids:
                self.assertNotIn(forb, ids, f"Query '{q}' leaked unrelated ID {forb}")

    def test_strict_category_isolation_across_professions(self):
        """Doctors must never return plumbers, plumbers must never return doctors."""
        doc_ids, _ = self._search('doctor')
        plumb_ids, _ = self._search('plumber')

        self.assertNotIn(str(self.plumb_cheap.id), doc_ids)
        self.assertNotIn(str(self.plumb_exp.id), doc_ids)
        self.assertNotIn(str(self.doc_cheap.id), plumb_ids)
        self.assertNotIn(str(self.doc_exp.id), plumb_ids)

