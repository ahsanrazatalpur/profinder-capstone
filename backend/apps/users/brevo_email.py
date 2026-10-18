# apps/users/brevo_email.py
#
# Brevo HTTP API se email bhejta hai (SMTP nahi).
# Wajah: PythonAnywhere ke free account par SMTP ports blocked hain, lekin
# api.brevo.com (HTTPS) allowlist mein hai.

import logging
from datetime import datetime

import requests
from django.conf import settings
from django.core.mail import EmailMultiAlternatives
from django.template.loader import render_to_string

logger = logging.getLogger(__name__)

BREVO_SEND_URL = "https://api.brevo.com/v3/smtp/email"


def send_brevo_email(to_email, to_name, subject, html_body, text_body):
    """Email bhejta hai Brevo HTTP API ke zariye. Fail hone par exception raise karta hai (caller log karega).

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


def send_otp_email(to_email, to_name, otp_code, purpose="signup"):
    """
    Sends a 6-digit numeric OTP via Brevo transactional email API with a ProFinder-branded
    responsive HTML template and plain-text fallback.

    If BREVO_API_KEY is not set (e.g. automated tests or local development),
    it falls back to Django's standard EmailMultiAlternatives.
    """
    to_email = (to_email or "").strip().lower()
    clean_name = to_name or to_email.split("@")[0]

    if purpose == "forgot_password":
        subject = f"Reset your ProFinder Password - Code: {otp_code}"
        purpose_title = "Reset Your Password"
        purpose_tag = "Password Reset"
        purpose_message = (
            "We received a request to reset the password for your ProFinder account. "
            "Enter the six-digit verification code below directly in the ProFinder app to continue."
        )
    elif purpose == "delete_account":
        subject = f"Confirm Account Deletion - Code: {otp_code}"
        purpose_title = "Confirm Account Deletion"
        purpose_tag = "Security & Privacy"
        purpose_message = (
            "We received a request to permanently delete your ProFinder account. "
            "To confirm this action and delete your account, enter the six-digit verification code below in the ProFinder app. "
            "WARNING: This action is permanent and cannot be undone."
        )
    else:
        subject = f"Verify your ProFinder Account - Code: {otp_code}"
        purpose_title = "Verify Your Email Address"
        purpose_tag = "Account Verification"
        purpose_message = (
            "Thank you for joining ProFinder! To complete your registration and activate your account, "
            "enter the six-digit verification code below directly in the ProFinder app."
        )

    context = {
        "user_name":       clean_name,
        "otp_code":        otp_code,
        "purpose_title":   purpose_title,
        "purpose_tag":     purpose_tag,
        "purpose_message": purpose_message,
        "support_email":   getattr(settings, "SUPPORT_EMAIL", settings.DEFAULT_FROM_EMAIL),
        "current_year":    datetime.now().year,
    }

    html_body = render_to_string("otp_email.html", context)
    text_body = render_to_string("otp_email.txt", context)

    if getattr(settings, "BREVO_API_KEY", None):
        message_id = send_brevo_email(
            to_email=to_email,
            to_name=clean_name,
            subject=subject,
            html_body=html_body,
            text_body=text_body,
        )
        logger.info(
            "OTP email (purpose=%s) sent via Brevo API to %s (messageId=%s)",
            purpose, to_email, message_id
        )
        return message_id
    else:
        msg = EmailMultiAlternatives(
            subject=subject,
            body=text_body,
            from_email=settings.DEFAULT_FROM_EMAIL,
            to=[to_email],
        )
        msg.attach_alternative(html_body, "text/html")
        msg.send(fail_silently=False)
        logger.info(
            "OTP email (purpose=%s) sent via Django email backend to %s",
            purpose, to_email
        )
        return "local_email_sent"
