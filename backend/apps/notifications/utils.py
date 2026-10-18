# PATH: backend/apps/notifications/utils.py
# apps/notifications/utils.py
#
# Shared helper — har app (bookings, payments, reviews, subscriptions, etc.)
# is se import kare ke koi bhi notification DB mein save ho aur
# saath hi user ke device par asal push notification (FCM) bhi chali jaye —
# chahe app band ho ya background mein ho.
#
# NOTE: firebase_admin use NAHI hota (grpcio etc. bohot bhari hain, PythonAnywhere
# free disk quota mein fit nahi hoti). Ye FCM HTTP v1 API ko seedha call karta hai
# sirf `google-auth` + `requests` se (dono chhoti libraries).

import json
import logging
import os
import re
import threading

import requests
from django.conf import settings
from dotenv import dotenv_values
from google.auth.transport.requests import Request as GoogleAuthRequest
from google.oauth2 import service_account

from apps.notifications.models import Notification

logger = logging.getLogger(__name__)

env = dotenv_values(os.path.join(settings.BASE_DIR, '.env'))

_FCM_SCOPES = ['https://www.googleapis.com/auth/firebase.messaging']
_creds = None
_project_id = None
_lock = threading.Lock()


def _load_credentials():
    """Service-account credentials load karta hai (ek dafa, phir cache).

    Credentials 2 tariqon se milte hain:
      1) FIREBASE_CREDENTIALS_JSON  (poora JSON ek env var mein)
      2) FIREBASE_CREDENTIALS       (file ka naam, default: firebase-credentials.json backend/ mein)
    """
    global _creds, _project_id
    if _creds is not None:
        return _creds
    try:
        cred_json = os.environ.get('FIREBASE_CREDENTIALS_JSON') or env.get('FIREBASE_CREDENTIALS_JSON')
        if cred_json:
            info = json.loads(cred_json)
            _creds = service_account.Credentials.from_service_account_info(info, scopes=_FCM_SCOPES)
            _project_id = info.get('project_id')
            return _creds

        cred_path = os.path.join(
            settings.BASE_DIR,
            os.environ.get('FIREBASE_CREDENTIALS') or env.get('FIREBASE_CREDENTIALS', 'firebase-credentials.json'),
        )
        if os.path.exists(cred_path):
            with open(cred_path, 'r', encoding='utf-8') as f:
                _project_id = json.load(f).get('project_id')
            _creds = service_account.Credentials.from_service_account_file(cred_path, scopes=_FCM_SCOPES)
            return _creds

        logger.error(
            "[FCM] firebase-credentials.json NOT FOUND at %s — push notifications "
            "will NOT be sent (DB notifications still work). Firebase Console → Project "
            "settings → Service accounts → Generate new private key.",
            cred_path,
        )
    except Exception as e:
        logger.error(f"[FCM] Could not load Firebase credentials: {e}")
    return None


def _access_token():
    creds = _load_credentials()
    if creds is None:
        return None
    with _lock:
        if not creds.valid:
            creds.refresh(GoogleAuthRequest())
        return creds.token


def send_fcm_push(fcm_token, title, body, data=None, badge=None, channel_id='profinder_default_channel'):
    """Single device ko asal push notification bhejta hai (FCM HTTP v1).

    - badge: agar diya jaye, iOS app-icon pe number dikhata hai (aps.badge).
      Android pe 'data' payload ke through client khud handle karta hai.
    - channel_id: Android notification channel — alag features (chat vs
      general) ko alag channel dena best-practice hai.
    """
    if not fcm_token:
        return False
    try:
        access_token = _access_token()
        if not access_token or not _project_id:
            return False

        payload_data = {k: str(v) for k, v in (data or {}).items()}
        if badge is not None:
            payload_data['badge_count'] = str(badge)

        aps = {'sound': 'default'}
        if badge is not None:
            aps['badge'] = badge

        message = {
            'token': fcm_token,
            'notification': {'title': title, 'body': body},
            'data': payload_data,
            'android': {
                'priority': 'HIGH',
                'notification': {
                    'channel_id': channel_id,
                    'notification_priority': 'PRIORITY_MAX',   # heads-up banner
                    'default_sound': True,
                    'default_vibrate_timings': True,
                    'visibility': 'PUBLIC',
                },
            },
            'apns': {'payload': {'aps': aps}},
        }

        resp = requests.post(
            f'https://fcm.googleapis.com/v1/projects/{_project_id}/messages:send',
            headers={
                'Authorization': f'Bearer {access_token}',
                'Content-Type': 'application/json; UTF-8',
            },
            data=json.dumps({'message': message}),
            timeout=10,
        )

        if resp.status_code == 200:
            return True

        # Token dead (app uninstalled / token rotated / galat project) — DB se hata do
        dead = ('UNREGISTERED' in resp.text or 'SENDER_ID_MISMATCH' in resp.text
                or (resp.status_code == 400 and 'registration token' in resp.text.lower()))
        if dead:
            from apps.users.models import User
            User.objects.filter(fcm_token=fcm_token).update(fcm_token=None)
            logger.warning(f"[FCM] Token ...{str(fcm_token)[-8:]} rejected ({resp.status_code}) & removed: {resp.text[:300]}")
            return False

        logger.error(f"[FCM] Push failed ({resp.status_code}) for token ...{str(fcm_token)[-8:]}: {resp.text[:300]}")
        return False
    except Exception as e:
        logger.error(f"[FCM] Push failed for token ...{str(fcm_token)[-8:]}: {e}")
        return False


