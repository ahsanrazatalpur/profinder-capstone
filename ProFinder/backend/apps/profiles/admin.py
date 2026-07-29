from django.contrib import admin
from apps.profiles.models import UserProfile, ProfessionalProfile

admin.site.register(UserProfile)
admin.site.register(ProfessionalProfile)