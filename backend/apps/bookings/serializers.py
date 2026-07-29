# apps/bookings/serializers.py

from rest_framework import serializers
from apps.bookings.models import Booking
from apps.users.models import User


class BookingSerializer(serializers.ModelSerializer):
    professional_name = serializers.SerializerMethodField(read_only=True)
    customer_name     = serializers.SerializerMethodField(read_only=True)

    # ✅ NEW — MyBookings card redesign ke liye. ProfessionalProfile /
    # UserProfile pehle se ye data rakhte hain, bas Booking API se
    # expose nahi ho rahe the.
    profession       = serializers.SerializerMethodField(read_only=True)
    professional_rating  = serializers.SerializerMethodField(read_only=True)
    professional_reviews = serializers.SerializerMethodField(read_only=True)
    location          = serializers.SerializerMethodField(read_only=True)
    professional_verified = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model  = Booking
        fields = ['id', 'customer', 'professional', 'professional_name',
                  'customer_name', 'date', 'time', 'note', 'status',
                  'cancel_reason', 'cancelled_by', 'created_at',
                  'profession', 'professional_rating', 'professional_reviews',
                  'location', 'professional_verified']
        # FIX: professional bhi read_only — view already handle karta hai isko
        read_only_fields = ['customer', 'professional', 'status', 'created_at',
                            'professional_name', 'customer_name',
                            'cancel_reason', 'cancelled_by',
                            'profession', 'professional_rating',
                            'professional_reviews', 'location',
                            'professional_verified']

    def get_professional_name(self, obj):
        return obj.professional.name if obj.professional else ''

    def get_customer_name(self, obj):
        return obj.customer.name if obj.customer else ''

    def get_profession(self, obj):
        if not obj.professional:
            return ''
        profile = getattr(obj.professional, 'professionalprofile', None)
        if profile and profile.category:
            return profile.category.name
        return ''

    def get_professional_rating(self, obj):
        if not obj.professional:
            return 0.0
        profile = getattr(obj.professional, 'professionalprofile', None)
        return float(profile.average_rating) if profile else 0.0

    def get_professional_reviews(self, obj):
        if not obj.professional:
            return 0
        # Lazy import — circular-import se bachne ke liye
        from apps.reviews.models import Review
        return Review.objects.filter(
            professional=obj.professional, is_hidden=False).count()

    def get_location(self, obj):
        if not obj.professional:
            return ''
        profile = getattr(obj.professional, 'userprofile', None)
        if not profile:
            return ''
        parts = [p for p in [profile.area, profile.city] if p]
        return ', '.join(parts)

    def get_professional_verified(self, obj):
        if not obj.professional:
            return False
        profile = getattr(obj.professional, 'professionalprofile', None)
        return bool(profile.is_verified) if profile else False

    def validate_time(self, value):
        # Accept both "08:00 AM" and "08:00:00" formats
        if isinstance(value, str):
            import re
            # Convert "08:00 AM" → "08:00:00"
            match = re.match(r'(\d{1,2}):(\d{2})\s*(AM|PM)', value, re.IGNORECASE)
            if match:
                hour   = int(match.group(1))
                minute = int(match.group(2))
                period = match.group(3).upper()
                if period == 'PM' and hour != 12:
                    hour += 12
                elif period == 'AM' and hour == 12:
                    hour = 0
                from datetime import time
                return time(hour, minute)
        return value