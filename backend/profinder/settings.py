# profinder/settings.py
"""
Django settings for ProFinder project.
"""

from pathlib import Path
from datetime import timedelta
import os
from dotenv import load_dotenv

# ─── Base Configuration ───────────────────────────────────────────────

BASE_DIR = Path(__file__).resolve().parent.parent

from django.core.exceptions import ImproperlyConfigured

# Load .env properly
load_dotenv(BASE_DIR / ".env")

# DEBUG default False (live safe). Local dev ke liye .env mein DEBUG=True likho.
DEBUG = os.getenv('DEBUG', 'False').strip().lower() == 'true'

SECRET_KEY = os.getenv('SECRET_KEY')
if not SECRET_KEY:
    if DEBUG:
        SECRET_KEY = 'django-insecure-dev-fallback-key-for-local-testing-only-replace-in-env'
    else:
        raise ImproperlyConfigured(
            "SECRET_KEY is required in production. Please define SECRET_KEY in your .env file."
        )
elif not DEBUG and SECRET_KEY in ['your-secret-key-here', 'change-me', 'secret', 'django-insecure-default']:
    raise ImproperlyConfigured(
        "Known insecure placeholder SECRET_KEY detected in production. Please set a unique, random SECRET_KEY."
    )

# Live domain + local dev. Extra host chahiye to .env mein
# ALLOWED_HOSTS=host1,host2 likho.
ALLOWED_HOSTS = [
    h.strip()
    for h in os.getenv(
        'ALLOWED_HOSTS',
        'ahsanrazatalpur.pythonanywhere.com,127.0.0.1,localhost,10.0.2.2',
    ).split(',')
    if h.strip()
]

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# ─── Installed Apps ───────────────────────────────────────────────────

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.sites',
    'django.contrib.postgres',
    'corsheaders',
    'cloudinary_storage',
    'cloudinary',

    'allauth',
    'allauth.account',
    'allauth.socialaccount',
    'allauth.socialaccount.providers.google',

    'rest_framework',

    'apps.users',
    'apps.profiles',
    'apps.search',
    'apps.reviews',
    'apps.articles',
    'apps.payments',
    'apps.bookings',
    'apps.notifications',
    'apps.subscriptions',
    'apps.ai_engine',
    'apps.admin_panel',
    'apps.messaging',  # ✅ NEW — in-app chat between customers and professionals
    "apps.about_page",
    "apps.support",  # Help Center, Privacy Policy, support tickets
]

# Safe conditional inclusion: on PythonAnywhere / standard WSGI environments where
# heavy Twisted/Autobahn/Daphne wheels exceed free disk quota, gracefully bypass without error.
try:
    import daphne
    INSTALLED_APPS.insert(0, 'daphne')
except ImportError:
    pass

try:
    import channels
    INSTALLED_APPS.append('channels')
except ImportError:
    pass

AUTH_USER_MODEL = 'users.User'

# ─── Middleware ──────────────────────────────────────────────────────

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'allauth.account.middleware.AccountMiddleware',
    # Universal dynamic-content localization (reads X-App-Language). Runs last on
    # the way in / first on the way out so it sees the final JSON response.
    'apps.ai_engine.middleware.ContentLocalizationMiddleware',
]

ROOT_URLCONF = 'profinder.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'profinder.wsgi.application'

# ✅ NEW — ASGI entry point (used by Daphne to serve both HTTP + WebSocket)
ASGI_APPLICATION = 'profinder.asgi.application'

# ─── Channels / Redis (real-time messaging) ───────────────────────────
# If channels_redis is installed and configured, use RedisChannelLayer.
# Otherwise, gracefully fall back to InMemoryChannelLayer so tests and
# single-process hosts (like PythonAnywhere) function without crashes.
try:
    import channels_redis  # noqa: F401
    CHANNEL_LAYERS = {
        'default': {
            'BACKEND': 'channels_redis.core.RedisChannelLayer',
            'CONFIG': {
                'hosts': [os.getenv('REDIS_URL', 'redis://127.0.0.1:6379')],
            },
        },
    }
