# apps/payments/safepay.py

import os
import uuid
import hmac
import hashlib
import logging
import requests
from decimal import Decimal, ROUND_HALF_UP
from urllib.parse import urlencode
from django.conf import settings

logger = logging.getLogger(__name__)


def pkr_to_paisas(amount: Decimal | float | int | str) -> int:
    """
    Safely converts PKR currency (e.g. Decimal('499.00')) to integer paisas (49900)
    using Decimal arithmetic without floating-point representation errors.
    """
    if isinstance(amount, (int, str)):
        d = Decimal(str(amount))
    elif isinstance(amount, float):
        d = Decimal(str(amount))
    else:
        d = amount
    quantized = d.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
    return int(quantized * 100)


def paisas_to_pkr(paisas: int) -> Decimal:
    """
    Converts integer paisas back to PKR Decimal with 2 decimal places.
    """
    return (Decimal(paisas) / Decimal(100)).quantize(Decimal('0.01'))


class SafepayGateway:
    """
    Production-grade Safepay payment integration adapter for Pakistan (PKR).
    Handles:
      1. Order creation (POST /order/payments/v3/) -> tracker token
      2. Passport Time-Based Token (POST /client/passport/v1/token) -> 1-hour session token
      3. Express Checkout URL construction
      4. Webhook HMAC-SHA256 signature verification
      5. Reporter API payment capture status verification (GET /reporter/api/v1/payments/{tracker})
    """

    def __init__(
        self,
        api_key: str = None,
        merchant_secret: str = None,
        webhook_secret: str = None,
        environment: str = None,
    ):
        self.environment = environment or getattr(settings, 'SAFEPAY_ENVIRONMENT', 'sandbox')
        self.api_key = api_key or getattr(settings, 'SAFEPAY_API_KEY', '')
        self.merchant_secret = merchant_secret or getattr(settings, 'SAFEPAY_MERCHANT_SECRET', '')
        self.webhook_secret = webhook_secret or getattr(settings, 'SAFEPAY_WEBHOOK_SECRET', '')

        if self.environment == 'production':
            self.base_url = 'https://api.getsafepay.com'
            self.checkout_url = getattr(settings, 'SAFEPAY_CHECKOUT_URL', 'https://getsafepay.com/checkout/pay')
        else:
            self.base_url = 'https://sandbox.api.getsafepay.com'
            self.checkout_url = getattr(settings, 'SAFEPAY_CHECKOUT_URL', 'https://sandbox.api.getsafepay.com/checkout/pay')

        self.allow_mock = getattr(settings, 'SAFEPAY_ALLOW_MOCK_SUCCESS', False)

    def create_order(self, amount_paisas: int, currency: str = 'PKR', intent: str = None) -> dict:
        """
        Creates an order with Safepay Orders v3 API.
        amount_paisas: Amount in minor units (paisas), must be positive integer.
        intent: Optional payment rail intent (e.g. 'RAAST' for Raast Dynamic QR & RTP,
                'CYBERSOURCE' for Debit/Credit Cards, or None for all supported account rails).
        Returns dict containing 'tracker' and raw metadata.
        """
        if not isinstance(amount_paisas, int) or amount_paisas <= 0:
            raise ValueError(f"amount_paisas must be a positive integer, got: {amount_paisas}")

        if not self.api_key and self.allow_mock:
            mock_tracker = f"track_mock_{uuid.uuid4().hex[:16]}"
            logger.info("Safepay mock mode: generated simulated tracker %s", mock_tracker)
            return {
                'tracker': mock_tracker,
                'token': mock_tracker,
                'status': 'success',
                'raw': {'mock': True, 'token': mock_tracker, 'amount': amount_paisas}
            }

        endpoint = f"{self.base_url}/order/v1/init"
        payload = {
            "client": self.api_key,
            "amount": amount_paisas,
            "currency": currency,
            "environment": self.environment,
        }
        if intent and intent.strip():
            payload["intent"] = intent.strip().upper()

        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-SFPY-MERCHANT-SECRET": self.merchant_secret,
        }

        try:
            resp = requests.post(endpoint, json=payload, headers=headers, timeout=30)
            resp.raise_for_status()
            data = resp.json()
            data_obj = data.get('data') or {}
            tracker = None
            if isinstance(data_obj, dict):
                tracker = data_obj.get('token') or data_obj.get('tracker')
            if not tracker:
                tracker = data.get('token')
            if not tracker:
                raise ValueError(f"Safepay response missing tracker token: {data}")
            return {
                'tracker': tracker,
                'token': tracker,
                'status': 'success',
                'raw': data,
            }
        except requests.RequestException as e:
            logger.error("Safepay order creation failed: %s", str(e))
            raise RuntimeError(f"Safepay order creation error: {str(e)}") from e

    def create_passport_token(self) -> str:
        """
        Requests a Time-Based Token (TBT) from Passport v1.
        Valid for 1 hour. Never persist or log token.
        """
        if not self.merchant_secret and self.allow_mock:
            return f"tbt_mock_{uuid.uuid4().hex[:32]}"

        endpoint = f"{self.base_url}/client/passport/v1/token"
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-SFPY-MERCHANT-SECRET": self.merchant_secret,
        }
        payload = {
            "client": self.api_key,
            "environment": self.environment,
        }

        try:
            resp = requests.post(endpoint, json=payload, headers=headers, timeout=30)
            resp.raise_for_status()
            data = resp.json()
            raw_token = data.get('data')
            if isinstance(raw_token, str):
                token = raw_token
            elif isinstance(raw_token, dict):
                token = raw_token.get('token')
            else:
                token = data.get('token')
            if not token:
                raise ValueError(f"Safepay Passport response missing token: {data}")
            return token
        except requests.RequestException as e:
            logger.error("Safepay passport token request failed: %s", str(e))
            raise RuntimeError(f"Safepay passport error: {str(e)}") from e

    def build_express_checkout_url(
        self,
        tracker: str,
        tbt: str,
        source: str = 'custom',
        redirect_url: str = None,
        cancel_url: str = None,
        order_id: str = None,
    ) -> str:
        """
        Constructs the official Safepay Hosted Checkout Component URL.
        Renders all enabled multi-rail payment methods (Cards, Raast QR & RTP, Wallets).
        """
        params = {
            'beacon': tracker,
            'env': self.environment,
            'source': source or 'custom',
            'webhooks': 'true',
        }
        if order_id:
            params['order_id'] = order_id
        if redirect_url:
            params['redirect_url'] = redirect_url
        if cancel_url:
            params['cancel_url'] = cancel_url

        return f"{self.checkout_url}?{urlencode(params)}"

    def query_reporter_status(self, tracker: str) -> dict:
        """
        Authoritative payment status inquiry via Safepay Reporter API v1
        with automatic fallback to Order API v1 for high resilience.
        """
        if tracker.startswith('track_mock_') or (not self.merchant_secret and self.allow_mock):
            return {
                'status': 'completed',
                'state': 'COMPLETED',
                'captured': True,
                'amount': None,  # will match payment amount
                'currency': 'PKR',
                'tracker': tracker,
                'raw': {'mock': True, 'state': 'COMPLETED'},
            }

        SUCCESS_STATES = {
            'TRACKER_ENDED',
            'TRACKER_COMPLETED',
            'COMPLETED',
            'PAID',
            'CAPTURED',
            'SUCCESS',
        }

        # 1. Primary: Try Reporter API
        endpoint = f"{self.base_url}/reporter/api/v1/payments/{tracker}"
        headers = {
            "Accept": "application/json",
            "X-SFPY-MERCHANT-SECRET": self.merchant_secret,
        }

        try:
            resp = requests.get(endpoint, headers=headers, timeout=15)
            if resp.status_code == 200:
                data = resp.json()
                data_obj = data.get('data') if isinstance(data.get('data'), dict) else data
                tracker_obj = data_obj.get('tracker') if isinstance(data_obj.get('tracker'), dict) else data_obj

                raw_state = (
                    tracker_obj.get('state') or
                    tracker_obj.get('status') or
                    data_obj.get('state') or
                    data_obj.get('status') or
                    data.get('state') or
                    data.get('status') or
                    ''
                )
                state = str(raw_state).strip().upper()
                captured = bool(tracker_obj.get('captured') or data_obj.get('captured') or (state in SUCCESS_STATES))
                is_completed = (state in SUCCESS_STATES) and captured
                amount = tracker_obj.get('amount') or data_obj.get('amount')
                currency = tracker_obj.get('currency') or data_obj.get('currency', 'PKR')

                logger.info("Safepay Reporter query tracker %s resolved state: %s, captured: %s", tracker, state, captured)
                return {
                    'status': 'completed' if is_completed else state.lower(),
                    'state': state,
                    'captured': captured,
                    'amount': amount,
                    'currency': currency,
                    'tracker': tracker,
                    'raw': data,
                }
            else:
                logger.warning("Safepay Reporter API returned %s for tracker %s, falling back to Order API", resp.status_code, tracker)
        except Exception as exc:
            logger.warning("Safepay Reporter API query error for tracker %s: %s, falling back to Order API", tracker, exc)

        # 2. Resilient Fallback: Order API /order/v1/{tracker}
        order_endpoint = f"{self.base_url}/order/v1/{tracker}"
        try:
            resp = requests.get(order_endpoint, timeout=15)
            if resp.status_code == 200:
                data = resp.json()
                order_data = data.get('data') or {}
                state = str(order_data.get('state') or '').strip().upper()
                transaction = order_data.get('transaction')
                has_transaction = bool(transaction)
                captured = (state in SUCCESS_STATES) or has_transaction
                is_completed = (state in SUCCESS_STATES) or has_transaction

                logger.info("Safepay Order API fallback tracker %s: state=%s, has_transaction=%s", tracker, state, has_transaction)
                return {
                    'status': 'completed' if is_completed else state.lower(),
                    'state': state,
                    'captured': captured,
                    'amount': order_data.get('amount'),
                    'currency': order_data.get('currency', 'PKR'),
                    'tracker': tracker,
                    'raw': data,
                }
            else:
                logger.error("Safepay Order API fallback returned %s for tracker %s", resp.status_code, tracker)
                resp.raise_for_status()
        except requests.RequestException as e:
            logger.error("Safepay verification query failed for tracker %s: %s", tracker, str(e))
            raise RuntimeError(f"Safepay verification query error: {str(e)}") from e

    def verify_webhook_signature(
        self,
        raw_payload_bytes: bytes,
        signature: str,
        secret: str = None,
    ) -> bool:
        """
        Verifies the HMAC-SHA256 signature of an incoming Safepay webhook.
        Safepay sends the signature in X-SFPY-SIGNATURE computed over raw body bytes.
        """
        if self.allow_mock and signature == 'mock_signature':
            return True

        if not signature or not raw_payload_bytes:
            return False

        sig = signature.strip().lower()

        # Check with configured webhook secret first, then merchant secret fallback
        secrets_to_try = []
        if secret and secret.strip():
            secrets_to_try.append(secret.strip())
        if self.webhook_secret and self.webhook_secret.strip() and self.webhook_secret.strip() not in secrets_to_try:
            secrets_to_try.append(self.webhook_secret.strip())
        if self.merchant_secret and self.merchant_secret.strip() and self.merchant_secret.strip() not in secrets_to_try:
            secrets_to_try.append(self.merchant_secret.strip())

        if not secrets_to_try:
            logger.warning("Safepay webhook signature validation attempted without any configured secret.")
            return False

        for sec in secrets_to_try:
            try:
                computed_hmac = hmac.new(
                    sec.encode('utf-8'),
                    raw_payload_bytes,
                    hashlib.sha256
                ).hexdigest().lower()
                if hmac.compare_digest(computed_hmac, sig):
                    return True
            except Exception as e:
                logger.error("Error computing webhook HMAC signature: %s", str(e))

        return False
