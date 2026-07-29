from rest_framework import serializers
from apps.ai_engine.models import AIRecommendation, SearchHistory

class AIRecommendationSerializer(serializers.ModelSerializer):
    class Meta:
        model = AIRecommendation
        fields = ['id', 'user', 'professional', 'score', 'reason', 'created_at']
        read_only_fields = ['user', 'created_at']

class SearchHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = SearchHistory
        fields = ['id', 'user', 'query', 'created_at']
        read_only_fields = ['user', 'created_at']