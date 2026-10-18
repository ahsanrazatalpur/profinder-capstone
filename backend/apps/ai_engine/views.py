# apps/ai_engine/views.py

from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.conf import settings
from django.core.cache import cache
from django.utils import timezone
from dotenv import dotenv_values
import os
import json
import re
import logging
from django.db.models import Count, Q as DQ

try:
    from google import genai
    from google.genai import types as genai_types
except ImportError:
    genai = None
    genai_types = None

from apps.ai_engine.models import AIRecommendation, SearchHistory
from apps.ai_engine.personalization import get_personalization_profile, personalization_boost
from apps.ai_engine.serializers import AIRecommendationSerializer, SearchHistorySerializer
from apps.ai_engine.symptoms import find_profession_from_symptoms, find_symptom_detail, is_medical_emergency
from apps.profiles.models import UserProfile
from apps.users.models import User
from apps.subscriptions.models import Subscription
from apps.subscriptions.utils import (
    check_ai_search_allowed,
    is_premium,
    get_active_subscription,
    get_ai_search_reset_at,
)
from apps.search.views import (
    _build_professional_data, _normalize, _expand_query, _correct_typo,
    SEARCH_VOCABULARY, SYNONYM_MAP, ABBREVIATIONS, _haversine_km,
    _translate_multilingual, _CITY_CENTROIDS,
)
from apps.search.alias_seed import CITY_ALIASES, SEED_ALIASES
from apps.search.aliases import translate_cities

# Flatten all alias pairs from SEED_ALIASES and sort by length descending
# so that longer compound phrases ("طبيب أسنان" = dentist) take precedence
# over single sub-words ("طبيب" = doctor).
_GLOBAL_ALIAS_PAIRS = []
for _canon, _aliases in SEED_ALIASES.items():
    for _a in [_canon] + list(_aliases):
        _GLOBAL_ALIAS_PAIRS.append((_a, _canon))
_GLOBAL_ALIAS_PAIRS.sort(key=lambda x: len(x[0]), reverse=True)

env = dotenv_values(os.path.join(settings.BASE_DIR, '.env'))
logger = logging.getLogger(__name__)


def _gemini_api_key():
    """
    .env first, then real environment variables. On PythonAnywhere the key
    is often set in the WSGI file / "Environment variables" rather than in
    a .env file, and dotenv_values() alone would never see it.
    """
    return (env.get('GEMINI_API_KEY') or os.environ.get('GEMINI_API_KEY') or '').strip() or None


# ─── Natural-language intent extraction phrases across 6 languages + Roman Urdu ───

_PRICE_CHEAP_PHRASES = [
    'cheap', 'affordable', 'budget', 'low cost', 'low-cost', 'inexpensive',
    'low price', 'economical', 'cheapest', 'reasonable price', 'reasonably priced',
    # Roman Urdu
    'sasta', 'sasti', 'saste', 'kam paisay', 'kam paise', 'kifayati',
    # Urdu
    'سستا', 'سستی', 'سستے', 'کم قیمت', 'کفایتی',
    # Hindi
    'सस्ता', 'सस्ती', 'कम कीमत', 'किफायती',
    # Arabic
    'رخيص', 'بسعر مناسب', 'اقتصادي', 'منخفض التكلفة',
    # French
    'pas cher', 'bon marché', 'abordable', 'économique',
    # Spanish
    'barato', 'económico', 'economico', 'asequible', 'bajo costo',
]

_URGENCY_PHRASES = [
    'today', 'right now', 'now', 'asap', 'urgent', 'urgently',
    'immediately', 'right away', 'emergency', 'this instant',
    # Roman Urdu
    'aaj', 'abhi', 'foran', 'jaldi',
    # Urdu
    'ابھی', 'آج', 'فوراً', 'جلدی', 'ہنگامی',
    # Hindi
    'आज', 'तुरंत', 'जल्दी', 'अभी', 'आपातकालीन',
    # Arabic
    'اليوم', 'الآن', 'الان', 'فوراً', 'فورا', 'عاجل', 'طوارئ',
    # French
    "aujourd'hui", 'maintenant', 'urgent', 'immédiatement', 'urgence',
    # Spanish
    'hoy', 'ahora', 'urgente', 'inmediatamente', 'emergencia',
]

_GENDER_FEMALE_PHRASES = [
    'female', 'woman', 'women', 'lady', 'ladies', 'girl',
    # Roman Urdu
    'larki', 'ladki', 'aurat', 'khatoon', 'khawateen',
    # Urdu
    'عورت', 'خاتون', 'لڑکی', 'خواتین',
    # Hindi
    'महिला', 'स्त्री', 'औरत', 'लड़की',
    # Arabic
    'أنثى', 'انثى', 'امرأة', 'سيدة', 'طبيبة', 'محامية',
    # French
    'femme', 'dame', 'féminine', 'feminine',
    # Spanish
    'mujer', 'femenina', 'doctora', 'abogada',
]

_GENDER_MALE_PHRASES = [
    'male', 'man ', ' men', 'gentleman', 'gentlemen', 'boy',
    # Roman Urdu
    'larka', 'ladka', 'aadmi', 'mard',
    # Urdu
    'مرد', 'آدمی', 'لڑکا',
    # Hindi
    'पुरुष', 'मर्द', 'आदमी', 'लड़का',
    # Arabic
    'ذكر', 'رجل',
    # French
    'homme', 'masculin',
    # Spanish
    'hombre', 'masculino',
]

_QUALITY_PHRASES = [
    'best', 'top rated', 'top-rated', 'highly rated', 'excellent', 'finest', 'great',
    # Roman Urdu
    'acha', 'sab se acha', 'behtareen', 'zabardast',
    # Urdu
    'بہترین', 'اچھا', 'اعلیٰ',
    # Hindi
    'सर्वश्रेष्ठ', 'सबसे अच्छा', 'बेहतरीन',
    # Arabic
    'الأفضل', 'الافضل', 'ممتاز', 'أعلى تقييما',
    # French
    'meilleur', 'mieux noté', 'excellent',
    # Spanish
    'mejor', 'mejor valorado', 'excelente',
]

_EXPERIENCE_PHRASES = [
    'experienced', 'senior', 'expert', 'veteran', 'skilled', 'years of experience',
    # Roman Urdu
    'tajurbekar', 'tajarbakar', 'purana', 'mahir',
    # Urdu
    'ماہر', 'تجربہ کار', 'سینئر',
    # Hindi
    'अनुभवी', 'माहिर', 'सीनियर',
    # Arabic
    'خبير', 'ذو خبرة', 'محترف',
    # French
    'expérimenté', 'expert', 'qualifié',
    # Spanish
    'experimentado', 'experto', 'cualificado',
]

_NEARBY_PHRASES = [
    'near me', 'nearby', 'close by', 'closest', 'near my location', 'around me', 'in my area',
    # Roman Urdu
    'qareeb', 'nazdeek', 'paas', 'mere paas', 'mere qareeb', 'aas paas',
    # Urdu
    'قریب', 'نزدیک', 'میرے پاس', 'میرے قریب', 'آس پاس',
    # Hindi
    'मेरे पास', 'नज़दीक', 'नजदीक', 'पास में', 'पास', 'आस पास',
    # Arabic
    'بالقرب مني', 'قريب مني', 'حولي', 'أقرب', 'في منطقتي',
    # French (with and without accents)
    'près de moi', 'pres de moi', 'proche', 'autour de moi', 'proche de moi',
    # Spanish (with and without accents)
    'cerca de mí', 'cerca de mi', 'cerca', 'a mi alrededor', 'en mi zona',
]

_VERIFIED_PHRASES = [
    'verified', 'certified', 'licensed', 'licenced', 'authentic', 'registered', 'legit',
    # Roman Urdu
    'tasdeeq shuda', 'tasdeeq shuda hai',
    # Urdu
    'تصدیق شدہ', 'مصدقہ',
    # Hindi
    'सत्यापित', 'प्रमाणित',
    # Arabic
    'موثق', 'معتمد', 'مرخص',
    # French
    'vérifié', 'certifié',
    # Spanish
    'verificado', 'certificado',
]

