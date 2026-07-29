"""
Django settings for ProFinder project.
"""

from pathlib import Path
from datetime import timedelta
import os
from dotenv import load_dotenv

# ─── Base Configuration ───────────────────────────────────────────────

BASE_DIR = Path(__file__).resolve().parent.parent

# Load .env properly
load_dotenv(BASE_DIR / ".env")

SECRET_KEY = os.getenv('SECRET_KEY')
DEBUG = True

ALLOWED_HOSTS = ['*']

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# ─── Installed Apps ───────────────────────────────────────────────────

INSTALLED_APPS = [
    'daphne',  # ✅ NEW — ASGI server; must be listed before django.contrib.staticfiles

    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.sites',
    'django.contrib.postgres',
    

    'corsheaders',
    'channels',  # ✅ NEW — WebSocket support

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
]

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
# ✅ NEW — Redis acts as the "channel layer": it relays messages between
# WebSocket connections, even across multiple server processes/machines.
# REDIS_URL comes from .env — e.g. redis://localhost:6379 for local dev,
# or your managed Redis provider's URL in production.
CHANNEL_LAYERS = {
    'default': {
        'BACKEND': 'channels_redis.core.RedisChannelLayer',
        'CONFIG': {
            'hosts': [os.getenv('REDIS_URL', 'redis://127.0.0.1:6379')],
        },
    },
}

# ─── Database (FIXED) ────────────────────────────────────────────────

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
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

CORS_ALLOW_ALL_ORIGINS = True

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