except ImportError:
    CHANNEL_LAYERS = {
        'default': {
            'BACKEND': 'channels.layers.InMemoryChannelLayer',
        },
    }

# ─── Database (FIXED) ────────────────────────────────────────────────

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
        # Wait up to 30s for a competing write instead of failing instantly
        # with "database is locked" (live site + manage.py commands at once).
        'OPTIONS': {'timeout': 30},
    }
}

# ─── Postgres (commented out — enable when available on hosting) ─────
# DATABASES = {
#     'default': {
#         'ENGINE': 'django.db.backends.postgresql',
#         'NAME': os.getenv('DB_NAME', 'ProFinder'),
#         'USER': os.getenv('DB_USER', 'postgres'),
#         'PASSWORD': os.getenv('DB_PASSWORD'),
#         'HOST': os.getenv('DB_HOST', 'localhost'),
#         'PORT': os.getenv('DB_PORT', '5432'),
#     }
# }

# ─── Postgres switch (NEW) ───────────────────────────────────────────
# Default stays SQLite (nothing changes for you). To use PostgreSQL — e.g. on
# your own PC, or later when your hosting offers it — just add
#     DB_ENGINE=postgres
# to .env (plus DB_NAME / DB_USER / DB_PASSWORD / DB_HOST / DB_PORT).
# Multilingual search works on both; on PostgreSQL the typo matching is
# faster (pg_trgm), on SQLite a small built-in fallback is used.
if os.getenv('DB_ENGINE', '').strip().lower() in ('postgres', 'postgresql'):
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.postgresql',
            'NAME': os.getenv('DB_NAME', 'ProFinder'),
            'USER': os.getenv('DB_USER', 'postgres'),
            'PASSWORD': os.getenv('DB_PASSWORD'),
            'HOST': os.getenv('DB_HOST', 'localhost'),
            'PORT': os.getenv('DB_PORT', '5432'),
        }
    }

# ─── Password Validators ─────────────────────────────────────────────

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# ─── Internationalization ─────────────────────────────────────────────

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# ─── Static / Media ───────────────────────────────────────────────────

STATIC_URL = 'static/'
# ✅ FIX: required by collectstatic (and Django in general once DEBUG=False
# or the staticfiles app is used outside runserver) — this is the on-disk
# folder collectstatic copies every app's static files into.
STATIC_ROOT = BASE_DIR / 'staticfiles'

MEDIA_URL = '/media/'
# 🐛 FIX: MEDIA_ROOT was never set, so Django had no defined disk location
# for uploaded files (chat images, profile photos, portfolios, ...) — and
# with nothing serving MEDIA_URL in urls.py either, every uploaded file
# 404'd the moment the app tried to load it back (see profinder/urls.py).
MEDIA_ROOT = BASE_DIR / 'media'

# ─── DRF ──────────────────────────────────────────────────────────────

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    # ScopedRateThrottle only throttles views that explicitly set a
    # `throttle_scope` — every other endpoint is unaffected by adding this.
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.ScopedRateThrottle',
    ],
    'DEFAULT_THROTTLE_RATES': {
        # Forgot-password: generous enough for a real user who mistyped
        # their email, tight enough to blunt inbox-spam/enumeration abuse.
        'forgot_password': '5/hour',
        # Reset-password: a few more attempts allowed since a legitimate
        # user may retype their new password a couple of times.
        'reset_password': '10/hour',
        # ✅ Trust & Safety Part 9 (security pass) — ReportUserView had no
        # duplicate/rate protection at all: a client could flood identical
        # reports about the same (or any) user with no limit. Reusing this
        # already-configured mechanism rather than building new
        # infrastructure. Generous enough for real abuse reporting, tight
        # enough to blunt a scripted flood.
        'user_report_create': '20/hour',
        # Authenticated /api/ai/localize/ (explicit client-side localization).
        'localize': '60/minute',
        'support_ticket_create': '5/hour',
        'support_ticket_reply': '30/hour',
        'support_guest_contact': '3/hour',
        'support_public_read': '120/minute',
    },
}

