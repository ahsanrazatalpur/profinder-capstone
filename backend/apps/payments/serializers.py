from rest_framework import serializers
from apps.payments.models import Payment, WithdrawalRequest

class PaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Payment
        fields = ['id', 'user', 'amount', 'currency', 'stripe_id', 'status', 'created_at']
        read_only_fields = ['user', 'stripe_id', 'status', 'created_at']


class WithdrawalRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = WithdrawalRequest
        fields = [
            'id', 'amount', 'status', 'bank_account_name', 'bank_account_number',
            'bank_name', 'admin_note', 'requested_at', 'processed_at',
        ]
        read_only_fields = ['status', 'admin_note', 'requested_at', 'processed_at']