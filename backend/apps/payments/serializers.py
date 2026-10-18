# apps/payments/serializers.py

from rest_framework import serializers
from apps.payments.models import Payment, WithdrawalRequest, WalletTransaction, ExchangeRateCache


class PaymentSerializer(serializers.ModelSerializer):
    user_email = serializers.CharField(source='user.email', read_only=True)
    user_name = serializers.CharField(source='user.name', read_only=True)

    class Meta:
        model = Payment
        fields = [
            'id', 'order_id', 'user', 'user_email', 'user_name',
            'amount', 'currency', 'purpose', 'booking', 'subscription',
            'subscription_plan', 'gateway', 'paypal_order_id', 'paypal_capture_id',
            'approval_url', 'local_amount', 'local_currency', 'exchange_rate',
            'status', 'error_message', 'created_at', 'updated_at',
        ]
        read_only_fields = [
            'id', 'order_id', 'user', 'user_email', 'user_name',
            'gateway', 'paypal_order_id', 'paypal_capture_id',
            'approval_url', 'status', 'error_message', 'created_at', 'updated_at',
        ]


class WalletTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = WalletTransaction
        fields = [
            'id', 'transaction_type', 'amount', 'currency',
            'status', 'description', 'created_at',
        ]
        read_only_fields = fields


class WithdrawalRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = WithdrawalRequest
        fields = [
            'id', 'amount', 'currency', 'status', 'payout_method',
            'paypal_email', 'bank_account_name', 'bank_account_number',
            'bank_name', 'admin_note', 'requested_at', 'processed_at',
        ]
        read_only_fields = ['status', 'admin_note', 'requested_at', 'processed_at']


class ExchangeRateCacheSerializer(serializers.ModelSerializer):
    class Meta:
        model = ExchangeRateCache
        fields = ['base_currency', 'target_currency', 'rate', 'updated_at']