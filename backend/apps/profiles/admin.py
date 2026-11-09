# PATH: backend/apps/profiles/admin.py
from django.contrib import admin
from apps.profiles.models import (
    UserProfile,
    ProfessionalProfile,
    Portfolio,
    Certificate,
    GalleryImage,
    ProfileView,
    ProfessionalSecondaryCategory,
    StagedMedia,
)


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'full_name', 'country', 'city', 'phone', 'whatsapp_number')
    search_fields = ('user__email', 'full_name', 'phone', 'whatsapp_number')


@admin.register(ProfessionalProfile)
class ProfessionalProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'company_name', 'category', 'is_verified', 'identity_verified', 'credentials_verified')
    list_filter = ('is_verified', 'identity_verified', 'credentials_verified', 'category')
    search_fields = ('company_name', 'user__email', 'slug', 'whatsapp_number')


@admin.register(ProfessionalSecondaryCategory)
class ProfessionalSecondaryCategoryAdmin(admin.ModelAdmin):
    list_display = ('professional_profile', 'category', 'is_active', 'created_at')
    list_filter = ('is_active', 'category')
    search_fields = ('professional_profile__company_name', 'professional_profile__user__email', 'category__name')


@admin.register(StagedMedia)
class StagedMediaAdmin(admin.ModelAdmin):
    list_display = ('public_id', 'professional', 'status', 'lease_expires_at', 'created_at')
    list_filter = ('status',)
    search_fields = ('public_id', 'professional__email')
    readonly_fields = ('created_at', 'updated_at')


admin.site.register(Portfolio)
admin.site.register(Certificate)
admin.site.register(GalleryImage)
admin.site.register(ProfileView)
