# apps/about_page/urls.py

from django.urls import path

from apps.about_page import views

urlpatterns = [
    # ── Public (Guest / Customer / Professional / Admin — read-only) ──────────
    path('', views.AboutPagePublicView.as_view(), name='about-page-public'),

    # ── Admin — Sections ────────────────────────────────────────────────────
    path('admin/sections/', views.AboutSectionAdminListCreateView.as_view(),
         name='about-admin-sections'),
    path('admin/sections/reorder/', views.AboutSectionReorderView.as_view(),
         name='about-admin-sections-reorder'),
    path('admin/sections/<int:section_id>/', views.AboutSectionAdminDetailView.as_view(),
         name='about-admin-section-detail'),

    # ── Admin — Dynamic collection items ────────────────────────────────────
    path('admin/sections/<int:section_id>/items/',
         views.AboutSectionItemAdminListCreateView.as_view(),
         name='about-admin-section-items'),
    path('admin/sections/<int:section_id>/items/reorder/',
         views.AboutSectionItemReorderView.as_view(),
         name='about-admin-section-items-reorder'),
    path('admin/items/<int:item_id>/', views.AboutSectionItemAdminDetailView.as_view(),
         name='about-admin-item-detail'),

    # ── Admin — Multilingual content ────────────────────────────────────────
    path('admin/sections/<int:section_id>/translations/<int:language_id>/',
         views.AboutSectionTranslationAdminView.as_view(),
         name='about-admin-section-translation'),
    path('admin/items/<int:item_id>/translations/<int:language_id>/',
         views.AboutSectionItemTranslationAdminView.as_view(),
         name='about-admin-item-translation'),

    # ── Admin — Media ────────────────────────────────────────────────────────
    path('admin/upload-image/', views.AboutImageUploadView.as_view(),
         name='about-admin-upload-image'),

    # ── Admin — SEO ──────────────────────────────────────────────────────────
    path('admin/seo/', views.AboutPageSEOAdminView.as_view(), name='about-admin-seo'),

    # ── Admin — Publish workflow ─────────────────────────────────────────────
    path('admin/status/', views.AboutPageStatusAdminView.as_view(), name='about-admin-status'),
    path('admin/preview/', views.AboutPagePreviewView.as_view(), name='about-admin-preview'),
    path('admin/publish/', views.AboutPagePublishView.as_view(), name='about-admin-publish'),
    path('admin/unpublish/', views.AboutPageUnpublishView.as_view(), name='about-admin-unpublish'),

    # ── Admin — Version history ─────────────────────────────────────────────
    path('admin/versions/', views.AboutPageVersionListView.as_view(), name='about-admin-versions'),
    path('admin/versions/<int:version_id>/', views.AboutPageVersionDetailView.as_view(),
         name='about-admin-version-detail'),
    path('admin/versions/<int:version_id>/restore/', views.AboutPageVersionRestoreView.as_view(),
         name='about-admin-version-restore'),
]