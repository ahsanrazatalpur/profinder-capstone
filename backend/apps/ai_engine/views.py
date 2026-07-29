# apps/ai_engine/views.py

from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.conf import settings
from django.core.cache import cache
from dotenv import dotenv_values
from datetime import date
from google import genai
from google.genai import types as genai_types
import os

from apps.ai_engine.models import AIRecommendation, SearchHistory
from apps.ai_engine.personalization import get_personalization_profile, personalization_boost
from apps.ai_engine.serializers import AIRecommendationSerializer, SearchHistorySerializer
from apps.profiles.models import UserProfile
from apps.users.models import User
from apps.search.views import (
    _build_professional_data, _normalize, _expand_query, _correct_typo,
    SEARCH_VOCABULARY, SYNONYM_MAP, ABBREVIATIONS, _haversine_km,
)
from apps.subscriptions.utils import (
    check_ai_search_allowed,
    is_premium,
    get_active_subscription,
    get_ai_search_reset_at,
)
import json
import re
from django.db.models import Count, Q as DQ

env = dotenv_values(os.path.join(settings.BASE_DIR, '.env'))


# ─── Natural-language intent extraction ───────────────────────────────────────
# Turns a free-text query into structured intent across 10 dimensions —
# Profession, Budget, Location, Availability, Experience, Gender, Distance,
# Ratings, Language, Verification — automatically, without ever asking the
# user a clarifying question. "Need cheap lawyer" becomes
# {profession: [lawyer, attorney, ...], max_budget-style cheap: True}, not a
# literal search for the words "need"/"cheap"/"lawyer".

_PRICE_CHEAP_PHRASES = [
    'cheap', 'affordable', 'budget', 'low cost', 'low-cost', 'inexpensive',
    'low price', 'economical', 'cheapest', 'reasonable price', 'reasonably priced',
    # Roman Urdu / Urdu
    'sasta', 'sasti', 'saste', 'kam paisay', 'kam paise', 'kifayati', 'سستا', 'سستی',
]
_URGENCY_PHRASES = [
    'today', 'right now', 'now', 'asap', 'urgent', 'urgently',
    'immediately', 'right away', 'emergency', 'this instant',
    # Roman Urdu / Urdu
    'aaj', 'abhi', 'foran', 'jaldi', 'ابھی', 'آج', 'فوراً',
]
_GENDER_FEMALE_PHRASES = [
    'female', 'woman', 'women', 'lady', 'ladies',
    # Roman Urdu / Urdu
    'larki', 'ladki', 'aurat', 'khatoon', 'khawateen', 'عورت', 'خاتون', 'لڑکی',
]
_GENDER_MALE_PHRASES = [
    'male', 'man ', ' men', 'gentleman',
    # Roman Urdu / Urdu
    'larka', 'ladka', 'aadmi', 'mard', 'مرد', 'آدمی', 'لڑکا',
]
_QUALITY_PHRASES = [
    'best', 'top rated', 'top-rated', 'highly rated', 'excellent', 'finest',
    # Roman Urdu / Urdu
    'acha', 'sab se acha', 'behtareen', 'zabardast', 'بہترین', 'اچھا',
]
_EXPERIENCE_PHRASES = [
    'experienced', 'senior', 'expert', 'veteran', 'skilled', 'years of experience',
    # Roman Urdu / Urdu
    'tajurbekar', 'tajarbakar', 'purana', 'mahir', 'ماہر', 'تجربہ کار',
]
_NEARBY_PHRASES = [
    'near me', 'nearby', 'close by', 'closest', 'near my location', 'around me',
    # Roman Urdu / Urdu
    'qareeb', 'nazdeek', 'paas', 'mere paas', 'قریب', 'نزدیک',
]
_VERIFIED_PHRASES = [
    'verified', 'certified', 'licensed', 'licenced', 'authentic', 'registered', 'legit',
    # Roman Urdu / Urdu
    'tasdeeq shuda', 'tasdeeq shuda hai', 'تصدیق شدہ',
]

# Common languages spoken across Pakistan/India — matched against the
# professional's own `languages` field (comma-separated free text).
_KNOWN_LANGUAGES = [
    'english', 'urdu', 'punjabi', 'sindhi', 'pashto', 'balochi',
    'arabic', 'hindi', 'saraiki', 'kashmiri', 'اردو', 'انگریزی',
]

