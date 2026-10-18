# apps/search/views.py

import math
import re
import unicodedata
import logging
import httpx
from difflib import get_close_matches
from math import radians, sin, cos, sqrt, atan2
from django.core.cache import cache
from rest_framework.response import Response
from rest_framework.views    import APIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from apps.users.models  import User
from apps.search.models import Category, Favorite
from apps.search.aliases import (
    alias_lookup as _alias_lookup,
    translate_phrases as _alias_phrases,
    translate_cities as _translate_cities,
)
from apps.search.alias_seed import CITY_ALIASES
from apps.search.fuzzy import (
    query_tokens as _fz_tokens,
    fuzzy_filter_q as _fz_q,
    fuzzy_bonus as _fuzzy_bonus,
)
from apps.payments.exchange import resolve_currency_for_user

logger = logging.getLogger(__name__)

EARTH_RADIUS_KM  = 6371.0
DISTANCE_BUCKETS = [5, 15, 30, 60, 120]

# ── City Centroid Coordinates (Normalized English Lowercase) ───────────────────
_CITY_CENTROIDS = {
    'karachi': (24.8607, 67.0011), 'hyderabad': (25.3960, 68.3578),
    'thatta': (24.7461, 67.9243), 'jamshoro': (25.4300, 68.2800),
    'sukkur': (27.7052, 68.8574), 'larkana': (27.5590, 68.2120),
    'nawabshah': (26.2442, 68.4100), 'mirpurkhas': (25.5270, 69.0110),
    'lahore': (31.5204, 74.3587), 'islamabad': (33.6844, 73.0479),
    'rawalpindi': (33.5651, 73.0169), 'peshawar': (34.0151, 71.5249),
    'quetta': (30.1798, 66.9750), 'multan': (30.1575, 71.5249),
    'faisalabad': (31.4504, 73.1350), 'gujranwala': (32.1877, 74.1945),
    'sialkot': (32.4945, 74.5229), 'bahawalpur': (29.3956, 71.6836),
    'sargodha': (32.0836, 72.6711), 'abbottabad': (34.1463, 73.2117),
    'mardan': (34.1986, 72.0404), 'gwadar': (25.1264, 62.3225),
    'badin': (24.6560, 68.8390), 'dadu': (26.7300, 67.7750),
    'umerkot': (25.3606, 69.7361), 'tando allahyar': (25.4600, 68.7180),
    'tando muhammad khan': (25.1233, 68.5367), 'shikarpur': (27.9558, 68.6386),
    'khairpur': (27.5295, 68.7592), 'ghotki': (28.0075, 69.3150),
    'jacobabad': (28.2769, 68.4514), 'matiari': (25.5989, 68.4514),
    'sanghar': (26.0464, 68.9481), 'kashmore': (28.4331, 69.5814),
}

_CITY_RADIUS_KM = {
    'karachi': 55, 'lahore': 45, 'islamabad': 35, 'rawalpindi': 30,
    'faisalabad': 30, 'peshawar': 25, 'multan': 25, 'quetta': 25,
    'gujranwala': 20, 'hyderabad': 20,
}
_DEFAULT_CITY_RADIUS_KM = 15

def _levenshtein_distance(s1: str, s2: str) -> int:
    """Exact Levenshtein edit distance without external dependencies."""
    if len(s1) < len(s2):
        return _levenshtein_distance(s2, s1)
    if len(s2) == 0:
        return len(s1)
    previous_row = range(len(s2) + 1)
    for i, c1 in enumerate(s1):
        current_row = [i + 1]
        for j, c2 in enumerate(s2):
            insertions = previous_row[j + 1] + 1
            deletions = current_row[j] + 1
            substitutions = previous_row[j] + (c1 != c2)
            current_row.append(min(insertions, deletions, substitutions))
        previous_row = current_row
    return previous_row[-1]

# ── Typo correction vocabulary ────────────────────────────────────────────────
# difflib.get_close_matches will correct "docter"→"doctor", "lawer"→"lawyer"
# etc. against this list. Keep it focused — too many words slow correction.
SEARCH_VOCABULARY = sorted({
    # Healthcare
    'doctor', 'physician', 'surgeon', 'specialist', 'dentist', 'dental',
    'nurse', 'pharmacist', 'physiotherapist', 'psychologist', 'therapist',
    'pediatrician', 'gynecologist', 'cardiologist', 'dermatologist',
    'ophthalmologist', 'neurologist', 'orthopedic', 'radiologist',
    # Legal
    'lawyer', 'attorney', 'advocate', 'solicitor', 'barrister',
    # Engineering
    'engineer', 'engineering', 'civil', 'electrical', 'mechanical',
    'software', 'chemical', 'structural',
    # Architecture
    'architect', 'architecture',
    # Trades
    'electrician', 'plumber', 'plumbing', 'mechanic', 'carpenter',
    'painter', 'welder', 'mason', 'driver', 'tailor', 'cleaner',
    'technician', 'handyman', 'barber',
    # Education
    'teacher', 'tutor', 'instructor', 'professor', 'lecturer',
    'trainer', 'coach', 'mentor', 'educator',
    # Finance
    'accountant', 'auditor', 'consultant', 'analyst', 'advisor',
    'bookkeeper', 'finance',
    # IT
    'developer', 'programmer', 'coder', 'designer', 'fullstack',
    'frontend', 'backend', 'devops', 'database',
    # Other professionals
    'photographer', 'videographer', 'chef', 'cook', 'caterer',
    'manager', 'supervisor', 'coordinator', 'administrator',
    'veterinarian', 'nutritionist', 'dietitian',
    'physiologist', 'pathologist', 'anesthesiologist',
})

# ── Abbreviation map ──────────────────────────────────────────────────────────
# "dr" → "doctor", "ca" → "accountant" etc.
ABBREVIATIONS = {
    'dr':    'doctor',
    'md':    'doctor',
    'mbbs':  'doctor',
    'ca':    'accountant',
    'cpa':   'accountant',
    'acca':  'accountant',
    'eng':   'engineer',
    'engg':  'engineer',
    'prof':  'professor',
    'dev':   'developer',
    'pt':    'physiotherapist',
    'rn':    'nurse',
    'adv':   'lawyer',
    'atty':  'lawyer',
    'arch':  'architect',
    'mech':  'mechanic',
    'elec':  'electrician',
    'pharm': 'pharmacist',
    'psych': 'psychologist',
    'vet':   'veterinarian',
    'dent':  'dentist',
    'tech':  'technician',
    'cs':    'developer',
    'it':    'developer',
}

# ── Canonical Profession to Category Pattern Mapping ──────────────────────────
# Used for strict category isolation. When a user searches for any profession,
# abbreviation, alias, or foreign term, it resolves to a canonical profession word,
# which then maps strictly to the corresponding database Category name patterns.
CANONICAL_TO_CATEGORY_PATTERNS = {
    # Healthcare & Doctors
    'doctor': ['doctor', 'healthcare', 'medical'],
    'physician': ['doctor', 'healthcare', 'medical'],
    'surgeon': ['doctor', 'healthcare', 'medical'],
    'dentist': ['doctor', 'healthcare', 'medical', 'dentist'],
    'nurse': ['doctor', 'healthcare', 'medical', 'nurse'],
    'pharmacist': ['doctor', 'healthcare', 'medical', 'pharm'],
    'physiotherapist': ['doctor', 'healthcare', 'medical', 'physio'],
    'psychologist': ['doctor', 'healthcare', 'medical', 'psych'],
    'cardiologist': ['doctor', 'healthcare', 'medical'],
    'dermatologist': ['doctor', 'healthcare', 'medical'],
    'pediatrician': ['doctor', 'healthcare', 'medical'],
    'gynecologist': ['doctor', 'healthcare', 'medical'],
    'ophthalmologist': ['doctor', 'healthcare', 'medical'],
    'neurologist': ['doctor', 'healthcare', 'medical'],
    'general practitioner': ['doctor', 'healthcare', 'medical'],
    'gp': ['doctor', 'healthcare', 'medical'],
    'veterinarian': ['doctor', 'healthcare', 'medical', 'vet'],

    # Legal
    'lawyer': ['lawyer', 'legal'],
    'attorney': ['lawyer', 'legal'],
    'advocate': ['lawyer', 'legal'],
    'solicitor': ['lawyer', 'legal'],
    'barrister': ['lawyer', 'legal'],
    'counsel': ['lawyer', 'legal'],

    # Engineering
    'engineer': ['engineer'],
    'civil engineer': ['engineer'],
    'mechanical engineer': ['engineer'],
    'chemical engineer': ['engineer'],
    'electrical engineer': ['engineer', 'electrician'],

    # IT & Tech
    'developer': ['it', 'tech'],
    'programmer': ['it', 'tech'],
    'coder': ['it', 'tech'],
    'software engineer': ['it', 'tech', 'engineer'],
    'web developer': ['it', 'tech'],
    'designer': ['it', 'tech'],
    'graphic designer': ['it', 'tech'],
    'it': ['it', 'tech'],
    'tech': ['it', 'tech'],

    # Tutors & Education
    'tutor': ['tutor', 'education', 'teacher'],
    'teacher': ['tutor', 'education', 'teacher'],
    'instructor': ['tutor', 'education', 'teacher'],
    'professor': ['tutor', 'education', 'teacher'],
    'educator': ['tutor', 'education', 'teacher'],
    'lecturer': ['tutor', 'education', 'teacher'],

    # Trades
    'plumber': ['plumber'],
    'plumbing': ['plumber'],
    'pipe fitter': ['plumber'],
    'pipe repair': ['plumber'],
    'electrician': ['electrician'],
    'electrical technician': ['electrician'],
    'wiring expert': ['electrician'],
    'architect': ['architect'],
    'architecture': ['architect'],
    'carpenter': ['carpenter'],
    'woodworker': ['carpenter'],
    'painter': ['painter'],
    'wall painter': ['painter'],
    'cleaner': ['cleaner'],
    'accountant': ['accountant', 'finance'],
    'auditor': ['accountant', 'finance'],
    'bookkeeper': ['accountant', 'finance'],
    'finance': ['accountant', 'finance'],
    'mechanic': ['mechanic'],
    'barber': ['barber'],
    'tailor': ['tailor'],
    'chef': ['chef', 'cook'],
    'photographer': ['photographer', 'photo'],
    'driver': ['driver'],
    'mason': ['mason'],
}


# ── Synonym groups ────────────────────────────────────────────────────────────
# Every word in a group maps to ALL other words in that group.
# Search "tutor"  → also searches "teacher", "instructor", "educator"
# Search "lawyer" → also searches "attorney", "advocate", "solicitor"
_SYNONYM_GROUPS = [
    # Education
    {'teacher', 'tutor', 'instructor', 'educator', 'lecturer', 'trainer', 'coach',
     'ustad', 'ustaad', 'sir', 'madam', 'muallim', 'استاد', 'ٹیوٹر'},
    # Legal
    {'lawyer', 'attorney', 'advocate', 'solicitor', 'barrister', 'counsel',
     'vakeel', 'wakeel', 'وکیل'},
    # Electrical
    {'electrician', 'electrical technician', 'electrical engineer', 'wiring expert',
     'bijli wala', 'bijli ka kaam', 'بجلی والا', 'الیکٹریشن'},
    # Plumbing
    {'plumber', 'pipe repair', 'pipe fitter', 'plumbing technician',
     'nalka wala', 'plumber wala', 'پلمبر'},
    # Medical
    {'doctor', 'physician', 'surgeon', 'medical officer', 'general practitioner', 'gp',
     'dactar', 'daktar', 'hakim', 'ڈاکٹر', 'حکیم'},
    # Finance
    {'accountant', 'auditor', 'chartered accountant', 'bookkeeper', 'cpa', 'finance expert',
     'munshi', 'حساب دان'},
    # IT
    {'developer', 'programmer', 'coder', 'software engineer', 'software developer'},
    # Cleaning
    {'cleaner', 'cleaning service', 'housekeeping', 'janitor', 'maid', 'sweeper',
     'safai wala', 'safai karne wala', 'صفائی والا'},
    # Design
    {'designer', 'graphic designer', 'ui designer', 'ux designer', 'visual designer'},
    # Mechanical
    {'mechanic', 'auto repair', 'car repair', 'vehicle technician',
     'mistri', 'gari ka mistri', 'مکینک', 'مستری'},
    # Healthcare support
    {'nurse', 'nursing', 'caregiver', 'healthcare worker', 'نرس'},
    {'physiotherapist', 'physical therapist', 'physio', 'rehabilitation specialist'},
    {'psychologist', 'therapist', 'counselor', 'mental health specialist'},
    {'dentist', 'dental surgeon', 'dental specialist', 'oral health doctor',
     'danton ka doctor', 'dant ka doctor', 'دانتوں کا ڈاکٹر'},
    {'pharmacist', 'pharmacy', 'drug specialist', 'dawai wala', 'دوائی والا'},
    {'veterinarian', 'vet', 'animal doctor', 'pet doctor'},
    # Construction
    {'architect', 'building designer', 'structural designer'},
    {'carpenter', 'woodworker', 'furniture maker', 'joiner', 'barhai', 'بڑھئی'},
    {'painter', 'wall painter', 'decorator', 'painting service',
     'rang saz', 'painter wala', 'رنگساز'},
    {'mason', 'bricklayer', 'construction worker', 'raj mistri', 'راج مستری'},
    # Other
    {'chef', 'cook', 'caterer', 'culinary expert', 'bawarchi', 'باورچی'},
    {'driver', 'chauffeur', 'cab driver', 'ڈرائیور'},
    {'photographer', 'photo service', 'photography'},
    {'tailor', 'stitching', 'alteration service', 'sewing', 'darzi', 'درزی'},
    # IT / device repair
    {'computer technician', 'laptop repair', 'pc technician', 'it technician', 'computer repair', 'laptop technician'},
    # Barber
    {'barber', 'hairdresser', 'hair stylist', 'salon', 'nai', 'حجام'},
]

# Build bidirectional lookup: word → frozenset of synonyms
SYNONYM_MAP: dict = {}
for group in _SYNONYM_GROUPS:
    for word in group:
        SYNONYM_MAP[word] = group - {word}  # all others in group

# Multi-word synonym keys (English phrases like "pipe repair", Roman Urdu
# phrases like "bijli wala", "danton ka doctor") need substring matching
# against the FULL sentence — a single split() word can never equal a
# multi-word dict key, so these would otherwise only match when the user's
# entire query was literally that exact phrase and nothing else.
_MULTI_WORD_SYNONYM_KEYS = [k for k in SYNONYM_MAP if ' ' in k]


# ── Problem / symptom → profession semantic map ──────────────────────────────
# "Heart pain" doesn't literally contain the word "cardiologist" — this is
# what lets search (and AI Search) understand MEANING instead of only
# matching literal profession keywords. Checked as a substring against the
# normalized query, so it fires from anywhere in a sentence
# ("I have bad heart pain, need help" still matches "heart pain").
PROBLEM_PROFESSION_MAP = {
    # Medical
    'heart pain':       'cardiologist',
    'chest pain':       'cardiologist',
    'heart attack':     'cardiologist',
    'high blood pressure': 'cardiologist',
    'tooth pain':       'dentist',
    'toothache':        'dentist',
    'tooth ache':       'dentist',
    'gum pain':         'dentist',
    'cavity':           'dentist',
    'back pain':        'physiotherapist',
    'joint pain':       'physiotherapist',
    'muscle pain':      'physiotherapist',
    'skin problem':     'dermatologist',
    'skin rash':        'dermatologist',
    'acne':             'dermatologist',
    'eye problem':      'ophthalmologist',
    'vision problem':   'ophthalmologist',
    'blurry vision':    'ophthalmologist',
    'fever':            'doctor',
    'headache':         'doctor',
    'stomach pain':     'doctor',
    'stomach ache':     'doctor',
    'cough':            'doctor',
    'pregnancy':        'gynecologist',
    'child not eating': 'pediatrician',
    'kid fever':        'pediatrician',
    'mental stress':    'psychologist',
    'anxiety':          'psychologist',
    'depression':       'psychologist',
    # Home / trades
    'pipe leak':        'plumber',
    'leaking pipe':     'plumber',
    'water leak':       'plumber',
    'leaking tap':      'plumber',
    'clogged drain':    'plumber',
    'blocked drain':    'plumber',
    'toilet leak':      'plumber',
    'house wiring':     'electrician',
    'wiring issue':     'electrician',
    'wiring problem':   'electrician',
    'power outage':     'electrician',
    'electrical fault':  'electrician',
    'short circuit':    'electrician',
    'no electricity':   'electrician',
    'fan not working':  'electrician',
    # Legal
    'legal notice':     'lawyer',
    'legal issue':      'lawyer',
    'legal problem':    'lawyer',
    'legal dispute':    'lawyer',
    'court case':       'lawyer',
    'property dispute': 'lawyer',
    'divorce case':     'lawyer',
    # Tech
    'broken laptop':    'computer technician',
    'laptop not working': 'computer technician',
    'laptop repair':    'computer technician',
    'computer not working': 'computer technician',
    'computer crashed': 'computer technician',
    'pc issue':         'computer technician',
    'screen broken':    'computer technician',
    'virus in laptop':  'computer technician',
}


