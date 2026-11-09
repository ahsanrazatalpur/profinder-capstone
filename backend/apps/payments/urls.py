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
    FeaturedPromotionPackagesListView,
    ProfessionalFeaturedStatusView,
    SafepayInitializeCheckoutView,
    SafepayVerifyPaymentView,
    SafepayWebhookView,
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

    # Safepay & Monetization Endpoints
    path('checkout/initialize/', SafepayInitializeCheckoutView.as_view(), name='safepay_checkout_initialize'),
    path('verify-status/', SafepayVerifyPaymentView.as_view(), name='safepay_verify_status'),
    path('webhook/safepay/', SafepayWebhookView.as_view(), name='safepay_webhook'),
    path('featured/packages/', FeaturedPromotionPackagesListView.as_view(), name='featured_packages_list'),
    path('featured/status/', ProfessionalFeaturedStatusView.as_view(), name='featured_status'),
]