# "mein"/"me" ("in <city>") and "chahiye"/"mujhe" ("I need") are common
# Roman Urdu sentence connectors — stripped before profession/typo matching
# so they don't get mistaken for meaningful search words (they're not in
# any vocabulary, so they're already harmless noise, but stripping keeps
# the query cleaner for logging/debugging).
_ROMAN_URDU_FILLERS = {'mujhe', 'chahiye', 'chahiy', 'mein', 'me', 'ke', 'liye', 'ka', 'ki', 'ko', 'se'}

# "under 2000", "below $50", "max budget 3000", "$50/hr", "3000 rs"
_BUDGET_RE     = re.compile(
    r'(?:under|below|less than|max(?:imum)?|budget(?:\s+of)?|within)\s*(?:rs\.?|pkr|\$)?\s*(\d+)'
    r'|\$\s*(\d+)'
    r'|(\d+)\s*(?:rs\.?|pkr|rupees)\b'
)
# "5+ years", "5 years experience", "at least 3 years"
_EXPERIENCE_RE = re.compile(r'(\d+)\s*\+?\s*years?\b')
# "within 5km", "5 km radius", "10 miles"
_DISTANCE_RE   = re.compile(r'(\d+)\s*(?:km|kilometers?|kilometres?|miles?)\b')
# "4 star", "4+ rating", "above 4.5 stars", "rating of 4", "rating above 4"
_RATING_RE     = re.compile(
    r'(\d(?:\.\d)?)\s*\+?\s*(?:star|stars|rating)\b'
    r'|rating\s*(?:of|above|over|at least)?\s*(\d(?:\.\d)?)'
)


def _contains_any(text: str, phrases) -> bool:
    return any(p in text for p in phrases)


def _first_match_float(pattern, text):
    m = pattern.search(text)
    if not m:
        return None
    for g in m.groups():
        if g:
            return float(g)
    return None


def _extract_intent(query: str, known_cities=None) -> dict:
    """
    Automatically detects, purely from free text — no clarifying questions:
      profession_terms   — profession/category words (typo/synonym-aware)
      max_budget          — numeric price ceiling, e.g. "under 2000" → 2000.0
      wants_cheap         — soft price preference ("cheap"/"affordable"/...)
                            used only when no explicit number was given
      city                — a known city name mentioned in the query
      wants_urgent        — "today"/"now"/"asap"/... → available right now
      min_experience      — numeric years, e.g. "5+ years" → 5.0
      wants_experienced   — soft preference ("experienced"/"senior"/...)
                            used only when no explicit number was given
      gender              — 'female' / 'male' / None
      wants_nearby         — "near me"/"nearby"/... (needs customer GPS)
      max_distance_km      — numeric radius, e.g. "within 5km" → 5.0
      min_rating           — numeric threshold, e.g. "4+ stars" → 4.0
      wants_top_rated      — soft preference ("best"/"top rated"/...)
                            used only when no explicit number was given
      language             — a known language mentioned, e.g. "urdu speaking"
      wants_verified        — "verified"/"certified"/"licensed"/...
    """
    q = f' {_normalize(query)} '   # padded so ' men'/' man ' phrase checks are safe

    # ── Profession detection — reuse Normal Search's vocabulary engine ────
    corrected, _ = _correct_typo(_normalize(query))
    profession_terms = set()
    for word in set(_normalize(query).split()) | set(corrected.split()):
        if word in SEARCH_VOCABULARY or word in SYNONYM_MAP or word in ABBREVIATIONS:
            profession_terms.update(_expand_query(word))
    profession_terms.update(_expand_query(_normalize(query)))
    profession_terms.discard(_normalize(query))

    # ── Location — a known city mentioned anywhere in the query ───────────
    city = None
    if known_cities:
        city = next((c for c in known_cities if c and c.strip().lower() in q), None)

    # ── Language — a recognized language name mentioned ───────────────────
    language = next((lang for lang in _KNOWN_LANGUAGES if lang in q), None)

    return {
        'profession_terms':  sorted(profession_terms),
        'max_budget':        _first_match_float(_BUDGET_RE, q),
        'wants_cheap':       _contains_any(q, _PRICE_CHEAP_PHRASES),
        'city':              city,
        'wants_urgent':      _contains_any(q, _URGENCY_PHRASES),
        'min_experience':    _first_match_float(_EXPERIENCE_RE, q),
        'wants_experienced': _contains_any(q, _EXPERIENCE_PHRASES),
        'gender':            ('female' if _contains_any(q, _GENDER_FEMALE_PHRASES)
                               else 'male' if _contains_any(q, _GENDER_MALE_PHRASES)
                               else None),
        'wants_nearby':      _contains_any(q, _NEARBY_PHRASES),
        'max_distance_km':   _first_match_float(_DISTANCE_RE, q),
        'min_rating':        _first_match_float(_RATING_RE, q),
        'wants_top_rated':   _contains_any(q, _QUALITY_PHRASES),
        'language':          language,
        'wants_verified':    _contains_any(q, _VERIFIED_PHRASES),
    }


