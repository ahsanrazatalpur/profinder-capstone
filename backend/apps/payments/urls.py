# apps/payments/urls.py

from django.urls import path
from apps.payments.views import (
    PaymentView,
    CreateBookingPaymentView,
    CreateSubscriptionPaymentView,
    CapturePaymentView,
    PayPalWebhookView,
    WalletSummaryView,
    WithdrawalRequestView,
    CurrencyListView,
    ExchangeRatesView,
)

urlpatterns = [
    path('', PaymentView.as_view(), name='payments'),
    path('booking/create/', CreateBookingPaymentView.as_view(), name='payment_booking_create'),
    path('subscription/create/', CreateSubscriptionPaymentView.as_view(), name='payment_subscription_create'),
    path('capture/', CapturePaymentView.as_view(), name='payment_capture'),
    path('webhook/', PayPalWebhookView.as_view(), name='payment_webhook'),
    path('wallet/', WalletSummaryView.as_view(), name='wallet_summary'),
    path('withdrawals/', WithdrawalRequestView.as_view(), name='withdrawals'),
    path('currencies/', CurrencyListView.as_view(), name='currencies'),
    path('exchange-rates/', ExchangeRatesView.as_view(), name='exchange_rates'),
]