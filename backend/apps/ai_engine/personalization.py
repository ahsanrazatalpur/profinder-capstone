# apps/ai_engine/personalization.py
#
# Personalization signals — Recent searches, Favourite categories,
# Preferred budget, Frequently contacted professionals — derived from
# each customer's own SearchHistory + Booking records.
#
# Design principles:
#   • SOFT boost only — these signals nudge ranking, they never filter out
#     a result. A customer with zero history gets zero boost, i.e. results
#     look exactly like they did before personalization existed.
#   • Guests (unauthenticated) always get {} — no behaviour change.
#   • Any failure (Booking model shape changes, missing relation, etc.)
#     degrades to "no personalization" rather than breaking search.
#
# Used by BOTH apps/search/views.py (Normal Search) and
# apps/ai_engine/views.py (AI Search) so personalization is consistent
# across both endpoints.

from datetime import timedelta
from django.utils import timezone

from apps.ai_engine.models import SearchHistory

# How far back to look for "recent searches" signal.
_RECENT_SEARCH_DAYS  = 30
_RECENT_SEARCH_LIMIT = 20

# A professional counts as "frequently contacted" once the customer has
# booked them this many times (any status — repeat intent is the signal,
# not necessarily a completed job).
_FREQUENT_CONTACT_THRESHOLD = 2

# Ranking boosts (points) — kept modest relative to the core relevance
# score (see apps/search/views.py `_relevance_score`, which ranges into the
# hundreds) so personalization nudges order without overriding a genuinely
# better keyword/location match.
BOOST_FAVOURITE_CATEGORY = 15.0
BOOST_FREQUENT_PRO       = 25.0
BOOST_PREFERRED_BUDGET   = 8.0
BOOST_RECENT_SEARCH_TERM = 5.0

# Preferred-budget match tolerance — professional's hourly_rate within this
# fraction of the customer's own historical average booking rate.
_BUDGET_MATCH_TOLERANCE = 0.30


def _get_booking_model():
    """Lazy import — avoids any circular-import risk with apps.bookings."""
    from apps.bookings.models import Booking
    return Booking


def get_personalization_profile(user) -> dict:
    """
    Returns what we know about this customer's preferences, or {} for
    guests / brand-new users with no history yet:

    {
        'favourite_category_ids':       {3, 7},              # top booked categories
        'frequently_contacted_pro_ids': {'12', '45'},          # repeat-booked professional user ids (as str)
        'preferred_budget_avg':         1800.0,                # avg hourly_rate across past bookings
        'recent_search_terms':          {'dentist', 'plumber'},# words from last 20 searches (30 days)
    }
    """
    if not user or not getattr(user, 'is_authenticated', False):
        return {}

    profile = {}

    # ── Recent searches ─────────────────────────────────────────────────
    try:
        cutoff = timezone.now() - timedelta(days=_RECENT_SEARCH_DAYS)
        recent_qs = (
            SearchHistory.objects
            .filter(user=user, created_at__gte=cutoff)
            .order_by('-created_at')[:_RECENT_SEARCH_LIMIT]
        )
        terms = set()
        for h in recent_qs:
            terms.update((h.query or '').lower().split())
        terms.discard('')
        if terms:
            profile['recent_search_terms'] = terms
    except Exception:
        pass

    # ── Favourite categories / frequently contacted / preferred budget ──
    # All three derived from the same booking history in one pass.
    try:
        Booking = _get_booking_model()
        bookings_qs = (
            Booking.objects
            .filter(customer=user)
            .select_related('professional__professionalprofile__category')
        )

        cat_counts = {}
        pro_counts = {}
        rates = []

        for b in bookings_qs:
            pro = getattr(b, 'professional', None)
            if not pro:
                continue
            pro_id = str(pro.id)
            pro_counts[pro_id] = pro_counts.get(pro_id, 0) + 1
            try:
                prof = pro.professionalprofile
                if prof.category_id:
                    cat_counts[prof.category_id] = cat_counts.get(prof.category_id, 0) + 1
                if prof.hourly_rate:
                    rates.append(float(prof.hourly_rate))
            except Exception:
                continue

        if cat_counts:
            top_cats = sorted(cat_counts.items(), key=lambda x: -x[1])[:3]
            profile['favourite_category_ids'] = {cat_id for cat_id, _ in top_cats}

        frequent = {pid for pid, count in pro_counts.items() if count >= _FREQUENT_CONTACT_THRESHOLD}
        if frequent:
            profile['frequently_contacted_pro_ids'] = frequent

        if rates:
            profile['preferred_budget_avg'] = sum(rates) / len(rates)
    except Exception:
        # Booking app/model not available or shape differs — no personalization,
        # not an error. Search must keep working either way.
        pass

    return profile


def personalization_boost(result_data: dict, profile: dict) -> float:
    """
    Small additive ranking boost (points) for ONE professional's result
    dict (as built by `_build_professional_data`), given the customer's
    personalization profile. Purely additive — a professional who doesn't
    match any signal gets +0, so results are unaffected for customers
    without a matching history.
    """
    if not profile:
        return 0.0

    boost = 0.0

    # ── Favourite category ───────────────────────────────────────────────
    fav_cats = profile.get('favourite_category_ids')
    if fav_cats and result_data.get('category_id') in fav_cats:
        boost += BOOST_FAVOURITE_CATEGORY

    # ── Frequently contacted (booked 2+ times before) ───────────────────
    frequent_ids = profile.get('frequently_contacted_pro_ids')
    if frequent_ids and result_data.get('id') in frequent_ids:
        boost += BOOST_FREQUENT_PRO

    # ── Preferred budget (within tolerance of historical avg rate) ──────
    avg_budget = profile.get('preferred_budget_avg')
    rate = result_data.get('hourly_rate')
    if avg_budget and rate is not None and avg_budget > 0:
        diff_ratio = abs(rate - avg_budget) / avg_budget
        if diff_ratio <= _BUDGET_MATCH_TOLERANCE:
            boost += BOOST_PREFERRED_BUDGET

    # ── Recent search terms (loose overlap with category/specialization) ──
    recent_terms = profile.get('recent_search_terms')
    if recent_terms:
        haystack_words = set(
            ' '.join(filter(None, [
                (result_data.get('category_name') or '').lower(),
                (result_data.get('specialization') or '').lower(),
            ])).split()
        )
        if recent_terms & haystack_words:
            boost += BOOST_RECENT_SEARCH_TERM

    return boost