# ── Push ka "kaun bhej raha hai" label ────────────────────────────────────
# Push title ke shuru mein emoji/label lagta hai taake phone pe foran pata chale
# ke ye chat hai, announcement hai, admin ka notice hai ya booking/payment alert.
# NOTE: sirf push ka title badalta hai. App ke andar bell-icon wali Notification
# row ka title waisa hi clean rehta hai.
PUSH_PREFIX = {
    'chat':         '💬 ',
    'announcement': '📢 Announcement • ',
    'admin':        '🔔 ProFinder • ',
    'booking':      '📅 ',
    'payment':      '💳 ',
    'review':       '⭐ ',
    'subscription': '🏷️ ',
    'report':       '🛡️ ',
}
# In ke prefix mein label (text) hai, is liye title emoji se shuru ho tab bhi lagte hain
_ALWAYS_PREFIX = {'announcement', 'admin'}

# Push label ka text user ki language mein. 'admin' ka label brand naam
# ("ProFinder") hai — har language mein wahi rehta hai.
PUSH_LABELS = {
    'announcement': {
        'en': 'Announcement', 'ur': 'اعلان', 'hi': 'घोषणा',
        'ar': 'إعلان', 'es': 'Anuncio', 'fr': 'Annonce',
    },
}


def get_user_lang(user):
    """User ki preferred_language ('en','ur',...). Set na ho to 'en'."""
    code = (getattr(user, 'preferred_language', None) or '').strip().lower()
    return code or 'en'


def _push_prefix(kind, lang=None):
    code = (lang or 'en').strip().lower().replace('_', '-').split('-')[0] or 'en'
    labels = PUSH_LABELS.get(kind)
    if labels:
        return f"{PUSH_PREFIX[kind].split(' ')[0]} {labels.get(code) or labels['en']} • "
    return PUSH_PREFIX.get(kind)


def detect_push_kind(title, notif_type='general'):
    """notif_type ya title ke lafzon se push ki qism nikalta hai."""
    if notif_type in ('payment', 'review', 'subscription', 'report'):
        return notif_type
    if 'booking' in (title or '').lower():
        return 'booking'
    return 'general'


def style_push_title(kind, title, lang=None):
    """Push title ke aage kind ka label/emoji lagata hai (double emoji se bachte hue).
    lang: receiver ki language code — label usi mein aata hai (None → English)."""
    prefix = _push_prefix(kind, lang)
    if not prefix or not title:
        return title
    if kind not in _ALWAYS_PREFIX and not title[0].isalnum():
        return title   # title pehle se emoji se shuru ho raha hai
    return prefix + title


def _send_notification_email_sync(to_email, user_name, title, message, notif_type='general'):
    """
    Sends a transactional notification email via Brevo HTTP API (api.brevo.com).
    - Uses settings.BREVO_API_KEY
    - Failure-isolated: never raises or breaks the user flow.
    """
    try:
        from apps.users.brevo_email import send_brevo_email
        clean_title = re.sub(r'[\U00010000-\U0010ffff]', '', title).strip()
        clean_message = re.sub(r'[\U00010000-\U0010ffff]', '', message).strip()
        subject = f"ProFinder - {clean_title}" if clean_title else "ProFinder Notification"

        html_body = f"""
        <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 580px; margin: 0 auto; padding: 24px; background: #ffffff; border-radius: 12px; border: 1px solid #e2e8f0;">
          <div style="text-align: center; padding-bottom: 20px; border-bottom: 1px solid #f1f5f9;">
            <h2 style="color: #0d9488; margin: 0; font-size: 24px; font-weight: 700;">ProFinder</h2>
            <p style="color: #64748b; font-size: 13px; margin: 4px 0 0;">Connecting You with Trusted Professionals</p>
          </div>
          <div style="padding: 24px 0;">
            <p style="font-size: 15px; color: #1e293b; margin: 0 0 12px;">Hello <strong>{user_name}</strong>,</p>
            <div style="background: #f8fafc; border-left: 4px solid #0d9488; padding: 14px 16px; border-radius: 6px; margin: 16px 0;">
              <h3 style="margin: 0 0 6px; color: #0f172a; font-size: 16px;">{clean_title}</h3>
              <p style="margin: 0; color: #334155; font-size: 14px; line-height: 1.5; white-space: pre-line;">{clean_message}</p>
            </div>
          </div>
          <div style="padding-top: 16px; border-top: 1px solid #f1f5f9; text-align: center; color: #94a3b8; font-size: 12px; line-height: 1.5;">
            <p style="margin: 0;">You received this update because email notifications are enabled for your ProFinder account.</p>
            <p style="margin: 4px 0 0;">You can update your preferences anytime in ProFinder Settings.</p>
          </div>
        </div>
        """
        text_body = f"Hello {user_name},\n\n{clean_title}\n{clean_message}\n\n--\nProFinder Team\nYou can manage email notifications in ProFinder Settings."

        send_brevo_email(
            to_email=to_email,
            to_name=user_name,
            subject=subject,
            html_body=html_body,
            text_body=text_body,
        )
        logger.info(f"[EMAIL] Sent notification email to {to_email}")
    except Exception as exc:
        logger.info(f"[EMAIL] Notification email skipped or failed for {to_email}: {exc}")


