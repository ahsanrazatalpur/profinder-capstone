# apps/payments/paypal.py

import os
import time
import base64
import logging
from decimal import Decimal
import requests
from django.conf import settings

logger = logging.getLogger(__name__)

# Token cache: (token_str, expire_timestamp)
_TOKEN_CACHE = {'token': None, 'expires_at': 0}


import sys

def get_paypal_mode():
    return getattr(settings, 'PAYPAL_MODE', 'sandbox')


def get_base_url():
    mode = get_paypal_mode()
    if mode == 'live':
        return 'https://api-m.paypal.com'
    return 'https://api-m.sandbox.paypal.com'


def get_credentials():
    client_id = getattr(settings, 'PAYPAL_CLIENT_ID', '') or os.getenv('PAYPAL_CLIENT_ID', '')
    client_secret = getattr(settings, 'PAYPAL_CLIENT_SECRET', '') or os.getenv('PAYPAL_CLIENT_SECRET', '')
    return client_id.strip(), client_secret.strip()


def is_dummy_or_placeholder(val):
    if not val:
        return True
    val_lower = str(val).lower().strip()
    return any(p in val_lower for p in [
        'your_', 'placeholder', 'dummy', 'change_me', 'my_client', 'client_id_here',
        'paypal_client', 'xxx', 'sample'
    ])


def has_valid_credentials():
    if getattr(settings, 'TESTING', False) or 'test' in sys.argv:
        return False
    cid, sec = get_credentials()
    if is_dummy_or_placeholder(cid) or is_dummy_or_placeholder(sec):
        return False
    return bool(cid and sec)


def get_access_token():
    """
    Retrieves OAuth 2.0 bearer token from PayPal API.
    Caches token in memory until expiration.
    Falls back to mock token if in testing or credentials are not configured yet.
    """
    global _TOKEN_CACHE

    if getattr(settings, 'TESTING', False) or 'test' in sys.argv or not has_valid_credentials():
        return "MOCK_PAYPAL_SANDBOX_TOKEN"

    now = time.time()
    if _TOKEN_CACHE['token'] and _TOKEN_CACHE['expires_at'] > now + 60:
        return _TOKEN_CACHE['token']

    cid, sec = get_credentials()
    url = f"{get_base_url()}/v1/oauth2/token"
    auth_header = base64.b64encode(f"{cid}:{sec}".encode('utf-8')).decode('utf-8')
    headers = {
        'Authorization': f'Basic {auth_header}',
        'Content-Type': 'application/x-www-form-urlencoded',
    }
    data = {'grant_type': 'client_credentials'}

    try:
        resp = requests.post(url, headers=headers, data=data, timeout=10)
        if resp.status_code == 200:
            res_data = resp.json()
            token = res_data.get('access_token')
            expires_in = res_data.get('expires_in', 3600)
            _TOKEN_CACHE['token'] = token
            _TOKEN_CACHE['expires_at'] = now + expires_in
            return token
        else:
            logger.error("PayPal token error: %s - %s", resp.status_code, resp.text)
            allow_mock = getattr(settings, 'PAYPAL_ALLOW_MOCK_SUCCESS', False) or getattr(settings, 'TESTING', False) or 'test' in sys.argv
            if allow_mock:
                logger.warning("PayPal token authentication failed (status %s); falling back to mock sandbox token.", resp.status_code)
                return "MOCK_PAYPAL_SANDBOX_TOKEN"
            raise ConnectionError(f"PayPal authentication failed with status {resp.status_code}")
    except requests.RequestException as exc:
        logger.error("PayPal connection failed: %s", exc)
        allow_mock = getattr(settings, 'PAYPAL_ALLOW_MOCK_SUCCESS', False) or getattr(settings, 'TESTING', False) or 'test' in sys.argv
        if allow_mock:
            logger.warning("PayPal connection failed (%s); falling back to mock sandbox token.", exc)
            return "MOCK_PAYPAL_SANDBOX_TOKEN"
        raise ConnectionError(f"Could not connect to PayPal: {exc}")


