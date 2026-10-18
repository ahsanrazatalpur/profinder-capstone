# apps/support/urls.py
#
# Mounted at /api/support/ (see profinder/urls.py).

from django.urls import path

from apps.support import admin_content_views, admin_views, ticket_views, views

urlpatterns = [
    # ── Public (no auth) ────────────────────────────────────────────────────
    path('policies/privacy/', views.PrivacyPolicyView.as_view(), name='support-privacy-policy'),
    path('help/categories/', views.HelpCategoryListView.as_view(), name='support-help-categories'),
    path('help/articles/', views.HelpArticleListView.as_view(), name='support-help-articles'),
    path('help/articles/<slug:slug>/', views.HelpArticleDetailView.as_view(),
         name='support-help-article'),

    # ── Tickets (login required) ────────────────────────────────────────────
    path('tickets/', ticket_views.TicketListCreateView.as_view(), name='support-tickets'),
    path('tickets/<int:pk>/', ticket_views.TicketDetailView.as_view(), name='support-ticket'),
    path('tickets/<int:pk>/messages/', ticket_views.TicketReplyView.as_view(),
         name='support-ticket-reply'),
    path('tickets/<int:pk>/close/', ticket_views.TicketCloseView.as_view(),
         name='support-ticket-close'),

    # ── Guest contact (no login, honeypot + throttle) ───────────────────────
    path('contact/', ticket_views.GuestContactView.as_view(), name='support-guest-contact'),

    # ── Admin ticket inbox (admin role only) ────────────────────────────────
    path('admin/tickets/summary/', admin_views.AdminTicketSummaryView.as_view(),
         name='support-admin-summary'),
    path('admin/tickets/', admin_views.AdminTicketListView.as_view(),
         name='support-admin-tickets'),
    path('admin/tickets/<int:pk>/', admin_views.AdminTicketDetailView.as_view(),
         name='support-admin-ticket'),
    path('admin/tickets/<int:pk>/reply/', admin_views.AdminTicketReplyView.as_view(),
         name='support-admin-ticket-reply'),

    # ── Admin content editor: privacy policy + help articles (admin role) ───
    path('admin/policy/', admin_content_views.AdminPolicyListView.as_view(),
         name='support-admin-policies'),
    path('admin/policy/<int:pk>/', admin_content_views.AdminPolicyDetailView.as_view(),
         name='support-admin-policy'),
    path('admin/policy/<int:pk>/publish/', admin_content_views.AdminPolicyPublishView.as_view(),
         name='support-admin-policy-publish'),
    path('admin/help/categories/', admin_content_views.AdminHelpCategoryListView.as_view(),
         name='support-admin-help-categories'),
    path('admin/help/articles/', admin_content_views.AdminHelpArticleListView.as_view(),
         name='support-admin-help-articles'),
    path('admin/help/articles/<int:pk>/', admin_content_views.AdminHelpArticleDetailView.as_view(),
         name='support-admin-help-article'),
]