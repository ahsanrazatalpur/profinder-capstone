# apps/payments/exchange.py

import logging
from decimal import Decimal, ROUND_HALF_UP
from datetime import timedelta
import requests
from django.utils import timezone
from django.conf import settings
from apps.payments.models import ExchangeRateCache

logger = logging.getLogger(__name__)

# Fallback exchange rates against 1 USD (used when offline/tests/rate-limit)
FALLBACK_RATES_USD = {
    'USD': Decimal('1.0'),
    'EUR': Decimal('0.92'),
    'GBP': Decimal('0.79'),
    'PKR': Decimal('278.50'),
    'INR': Decimal('83.40'),
    'AED': Decimal('3.67'),
    'SAR': Decimal('3.75'),
    'CAD': Decimal('1.36'),
    'AUD': Decimal('1.51'),
    'JPY': Decimal('155.20'),
    'CNY': Decimal('7.23'),
}

# ISO 4217 Currencies with display metadata
SUPPORTED_CURRENCIES = {
    'USD': {'name': 'US Dollar', 'symbol': '$', 'decimals': 2},
    'EUR': {'name': 'Euro', 'symbol': '€', 'decimals': 2},
    'GBP': {'name': 'British Pound', 'symbol': '£', 'decimals': 2},
    'PKR': {'name': 'Pakistani Rupee', 'symbol': 'Rs', 'decimals': 2},
    'INR': {'name': 'Indian Rupee', 'symbol': '₹', 'decimals': 2},
    'AED': {'name': 'UAE Dirham', 'symbol': 'AED', 'decimals': 2},
    'SAR': {'name': 'Saudi Riyal', 'symbol': 'SAR', 'decimals': 2},
    'CAD': {'name': 'Canadian Dollar', 'symbol': 'CA$', 'decimals': 2},
    'AUD': {'name': 'Australian Dollar', 'symbol': 'A$', 'decimals': 2},
    'JPY': {'name': 'Japanese Yen', 'symbol': '¥', 'decimals': 0},
    'CNY': {'name': 'Chinese Yuan', 'symbol': '¥', 'decimals': 2},
}

# Country code to primary currency mapping
COUNTRY_CURRENCY_MAP = {
    'US': 'USD',
    'GB': 'GBP',
    'PK': 'PKR',
    'IN': 'INR',
    'AE': 'AED',
    'SA': 'SAR',
    'CA': 'CAD',
    'AU': 'AUD',
    'JP': 'JPY',
    'CN': 'CNY',
    'FR': 'EUR',
    'DE': 'EUR',
    'ES': 'EUR',
    'IT': 'EUR',
}

# Pakistani cities list for location-based currency mapping
PK_CITIES = {
    'badin', 'karachi', 'lahore', 'islamabad', 'rawalpindi', 'faisalabad',
    'multan', 'peshawar', 'quetta', 'gujranwala', 'hyderabad', 'sukkur',
    'larkana', 'sialkot', 'bahawalpur', 'sargodha', 'mirpurkhas', 'sheikhupura',
    'jhang', 'gujrat', 'kasur', 'mardan', 'swat', 'sahiwal', 'okara',
    'wah cantt', 'dera ghazi khan', 'rahim yar khan', 'dadu', 'tando allahyar',
    'tando muhammad khan', 'khairpur', 'shikarpur', 'jacobabad', 'umerkot',
    'sanghar', 'matiari', 'kashmore', 'ghotki', 'abbottabad', 'muzaffargarh',
    'khanewal', 'mandi bahauddin', 'hafizabad', 'kohat', 'daska', 'gojra',
    'bahawalnagar', 'muridke', 'pakpattan', 'tando adam', 'jaranwala',
    'chishtian', 'attock', 'vehari', 'chakwal', 'kamalia', 'ahmedpur east',
    'kot addu', 'wazirabad', 'mansehra', 'layyah', 'swabi', 'chaman', 'taxila',
    'nowshera', 'khushab', 'shahdadkot', 'mianwali', 'lodhran', 'charsadda',
    'gwadar', 'turbat', 'hub', 'khuzdar'
}


def resolve_currency_for_user(country=None, city=None):
    """
    Returns (currency_code, currency_symbol), e.g. ('PKR', 'Rs').
    Detects based on user country or city. Defaults to PKR for Pakistan/local users.
    """
    c_clean = (country or '').strip().upper()
    city_clean = (city or '').strip().lower()

    if c_clean in ('PK', 'PAK', 'PAKISTAN') or city_clean in PK_CITIES:
        return 'PKR', 'Rs'
    if c_clean in ('IN', 'IND', 'INDIA'):
        return 'INR', '₹'
    if c_clean in ('GB', 'UK', 'GBR', 'UNITED KINGDOM', 'ENGLAND'):
        return 'GBP', '£'
    if c_clean in ('AE', 'ARE', 'UAE', 'UNITED ARAB EMIRATES'):
        return 'AED', 'AED'
    if c_clean in ('SA', 'SAU', 'KSA', 'SAUDI ARABIA'):
        return 'SAR', 'SAR'
    if c_clean in ('CA', 'CAN', 'CANADA'):
        return 'CAD', 'CA$'
    if c_clean in ('AU', 'AUS', 'AUSTRALIA'):
        return 'AUD', 'A$'
    if c_clean in ('JP', 'JPN', 'JAPAN'):
        return 'JPY', '¥'
    if c_clean in ('CN', 'CHN', 'CHINA'):
        return 'CNY', '¥'
    if c_clean in ('FR', 'FRA', 'DE', 'DEU', 'GERMANY', 'ES', 'ESP', 'SPAIN', 'IT', 'ITA', 'ITALY', 'EUR', 'EUROPE'):
        return 'EUR', '€'
    if c_clean in ('US', 'USA', 'UNITED STATES', 'AMERICA'):
        return 'USD', '$'

    # ProFinder is a Pakistan-based marketplace platform
    return 'PKR', 'Rs'



