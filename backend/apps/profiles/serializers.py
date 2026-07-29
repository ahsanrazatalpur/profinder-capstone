# apps/profiles/serializers.py

from rest_framework import serializers
from apps.profiles.models import UserProfile, ProfessionalProfile, Portfolio, Certificate, GalleryImage


class UserProfileSerializer(serializers.ModelSerializer):
    # GET ke liye full URL
    photo_url = serializers.SerializerMethodField()
    # PATCH ke liye write-only upload field
    photo     = serializers.ImageField(write_only=True, required=False)

    class Meta:
        model  = UserProfile
        fields = ['id', 'full_name', 'photo_url', 'photo', 'phone', 'gender', 'city', 'latitude', 'longitude']

    def get_photo_url(self, obj):
        if obj.photo_url:
            return obj.photo_url.url
        return None

    def update(self, instance, validated_data):
        photo = validated_data.pop('photo', None)
        if photo:
            instance.photo_url = photo   # CloudinaryField automatically upload karega
        return super().update(instance, validated_data)

    def validate_phone(self, value):
        value = value.strip()
        if value and len(value) > 20:
            raise serializers.ValidationError("Phone number is too long.")
        return value

    def validate_latitude(self, value):
        if value is not None and not (-90 <= float(value) <= 90):
            raise serializers.ValidationError("Latitude must be between -90 and 90.")
        return value

    def validate_longitude(self, value):
        if value is not None and not (-180 <= float(value) <= 180):
            raise serializers.ValidationError("Longitude must be between -180 and 180.")
        return value


class ProfessionalProfileSerializer(serializers.ModelSerializer):
    photo_url   = serializers.SerializerMethodField()
    cnic_url    = serializers.SerializerMethodField()
    license_url = serializers.SerializerMethodField()
    # ✅ Real-time presence (from messaging's UserPresence, updated by the
    # chat WebSocket) — separate from `is_available`, which is just the
    # professional's manual "open for bookings" toggle. The profile screen
    # needs BOTH: this for the green "Online" dot, is_available for the
    # "Availability" info card.
    is_online   = serializers.SerializerMethodField()
    last_seen   = serializers.SerializerMethodField()

    # Write-only upload fields
    photo   = serializers.ImageField(write_only=True, required=False)
    cnic    = serializers.ImageField(write_only=True, required=False)
    license = serializers.ImageField(write_only=True, required=False)

    class Meta:
        model  = ProfessionalProfile
        fields = ['id', 'photo_url', 'photo', 'bio', 'experience_years', 'hourly_rate',
                  'is_verified', 'average_rating', 'cnic_url', 'cnic', 'license_url', 'license',
                  'skills', 'is_available', 'is_online', 'last_seen',
                  'languages', 'education', 'working_hours_start', 'working_hours_end',  # ✅ NEW
                  'bank_account_name', 'bank_account_number', 'bank_name']  # ✅ NEW — Wallet ke liye
        read_only_fields = ['is_verified', 'average_rating']

    def get_photo_url(self, obj):
        return obj.photo_url.url if obj.photo_url else None

    def get_cnic_url(self, obj):
        return obj.cnic_url.url if obj.cnic_url else None

    def get_license_url(self, obj):
        return obj.license_url.url if obj.license_url else None

    def get_is_online(self, obj):
        presence = getattr(obj.user, 'presence', None)
        return bool(presence.is_online) if presence else False

    def get_last_seen(self, obj):
        presence = getattr(obj.user, 'presence', None)
        return presence.last_seen.isoformat() if presence and presence.last_seen else None

    def update(self, instance, validated_data):
        photo   = validated_data.pop('photo',   None)
        cnic    = validated_data.pop('cnic',    None)
        license = validated_data.pop('license', None)
        if photo:   instance.photo_url   = photo
        if cnic:    instance.cnic_url    = cnic
        if license: instance.license_url = license
        return super().update(instance, validated_data)

    def validate_hourly_rate(self, value):
        if float(value) < 0:
            raise serializers.ValidationError("Hourly rate cannot be negative.")
        if float(value) > 100000:
            raise serializers.ValidationError("Hourly rate seems unrealistically high.")
        return value

    def validate_experience_years(self, value):
        if value < 0:
            raise serializers.ValidationError("Experience years cannot be negative.")
        if value > 60:
            raise serializers.ValidationError("Experience years seems unrealistically high.")
        return value


class PortfolioSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()
    image     = serializers.ImageField(write_only=True, required=False)

    class Meta:
        model  = Portfolio
        fields = ['id', 'title', 'description', 'image_url', 'image', 'created_at']
        read_only_fields = ['created_at']

    def get_image_url(self, obj):
        return obj.image_url.url if obj.image_url else None

    def update(self, instance, validated_data):
        image = validated_data.pop('image', None)
        if image:
            instance.image_url = image
        return super().update(instance, validated_data)

    def validate_title(self, value):
        value = value.strip()
        if len(value) < 2:
            raise serializers.ValidationError("Title must be at least 2 characters.")
        return value


# ✅ NEW — Certificates
class CertificateSerializer(serializers.ModelSerializer):
    certificate_image = serializers.SerializerMethodField()
    image = serializers.ImageField(write_only=True, required=False)

    class Meta:
        model  = Certificate
        fields = ['id', 'title', 'issuing_organization', 'issue_date', 'certificate_image', 'image', 'created_at']
        read_only_fields = ['created_at']

    def get_certificate_image(self, obj):
        return obj.certificate_image.url if obj.certificate_image else None

    # NOTE: 'image' is write-only and doesn't match a model field name
    # directly (model field is 'certificate_image') — pop it before create()
    # so it isn't passed straight into Certificate.objects.create(**data).
    def create(self, validated_data):
        image = validated_data.pop('image', None)
        instance = Certificate.objects.create(**validated_data)
        if image:
            instance.certificate_image = image
            instance.save(update_fields=['certificate_image'])
        return instance

    def validate_title(self, value):
        value = value.strip()
        if len(value) < 2:
            raise serializers.ValidationError("Title must be at least 2 characters.")
        return value


# ✅ NEW — Gallery (photo-only, no title/description/approval)
class GalleryImageSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()
    image     = serializers.ImageField(write_only=True, required=True)

    class Meta:
        model  = GalleryImage
        fields = ['id', 'image_url', 'image', 'created_at']
        read_only_fields = ['created_at']

    def get_image_url(self, obj):
        return obj.image.url if obj.image else None