# ─── JWT ──────────────────────────────────────────────────────────────

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
}

# ─── Cloudinary ───────────────────────────────────────────────────────

CLOUDINARY_STORAGE = {
    'CLOUD_NAME': os.getenv('CLOUDINARY_CLOUD_NAME'),
    'API_KEY': os.getenv('CLOUDINARY_API_KEY'),
    'API_SECRET': os.getenv('CLOUDINARY_API_SECRET'),
}

DEFAULT_FILE_STORAGE = 'cloudinary_storage.storage.MediaCloudinaryStorage'

# ─── CORS ─────────────────────────────────────────────────────────────

CORS_ALLOW_ALL_ORIGINS = os.getenv('CORS_ALLOW_ALL_ORIGINS', 'True' if DEBUG else 'False').strip().lower() == 'true'
cors_allowed_env = os.getenv('CORS_ALLOWED_ORIGINS', '')
if cors_allowed_env:
    CORS_ALLOWED_ORIGINS = [o.strip() for o in cors_allowed_env.split(',') if o.strip()]
else:
    CORS_ALLOWED_ORIGINS = [
        'https://ahsanrazatalpur.pythonanywhere.com',
        'http://localhost:3000',
        'http://127.0.0.1:3000',
        'http://localhost:8000',
        'http://127.0.0.1:8000',
    ]

# Allow the app's language header (needed for Flutter web / browsers).
from corsheaders.defaults import default_headers as _cors_default_headers
CORS_ALLOW_HEADERS = list(_cors_default_headers) + ['x-app-language', 'x-no-localize']

import sys
TESTING = 'test' in sys.argv

# ─── Security & HTTPS (Production Hardening) ──────────────────────────
if not DEBUG and not TESTING:
    # PythonAnywhere reverse-proxy terminates SSL and forwards via X-Forwarded-Proto
    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
    # On PythonAnywhere, SSL redirect is handled by Nginx web tab ("Force HTTPS").
    # Setting this to True in Django can cause 301 loops or test failures unless explicitly enabled.
    SECURE_SSL_REDIRECT = os.getenv('SECURE_SSL_REDIRECT', 'False').strip().lower() == 'true'
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_BROWSER_XSS_FILTER = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    X_FRAME_OPTIONS = 'DENY'
    SECURE_HSTS_SECONDS = int(os.getenv('SECURE_HSTS_SECONDS', '31536000'))
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True


# ─── Google Sign-In ───────────────────────────────────────────────────
# The OAuth Client ID from Google Cloud Console (the "Web client" one —
# that's the audience google_sign_in tokens are issued for even when the
# app runs on Android/iOS). Set this in your .env file.
GOOGLE_CLIENT_ID = os.getenv('GOOGLE_CLIENT_ID')


# ─── Allauth ──────────────────────────────────────────────────────────

SITE_ID = 1

SOCIALACCOUNT_PROVIDERS = {
    'google': {
        'SCOPE': ['profile', 'email'],
        'AUTH_PARAMS': {'access_type': 'online'},
        'OAUTH_PKCE_ENABLED': True,
    }
}

ACCOUNT_USER_MODEL_USERNAME_FIELD = None
ACCOUNT_LOGIN_METHODS = {'email'}
ACCOUNT_SIGNUP_FIELDS = ['email*', 'password1*', 'password2*']

LOGIN_REDIRECT_URL = '/api/users/me/'
ACCOUNT_LOGOUT_REDIRECT_URL = '/api/auth/login/'

