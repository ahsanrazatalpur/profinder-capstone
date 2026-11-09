"""
Centralized Localization & Nationalization Configuration for ProFinder.

Controls the operational scope of ProFinder (Pakistan-only vs Global).
Allows seamless flipping back to multi-country / multi-currency / multi-language mode
when expanding internationally in the future.
"""

# Scope Mode: 'PK_NATIONAL' or 'GLOBAL'
MARKETPLACE_SCOPE_MODE = 'PK_NATIONAL'

# Default National Configuration
DEFAULT_COUNTRY_NAME = 'Pakistan'
DEFAULT_COUNTRY_CODE = 'PK'
DEFAULT_DIALING_CODE = '+92'
DEFAULT_CURRENCY_CODE = 'PKR'
DEFAULT_CURRENCY_SYMBOL = 'Rs.'
DEFAULT_TIME_ZONE = 'Asia/Karachi'

# Active Supported Languages
# In PK_NATIONAL mode: English ('en') and Urdu ('ur') only.
NATIONAL_LANGUAGES = [
    ('en', 'English'),
    ('ur', 'Urdu'),
]

# Preserved Global Languages (for future international expansion)
GLOBAL_LANGUAGES = [
    ('en', 'English'),
    ('ur', 'Urdu'),
    ('hi', 'Hindi'),
    ('ar', 'Arabic'),
    ('fr', 'French'),
    ('es', 'Spanish'),
]

ACTIVE_LANGUAGES = NATIONAL_LANGUAGES if MARKETPLACE_SCOPE_MODE == 'PK_NATIONAL' else GLOBAL_LANGUAGES

# Active Supported Currencies
NATIONAL_CURRENCIES = {
    'PKR': {'name': 'Pakistani Rupee', 'symbol': 'Rs.', 'decimals': 0},
}

GLOBAL_CURRENCIES = {
    'PKR': {'name': 'Pakistani Rupee', 'symbol': 'Rs.', 'decimals': 0},
    'USD': {'name': 'US Dollar', 'symbol': '$', 'decimals': 2},
    'EUR': {'name': 'Euro', 'symbol': '€', 'decimals': 2},
    'GBP': {'name': 'British Pound', 'symbol': '£', 'decimals': 2},
    'AED': {'name': 'UAE Dirham', 'symbol': 'AED', 'decimals': 2},
    'SAR': {'name': 'Saudi Riyal', 'symbol': 'SAR', 'decimals': 2},
    'INR': {'name': 'Indian Rupee', 'symbol': '₹', 'decimals': 2},
}

ACTIVE_CURRENCIES = NATIONAL_CURRENCIES if MARKETPLACE_SCOPE_MODE == 'PK_NATIONAL' else GLOBAL_CURRENCIES

# Feature Flags
ENABLE_INTERNATIONAL_COUNTRY_SELECTION = (MARKETPLACE_SCOPE_MODE == 'GLOBAL')
ENABLE_FOREIGN_CURRENCY_CONVERSION = (MARKETPLACE_SCOPE_MODE == 'GLOBAL')
ENABLE_MULTI_COUNTRY_ONBOARDING = (MARKETPLACE_SCOPE_MODE == 'GLOBAL')
