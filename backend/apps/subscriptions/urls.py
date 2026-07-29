# apps/subscriptions/urls.py

from django.urls import path
from apps.subscriptions.views import (
    SubscriptionPlanView,
    SubscriptionView,
    CancelSubscriptionView,
    MyPlanView,
)

urlpatterns = [
    path('plans/',    SubscriptionPlanView.as_view(),  name='subscription_plans'),
    path('',          SubscriptionView.as_view(),      name='subscription'),
    path('cancel/',   CancelSubscriptionView.as_view(),name='subscription_cancel'),
    path('my-plan/',  MyPlanView.as_view(),            name='my_plan'),
]
