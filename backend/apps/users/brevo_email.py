# apps/users/brevo_email.py
#
# Brevo HTTP API se email bhejta hai (SMTP nahi).
# Wajah: PythonAnywhere ke free account par SMTP ports blocked hain, lekin
# api.brevo.com (HTTPS) allowlist mein hai.

import logging

import requests
from django.conf import settings

logger = logging.getLogger(__name__)

BREVO_SEND_URL = "https://api.brevo.com/v3/smtp/email"


def send_brevo_email(to_email, to_name, subject, html_body, text_body):
    """Email bhejta hai. Fail hone par exception raise karta hai (caller log karega).

    Returns: Brevo ka messageId.
    """
    api_key = getattr(settings, "BREVO_API_KEY", None)
    if not api_key:
        raise RuntimeError("BREVO_API_KEY is not set in .env")

    payload = {
        "sender":      {"name": "ProFinder", "email": settings.DEFAULT_FROM_EMAIL},
        "to":          [{"email": to_email, "name": to_name or to_email}],
        "replyTo":     {"email": getattr(settings, "SUPPORT_EMAIL", settings.DEFAULT_FROM_EMAIL)},
        "subject":     subject,
        "htmlContent": html_body,
        "textContent": text_body,
    }
    resp = requests.post(
        BREVO_SEND_URL,
        headers={
            "api-key":      api_key,
            "content-type": "application/json",
            "accept":       "application/json",
        },
        json=payload,
        timeout=15,
    )
    if resp.status_code not in (200, 201):
        # Key kabhi log mein nahi aati, sirf status aur Brevo ka jawab
        raise RuntimeError(f"Brevo API error {resp.status_code}: {resp.text[:300]}")

    return resp.json().get("messageId")
