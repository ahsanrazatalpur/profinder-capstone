# PATH: backend/apps/profiles/admin.py
from django.contrib import admin
from apps.profiles.models import UserProfile, ProfessionalProfile, Portfolio, Certificate, GalleryImage, ProfileView

admin.site.register(UserProfile)
admin.site.register(ProfessionalProfile)
admin.site.register(Portfolio)
admin.site.register(Certificate)
admin.site.register(GalleryImage)
admin.site.register(ProfileView)