# ─── AI Search Status (no search consumed) ────────────────────────────────────

class AISearchStatusView(APIView):
    """
    GET — sirf current usage/limit batata hai, koi search consume nahi karta.
    Flutter screen load hote hi ye call karega taake "X left" hamesha
    sahi/up-to-date dikhe — purana search karne tak wait nahi karna padega.
    """
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


# ─── AI Search ────────────────────────────────────────────────────────────────

# ─── Persist AIRecommendation rows ─────────────────────────────────────────
# AIRecommendationView.get() reads from this table — without writing to it
# somewhere, that endpoint always returns []. This upserts the top results
# of each AI Search so a customer's /recommendations/ reflects real,
# recent matches rather than being permanently empty.
def _persist_ai_recommendations(user, items, cap=10):
    for item in (items or [])[:cap]:
        try:
            pro_id = int(item.get('id'))
        except (TypeError, ValueError):
            continue

        raw_score = item.get('ai_confidence') or item.get('relevance_score') or 0
        try:
            score = max(0.0, min(float(raw_score), 999.99))  # fits DecimalField(5,2)
        except (TypeError, ValueError):
            score = 0.0

        reason = (item.get('ai_reason') or item.get('recommendation_reason') or 'Matched your search')[:500]

        try:
            AIRecommendation.objects.update_or_create(
                user=user, professional_id=pro_id,
                defaults={'score': score, 'reason': reason},
            )
        except Exception:
            # Never let a recommendation-logging failure break the search response.
            continue


