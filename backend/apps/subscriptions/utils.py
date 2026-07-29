# apps/subscriptions/utils.py

from django.utils import timezone
from datetime import date


# ─── Plan Fetching ────────────────────────────────────────────────────────────

def get_active_subscription(user):
    """
    User ka active, valid subscription return karta hai.
    Agar nahi mila to None.
    """
    from apps.subscriptions.models import Subscription
    try:
        sub = Subscription.objects.select_related('plan').filter(
            user=user,
            status='active'
        ).latest('start_date')
        if sub.is_valid():
            return sub
        # Expired ho gaya — status update karo
        sub.status = 'expired'
        sub.save(update_fields=['status'])
        return None
    except Exception:
        return None


def get_user_plan(user):
    """
    User ka SubscriptionPlan return karta hai.
    Agar koi active subscription nahi to None return karega.
    Views free default handle karein.
    """
    sub = get_active_subscription(user)
    return sub.plan if sub else None


def get_feature_value(user, key, default=0):
    """
    User ke active plan se kisi feature ki value lo.
    Agar plan nahi / feature nahi — default return karo.

    Usage:
        limit = get_feature_value(user, 'ai_search_limit', default=5)
        bookings = get_feature_value(user, 'booking_limit', default=5)
    """
    plan = get_user_plan(user)
    if plan is None:
        return default
    try:
        feature = plan.features.get(key=key)
        # Type ke hisaab se cast karo
        if feature.feature_type == 'int':
            return feature.as_int()
        if feature.feature_type == 'bool':
            return feature.as_bool()
        return feature.value
    except Exception:
        return default


def is_premium(user):
    """
    User premium plan par hai ya nahi.
    Free plan = False, koi bhi paid plan = True.
    """
    plan = get_user_plan(user)
    if plan is None:
        return False
    return plan.billing != 'free'


# ─── AI Search Limits ─────────────────────────────────────────────────────────

def get_ai_search_limit(user):
    """
    User ka daily AI search limit.
    Free customer default: 5
    Premium customer default: 20
    """
    if not user.is_authenticated:
        return 0  # Guest = AI nahi
    # DB se lo — free plan mein 5, premium mein 20 set hoga
    return get_feature_value(user, 'ai_search_limit', default=5)


def get_ai_search_used_today(user):
    """Aaj ke AI searches count."""
    from apps.ai_engine.models import SearchHistory
    return SearchHistory.objects.filter(
        user=user,
        created_at__date=date.today()
    ).count()


def get_ai_search_reset_at():
    """
    AI search daily limit kab reset hoga — exact UTC timestamp.
    Limit `created_at__date=date.today()` (UTC) pe based hai, isliye
    reset hamesha agle UTC din ki midnight (00:00 UTC) par hota hai.
    """
    from datetime import datetime, time, timedelta
    tomorrow = date.today() + timedelta(days=1)
    return timezone.make_aware(
        datetime.combine(tomorrow, time.min), timezone.UTC
    )


def check_ai_search_allowed(user):
    """
    Returns: (allowed: bool, used: int, limit: int, upgrade_required: bool)
    """
    if not user.is_authenticated:
        return False, 0, 0, False  # Guest

    limit = get_ai_search_limit(user)
    used  = get_ai_search_used_today(user)

    if limit == 0:  # 0 = unlimited (premium)
        return True, used, 0, False

    if used >= limit:
        return False, used, limit, not is_premium(user)

    return True, used, limit, False


# ─── Professional Booking Limits ──────────────────────────────────────────────

def get_booking_limit(professional):
    """
    Professional ka monthly booking limit.
    Free default: 5, Premium: 0 (unlimited)
    """
    return get_feature_value(professional, 'booking_limit', default=5)


def get_bookings_this_month(professional):
    """Is mahine professional ne kitne bookings complete kiye."""
    from apps.bookings.models import Booking
    now = timezone.now()
    return Booking.objects.filter(
        professional=professional,
        status='completed',
        created_at__year=now.year,
        created_at__month=now.month,
    ).count()


def check_booking_limit(professional):
    """
    Returns: (allowed: bool, used: int, limit: int, sub_end_date: str|None)
    """
    limit = get_booking_limit(professional)

    if limit == 0:  # 0 = unlimited
        return True, 0, 0, None

    used = get_bookings_this_month(professional)

    # Subscription end date
    sub = get_active_subscription(professional)
    end_date_str = None
    if sub and sub.end_date:
        end_date_str = sub.end_date.strftime('%d %b %Y')

    if used >= limit:
        return False, used, limit, end_date_str

    return True, used, limit, end_date_str


# ─── Portfolio Limits ─────────────────────────────────────────────────────────

def check_portfolio_limit(professional):
    """
    Returns: (allowed: bool, used: int, limit: int)
    """
    from apps.profiles.models import Portfolio
    limit = get_feature_value(professional, 'portfolio_limit', default=3)

    if limit == 0:  # unlimited
        return True, 0, 0

    used = Portfolio.objects.filter(professional=professional).count()
    return used < limit, used, limit


# ─── Message Limits ───────────────────────────────────────────────────────────

def get_message_limit(user):
    """Daily message send limit. 0 = unlimited."""
    return get_feature_value(user, 'message_send_limit', default=20)


def get_messages_sent_today(user):
    """Aaj bheje gaye messages."""
    # Future: messaging app se count lo
    # Abhi placeholder — messaging module alag banega
    return 0


def check_message_limit(user):
    """Returns: (allowed: bool, used: int, limit: int)"""
    limit = get_message_limit(user)
    if limit == 0:
        return True, 0, 0
    used = get_messages_sent_today(user)
    return used < limit, used, limit


# ─── Search Boost ─────────────────────────────────────────────────────────────

def is_search_boosted(professional):
    """Premium professional search mein upar aata hai."""
    return bool(get_feature_value(professional, 'priority_ranking', default=False))


# ─── Ads Check ───────────────────────────────────────────────────────────────

def should_show_ads(user):
    """Free users ko ads dikhao, premium ko nahi."""
    return bool(get_feature_value(user, 'ads_enabled', default=True))