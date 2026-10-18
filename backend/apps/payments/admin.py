# apps/payments/admin.py

from django.contrib import admin
from apps.payments.models import Payment, WalletTransaction, WithdrawalRequest, ExchangeRateCache


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ('order_id', 'user', 'amount', 'currency', 'purpose', 'status', 'gateway', 'created_at')
    list_filter = ('status', 'purpose', 'currency', 'gateway')
    search_fields = ('order_id', 'user__email', 'paypal_order_id', 'paypal_capture_id')
    readonly_fields = ('created_at', 'updated_at')


@admin.register(WalletTransaction)
class WalletTransactionAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'transaction_type', 'amount', 'currency', 'status', 'created_at')
    list_filter = ('transaction_type', 'status', 'currency')
    search_fields = ('user__email', 'description')
    readonly_fields = ('created_at', 'updated_at')


@admin.register(WithdrawalRequest)
class WithdrawalRequestAdmin(admin.ModelAdmin):
    list_display = ('id', 'professional', 'amount', 'currency', 'payout_method', 'status', 'requested_at')
    list_filter = ('status', 'payout_method')
    search_fields = ('professional__email', 'bank_account_number', 'paypal_email')
    readonly_fields = ('requested_at', 'processed_at')


@admin.register(ExchangeRateCache)
class ExchangeRateCacheAdmin(admin.ModelAdmin):
    list_display = ('base_currency', 'target_currency', 'rate', 'updated_at')
    search_fields = ('target_currency',)