class AISearchView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        query = request.data.get('query', '').strip()
        if not query:
            return Response({'error': 'query field is required.'}, status=400)

        # ── Guest — AI nahi ──────────────────────────────────────────────
        if not request.user.is_authenticated:
            return Response({
                'ai_used':  False,
                'message':  'Please login to use AI Search.',
                'results':  [],
                'upgrade':  False,
            }, status=status.HTTP_401_UNAUTHORIZED)

        # ── Limit check — DB se ──────────────────────────────────────────
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

        # ── Search history save karo ─────────────────────────────────────
        SearchHistory.objects.create(user=request.user, query=query)

        # ── Personalization profile (favourite categories, frequently
        #    contacted professionals, preferred budget, recent searches) ──
        # Derived from THIS customer's own history. Guests never reach this
        # line (401 above), and brand-new customers with no history simply
        # get {} — zero ranking change, same as before personalization.
        personalization_profile = get_personalization_profile(request.user)

        # ── Professionals fetch karo ─────────────────────────────────────
        # ✅ FIX 1: Pehle SAARE users (customers samet) chale jaate the AI ko —
        # ab sirf actual professionals (role='professional') bhejte hain.
        # ✅ FIX 2: pro_list[:10] / pro_list[:20] slicing ki wajah se agar
        # user ka direct-match professional list mein neeche (DB order mein
        # baad mein) tha, toh woh AI ko bheja hi nahi jaata tha — AI sirf
        # unhi logon mein se fuzzy-match karta jo usse mile the, result:
        # exact-naam wala professional kabhi dikhta hi nahi tha.
        # Ab pehle naam-match wale professionals ko upar laate hain taake
        # woh hamesha AI tak pahunchein, chahe DB mein kahin bhi hon.
        # PERF: capped + pre-ordered so we never Python-process an unbounded
        # number of rows as the platform grows — verified/highly-rated
        # professionals are kept first, so truncation doesn't drop the
        # candidates most likely to matter anyway. 500 comfortably covers
        # even a single profession in a big city; the DB does the ordering,
        # not Python.
        professionals = UserProfile.objects.select_related(
            'user', 'user__professionalprofile', 'user__professionalprofile__category'
        ).filter(user__role='professional').annotate(
            completed_jobs_count=Count(
                'user__bookings_received',
                filter=DQ(user__bookings_received__status='completed'),
                distinct=True,
            )
        ).order_by(
            '-user__professionalprofile__is_verified',
            '-user__professionalprofile__average_rating',
        )[:500]

        query_lower = query.strip().lower()

        def name_of(pro):
            return (pro.full_name or pro.user.name or '').strip()

        # PERF: this used to be a fresh DISTINCT scan over the whole
        # UserProfile table on every single AI search request just to
        # recognize city names in the query. Cities change rarely, so we
        # cache the set for 10 minutes instead — cuts one full-table query
        # per request down to roughly once every 10 minutes across all users.
        known_cities = cache.get('ai_search_known_cities')
        if known_cities is None:
            known_cities = set(
                UserProfile.objects.exclude(city__isnull=True)
                .exclude(city__exact='')
                .values_list('city', flat=True)
                .distinct()
            )
            cache.set('ai_search_known_cities', known_cities, timeout=600)

        # ── Natural-language intent extraction ─────────────────────────────
        # Auto-detects Profession, Budget, Location, Availability, Experience,
        # Gender, Distance, Ratings, Language, Verification — no clarifying
        # questions asked. Each filter degrades gracefully: if honoring it
        # would empty the pool, we drop that one filter (flagging it) rather
        # than showing zero results.
        intent = _extract_intent(query, known_cities=known_cities)
        intent_notes  = []   # human-readable, shown to Gemini + returned to app
        unmet_intents = []   # filters that couldn't be honored (pool would be empty)

        # Optional customer GPS — needed only for the Distance dimension.
        # Sent by the app the same way Normal Search does; harmless if absent.
        try:
            customer_lat = float(request.data.get('latitude'))  if request.data.get('latitude')  else None
            customer_lng = float(request.data.get('longitude')) if request.data.get('longitude') else None
        except (TypeError, ValueError):
            customer_lat = customer_lng = None

        requested_city = intent['city']

        if requested_city:
            city_filtered = [
                p for p in professionals
                if (p.city or '').strip().lower() == requested_city.strip().lower()
            ]
        else:
            city_filtered = list(professionals)

        # Agar requested city mein koi professional nahi mila, to poori list
        # pe fallback karte hain (taake result bilkul khaali na ho) — lekin
        # flag rakhte hain taake frontend/response mein clearly bataya ja
        # sake ke ye exact-city match nahi hai.
        city_fallback_used = requested_city is not None and len(city_filtered) == 0
        search_pool = city_filtered if city_filtered else list(professionals)
        if requested_city and not city_fallback_used:
            intent_notes.append(f"location: {requested_city}")

        def _prof(pro):
            try:
                return pro.user.professionalprofile
            except Exception:
                return None

        def _matches_profession(pro, terms):
            prof = _prof(pro)
            if not prof:
                return False
            haystack = _normalize(' '.join(filter(None, [
                prof.category.name if prof.category else '',
                prof.specialization, prof.skills, prof.services, prof.tags,
            ])))
            return any(t in haystack for t in terms)

        # Profession/category intent (reuses Normal Search's vocabulary engine)
        if intent['profession_terms']:
            terms = intent['profession_terms']
            filtered = [p for p in search_pool if _matches_profession(p, terms)]
            if filtered:
                search_pool = filtered
                intent_notes.append(f"profession: {', '.join(terms[:4])}")
            else:
                unmet_intents.append('profession')

        # Gender intent
        if intent['gender']:
            filtered = [p for p in search_pool if (p.gender or '').lower() == intent['gender']]
            if filtered:
                search_pool = filtered
                intent_notes.append(f"gender: {intent['gender']}")
            else:
                unmet_intents.append('gender')

        # Urgency intent — must be available right now
        if intent['wants_urgent']:
            filtered = [p for p in search_pool if getattr(_prof(p), 'is_available', True)]
            if filtered:
                search_pool = filtered
                intent_notes.append('availability: today/now')
            else:
                unmet_intents.append('availability')

        # Language intent — professional's own `languages` field
        if intent['language']:
            lang = intent['language']
            filtered = [p for p in search_pool
                        if lang in _normalize(getattr(_prof(p), 'languages', '') or '')]
            if filtered:
                search_pool = filtered
                intent_notes.append(f"language: {lang}")
            else:
                unmet_intents.append('language')

        # Verification intent — "verified"/"certified"/"licensed"
        if intent['wants_verified']:
            filtered = [p for p in search_pool if getattr(_prof(p), 'is_verified', False)]
            if filtered:
                search_pool = filtered
                intent_notes.append('verification: verified only')
            else:
                unmet_intents.append('verification')

        # Budget — explicit number ("under 2000") is a hard filter;
        # otherwise "cheap"/"affordable" is a soft preference (sort only).
        def _rate(pro):    return float(getattr(_prof(pro), 'hourly_rate', 0) or 0)
        def _rating(pro):  return float(getattr(_prof(pro), 'average_rating', 0) or 0)
        def _exp(pro):     return int(getattr(_prof(pro), 'experience_years', 0) or 0)

        if intent['max_budget'] is not None:
            filtered = [p for p in search_pool if _rate(p) <= intent['max_budget']]
            if filtered:
                search_pool = filtered
                intent_notes.append(f"budget: under {intent['max_budget']:.0f}")
            else:
                unmet_intents.append('budget')

        # Experience — explicit number ("5+ years") is a hard filter;
        # otherwise "experienced"/"senior" is a soft preference (sort only).
        if intent['min_experience'] is not None:
            filtered = [p for p in search_pool if _exp(p) >= intent['min_experience']]
            if filtered:
                search_pool = filtered
                intent_notes.append(f"experience: {intent['min_experience']:.0f}+ years")
            else:
                unmet_intents.append('experience')

        # Ratings — explicit number ("4+ stars") is a hard filter;
        # otherwise "best"/"top rated" is a soft preference (sort only).
        if intent['min_rating'] is not None:
            filtered = [p for p in search_pool if _rating(p) >= intent['min_rating']]
            if filtered:
                search_pool = filtered
                intent_notes.append(f"rating: {intent['min_rating']:.1f}+ stars")
            else:
                unmet_intents.append('rating')

        # Distance — needs customer GPS; "within 5km" is a hard filter,
        # "near me"/"nearby" is a soft preference (sort by distance only).
        def _dist(pro):
            if customer_lat is None or customer_lng is None or pro.latitude is None or pro.longitude is None:
                return None
            return _haversine_km(customer_lat, customer_lng, float(pro.latitude), float(pro.longitude))

        if customer_lat is not None and customer_lng is not None:
            if intent['max_distance_km'] is not None:
                filtered = [p for p in search_pool
                            if _dist(p) is not None and _dist(p) <= intent['max_distance_km']]
                if filtered:
                    search_pool = sorted(filtered, key=lambda p: _dist(p))
                    intent_notes.append(f"distance: within {intent['max_distance_km']:.0f}km")
                else:
                    unmet_intents.append('distance')
            elif intent['wants_nearby']:
                with_dist = [p for p in search_pool if _dist(p) is not None]
                if with_dist:
                    search_pool = sorted(with_dist, key=lambda p: _dist(p))
                    intent_notes.append('distance: nearest first')
        elif intent['wants_nearby'] or intent['max_distance_km'] is not None:
            unmet_intents.append('distance')   # no GPS available to honor this

        # Price / rating / experience SOFT preferences — sort, don't filter,
        # and only when no explicit number was already applied above.
        if intent['wants_cheap'] and intent['max_budget'] is None:
            search_pool = sorted(search_pool, key=_rate)
            intent_notes.append('preference: lowest price first')
        elif (intent['wants_top_rated'] or intent['wants_experienced']) and \
             intent['min_rating'] is None and intent['min_experience'] is None:
            search_pool = sorted(search_pool, key=lambda p: (-_rating(p), -_exp(p)))
            intent_notes.append('preference: highest rated / most experienced first')

        # ── Availability fallback — never show an all-unavailable page ─────
        # If every professional currently matching the request happens to
        # be unavailable right now, don't just show a wall of "not
        # available" cards (or nothing). Pivot to the nearest professionals
        # who ARE available — same profession first if one was detected,
        # sorted by real distance when we have the customer's GPS.
        availability_fallback_used    = False
        availability_fallback_message = ''

        if search_pool and not any(getattr(_prof(p), 'is_available', True) for p in search_pool):
            terms = intent['profession_terms']
            candidates = (
                [p for p in professionals if _matches_profession(p, terms)] if terms
                else list(professionals)
            )
            available_candidates = [p for p in candidates if getattr(_prof(p), 'is_available', True)]

            if available_candidates:
                if customer_lat is not None and customer_lng is not None:
                    available_candidates.sort(
                        key=lambda p: (_dist(p) if _dist(p) is not None else float('inf'))
                    )
                    availability_fallback_message = (
                        'No one matching your request is available right now — '
                        'showing the nearest available professionals instead.'
                    )
                else:
                    available_candidates.sort(key=lambda p: -_rating(p))
                    availability_fallback_message = (
                        'No one matching your request is available right now — '
                        'showing available professionals instead.'
                    )
                search_pool = available_candidates
                availability_fallback_used = True
                intent_notes.append('availability fallback: nearest available shown')
            else:
                # Truly nobody is available anywhere (rare) — still never
                # blank the page; keep the original (unavailable) matches
                # so the person can at least see who exists and message them.
                availability_fallback_used = True
                availability_fallback_message = (
                    'No professionals are currently available — showing the best '
                    'matches anyway so you can reach out for later.'
                )

        # ── Smartest ranking — deterministic, priority-ordered ─────────────
        # Strictly decreasing weight bands enforce the priority order itself
        # (each tier's max score is below the tier above it's minimum
        # meaningful contribution), same pattern Normal Search uses:
        #   1. Intent Match      0-200   (how well already-applied intent
        #                                 sorts/filters rank this candidate)
        #   2. Profession Match  0-180   (category/skills/tags/services)
        #   3. Specialization    0-160   (specialization field specifically)
        #   4. Nearest           0-140   (real GPS distance, if available)
        #   5. Verified            120   (flat bonus)
        #   6. Highest Rating    0-100   (rating × 20)
        #   7. Availability        80    (flat bonus)
        #   8. Experience         0-60   (capped at 15 years)
        #   9. Popularity          0-40  (completed jobs, capped at 20)
        #  10. Response Time      0-20   (faster = higher)
        pool_size = max(len(search_pool), 1)
        intent_rank = {id(p): i for i, p in enumerate(search_pool)}  # already intent-sorted above

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

            # 0. Exact name match — what the user literally typed always
            #    wins outright, above all 10 priority tiers below. This
            #    must survive Gemini's own (non-deterministic) output order,
            #    so it's baked into the score itself, not just pool ordering.
            if query_lower and query_lower in _normalize(name_of(pro)):
                score += 1000.0

            # 1. Intent Match — position within the already intent-sorted
            #    pool (nearest/cheapest/top-rated first, per detected intent)
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

            # 4. Nearest
            d = _dist(pro)
            if d is not None:
                score += max(0.0, 140.0 - d * 1.4)   # 140 at 0km → 0 at 100km+

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

            # 9. Popularity (completed jobs)
            score += min(getattr(pro, 'completed_jobs_count', 0) or 0, 20) * 2

            # 10. Response Time
            resp_hrs = getattr(prof, 'response_time_hrs', 24.0) or 24.0
            score += max(0.0, 20.0 - resp_hrs * 0.83)

            # 11. Personalization — favourite categories / frequently booked /
            #     preferred budget / recent searches, from THIS customer's
            #     own history. Soft additive boost only (see
            #     apps.ai_engine.personalization) — customers with no
            #     history get +0 here, so ranking is unaffected for them.
            if personalization_profile and prof:
                score += personalization_boost({
                    'id':             str(pro.user_id),
                    'category_id':    prof.category_id,
                    'category_name':  prof.category.name if prof.category else '',
                    'specialization': getattr(prof, 'specialization', ''),
                    'hourly_rate':    float(getattr(prof, 'hourly_rate', 0) or 0),
                }, personalization_profile)

            return score

        # Exact name match still wins outright — it's literally what the
        # person typed — but within that group (and the rest), everything
        # is now ranked by the full priority-ordered score above.
        # PERF: score every candidate exactly once and reuse the same dict
        # for sorting here AND for the final Gemini-independent re-sort
        # below — this used to call the (non-trivial) _rank_score twice
        # per candidate.
        rank_score_by_pro_id = {id(p): _rank_score(p) for p in search_pool}

        name_matches  = sorted(
            [p for p in search_pool if query_lower in name_of(p).lower()],
            key=lambda p: rank_score_by_pro_id[id(p)], reverse=True,
        )
        other_pros    = sorted(
            [p for p in search_pool if query_lower not in name_of(p).lower()],
            key=lambda p: rank_score_by_pro_id[id(p)], reverse=True,
        )

        ordered_pros = name_matches + other_pros

        # Enriched candidate strings — price/gender/rating/availability are
        # now visible to Gemini, so "cheap"/"female"/"today" reasoning is
        # grounded in real data instead of being guessed from the name alone.
        pro_list = [
            f"Name: {name_of(pro)}, City: {pro.city}, Rate: ${_rate(pro):.0f}/hr, "
            f"Rating: {_rating(pro):.1f}/5, Gender: {pro.gender or 'unspecified'}, "
            f"Available: {'yes' if getattr(_prof(pro), 'is_available', True) else 'no'}, "
            f"Experience: {_exp(pro)}yrs"
            for pro in ordered_pros
        ]

        # ── Premium vs Free AI prompt ─────────────────────────────────────
        # ✅ FIX: Pehle AI sirf FREE TEXT return karta tha ("**Dr. Ahmed
        # Khan** | reason..."), jisko Flutter ek plain Text widget mein
        # dikhata tha — koi professional id na hone ki wajah se tap/click
        # karna possible hi nahi tha. Ab AI se STRICT JSON maangte hain
        # (professional_name + reason), phir us naam se humara apna DB
        # record dhoond ke uska poora structured object (id, photo, rating
        # waghera) frontend ko bhejte hain — taake card tap karke seedha
        # us professional ki detail screen par jaaya ja sake.
        user_is_premium = is_premium(request.user)
        top_n = 5 if user_is_premium else 3
        pro_slice = pro_list[:20] if user_is_premium else pro_list[:10]

        intent_summary = (
            f"Detected intent — {'; '.join(intent_notes)}." if intent_notes
            else "No specific price/gender/urgency/rating intent detected — rank by general relevance."
        )

        prompt = f"""
You are ProFinder's AI assistant. You understand natural language requests,
not just keywords — e.g. "Need cheap lawyer" means profession=lawyer AND
prefers a lower hourly rate; "Need tutor today" means profession=tutor AND
must be available now; "Need female dentist" means profession=dentist AND
gender=female.

You also understand MEANING behind problems/symptoms, mapping them to the
correct profession even if the profession is never named — e.g. "heart
pain" → Cardiologist, "tooth pain" → Dentist, "pipe leak" → Plumber,
"house wiring" → Electrician, "legal notice" → Lawyer, "broken laptop" →
Computer Technician. Apply this same reasoning to any similar problem
phrase in the query, even ones not listed here.

User is searching for: "{query}"
{intent_summary}

Available professionals (already filtered/sorted to match the detected
intent, if any — each with real rate/rating/gender/availability/experience):
{', '.join(pro_slice)}

IMPORTANT: If any professional's name contains or closely matches the
search query "{query}" (exact or near-exact match), they MUST be ranked
first/highest — exact name matches always outrank everything else.

Only rank professionals from the list above using their ACTUAL listed
attributes — do not invent prices, ratings, or genders, and do not assume
professionals from other cities are relevant; the list has already been
restricted to the right city where applicable.

Rank the top {top_n} most relevant professionals. In "reason", explicitly
reference how they match the user's intent (e.g. "Affordable at $15/hr as
requested", "Available today", "Female dentist as requested").

Respond with ONLY a valid JSON array, no other text, no markdown fences.
Each item must have exactly these keys:
"name" (must exactly match one of the names given above),
"reason" (short 1-2 sentence explanation referencing real attributes),
"confidence" (integer 1-10).

Example format:
[{{"name": "Ahsan Raza", "reason": "Affordable at $15/hr and available today.", "confidence": 10}}]
"""

        # ── Gemini API call ───────────────────────────────────────────────
        ai_result       = None
        ai_error        = None
        matched_pros    = []
        try:
            client = genai.Client(
                api_key=env.get('GEMINI_API_KEY'),
                http_options=genai_types.HttpOptions(timeout=15000),  # ms — never hang the request indefinitely
            )
            response = client.models.generate_content(
                model='models/gemini-flash-latest',
                contents=prompt
            )
            raw_text = response.text or ''

            # AI kabhi-kabhi ```json ... ``` fences laga deta hai — strip karo
            cleaned = raw_text.strip()
            cleaned = re.sub(r'^```json\s*|^```\s*|```$', '', cleaned.strip(), flags=re.MULTILINE).strip()

            ranked = json.loads(cleaned)

            # ── AI ke naam se actual User record dhoondo ──────────────────
            # Naam-by-naam lookup taake exact DB record + id mile, jisse
            # frontend ProfessionalDetailScreen par navigate kar sake.
            name_to_user = {name_of(p): p.user for p in ordered_pros}
            # Gemini sirf WHICH professionals + reasoning text decide karta
            # hai — final DISPLAY ORDER hamesha humare apne deterministic
            # _rank_score se aata hai, taake exact priority order (Intent →
            # Profession → Specialization → Nearest → Verified → Rating →
            # Availability → Experience → Popularity → Response Time)
            # guaranteed rahe, LLM ke output-order pe depend na kare.
            rank_score_by_user_id = {
                str(p.user.id): rank_score_by_pro_id[id(p)] for p in ordered_pros
            }

            for item in ranked:
                ai_name = (item.get('name') or '').strip()
                matched_user = name_to_user.get(ai_name)

                # Exact match na mile to case-insensitive / substring try karo
                if not matched_user:
                    for stored_name, u in name_to_user.items():
                        if stored_name.lower() == ai_name.lower() or ai_name.lower() in stored_name.lower():
                            matched_user = u
                            break

                if matched_user:
                    data = _build_professional_data(matched_user)
                    if data:
                        data['ai_reason']     = item.get('reason', '')
                        data['ai_confidence'] = item.get('confidence', 0)
                        matched_pros.append(data)

            # Re-sort by our deterministic priority score — this is the
            # "smartest ranking" guarantee, independent of Gemini's own
            # (non-deterministic) output ordering.
            matched_pros.sort(
                key=lambda d: rank_score_by_user_id.get(d.get('id'), 0.0),
                reverse=True,
            )

            # Display ke liye human-readable text bhi banate hain (fallback /
            # legacy UI ke liye), lekin asal navigation 'matched_professionals' se hoga
            ai_result = '\n\n'.join(
                f"{p['name']} | {p.get('ai_reason', '')}" for p in matched_pros
            ) or 'No matching professionals found.'

        except Exception as e:
            ai_error  = str(e)
            ai_result = 'AI matching temporarily unavailable.'
            matched_pros = []

        # ── No exact match — never leave the page empty ────────────────────
        # Recommend similar professionals, related professions, trending
        # professionals, and popular nearby professionals — each with an
        # explanation of why it's being suggested.
        recommendations = {}
        if not matched_pros:
            recommendations = _build_ai_recommendations(
                query, intent, professionals, customer_lat, customer_lng,
                personalization_profile,
            )
            if not ai_result or ai_result == 'No matching professionals found.':
                ai_result = (
                    f'No exact match for "{query}" — here are some relevant '
                    f'alternatives instead.'
                )

        remaining = (limit - used - 1) if limit > 0 else None

        # ── Persist top results as AIRecommendation rows ────────────────
        # Matched professionals take priority; if there were none, fall
        # back to the recommendation fallback sections (similar +
        # frequently-booked) so the table still gets meaningful data.
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
            'matched_professionals': matched_pros,   # ✅ NEW — structured + tappable
            'recommendations':       recommendations,  # populated only when matched_professionals is empty
            'ai_used':               True,
            'is_premium_result':     user_is_premium,
            'searches_used':         used + 1,
            'searches_remaining':    remaining,
            'searches_limit':        limit if limit > 0 else None,
            'error_detail':          ai_error,
            'requested_city':        requested_city,
            'city_fallback_used':    city_fallback_used,
            'availability_fallback_used':    availability_fallback_used,
            'availability_fallback_message': availability_fallback_message,
            'detected_intent':       intent_notes,     # e.g. ["profession: lawyer", "preference: lowest price first"]
            'unmet_intent':          unmet_intents,     # e.g. ["gender"] — couldn't honor without emptying results
            'reset_at':              get_ai_search_reset_at().isoformat() if limit > 0 else None,
        })