# ── Multilingual query translation (English / Urdu / Roman Urdu / mixed) ────
# Runs on the RAW query text, before normalization. Translates known Roman
# Urdu and Urdu-script tokens to their English canonical equivalent, so
# "Mujhe tutor chahiye", "ڈاکٹر چاہیے", and "Need a doctor" all end up
# driving the exact same English vocabulary engine (SEARCH_VOCABULARY,
# SYNONYM_MAP, PROBLEM_PROFESSION_MAP, price/gender/urgency detection).
# Mixed-language queries ("Karachi me doctor") work automatically since
# untranslated English words just pass through unchanged.
_MULTILINGUAL_MAP = {
    # ── Professions — Roman Urdu ──
    'wakeel':   'lawyer',   'vakeel':  'lawyer',   'wakil':   'lawyer',   'vakil':  'lawyer',
    'ustaad':   'teacher',  'ustad':   'teacher',  'maulvi':  'teacher',  'shikshak': 'teacher',
    'daant':    'dentist',  'dant':    'dentist',
    'mistri':   'mechanic', 'mistari': 'mechanic',
    'nai':      'barber',   'hajam':   'barber',
    'darzi':    'tailor',
    'bijli wala': 'electrician', 'bijli mistri': 'electrician', 'bijli': 'electrician',
    'nalka wala': 'plumber',     'nalka': 'plumber', 'nalki': 'plumber',
    'rangsaz':  'painter',      'rang saz': 'painter',
    'daktar':   'doctor',       'daactar': 'doctor',

    # ── Professions — Urdu script ──
    'ڈاکٹر': 'doctor', 'وکیل': 'lawyer', 'استاد': 'teacher', 'ٹیوٹر': 'tutor',
    'دانتوں': 'dentist', 'انجینئر': 'engineer', 'الیکٹریشن': 'electrician',
    'پلمبر': 'plumber', 'درزی': 'tailor', 'مکینک': 'mechanic', 'نائی': 'barber',
    'بڑھئی': 'carpenter', 'رنگ ساز': 'painter', 'صفائی والا': 'cleaner',

    # ── Professions — Hindi Devanagari script ──
    'डॉक्टर': 'doctor', 'डाक्टर': 'doctor', 'चिकित्सक': 'doctor', 'डाकटर': 'doctor',
    'प्लंबर': 'plumber', 'प्लम्बर': 'plumber', 'नलसाज': 'plumber', 'नलसाज़': 'plumber', 'पलबर': 'plumber',
    'बिजली मिस्त्री': 'electrician', 'बिजलीमिस्त्री': 'electrician', 'बिजली वाला': 'electrician',
    'बिजलीवाला': 'electrician', 'इलेक्ट्रीशियन': 'electrician',
    'वकील': 'lawyer', 'अधिवक्ता': 'lawyer',
    'इंजीनियर': 'engineer', 'अभियंता': 'engineer',
    'शिक्षक': 'teacher', 'अध्यापक': 'teacher', 'अध्यापिका': 'teacher', 'टीचर': 'teacher',
    'ट्यूटर': 'tutor',
    'दंत चिकित्सक': 'dentist', 'दंतवैद्य': 'dentist', 'डेंटिस्ट': 'dentist',
    'दर्जी': 'tailor', 'दर्ज़ी': 'tailor',
    'नाई': 'barber', 'हज्जाम': 'barber',
    'मैकेनिक': 'mechanic', 'मिस्त्री': 'mechanic',
    'बढ़ई': 'carpenter',
    'पेंटर': 'painter', 'रंगसाज': 'painter',
    'अकाउंटेंट': 'accountant', 'मुंशी': 'accountant',
    'सफाईकर्मी': 'cleaner', 'सफाईवाला': 'cleaner', 'क्लीनर': 'cleaner',
    'ड्राइवर': 'driver', 'चालक': 'driver',
    'शेफ': 'chef', 'रसोइया': 'chef',

    # ── Filler / connector words — safe to drop or map to English glue ──
    'chahiye':  '', 'chahye': '', 'chaiye': '', 'chaheye': '',
    'mujhe':    '', 'mujhay': '',
    'mein':     'in', 'me': 'in', 'main': 'in', 'mn': 'in',
    'ka': '', 'ki': '', 'ke': '', 'kay': '', 'k': '', 'ko': '', 'se': '', 'say': '', 'sy': '',

    # Urdu filler
    'مجھے': '', 'چاہیے': '', 'میں': 'in',
    'کا': '', 'کی': '', 'کے': '', 'کو': '', 'سے': '',

    # Hindi filler
    'मुझे': '', 'मुझको': '', 'मझ': '',
    'चाहिए': '', 'चाहीये': '', 'चाहिये': '',
    'में': 'in', 'म': 'in', 'पे': 'at', 'पर': 'at',
    'का': '', 'की': '', 'के': '', 'क': '', 'को': '', 'से': '', 'स': '',
    'पास': 'near', 'नजदीक': 'near', 'मेरे पास': 'near me',

    # ── Budget / Price phrases ──
    # Roman Urdu
    'ke andar': 'under', 'ke ander': 'under', 'kay andar': 'under', 'kay ander': 'under',
    'k andar': 'under', 'k ander': 'under',
    'ander': 'under', 'andar': 'under',
    'se kam': 'under', 'say kam': 'under', 'sy kam': 'under',
    'se zyada': 'over', 'se ziada': 'over', 'say zyada': 'over', 'say ziada': 'over', 'se upar': 'over',
    'rupay': 'rs', 'rupaye': 'rs', 'rupees': 'rs', 'rupee': 'rs',
    'sasta': 'cheap', 'saste': 'cheap', 'sasti': 'cheap', 'arzan': 'cheap',
    'mehnga': 'expensive', 'mehngay': 'expensive', 'mehngi': 'expensive',

    # Urdu script
    'کے اندر': 'under', 'اندر': 'under', 'سے کم': 'under',
    'سے زیادہ': 'over', 'سے اوپر': 'over',
    'روپے': 'rs', 'روپیہ': 'rs',
    'سستا': 'cheap', 'مہنگا': 'expensive',

    # Hindi Devanagari script
    'के अंदर': 'under', 'के अन्दर': 'under', 'क अदर': 'under',
    'अंदर': 'under', 'अन्दर': 'under', 'अदर': 'under',
    'से कम': 'under', 'स कम': 'under',
    'से ज्यादा': 'over', 'से अधिक': 'over', 'से ऊपर': 'over',
    'रुपये': 'rs', 'रुपए': 'rs', 'रुपया': 'rs', 'रु': 'rs',
    'सस्ता': 'cheap', 'सस्ते': 'cheap', 'sasti': 'cheap',
    'महंगा': 'expensive', 'महंगे': 'expensive', 'महंगी': 'expensive',

    # ── Gender ──
    'aurat': 'female', 'khatoon': 'female', 'larki': 'female', 'ladki': 'female',
    'mard': 'male', 'aadmi': 'male', 'larka': 'male', 'ladka': 'male',
    'عورت': 'female', 'خاتون': 'female', 'مرد': 'male',
    'महिला': 'female', 'औरत': 'female', 'लड़की': 'female',
    'पुरुष': 'male', 'आदमी': 'male', 'लड़का': 'male',

    # ── Urgency ──
    'abhi': 'now', 'foran': 'immediately', 'jaldi': 'urgent',
    'ابھی': 'now', 'فوراً': 'immediately',
    'अभी': 'now', 'तुरंत': 'immediately', 'जल्दी': 'urgent',
    'aaj': 'today', 'آج': 'today', 'आज': 'today',
}

# ── Query filler words ────────────────────────────────────────────────────────
_QUERY_FILLER_WORDS = {
    'wala', 'wali', 'wale', 'walay', 'walon',
    'in', 'at', 'near', 'nearby', 'me', 'my', 'i', 'a', 'an', 'the', 'for', 'to',
    'of', 'and', 'or', 'with', 'who', 'is', 'are', 'am', 'need', 'needs', 'want',
    'wants', 'looking', 'look', 'find', 'show', 'get', 'give', 'please', 'plz',
    'someone', 'somebody', 'any', 'best', 'top', 'good', 'great', 'cheap',
    'expensive', 'affordable', 'speaking', 'speaker', 'available', 'professional',
    'professionals', 'rs', 'pkr', 'usd', 'rupees', 'dollar', 'dollars', 'k',
    # Roman Urdu filler & glue
    'chahiye', 'chahye', 'chaiye', 'chaheye', 'mujhe', 'mujhay',
    'ka', 'ki', 'ke', 'kay', 'k', 'ko', 'se', 'say', 'sy', 'mein', 'main', 'mn',
    'ander', 'andar', 'kam', 'rupay', 'rupaye', 'rupe', 'tak',
    # Hindi filler & glue
    'मुझे', 'चाहिए', 'चाहीये', 'चाहिये', 'की', 'के', 'का', 'को', 'में', 'से', 'पर',
    'वाला', 'वाली', 'वाले', 'अंदर', 'अन्दर', 'अदर', 'रुपये', 'रुपए', 'तक', 'कम',
    'मझ', 'क', 'स', 'म', 'पे',
    # Urdu filler & glue
    'چاہیے', 'مجھے', 'کی', 'کے', 'کا', 'کو', 'میں', 'سے', 'پر', 'والا', 'والی', 'والے',
    'اندر', 'روپے', 'تک',
}


def _translate_multilingual(text: str) -> str:
    """Roman Urdu / Urdu-script tokens → English, word/phrase-boundary safe."""
    if not text:
        return text
    result = text
    # 0. Translate city names across scripts (Urdu, Hindi, Arabic, etc.)
    result = _translate_cities(result)
    # Longer phrases first so multi-word keys aren't shadowed by single-word ones
    for src in sorted(_MULTILINGUAL_MAP, key=len, reverse=True):
        dst = _MULTILINGUAL_MAP[src]
        result = re.sub(r'(?<!\S)' + re.escape(src) + r'(?!\S)', dst, result, flags=re.IGNORECASE)

    # Language-independent pass (apps/search/aliases.py): multi-word aliases,
    # then any remaining word whose phonetic key matches a known profession
    # alias in ANY script/spelling (wakeel / vakeel / wkil / وکیل / वकील -> lawyer).
    result = _alias_phrases(result)
    known = set(SEARCH_VOCABULARY) | set(_QUERY_FILLER_WORDS) | set(_CITY_CENTROIDS)
    return ' '.join(_alias_lookup(tok, known) or tok for tok in result.split())


# ══════════════════════════════════════════════════════════════════════════
# Intent extraction — Gender / Availability-urgency / Language / Experience
# ══════════════════════════════════════════════════════════════════════════
# These are the intent fields the spec calls out (point 2/3: "Extract Gender,
# Experience, Availability, Language...") that were previously only mapped
# to English words (via _MULTILINGUAL_MAP) but never turned into an actual
# filter. Runs on the ALREADY-multilingual-translated + normalized text, so
# "female dentist", "khatoon dentist", and "خاتون dentist" all hit the same
# word set below.

GENDER_INTENT_WORDS = {
    'female': {'female', 'woman', 'women', 'girl', 'lady'},
    'male':   {'male', 'man', 'men', 'boy'},
}

URGENCY_INTENT_WORDS = {'now', 'urgent', 'immediately', 'today', 'asap'}

EXPERIENCE_INTENT_WORDS = {
    'experienced': 5, 'senior': 5, 'expert': 7, 'veteran': 8,
}

# Free-text `languages` field on ProfessionalProfile is comma-separated
# (e.g. "Urdu, English, Sindhi") — icontains match against these names.
LANGUAGE_INTENT_WORDS = {
    'english', 'urdu', 'sindhi', 'punjabi', 'pashto', 'balochi',
    'arabic', 'hindi', 'chinese', 'french',
}

# Free-text `services` field on ProfessionalProfile (e.g. "Home visits,
# Online consult") — matched via icontains against these keyword groups.
SERVICE_MODE_KEYWORDS = {
    'online':     {'online', 'video call', 'video consult', 'remote', 'virtual'},
    'home_visit': {'home visit', 'home service', 'house call', 'at home'},
    'in_office':  {'in office', 'office visit', 'clinic visit', 'walk in', 'in person'},
}

# "near me" / "nearby" style phrases → default search radius (km) when no
# explicit max_distance param is given. Checked as substrings so they fire
# from anywhere in the sentence ("find a plumber near me right now").
NEARBY_PHRASE_RADIUS_KM = {
    'near me': 15, 'nearby': 15, 'close by': 15, 'walking distance': 3,
}


# ── Numeric price phrases ─────────────────────────────────────────────────
# "under 100", "under $100", "below 200", "less than 500", "max 1000",
# "upto 300", "up to 300", "within 100", "500 under", "500 ke ander",
# "500 ke andar", "500 se kam", "500 rupay ke andar", "500 के अंदर" → a MAX price ceiling.
# "above 500", "over 1000", "more than 200", "min 100", "at least 300",
# "500 se zyada", "500 से ज्यादा" → a MIN price floor.
_CURRENCY = r'(?:rs\.?|pkr|\$|rupaye?|rupees?|rupe|روپے|روپئے|रुपये|रुपए|रु)'
_PRICE_NUMBER = rf'(?:{_CURRENCY}\s*)?([\d,]+)\s*(k)?(?:\s*{_CURRENCY})?'

_MAX_PRICE_PATTERNS = [
    # Prefix: keyword before price
    r'\b(?:under|below|less than|max(?:imum)?|up ?to|within|cheaper than)\s*' + _PRICE_NUMBER,
    r'\b(?:ke\s*and[ae]r|kay\s*and[ae]r|k\s*and[ae]r|and[ae]r|se\s*kam|say\s*kam|sy\s*kam)\s*' + _PRICE_NUMBER,
    r'(?:के\s*अं?द[रा]|के\s*अन्दर|अं?द[रा]|अन्दर|से\s*कम|क\s*अदर|अदर|स\s*कम)\s*' + _PRICE_NUMBER,
    r'(?:کے\s*اندر|اندر|سے\s*کم)\s*' + _PRICE_NUMBER,

    # Suffix: price before keyword
    _PRICE_NUMBER + r'\s*(?:under|below|less than|max(?:imum)?|or less|and under)\b',
    _PRICE_NUMBER + r'\s*(?:ke\s*and[ae]r|kay\s*and[ae]r|k\s*and[ae]r|and[ae]r|se\s*kam|say\s*kam|sy\s*kam|tak)\b',
    _PRICE_NUMBER + r'\s*(?:के\s*अं?द[रा]|के\s*अन्दर|अं?द[रा]|अन्दर|से\s*कम|तक|क\s*अदर|अदर|स\s*कम)\b',
    _PRICE_NUMBER + r'\s*(?:کے\s*اندر|اندر|سے\s*کم|تک)\b',
]

_MIN_PRICE_PATTERNS = [
    # Prefix: keyword before price
    r'\b(?:above|over|more than|min(?:imum)?|at least|starting from)\s*' + _PRICE_NUMBER,
    r'\b(?:se\s*z[iy]ada|say\s*z[iy]ada|sy\s*z[iy]ada|se\s*upar|say\s*upar)\s*' + _PRICE_NUMBER,
    r'(?:से\s*ज्यादा|से\s*अधिक|से\s*ऊपर|स\s*ज्यादा)\s*' + _PRICE_NUMBER,
    r'(?:سے\s*زیادہ|سے\s*اوپر)\s*' + _PRICE_NUMBER,

    # Suffix: price before keyword
    _PRICE_NUMBER + r'\s*(?:above|over|min(?:imum)?|or more|and above|plus|\+)\b',
    _PRICE_NUMBER + r'\s*(?:se\s*z[iy]ada|say\s*z[iy]ada|sy\s*z[iy]ada|se\s*upar|say\s*upar|se\s*barh\s*kar)\b',
    _PRICE_NUMBER + r'\s*(?:से\s*ज्यादा|से\s*अधिक|से\s*ऊपर)\b',
    _PRICE_NUMBER + r'\s*(?:سے\s*زیادہ|سے\s*اوپر)\b',
]


def _parse_price_number(match) -> float:
    num = float(match.group(1).replace(',', ''))
    if match.group(2):  # "k" shorthand
        num *= 1000
    return num


def _extract_price_filter(term: str) -> dict:
    """
    Best-effort numeric budget detection from free text.
    Returns only the keys actually detected: {'max_price': ...} and/or
    {'min_price': ...} — missing keys mean "not specified".

    "dr under 100$"         → {'max_price': 100.0}
    "500 ke ander doctor"   → {'max_price': 500.0}
    "plumber over 2k"       → {'min_price': 2000.0}
    """
    if not term:
        return {}

    intent = {}
    for pattern in _MAX_PRICE_PATTERNS:
        m = re.search(pattern, term, flags=re.IGNORECASE)
        if m:
            intent['max_price'] = _parse_price_number(m)
            break

    for pattern in _MIN_PRICE_PATTERNS:
        m = re.search(pattern, term, flags=re.IGNORECASE)
        if m:
            intent['min_price'] = _parse_price_number(m)
            break

    return intent