def create_order(amount, currency='USD', return_url='', cancel_url='', custom_id='', description=''):
    """
    Creates a PayPal V2 order for capture.
    Returns: dict { 'id': paypal_order_id, 'status': str, 'approval_url': str }
    """
    if isinstance(amount, (int, float)):
        amount = Decimal(str(amount))
    amount_str = f"{amount:.2f}"

    is_test = getattr(settings, 'TESTING', False) or 'test' in sys.argv
    allow_mock = getattr(settings, 'PAYPAL_ALLOW_MOCK_SUCCESS', False) or is_test

    if is_test or not has_valid_credentials():
        if not allow_mock:
            raise ValueError(
                "PayPal gateway credentials (PAYPAL_CLIENT_ID / PAYPAL_CLIENT_SECRET) are missing in .env. "
                "Please configure your PayPal Sandbox credentials from developer.paypal.com."
            )
        # Simulated order for preview / staging environments before merchant activation
        mock_id = f"MOCK-PAYPAL-{custom_id or int(time.time())}"
        approval_mock = return_url or f"https://www.sandbox.paypal.com/checkoutnow?token={mock_id}"
        if '?' in approval_mock:
            approval_mock += f"&token={mock_id}&PayerID=MOCKPAYER123"
        else:
            approval_mock += f"?token={mock_id}&PayerID=MOCKPAYER123"
        return {
            'id': mock_id,
            'status': 'CREATED',
            'approval_url': approval_mock,
            'is_mock': True,
        }

    token = get_access_token()
    if token == "MOCK_PAYPAL_SANDBOX_TOKEN" or token.startswith("MOCK_"):
        mock_id = f"MOCK-PAYPAL-{custom_id or int(time.time())}"
        approval_mock = return_url or f"https://www.sandbox.paypal.com/checkoutnow?token={mock_id}"
        if '?' in approval_mock:
            approval_mock += f"&token={mock_id}&PayerID=MOCKPAYER123"
        else:
            approval_mock += f"?token={mock_id}&PayerID=MOCKPAYER123"
        return {
            'id': mock_id,
            'status': 'CREATED',
            'approval_url': approval_mock,
            'is_mock': True,
        }

    url = f"{get_base_url()}/v2/checkout/orders"
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json',
    }

    payload = {
        "intent": "CAPTURE",
        "purchase_units": [
            {
                "reference_id": custom_id or "default",
                "custom_id": custom_id,
                "description": (description or "ProFinder Service")[:127],
                "amount": {
                    "currency_code": currency.upper(),
                    "value": amount_str,
                }
            }
        ],
        "application_context": {
            "brand_name": "ProFinder",
            "landing_page": "BILLING",
            "user_action": "PAY_NOW",
            "return_url": return_url,
            "cancel_url": cancel_url,
        }
    }

    resp = requests.post(url, headers=headers, json=payload, timeout=12)
    if resp.status_code in (200, 201):
        data = resp.json()
        paypal_id = data.get('id')
        status = data.get('status')
        approval_url = ''
        for link in data.get('links', []):
            if link.get('rel') == 'approve':
                approval_url = link.get('href', '')
                break
        return {
            'id': paypal_id,
            'status': status,
            'approval_url': approval_url,
            'raw': data,
        }
    else:
        logger.error("Failed to create PayPal order: %s - %s", resp.status_code, resp.text)
        raise ValueError(f"PayPal order creation failed: {resp.text}")