# ─── "No exact match" recommendations ──────────────────────────────────────
# When AI Search finds nothing that truly matches, this builds 4 explained
# fallback sections so the page is never empty and the person always has
# somewhere to go next.
def _build_ai_recommendations(query, intent, professionals, customer_lat, customer_lng, personalization_profile=None):
    def _prof(pro):
        try:
            return pro.user.professionalprofile
        except Exception:
            return None

    def _mk(pro, reason):
        data = _build_professional_data(pro.user)
        if data:
            data['recommendation_reason'] = reason
        return data

    pro_list = list(professionals)

    # ── 1. Similar professionals — broaden the term set beyond just the
    #    recognized profession words, using every word's own expansion too,
    #    so near-misses still surface with an explanation.
    all_terms = set(intent['profession_terms'])
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

    # ── 2. Related professions — other categories that DO have professionals
    #    (excluding ones already shown above), most-populated first, so the
    #    person sees a genuinely different but plausible alternative.
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

    # ── 3. Trending professionals — most completed jobs on the platform.
    trending = []
    for pro in sorted(pro_list, key=lambda p: -(getattr(p, 'completed_jobs_count', 0) or 0))[:8]:
        jobs = getattr(pro, 'completed_jobs_count', 0) or 0
        if jobs > 0:
            d = _mk(pro, f'Trending — completed {jobs} job{"s" if jobs != 1 else ""} on ProFinder')
            if d:
                trending.append(d)
        if len(trending) >= 5:
            break

    # ── 4. Popular nearby professionals — top-rated + close by (needs GPS).
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

    # ── 5. Frequently booked professionals (personalization) ──────────────
    # Professionals THIS customer has booked 2+ times before — a genuine
    # "you usually go back to them" signal, distinct from platform-wide
    # trending. Empty for guests / customers with no repeat-booking history.
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