# ── City-in-free-text detection ──────────────────────────────────────────
# "badin mn dr", "dr in karachi", "plumber near sanghar" — the city name is
# often just typed as part of the search sentence rather than picked from a
# separate city dropdown. Without this, the city word gets diluted into the
# big OR-across-every-field keyword match (`_multi_field_qs`) and never
# actually narrows results to that city — matched professions from anywhere
# in the country slip through. Longest names checked first so multi-word
# cities ("tando allahyar") aren't shadowed by a shorter city sharing a
# prefix.
def _find_city_in_text(term: str) -> tuple:
    """
    Returns (city, matched_tokens). Exact match first (longest name wins), then
    a fuzzy pass so a typo'd city ("lahor", "karchi", "hyderbad") still narrows
    to that city instead of being silently ignored.
    """
    if not term:
        return '', set()

    # 1. Multi-script city aliases (e.g. کراچی, करांची, etc.)
    for alias, canon in sorted(CITY_ALIASES.items(), key=lambda x: len(x[0]), reverse=True):
        if re.search(r'(?<!\S)' + re.escape(alias) + r'(?!\S)', term, flags=re.IGNORECASE):
            return canon, set(alias.split())

    # 2. Canonical centroid names
    for city in sorted(_CITY_CENTROIDS, key=len, reverse=True):
        if re.search(r'(?<!\S)' + re.escape(city) + r'(?!\S)', term, flags=re.IGNORECASE):
            return city, set(city.split())

    # Fuzzy pass — single-word cities only, and never on words that are
    # already known profession words / typos of them ("plumer" is not a city).
    known = set(SEARCH_VOCABULARY) | set(SYNONYM_MAP) | set(ABBREVIATIONS) | _QUERY_FILLER_WORDS
    single_word_cities = [c for c in _CITY_CENTROIDS if ' ' not in c]
    for w in term.split():
        if len(w) < 4 or w in known or w.isdigit():
            continue
        if get_close_matches(w, SEARCH_VOCABULARY, n=1, cutoff=0.72):
            continue
        m = get_close_matches(w, single_word_cities, n=1, cutoff=0.8)
        if m:
            return m[0], {w}
    return '', set()


def _extract_city_from_text(term: str) -> str:
    return _find_city_in_text(term)[0]


def _extract_intent_filters(normalized_term: str) -> dict:
    """
    Best-effort intent detection from free text. Returns only the keys that
    were actually detected — callers should treat missing keys as "not
    specified" and fall back to explicit query params / no filter.

    'Need female dentist urgent, urdu speaking, near me' →
        {'gender': 'female', 'urgent': True, 'language': 'urdu', 'max_distance': 15}
    """
    if not normalized_term:
        return {}

    words = set(normalized_term.split())
    intent = {}

    for gender, triggers in GENDER_INTENT_WORDS.items():
        if words & triggers:
            intent['gender'] = gender
            break

    if words & URGENCY_INTENT_WORDS:
        intent['urgent'] = True

    for word, years in EXPERIENCE_INTENT_WORDS.items():
        if word in words:
            intent['min_experience'] = years
            break

    detected_lang = words & LANGUAGE_INTENT_WORDS
    if detected_lang:
        intent['language'] = sorted(detected_lang)[0]

    # Multi-word phrases → substring check against the full sentence
    # (a single split() word can never equal "home visit" etc).
    for mode, phrases in SERVICE_MODE_KEYWORDS.items():
        if any(p in normalized_term for p in phrases):
            intent['service_mode'] = mode
            break

    for phrase, radius in NEARBY_PHRASE_RADIUS_KM.items():
        if phrase in normalized_term:
            intent['max_distance'] = radius
            break

    return intent


# ── Text normalizer ───────────────────────────────────────────────────────────
# lowercase + remove accents + strip special chars (punctuation)
def _normalize(text: str) -> str:
    text = unicodedata.normalize('NFD', text)
    text = ''.join(c for c in text if unicodedata.category(c) != 'Mn')
    # keep letters, digits and spacing marks (Devanagari matras); `\w` would
    # wrongly split Hindi words at every vowel sign
    text = ''.join(c if unicodedata.category(c)[0] in 'LNM' else ' ' for c in text.lower())
    return ' '.join(text.split())


# ── Core query extraction ────────────────────────────────────────────────────
# ROOT-CAUSE FIX: a sentence like "female doctor", "doctor lahore", "bijli wala"
# or "cheap plumber near me" used to be searched as ONE literal phrase (plus
# synonyms of the individual words) — the bare word "doctor" was never added to
# the search terms, so multi-word queries returned 0 results even though the
# same profession worked fine as a single word. Here we strip everything that is
# already handled as a FILTER (city, gender, price, urgency, language, distance,
# service-mode, experience) or is just sentence filler, so only the actual
# profession/skill words are text-matched.
def _resolve_category_ids(term: str, categories_cache=None) -> tuple:
    """
    Given a query word or phrase, checks if it corresponds to an unambiguous
    profession or category.
    Returns (canonical_profession_or_none, list_of_category_ids).
    """
    if not term:
        return None, []

    term_norm = _normalize(term).strip()
    if not term_norm:
        return None, []

    # 1. Abbreviation check ('dr' -> 'doctor', 'eng' -> 'engineer', 'ca' -> 'accountant', etc.)
    canon = ABBREVIATIONS.get(term_norm)

    # 2. Multi-word phrase translation ('nalka wala' -> 'plumber', etc.)
    if not canon:
        translated_phrase = _alias_phrases(term)
        if translated_phrase != term:
            canon = _normalize(translated_phrase)

    # 3. Multilingual alias lookup ('wakeel' -> 'lawyer', 'daktar' -> 'doctor', etc.)
    if not canon:
        canon = _alias_lookup(term)

    # 4. Canonical category pattern direct lookup
    if not canon and term_norm in CANONICAL_TO_CATEGORY_PATTERNS:
        canon = term_norm

    # 5. Semantic problem/symptom map ('heart pain' -> 'cardiologist' -> doctor)
    if not canon and term_norm in PROBLEM_PROFESSION_MAP:
        canon = PROBLEM_PROFESSION_MAP[term_norm]

    # 6. Check if term directly matches a Category in DB
    if categories_cache is None:
        try:
            categories_cache = list(Category.objects.all().values('id', 'name'))
        except Exception:
            categories_cache = []

    matched_ids = []
    # If term directly matches category name (e.g. "Doctors & Healthcare", "Plumbers")
    for cat in categories_cache:
        c_name_norm = _normalize(cat['name'])
        if term_norm == c_name_norm or term_norm in c_name_norm.split():
            matched_ids.append(cat['id'])
            if not canon:
                canon = term_norm

    # If canonical was found, match patterns against Category names in DB
    if canon:
        patterns = CANONICAL_TO_CATEGORY_PATTERNS.get(canon, [canon])
        for cat in categories_cache:
            c_name_norm = _normalize(cat['name'])
            if any(p in c_name_norm for p in patterns):
                if cat['id'] not in matched_ids:
                    matched_ids.append(cat['id'])

    return canon, matched_ids


def _classify_search_query(term: str, raw_query: str = '', city_param: str = '', category_id_param=None) -> dict:
    """
    Comprehensive query disambiguation engine.
    Differentiates between:
    - category_only (e.g. 'doctor', 'plumber', 'dr', 'wakeel')
    - name_only (e.g. 'Amber', 'Ali', 'Faisal Shaikh')
    - combined_category_name (e.g. 'Amber doctor', 'Amber tutor')
    - combined_category_city (e.g. 'doctor in Badin', 'plumber Karachi')
    - combined_name_city (e.g. 'Amber in Islamabad')
    - city_only (e.g. 'Badin')
    - general (specialization, skills, etc.)
    """
    categories_cache = []
    try:
        categories_cache = list(Category.objects.all().values('id', 'name'))
    except Exception:
        pass

    target_category_ids = []
    canonical_profession = None
    if category_id_param:
        try:
            target_category_ids = [int(category_id_param)]
        except (ValueError, TypeError):
            pass

    # Detect city
    detected_city = city_param or _extract_city_from_text(term) or _extract_city_from_text(raw_query)

    # Core query without city tokens
    _city_found, _city_tokens = _find_city_in_text(term) if term else ('', set())
    core_text, ignored_words = _core_query(term, _city_tokens) if term else ('', set())

    # Pre-clean filler
    filler = set(_QUERY_FILLER_WORDS) | {'chahiye', 'need', 'want', 'wala', 'wali', 'walay', 'expert', 'services'}
    words = [w for w in core_text.split() if w not in filler and not w.isdigit()]

    # 1. Check if the whole core_text is an unambiguous category/profession
    if core_text:
        c_canon, c_ids = _resolve_category_ids(core_text, categories_cache)
        if c_ids:
            if not target_category_ids:
                target_category_ids = c_ids
            canonical_profession = c_canon
            q_type = 'combined_category_city' if detected_city else 'category_only'
            return {
                'query_type': q_type,
                'canonical_profession': canonical_profession,
                'strict_category_ids': target_category_ids,
                'name_query': None,
                'detected_city': detected_city,
                'is_category_search': True,
                'is_name_search': False,
                'core_text': core_text,
            }

    # 2. Check if query is a combination of Category + Name / Other words
    prof_words = []
    other_words = []
    for w in words:
        w_canon, w_ids = _resolve_category_ids(w, categories_cache)
        if w_ids:
            prof_words.append((w, w_canon, w_ids))
        else:
            other_words.append(w)

    if prof_words:
        canonical_profession = prof_words[0][1]
        if not target_category_ids:
            target_category_ids = prof_words[0][2]

        if other_words:
            name_query = ' '.join(other_words)
            q_type = 'combined_category_name'
            return {
                'query_type': q_type,
                'canonical_profession': canonical_profession,
                'strict_category_ids': target_category_ids,
                'name_query': name_query,
                'detected_city': detected_city,
                'is_category_search': True,
                'is_name_search': True,
                'core_text': core_text,
            }
        else:
            q_type = 'combined_category_city' if detected_city else 'category_only'
            return {
                'query_type': q_type,
                'canonical_profession': canonical_profession,
                'strict_category_ids': target_category_ids,
                'name_query': None,
                'detected_city': detected_city,
                'is_category_search': True,
                'is_name_search': False,
                'core_text': core_text,
            }

    # 3. No category word detected: Is it a Name query or City only?
    if not words and detected_city:
        return {
            'query_type': 'city_only',
            'canonical_profession': None,
            'strict_category_ids': target_category_ids,
            'name_query': None,
            'detected_city': detected_city,
            'is_category_search': bool(target_category_ids),
            'is_name_search': False,
            'core_text': '',
        }

    # Check if words match professional names in DB
    name_query = ' '.join(words) if words else core_text
    is_name = False
    if name_query:
        try:
            from django.db.models import Q as DQ
            if User.objects.filter(role='professional').filter(DQ(name__icontains=name_query) | DQ(name__istartswith=name_query)).exists():
                is_name = True
            else:
                known_names = cache.get('search_known_name_tokens')
                if known_names:
                    for w in words:
                        if len(w) >= 4 and get_close_matches(w, known_names, n=1, cutoff=0.80):
                            is_name = True
                            break
        except Exception:
            pass

    q_type = 'combined_name_city' if (is_name and detected_city) else ('name_only' if is_name else 'general')
    return {
        'query_type': q_type,
        'canonical_profession': None,
        'strict_category_ids': target_category_ids,
        'name_query': name_query if is_name else None,
        'detected_city': detected_city,
        'is_category_search': bool(target_category_ids),
        'is_name_search': is_name,
        'core_text': core_text,
    }


def _core_query(term: str, city_tokens=None) -> tuple:
    """
    "female doctor in lahore under 2000" → ("doctor", {"female","in","lahore","under","2000"})
    Returns (core_term, ignored_words). If stripping would leave nothing
    (e.g. the query IS just "lahore" or "female"), the original term is
    returned so single-word searches keep working exactly as before.
    """
    if not term:
        return term, set()

    text = f' {term} '
    for pattern in _MAX_PRICE_PATTERNS + _MIN_PRICE_PATTERNS:
        text = re.sub(pattern, ' ', text, flags=re.IGNORECASE)

    phrases = list(NEARBY_PHRASE_RADIUS_KM)
    for phrase_set in SERVICE_MODE_KEYWORDS.values():
        phrases.extend(phrase_set)
    for phrase in sorted(phrases, key=len, reverse=True):
        text = text.replace(f' {phrase} ', ' ')

    drop = set(_QUERY_FILLER_WORDS) | set(city_tokens or ())
    for words in GENDER_INTENT_WORDS.values():
        drop |= words
    drop |= URGENCY_INTENT_WORDS
    drop |= LANGUAGE_INTENT_WORDS
    if not any(k in term for k in _MULTI_WORD_SYNONYM_KEYS):
        drop |= set(EXPERIENCE_INTENT_WORDS)

    kept = [w for w in text.split() if w not in drop and not w.isdigit()]
    ignored = set(term.split()) - set(kept)
    if not kept:
        filter_words = ignored - _QUERY_FILLER_WORDS
        return ('', ignored) if filter_words else (term, set())
    return ' '.join(kept), ignored


# ── Typo corrector (Conservative & Length-Aware) ──────────────────────────────
# 1. Length < 4: NEVER corrected (leaves short names, abbreviations intact).
# 2. Length 4-5: cutoff=0.80, max Levenshtein edit distance = 1.
# 3. Length 6+: cutoff=0.75, max Levenshtein edit distance = 2.
# 4. Exact matches on names or professions ALWAYS take precedence.
def _correct_typo(term: str, skip_words=None, extra_vocab=None) -> tuple:
    skip_words = set(skip_words or ())
    words = term.split()
    corrected = []
    any_fixed = False

    vocab = SEARCH_VOCABULARY
    if extra_vocab:
        vocab = sorted(set(vocab) | {w.lower() for w in extra_vocab if w})

    for word in words:
        w_low = word.lower()
        if len(w_low) < 4 or w_low in skip_words or w_low in ABBREVIATIONS:
            corrected.append(word)
            continue

        if w_low in vocab:
            corrected.append(word)
            continue

        cutoff = 0.80 if len(w_low) <= 5 else 0.75
        max_dist = 1 if len(w_low) <= 6 else 2

        matches = get_close_matches(w_low, vocab, n=6, cutoff=cutoff)
        valid_matches = []
        for m in matches:
            dist = _levenshtein_distance(w_low, m)
            if dist <= max_dist:
                valid_matches.append((dist, abs(len(w_low) - len(m)), m))

        if valid_matches:
            valid_matches.sort(key=lambda x: (x[0], x[1]))
            best_match = valid_matches[0][2]
            if best_match != w_low:
                corrected.append(best_match)
                any_fixed = True
                continue

        corrected.append(word)

    return ' '.join(corrected), any_fixed


# ── Query expander ────────────────────────────────────────────────────────────
# Takes a normalized, typo-corrected term and returns ALL terms that should
# be searched — original + abbreviation expansion + all synonyms.
#
# "dr"      → ["dr", "doctor", "physician", "surgeon", ...]
# "tutor"   → ["tutor", "teacher", "instructor", "educator", ...]
# "plumer"  → corrected to "plumber" → ["plumber", "pipe repair", ...]
# "ca"      → ["ca", "accountant", "auditor", "bookkeeper", ...]
def _expand_query(term: str, split_words: bool = True) -> list:
    expanded = {term}

    # 0. Problem/symptom → profession (semantic meaning, not literal keywords)
    #    "heart pain" → cardiologist (+ cardiologist's own synonyms)
    for phrase, profession in PROBLEM_PROFESSION_MAP.items():
        if phrase in term:
            expanded.add(profession)
            if profession in SYNONYM_MAP:
                expanded.update(SYNONYM_MAP[profession])

    for word in term.split():
        # 1. Abbreviation expansion
        if word in ABBREVIATIONS:
            expanded.add(ABBREVIATIONS[word])
            word = ABBREVIATIONS[word]   # use expanded form for synonym lookup

        # 2. Synonym expansion (full term and per-word)
        if word in SYNONYM_MAP:
            expanded.update(SYNONYM_MAP[word])

    # 2.5 Multi-word phrase synonyms — "bijli wala", "pipe repair" etc. —
    #     checked as substrings so they fire from anywhere in a sentence
    #     ("Mujhe bijli wala chahiye"), not only as the entire query.
    for phrase in _MULTI_WORD_SYNONYM_KEYS:
        if phrase in term:
            expanded.update(SYNONYM_MAP[phrase])

    # Also try full term in synonym map (e.g. "pipe repair" is a full key)
    if term in SYNONYM_MAP:
        expanded.update(SYNONYM_MAP[term])

    # 3. Each meaningful word on its own. Without this a multi-word query like
    #    "python developer" only searched the literal phrase, so "developer"
    #    (or "doctor" in "doctor lahore") was never matched by itself.
    words = term.split()
    if split_words and len(words) > 1:
        for w in words:
            if len(w) >= 3 and w not in _QUERY_FILLER_WORDS:
                expanded.add(w)

    return list(expanded)


# Accepts a LIST of terms — original + typo-corrected are passed together.
# All terms are OR-combined so "docter" AND "doctor" both produce candidates.
# icontains handles: contains / partial / prefix / suffix automatically.
#   "doc"    → icontains matches "doctor" (prefix ✅)
#   "yer"    → icontains matches "lawyer" (suffix ✅)
#   "plumb"  → icontains matches "plumber" (partial ✅)
#   "doctor" → icontains matches "doctor" (exact ✅)
def _multi_field_qs(qs, terms: list, fuzzy_tokens=None, is_name_search: bool = False, is_category_search: bool = False):
    from django.db.models import Q

    if is_name_search:
        name_q = Q()
        for t in terms:
            t = str(t).strip()
            if not t:
                continue
            if len(t) <= 2:
                name_q |= (
                    Q(name__istartswith=t) |
                    Q(name__icontains=f' {t}')
                )
            else:
                name_q |= (
                    Q(name__iexact=t) |
                    Q(name__istartswith=t) |
                    Q(name__icontains=t)
                )
        if fuzzy_tokens and any(len(lat) >= 3 for lat, _ in fuzzy_tokens):
            name_q |= _fz_q(fuzzy_tokens)
        return qs.filter(name_q).distinct()

    combined = Q()
    for t in terms:
        t = str(t).strip()
        if not t:
            continue
        if len(t) <= 2:
            combined |= (
                Q(name__istartswith=t) |
                Q(name__icontains=f' {t}') |
                Q(professionalprofile__category__name__istartswith=t)
            )
        else:
            combined |= (
                Q(name__icontains=t)                                       |
                Q(professionalprofile__category__name__icontains=t)        |
                Q(professionalprofile__specialization__icontains=t)        |
                Q(professionalprofile__skills__icontains=t)                |
                Q(professionalprofile__company_name__icontains=t)          |
                Q(professionalprofile__bio__icontains=t)                   |
                Q(professionalprofile__services__icontains=t)              |
                Q(professionalprofile__tags__icontains=t)                  |
                Q(userprofile__city__icontains=t)                          |
                Q(userprofile__area__icontains=t)                          |
                Q(userprofile__country__icontains=t)
            )
    if fuzzy_tokens and any(len(lat) >= 3 for lat, _ in fuzzy_tokens):
        combined |= _fz_q(fuzzy_tokens)
    return qs.filter(combined).distinct()


