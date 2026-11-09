# PATH: backend/apps/profiles/urls.py
# apps/profiles/urls.py

from django.urls import path
from apps.profiles.views import (
    UserProfileView,
    ProfessionalProfileView,
    PortfolioView,
    AdminPortfolioView,
    ProfessionalDashboardView,
    CertificateView,
    GalleryView,
    GalleryStageView,
    GalleryCommitView,
    SecondaryCategoryView,
    ProfessionalAnalyticsView,
)

urlpatterns = [
    path('user/',                               UserProfileView.as_view(),         name='user_profile'),
    path('professional/',                       ProfessionalProfileView.as_view(), name='professional_profile'),
    path('professional/<int:user_id>/',         ProfessionalProfileView.as_view(), name='professional_profile_public'),
    path('professional/dashboard/',             ProfessionalDashboardView.as_view(), name='professional_dashboard'),
    path('professional/analytics/',             ProfessionalAnalyticsView.as_view(), name='professional_analytics'),
    path('portfolio/',                          PortfolioView.as_view(),            name='portfolio'),
    path('portfolio/<int:portfolio_id>/',       PortfolioView.as_view(),            name='portfolio_delete'),
    path('portfolio/user/<int:user_id>/',       PortfolioView.as_view(),            name='portfolio_public'),

    # Certificates
    path('certificates/',                       CertificateView.as_view(),          name='certificates'),
    path('certificates/<int:certificate_id>/',  CertificateView.as_view(),          name='certificate_delete'),
    path('certificates/user/<int:user_id>/',    CertificateView.as_view(),          name='certificates_public'),

    # Gallery
    path('gallery/',                            GalleryView.as_view(),              name='gallery'),
    path('gallery/<int:image_id>/',             GalleryView.as_view(),              name='gallery_delete'),
    path('gallery/user/<int:user_id>/',         GalleryView.as_view(),              name='gallery_public'),
    path('gallery/stage/',                      GalleryStageView.as_view(),         name='gallery_stage'),
    path('gallery/commit/',                     GalleryCommitView.as_view(),        name='gallery_commit'),

    # Secondary Categories
    path('secondary-categories/',               SecondaryCategoryView.as_view(),    name='secondary_categories'),
    path('secondary-categories/<int:cat_id>/',  SecondaryCategoryView.as_view(),    name='secondary_category_delete'),
    path('secondary-categories/user/<int:user_id>/', SecondaryCategoryView.as_view(), name='secondary_categories_public'),

    # Admin endpoints
    path('admin/portfolio/',                    AdminPortfolioView.as_view(),       name='admin_portfolio'),
    path('admin/portfolio/<int:portfolio_id>/', AdminPortfolioView.as_view(),       name='admin_portfolio_detail'),
]