def _dispatch_external_worker(fcm_token, push_title, message, push_data, user_email, user_name, title, notif_type, email_allowed, push_allowed):
    """
    Background worker thread target to dispatch FCM push and Brevo email without
    blocking the Django request/response cycle.
    """
    from django.db import connection
    try:
        if push_allowed and fcm_token:
            try:
                send_fcm_push(fcm_token, push_title, message, data=push_data)
            except Exception as exc:
                logger.warning(f"[FCM] Background push failed: {exc}")
        elif not push_allowed:
            logger.info(f"[FCM] Push skipped for {user_email} — push_notifications disabled.")

        if email_allowed and user_email:
            try:
                _send_notification_email_sync(user_email, user_name, title, message, notif_type)
            except Exception as exc:
                logger.warning(f"[EMAIL] Background email failed: {exc}")
        elif not email_allowed:
            logger.info(f"[EMAIL] Email skipped for {user_email} — email_notifications disabled.")
    finally:
        connection.close()


def notify_user(user, title, message, notif_type='general', data=None, push_kind=None):
    """
    Universal notification entry point:
    1. Synchronously saves row to DB (instant bell tray display).
    2. Asynchronously dispatches outbound FCM HTTP and Brevo Email in a worker thread.
    """
    try:
        Notification.objects.create(
            user=user, title=title, message=message, type=notif_type)
    except Exception as e:
        logger.error(f"[NOTIFICATION] DB save failed: {e}")

    push_allowed = getattr(user, 'push_notifications', True)
    fcm_token = getattr(user, 'fcm_token', None)
    email_allowed = getattr(user, 'email_notifications', True)
    user_email = getattr(user, 'email', None)
    user_name = getattr(user, 'name', '') or (user_email.split('@')[0] if user_email else '')

    kind = push_kind or detect_push_kind(title, notif_type)
    push_data = dict(data or {})
    push_data.setdefault('type', kind)
    push_title = style_push_title(kind, title, getattr(user, 'preferred_language', None))

    t = threading.Thread(
        target=_dispatch_external_worker,
        args=(fcm_token, push_title, message, push_data, user_email, user_name, title, notif_type, email_allowed, push_allowed),
        daemon=True,
    )
    t.start()


def notify_admins(title, message, notif_type='general', data=None):
    """
    Notifies every admin user:
    1. Bulk creates Notification records in DB.
    2. Dispatches external push and email asynchronously without loop latency.
    """
    from apps.users.models import User

    admins = list(User.objects.filter(role='admin'))
    if not admins:
        return

    # Bulk create DB rows in 1 query
    notifs = [
        Notification(user=admin, title=title, message=message, type=notif_type)
        for admin in admins
    ]
    try:
        Notification.objects.bulk_create(notifs)
    except Exception as e:
        logger.error(f"[NOTIFICATION] Admin bulk create failed: {e}")

    # Dispatch external alerts asynchronously
    for admin in admins:
        push_allowed = getattr(admin, 'push_notifications', True)
        fcm_token = getattr(admin, 'fcm_token', None)
        email_allowed = getattr(admin, 'email_notifications', True)
        user_email = getattr(admin, 'email', None)
        user_name = getattr(admin, 'name', '') or (user_email.split('@')[0] if user_email else '')

        kind = detect_push_kind(title, notif_type)
        push_data = dict(data or {})
        push_data.setdefault('type', kind)
        push_title = style_push_title(kind, title, getattr(admin, 'preferred_language', None))

        t = threading.Thread(
            target=_dispatch_external_worker,
            args=(fcm_token, push_title, message, push_data, user_email, user_name, title, notif_type, email_allowed, push_allowed),
            daemon=True,
        )
        t.start()