# ── Relevance scorer ──────────────────────────────────────────────────────────
# Returns a float score — higher = more relevant.
# Weights reflect how "precise" a match field is:
#   Category/Profession > Name > Specialization > Skills > City > Bio/Tags
def _profile_completeness(user) -> float:
    """
    Returns 0.0–1.0 — how complete a professional's profile is.
    10 fields × 10% each = 100% max.
    Used as ranking signal (Priority 9).
    """
    try:
        prof = user.professionalprofile
        up   = user.userprofile
        checks = [
            bool(prof.photo_url),
            bool(prof.bio        and len(prof.bio) > 30),
            bool(prof.specialization),
            bool(prof.skills),
            bool(prof.services),
            bool(prof.tags),
            bool(up.city),
            bool(prof.experience_years > 0),
            bool(float(prof.hourly_rate) > 0),
            bool(prof.company_name),
        ]
        return sum(checks) / len(checks)
    except Exception:
        return 0.0


def _relevance_score(user, terms, customer_lat=None, customer_lng=None, fuzzy_tokens=None, is_premium=None, target_category_ids=None, is_name_search=False) -> float:
    """
    Transparent, maintainable relevance scoring:
    1. Strict category isolation: if target_category_ids is provided, professionals
       outside that category receive 0.0 immediately.
    2. Strict name isolation: if is_name_search is True, professionals whose names
       do not match receive 0.0 immediately.
    3. Exact full-name match (200 pts)
    4. Exact normalized name or alias match (180 pts)
    5. Strong prefix and partial-name match (140-160 pts)
    6. Profession/category match (130-150 pts)
    7. Specialization match (110-130 pts)
    8. Strong fuzzy name match (70-130 pts)
    9. City/location match (50-70 pts)
    10. Secondary fields: skills, services, tags, company, bio (15-40 pts)
    
    CRITICAL INVARIANT:
    Secondary factors (rating, availability, distance, verification) are strictly
    bounded tie-breakers (max ~25 pts total) and are ONLY awarded when
    there is a legitimate match (text_match_score > 0). If text_match_score == 0,
    the score is 0.0 (irrelevant results cannot receive bonuses).
    """
    try:
        prof = user.professionalprofile
        up   = user.userprofile
    except Exception:
        return 0.0

    # 1. Strict Category Isolation: If search has target categories,
    # any professional outside those categories is strictly 0.0!
    if target_category_ids:
        prof_cat_id = getattr(prof, 'category_id', None)
        if prof_cat_id not in target_category_ids:
            return 0.0

    name    = _normalize(user.name or '')
    cat     = _normalize(prof.category.name if prof.category else '')
    spec    = _normalize(prof.specialization or '')
    skills  = _normalize(prof.skills or '')
    co      = _normalize(prof.company_name or '')
    bio     = _normalize(prof.bio or '')
    svc     = _normalize(prof.services or '')
    tags    = _normalize(prof.tags or '')
    city    = _normalize(up.city or '')
    area    = _normalize(up.area or '')
    country = _normalize(up.country or '')

    term_list = [terms] if isinstance(terms, str) else list(terms or [])
    term_list = [t for t in term_list if t]
    if not term_list and not fuzzy_tokens:
        return 50.0  # browsing fallback when no search terms provided

    def _match(field: str, exact: float, starts: float, contains: float, min_len: int = 1) -> float:
        if not field or not term_list:
            return 0.0
        best = 0.0
        for t in term_list:
            if len(t) < min_len:
                continue
            if field == t:
                best = max(best, exact)
                continue
            if field.startswith(t):
                best = max(best, starts)
                continue
            words = field.split()
            if any(w == t for w in words):
                best = max(best, exact * 0.85)
                continue
            if any(w.startswith(t) for w in words):
                best = max(best, starts * 0.75)
                continue
            if ' ' in field and f' {t}' in f' {field}':
                best = max(best, contains)
                continue
            if len(t) >= 4 and any(w.startswith(t) or (len(w) >= len(t) + 4 and t in w) for w in words):
                best = max(best, contains * 0.5)
                continue
        return best

    # 1. Exact Name & Prefix Name
    name_score = _match(name, exact=200, starts=160, contains=120)

    # 2. Strong fuzzy name match (only fills gaps the exact matcher left)
    fuzzy_name_score = 0.0
    fuzzy_other_score = 0.0
    if fuzzy_tokens:
        try:
            _nb, _ob = _fuzzy_bonus(getattr(user, 'search_index', None), fuzzy_tokens)
            fuzzy_name_score = _nb
            fuzzy_other_score = _ob
        except Exception:
            fuzzy_name_score = 0.0
            fuzzy_other_score = 0.0

    effective_name_score = name_score
    if fuzzy_name_score > 0:
        effective_name_score = max(name_score, fuzzy_name_score)

    # Strict Name Isolation: If this is a Name search, professional MUST match the name!
    if is_name_search and effective_name_score <= 0.0:
        return 0.0

    # 3. Profession / Category match
    cat_score = _match(cat, exact=150, starts=125, contains=95, min_len=2)

    # 4. Specialization match
    spec_score = _match(spec, exact=125, starts=105, contains=80, min_len=2)

    # 5. City / Location match
    city_score = _match(city, exact=70, starts=55, contains=35, min_len=2)
    area_score = _match(area, exact=50, starts=40, contains=25, min_len=2)
    country_score = _match(country, exact=30, starts=20, contains=15, min_len=3)

    # 6. Secondary fields (skills, services, company, tags, bio)
    skills_score = _match(skills, exact=40, starts=30, contains=20, min_len=3)
    svc_score = _match(svc, exact=35, starts=25, contains=15, min_len=3)
    co_score = _match(co, exact=30, starts=20, contains=15, min_len=3)
    tags_score = _match(tags, exact=25, starts=18, contains=10, min_len=3)
    bio_score = _match(bio, exact=20, starts=15, contains=10, min_len=3)

    text_match_score = (
        effective_name_score +
        cat_score +
        spec_score +
        city_score +
        area_score +
        country_score +
        skills_score +
        svc_score +
        co_score +
        tags_score +
        bio_score +
        (fuzzy_other_score if effective_name_score == 0 else 0.0)
    )

    # Invariant: If there is no textual/relevance match, the professional gets 0.0!
    # Non-relevance bonuses (verified, rating, etc.) must NEVER manufacture relevance out of thin air.
    if text_match_score <= 0.0:
        return 0.0

    score = text_match_score

    # ── Secondary Quality & Location Signals (Strictly bounded: max ~25 pts total) ──
    # Verified (max 3 pts)
    if prof.is_verified:
        score += 3.0

    # Rating (0-5 pts, 5★ = 5.0)
    try:
        score += min(5.0, float(prof.average_rating))
    except (TypeError, ValueError):
        pass

    # Location proximity (0-5 pts, closer = more pts)
    if customer_lat and customer_lng:
        try:
            prof_lat = float(up.latitude)
            prof_lng = float(up.longitude)
            dist = _haversine_km(customer_lat, customer_lng, prof_lat, prof_lng)
            score += max(0.0, 5.0 - dist * 0.05)  # 5 at 0km -> 0 at 100km+
        except Exception:
            pass

    # Availability (+3 pts)
    if getattr(prof, 'is_available', True):
        score += 3.0

    # Completed Jobs (0-3 pts)
    completed = getattr(user, 'completed_jobs_count', 0) or 0
    score += min(3.0, completed * 0.1)

    # Profile Completeness (0-2 pts)
    score += _profile_completeness(user) * 2.0

    # Response Time (0-2 pts)
    resp_hrs = getattr(prof, 'response_time_hrs', 24.0) or 24.0
    score += max(0.0, 2.0 - resp_hrs * 0.08)

    # Premium boost (+2 pts)
    prem = is_premium if is_premium is not None else _is_premium_professional(user)
    if prem:
        score += 2.0

    return score


# ── Minimum relevance threshold ───────────────────────────────────────────────
# Raised from 12.0 to 30.0 so non-matching noise is strictly eliminated.
MIN_RELEVANCE_SCORE = 30.0


# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

def _is_premium_professional(user):
    from apps.subscriptions.utils import is_premium
    return is_premium(user)


def _haversine_km(lat1, lon1, lat2, lon2):
    lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
    return EARTH_RADIUS_KM * 2 * atan2(sqrt(a), sqrt(1 - a))


def _distance_bucket(distance_km):
    if distance_km is None:
        return len(DISTANCE_BUCKETS) + 1
    for i, cutoff in enumerate(DISTANCE_BUCKETS):
        if distance_km <= cutoff:
            return i
    return len(DISTANCE_BUCKETS)


# ══════════════════════════════════════════════════════════════════════════
# Intelligent Location Priority (additive layer — does NOT touch scoring,
# filtering, or sorting above). Applied only as a post-processing step on
# the already-scored/sorted results, and only when:
#   • the request has no explicit `city` filter (that existing behaviour
#     is left completely untouched), and
#   • the customer's GPS coordinates are available.
# Otherwise results pass through exactly as before.
# ══════════════════════════════════════════════════════════════════════════

# Note: _CITY_CENTROIDS, _CITY_RADIUS_KM, and _DEFAULT_CITY_RADIUS_KM are
# defined near the top of the module for global availability across all functions.



def _reverse_geocode_city(lat, lng):
    """
    Real reverse geocoding — turns live GPS coordinates into a city name
    for ANY location worldwide, via OpenStreetMap's Nominatim service.
    This is display-only: it is never used to filter or match
    professionals (see _apply_location_priority, which matches purely on
    haversine distance between real coordinates).

    🐛 FIX: the previous approach guessed the customer's city from a fixed,
    hand-maintained table of ~30 Pakistani city centroids
    (_CITY_CENTROIDS). That doesn't scale to a global marketplace and is
    exactly the kind of hardcoding this function replaces — any city
    anywhere in the world now resolves correctly, not just the ones
    someone remembered to add to a list.

    Results are cached (rounded to ~1km precision) for 24h, both to keep
    this fast on repeat requests and to respect Nominatim's usage policy
    (max ~1 request/sec, caching strongly encouraged). Returns None on any
    failure (timeout, network error, no address found) — callers must
    treat a None city as "don't show a city name", never crash or block.
    """
    if not lat or not lng:
        return None

    cache_key = f'reverse_geocode_city:{round(lat, 2)}:{round(lng, 2)}'
    cached = cache.get(cache_key)
    if cached is not None:
        return cached or None   # cached empty string means "looked up, found nothing"

    city = None
    try:
        response = httpx.get(
            'https://nominatim.openstreetmap.org/reverse',
            params={
                'format':       'jsonv2',
                'lat':          lat,
                'lon':          lng,
                'zoom':         10,          # city-level detail
                'addressdetails': 1,
            },
            headers={
                # Required by Nominatim's usage policy — identifies the
                # calling application, not a real user.
                'User-Agent': 'ProFinder-App/1.0 (location-based professional search)',
            },
            timeout=3.0,
        )
        response.raise_for_status()
        address = response.json().get('address', {})
        # Try progressively broader fields — not every location has a
        # "city" field (rural areas often only have "town"/"village"/"county").
        city = (
            address.get('city') or address.get('town') or address.get('village')
            or address.get('municipality') or address.get('county')
        )
        if city:
            city = city.strip()
    except Exception as e:
        logger.warning('[geocode] reverse geocoding failed for (%s, %s): %s', lat, lng, e)
        city = None

    cache.set(cache_key, city or '', timeout=60 * 60 * 24)  # 24h
    return city


def _detect_customer_city(customer_lat, customer_lng):
    """
    Last-resort city guess from a fixed Pakistani city-centroid table —
    used ONLY if _reverse_geocode_city's live API call fails (network
    error, timeout, service down). Not scalable outside Pakistan by
    design; that's fine here because it's a fallback of a fallback, not
    the primary path anymore.
    """
    if not customer_lat or not customer_lng:
        return None

    distances = {
        city: _haversine_km(customer_lat, customer_lng, clat, clng)
        for city, (clat, clng) in _CITY_CENTROIDS.items()
    }

    # 1) Inside a city's own footprint? Prefer the largest-radius match
    #    (avoids a big metro's outskirts being claimed by a small nearby town).
    inside = [c for c, d in distances.items()
              if d <= _CITY_RADIUS_KM.get(c, _DEFAULT_CITY_RADIUS_KM)]
    if inside:
        return max(inside, key=lambda c: _CITY_RADIUS_KM.get(c, _DEFAULT_CITY_RADIUS_KM))

    # 2) Not inside any known footprint — fall back to nearest centroid.
    return min(distances, key=distances.get)


def _customer_location_label(customer_lat, customer_lng, saved_city=None):
    """
    Single entry point for "what do we call the customer's current
    location" — always prefers a real, dynamically-detected name over any
    hardcoded guess:
      1) saved profile city (authenticated users — their own stated city)
      2) live reverse geocoding of their GPS (works for any city, any country)
      3) the old centroid-table guess, only if the geocoding API call itself failed
    """
    if saved_city:
        return saved_city.title()
    geocoded = _reverse_geocode_city(customer_lat, customer_lng)
    if geocoded:
        return geocoded.title()
    guessed = _detect_customer_city(customer_lat, customer_lng)
    return guessed.title() if guessed else None


# 🎛️ Nearby Professionals radius caps. This is the ONLY thing that
# decides who counts as "nearby" — real Haversine distance from the
# customer's live coordinates, calculated for the ENTIRE professional
# pool in one pass. City names are never used to filter or batch this
# calculation.
MAX_NEARBY_DISTANCE_KM      = 300   # primary cap
EXTENDED_NEARBY_DISTANCE_KM = 500   # single fallback expansion, only if 300km is completely empty


