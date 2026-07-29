# apps/users/serializers.py

from rest_framework import serializers
from apps.users.models import User
from apps.profiles.models import UserProfile, ProfessionalProfile
from apps.search.models import Category


class RegisterSerializer(serializers.ModelSerializer):
    password    = serializers.CharField(write_only=True, min_length=8)
    email       = serializers.EmailField(max_length=254)
    name        = serializers.CharField(max_length=255)
    city        = serializers.CharField(max_length=100, required=False, allow_blank=True)
    country     = serializers.CharField(max_length=100, required=False, allow_blank=True)
    category_id = serializers.IntegerField(required=False, allow_null=True)

    class Meta:
        model  = User
        fields = ['email', 'name', 'role', 'password', 'city', 'country', 'category_id']

    def validate_email(self, value):
        value = value.strip().lower()
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("This email is already registered.")
        return value

    def validate_name(self, value):
        value = value.strip()
        if len(value) < 2:
            raise serializers.ValidationError("Name must be at least 2 characters.")
        return value

    def validate_role(self, value):
        allowed = ['customer', 'professional']
        if value not in allowed:
            raise serializers.ValidationError("Role must be 'customer' or 'professional'.")
        return value

    def validate_password(self, value):
        if len(value) < 8:
            raise serializers.ValidationError("Password must be at least 8 characters.")
        return value

    def create(self, validated_data):
        # Extract extra fields before creating user
        city        = validated_data.pop('city', '')
        country     = validated_data.pop('country', '')
        category_id = validated_data.pop('category_id', None)

        # Create user
        user = User.objects.create_user(
            email=validated_data['email'],
            name=validated_data['name'],
            role=validated_data['role'],
            password=validated_data['password'],
        )

        # Auto create UserProfile with city + country
        UserProfile.objects.create(
            user=user,
            city=city,
            country=country,
        )

        # If professional — auto create ProfessionalProfile with category
        if user.role == 'professional':
            prof = ProfessionalProfile.objects.create(user=user)
            if category_id:
                try:
                    category = Category.objects.get(id=category_id)
                    prof.category = category
                    prof.save()
                except Category.DoesNotExist:
                    pass

        return user


# ✅ i18n — used by PATCH /api/users/language/
class UpdateLanguageSerializer(serializers.Serializer):
    preferred_language = serializers.ChoiceField(choices=User.LANGUAGE_CHOICES)