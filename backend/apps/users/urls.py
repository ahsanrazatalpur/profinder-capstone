# apps/users/urls.py 

from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from apps.users.views import (
    RegisterView, LoginView, UserView,
    ForgotPasswordView, ResetPasswordView, ChangePasswordView,
    AdminUserListView, CheckEmailView, PublicCountriesView, PublicCitiesView,
    UpdateLanguageView,
)

urlpatterns = [
    path('register/',                               RegisterView.as_view(),       name='register'),
    path('check-email/',                            CheckEmailView.as_view(),      name='check_email'),
    path('countries/',                              PublicCountriesView.as_view(), name='public_countries'),
    path('cities/',                                 PublicCitiesView.as_view(),    name='public_cities'),
    path('login/',                                  LoginView.as_view(),           name='login'),
    path('token/refresh/',                          TokenRefreshView.as_view(),    name='token_refresh'),
    path('me/',                                     UserView.as_view(),            name='user'),
    path('language/',                               UpdateLanguageView.as_view(),  name='update_language'),
    path('forgot-password/',                        ForgotPasswordView.as_view(),  name='forgot_password'),
    path('reset-password/<str:uidb64>/<str:token>/',ResetPasswordView.as_view(),   name='reset_password'),
    path('change-password/',                        ChangePasswordView.as_view(),  name='change_password'),
    path('',                                        AdminUserListView.as_view(),   name='admin_user_list'), 
]