def _apply_location_priority(results, customer_lat, customer_lng, term_label, saved_city=None):
    """
    Production location-matching logic for "Nearby Professionals".

    🐛 COMPLETE REWRITE (reported: Karachi results cutting off after 2-3,
    Hyderabad professionals reappearing after Karachi in the response —
    proof the previous implementation was not doing one clean, global
    distance-then-sort pass over the entire dataset).

    This function now does EXACTLY three steps, over the FULL `results`
    list handed to it (already built from every active professional with
    a computed `distance_km` — never filtered or looped by city before
    this point):

      Step 1 — FILTER: keep only professionals with a computed
               `distance_km` that is <= MAX_NEARBY_DISTANCE_KM (300km).
               This is a single list comprehension over the entire pool
               in one pass — not per-city, not batched, not limited.

      Step 2 — SORT: one single `sorted()` call, globally, by
               `distance_km` ascending, over that entire filtered list.
               There is no secondary grouping key of any kind (no city,
               no rating) — distance is the ONLY sort key, so the result
               is strictly nearest-first with no possibility of a farther
               professional appearing before a nearer one, regardless of
               which city either belongs to.

      Step 3 — EXPAND (only if Step 1 produced zero results): re-run the
               exact same filter+sort against EXTENDED_NEARBY_DISTANCE_KM
               (500km). If THAT is also empty, fall back to nationwide
               top-rated as the absolute last resort. The radius is never
               allowed to jump straight from "no GPS at all" or "empty at
               300km" directly to nationwide — 500km is always tried
               first.

    `saved_city` (authenticated users only) is used ONLY when live GPS is
    unavailable at all — never as a substitute for real GPS when GPS is
    present, and never as the matching key when it is used (it's a plain
    string city match at that point, same as the old city-filter path).

    `_customer_location_label` does real reverse geocoding for the "you're
    near X" label — it never filters or scores anything below.
    """
    has_gps = bool(customer_lat and customer_lng)
    location_label = _customer_location_label(customer_lat, customer_lng, saved_city=saved_city) if has_gps or saved_city else None

    logger.info(
        '[location] gps=(%s, %s) resolved_current_city=%s saved_city=%s',
        customer_lat, customer_lng, location_label, saved_city,
    )

    def _nationwide_top_rated(pool, reason):
        ranked = sorted(
            pool,
            key=lambda r: (r.get('average_rating', 0), r.get('reviews_count', 0), r.get('relevance_score', 0)),
            reverse=True,
        )
        logger.info('[location] source=nationwide reason=%s found=%d', reason, len(ranked))
        unavailable = (
            f'No professionals are currently available in {location_label}.'
            if location_label else 'No professionals are currently available nearby.'
        )
        return ranked, {
            'location_label':           location_label,
            'city_unavailable_message': unavailable,
            'other_cities_section':     'Top Rated Professionals Nationwide',
            'results_source':           'nationwide',
        }

    def _global_distance_filter_and_sort(pool, max_km):
        """
        Step 1 + Step 2, exactly as specced: ONE filter pass over the
        WHOLE pool (never restricted to a city, never restricted to a
        batch), then ONE global sort by distance_km ascending. Nothing
        else touches ordering.
        """
        within = [r for r in pool if r.get('distance_km') is not None and r['distance_km'] <= max_km]
        within_sorted = sorted(within, key=lambda r: r['distance_km'])
        return within_sorted

    # ── No live GPS at all ──────────────────────────────────────────────
    #
    # 🐛 FIX (reported): "no GPS, use saved city" used to be a plain
    # exact-string-match filter — `city == 'karachi'` — which is exactly
    # the same city-name-based mistake this function must never make
    # elsewhere either. A customer whose saved city is Karachi but who
    # has 2 professionals in Hyderabad genuinely closer than some/all
    # Karachi ones would NEVER see those Hyderabad professionals at all —
    # only ever "Karachi", regardless of real distance. Since we know the
    # saved city's name, we know its centroid coordinates — so instead of
    # string-matching, treat that centroid as the customer's coordinates
    # and run it through the EXACT SAME real-distance filter+sort used
    # for live GPS below. This is still "saved city as fallback, never a
    # substitute for live GPS" — it just means the fallback itself is now
    # distance-based too, instead of a name filter.
    if not has_gps and saved_city:
        centroid = _CITY_CENTROIDS.get(_normalize(saved_city))
        if centroid:
            customer_lat, customer_lng = centroid
            has_gps = True
            logger.info(
                '[location] source=saved_city_centroid city=%s centroid=(%s, %s) — '
                'using real-distance logic instead of a city-name filter',
                saved_city, customer_lat, customer_lng,
            )
        else:
            # Saved city isn't in our known centroid table at all — can't
            # compute real distance from it, so this is the one case
            # where a plain string match is the only option left.
            same_city = [r for r in results if _normalize(r.get('city') or '') == saved_city]
            logger.info('[location] source=saved_city_unrecognized city=%s found=%d', saved_city, len(same_city))
            if same_city:
                return same_city, {
                    'location_label':   location_label,
                    'results_source':   'saved_city',
                }
            return _nationwide_top_rated(results, reason='saved_city_empty')

    if not has_gps:
        # Guest, no GPS permission, no saved city — caller shows "Popular
        # Professionals" instead of "Nearby Professionals"; results stay
        # as the existing relevance/rating-sorted order, untouched.
        logger.info('[location] source=popular (no gps, no saved city) found=%d', len(results))
        return results, {'location_label': None, 'results_source': 'popular'}

    # ── Live GPS available (or a saved-city centroid standing in for it) ──
    # Step 1: EVERY professional in `results` already has a `distance_km`
    # computed against `customer_lat`/`customer_lng` (done once, up front,
    # for the entire pool — see HomeFeedView/_build_professional_data).
    # Nothing here filters that pool by city or processes it in batches.
    total_with_gps = sum(1 for r in results if r.get('distance_km') is not None)
    logger.info(
        '[location] user_gps=(%.6f, %.6f) professionals_with_valid_distance=%d/%d — '
        'running ONE global filter + ONE global sort over the full pool',
        customer_lat, customer_lng, total_with_gps, len(results),
    )

    # Step 1 + Step 2 — single global filter + single global sort at 300km.
    nearby = _global_distance_filter_and_sort(results, MAX_NEARBY_DISTANCE_KM)

    search_radius_km = MAX_NEARBY_DISTANCE_KM
    results_source    = 'radius'

    # Step 3 — expand ONLY if 300km produced nothing at all.
    if not nearby:
        nearby = _global_distance_filter_and_sort(results, EXTENDED_NEARBY_DISTANCE_KM)
        search_radius_km = EXTENDED_NEARBY_DISTANCE_KM
        results_source    = 'extended_radius'

    if not nearby:
        # Nobody anywhere within 500km (or no professional anywhere has
        # usable GPS distance at all) — absolute last resort.
        return _nationwide_top_rated(results, reason='beyond_extended_radius' if total_with_gps else 'no_distance_data')

    # 🪵 Step 7 — temporary debug verification. Logs the FINAL response
    # order exactly as it will be returned, so it can be diff'd directly
    # against the API response to confirm there is no reordering anywhere
    # downstream of this function.
    logger.info(
        '[location] === NEARBY DEBUG: radius_km=%d results_source=%s total=%d ===',
        search_radius_km, results_source, len(nearby),
    )
    for r in nearby:
        logger.info(
            '[location] %s - %s - %skm',
            r.get('name') or r.get('id'), r.get('city') or 'unknown', r.get('distance_km'),
        )

    return nearby, {
        'location_label':    location_label,
        'search_radius_km':  search_radius_km,   # internal/debug only
        'results_source':    results_source,
    }


# Sanity-check radius for cross-validating a professional's stored GPS
# against their own declared city. If their coordinates are farther than
# this from where their city actually is, something is wrong with the
# data (swapped/copy-pasted coordinates, bad manual entry, stale test
# data, etc.) — trusting it anyway is exactly how a Faisalabad-labelled
# professional can wrongly show up 140km away instead of ~1000km away.
COORD_CITY_SANITY_RADIUS_KM = 60.0


def _validate_professional_coords(lat, lng, city):
    """
    Returns (is_valid, reason). Coordinates are rejected — never used for
    distance math — when:
      • missing entirely
      • outside the physically valid world range
      • exactly (0, 0) — the classic "null island" uninitialized-field bug
      • inconsistent with the professional's OWN declared city by more
        than COORD_CITY_SANITY_RADIUS_KM (only checked when that city is
        a recognized centroid — unrecognized cities aren't penalized)
    This is a data-quality safety net, not the primary search mechanism —
    it only prevents corrupted/mismatched coordinates from silently
    producing a wrong distance number.
    """
    if lat is None or lng is None:
        return False, 'missing'
    if not (-90 <= lat <= 90) or not (-180 <= lng <= 180):
        return False, 'out_of_range'
    if lat == 0 and lng == 0:
        return False, 'null_island'
    if city:
        centroid = _CITY_CENTROIDS.get(_normalize(city))
        if centroid:
            drift_km = _haversine_km(lat, lng, centroid[0], centroid[1])
            if drift_km > COORD_CITY_SANITY_RADIUS_KM:
                return False, f'inconsistent_with_declared_city(drift={drift_km:.0f}km)'
    return True, None


def _build_professional_data(user, customer_lat=None, customer_lng=None, relevance=None, is_premium=None):
    try:
        prof = user.professionalprofile
        up   = user.userprofile

        prof_lat_raw = float(up.latitude)  if up.latitude  is not None else None
        prof_lng_raw = float(up.longitude) if up.longitude is not None else None

        is_valid, invalid_reason = _validate_professional_coords(prof_lat_raw, prof_lng_raw, up.city)

        if is_valid:
            prof_lat, prof_lng = prof_lat_raw, prof_lng_raw
            distance_is_precise = True
        else:
            if prof_lat_raw is not None or prof_lng_raw is not None:
                logger.warning(
                    '[geo] INVALID coordinates for professional user_id=%s city=%s lat=%s lng=%s reason=%s — '
                    'falling back to city centroid, please review this profile\'s data',
                    user.id, up.city, prof_lat_raw, prof_lng_raw, invalid_reason,
                )
            else:
                logger.info('[geo] professional user_id=%s city=%s has no coordinates on file', user.id, up.city)
            prof_lat, prof_lng = None, None
            distance_is_precise = False

        if not distance_is_precise and up.city:
            centroid = _CITY_CENTROIDS.get(_normalize(up.city))
            if centroid:
                prof_lat, prof_lng = centroid

        distance_km = None
        if customer_lat and customer_lng and prof_lat and prof_lng:
            distance_km = round(
                _haversine_km(customer_lat, customer_lng, prof_lat, prof_lng), 1
            )

        photo_url = None
        if prof.photo_url:
            try:
                photo_url = prof.photo_url.url
            except Exception:
                pass
        if not photo_url and hasattr(user, 'userprofile') and user.userprofile.photo_url:
            try:
                photo_url = user.userprofile.photo_url.url
            except Exception:
                pass

        # Real-time presence (chat WebSocket)
        presence = getattr(user, 'presence', None)
        is_online = bool(presence.is_online) if presence else False
        last_seen = presence.last_seen.isoformat() if presence and presence.last_seen else None

        prem = is_premium if is_premium is not None else _is_premium_professional(user)
        currency, currency_symbol = resolve_currency_for_user(country=up.country, city=up.city)

        return {
            'id':                str(user.id),
            'name':              user.name,
            'photo_url':         photo_url,
            'bio':               prof.bio,
            'specialization':    prof.specialization,
            'skills':            prof.skills,
            'company_name':      prof.company_name,
            'services':          prof.services,
            'tags':              prof.tags,
            'hourly_rate':       float(prof.hourly_rate),
            'currency':          currency,
            'currency_symbol':   currency_symbol,
            'average_rating':    float(prof.average_rating),
            'experience_years':  prof.experience_years,
            'is_verified':       prof.is_verified,
            'is_premium':        prem,
            'is_available':      getattr(prof, 'is_available', True),
            'is_online':         is_online,
            'last_seen':         last_seen,
            'completed_jobs':    getattr(user, 'completed_jobs_count', 0) or 0,
            'reviews_count':     getattr(user, 'reviews_count', 0) or 0,
            'profile_views_count':  getattr(user, 'profile_views_count', 0) or 0,
            'favorites_count':      getattr(user, 'favorites_count', 0) or 0,
            'bookings_this_week':   getattr(user, 'bookings_this_week', 0) or 0,
            'bookings_prev_week':   getattr(user, 'bookings_prev_week', 0) or 0,
            'positive_reviews_week': getattr(user, 'positive_reviews_week', 0) or 0,
            'views_this_week':      getattr(user, 'views_this_week', 0) or 0,
            'inquiries_this_week':  getattr(user, 'inquiries_this_week', 0) or 0,
            'favorites_this_week':  getattr(user, 'favorites_this_week', 0) or 0,
            'reviews_this_week':    getattr(user, 'reviews_this_week', 0) or 0,
            'response_time_hrs': getattr(prof, 'response_time_hrs', 24.0) or 24.0,
            'profile_complete':  round(_profile_completeness(user) * 100),
            'city':              up.city,
            'gender':            up.gender,
            'area':              up.area,
            'country':           up.country,
            'latitude':          prof_lat,
            'longitude':         prof_lng,
            'category_id':       prof.category_id,
            'category_name':     prof.category.name if prof.category else '',
            'distance_km':       distance_km,
            'distance_is_precise': distance_is_precise,
            'relevance_score':   round(relevance or 0, 1),
            'created_at':        user.created_at.isoformat() if getattr(user, 'created_at', None) else None,
        }
    except Exception:
        logger.exception('[home] _build_professional_data failed for user_id=%s — dropping this professional', getattr(user, 'id', None))
        return None


def _sort_professionals(results):
    """
    Primary:   relevance_score DESC  — contains Name/Profession/Specialization
               plus all weighted signals below.
    Tie-breakers (same score, e.g. category browse with no keyword) follow
    the EXACT required priority order:
      Verified → Highest Rating → Nearest → Availability →
      Completed Jobs → Profile Completeness → Response Time → Deterministic ID
    """
    return sorted(
        results,
        key=lambda x: (
            -x.get('relevance_score',   0),
            not x.get('is_verified',    False),
            -x.get('average_rating',    0),
            x['distance_km'] if x.get('distance_km') is not None else float('inf'),
            not x.get('is_available',   True),
            -x.get('completed_jobs',    0),
            -x.get('profile_complete',  0),
            x.get('response_time_hrs',  24),
            not x.get('is_premium',     False),
            str(x.get('id', '')),
        )
    )


def _float_param(request, name, default):
    """
    Optional numeric query param. Missing, empty, malformed, non-finite
    (nan/inf) or negative values are IGNORED (the default is used) — same
    lenient convention as lat/lng and max_distance here — so bad input can
    never raise and turn into an HTTP 500.
    """
    raw = request.query_params.get(name)
    if raw is None or not str(raw).strip():
        return default
    try:
        value = float(str(raw).strip())
    except (TypeError, ValueError):
        return default
    if not math.isfinite(value) or value < 0:
        return default
    return value


def _get_customer_location(request):
    lat = request.query_params.get('lat') or request.query_params.get('latitude')
    lng = request.query_params.get('lng') or request.query_params.get('longitude')
    try:
        return (float(lat), float(lng)) if lat and lng else (None, None)
    except (TypeError, ValueError):
        return (None, None)


def _get_customer_saved_city(request):
    """
    Logged-in customer's own profile city — the reliable ground truth.
    Big metro areas (Karachi, Lahore, etc.) span 40-60km+, so guessing the
    city purely from a single GPS point vs. small-town centroids can pick
    the wrong neighbour (e.g. a customer in outer Karachi being closer to
    Thatta's centroid than Karachi's). The saved profile city avoids that
    entirely. Falls back to None for guests / customers without a saved city.
    """
    user = getattr(request, 'user', None)
    if not user or not getattr(user, 'is_authenticated', False):
        return None
    try:
        city = user.userprofile.city
        return _normalize(city) if city else None
    except Exception:
        return None


def _build_empty_state(term='', customer_lat=None, customer_lng=None) -> dict:
    """
    Jab koi result na mile — 4 fallback sections return karta hai.
    Flutter isse rich empty-state UI mein dikhata hai.

    1. similar_professionals  — synonyms expand karke related pros dhundho
    2. nearby_professionals   — GPS se nearest top-rated (any category)
    3. popular_professionals  — highest rating overall
    4. trending_categories    — sabse zyada professionals wali categories
    """
    from django.db.models import Count, Q as DQ

    base_qs = (
        User.objects
        .filter(role='professional')
        .select_related('professionalprofile', 'professionalprofile__category', 'userprofile', 'presence')
    )

    # ── 1. Similar professionals (synonym-expanded search) ────────────────
    similar = []
    if term:
        # The term itself first — _expand_query() returns an unordered set, so
        # [:4] could previously skip the actual profession word entirely.
        expanded = [term] + [e for e in _expand_query(term) if e != term]
        # Use up to 3 expanded synonyms for similar search
        sim_qs = base_qs.none()
        for syn in expanded[:4]:
            sim_qs = sim_qs | _multi_field_qs(base_qs, [syn])
        for user in sim_qs.distinct()[:6]:
            d = _build_professional_data(user, customer_lat, customer_lng, relevance=40)
            if d:
                similar.append(d)
        similar = _sort_professionals(similar)[:5]

    # ── 2. Nearby professionals (any category, sorted by distance) ────────
    nearby = []
    if customer_lat and customer_lng:
        for user in base_qs.filter(
            professionalprofile__average_rating__gte=3.5
        )[:40]:
            d = _build_professional_data(user, customer_lat, customer_lng, relevance=30)
            if d and d.get('distance_km') is not None:
                nearby.append(d)
        nearby = sorted(nearby, key=lambda x: x.get('distance_km', 9999))[:5]

    # ── 3. Popular professionals (top rated overall) ──────────────────────
    popular_qs = (
        base_qs
        .filter(professionalprofile__is_verified=True)
        .order_by('-professionalprofile__average_rating')[:8]
    )
    popular = []
    for user in popular_qs:
        d = _build_professional_data(user, customer_lat, customer_lng, relevance=20)
        if d:
            popular.append(d)

    # ── 4. Trending categories (most professionals) ───────────────────────
    trending_cats = list(
        Category.objects
        .annotate(pro_count=Count('professionalprofile'))
        .filter(pro_count__gt=0)
        .order_by('-pro_count')
        .values('id', 'name', 'pro_count')[:6]
    )

    return {
        'similar_professionals':  similar,
        'nearby_professionals':   nearby,
        'popular_professionals':  popular,
        'trending_categories':    trending_cats,
    }


def _build_response(results, meta=None):
    return {
        'results': results,
        'meta':    meta or {'is_fallback': False, 'fallback_message': '', 'total': len(results)},
    }


# ─────────────────────────────────────────────────────────────────────────────
# Views
# ─────────────────────────────────────────────────────────────────────────────

