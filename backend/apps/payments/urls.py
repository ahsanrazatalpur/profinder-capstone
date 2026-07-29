from django.urls import path
from apps.payments.views import PaymentView, WalletSummaryView, WithdrawalRequestView

urlpatterns = [
    path('', PaymentView.as_view(), name='payments'),
    path('wallet/', WalletSummaryView.as_view(), name='wallet_summary'),          # ✅ NEW
    path('withdrawals/', WithdrawalRequestView.as_view(), name='withdrawals'),    # ✅ NEW
]