# ─── Email (Brevo SMTP) ────────────────────────────────────────────────
# Every value comes from .env — nothing here is hardcoded. Brevo's relay
# host/port/TLS are stable enough to default here for convenience, but the
# credentials themselves (EMAIL_HOST_USER / EMAIL_HOST_PASSWORD) must
# always be supplied via the environment; there is no fallback for those.

EMAIL_BACKEND       = os.getenv('EMAIL_BACKEND', 'django.core.mail.backends.smtp.EmailBackend')
EMAIL_HOST          = os.getenv('EMAIL_HOST', 'smtp-relay.brevo.com')
EMAIL_PORT          = int(os.getenv('EMAIL_PORT', '587'))
EMAIL_USE_TLS       = os.getenv('EMAIL_USE_TLS', 'True').strip().lower() == 'true'
EMAIL_HOST_USER     = os.getenv('EMAIL_HOST_USER')
EMAIL_HOST_PASSWORD = os.getenv('EMAIL_HOST_PASSWORD')
DEFAULT_FROM_EMAIL  = os.getenv('DEFAULT_FROM_EMAIL', EMAIL_HOST_USER)

# Brevo HTTP API key (SMTP key se alag). PythonAnywhere free account par SMTP
# blocked hai, isliye password-reset email isi API se jati hai. Set ho to API
# use hoti hai, warna purana SMTP/console backend (local development).
BREVO_API_KEY = os.getenv('BREVO_API_KEY')

# Shown in the password-reset email footer ("contact support at ...").
SUPPORT_EMAIL = os.getenv('SUPPORT_EMAIL', DEFAULT_FROM_EMAIL)

# Base URL used to build the reset link sent in the email. In production
# this should be your real HTTPS domain (e.g. https://api.profinder.com);
# set PUBLIC_BASE_URL in .env for each environment rather than hardcoding.
PUBLIC_BASE_URL = os.getenv('PUBLIC_BASE_URL', 'http://127.0.0.1:8000')

# How long a password-reset link stays valid, in seconds. Django's
# default_token_generator reads this setting internally when checking a
# token's age — 24h is a sane default for a reset link (Django's own
# default is 3 days, which is longer than most production apps want).
PASSWORD_RESET_TIMEOUT = int(os.getenv('PASSWORD_RESET_TIMEOUT', str(60 * 60 * 24)))

# ─── Logging ──────────────────────────────────────────────────────────
# Without this, `logging.getLogger(__name__).info(...)` calls in app code
# (e.g. the location-matching debug logs in apps.search.views) are silently
# dropped — Django's implicit default logging config doesn't attach a
# console handler to arbitrary app loggers, only to Django's own 'django.*'
# loggers. This makes 'apps' logger calls visible in the runserver console.
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'loggers': {
        'apps': {
            'handlers':  ['console'],
            'level':     'INFO',
            'propagate': False,
        },
    },
}


# ─── Automatic content translation (apps/ai_engine) ───────────────────
# Engine:  'gemini' | 'libretranslate' | 'libretranslate,gemini' | 'none'
TRANSLATION_ENABLED               = os.getenv('TRANSLATION_ENABLED', '1') == '1'
TRANSLATION_PROVIDER              = os.getenv('TRANSLATION_PROVIDER', 'gemini')
TRANSLATION_LIBRETRANSLATE_URL    = os.getenv('TRANSLATION_LIBRETRANSLATE_URL', '')
TRANSLATION_LIBRETRANSLATE_KEY    = os.getenv('TRANSLATION_LIBRETRANSLATE_KEY', '')

