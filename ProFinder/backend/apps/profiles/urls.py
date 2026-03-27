from django.urls import path
from apps.profiles.views import UserProfileView, ProfessionalProfileView

urlpatterns = [
    path('user/', UserProfileView.as_view(), name='user_profile'),
    path('professional/', ProfessionalProfileView.as_view(), name='professional_profile'),
]