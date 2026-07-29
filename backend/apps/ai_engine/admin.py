from django.contrib import admin
from apps.ai_engine.models import AIRecommendation, SearchHistory

admin.site.register(AIRecommendation)
admin.site.register(SearchHistory)