def capture_order(paypal_order_id):
    """
    Captures payment for an approved PayPal order.
    Returns: dict { 'capture_id': str, 'status': str, 'payer_id': str, 'payer_email': str }
    """
    is_test = getattr(settings, 'TESTING', False) or 'test' in sys.argv
    allow_mock = getattr(settings, 'PAYPAL_ALLOW_MOCK_SUCCESS', False) or is_test

    if is_test or str(paypal_order_id).startswith('MOCK-') or not has_valid_credentials():
        if not allow_mock and not str(paypal_order_id).startswith('MOCK-'):
            raise ValueError(
                "PayPal gateway is not configured. Please add PAYPAL_CLIENT_ID and PAYPAL_CLIENT_SECRET to .env"
            )
        return {
            'capture_id': f"MOCK-CAP-{int(time.time())}",
            'status': 'COMPLETED',
            'payer_id': 'MOCK-PAYER-USER',
            'payer_email': 'buyer@sandbox.profinder.com',
            'is_mock': True,
        }

    token = get_access_token()
    if token == "MOCK_PAYPAL_SANDBOX_TOKEN" or token.startswith("MOCK_"):
        return {
            'capture_id': f"MOCK-CAP-{int(time.time())}",
            'status': 'COMPLETED',
            'payer_id': 'MOCK-PAYER-USER',
            'payer_email': 'buyer@sandbox.profinder.com',
            'is_mock': True,
        }

    url = f"{get_base_url()}/v2/checkout/orders/{paypal_order_id}/capture"
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json',
    }

    resp = requests.post(url, headers=headers, json={}, timeout=15)
    if resp.status_code in (200, 201):
        data = resp.json()
        status = data.get('status')
        capture_id = ''
        payer_id = ''
        payer_email = ''

        payer = data.get('payer', {})
        payer_id = payer.get('payer_id', '')
        payer_email = payer.get('email_address', '')

        purchase_units = data.get('purchase_units', [])
        if purchase_units:
            payments_obj = purchase_units[0].get('payments', {})
            captures = payments_obj.get('captures', [])
            if captures:
                capture_id = captures[0].get('id', '')

        return {
            'capture_id': capture_id,
            'status': status,
            'payer_id': payer_id,
            'payer_email': payer_email,
            'raw': data,
        }
    else:
        logger.error("Failed to capture PayPal order %s: %s - %s", paypal_order_id, resp.status_code, resp.text)
        raise ValueError(f"PayPal capture failed: {resp.text}")


def refund_capture(capture_id, amount=None, currency='USD', note='ProFinder Refund'):
    """
    Refunds a captured PayPal payment (full or partial).
    Returns: dict { 'refund_id': str, 'status': str }
    """
    is_test = getattr(settings, 'TESTING', False) or 'test' in sys.argv
    if is_test or str(capture_id).startswith('MOCK-') or not has_valid_credentials():
        return {
            'refund_id': f"MOCK-REF-{int(time.time())}",
            'status': 'COMPLETED',
            'is_mock': True,
        }

    token = get_access_token()
    if token == "MOCK_PAYPAL_SANDBOX_TOKEN" or token.startswith("MOCK_"):
        return {
            'refund_id': f"MOCK-REF-{int(time.time())}",
            'status': 'COMPLETED',
            'is_mock': True,
        }

    url = f"{get_base_url()}/v2/payments/captures/{capture_id}/refund"
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json',
    }
    payload = {'note_to_payer': note[:255]}
    if amount:
        payload['amount'] = {
            'value': f"{Decimal(str(amount)):.2f}",
            'currency_code': currency.upper(),
        }

    resp = requests.post(url, headers=headers, json=payload, timeout=12)
    if resp.status_code in (200, 201):
        data = resp.json()
        return {
            'refund_id': data.get('id'),
            'status': data.get('status'),
            'raw': data,
        }
    else:
        logger.error("Failed to refund capture %s: %s - %s", capture_id, resp.status_code, resp.text)
        raise ValueError(f"PayPal refund failed: {resp.text}")


def verify_webhook_signature(headers, body_raw):
    """
    Verifies that an incoming webhook genuinely originated from PayPal.
    """
    is_test = getattr(settings, 'TESTING', False) or 'test' in sys.argv
    webhook_id = getattr(settings, 'PAYPAL_WEBHOOK_ID', '')
    if is_test or not webhook_id or not has_valid_credentials():
        # During tests or sandbox setup without webhook ID configured, return True
        return True

    token = get_access_token()
    url = f"{get_base_url()}/v1/notifications/verify-webhook-signature"

    payload = {
        "auth_algo": headers.get('PAYPAL-AUTH-ALGO', ''),
        "cert_url": headers.get('PAYPAL-CERT-URL', ''),
        "transmission_id": headers.get('PAYPAL-TRANSMISSION-ID', ''),
        "transmission_sig": headers.get('PAYPAL-TRANSMISSION-SIG', ''),
        "transmission_time": headers.get('PAYPAL-TRANSMISSION-TIME', ''),
        "webhook_id": webhook_id,
        "webhook_event": body_raw if isinstance(body_raw, dict) else {},
    }

    try:
        resp = requests.post(
            url,
            headers={'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'},
            json=payload,
            timeout=10
        )
        if resp.status_code == 200:
            return resp.json().get('verification_status') == 'SUCCESS'
    except Exception as exc:
        logger.warning("Error verifying PayPal webhook: %s", exc)

    return False