def get_base_currency():
    return getattr(settings, 'BASE_SETTLEMENT_CURRENCY', 'USD')


def refresh_exchange_rates(force=False):
    """
    Refreshes exchange rates from external API with DB caching (24-hour TTL).
    Falls back gracefully to fallback table on network timeout or test environments.
    """
    base = get_base_currency()
    now = timezone.now()
    cache_cutoff = now - timedelta(hours=24)

    # Check if existing DB rates are fresh
    if not force:
        fresh_count = ExchangeRateCache.objects.filter(base_currency=base, updated_at__gte=cache_cutoff).count()
        if fresh_count >= len(SUPPORTED_CURRENCIES) - 1:
            return

    api_url = getattr(settings, 'EXCHANGE_RATE_API_URL', 'https://open.er-api.com/v6/latest/USD')
    rates_fetched = {}

    try:
        resp = requests.get(api_url, timeout=4)
        if resp.status_code == 200:
            data = resp.json()
            if data.get('result') == 'success' and 'rates' in data:
                rates_fetched = data['rates']
    except Exception as exc:
        logger.warning("Could not fetch latest rates from %s: %s", api_url, exc)

    # Update or populate DB cache
    for target in SUPPORTED_CURRENCIES.keys():
        if target == base:
            rate = Decimal('1.0')
        elif target in rates_fetched:
            try:
                rate = Decimal(str(rates_fetched[target]))
            except Exception:
                rate = FALLBACK_RATES_USD.get(target, Decimal('1.0'))
        else:
            rate = FALLBACK_RATES_USD.get(target, Decimal('1.0'))

        ExchangeRateCache.objects.update_or_create(
            base_currency=base,
            target_currency=target,
            defaults={'rate': rate}
        )


def get_exchange_rate(from_currency='USD', to_currency='USD'):
    """
    Returns (rate: Decimal).
    Calculates rate from `from_currency` to `to_currency` using base currency triangulation.
    """
    from_curr = (from_currency or 'USD').upper()
    to_curr = (to_currency or 'USD').upper()

    if from_curr == to_curr:
        return Decimal('1.0')

    base = get_base_currency()

    # Ensure cache is populated
    try:
        refresh_exchange_rates()
    except Exception:
        pass

    def _get_rate_to_base(curr):
        if curr == base:
            return Decimal('1.0')
        try:
            cache_obj = ExchangeRateCache.objects.filter(base_currency=base, target_currency=curr).first()
            if cache_obj:
                return cache_obj.rate
        except Exception:
            pass
        return FALLBACK_RATES_USD.get(curr, Decimal('1.0'))

    rate_base_to_from = _get_rate_to_base(from_curr)
    rate_base_to_to = _get_rate_to_base(to_curr)

    if rate_base_to_from <= Decimal('0.0'):
        return Decimal('1.0')

    # 1 from_currency = (rate_base_to_to / rate_base_to_from) to_currency
    rate = rate_base_to_to / rate_base_to_from
    return rate.quantize(Decimal('0.000001'), rounding=ROUND_HALF_UP)


def convert_currency(amount, from_currency='USD', to_currency='USD'):
    """
    Converts amount from one currency to another.
    Returns: (converted_amount: Decimal, rate: Decimal)
    """
    if amount is None:
        return (Decimal('0.00'), Decimal('1.0'))

    if not isinstance(amount, Decimal):
        amount = Decimal(str(amount))

    rate = get_exchange_rate(from_currency, to_currency)
    converted = (amount * rate).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
    return (converted, rate)


def format_currency_amount(amount, currency_code='USD'):
    """
    Formats decimal amount with appropriate currency symbol.
    """
    if amount is None:
        amount = Decimal('0.00')
    if not isinstance(amount, Decimal):
        amount = Decimal(str(amount))

    curr = (currency_code or 'USD').upper()
    meta = SUPPORTED_CURRENCIES.get(curr, {'symbol': curr, 'decimals': 2})
    symbol = meta['symbol']
    decimals = meta.get('decimals', 2)

    if decimals == 0:
        formatted_num = f"{int(amount.quantize(Decimal('1'), rounding=ROUND_HALF_UP)):,}"
    else:
        formatted_num = f"{amount.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP):,}"

    return f"{symbol} {formatted_num}"