# Gemini model(s) sirf translation ke liye. Free-tier quota PER MODEL hoti hai.
# .env mein ek ya zyada models comma se alag likh sakte hain; pehla band (404) ya quota
# khatam (429) ho to app khud agla try karti hai. Misal:
#   TRANSLATION_GEMINI_MODEL=models/gemini-3.5-flash-lite,models/gemini-2.5-flash,models/gemini-flash-latest
# Models ke naam ai.dev/rate-limit se apne project ke mutabiq check karein (Google inhein
# badalta rehta hai; 2.5-flash-lite naye users ke liye band ho chuka hai).
# (Default 'gemini-flash-latest' naye model par chala jata hai jis ki free limit sirf
#  ~20/din thi -- isi wajah se translations English reh gayi thin.)
TRANSLATION_GEMINI_MODEL          = os.getenv('TRANSLATION_GEMINI_MODEL', 'models/gemini-flash-latest')

# Daily quota (429 PerDay) khatam hone par itni der (seconds) Gemini ko call nahi karte:
# app original text foran dikha deta hai, retry/sleep mein latakta nahi.
TRANSLATION_QUOTA_BLOCK_SECONDS   = 3600

TRANSLATION_SOURCE_LANGUAGE       = 'en'
# TEMPORARY (free quota bachane ke liye): abhi sirf Urdu + Hindi ka dynamic content translate hota hai.
# Fund / billing milne par wapas poori list kar dein: ['ur', 'hi', 'ar', 'es', 'fr']
# (baqi languages ki static UI .arb se phir bhi chalti rahegi, sirf DB content English dikhega.)
TRANSLATION_LANGUAGES             = ['ur', 'hi']

# Kisi naye (never-seen) string ke liye server itne seconds tak translation ka intezar
# karta hai. Pehle 2.5 tha -- Gemini ko 3-8 sec lagte hain, is liye pehli load hamesha
# English aati thi. 10 rakha taake pehli hi dafa translated aaye. Translation permanent
# cache hoti hai, is liye ye intezar sirf pehli dafa hota hai.
TRANSLATION_SYNC_BUDGET_SECONDS   = 10

TRANSLATION_PROVIDER_TIMEOUT      = 20

# Fail hone wali translation (engine error) itne seconds tak dobara try nahi hoti.
# Pehle 600 (10 min) tha; 120 se jaldi dobara koshish hoti hai.
TRANSLATION_FAIL_TTL              = 120

# Lambe text (magazine body) ke tukre ek Gemini call mein kitne bheje jayein.
TRANSLATION_CHUNKS_PER_CALL       = 6

TRANSLATION_MAX_NEW_PER_REQUEST   = 40      # new (uncached) strings translated per API call
TRANSLATION_CLIENT_NEW_PER_MINUTE = 120     # per user / IP
TRANSLATION_DAILY_NEW_LIMIT       = 5000    # global hard stop per day (cost cap)
TRANSLATION_MAX_TEXT_LENGTH       = 20000
TRANSLATION_BACKGROUND            = True

# ─── Global Payments Configuration (PayPal & Multi-Currency) ────────
PAYPAL_MODE = os.getenv('PAYPAL_MODE', 'sandbox')  # 'sandbox' or 'live'
PAYPAL_CLIENT_ID = os.getenv('PAYPAL_CLIENT_ID', '')
PAYPAL_CLIENT_SECRET = os.getenv('PAYPAL_CLIENT_SECRET', '')
PAYPAL_WEBHOOK_ID = os.getenv('PAYPAL_WEBHOOK_ID', '')
PAYPAL_ALLOW_MOCK_SUCCESS = os.getenv('PAYPAL_ALLOW_MOCK_SUCCESS', 'True' if (DEBUG or TESTING or not PAYPAL_CLIENT_ID) else 'False').strip().lower() == 'true'
BASE_SETTLEMENT_CURRENCY = os.getenv('BASE_SETTLEMENT_CURRENCY', 'USD')
MIN_WITHDRAWAL_AMOUNT = float(os.getenv('MIN_WITHDRAWAL_AMOUNT', 20.0))
EXCHANGE_RATE_API_URL = os.getenv('EXCHANGE_RATE_API_URL', 'https://open.er-api.com/v6/latest/USD')