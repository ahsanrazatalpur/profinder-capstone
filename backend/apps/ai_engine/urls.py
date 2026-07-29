from django.urls import path
from apps.ai_engine.views import (
    AIRecommendationView,
    SearchHistoryView,
    AISearchView,
    AISearchStatusView,
)

urlpatterns = [
    path('recommendations/', AIRecommendationView.as_view(), name='recommendations'),
    path('search-history/', SearchHistoryView.as_view(), name='search_history'),
    path('search/', AISearchView.as_view(), name='ai_search'),
    path('search-status/', AISearchStatusView.as_view(), name='ai_search_status'),
]