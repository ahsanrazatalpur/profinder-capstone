from rest_framework import serializers
from apps.profiles.models import UserProfile, ProfessionalProfile

class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = ['id', 'full_name', 'photo_url', 'phone', 'city', 'latitude', 'longitude']

class ProfessionalProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProfessionalProfile
        fields = ['id', 'bio', 'experience_years', 'hourly_rate', 'is_verified']