class AutoSuggestView(APIView):
    """
    Real-time suggestions while user is typing.
    Returns 5 sections — never returns all-empty.

    GET /search/suggest/?q=doc
    Response:
    {
      "popular_searches":      ["Doctor", "Lawyer", ...],
      "matching_professions":  ["Doctor", "Dentist", ...],
      "matching_categories":   [{"id": 1, "name": "Healthcare"}],
      "matching_professionals": [{"id":"1","name":"Dr. Ali","category":"Doctor","city":"Karachi"}],
    }
    """
    permission_classes = [AllowAny]

    POPULAR_SEARCHES = [
        'Doctor', 'Lawyer', 'Engineer', 'Teacher', 'Plumber',
        'Electrician', 'Accountant', 'Developer', 'Dentist', 'Architect',
        'Cleaner', 'Mechanic', 'Chef', 'Photographer', 'Physiotherapist',
        'Tutor', 'Nurse', 'Carpenter', 'Painter', 'Veterinarian',
    ]

    def get(self, request):
        from django.db.models import Q as DQ

        raw = request.query_params.get('q', '').strip()
        term = _normalize(raw)
        # Any-language typing: Urdu/Hindi/Arabic/Roman-spelling profession words
        # are mapped to their English profession (aliases.py), then a one-word
        # typo is repaired, so every section below also works for Urdu script,
        # "vakil", "dentst" ... exactly like it does for English.
        search_term = _normalize(_translate_multilingual(raw)) if raw else ''
        search_term = search_term or term
        if search_term and ' ' not in search_term and len(search_term) >= 4:
            search_term = _correct_typo(search_term)[0] or search_term
        fz_tokens = _fz_tokens(raw) if raw else []

        # ── No query — show popular only ─────────────────────────────────
        if not term:
            return Response({
                'popular_searches':       self.POPULAR_SEARCHES[:8],
                'matching_professions':   [],
                'matching_categories':    [],
                'matching_professionals': [],
            })

        # ── Matching professions from vocabulary ──────────────────────────
        # startswith gets highest priority, then contains
        starts   = [w.title() for w in SEARCH_VOCABULARY if w.startswith(search_term)]
        contains = [w.title() for w in SEARCH_VOCABULARY if search_term in w and not w.startswith(search_term)]
        matching_professions = list(dict.fromkeys(starts + contains))[:6]

        # ── Matching categories from DB ───────────────────────────────────
        cats = list(
            Category.objects
            .filter(DQ(name__icontains=raw) | DQ(name__icontains=search_term))
            .values('id', 'name')
            .order_by('name')[:5]
        )

        # ── Matching professionals (name / specialization / category) ─────
        # If query matches a known profession or category, suggest professionals from that category only!
        _, suggest_cat_ids = _resolve_category_ids(search_term) if search_term else (None, [])
        if not suggest_cat_ids and raw:
            _, suggest_cat_ids = _resolve_category_ids(raw)

        if suggest_cat_ids:
            pro_match = DQ(professionalprofile__category_id__in=suggest_cat_ids)
        else:
            pro_match = (
                DQ(name__icontains=raw) |
                DQ(name__icontains=search_term)
            )
            if len(search_term) >= 3:
                pro_match |= (
                    DQ(professionalprofile__specialization__icontains=raw) |
                    DQ(professionalprofile__category__name__icontains=raw) |
                    DQ(professionalprofile__specialization__icontains=search_term) |
                    DQ(professionalprofile__category__name__icontains=search_term)
                )
            if fz_tokens:                       # cross-script / misspelt names
                pro_match |= _fz_q(fz_tokens)
        pro_qs = (
            User.objects
            .filter(role='professional')
            .filter(pro_match)
            .select_related('professionalprofile', 'professionalprofile__category', 'userprofile', 'presence')
            .distinct()[:6]
        )
        pros = []
        for p in pro_qs:
            try:
                pp = getattr(p, 'professionalprofile', None)
                up = getattr(p, 'userprofile', None)
                photo_url = None
                if pp and pp.photo_url:
                    try:
                        photo_url = pp.photo_url.url
                    except Exception:
                        s = str(pp.photo_url).strip()
                        if 'http://' in s or 'https://' in s or '/' in s:
                            photo_url = s
                if not photo_url and up and up.photo_url:
                    try:
                        photo_url = up.photo_url.url
                    except Exception:
                        s = str(up.photo_url).strip()
                        if 'http://' in s or 'https://' in s or '/' in s:
                            photo_url = s

                pros.append({
                    'id':       str(p.id),
                    'name':     p.name,
                    'category': pp.category.name if pp and pp.category else '',
                    'city':     (up.city if up else '') or '',
                    'photo_url': photo_url,
                })
            except Exception:
                pass

        # ── Popular — filter by query, fallback to all ────────────────────
        popular = [p for p in self.POPULAR_SEARCHES if search_term in p.lower()]
        if not popular:
            popular = self.POPULAR_SEARCHES[:6]

        # ── Never all-empty guarantee ─────────────────────────────────────
        if not matching_professions and not cats and not pros:
            matching_professions = popular[:6]

        return Response({
            'popular_searches':       popular[:5],
            'matching_professions':   matching_professions,
            'matching_categories':    cats,
            'matching_professionals': pros,
        })


def _localize_names(label, rows, request):
    """
    Categories/subcategories ko ?lang= ke mutabiq 'localized_name' lagata hai
    (`name` untouched — search matching aur purane clients English par chalte
    hain). Kabhi raise nahi karta: koi bhi error ho to localized_name = name,
    taake Home ke sections is wajah se kabhi khali na hon.
    """
    try:
        from apps.admin_panel.models import ContentTranslation
        return ContentTranslation.localize_rows(
            label, rows, request.query_params.get('lang'), prefix='localized_')
    except Exception:
        logger.exception('[i18n] %s localization failed — serving base names', label)
        return [{**dict(r), 'localized_name': r.get('name', '')} for r in rows]


class CategoryView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        from apps.search.serializers import CategorySerializer

        # 🐛 FIX (regression root cause, part 1): this query used to be
        # unguarded. Any error here (bad/missing column after a migration
        # drift, a transient DB hiccup, etc.) raised straight out of the
        # view as an unhandled 500 — which the Flutter side surfaces as a
        # generic failure, but which should NEVER be able to take down
        # "Popular Categories" as a section. Every Guest Home section must
        # degrade to empty on its own failure, never throw.
        try:
            cats = Category.objects.all().order_by('order', 'name')
            return Response(_localize_names(
                'category', CategorySerializer(cats, many=True).data, request))
        except Exception:
            logger.exception('[home] CategoryView failed — returning empty list')
            return Response([])


class FeaturedCategoriesView(APIView):
    """
    GET /api/search/categories/featured/

    Guest Home's "Featured Categories" section — admin-curated, never a
    random/arbitrary subset of whatever CategoryView happens to return.

    🐛 FIX: previously the Flutter side just took the first N categories
    off the plain /categories/ list (itself ordered only by the `order`
    field) and called that "Featured" — no actual curation, no admin
    control, and functionally indistinguishable from "whichever categories
    happen to have the lowest `order` value".

    Rules:
      1. Only categories with is_featured=True are eligible.
      2. Top-level categories only (parent__isnull=True) — a featured
         subcategory wouldn't render sensibly in this UI.
      3. Ordered by `order`, then `name` — same deterministic ordering as
         everywhere else, never random.
      4. Capped at 6 (spec: max 6, horizontal scroll).
      5. If ZERO categories are marked featured, automatically fall back
         to the most popular categories — ranked by completed bookings
         + matching search volume — so the section is never empty just
         because no admin has curated it yet.
    """
    permission_classes = [AllowAny]
    MAX_FEATURED = 6

    def get(self, request):
        from apps.search.serializers import CategorySerializer

        # 🐛 FIX (regression root cause, part 2): this is the exact query
        # that changed when Featured Categories shipped (new is_featured
        # filter + parent__isnull filter). It was unguarded — any error
        # evaluating it (e.g. the is_featured column not existing yet
        # because a migration wasn't run against this environment's DB,
        # or any other transient DB error) propagated as an unhandled
        # 500, wiping out the ENTIRE "Featured Categories" section AND,
        # because the same request cycle in Flutter loads categories and
        # featured-categories together, made the failure look like the
        # whole Guest Home had gone empty. Now: any failure here falls
        # through to the popular-categories fallback below instead of
        # ever raising — satisfying requirement #6 (never fail just
        # because is_featured isn't usable) and requirement #3 (zero
        # featured results -> fall back to popular, never an empty
        # section).
        try:
            featured = list(
                Category.objects.filter(is_featured=True, parent__isnull=True)
                .order_by('order', 'name')[:self.MAX_FEATURED]
            )
            if featured:
                return Response({
                    'source':     'featured',
                    'categories': _localize_names(
                        'category', CategorySerializer(featured, many=True).data, request),
                })
        except Exception:
            logger.exception('[home] Featured-categories query failed — falling back to popular')

        # ── Fallback: most popular categories, by real demand signals ──
        fallback = self._popular_categories_fallback()
        return Response({
            'source':     'popular_fallback',
            'categories': _localize_names(
                'category', CategorySerializer(fallback, many=True).data, request),
        })

    def _popular_categories_fallback(self):
        """Never raises. Any error at any stage (bookings signal, search
        signal, or even reading Category itself) degrades to the next
        cheaper signal, and ultimately to a plain deterministic category
        list — this section must never come back empty just because a
        richer ranking signal failed."""
        try:
            candidates = list(Category.objects.filter(parent__isnull=True))
        except Exception:
            logger.exception('[home] Could not read categories at all for popular fallback')
            return []
        if not candidates:
            return []

        booking_counts = {}
        try:
            from django.db.models import Count
            from apps.bookings.models import Booking

            # Signal 1 — completed bookings per category (strongest demand signal).
            booking_rows = (
                Booking.objects
                .filter(status='completed',
                        professional__professionalprofile__category__isnull=False)
                .values('professional__professionalprofile__category_id')
                .annotate(c=Count('id'))
            )
            booking_counts = {
                row['professional__professionalprofile__category_id']: row['c']
                for row in booking_rows
            }
        except Exception:
            logger.exception('[home] Booking-demand signal unavailable for popular-categories fallback')

        search_counts = {}
        try:
            from apps.ai_engine.models import SearchHistory

            # Signal 2 — search volume matching a category's name (same
            # normalize + substring-match approach used for personalization
            # elsewhere in this file, since SearchHistory has no category FK).
            recent_queries = list(
                SearchHistory.objects.order_by('-created_at').values_list('query', flat=True)[:500]
            )
            normalized_queries = [_normalize(q) for q in recent_queries if q]
            for cat in candidates:
                cat_norm = _normalize(cat.name)
                if not cat_norm:
                    continue
                search_counts[cat.id] = sum(
                    1 for nq in normalized_queries if cat_norm in nq or nq in cat_norm
                )
        except Exception:
            logger.exception('[home] Search-volume signal unavailable for popular-categories fallback')

        def popularity_score(cat):
            return booking_counts.get(cat.id, 0) * 3 + search_counts.get(cat.id, 0)

        try:
            ranked = sorted(candidates, key=popularity_score, reverse=True)
        except Exception:
            logger.exception('[home] Popularity ranking failed — using deterministic category order')
            ranked = sorted(candidates, key=lambda c: (c.order, c.name))
        return ranked[:self.MAX_FEATURED]


class SubCategoryView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, category_id):
        from apps.search.serializers import SubCategorySerializer
        from apps.search.models import SubCategory
        subs = SubCategory.objects.filter(category_id=category_id)
        return Response(_localize_names(
            'subcategory', SubCategorySerializer(subs, many=True).data, request))


