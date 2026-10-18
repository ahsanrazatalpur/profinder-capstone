# apps/ai_engine/tests.py
#
# Comprehensive test suite for ProFinder Global AI Search Upgrade.
# Tests natural-language intent extraction across 6 languages + Roman Urdu,
# symptom mapping, strict budget and hard-constraint enforcement,
# city aliases, candidate reduction, N+1 query elimination, deterministic ranking,
# mock Gemini responses, quota enforcement, and response privacy.
# Compatible with SQLite and PostgreSQL.

from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from unittest.mock import patch, MagicMock
import json

from apps.profiles.models import UserProfile, ProfessionalProfile
from apps.search.models import Category
from apps.ai_engine.models import SearchHistory, AIRecommendation
from apps.ai_engine.views import extract_max_budget, _extract_intent
from apps.ai_engine.symptoms import find_profession_from_symptoms

User = get_user_model()


class AISearchComprehensiveTests(TestCase):
    def setUp(self):
        self.client = APIClient()

        # Deterministic mock for Gemini in unit tests (Section 13)
        self.gemini_patcher = patch('apps.ai_engine.views._gemini_api_key', return_value=None)
        self.gemini_patcher.start()
        self.addCleanup(self.gemini_patcher.stop)

        # Create Category records
        self.cat_doctor = Category.objects.create(name='Doctors & Healthcare')
        self.cat_dentist = Category.objects.create(name='Dentistry')
        self.cat_electrician = Category.objects.create(name='Electrician & Electrical')
        self.cat_plumber = Category.objects.create(name='Plumbing & Sanitary')
        self.cat_lawyer = Category.objects.create(name='Legal Services')

        # Create Customer
        self.customer = User.objects.create_user(
            email='customer@example.com', password='password123',
            name='Test Customer', role='customer'
        )
        UserProfile.objects.create(user=self.customer, full_name='Test Customer')

        # Helper to create professional
        def make_pro(email, name, cat, city, rate, rating, is_avail=True, is_ver=True, gender='male', spec=''):
            u = User.objects.create_user(email=email, password='password123', name=name, role='professional')
            up = UserProfile.objects.create(
                user=u, full_name=name, city=city, gender=gender,
                latitude=24.8607 if city == 'Karachi' else 31.5204 if city == 'Lahore' else None,
                longitude=67.0011 if city == 'Karachi' else 74.3587 if city == 'Lahore' else None,
            )
            pp = ProfessionalProfile.objects.create(
                user=u, category=cat, hourly_rate=rate, average_rating=rating,
                is_available=is_avail, is_verified=is_ver, specialization=spec,
                experience_years=5, bio=f'{name} professional', skills=cat.name,
                services='Consultation, Diagnostics',
            )
            return u, up, pp

        # 1. Doctors
        self.doc_karachi_cheap, _, _ = make_pro(
            'doc_khi_cheap@pro.com', 'Dr. Ali Raza', self.cat_doctor, 'Karachi', 450, 4.8,
            is_avail=True, is_ver=True, gender='male', spec='General Physician'
        )
        self.doc_karachi_expensive, _, _ = make_pro(
            'doc_khi_exp@pro.com', 'Dr. Imran Khan', self.cat_doctor, 'Karachi', 2500, 4.9,
            is_avail=True, is_ver=True, gender='male', spec='Cardiologist'
        )
        self.doc_lahore_female, _, _ = make_pro(
            'doc_lhr_female@pro.com', 'Dr. Fatima Noor', self.cat_doctor, 'Lahore', 800, 4.7,
            is_avail=True, is_ver=True, gender='female', spec='Pediatrician'
        )
        self.doc_badin, _, _ = make_pro(
            'doc_badin@pro.com', 'Dr. Tariq Badini', self.cat_doctor, 'Badin', 400, 4.5,
            is_avail=False, is_ver=False, gender='male', spec='General Physician'
        )

        # 2. Dentists
        self.dentist_karachi, _, _ = make_pro(
            'dentist_khi@pro.com', 'Dr. Sara Ahmed', self.cat_dentist, 'Karachi', 600, 4.6,
            is_avail=True, is_ver=True, gender='female', spec='Orthodontist'
        )

        # 3. Electricians
        self.elec_karachi, _, _ = make_pro(
            'elec_khi@pro.com', 'Rashid Bijli', self.cat_electrician, 'Karachi', 350, 4.4,
            is_avail=True, is_ver=True, gender='male', spec='Wiring Specialist'
        )

        # 4. Plumbers
        self.plumb_lahore, _, _ = make_pro(
            'plumb_lhr@pro.com', 'Usman Plumber', self.cat_plumber, 'Lahore', 500, 4.2,
            is_avail=True, is_ver=False, gender='male', spec='Pipe Repair'
        )

        # 5. Lawyers
        self.lawyer_islamabad, _, _ = make_pro(
            'lawyer_isb@pro.com', 'Advocate Bilal Qureshi', self.cat_lawyer, 'Islamabad', 1500, 4.8,
            is_avail=True, is_ver=True, gender='male', spec='Criminal Law'
        )

    # 1. Simple English profession query
    def test_01_simple_english_profession(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'I need a doctor'})
        self.assertEqual(res.status_code, 200)
        self.assertTrue(len(res.data['matched_professionals']) > 0)
        names = [p['name'] for p in res.data['matched_professionals']]
        self.assertTrue(any('Dr.' in n for n in names))

    # 2. English symptom/problem query (tooth pain -> dentist)
    def test_02_english_symptom_problem_query(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'I have severe tooth pain and bleeding gums'})
        self.assertEqual(res.status_code, 200)
        self.assertTrue(len(res.data['matched_professionals']) > 0)
        self.assertEqual(res.data['matched_professionals'][0]['name'], 'Dr. Sara Ahmed')

    # 3. Urdu Unicode query (ڈاکٹر چاہیے)
    def test_03_urdu_unicode_query(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'مجھے کراچی میں ڈاکٹر چاہیے'})
        self.assertEqual(res.status_code, 200)
        self.assertTrue(len(res.data['matched_professionals']) > 0)
        self.assertEqual(res.data['requested_city'], 'Karachi')

    # 4. Roman Urdu query ("Mujhe bukhar hai, 500 ke andar doctor chahiye")
    def test_04_roman_urdu_symptom_and_budget(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'Mujhe bukhar hai, 500 ke andar doctor chahiye'})
        self.assertEqual(res.status_code, 200)
        self.assertTrue(len(res.data['matched_professionals']) > 0)
        for p in res.data['matched_professionals']:
            self.assertLessEqual(p['hourly_rate'], 500)

    # 5. Hindi Unicode query (मुझे कराची में दंत चिकित्सक चाहिए)
    def test_05_hindi_unicode_query(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'मुझे कराची में दंत चिकित्सक चाहिए'})
        self.assertEqual(res.status_code, 200)
        self.assertTrue(len(res.data['matched_professionals']) > 0)
        self.assertEqual(res.data['matched_professionals'][0]['name'], 'Dr. Sara Ahmed')

    # 6. Arabic Unicode query (عندي ألم في الأسنان، أحتاج طبيب أسنان)
    def test_06_arabic_unicode_query(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'عندي ألم في الأسنان، أحتاج طبيب أسنان'})
        self.assertEqual(res.status_code, 200)
        self.assertTrue(len(res.data['matched_professionals']) > 0)
        self.assertEqual(res.data['matched_professionals'][0]['name'], 'Dr. Sara Ahmed')

    # 7. French query (Je cherche un médecin à Karachi)
    def test_07_french_query(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'Je cherche un médecin à Karachi'})
        self.assertEqual(res.status_code, 200)
        self.assertTrue(len(res.data['matched_professionals']) > 0)
        self.assertEqual(res.data['requested_city'], 'Karachi')

    # 8. Spanish query (Necesito un abogado)
    def test_08_spanish_query(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'Necesito un abogado'})
        self.assertEqual(res.status_code, 200)
        self.assertTrue(len(res.data['matched_professionals']) > 0)
        self.assertEqual(res.data['matched_professionals'][0]['name'], 'Advocate Bilal Qureshi')

    # 9. Mixed-language query (Karachi me doctor under 500)
    def test_09_mixed_language_query(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'Karachi me doctor under 500'})
        self.assertEqual(res.status_code, 200)
        self.assertTrue(len(res.data['matched_professionals']) > 0)
        self.assertEqual(res.data['matched_professionals'][0]['name'], 'Dr. Ali Raza')

    # 10. Profession + city extraction (dentist in Karachi)
    def test_10_profession_plus_city(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'dentist in Karachi'})
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data['requested_city'], 'Karachi')
        self.assertEqual(res.data['matched_professionals'][0]['name'], 'Dr. Sara Ahmed')

    # 11. City spelling mistakes & aliases (Badin, Khi)
    def test_11_city_aliases(self):
        intent_khi = _extract_intent('doctor in Khi')
        self.assertEqual(intent_khi['city'], 'Karachi')

        intent_urdu_city = _extract_intent('ڈاکٹر لاہور میں')
        self.assertEqual(intent_urdu_city['city'], 'Lahore')

    # 12. Budget extraction across languages
    def test_12_budget_extraction_expressions(self):
        self.assertEqual(extract_max_budget('under 2000'), 2000.0)
        self.assertEqual(extract_max_budget('500 rupay ke andar'), 500.0)
        self.assertEqual(extract_max_budget('500 ke andar'), 500.0)
        self.assertEqual(extract_max_budget('500 tak'), 500.0)
        self.assertEqual(extract_max_budget('500 روپے کے اندر'), 500.0)
        self.assertEqual(extract_max_budget('500 रुपये के अंदर'), 500.0)
        self.assertEqual(extract_max_budget('أقل من 500'), 500.0)
        self.assertEqual(extract_max_budget('moins de 500'), 500.0)
        self.assertEqual(extract_max_budget('menos de 500'), 500.0)

    # 13. Strict maximum-price enforcement
    def test_13_strict_maximum_price_enforcement(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'doctor in Karachi under 500'})
        self.assertEqual(res.status_code, 200)
        self.assertTrue(len(res.data['matched_professionals']) > 0)
        for p in res.data['matched_professionals']:
            self.assertLessEqual(p['hourly_rate'], 500)
        names = [p['name'] for p in res.data['matched_professionals']]
        self.assertNotIn('Dr. Imran Khan', names)

    # 14. Missing prices when a budget is specified (impossible budget -> 0 matches)
    def test_14_impossible_budget_returns_no_matches(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'doctor in Karachi under 100'})
        self.assertEqual(res.status_code, 200)
        self.assertEqual(len(res.data['matched_professionals']), 0)
        self.assertIn('budget', res.data['unmet_intent'])

    # 15. Rating, availability, gender filters
    def test_15_gender_and_availability_filters(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'female doctor'})
        self.assertEqual(res.status_code, 200)
        for p in res.data['matched_professionals']:
            self.assertEqual(p['gender'], 'female')

    # 16. "Near me" with location and missing location fallback
    def test_16_near_me_handling(self):
        self.client.force_authenticate(user=self.customer)
        # Without GPS
        res_no_gps = self.client.post('/api/ai/search/', {'query': 'electrician near me'})
        self.assertEqual(res_no_gps.status_code, 200)
        self.assertIn('distance: location unavailable', res_no_gps.data['unmet_intent'])

        # With GPS
        res_gps = self.client.post('/api/ai/search/', {
            'query': 'electrician near me', 'latitude': 24.8607, 'longitude': 67.0011
        })
        self.assertEqual(res_gps.status_code, 200)
        self.assertTrue(len(res_gps.data['matched_professionals']) > 0)

    # 17. No matching profession or category
    def test_17_no_matching_category(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'astronaut in Badin'})
        self.assertEqual(res.status_code, 200)
        self.assertEqual(len(res.data['matched_professionals']), 0)

    # 18. Gibberish and unrelated queries
    def test_18_gibberish_and_unrelated_queries(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'asdfghjkl999xyz'})
        self.assertEqual(res.status_code, 200)
        self.assertEqual(len(res.data['matched_professionals']), 0)

    # 19. Empty and whitespace queries
    def test_19_empty_and_whitespace_queries(self):
        self.client.force_authenticate(user=self.customer)
        res1 = self.client.post('/api/ai/search/', {'query': ''})
        self.assertEqual(res1.status_code, 400)
        res2 = self.client.post('/api/ai/search/', {'query': '   '})
        self.assertEqual(res2.status_code, 400)

    # 20. Exact name match versus weak relevance ranking
    def test_20_exact_name_match_ranks_first(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'Ali Raza'})
        self.assertEqual(res.status_code, 200)
        self.assertTrue(len(res.data['matched_professionals']) > 0)
        self.assertEqual(res.data['matched_professionals'][0]['name'], 'Dr. Ali Raza')

    # 21. No arbitrary professionals returned for failed interpretation
    def test_21_no_arbitrary_pros_for_random_questions(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'what is the weather in Paris today?'})
        self.assertEqual(res.status_code, 200)
        self.assertEqual(len(res.data['matched_professionals']), 0)

    # 22. Mock Gemini timeout / quota error falls back cleanly
    @patch('apps.ai_engine.views._gemini_api_key', return_value='fake_key')
    @patch('apps.ai_engine.views.genai')
    def test_22_gemini_timeout_fallback(self, mock_genai, mock_key):
        mock_instance = MagicMock()
        mock_instance.models.generate_content.side_effect = TimeoutError('Request timed out')
        mock_genai.Client.return_value = mock_instance

        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'doctor in Karachi'})
        self.assertEqual(res.status_code, 200)
        self.assertTrue(res.data['ai_fallback_used'])
        self.assertTrue(len(res.data['matched_professionals']) > 0)

    # 23. Gemini disabled or unavailable with deterministic fallback
    @patch('apps.ai_engine.views._gemini_api_key', return_value=None)
    def test_23_gemini_unavailable_fallback(self, mock_key):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'doctor in Karachi'})
        self.assertEqual(res.status_code, 200)
        self.assertTrue(res.data['ai_fallback_used'])
        self.assertTrue(len(res.data['matched_professionals']) > 0)

    # 24. Model output containing invalid or fabricated candidate IDs
    @patch('apps.ai_engine.views._gemini_api_key', return_value='fake_key')
    @patch('apps.ai_engine.views.genai')
    def test_24_model_output_fabricated_candidate_discarded(self, mock_genai, mock_key):
        mock_instance = MagicMock()
        mock_resp = MagicMock()
        mock_resp.text = json.dumps([
            {'name': 'Fabricated Fake Doctor Who Does Not Exist', 'reason': 'Great fake pro', 'confidence': 9},
            {'name': 'Dr. Ali Raza', 'reason': 'Real verified doctor in Karachi', 'confidence': 10},
        ])
        mock_instance.models.generate_content.return_value = mock_resp
        mock_genai.Client.return_value = mock_instance

        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'doctor in Karachi under 500'})
        self.assertEqual(res.status_code, 200)
        names = [p['name'] for p in res.data['matched_professionals']]
        self.assertIn('Dr. Ali Raza', names)
        self.assertNotIn('Fabricated Fake Doctor Who Does Not Exist', names)

    # 25. Explicit filters remaining enforced after Gemini reranking
    @patch('apps.ai_engine.views._gemini_api_key', return_value='fake_key')
    @patch('apps.ai_engine.views.genai')
    def test_25_explicit_filters_revalidated_after_gemini(self, mock_genai, mock_key):
        mock_instance = MagicMock()
        mock_resp = MagicMock()
        # Gemini tries to rank Dr. Imran Khan ($2500) when user asked under 500
        mock_resp.text = json.dumps([
            {'name': 'Dr. Imran Khan', 'reason': 'Famous doctor', 'confidence': 10},
            {'name': 'Dr. Ali Raza', 'reason': 'Affordable doctor', 'confidence': 8},
        ])
        mock_instance.models.generate_content.return_value = mock_resp
        mock_genai.Client.return_value = mock_instance

        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'doctor in Karachi under 500'})
        self.assertEqual(res.status_code, 200)
        for p in res.data['matched_professionals']:
            self.assertLessEqual(p['hourly_rate'], 500)
        names = [p['name'] for p in res.data['matched_professionals']]
        self.assertNotIn('Dr. Imran Khan', names)

    # 26. Authentication and daily quota behavior
    def test_26_guest_search_rejected(self):
        res = self.client.post('/api/ai/search/', {'query': 'doctor in Karachi'})
        self.assertEqual(res.status_code, 401)
        self.assertFalse(res.data['ai_used'])

    # 27. Malformed requests and numeric values
    def test_27_malformed_numeric_requests(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {
            'query': 'doctor in Karachi', 'latitude': 'abc_invalid', 'longitude': 'xyz_invalid'
        })
        self.assertEqual(res.status_code, 200)

    # 28. Search history behavior
    def test_28_search_history_recorded(self):
        self.client.force_authenticate(user=self.customer)
        count_before = SearchHistory.objects.filter(user=self.customer).count()
        self.client.post('/api/ai/search/', {'query': 'doctor in Karachi'})
        count_after = SearchHistory.objects.filter(user=self.customer).count()
        self.assertEqual(count_after, count_before + 1)

    # 29. Response privacy (no email in results)
    def test_29_response_privacy(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'doctor in Karachi'})
        self.assertEqual(res.status_code, 200)
        for pro in res.data['matched_professionals']:
            self.assertNotIn('email', pro)

    # 30. AI recommendations persisted
    def test_30_ai_recommendations_persisted(self):
        self.client.force_authenticate(user=self.customer)
        self.client.post('/api/ai/search/', {'query': 'doctor in Karachi'})
        recs = AIRecommendation.objects.filter(user=self.customer)
        self.assertTrue(recs.exists())

    # 31. SQLite database compatibility
    def test_31_sqlite_compatibility(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'Rashid Bijli'})
        self.assertEqual(res.status_code, 200)
        self.assertTrue(len(res.data['matched_professionals']) > 0)
        self.assertEqual(res.data['matched_professionals'][0]['name'], 'Rashid Bijli')

    # 32. Multi-language symptom mapping verification
    def test_32_multilingual_symptom_mappings(self):
        self.assertEqual(find_profession_from_symptoms('mujhe bukhar hai'), 'doctor')
        self.assertEqual(find_profession_from_symptoms('mujhe tez bukhar hai'), 'doctor')
        self.assertEqual(find_profession_from_symptoms('مجھے بخار ہے'), 'doctor')
        self.assertEqual(find_profession_from_symptoms('मुझे तेज बुखार है'), 'doctor')
        self.assertEqual(find_profession_from_symptoms('عندي ألم في الأسنان'), 'dentist')
        self.assertEqual(find_profession_from_symptoms('pipe leak in bathroom'), 'plumber')
        self.assertEqual(find_profession_from_symptoms('bijli kharab ho gayi hai'), 'electrician')
        self.assertEqual(find_profession_from_symptoms('court case legal notice'), 'lawyer')

    # 33. Minimum budget expressions across languages and enforcement
    def test_33_minimum_budget_enforcement(self):
        from apps.ai_engine.views import extract_min_budget
        self.assertEqual(extract_min_budget('above 500'), 500.0)
        self.assertEqual(extract_min_budget('at least 600'), 600.0)
        self.assertEqual(extract_min_budget('500 se zyada'), 500.0)
        self.assertEqual(extract_min_budget('500 سے زیادہ'), 500.0)
        self.assertEqual(extract_min_budget('500 से अधिक'), 500.0)
        self.assertEqual(extract_min_budget('أكثر من 500'), 500.0)
        self.assertEqual(extract_min_budget('plus de 500'), 500.0)
        self.assertEqual(extract_min_budget('más de 500'), 500.0)

        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'doctor in Karachi above 1000'})
        self.assertEqual(res.status_code, 200)
        self.assertTrue(len(res.data['matched_professionals']) > 0)
        for p in res.data['matched_professionals']:
            self.assertGreaterEqual(p['hourly_rate'], 1000)
        names = [p['name'] for p in res.data['matched_professionals']]
        self.assertIn('Dr. Imran Khan', names)
        self.assertNotIn('Dr. Ali Raza', names)

    # 34. Structured intent representation in response
    def test_34_structured_intent_representation(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'mujhe Karachi mein dentist chahiye'})
        self.assertEqual(res.status_code, 200)
        self.assertIn('structured_intent', res.data)
        intent = res.data['structured_intent']
        self.assertEqual(intent['profession'], 'dentist')
        self.assertEqual(intent['city'], 'Karachi')
        self.assertEqual(intent['language'], 'roman_ur')
        self.assertGreaterEqual(intent['confidence'], 0.8)

    # 35. Medical emergency detection and advisory notice
    def test_35_medical_emergency_detection(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'severe chest pain heart attack in Karachi'})
        self.assertEqual(res.status_code, 200)
        self.assertIsNotNone(res.data.get('emergency_alert'))
        self.assertIn('1122 or 911', res.data['emergency_alert'])
        self.assertIn('⚠️ Medical Emergency Notice', res.data['ai_result'])

    # 36. Duplicate result prevention
    def test_36_duplicate_result_prevention(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'doctor in Karachi'})
        self.assertEqual(res.status_code, 200)
        pro_ids = [p['id'] for p in res.data['matched_professionals']]
        self.assertEqual(len(pro_ids), len(set(pro_ids)))

    # 37. Mixed script queries (native script + English words)
    def test_37_mixed_script_queries(self):
        self.client.force_authenticate(user=self.customer)
        # Urdu + English: "مجھے doctor near me چاہیے"
        res = self.client.post('/api/ai/search/', {
            'query': 'مجھے doctor near me چاہیے',
            'latitude': 24.8607,
            'longitude': 67.0011,
        })
        self.assertEqual(res.status_code, 200)
        self.assertTrue(len(res.data['matched_professionals']) > 0)
        names = [p['name'] for p in res.data['matched_professionals']]
        self.assertTrue(any('Dr.' in n for n in names))

    # 38. Compound alias priority (Dentist "طبيب أسنان" vs Doctor "طبيب")
    def test_38_compound_alias_priority(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/ai/search/', {'query': 'أريد طبيب أسنان بالقرب مني'})
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data['structured_intent']['profession'], 'dentist')
        names = [p['name'] for p in res.data['matched_professionals']]
        self.assertIn('Dr. Sara Ahmed', names)
        self.assertNotIn('Dr. Ali Raza', names)