_KNOWN_LANGUAGES = [
    'english', 'urdu', 'punjabi', 'sindhi', 'pashto', 'balochi',
    'arabic', 'hindi', 'saraiki', 'kashmiri', 'french', 'spanish',
    'اردو', 'انگریزی', 'عربي', 'हिन्दी',
]

_EXPERIENCE_RE = re.compile(r'(\d+)\s*\+?\s*years?\b', flags=re.IGNORECASE)
_DISTANCE_RE   = re.compile(r'(\d+)\s*(?:km|kilometers?|kilometres?|miles?)\b', flags=re.IGNORECASE)
_RATING_RE     = re.compile(
    r'(\d(?:\.\d)?)\s*\+?\s*(?:star|stars|rating)\b'
    r'|rating\s*(?:of|above|over|at least)?\s*(\d(?:\.\d)?)',
    flags=re.IGNORECASE,
)


def _contains_any(text: str, phrases) -> bool:
    t_raw = f" {text.lower()} "
    t_norm = f" {_normalize(text)} "
    for p in phrases:
        p_raw = p.lower()
        p_norm = _normalize(p)
        if p_raw in t_raw or p_norm in t_norm:
            return True
    return False


def detect_query_language(text: str) -> str:
    """
    Detects the primary language or script form of a natural-language query:
    'ur', 'ar', 'hi', 'fr', 'es', 'roman_ur', 'en', or 'mixed'.
    """
    if not text:
        return 'en'
    has_devanagari = bool(re.search(r'[\u0900-\u097F]', text))
    has_arabic_script = bool(re.search(r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]', text))
    has_latin = bool(re.search(r'[a-zA-Z]', text))

    if has_devanagari:
        return 'mixed' if has_latin else 'hi'
    if has_arabic_script:
        urdu_chars = set('ٹڈڑںےہھچپژگ')
        urdu_words = {'مجھے', 'چاہیے', 'میں', 'کے', 'کا', 'کی', 'پاس', 'قریب', 'کرو', 'ہو', 'ہے', 'تک', 'سے', 'ڈاکٹر', 'روپے'}
        tokens = set(text.split())
        is_urdu = any(c in urdu_chars for c in text) or bool(tokens & urdu_words)
        if is_urdu:
            return 'mixed' if has_latin else 'ur'
        return 'mixed' if has_latin else 'ar'
    if has_latin:
        words = set(re.findall(r'[a-zA-ZáàâäéèêëíìîïóòôöúùûüñçÁÀÂÄÉÈÊËÍÌÎÏÓÒÔÖÚÙÛÜÑÇ]+', text.lower()))
        en_words = {'i', 'need', 'want', 'looking', 'for', 'a', 'an', 'the', 'near', 'me', 'around', 'in', 'under', 'below', 'cheap', 'best', 'doctor', 'plumber', 'lawyer', 'dentist', 'electrician'}
        ru_distinctive = {'mujhe', 'chahiye', 'chahye', 'chaiye', 'mere', 'paas', 'nazdeek', 'qareeb', 'andar', 'sasta', 'sasti', 'saste', 'accha', 'acha', 'behtareen', 'karo', 'karna', 'bhai', 'wala', 'wali', 'walay', 'bukhar', 'dard', 'nalka', 'bijli', 'pani', 'foran', 'abhi', 'jaldi', 'rupay', 'rupaye', 'chahie'}
        fr_words = {'je', 'cherche', 'un', 'une', 'des', 'le', 'la', 'les', 'médecin', 'medecin', 'plombier', 'avocat', 'électricien', 'electricien', 'dentiste', 'près', 'pres', 'de', 'moi', 'pour', 'avec', 'moins', 'dans', 'urgence'}
        es_words = {'necesito', 'busco', 'un', 'una', 'el', 'la', 'médico', 'medico', 'abogado', 'fontanero', 'plomero', 'electricista', 'dentista', 'cerca', 'mí', 'mi', 'por', 'favor', 'menos', 'bajo', 'urgente', 'hoy'}

        ru = len(words & ru_distinctive)
        fr = len(words & fr_words)
        es = len(words & es_words)
        en = len(words & en_words)

        if ru > 0 and en > 2:
            return 'mixed'
        if ru > 0:
            return 'roman_ur'
        if fr > 0 and fr >= es and fr >= en:
            return 'fr'
        if es > 0 and es >= en:
            return 'es'
        return 'en'
    return 'en'


def _first_match_float(pattern, text):
    m = pattern.search(text)
    if not m:
        return None
    for g in m.groups():
        if g:
            return float(g)
    return None


def extract_max_budget(query: str) -> float | None:
    """
    Extracts explicit upper price budget across English, Roman Urdu, Urdu,
    Hindi, Arabic, French, and Spanish expressions without confusing
    experience years, ratings, or distances with currency amounts.
    """
    if not query:
        return None

    # Sanitize out explicit experience, distance, and rating numbers first
    s = re.sub(r'\b\d+\s*(?:km|kilometers?|kilometres?|miles?)\b', ' ', query, flags=re.IGNORECASE)
    s = re.sub(r'\b\d+\s*\+?\s*years?\b', ' ', s, flags=re.IGNORECASE)
    s = re.sub(r'\b\d(?:\.\d)?\s*\+?\s*(?:star|stars|rating)\b', ' ', s, flags=re.IGNORECASE)

    patterns = [
        # Roman Urdu: "500 rupay ke andar", "500 ke andar", "500 tak", "500 se kam"
        r'(\d+)\s*(?:rs\.?|pkr|rupees?|rupaye?|rupay)?\s*(?:ke\s*andar|kay\s*andar|se\s*kam|say\s*kam|tak)\b',
        # Urdu: "500 روپے کے اندر", "500 کے اندر", "500 سے کم", "500 روپے تک", "500 تک"
        r'(\d+)\s*(?:روپے|روپئے)?\s*(?:کے\s*اندر|سے\s*کم|تک)\b',
        # Hindi: "500 रुपये के अंदर", "500 के अंदर", "500 से कम", "500 रुपये तक"
        r'(\d+)\s*(?:रुपये|रुपए)?\s*(?:के\s*अंदर|से\s*कम|तक)\b',
        # Arabic: "أقل من 500", "تحت 500", "بسعر أقل من 500", "500 أو أقل"
        r'(?:أقل\s*من|تحت|بسعر\s*أقل\s*من|ميزانية)\s*(?:ريال|جنيه|درهم)?\s*(\d+)',
        r'(\d+)\s*(?:أو\s*أقل)',
        # French: "moins de 500", "sous 500", "budget de 500", "max 500"
        r'(?:moins\s*de|sous|en\s*dessous\s*de|budget\s*de|max(?:imum)?)\s*(?:€|\$|eur)?\s*(\d+)',
        # Spanish: "menos de 500", "por debajo de 500", "bajo 500", "presupuesto de 500"
        r'(?:menos\s*de|por\s*debajo\s*de|bajo|presupuesto\s*de|máximo|maximo)\s*(?:€|\$)?\s*(\d+)',
        # English: "under 500", "below 1000", "less than 2000", "max 1500", "budget of 800", "within 500"
        r'(?:under|below|less\s*than|max(?:imum)?|budget(?:\s+of)?|within)\s*(?:rs\.?|pkr|\$)?\s*(\d+)',
        r'\$\s*(\d+)',
        r'(\d+)\s*\$',
        r'(\d+)\s*(?:rs\.?|pkr|rupees?|rupaye?|rupay)\b',
    ]

    for p in patterns:
        m = re.search(p, s, flags=re.IGNORECASE)
        if m:
            try:
                val = float(m.group(1))
                if 0 < val < 1000000:
                    return val
            except (ValueError, TypeError):
                continue
    return None


def extract_min_budget(query: str) -> float | None:
    """
    Extracts explicit minimum price floor across English, Roman Urdu, Urdu,
    Hindi, Arabic, French, and Spanish without confusing experience years,
    ratings, or distances with currency amounts.
    """
    if not query:
        return None
    s = re.sub(r'\b\d+\s*(?:km|kilometers?|kilometres?|miles?)\b', ' ', query, flags=re.IGNORECASE)
    s = re.sub(r'\b\d+\s*\+?\s*years?\b', ' ', s, flags=re.IGNORECASE)
    s = re.sub(r'\b\d(?:\.\d)?\s*\+?\s*(?:star|stars|rating)\b', ' ', s, flags=re.IGNORECASE)

    patterns = [
        # Roman Urdu: "500 se zyada", "500 se oper", "kam az kam 500", "kam se kam 500"
        r'(?:kam\s*az\s*kam|kam\s*se\s*kam)\s*(?:rs\.?|pkr|rupees?|rupaye?|rupay)?\s*(\d+)',
        r'(\d+)\s*(?:rs\.?|pkr|rupees?|rupaye?|rupay)?\s*(?:se\s*zyada|say\s*zyada|se\s*oper|say\s*oper|se\s*ziada)\b',
        # Urdu: "500 سے زیادہ", "کم از کم 500", "500 سے اوپر"
        r'(?:کم\s*از\s*کم)\s*(?:روپے|روپئے)?\s*(\d+)',
        r'(\d+)\s*(?:روپے|روپئے)?\s*(?:سے\s*زیادہ|سے\s*اوپر)\b',
        # Hindi: "500 से अधिक", "500 से ज्यादा", "कम से कम 500"
        r'(?:कम\s*से\s*कम)\s*(?:रुपये|रुपए)?\s*(\d+)',
        r'(\d+)\s*(?:रुपये|रुपए)?\s*(?:से\s*अधिक|से\s*ज्यादा|से\s*ऊपर)\b',
        # Arabic: "أكثر من 500", "على الأقل 500", "أعلى من 500"
        r'(?:أكثر\s*من|على\s*الأقل|أعلى\s*من)\s*(?:ريال|جنيه|درهم)?\s*(\d+)',
        # French: "plus de 500", "au moins 500", "supérieur à 500"
        r'(?:plus\s*de|au\s*moins|supérieur\s*à|superieur\s*a)\s*(?:€|\$|eur)?\s*(\d+)',
        # Spanish: "más de 500", "mas de 500", "al menos 500", "por encima de 500"
        r'(?:más\s*de|mas\s*de|al\s*menos|por\s*encima\s*de|mínimo|minimo)\s*(?:€|\$)?\s*(\d+)',
        # English: "above 500", "over 1000", "more than 500", "at least 500", "min 500"
        r'(?:above|over|more\s*than|at\s*least|min(?:imum)?|starting\s*at|starting\s*from)\s*(?:rs\.?|pkr|\$)?\s*(\d+)',
    ]
    for p in patterns:
        m = re.search(p, s, flags=re.IGNORECASE)
        if m:
            try:
                val = float(m.group(1))
                if 0 < val < 1000000:
                    return val
            except (ValueError, TypeError):
                continue
    return None


def _find_city_in_query(query: str, known_cities=None) -> str | None:
    """
    Detects city mentions across languages and scripts using translate_cities,
    CITY_ALIASES, known database cities, and canonical centroids.
    """
    if not query:
        return None

    # Step 1: Check multi-script city translations and aliases
    t_query = translate_cities(query)
    q_norm = _normalize(t_query)
    q_words = set(q_norm.split())

    # Build map of normalized/lowercase to canonical Title-case city names
    all_known = {}
    if known_cities:
        for c in known_cities:
            if c:
                all_known[_normalize(c)] = c.strip().capitalize()
    for c in _CITY_CENTROIDS.keys():
        all_known[_normalize(c)] = c.strip().capitalize()

    # Direct match on normalized words
    for c_norm, canonical in sorted(all_known.items(), key=lambda x: len(x[0]), reverse=True):
        if ' ' in c_norm:
            if c_norm in q_norm:
                return canonical
        else:
            if c_norm in q_words:
                return canonical

    # Step 2: Check raw query against CITY_ALIASES
    raw_lower = query.strip().lower()
    for alias_src, canonical_target in sorted(CITY_ALIASES.items(), key=lambda x: len(x[0]), reverse=True):
        pattern = r'(?<!\w)' + re.escape(alias_src.lower()) + r'(?!\w)'
        if re.search(pattern, raw_lower):
            for k_norm, canonical in all_known.items():
                if canonical.lower() == canonical_target.lower():
                    return canonical
            return canonical_target.capitalize()

    return None


def _format_structured_intent(intent: dict, unmet_intents=None) -> dict:
    """
    Builds the standardized structured search intent contract:
    profession, specialization, problem_description, city, near_me,
    max_price, min_price, min_rating, availability, name_query,
    language, confidence, unresolved_constraints.
    """
    unmet = list(unmet_intents or [])
    unresolved = list(set(intent.get('unresolved_constraints', []) + unmet))
    return {
        'profession':             intent.get('canonical_profession'),
        'specialization':         intent.get('specialization'),
        'problem_description':    intent.get('problem_description'),
        'city':                   intent.get('city'),
        'near_me':                bool(intent.get('wants_nearby')),
        'max_price':              intent.get('max_budget'),
        'min_price':              intent.get('min_budget'),
        'min_rating':             intent.get('min_rating'),
        'availability':           'immediate' if intent.get('wants_urgent') else None,
        'name_query':             intent.get('name_query'),
        'language':               intent.get('query_language', 'en'),
        'confidence':             intent.get('confidence', 0.5),
        'unresolved_constraints': unresolved,
    }


def _extract_intent(query: str, known_cities=None) -> dict:
    """
    Multilingual natural-language intent extractor covering:
      profession_terms       — canonical profession/category terms
      canonical_profession  — main canonical profession name
      specialization        — specific domain specialization if any
      problem_description   — matched symptom/problem phrase if any
      max_budget            — numeric price ceiling
      min_budget            — numeric price floor
      wants_cheap           — soft price preference
      city                  — canonical city location
      wants_urgent          — available right now / today
      min_experience        — numeric years
      wants_experienced     — soft experience preference
      gender                — 'female' / 'male' / None
      wants_nearby          — proximity preference (requires customer GPS)
      max_distance_km       — numeric radius limit
      min_rating            — numeric rating threshold
      wants_top_rated       — soft quality preference
      language              — recognized spoken language
      query_language        — detected natural language ('ur', 'hi', 'ar', 'fr', 'es', 'roman_ur', 'mixed', 'en')
      wants_verified        — verification preference
      is_emergency          — True if emergency phrases detected
      emergency_message     — Life-safety guidance message if emergency detected
      confidence            — 0.0 to 1.0 confidence score
      unresolved_constraints— list of unrecognized constraints
    """
    q_raw = query.strip()
    q_norm = _normalize(q_raw)
    q = f' {q_norm} '

    detected_lang = detect_query_language(q_raw)
    is_emergency = is_medical_emergency(q_raw)

    profession_terms = set()
    problem_description = None
    specialization = None

    # 1. Symptom / problem mapping across 6 languages + Roman Urdu
    symptom_pro, symptom_phrase = find_symptom_detail(q_raw)
    if symptom_pro:
        profession_terms.add(symptom_pro)
        profession_terms.update(_expand_query(symptom_pro))
        problem_description = symptom_phrase

    # 2. Multilingual alias pairs (longest matching first to prevent compound shadowing)
    # E.g. 'طبيب أسنان' (dentist) before 'طبيب' (doctor)
    q_working_raw = f" {q_raw.lower()} "
    q_working_norm = f" {q_norm} "
    alias_matched_pro = None
    for alias_text, canonical_target in _GLOBAL_ALIAS_PAIRS:
        a_norm = _normalize(alias_text)
        a_raw = alias_text.lower()
        if (f" {a_raw} " in q_working_raw) or (f" {a_norm} " in q_working_norm):
            if not alias_matched_pro:
                alias_matched_pro = canonical_target
            profession_terms.add(canonical_target)
            profession_terms.update(_expand_query(canonical_target))
            # Mask out matched alias to avoid sub-word false matches
            q_working_raw = q_working_raw.replace(f" {a_raw} ", " ")
            q_working_norm = q_working_norm.replace(f" {a_norm} ", " ")

    # 3. Multilingual translation pass (Urdu, Hindi, Arabic, French, Spanish, Roman Urdu)
    nq = _normalize(_translate_multilingual(query))
    corrected, _ = _correct_typo(nq)

    for word in set(nq.split()) | set(corrected.split()):
        if word in SEARCH_VOCABULARY or word in SYNONYM_MAP or word in ABBREVIATIONS:
            profession_terms.update(_expand_query(word))

    # Whole-phrase synonyms / symptoms
    profession_terms.update(_expand_query(nq, split_words=False))

    if nq not in SEARCH_VOCABULARY and nq not in SYNONYM_MAP and nq not in ABBREVIATIONS:
        profession_terms.discard(nq)
    profession_terms.discard('')

    # 4. Location detection
    city = _find_city_in_query(query, known_cities=known_cities)

    # 5. Spoken language detection
    language = next((lang for lang in _KNOWN_LANGUAGES if lang in q), None)

    # 6. Budget extraction (Max & Min)
    max_budget = extract_max_budget(query)
    min_budget = extract_min_budget(query)

    # 7. Canonical profession determination
    canonical_pro = symptom_pro or alias_matched_pro
    if not canonical_pro and profession_terms:
        from apps.search.views import SEARCH_VOCABULARY as _SV
        for w in _SV:
            if w in profession_terms:
                canonical_pro = w
                break
        if not canonical_pro:
            canonical_pro = sorted(profession_terms, key=len)[0]

    # 8. Specialization extraction
    spec_keywords = {
        'cardiologist': 'Cardiology',
        'pediatrician': 'Pediatrics',
        'orthodontist': 'Orthodontics',
        'dermatologist': 'Dermatology',
        'neurologist': 'Neurology',
        'gynecologist': 'Gynecology',
        'psychiatrist': 'Psychiatry',
        'civil engineer': 'Civil Engineering',
        'electrical engineer': 'Electrical Engineering',
        'software engineer': 'Software Engineering',
        'corporate lawyer': 'Corporate Law',
        'criminal lawyer': 'Criminal Law',
        'family lawyer': 'Family Law',
    }
    for k, v in spec_keywords.items():
        if k in q or k in q_raw.lower():
            specialization = v
            break

    # 9. Emergency guidance message
    emergency_message = None
    if is_emergency:
        emergency_message = (
            "Medical Emergency Notice: If this is a life-threatening medical emergency, "
            "please contact local emergency services immediately (such as 1122 or 911). "
            "ProFinder is an appointment directory and cannot provide emergency medical care."
        )

    # 10. Confidence calculation
    if canonical_pro and (city or max_budget is not None or _contains_any(q, _NEARBY_PHRASES)):
        confidence = 0.95
    elif canonical_pro:
        confidence = 0.85
    elif city or max_budget is not None:
        confidence = 0.70
    else:
        confidence = 0.50

    return {
        'profession_terms':      sorted(profession_terms),
        'canonical_profession': canonical_pro,
        'specialization':        specialization,
        'problem_description':   problem_description,
        'max_budget':            max_budget,
        'min_budget':            min_budget,
        'wants_cheap':           _contains_any(q, _PRICE_CHEAP_PHRASES),
        'city':                  city,
        'wants_urgent':          _contains_any(q, _URGENCY_PHRASES),
        'min_experience':        _first_match_float(_EXPERIENCE_RE, q),
        'wants_experienced':     _contains_any(q, _EXPERIENCE_PHRASES),
        'gender':                ('female' if _contains_any(q, _GENDER_FEMALE_PHRASES)
                                  else 'male' if _contains_any(q, _GENDER_MALE_PHRASES)
                                  else None),
        'wants_nearby':          _contains_any(q, _NEARBY_PHRASES),
        'max_distance_km':       _first_match_float(_DISTANCE_RE, q),
        'min_rating':            _first_match_float(_RATING_RE, q),
        'wants_top_rated':       _contains_any(q, _QUALITY_PHRASES),
        'language':              language,
        'query_language':        detected_lang,
        'wants_verified':        _contains_any(q, _VERIFIED_PHRASES),
        'is_emergency':          is_emergency,
        'emergency_message':     emergency_message,
        'confidence':            confidence,
        'unresolved_constraints': [],
    }


# ─── AI Search Status ─────────────────────────────────────────────────────────

class AISearchStatusView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        if not request.user.is_authenticated:
            return Response({
                'is_authenticated': False,
                'searches_used':    0,
                'searches_limit':   0,
                'is_premium':       False,
            })

        allowed, used, limit, upgrade_required = check_ai_search_allowed(request.user)
        return Response({
            'is_authenticated': True,
            'searches_used':    used,
            'searches_limit':   limit,          # 0 = unlimited (premium)
            'allowed':          allowed,
            'is_premium':       is_premium(request.user),
            'reset_at':         get_ai_search_reset_at().isoformat() if limit > 0 else None,
        })


# ─── Persist AIRecommendation rows ───────────────────────────────────────────

def _persist_ai_recommendations(user, items, cap=10):
    for item in (items or [])[:cap]:
        try:
            pro_id = int(item.get('id'))
        except (TypeError, ValueError):
            continue

        raw_score = item.get('ai_confidence') or item.get('relevance_score') or 0
        try:
            score = max(0.0, min(float(raw_score), 999.99))
        except (TypeError, ValueError):
            score = 0.0

        reason = (item.get('ai_reason') or item.get('recommendation_reason') or 'Matched your search')[:500]

        try:
            AIRecommendation.objects.update_or_create(
                user=user, professional_id=pro_id,
                defaults={'score': score, 'reason': reason},
            )
        except Exception:
            continue


# ─── AI Search Endpoint ───────────────────────────────────────────────────────

class AISearchView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        raw_query = request.data.get('query', '')
        if not isinstance(raw_query, str) or not raw_query.strip():
            return Response({'error': 'query field is required.'}, status=400)

        query = raw_query.strip()

        # ── 1. Authentication Check ───────────────────────────────────────
        if not request.user.is_authenticated:
            return Response({
                'ai_used':  False,
                'message':  'Please login to use AI Search.',
                'results':  [],
                'upgrade':  False,
            }, status=status.HTTP_401_UNAUTHORIZED)

        # ── 2. Daily Limit Check ──────────────────────────────────────────
        allowed, used, limit, upgrade_required = check_ai_search_allowed(request.user)
        if not allowed:
            limit_display = f"{limit}/day" if limit > 0 else "unlimited"
            return Response({
                'error':            'daily_limit_reached',
                'message':          f"You've reached today's AI search limit ({limit_display}). Upgrade to Premium for more searches.",
                'searches_used':    used,
                'searches_limit':   limit,
                'upgrade':          upgrade_required,
                'ai_used':          False,
                'reset_at':         get_ai_search_reset_at().isoformat(),
            }, status=status.HTTP_429_TOO_MANY_REQUESTS)

        # ── 3. Record Search History ──────────────────────────────────────
        SearchHistory.objects.create(user=request.user, query=query)

        # ── 4. Personalization Profile ────────────────────────────────────
        personalization_profile = get_personalization_profile(request.user)

        # ── 5. Customer GPS Location ──────────────────────────────────────
        try:
            customer_lat = float(request.data.get('latitude'))  if request.data.get('latitude') is not None else None
            customer_lng = float(request.data.get('longitude')) if request.data.get('longitude') is not None else None
        except (TypeError, ValueError):
            customer_lat = customer_lng = None

        # ── 6. Known Cities Cache ─────────────────────────────────────────
        known_cities = cache.get('ai_search_known_cities')
        if known_cities is None:
            known_cities = set(
                UserProfile.objects.exclude(city__isnull=True)
                .exclude(city__exact='')
                .values_list('city', flat=True)
                .distinct()
            )
            cache.set('ai_search_known_cities', known_cities, timeout=600)

        # ── 7. Extract Natural Language Intent ────────────────────────────
        intent = _extract_intent(query, known_cities=known_cities)
        intent_notes  = []
        unmet_intents = []

        query_lower = query.lower()

        # Prefetch active subscriptions once to eliminate N+1 queries
        active_premium_ids = set(
            Subscription.objects.filter(
                status='active'
            ).filter(
                DQ(end_date__isnull=True) | DQ(end_date__gt=timezone.now())
            ).exclude(plan__billing='free').values_list('user_id', flat=True)
        )

        def name_of(pro):
            return (pro.full_name or pro.user.name or '').strip()

        def _prof(pro):
            try:
                return pro.user.professionalprofile
            except Exception:
                return None

        def _rate(pro):
            return float(getattr(_prof(pro), 'hourly_rate', 0) or 0)

        def _rating(pro):
            return float(getattr(_prof(pro), 'average_rating', 0) or 0)

        def _exp(pro):
            return int(getattr(_prof(pro), 'experience_years', 0) or 0)

        def _dist(pro):
            if customer_lat is None or customer_lng is None or pro.latitude is None or pro.longitude is None:
                return None
            return _haversine_km(customer_lat, customer_lng, float(pro.latitude), float(pro.longitude))

        def _matches_profession(pro, terms):
            prof = _prof(pro)
            if not prof:
                return False
            name_text = name_of(pro)
            cat_name = prof.category.name if prof.category else ''
            cat_lower = cat_name.lower()
            spec_lower = (prof.specialization or '').lower()

            # Cross-domain conflict prevention (e.g. Electricians or Engineers in dummy test data matching doctor searches)
            medical_terms = {'doctor', 'physician', 'dr', 'surgeon', 'fever', 'clinic', 'dentist'}
            if any(t in medical_terms for t in terms):
                non_med_cats = {'engineer', 'electric', 'plumb', 'legal', 'law', 'tutor', 'carpenter', 'salon', 'barber'}
                if any(bad in cat_lower for bad in non_med_cats):
                    return False
                non_med_specs = {'civil engineer', 'software engineer', 'electrician', 'plumber', 'lawyer', 'chef', 'makeup artist', 'carpenter', 'graphic designer'}
                if any(bad in spec_lower for bad in non_med_specs):
                    return False

            if any(t in {'electrician', 'wiring', 'electrical', 'electricista'} for t in terms):
                if any(bad in cat_lower for bad in {'doctor', 'medical', 'health', 'legal', 'law', 'tutor'}):
                    return False

            haystack = _normalize(' '.join(filter(None, [
                name_text,
                cat_name,
                prof.specialization, prof.skills, prof.services, prof.tags,
            ])))
            hay_words = set(haystack.split())
            if any((t in hay_words) if len(t) < 4 else (any(w == t or w.startswith(t) or t in w for w in hay_words)) for t in terms):
                return True

            # Category synonym / domain mapping
            if 'legal' in cat_lower or 'law' in cat_lower:
                if any(t in {'lawyer', 'attorney', 'advocate', 'wakeel', 'vakeel', 'abogado'} for t in terms):
                    return True
            if 'doctor' in cat_lower or 'health' in cat_lower or 'medical' in cat_lower:
                if any(t in {'doctor', 'physician', 'dr', 'tabeeb', 'medecin', 'medico'} for t in terms):
                    return True
            if 'dent' in cat_lower:
                if any(t in {'dentist', 'dental', 'orthodontist', 'dentiste', 'dentista'} for t in terms):
                    return True
            if 'electr' in cat_lower:
                if any(t in {'electrician', 'wiring', 'electrical', 'electricista'} for t in terms):
                    return True
            if 'plumb' in cat_lower:
                if any(t in {'plumber', 'plumbing', 'sanitary', 'plombier', 'fontanero'} for t in terms):
                    return True
            return False

        # ── 8. Base QuerySet with Bounded Retrieval ───────────────────────
        qs = UserProfile.objects.select_related(
            'user', 'user__professionalprofile', 'user__professionalprofile__category'
        ).filter(user__role='professional').annotate(
            completed_jobs_count=Count(
                'user__bookings_received',
                filter=DQ(user__bookings_received__status='completed'),
                distinct=True,
            )
        )

        # Check if the query matches a specific professional name directly
        direct_name_match_exists = qs.filter(
            DQ(user__name__icontains=query) |
            DQ(full_name__icontains=query)
        ).exists()

        has_semantic_intent = bool(
            intent['profession_terms'] or
            intent['city'] or
            intent['max_budget'] is not None or
            intent['wants_cheap'] or
            intent['gender'] or
            intent['wants_urgent'] or
            intent['wants_nearby'] or
            intent['min_rating'] is not None or
            intent['wants_top_rated'] or
            intent['wants_verified'] or
            direct_name_match_exists
        )

        user_is_premium = is_premium(request.user)
        remaining = (limit - used - 1) if limit > 0 else None

        # Gibberish / Unrecognized query safeguard:
        if not has_semantic_intent and len(query.strip()) > 1:
            return Response({
                'query':                 query,
                'ai_result':             f'No matching professionals found for "{query}".',
                'matched_professionals': [],
                'recommendations':       {},
                'ai_used':               True,
                'is_premium_result':     user_is_premium,
                'searches_used':         used + 1,
                'searches_remaining':    remaining,
                'searches_limit':        limit if limit > 0 else None,
                'error_detail':          None,
                'ai_fallback_used':      False,
                'requested_city':        None,
                'city_fallback_used':    False,
                'availability_fallback_used':    False,
                'availability_fallback_message': '',
                'detected_intent':       [],
                'unmet_intent':          ['no_semantic_match'],
                'structured_intent':     _format_structured_intent(intent, ['no_semantic_match']),
                'emergency_alert':       intent.get('emergency_message'),
                'reset_at':              get_ai_search_reset_at().isoformat() if limit > 0 else None,
            })

        # ── 9. Strict Hard Constraints ────────────────────────────────────

        # A. Profession / Category / Name Filter
        if intent['profession_terms']:
            terms = intent['profession_terms']
            candidates = [p for p in qs[:300] if _matches_profession(p, terms)]
            if candidates:
                p_ids = [p.id for p in candidates]
                qs = qs.filter(id__in=p_ids)
                clean_name = (intent.get('canonical_profession') or terms[0]).capitalize()
                intent_notes.append(f"profession: {clean_name}")
            elif not direct_name_match_exists:
                unmet_intents.append('profession')
                return Response({
                    'query':                 query,
                    'ai_result':             f'No professionals found for "{query}".',
                    'matched_professionals': [],
                    'recommendations':       _build_ai_recommendations(
                        query, intent, qs[:50], customer_lat, customer_lng, personalization_profile, active_premium_ids
                    ),
                    'ai_used':               True,
                    'is_premium_result':     user_is_premium,
                    'searches_used':         used + 1,
                    'searches_remaining':    remaining,
                    'searches_limit':        limit if limit > 0 else None,
                    'error_detail':          None,
                    'ai_fallback_used':      False,
                    'requested_city':        intent['city'],
                    'city_fallback_used':    False,
                    'availability_fallback_used':    False,
                    'availability_fallback_message': '',
                    'detected_intent':       intent_notes,
                    'unmet_intent':          unmet_intents,
                    'structured_intent':     _format_structured_intent(intent, unmet_intents),
                    'emergency_alert':       intent.get('emergency_message'),
                    'reset_at':              get_ai_search_reset_at().isoformat() if limit > 0 else None,
                })
        elif direct_name_match_exists:
            # Filter specifically to the candidates whose names match the query
            qs = qs.filter(DQ(user__name__icontains=query) | DQ(full_name__icontains=query))
        else:
            # Query has no profession terms and no name match
            is_solely_city = bool(intent['city'] and _normalize(query) == _normalize(intent['city']))
            if not is_solely_city:
                # Query contains substantive words (e.g. "astronaut in Badin", "weather in Paris today") that match no professional
                unmet_intents.append('profession')
                return Response({
                    'query':                 query,
                    'ai_result':             f'No matching professionals found for "{query}".',
                    'matched_professionals': [],
                    'recommendations':       _build_ai_recommendations(
                        query, intent, qs[:50], customer_lat, customer_lng, personalization_profile, active_premium_ids
                    ),
                    'ai_used':               True,
                    'is_premium_result':     user_is_premium,
                    'searches_used':         used + 1,
                    'searches_remaining':    remaining,
                    'searches_limit':        limit if limit > 0 else None,
                    'error_detail':          None,
                    'ai_fallback_used':      False,
                    'requested_city':        intent['city'],
                    'city_fallback_used':    False,
                    'availability_fallback_used':    False,
                    'availability_fallback_message': '',
                    'detected_intent':       intent_notes,
                    'unmet_intent':          unmet_intents,
                    'structured_intent':     _format_structured_intent(intent, unmet_intents),
                    'emergency_alert':       intent.get('emergency_message'),
                    'reset_at':              get_ai_search_reset_at().isoformat() if limit > 0 else None,
                })

        # B. City Filter
        requested_city = intent['city']
        city_fallback_used = False
        if requested_city:
            city_qs = qs.filter(city__iexact=requested_city)
            if city_qs.exists():
                qs = city_qs
                intent_notes.append(f"location: {requested_city}")
            else:
                unmet_intents.append(f"location: {requested_city}")
                city_fallback_used = True
                return Response({
                    'query':                 query,
                    'ai_result':             f'No professionals found in {requested_city} matching your request.',
                    'matched_professionals': [],
                    'recommendations':       _build_ai_recommendations(
                        query, intent, UserProfile.objects.filter(user__role='professional')[:50],
                        customer_lat, customer_lng, personalization_profile, active_premium_ids
                    ),
                    'ai_used':               True,
                    'is_premium_result':     user_is_premium,
                    'searches_used':         used + 1,
                    'searches_remaining':    remaining,
                    'searches_limit':        limit if limit > 0 else None,
                    'error_detail':          None,
                    'ai_fallback_used':      False,
                    'requested_city':        requested_city,
                    'city_fallback_used':    True,
                    'availability_fallback_used':    False,
                    'availability_fallback_message': '',
                    'detected_intent':       intent_notes,
                    'unmet_intent':          unmet_intents,
                    'structured_intent':     _format_structured_intent(intent, unmet_intents),
                    'emergency_alert':       intent.get('emergency_message'),
                    'reset_at':              get_ai_search_reset_at().isoformat() if limit > 0 else None,
                })

        # C. Budget Filter (Strict Maximum Price)
        if intent['max_budget'] is not None:
            budget_qs = qs.filter(
                user__professionalprofile__hourly_rate__lte=intent['max_budget'],
                user__professionalprofile__hourly_rate__gt=0,
            )
            if budget_qs.exists():
                qs = budget_qs
                intent_notes.append(f"budget: under {intent['max_budget']:.0f}")
            else:
                unmet_intents.append('budget')
                return Response({
                    'query':                 query,
                    'ai_result':             f'No professionals found within your budget of {intent["max_budget"]:.0f}.',
                    'matched_professionals': [],
                    'recommendations':       _build_ai_recommendations(
                        query, intent, qs[:50], customer_lat, customer_lng, personalization_profile, active_premium_ids
                    ),
                    'ai_used':               True,
                    'is_premium_result':     user_is_premium,
                    'searches_used':         used + 1,
                    'searches_remaining':    remaining,
                    'searches_limit':        limit if limit > 0 else None,
                    'error_detail':          None,
                    'ai_fallback_used':      False,
                    'requested_city':        requested_city,
                    'city_fallback_used':    False,
                    'availability_fallback_used':    False,
                    'availability_fallback_message': '',
                    'detected_intent':       intent_notes,
                    'unmet_intent':          unmet_intents,
                    'structured_intent':     _format_structured_intent(intent, unmet_intents),
                    'emergency_alert':       intent.get('emergency_message'),
                    'reset_at':              get_ai_search_reset_at().isoformat() if limit > 0 else None,
                })

        # C2. Budget Filter (Strict Minimum Price Floor)
        if intent.get('min_budget') is not None:
            min_budget_qs = qs.filter(
                user__professionalprofile__hourly_rate__gte=intent['min_budget'],
            )
            if min_budget_qs.exists():
                qs = min_budget_qs
                intent_notes.append(f"budget: min {intent['min_budget']:.0f}")
            else:
                unmet_intents.append('budget')
                return Response({
                    'query':                 query,
                    'ai_result':             f'No professionals found with rate at or above your minimum budget of {intent["min_budget"]:.0f}.',
                    'matched_professionals': [],
                    'recommendations':       _build_ai_recommendations(
                        query, intent, qs[:50], customer_lat, customer_lng, personalization_profile, active_premium_ids
                    ),
                    'ai_used':               True,
                    'is_premium_result':     user_is_premium,
                    'searches_used':         used + 1,
                    'searches_remaining':    remaining,
                    'searches_limit':        limit if limit > 0 else None,
                    'error_detail':          None,
                    'ai_fallback_used':      False,
                    'requested_city':        requested_city,
                    'city_fallback_used':    False,
                    'availability_fallback_used':    False,
                    'availability_fallback_message': '',
                    'detected_intent':       intent_notes,
                    'unmet_intent':          unmet_intents,
                    'structured_intent':     _format_structured_intent(intent, unmet_intents),
                    'emergency_alert':       intent.get('emergency_message'),
                    'reset_at':              get_ai_search_reset_at().isoformat() if limit > 0 else None,
                })

        # D. Gender Filter
        if intent['gender']:
            gender_qs = qs.filter(gender__iexact=intent['gender'])
            if gender_qs.exists():
                qs = gender_qs
                intent_notes.append(f"gender: {intent['gender']}")
            else:
                unmet_intents.append('gender')
                return Response({
                    'query':                 query,
                    'ai_result':             f'No {intent["gender"]} professionals found matching your request.',
                    'matched_professionals': [],
                    'recommendations':       _build_ai_recommendations(
                        query, intent, qs[:50], customer_lat, customer_lng, personalization_profile, active_premium_ids
                    ),
                    'ai_used':               True,
                    'is_premium_result':     user_is_premium,
                    'searches_used':         used + 1,
                    'searches_remaining':    remaining,
                    'searches_limit':        limit if limit > 0 else None,
                    'error_detail':          None,
                    'ai_fallback_used':      False,
                    'requested_city':        requested_city,
                    'city_fallback_used':    False,
                    'availability_fallback_used':    False,
                    'availability_fallback_message': '',
                    'detected_intent':       intent_notes,
                    'unmet_intent':          unmet_intents,
                    'structured_intent':     _format_structured_intent(intent, unmet_intents),
                    'emergency_alert':       intent.get('emergency_message'),
                    'reset_at':              get_ai_search_reset_at().isoformat() if limit > 0 else None,
                })

        # E. Urgency / Availability Filter
        availability_fallback_used = False
        availability_fallback_message = ''
        if intent['wants_urgent']:
            urgent_qs = qs.filter(user__professionalprofile__is_available=True)
            if urgent_qs.exists():
                qs = urgent_qs
                intent_notes.append('availability: today/now')
            else:
                unmet_intents.append('availability')
                availability_fallback_used = True
                availability_fallback_message = (
                    'No matching professionals are currently available right now — showing available matches for later.'
                )

        # F. Verification Filter
        if intent['wants_verified']:
            v_qs = qs.filter(user__professionalprofile__is_verified=True)
            if v_qs.exists():
                qs = v_qs
                intent_notes.append('verification: verified only')
            else:
                unmet_intents.append('verification')

        # G. Distance / Proximity Filter
        if customer_lat is not None and customer_lng is not None:
            if intent['max_distance_km'] is not None:
                pool = list(qs[:100])
                within_radius = [p for p in pool if _dist(p) is not None and _dist(p) <= intent['max_distance_km']]
                if within_radius:
                    qs = qs.filter(id__in=[p.id for p in within_radius])
                    intent_notes.append(f"distance: within {intent['max_distance_km']:.0f}km")
                else:
                    unmet_intents.append('distance')
            elif intent['wants_nearby']:
                intent_notes.append('distance: nearest first')
        elif intent['wants_nearby'] or intent['max_distance_km'] is not None:
            unmet_intents.append('distance: location unavailable')

        search_pool = list(qs.order_by(
            '-user__professionalprofile__is_verified',
            '-user__professionalprofile__average_rating',
        )[:100])

        if not search_pool:
            return Response({
                'query':                 query,
                'ai_result':             f'No matching professionals found for "{query}".',
                'matched_professionals': [],
                'recommendations':       {},
                'ai_used':               True,
                'is_premium_result':     user_is_premium,
                'searches_used':         used + 1,
                'searches_remaining':    remaining,
                'searches_limit':        limit if limit > 0 else None,
                'error_detail':          None,
                'ai_fallback_used':      False,
                'requested_city':        requested_city,
                'city_fallback_used':    False,
                'availability_fallback_used':    availability_fallback_used,
                'availability_fallback_message': availability_fallback_message,
                'detected_intent':       intent_notes,
                'unmet_intent':          unmet_intents,
                'structured_intent':     _format_structured_intent(intent, unmet_intents),
                'emergency_alert':       intent.get('emergency_message'),
                'reset_at':              get_ai_search_reset_at().isoformat() if limit > 0 else None,
            })

        # ── 10. Priority-Ordered Ranking ──────────────────────────────────
        pool_size = max(len(search_pool), 1)
        intent_rank = {id(p): i for i, p in enumerate(search_pool)}

        def _profession_terms_or_query():
            return intent['profession_terms'] or [query_lower]

        def _field_match_score(field_text: str, terms, exact, starts, contains) -> float:
            field_text = _normalize(field_text or '')
            if not field_text or not terms:
                return 0.0
            best = 0.0
            for t in terms:
                if not t:
                    continue
                if field_text == t:
                    best = max(best, exact)
                elif field_text.startswith(t):
                    best = max(best, starts)
                elif t in field_text:
                    best = max(best, contains)
            return best

        def _rank_score(pro) -> float:
            prof  = _prof(pro)
            terms = _profession_terms_or_query()
            score = 0.0

            # 0. Exact name match wins outright
            if query_lower and query_lower in _normalize(name_of(pro)):
                score += 1000.0

            # 1. Intent match position
            score += 200.0 * (1 - intent_rank.get(id(pro), pool_size) / pool_size)

            # 2. Profession Match
            cat_name = prof.category.name if (prof and prof.category) else ''
            haystack = ' '.join(filter(None, [
                cat_name, getattr(prof, 'skills', ''), getattr(prof, 'tags', ''),
                getattr(prof, 'services', ''),
            ])) if prof else ''
            score += _field_match_score(haystack, terms, exact=180, starts=140, contains=100)

            # 3. Specialization
            score += _field_match_score(getattr(prof, 'specialization', '') if prof else '',
                                         terms, exact=160, starts=120, contains=80)

            # 4. Nearest (GPS)
            d = _dist(pro)
            if d is not None:
                score += max(0.0, 140.0 - d * 1.4)

            # 5. Verified
            if getattr(prof, 'is_verified', False):
                score += 120

            # 6. Highest Rating
            score += _rating(pro) * 20

            # 7. Availability
            if getattr(prof, 'is_available', True):
                score += 80

            # 8. Experience
            score += min(_exp(pro), 15) * 4

            # 9. Popularity
            score += min(getattr(pro, 'completed_jobs_count', 0) or 0, 20) * 2

            # 10. Response Time
            resp_hrs = getattr(prof, 'response_time_hrs', 24.0) or 24.0
            score += max(0.0, 20.0 - resp_hrs * 0.83)

            # 11. Personalization boost
            if personalization_profile and prof:
                score += personalization_boost({
                    'id':             str(pro.user_id),
                    'category_id':    prof.category_id,
                    'category_name':  prof.category.name if prof.category else '',
                    'specialization': getattr(prof, 'specialization', ''),
                    'hourly_rate':    float(getattr(prof, 'hourly_rate', 0) or 0),
                }, personalization_profile)

            return score

        rank_score_by_pro_id = {id(p): _rank_score(p) for p in search_pool}

        ordered_pros = sorted(
            search_pool,
            key=lambda p: (
                1 if query_lower in name_of(p).lower() else 0,
                rank_score_by_pro_id[id(p)],
                -int(p.user_id),
            ),
            reverse=True,
        )

        top_n = 5 if user_is_premium else 3
        candidate_slice = ordered_pros[:20] if user_is_premium else ordered_pros[:10]

        pro_list_desc = [
            f"Name: {name_of(pro)}, City: {pro.city}, Rate: ${_rate(pro):.0f}/hr, "
            f"Rating: {_rating(pro):.1f}/5, Gender: {pro.gender or 'unspecified'}, "
            f"Available: {'yes' if getattr(_prof(pro), 'is_available', True) else 'no'}, "
            f"Experience: {_exp(pro)}yrs"
            for pro in candidate_slice
        ]

        intent_summary = (
            f"Detected intent — {'; '.join(intent_notes)}." if intent_notes
            else "No specific price/gender/urgency/rating intent detected — rank by general relevance."
        )

        prompt = f"""
You are ProFinder's AI assistant. You understand natural language requests across multiple languages (English, Urdu, Hindi, Arabic, French, Spanish, Roman Urdu).

User is searching for: "{query}"
{intent_summary}

Available professionals (strictly verified and pre-filtered to match the user's explicit constraints):
{', '.join(pro_list_desc)}

IMPORTANT RULES:
1. Exact name match: If any professional's name contains or matches "{query}", rank them highest.
2. Only rank professionals from the list above using their ACTUAL listed attributes. Never invent prices or qualifications.
3. In "reason", provide a concise 1-sentence explanation referencing real attributes (e.g. "Affordable at $15/hr", "Available today in Karachi").

Respond with ONLY a valid JSON array, no other text, no markdown fences.
Each item must have:
"name" (must exactly match one of the candidate names above),
"reason" (short explanation referencing real attributes),
"confidence" (integer 1-10).

Rank the top {top_n} most relevant candidates.
"""

        # ── 11. Gemini Call with Hard Constraint Revalidation ─────────────
        ai_result       = None
        ai_error        = None
        matched_pros    = []
        ai_fallback_used = False

        try:
            _api_key = _gemini_api_key()
            if not _api_key:
                raise RuntimeError('GEMINI_API_KEY is not configured on the server.')

            client_kwargs = {'api_key': _api_key}
            if genai_types and hasattr(genai_types, 'HttpOptions'):
                client_kwargs['http_options'] = genai_types.HttpOptions(timeout=10000)
            client = genai.Client(**client_kwargs)
            response = client.models.generate_content(
                model='models/gemini-flash-latest',
                contents=prompt,
            )
            raw_text = response.text or ''
            cleaned = raw_text.strip()
            cleaned = re.sub(r'^```json\s*|^```\s*|```$', '', cleaned.strip(), flags=re.MULTILINE).strip()

            ranked = json.loads(cleaned)

            candidate_by_name = {name_of(p).lower(): p for p in candidate_slice}
            candidate_by_id = {str(p.user_id): p for p in candidate_slice}
            allowed_candidate_ids = set(candidate_by_id.keys())
            rank_score_by_user_id = {
                str(p.user.id): rank_score_by_pro_id[id(p)] for p in candidate_slice
            }

            for item in ranked:
                # Untrusted model output validation: candidate must match permitted candidate set
                ai_id = str(item.get('id') or '').strip()
                ai_name = (item.get('name') or '').strip().lower()

                pro = None
                if ai_id and ai_id in candidate_by_id:
                    pro = candidate_by_id[ai_id]
                elif ai_name:
                    pro = candidate_by_name.get(ai_name)
                    if not pro:
                        for c_name, c_pro in candidate_by_name.items():
                            if c_name == ai_name or ai_name in c_name:
                                pro = c_pro
                                break

                # Strictly reject candidates not in the permitted candidate slice
                if pro and str(pro.user_id) in allowed_candidate_ids:
                    # REVALIDATE HARD CONSTRAINTS
                    if requested_city and (pro.city or '').strip().lower() != requested_city.strip().lower():
                        continue
                    if intent['max_budget'] is not None and _rate(pro) > intent['max_budget']:
                        continue
                    if intent.get('min_budget') is not None and _rate(pro) < intent['min_budget']:
                        continue
                    if intent['gender'] and (pro.gender or '').lower() != intent['gender']:
                        continue

                    data = _build_professional_data(
                        pro.user, customer_lat, customer_lng,
                        is_premium=(pro.user_id in active_premium_ids)
                    )
                    if data:
                        data['ai_reason']     = item.get('reason', '')
                        data['ai_confidence'] = item.get('confidence', 0)
                        matched_pros.append(data)

            # Sort by deterministic priority score
            matched_pros.sort(
                key=lambda d: rank_score_by_user_id.get(d.get('id'), 0.0),
                reverse=True,
            )

            ai_result = '\n\n'.join(
                f"{p['name']} | {p.get('ai_reason', '')}" for p in matched_pros
            ) or 'No matching professionals found.'

        except Exception as e:
            ai_error = str(e)
            logger.info('[ai_search] Gemini skipped/failed (%s), falling back to priority ranking.', e)
            matched_pros = []

        # Deterministic fallback when Gemini is unavailable, errors, or fails to return candidates
        if (ai_error or not matched_pros) and candidate_slice:
            ai_fallback_used = True
            clean_pro = (intent.get('canonical_profession') or '').capitalize()
            if clean_pro:
                city_part = f" in {requested_city.title()}" if requested_city else ''
                _why = f"Best match for your request ({clean_pro}{city_part})"
            else:
                _why = ('Best match for your request' +
                        (f" ({'; '.join(intent_notes)})" if intent_notes else ''))
            for _pro in candidate_slice[:top_n]:
                # Revalidate hard constraints in fallback
                if requested_city and (_pro.city or '').strip().lower() != requested_city.strip().lower():
                    continue
                if intent['max_budget'] is not None and _rate(_pro) > intent['max_budget']:
                    continue
                if intent.get('min_budget') is not None and _rate(_pro) < intent['min_budget']:
                    continue
                if intent['gender'] and (_pro.gender or '').lower() != intent['gender']:
                    continue

                _data = _build_professional_data(
                    _pro.user, customer_lat, customer_lng,
                    is_premium=(_pro.user_id in active_premium_ids)
                )
                if _data:
                    _data['ai_reason']     = _why
                    _data['ai_confidence'] = 0
                    matched_pros.append(_data)

            if matched_pros:
                ai_result = '\n\n'.join(f"{p['name']} | {p.get('ai_reason', '')}" for p in matched_pros)
            else:
                ai_result = f'No matching professionals found for "{query}".'

        # Prepend emergency safety guidance if emergency phrases detected
        if intent.get('is_emergency') and intent.get('emergency_message'):
            ai_result = f"⚠️ {intent['emergency_message']}\n\n{ai_result}"

        # Recommendations fallback if no exact candidate matched
        recommendations = {}
        if not matched_pros:
            recommendations = _build_ai_recommendations(
                query, intent, UserProfile.objects.filter(user__role='professional')[:50],
                customer_lat, customer_lng, personalization_profile, active_premium_ids
            )

        # ── 12. Persist Recommendations for /recommendations/ ─────────────
        if matched_pros:
            _persist_ai_recommendations(request.user, matched_pros)
        else:
            fallback_items = (
                recommendations.get('frequently_booked_professionals', [])
                + recommendations.get('similar_professionals', [])
            )
            _persist_ai_recommendations(request.user, fallback_items)

        return Response({
            'query':                 query,
            'ai_result':             ai_result,
            'matched_professionals': matched_pros,
            'recommendations':       recommendations,
            'ai_used':               True,
            'is_premium_result':     user_is_premium,
            'searches_used':         used + 1,
            'searches_remaining':    remaining,
            'searches_limit':        limit if limit > 0 else None,
            'error_detail':          ai_error,
            'ai_fallback_used':      ai_fallback_used,
            'requested_city':        requested_city,
            'city_fallback_used':    city_fallback_used,
            'availability_fallback_used':    availability_fallback_used,
            'availability_fallback_message': availability_fallback_message,
            'detected_intent':       intent_notes,
            'unmet_intent':          unmet_intents,
            'structured_intent':     _format_structured_intent(intent, unmet_intents),
            'emergency_alert':       intent.get('emergency_message'),
            'reset_at':              get_ai_search_reset_at().isoformat() if limit > 0 else None,
        })


# ─── "No exact match" recommendations ─────────────────────────────────────────

def _build_ai_recommendations(query, intent, professionals, customer_lat, customer_lng, personalization_profile=None, active_premium_ids=None):
    if active_premium_ids is None:
        active_premium_ids = set()

    def _prof(pro):
        try:
            return pro.user.professionalprofile
        except Exception:
            return None

    def _mk(pro, reason):
        data = _build_professional_data(
            pro.user, customer_lat, customer_lng,
            is_premium=(pro.user_id in active_premium_ids)
        )
        if data:
            data['recommendation_reason'] = reason
        return data

    pro_list = list(professionals)

    all_terms = set(intent.get('profession_terms', []))
    for w in _normalize(query).split():
        all_terms.update(_expand_query(w))
    all_terms.discard('')

    similar = []
    matched_categories = set()
    if all_terms:
        for pro in pro_list:
            prof = _prof(pro)
            if not prof:
                continue
            haystack = _normalize(' '.join(filter(None, [
                prof.category.name if prof.category else '',
                prof.specialization, prof.skills, prof.tags, prof.services,
            ])))
            if any(t in haystack for t in all_terms):
                d = _mk(pro, f'Similar to your search for "{query}"')
                if d:
                    similar.append(d)
                    if prof.category:
                        matched_categories.add(prof.category.name)
    similar = similar[:5]

    category_counts = {}
    category_sample = {}
    for pro in pro_list:
        prof = _prof(pro)
        cat = prof.category.name if (prof and prof.category) else None
        if cat and cat not in matched_categories:
            category_counts[cat] = category_counts.get(cat, 0) + 1
            category_sample.setdefault(cat, pro)

    related = []
    for cat_name, _count in sorted(category_counts.items(), key=lambda x: -x[1])[:3]:
        d = _mk(category_sample[cat_name], f'Related profession you might also need: {cat_name}')
        if d:
            related.append(d)

    trending = []
    for pro in sorted(pro_list, key=lambda p: -(getattr(p, 'completed_jobs_count', 0) or 0))[:8]:
        jobs = getattr(pro, 'completed_jobs_count', 0) or 0
        if jobs > 0:
            d = _mk(pro, f'Trending — completed {jobs} job{"s" if jobs != 1 else ""} on ProFinder')
            if d:
                trending.append(d)
        if len(trending) >= 5:
            break

    nearby = []
    if customer_lat is not None and customer_lng is not None:
        def _dist(pro):
            if pro.latitude is None or pro.longitude is None:
                return None
            return _haversine_km(customer_lat, customer_lng, float(pro.latitude), float(pro.longitude))

        with_dist = sorted(
            [(pro, _dist(pro)) for pro in pro_list if _dist(pro) is not None],
            key=lambda x: x[1],
        )
        for pro, dist_km in with_dist[:8]:
            rating = float(getattr(_prof(pro), 'average_rating', 0) or 0)
            if rating >= 3.5:
                d = _mk(pro, f'Popular nearby — {rating:.1f}★ rated, {dist_km:.1f}km away')
                if d:
                    nearby.append(d)
            if len(nearby) >= 5:
                break

    frequent_booked = []
    frequent_ids = (personalization_profile or {}).get('frequently_contacted_pro_ids')
    if frequent_ids:
        for pro in pro_list:
            if str(pro.user_id) in frequent_ids:
                d = _mk(pro, 'You\u2019ve booked this professional before')
                if d:
                    frequent_booked.append(d)
            if len(frequent_booked) >= 5:
                break

    return {
        'similar_professionals':        similar,
        'related_professions':          related,
        'trending_professionals':       trending,
        'popular_nearby_professionals': nearby,
        'frequently_booked_professionals': frequent_booked,
    }


# ─── AI Recommendations ───────────────────────────────────────────────────────

class AIRecommendationView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        recs = AIRecommendation.objects.filter(user=request.user)
        return Response(AIRecommendationSerializer(recs, many=True).data)


# ─── Search History ───────────────────────────────────────────────────────────

class SearchHistoryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        history = SearchHistory.objects.filter(user=request.user)
        return Response(SearchHistorySerializer(history, many=True).data)

    def post(self, request):
        serializer = SearchHistorySerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ─── Localize dynamic display text ───────────────────────────────────────────

class LocalizeView(APIView):
    permission_classes = [IsAuthenticated]
    throttle_scope = 'localize'

    def post(self, request):
        from apps.ai_engine.localize import localize_texts, KINDS, MAX_ITEMS, MAX_LEN

        lang = str(request.data.get('lang') or '').strip().lower()
        items = request.data.get('items') or []
        if not isinstance(items, list) or len(items) > MAX_ITEMS:
            return Response({'error': f'items must be a list of at most {MAX_ITEMS}'}, status=400)

        grouped = {}
        for it in items:
            if not isinstance(it, dict):
                continue
            kind = it.get('kind')
            text = str(it.get('text') or '').strip()
            if kind in KINDS and text and len(text) <= MAX_LEN:
                grouped.setdefault(kind, []).append(text)

        result = {k: localize_texts(v, lang, k) for k, v in grouped.items()}
        return Response({'translations': result})