class NearbyProfessionalsView(APIView):
    """
    Enhanced keyword search across 11 fields with relevance scoring.
    Returns only high-relevance results (score >= MIN_RELEVANCE_SCORE).
    """
    permission_classes = [AllowAny]

    # Base queryset with all joins pre-fetched in ONE DB query
    _BASE_SELECT = (
        'professionalprofile',
        'professionalprofile__category',
        'userprofile',
        'presence',
        'search_index',
    )

    def get(self, request):
        q_param_provided = 'q' in request.query_params
        raw_query    = request.query_params.get('q', '').strip()
        city_param   = request.query_params.get('city', '').strip()
        category_id  = request.query_params.get('category_id', '')
        min_price    = _float_param(request, 'min_price',  0)
        max_price    = _float_param(request, 'max_price',  999999)
        min_rating   = _float_param(request, 'min_rating', 0)
        verified_only = request.query_params.get('verified_only', 'false').lower() == 'true'

        # ── Explicit smart filters (gender / experience / availability / language) ──
        gender_param      = request.query_params.get('gender', '').strip().lower()
        min_exp_param_raw = request.query_params.get('min_experience', '')
        available_only_param = request.query_params.get('available_only', 'false').lower() == 'true'
        language_param    = request.query_params.get('language', '').strip().lower()
        service_mode_param = request.query_params.get('service_mode', '').strip().lower()  # online / home_visit / in_office
        max_distance_param_raw = request.query_params.get('max_distance', '')  # km
        try:
            min_exp_param = float(min_exp_param_raw) if min_exp_param_raw else None
        except ValueError:
            min_exp_param = None
        try:
            max_distance_param = float(max_distance_param_raw) if max_distance_param_raw else None
        except ValueError:
            max_distance_param = None

        customer_lat, customer_lng = _get_customer_location(request)

        # ── Phase 5 Empty/Whitespace Query Guard ────────────────────────────
        # Empty or whitespace-only searches must not return the entire professional
        # directory by default. When 'q' was sent but is empty/whitespace, and no
        # other filter or location coordinate was specified, return empty state immediately.
        has_any_filter = bool(
            category_id or city_param or min_price > 0 or max_price < 999999 or
            min_rating > 0 or verified_only or gender_param or (min_exp_param is not None) or
            available_only_param or language_param or service_mode_param or
            (max_distance_param is not None) or (customer_lat and customer_lng)
        )
        if q_param_provided and not raw_query and not has_any_filter:
            empty_data = _build_empty_state(customer_lat=customer_lat, customer_lng=customer_lng)
            return Response(_build_response(
                [],
                meta={
                    'is_fallback':         False,
                    'fallback_message':    '',
                    'city_searched':       '',
                    'total':               0,
                    'spelling_corrected':  False,
                    'corrected_query':     '',
                    'is_empty':            True,
                    'detected_gender':          None,
                    'detected_urgent':          False,
                    'detected_language':        None,
                    'detected_min_experience':  None,
                    'detected_service_mode':    None,
                    'detected_max_distance':    None,
                    'distance_filter_applied':  False,
                    'personalization_applied':  False,
                    **empty_data,
                }
            ))

        # ── Base queryset — 1 DB round-trip for all relations + job count ──
        from django.db.models import Count
        from django.db.models import Q as DQ
        from django.utils import timezone

        # ── Exclude suspended or banned professionals ───────────────────────
        suspended_ids = set()
        try:
            from apps.admin_panel.models import ModerationAction
            now = timezone.now()
            suspended_ids = set(
                ModerationAction.objects
                .filter(
                    is_active=True,
                    starts_at__lte=now,
                    action_type__in=[
                        ModerationAction.ACTION_SUSPEND_PERMANENT,
                        ModerationAction.ACTION_SUSPEND_TEMPORARY,
                    ]
                )
                .filter(DQ(expires_at__isnull=True) | DQ(expires_at__gt=now))
                .values_list('target_user_id', flat=True)
            )
        except Exception as exc:
            logger.warning("Failed to fetch suspended user IDs for search: %s", exc)

        qs = (
            User.objects
            .filter(role='professional', is_active=True)
            .exclude(id__in=suspended_ids)
            .select_related(*self._BASE_SELECT)
            .annotate(
                # Real completed job count from Booking model
                completed_jobs_count=Count(
                    'bookings_received',
                    filter=DQ(bookings_received__status='completed'),
                    distinct=True,
                ),
                reviews_count=Count(
                    'received_reviews',
                    distinct=True,
                ),
            )
        )

        # ── Pre-fetch active premium professional IDs (avoids N+1 queries) ──
        try:
            from apps.subscriptions.models import Subscription
            active_premium_user_ids = set(
                Subscription.objects.filter(status='active')
                .exclude(plan__billing='free')
                .values_list('user_id', flat=True)
            )
        except Exception:
            active_premium_user_ids = set()

        # ── Filters ───────────────────────────────────────────────────────
        if min_rating   > 0:   qs = qs.filter(professionalprofile__average_rating__gte=min_rating)
        if verified_only:       qs = qs.filter(professionalprofile__is_verified=True)
        if category_id:         qs = qs.filter(professionalprofile__category_id=category_id)

        # ── Keyword search: multilingual translation → normalize → typo-fix ──
        translated_query = _translate_multilingual(raw_query) if raw_query else ''
        term = _normalize(translated_query) if translated_query else ''
        corrected_term = term
        spelling_corrected = False
        search_terms = []
        core_term = ''
        fuzzy_tokens = []

        # ── Query Classification & Disambiguation ──
        classification = _classify_search_query(term, raw_query, city_param, category_id)
        strict_category_ids = classification.get('strict_category_ids') or []
        is_category_search = classification.get('is_category_search', False)
        is_name_search = classification.get('is_name_search', False)
        name_query = classification.get('name_query')
        canonical_profession = classification.get('canonical_profession')

        # ── 1. Strict Category Isolation ──────────────────────────────────
        # Critical rule: When user searches for a profession or category, results
        # MUST belong strictly to that requested category. Never include a different
        # profession just because its name, rating, availability, or fuzzy score is similar.
        if strict_category_ids:
            qs = qs.filter(professionalprofile__category_id__in=strict_category_ids)

        if term:
            _city_found, _city_tokens = _find_city_in_text(term)
            core_term, ignored_words = _core_query(term, _city_tokens)
            
            # Efficient single-query check for words that match a professional's name
            words_for_name = [w for w in term.split() if len(w) >= 3]
            name_words = set()
            if words_for_name:
                name_q = DQ()
                for w in words_for_name:
                    name_q |= DQ(name__icontains=w)
                matching_names = list(
                    User.objects.filter(role='professional').filter(name_q).values_list('name', flat=True)[:30]
                )
                name_words = {w for w in words_for_name if any(w in n.lower() for n in matching_names)}

            # Known professional name parts for typo correction (e.g. 'umber' -> 'amber')
            known_name_tokens = cache.get('search_known_name_tokens')
            if known_name_tokens is None:
                known_name_tokens = set()
                for n in User.objects.filter(role='professional').values_list('name', flat=True)[:200]:
                    if n:
                        for part in n.lower().split():
                            if len(part) >= 3:
                                known_name_tokens.add(part)
                cache.set('search_known_name_tokens', known_name_tokens, timeout=300)

            # Skip typo correction if user typed an exact name that exists in DB
            skip_typo = set(ignored_words) | name_words
            if is_name_search and name_query:
                try:
                    if User.objects.filter(role='professional').filter(DQ(name__icontains=name_query) | DQ(name__istartswith=name_query)).exists():
                        skip_typo.add(name_query.lower())
                except Exception:
                    pass

            corrected_term, spelling_corrected = _correct_typo(
                term, skip_words=skip_typo, extra_vocab=known_name_tokens
            )
            # A typo'd city ("lahor") is fixed in the banner too.
            if _city_found and ' ' not in _city_found:
                for _t in _city_tokens:
                    if _t != _city_found:
                        corrected_term = re.sub(r'\b' + re.escape(_t) + r'\b', _city_found, corrected_term)
                        spelling_corrected = True
            core_corrected, _ = _core_query(
                corrected_term, _city_tokens | set(_city_found.split()) if _city_found else _city_tokens
            )

            # If typo corrected a name (e.g. 'umber' -> 'amber'), update name_query
            if is_name_search and name_query and spelling_corrected:
                for orig_w, fixed_w in zip(term.split(), corrected_term.split()):
                    if orig_w.lower() == name_query.lower() and fixed_w.lower() != orig_w.lower():
                        name_query = fixed_w

            # Expand: abbreviations + synonyms + original + corrected
            search_terms = [t for t in dict.fromkeys(
                _expand_query(core_term) + _expand_query(core_corrected)
            ) if t]
            fuzzy_tokens = _fz_tokens(f'{core_term} {core_corrected}')

            # ── 2. Accurate Name Matching / Multi-field Execution ─────────
            if is_name_search and name_query:
                # Name searches query strictly on name fields to avoid noise from bio/tags
                name_search_terms = [name_query]
                if name_query != core_term:
                    name_search_terms.append(core_term)
                if spelling_corrected and core_corrected:
                    name_search_terms.append(core_corrected)
                qs = _multi_field_qs(qs, name_search_terms, fuzzy_tokens, is_name_search=True)
            elif search_terms:
                qs = _multi_field_qs(qs, search_terms, fuzzy_tokens, is_category_search=is_category_search)

        # Use corrected_term for scoring (best signal)
        score_term = corrected_term if corrected_term else term
        # Full expanded term list used for actual scoring (abbreviations + synonyms)
        scoring_terms = search_terms if term else []

        # ── Numeric price detected in free text ("dr under 100$", "over 2k") ──
        price_intent = _extract_price_filter(term) if term else {}
        if raw_query:
            raw_price = _extract_price_filter(raw_query)
            if 'max_price' not in price_intent and 'max_price' in raw_price:
                price_intent['max_price'] = raw_price['max_price']
            if 'min_price' not in price_intent and 'min_price' in raw_price:
                price_intent['min_price'] = raw_price['min_price']
        if 'max_price' in price_intent:
            max_price = min(max_price, price_intent['max_price'])
        if 'min_price' in price_intent:
            min_price = max(min_price, price_intent['min_price'])
        qs = qs.filter(
            professionalprofile__hourly_rate__gte=min_price,
            professionalprofile__hourly_rate__lte=max_price,
        )

        # ── Intent-detected smart filters (Gender / Availability / Language / Experience) ──
        detected_intent = _extract_intent_filters(term) if term else {}

        effective_gender      = gender_param or detected_intent.get('gender', '')
        effective_urgent      = available_only_param or detected_intent.get('urgent', False)
        effective_language    = language_param or detected_intent.get('language', '')
        effective_min_exp     = min_exp_param if min_exp_param is not None else detected_intent.get('min_experience')
        effective_service_mode = service_mode_param or detected_intent.get('service_mode', '')
        effective_max_distance = (
            max_distance_param if max_distance_param is not None
            else detected_intent.get('max_distance')
        )

        if effective_gender in ('male', 'female', 'other'):
            qs = qs.filter(userprofile__gender=effective_gender)
        if effective_urgent:
            qs = qs.filter(professionalprofile__is_available=True)
        if effective_language:
            qs = qs.filter(professionalprofile__languages__icontains=effective_language)
        if effective_min_exp:
            qs = qs.filter(professionalprofile__experience_years__gte=effective_min_exp)
        if effective_service_mode in SERVICE_MODE_KEYWORDS:
            mode_q = DQ()
            for phrase in SERVICE_MODE_KEYWORDS[effective_service_mode]:
                mode_q |= DQ(professionalprofile__services__icontains=phrase)
            qs = qs.filter(mode_q)

        # ── City filter & Category-Preserved Fallback ─────────────────────
        is_fallback = False
        fallback_message = ''
        effective_city = city_param or classification.get('detected_city') or _extract_city_from_text(term)

        if effective_city:
            city_qs = qs.filter(userprofile__city__icontains=effective_city)
            if city_qs.exists():
                qs = city_qs
            else:
                is_fallback = True
                label = (canonical_profession or core_term or 'Professionals').title()
                fallback_message = (
                    f'No {label} found in {effective_city.title()}. '
                    f'Showing professionals from other cities.'
                )

        # ── Score + filter with Strict Category & Name Constraints ────────
        results = []
        for user in qs:
            user_is_premium = (user.id in active_premium_user_ids)
            score = _relevance_score(
                user, scoring_terms, customer_lat, customer_lng, fuzzy_tokens,
                is_premium=user_is_premium,
                target_category_ids=strict_category_ids if strict_category_ids else None,
                is_name_search=is_name_search,
            ) if score_term else 50.0
            if score < MIN_RELEVANCE_SCORE:
                continue
            data = _build_professional_data(
                user, customer_lat, customer_lng, relevance=score,
                is_premium=user_is_premium
            )
            if data:
                results.append(data)

        # ── Distance-radius filter ("near me" / explicit max_distance) ──────
        # Only meaningful once distance_km is known (needs customer GPS).
        # If GPS isn't available, the filter is silently skipped rather than
        # dropping every result — matches the "never show empty" principle.
        distance_filter_applied = False
        if effective_max_distance and customer_lat and customer_lng:
            distance_filter_applied = True
            within_radius = [
                r for r in results
                if r.get('distance_km') is not None and r['distance_km'] <= effective_max_distance
            ]
            if within_radius:
                results = within_radius
            # else: nobody within radius — fall through to full result set
            # rather than showing zero results for a distance preference.

        # ── Personalization (soft boost only — never filters results) ──────
        # Favourite categories / frequently contacted professionals /
        # preferred budget / recent searches, derived from THIS customer's
        # own history. Guests and customers with no history get +0 boost
        # everywhere, so behaviour is unchanged for them.
        from apps.ai_engine.personalization import get_personalization_profile, personalization_boost
        personalization_applied = False
        personalization_profile = get_personalization_profile(getattr(request, 'user', None))
        if personalization_profile:
            personalization_applied = True
            for r in results:
                extra = personalization_boost(r, personalization_profile)
                if extra:
                    r['relevance_score'] = round(r.get('relevance_score', 0) + extra, 1)
                    r['personalized'] = True

        sorted_results = _sort_professionals(results)

        # ── Location priority (additive, does not touch scoring/filtering/
        #    sorting above). Only runs when the customer hasn't set an
        #    explicit city filter — that existing path is untouched. Always
        #    runs (even with no GPS and no saved city) so the response's
        #    `results_source` meta correctly signals "popular" for guests
        #    with no location data — the frontend needs that signal to
        #    show "Popular Professionals" instead of "Nearby Professionals".
        location_meta = {}
        saved_city = _get_customer_saved_city(request)
        logger.info(
            '[location] request lat=%s lng=%s authenticated=%s results_before_location=%d',
            customer_lat, customer_lng,
            bool(getattr(request, 'user', None) and request.user.is_authenticated),
            len(sorted_results),
        )
        # A real text search (name / profession / skill, e.g. "amber") must
        # return EVERY match — the 300km "nearby" radius cut is only for
        # browsing without a text query. Distance still helps ranking via
        # the relevance score / sort tie-breakers above.
        has_text_query = bool(search_terms)
        if not effective_city and sorted_results and not has_text_query:
            sorted_results, location_meta = _apply_location_priority(
                sorted_results, customer_lat, customer_lng, score_term,
                saved_city=saved_city,
            )

        # ── Empty state — never show blank page ───────────────────────────
        empty_data = {}
        if not sorted_results:
            empty_data = _build_empty_state(
                term          = core_term or score_term,   # profession words only (not 'female'/'karachi')
                customer_lat  = customer_lat,
                customer_lng  = customer_lng,
            )

        return Response(_build_response(
            sorted_results,
            meta={
                'is_fallback':         is_fallback,
                'fallback_message':    fallback_message,
                'city_searched':       effective_city,
                'total':               len(sorted_results),
                'spelling_corrected':  spelling_corrected,
                'corrected_query':     corrected_term if spelling_corrected else '',
                'is_empty':            len(sorted_results) == 0,
                'detected_gender':          effective_gender or None,
                'detected_urgent':          bool(effective_urgent),
                'detected_language':        effective_language or None,
                'detected_min_experience':  effective_min_exp,
                'detected_service_mode':    effective_service_mode or None,
                'detected_max_distance':    effective_max_distance,
                'distance_filter_applied':  distance_filter_applied,
                'personalization_applied':  personalization_applied,
                **location_meta,
                **empty_data,
            }
        ))


class SearchView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        return NearbyProfessionalsView().get(request)


class PriceRangeSearchView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        min_price = _float_param(request, 'min_price', 0)
        max_price = _float_param(request, 'max_price', 999999)
        customer_lat, customer_lng = _get_customer_location(request)

        # Exclude suspended professionals
        suspended_ids = set()
        try:
            from apps.admin_panel.models import ModerationAction
            from django.utils import timezone
            now = timezone.now()
            suspended_ids = set(
                ModerationAction.objects
                .filter(
                    is_active=True,
                    starts_at__lte=now,
                    action_type__in=[
                        ModerationAction.ACTION_SUSPEND_PERMANENT,
                        ModerationAction.ACTION_SUSPEND_TEMPORARY,
                    ]
                )
                .filter(Q(expires_at__isnull=True) | Q(expires_at__gt=now))
                .values_list('target_user_id', flat=True)
            )
        except Exception:
            suspended_ids = set()

        qs = (
            User.objects
            .filter(
                role='professional',
                is_active=True,
                professionalprofile__hourly_rate__gte=min_price,
                professionalprofile__hourly_rate__lte=max_price,
            )
            .exclude(id__in=suspended_ids)
            .select_related('professionalprofile', 'professionalprofile__category', 'userprofile', 'presence')
        )

        results = []
        for user in qs:
            data = _build_professional_data(user, customer_lat, customer_lng, relevance=50)
            if data:
                results.append(data)

        return Response(_build_response(_sort_professionals(results)))


# ─── Customer Dashboard — Home Feed ────────────────────────────────────────
#
# Everything the Customer Dashboard needs in ONE call: Recommended, Nearby,
# Top Rated, and Trending — each independently ranked with its own real
# signals, and de-duplicated against each other so the same 2-3 professionals
# don't dominate every section. This replaces the old approach of reusing a
# single `nearbyProfessionals` list on the client for all four sections
# (client-side "sections" that were really just re-sorted views of one list,
# with no city enforcement and no real trending/popularity signal at all).

