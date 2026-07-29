# PATH: backend/apps/notifications/utils.py
# apps/notifications/utils.py
#
# Shared helper — har app (bookings, payments, reviews, subscriptions, etc.)
# is se import kare ke koi bhi notification DB mein save ho aur
# saath hi user ke device par asal push notification (FCM) bhi chali jaye —
# chahe app band ho ya background mein ho.

import logging
import os

import firebase_admin
from django.conf import settings
from dotenv import dotenv_values
from firebase_admin import credentials, messaging

from apps.notifications.models import Notification

logger = logging.getLogger(__name__)

env = dotenv_values(os.path.join(settings.BASE_DIR, '.env'))

# Firebase initialize karo — sirf ek baar, jab pehli dafa ye module load ho
if not firebase_admin._apps:
    cred_path = os.path.join(
        settings.BASE_DIR,
        env.get('FIREBASE_CREDENTIALS', 'firebase-credentials.json'),
    )
    if os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
    else:
        logger.warning(
            "[FCM] firebase-credentials.json not found at %s — "
            "push notifications will NOT be sent (DB notifications still work).",
            cred_path,
        )


def send_fcm_push(fcm_token, title, body, data=None, badge=None, channel_id='profinder_default_channel'):
    """Single device ko asal push notification bhejta hai.

    - badge: agar diya jaye, iOS app-icon pe number dikhata hai (aps.badge).
      Android pe 'data' payload ke through client khud handle karta hai.
    - channel_id: Android notification channel — alag features (chat vs
      general) ko alag channel dena best-practice hai.
    """
    if not fcm_token:
        return False
    try:
        payload_data = {k: str(v) for k, v in (data or {}).items()}
        if badge is not None:
            payload_data['badge_count'] = str(badge)

        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            token=fcm_token,
            data=payload_data,
            android=messaging.AndroidConfig(
                priority='high',
                notification=messaging.AndroidNotification(
                    channel_id=channel_id,
                ),
            ),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        sound='default',
                        badge=badge,
                    ),
                ),
            ),
        )
        messaging.send(message)
        return True
    except Exception as e:
        logger.error(f"[FCM] Push failed for token ...{str(fcm_token)[-8:]}: {e}")
        return False


def notify_user(user, title, message, notif_type='general', data=None):
    """
    Har jagah yehi function call karo notification bhejne ke liye.
    - DB mein Notification row banegi (bell icon ke liye)
    - Agar user ka fcm_token saved hai to real push bhi chali jayegi,
      app band ho ya open ho — dono surat mein.
    """
    try:
        Notification.objects.create(
            user=user, title=title, message=message, type=notif_type)
    except Exception as e:
        logger.error(f"[NOTIFICATION] DB save failed: {e}")

    fcm_token = getattr(user, 'fcm_token', None)
    if fcm_token:
        send_fcm_push(fcm_token, title, message, data=data)
    else:
        logger.info(f"[FCM] No fcm_token saved for user {user.email} — push skipped.")