class HomeFeedView(APIView):
    """
    Single call powering ALL home-dashboard professional sections —
    Recommended / Nearby / Top Rated / Trending — each with its OWN
    independent query, exactly as production marketplace apps do it.

    🐛 FIX: guests previously had no equivalent of this. Their home screen
    reused ONE already-location-narrowed list (from /search/nearby/, which
    applies radius-based location priority) for every single section —
    so "Top Rated", "Trending", and "Recommended" all silently became
    "whatever 1-2 people happen to be nearby" instead of pulling from the
    WHOLE app. Nearby should be location-scoped; everything else must not
    be. Making this endpoint AllowAny (instead of IsAuthenticated) lets
    guests share the exact same correctly-scoped logic customers get.
    """
    permission_classes = [AllowAny]

    SECTION_CAP_10      = 10   # Recommended / Top Rated / Trending / Recently Added all cap at 10 per spec
    # 🐛 REMOVED: NEARBY_CAP (was 20) — Nearby must return every professional
    # inside the radius, uncapped, per spec. See the fix note in get() below.
    MIN_BACKFILL       = 4   # don't force a section down to 1-2 cards just to stay unique

    def get(self, request):
        from django.db.models import Count, Q as DQ
        from django.utils import timezone
        from datetime import timedelta

        user = request.user
        is_authenticated = bool(user and getattr(user, 'is_authenticated', False))

        # Live GPS query params are the primary source for EVERYONE (guest
        # or authenticated) — a customer's saved profile location is only
        # a fallback when they haven't granted live location this session.
        my_lat, my_lng = _get_customer_location(request)
        if my_lat is None and is_authenticated:
            try:
                up = user.userprofile
                my_lat = float(up.latitude)  if up.latitude  else None
                my_lng = float(up.longitude) if up.longitude else None
            except Exception:
                pass

        my_city = _get_customer_saved_city(request) or ''

        # 🐛 FIX (reported): when there's no live GPS AND no precise
        # profile lat/lng, `my_lat`/`my_lng` stayed None — which meant
        # EVERY professional's `distance_km` came out None too (computed
        # once, below, before location-priority even runs). A saved-city
        # centroid substitution inside `_apply_location_priority` alone
        # can't fix that retroactively — the distances have to exist
        # first. So: if we still have no coordinates at all but do know
        # the customer's saved city, use that city's centroid as the
        # distance-calculation origin right here, so every professional
        # gets a real (if approximate) distance_km — letting the normal
        # real-distance radius/expansion logic include a genuinely-closer
        # professional in a NEIGHBORING city (e.g. Hyderabad) instead of
        # only ever matching the exact saved city name (e.g. Karachi).
        if my_lat is None and my_city:
            centroid = _CITY_CENTROIDS.get(_normalize(my_city))
            if centroid:
                my_lat, my_lng = centroid

        now              = timezone.now()
        week_start       = now - timedelta(days=7)
        prev_week_start  = now - timedelta(days=14)

        # 🐛 FIX (regression root cause): this shared base query — and in
        # particular the `select_related('professionalprofile__category')`
        # join — is exactly what the Featured Categories work touched
        # (Category gained new columns). If the environment's DB schema
        # is ever out of sync with the models (e.g. a migration wasn't
        # applied), evaluating this queryset throws, and previously that
        # exception had nothing to catch it here: it propagated straight
        # out of get() as one unhandled 500 for the ENTIRE home feed —
        # Top Rated, Nearby, Trending, Recently Added, and Recommended
        # all disappearing at once, which is exactly the reported
        # "Guest Home is empty, multiple sections vanished" symptom.
        # Now this degrades to an empty (but 200 OK) feed instead, and
        # every section below is additionally isolated on its own so a
        # narrower failure never cascades either.
        try:
            qs = (
                User.objects
                .filter(role='professional', is_active=True)
                .select_related('professionalprofile', 'professionalprofile__category', 'userprofile', 'presence')
                .annotate(
                    reviews_count=Count('received_reviews', distinct=True),
                    completed_jobs_count=Count(
                        'bookings_received', filter=DQ(bookings_received__status='completed'), distinct=True),
                    profile_views_count=Count('profile_views', distinct=True),
                    favorites_count=Count('favorited_by', distinct=True),
                    bookings_this_week=Count(
                        'bookings_received', filter=DQ(bookings_received__created_at__gte=week_start), distinct=True),
                    bookings_prev_week=Count(
                        'bookings_received',
                        filter=DQ(bookings_received__created_at__gte=prev_week_start,
                                  bookings_received__created_at__lt=week_start),
                        distinct=True),
                    positive_reviews_week=Count(
                        'received_reviews',
                        filter=DQ(received_reviews__created_at__gte=week_start, received_reviews__rating__gte=4),
                        distinct=True),
                    views_this_week=Count(
                        'profile_views', filter=DQ(profile_views__created_at__gte=week_start), distinct=True),
                    favorites_this_week=Count(
                        'favorited_by', filter=DQ(favorited_by__created_at__gte=week_start), distinct=True),
                    reviews_this_week=Count(
                        'received_reviews', filter=DQ(received_reviews__created_at__gte=week_start), distinct=True),
                    # "Customer inquiries" signal for Trending — there's no separate
                    # Inquiry model in this app, so a new chat Conversation started
                    # by a customer with this professional is the real-world
                    # equivalent (a customer reaching out = an inquiry).
                    inquiries_this_week=Count(
                        'conversations_as_professional',
                        filter=DQ(conversations_as_professional__created_at__gte=week_start),
                        distinct=True),
                )
            )

            all_pros = []
            for u in qs:
                d = _build_professional_data(u, my_lat, my_lng)
                if d:
                    all_pros.append(d)
        except Exception:
            logger.exception('[home] Base professionals query failed — returning empty feed, not a 500')
            all_pros = []

        if not all_pros:
            return Response({
                'recommended': [], 'nearby': [], 'top_rated': [], 'trending': [], 'recently_added': [],
                'popular_professionals': [],
                'city_unavailable_message': 'No professionals available in your city.',
            })

        used_ids = set()

        def take(ranked, limit=None, allow_backfill=True):
            """All professionals not already used in an earlier section
            (or the first `limit` of them, if a limit is given — only
            "Top Rated" uses one, per spec). If that leaves the section
            too thin, backfill from the same ranked pool (may repeat a
            professional already shown elsewhere) rather than showing an
            almost-empty section — dedup is "whenever possible", not
            absolute."""
            fresh = [p for p in ranked if p['id'] not in used_ids]
            picked = fresh[:limit] if limit is not None else fresh
            if allow_backfill and len(picked) < self.MIN_BACKFILL:
                seen = {p['id'] for p in picked}
                for p in ranked:
                    if len(picked) >= self.MIN_BACKFILL:
                        break
                    if p['id'] not in seen:
                        picked.append(p)
                        seen.add(p['id'])
            for p in picked:
                used_ids.add(p['id'])
            return picked

        # ── 1) Nearby Professionals — THE ONLY location-based section.
        #      Reuses the exact same GPS-radius-tiered logic as the
        #      dedicated /search/nearby/ endpoint (_apply_location_priority):
        #      live GPS radius (20/50/100km) → nearest-by-distance fallback
        #      → nationwide top-rated as an absolute last resort.
        #      Independent call — its result is used ONLY here, never
        #      reused by any section below. ─────────────────────────────
        # 🐛 FIX (regression root cause, part 3): all 5 sections used to be
        # computed inline, one after another, with no isolation — a bug or
        # transient error thrown by ANY single section (e.g. this location
        # lookup) propagated straight out of get() as one unhandled 500,
        # wiping out every other section's already-good data along with
        # it. Each section is independently queried per spec (#4), so each
        # one must also independently fail — degrading to an empty list
        # for itself only, never for its siblings.
        #
        # 🐛 FIX (regression root cause, part 4): Nearby, Recommended, Top
        # Rated, Trending, and Recently Added are independent discovery
        # sections — a professional is allowed to appear in more than one
        # of them if they naturally qualify for each. This section no
        # longer filters its results through the shared `used_ids` set;
        # it only dedupes WITHIN itself (a professional can't appear twice
        # in the same section) and caps its own length.
        try:
            nearby, nearby_location_meta = _apply_location_priority(
                all_pros, my_lat, my_lng, 'professionals', saved_city=my_city or None,
            )
            # 🐛 ROOT-CAUSE FIX (missing professionals): this used to slice
            # `nearby[:self.NEARBY_CAP]` (20) AFTER `_apply_location_priority`
            # had already done its one correct global filter+sort by
            # `distance_km`. A hard slice here silently drops every
            # professional past position 20 — e.g. if 40 professionals are
            # inside the 300km radius, only the nearest 20 were ever
            # returned, and the other 20 (all genuinely "nearby") vanished
            # with no indication anything was cut. `_apply_location_priority`
            # itself already returns exactly one clean, globally-sorted list
            # with nothing filtered by city and nothing merged/re-ranked
            # afterward — the fix is to stop truncating that list, not to
            # patch around the symptom. The API response for Nearby must be
            # the full globally-sorted list, returned directly, matching the
            # same (uncapped) behaviour as the dedicated /search/nearby/
            # endpoint.
            #
            # NOTE: `NEARBY_CAP` is intentionally no longer applied here.
        except Exception:
            logger.exception('[home] Nearby section failed independently — other sections unaffected')
            nearby, nearby_location_meta = [], {}

        # ── 2) Recommended For You — GLOBAL, independent of location.
        # Personalization from search history + booking history (categories
        # the customer has shown real interest in). With no signal at all
        # (brand-new user), every professional gets the same category bonus
        # (0), so ranking collapses to rating + reviews, with same-city as
        # only a minor tie-break bonus — never a filter. Professionals from
        # any city or country can and do appear here.
        #
        # 🐛 FIX (regression root cause, part 4 — see Nearby above):
        # independent section, no longer filtered against ids already
        # picked by Nearby — only deduped within itself.
        try:
            pref_category_ids, pref_weight = self._personalization_signal(user)

            def rec_score(p):
                score = float(p['average_rating']) * 2 + p['reviews_count'] * 0.1
                cat_id = p.get('category_id')
                if cat_id in pref_category_ids:
                    score += 5 * pref_weight.get(cat_id, 1)
                if my_city and _normalize(p.get('city') or '') == my_city:
                    score += 2
                return score

            recommended = sorted(all_pros, key=rec_score, reverse=True)[:self.SECTION_CAP_10]
        except Exception:
            logger.exception('[home] Recommended section failed independently — other sections unaffected')
            recommended = []

        # ── 3) Top Rated — Top 10 ONLY (the one section with an explicit
        #      limit, per spec).
        #
        #      🐛 FIX: previously had NO eligibility filter at all, so
        #      brand-new professionals with average_rating == 0 and zero
        #      reviews were sorted right alongside genuinely top-rated
        #      pros (and, on ties, could even outrank them depending on
        #      the secondary keys). A professional needs at least one
        #      completed review AND a rating > 0 to be "Top Rated" —
        #      full stop, no backfill exception for this section.
        #
        #      Sort priority (per spec, highest first):
        #        1. Average Rating   2. Number of Reviews
        #        3. Completed Bookings  4. Verified   5. Profile Completion
        try:
            top_rated_eligible = [
                p for p in all_pros
                if p['average_rating'] > 0 and p['reviews_count'] >= 1
            ]
            # 🐛 FIX (regression root cause): this used to go through the
            # shared take() helper, which filters out any professional
            # already claimed by an EARLIER section (Nearby, Recommended)
            # via the cross-section `used_ids` set. Recommended in
            # particular has no eligibility filter and ranks heavily by
            # rating, so it was silently claiming the exact professionals
            # Top Rated needed — leaving Top Rated's own `fresh` pool
            # empty on a small/young professional base, with
            # allow_backfill=False meaning it could never recover them.
            # Top Rated must be a fully independent global query per spec
            # (never reusing / being reduced by another section's
            # results), so it now ranks directly over the full eligible
            # pool and is not subject to any other section's dedup.
            top_rated_key = lambda p: (
                p['average_rating'],
                p['reviews_count'],
                p['completed_jobs'],
                bool(p.get('is_verified')),
                p.get('profile_complete', 0),
            )
            if top_rated_eligible:
                top_rated = sorted(top_rated_eligible, key=top_rated_key, reverse=True)[:self.SECTION_CAP_10]
            else:
                # 🐛 FIX: a brand-new platform where nobody has a review yet
                # made this section permanently hidden (empty list → guest
                # home silently drops "Top Rated" entirely, looking broken).
                # Fall back to the same ranking over the full pool — still
                # best-available-first, just without the "must have a real
                # review" bar — exactly like Nearby's own last-resort
                # fallback (_nationwide_top_rated) already does.
                top_rated = sorted(all_pros, key=top_rated_key, reverse=True)[:self.SECTION_CAP_10]
            # Still contribute these ids to used_ids so LATER sections
            # (Trending, etc.) keep avoiding an exact repeat where
            # possible — Top Rated just must never be filtered BY it.
            used_ids.update(p['id'] for p in top_rated)
        except Exception:
            logger.exception('[home] Top Rated section failed independently — other sections unaffected')
            top_rated = []

        # ── 4) Trending This Week — up to 10, per spec ───────────────────
        #
        #      🐛 FIX (rebuilt): the previous version ranked 0-rated /
        #      0-review professionals purely by weekly Trending Score —
        #      which meant a brand-new account with a couple of profile
        #      views could out-rank a professional who already has real
        #      ratings, reviews, and completed work. A professional with
        #      0 rating and 0 reviews must NEVER outrank someone who
        #      already has ratings/reviews/completed work, no matter what
        #      their weekly activity numbers look like.
        #
        #      🐛 FIX (reported): a professional with 10 real completed
        #      bookings but no review yet (very common — a customer
        #      doesn't always leave a review right after a booking) was
        #      being treated as "unrated" here, same tier as a brand-new
        #      account with 0 bookings/0 rating/0 reviews — since this
        #      section previously required rating > 0 AND ≥1 review to
        #      count as having real marketplace history. Completed
        #      bookings ARE real marketplace history on their own. Now
        #      matches Popular Professionals' rule: qualified = has
        #      completed bookings, OR a rating, OR reviews — any one of
        #      the three, not all three.
        #
        #      Fix: rated (has real history) and unrated pools are ranked
        #      SEPARATELY, then concatenated rated-first — so rated
        #      professionals always occupy the first slots, and unrated
        #      professionals only fill in remaining capacity. This still
        #      solves cold-start (section is never empty) without ever
        #      letting an unrated account outrank a rated one.
        #
        #      Trending Score (rated pool's primary sort key) uses exactly
        #      the 5 weekly signals from spec: weekly completed bookings,
        #      weekly profile views, weekly customer inquiries, weekly
        #      favorites/saves, weekly reviews.
        #
        #      Rated sort priority (highest first):
        #        1. Trending Score  2. Average Rating
        #        3. Number of Reviews  4. Completed Bookings
        #        5. Verified Status (small tie-break only, listed last)
        #
        #      Unrated fallback sort priority (highest first) — quality
        #      signals only, per spec, since there's no rating/reviews to
        #      go on yet:
        #        1. Profile Completion  2. Verified Status
        #        3. Completed Bookings  4. Profile Views
        #        5. Favorites  6. Recent activity (this week's signals)
        try:
            def trending_score(p):
                return (
                    p['bookings_this_week']      * 5
                    + p['views_this_week']       * 0.5
                    + p['inquiries_this_week']   * 1.5
                    + p['favorites_this_week']   * 2
                    + p['reviews_this_week']     * 3
                )

            trending_rated = [
                p for p in all_pros
                if p['completed_jobs'] > 0 or p['average_rating'] > 0 or p['reviews_count'] > 0
            ]
            trending_rated_ids = {p['id'] for p in trending_rated}
            trending_unrated = [p for p in all_pros if p['id'] not in trending_rated_ids]

            trending_rated_sorted = sorted(trending_rated, key=lambda p: (
                trending_score(p),
                p['average_rating'],
                p['reviews_count'],
                p['completed_jobs'],
                bool(p.get('is_verified')),   # small tie-break only — never the primary key
            ), reverse=True)

            trending_unrated_sorted = sorted(trending_unrated, key=lambda p: (
                p.get('profile_complete', 0),
                bool(p.get('is_verified')),
                p['completed_jobs'],
                p.get('profile_views_count', 0) or 0,
                p.get('favorites_count', 0) or 0,
                trending_score(p),
            ), reverse=True)

            # Rated professionals ALWAYS occupy the first slots — unrated
            # ones only fill in whatever capacity is left. This is what
            # guarantees "4 rated + 20 unrated" always shows the 4 rated
            # ones first, per spec's Expected Behaviour example.
            trending = (trending_rated_sorted + trending_unrated_sorted)[:self.SECTION_CAP_10]
        except Exception:
            logger.exception('[home] Trending section failed independently — other sections unaffected')
            trending = []

        # ── 5) Recently Added — up to 10 newest accounts, nationwide,
        #      its own independent sort (account creation date, newest
        #      first) — never derived from the nearby/location list.
        #
        #      🐛 FIX: previously had NO 30-day window — any professional,
        #      no matter how old their account, could show up here as long
        #      as they ranked in the top 10 by creation date (which, on a
        #      young platform with <10 professionals total, meant everyone
        #      showed up regardless of how "recent" they actually were).
        #      Now: only accounts created in the last 30 days are eligible
        #      at all; if fewer than 10 qualify, fewer than 10 are shown —
        #      no backfill with older accounts. ─────────────────────────
        try:
            recently_added_cutoff = now - timedelta(days=30)
            recently_added_eligible = [
                p for p in all_pros
                if p.get('created_at') and p['created_at'] >= recently_added_cutoff.isoformat()
            ]
            # 🐛 FIX (regression root cause): same used_ids-starvation bug
            # as Top Rated — Recently Added ran even later than Top Rated
            # (after Nearby, Recommended, AND Top Rated had all already
            # claimed ids), so its `fresh` pool via take() was frequently
            # empty even when genuinely-new professionals existed. Recently
            # Added must be a fully independent global query per spec, so
            # it now ranks directly over its own eligible pool.
            if recently_added_eligible:
                recently_added = sorted(
                    recently_added_eligible, key=lambda p: p.get('created_at') or '', reverse=True
                )[:self.SECTION_CAP_10]
            else:
                # 🐛 FIX: on a young platform where every account is older
                # than 30 days, the strict window hid this section
                # entirely. Fall back to the newest accounts overall
                # (still real, still "most recently added" relative to
                # each other) instead of showing nothing.
                recently_added = sorted(
                    all_pros, key=lambda p: p.get('created_at') or '', reverse=True
                )[:self.SECTION_CAP_10]
            used_ids.update(p['id'] for p in recently_added)
        except Exception:
            logger.exception('[home] Recently Added section failed independently — other sections unaffected')
            recently_added = []

        # ── 6) Popular Professionals — up to 10, GLOBAL (location ignored
        #      completely), its own independent query — never derived from
        #      `nearby`, `top_rated`, `trending`, or any other section's
        #      already-filtered/already-sorted list.
        #
        #      🐛 FIX (rebuilt): the previous version required rating > 0
        #      AND ≥1 review to even be considered "qualified" — but that
        #      meant a professional with real completed bookings and zero
        #      reviews yet (very common right after a booking closes,
        #      before the customer leaves a review) got thrown into the
        #      same 0-signal fallback bucket as a totally new, no-activity
        #      account, and ranked no better than them. A professional
        #      with genuine marketplace history (bookings, rating, OR
        #      reviews — any one of the three) must always outrank a
        #      professional with none of the three, full stop.
        #
        #      Fix: split into a "qualified" pool (has at least one of:
        #      completed bookings, a real rating, or reviews) and an
        #      "unrated" pool (has none of the three), rank each pool
        #      separately, then concatenate qualified-first — exactly the
        #      same rated-always-first pattern as Trending This Week.
        #
        #      Qualified sort priority (highest first), per spec:
        #        1. Completed Bookings (highest weight)  2. Average Rating
        #        3. Total Reviews  4. Profile Views  5. Favorites/Saves
        #        6. Verified Status (small bonus only)  7. Profile Completion
        #
        #      Unrated fallback sort priority (highest first), per spec —
        #      quality/account signals only, since there's no marketplace
        #      history to go on yet:
        #        1. Profile Completion  2. Verified Status
        #        3. Profile Views  4. Favorites  5. Recent activity
        #        6. Account quality (experience years, as a tiebreak)
        try:
            def recent_activity(p):
                return (
                    p.get('bookings_this_week', 0)   * 5
                    + p.get('views_this_week', 0)     * 0.5
                    + p.get('inquiries_this_week', 0) * 1.5
                    + p.get('favorites_this_week', 0) * 2
                    + p.get('reviews_this_week', 0)   * 3
                )

            popular_qualified = [
                p for p in all_pros
                if p['completed_jobs'] > 0 or p['average_rating'] > 0 or p['reviews_count'] > 0
            ]
            qualified_ids = {p['id'] for p in popular_qualified}
            popular_unrated = [p for p in all_pros if p['id'] not in qualified_ids]

            popular_qualified_sorted = sorted(popular_qualified, key=lambda p: (
                p['completed_jobs'],
                p['average_rating'],
                p['reviews_count'],
                p.get('profile_views_count', 0) or 0,
                p.get('favorites_count', 0) or 0,
                bool(p.get('is_verified')),        # small bonus only — never a primary key
                p.get('profile_complete', 0),
            ), reverse=True)

            popular_unrated_sorted = sorted(popular_unrated, key=lambda p: (
                p.get('profile_complete', 0),
                bool(p.get('is_verified')),
                p.get('profile_views_count', 0) or 0,
                p.get('favorites_count', 0) or 0,
                recent_activity(p),
                p.get('experience_years', 0) or 0,
            ), reverse=True)

            # Qualified professionals ALWAYS occupy the first slots —
            # unrated ones only fill in whatever capacity is left. This is
            # what guarantees a 0-rated/0-activity professional can never
            # outrank someone with real bookings/ratings/reviews, per the
            # spec's Expected Behaviour example (A, B, C always before D).
            popular = (popular_qualified_sorted + popular_unrated_sorted)[:self.SECTION_CAP_10]
            used_ids.update(p['id'] for p in popular)
        except Exception:
            logger.exception('[home] Popular Professionals section failed independently — other sections unaffected')
            popular = []

        return Response({
            'recommended':           recommended,
            'nearby':                nearby,
            'top_rated':             top_rated,
            'trending':              trending,
            'recently_added':        recently_added,
            'popular_professionals': popular,
            **nearby_location_meta,
        })

    @staticmethod
    def _personalization_signal(user):
        """Category-preference weights from the customer's SearchHistory
        (last 20 queries) and booking history. Bookings count double —
        actually paying for a category is a stronger signal than searching
        for it. Returns (set of category ids, {category_id: weight}).
        Guests (AnonymousUser) simply have no history to query — they get
        an empty signal, which correctly collapses "Recommended For You"
        down to rating + reviews + same-city bonus (see rec_score above)."""
        if not user or not getattr(user, 'is_authenticated', False):
            return set(), {}

        from apps.ai_engine.models import SearchHistory
        from apps.bookings.models import Booking

        weight = {}

        recent_queries = list(
            SearchHistory.objects.filter(user=user)
            .order_by('-created_at').values_list('query', flat=True)[:20]
        )
        if recent_queries:
            for cat in Category.objects.all():
                cat_norm = _normalize(cat.name)
                if not cat_norm:
                    continue
                for q in recent_queries:
                    nq = _normalize(q)
                    if cat_norm in nq or nq in cat_norm:
                        weight[cat.id] = weight.get(cat.id, 0) + 1
                        break

        booked_category_ids = (
            Booking.objects.filter(customer=user)
            .values_list('professional__professionalprofile__category_id', flat=True)
        )
        for cid in booked_category_ids:
            if cid:
                weight[cid] = weight.get(cid, 0) + 2

        return set(weight.keys()), weight


# ─── Favourites ─────────────────────────────────────────────────────────────
# Server-side favourites — see apps/search/models.py:Favorite for why this
# replaces the old device-only SharedPreferences store.

class FavoriteListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        ids = list(
            Favorite.objects.filter(customer=request.user)
            .values_list('professional_id', flat=True)
        )
        return Response({'professional_ids': [str(i) for i in ids]})


class FavoriteToggleView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, professional_id):
        try:
            professional = User.objects.get(id=professional_id, role='professional')
        except User.DoesNotExist:
            return Response({'error': 'Professional not found'}, status=404)

        existing = Favorite.objects.filter(customer=request.user, professional=professional).first()
        if existing:
            existing.delete()
            return Response({'is_favorite': False})

        Favorite.objects.create(customer=request.user, professional=professional)
        return Response({'is_favorite': True})