# apps/admin_panel/urls.py

from django.urls import path
from apps.admin_panel.views import (
    AdminLogView,
    AdminLogDeleteView,
    AdminUserDetailView,
    BanUserView,
    VerifyProfessionalView,
    RemindProfessionalView,
    AdminBlockedUsersView,
    AdminVerificationRequestsView,
    AdminVerificationActionView,
    AdminBookingView,
    AdminCancelBookingView,
    PromoBannerAdminView,
    ContentTranslationAdminView,
    PromoBannerImageUploadView,
    ActivePromoBannerView,
    AdminSubscriptionPlanView,
    AdminPlanFeatureView,
    AdminDashboardView,
    AdminAnalyticsView,
    ReportUserView,
    MyReportsView,
    AdminReportedUsersView,
    AdminReportActionView,
    AdminModerationActionCreateView,
    AdminModerationActionReverseView,
    AdminUserModerationHistoryView,
    MyModerationStatusView,
    AdminReportModerationActionsView,
    AppealCreateView,
    MyAppealsView,
    AdminAppealListView,
    AdminAppealDetailView,
    AdminAppealApproveView,
    AdminAppealRejectView,
    AdminCategoryView,
    AdminSubCategoryView,
    AdminPaymentView,
    AdminPaymentRefundView,
    AdminRevenueView,
    AdminSubscriptionsView,
    AdminSubscriptionActionView,
    AdminReviewView,
    AdminComplaintView,
    AdminComplaintActionView,
    AdminReportsView,
    AdminNotificationView,
    AdminNotificationCancelView,
    AdminLanguageView,
    AdminLanguageDetailView,
    AdminTranslationView,
    AdminTranslationKeyView,
    AdminCountryView,
    AdminCountryDetailView,
    AdminCountryMergeView,
    AdminCityView,
    AdminCityDetailView,
    AdminCityMergeView,
    AdminAnnouncementView,
    AdminAnnouncementDetailView,
    ActiveAnnouncementView,
)

urlpatterns = [
    # ── Dashboard ──────────────────────────────────────────────────────────────
    path('dashboard/',                                     AdminDashboardView.as_view(),         name='admin_dashboard'),
    path('analytics/',                                     AdminAnalyticsView.as_view(),         name='admin_analytics'),

    # ── Logs ───────────────────────────────────────────────────────────────────
    path('logs/',                                          AdminLogView.as_view(),               name='admin_logs'),
    path('logs/clear/',                                    AdminLogDeleteView.as_view(),         name='admin_logs_clear'),
    path('logs/<int:log_id>/',                             AdminLogDeleteView.as_view(),         name='admin_log_delete'),

    # ── Users ──────────────────────────────────────────────────────────────────
    path('users/<int:user_id>/details/',                  AdminUserDetailView.as_view(),        name='admin_user_details'),
    path('users/<int:user_id>/ban/',                       BanUserView.as_view(),                name='ban_user'),
    path('users/<int:user_id>/verify/',                    VerifyProfessionalView.as_view(),     name='verify_professional'),
    path('users/<int:user_id>/remind/',                    RemindProfessionalView.as_view(),     name='remind_professional'),
    path('blocked-users/',                                 AdminBlockedUsersView.as_view(),      name='admin_blocked_users'),
    path('verification-requests/',                         AdminVerificationRequestsView.as_view(), name='admin_verification_requests'),
    path('verification-requests/<int:user_id>/action/',    AdminVerificationActionView.as_view(),name='admin_verification_action'),

    # ── Bookings ───────────────────────────────────────────────────────────────
    path('bookings/',                                      AdminBookingView.as_view(),           name='admin_bookings'),
    path('bookings/<int:booking_id>/cancel/',              AdminCancelBookingView.as_view(),     name='admin_cancel_booking'),

    # ── Promo Banners ──────────────────────────────────────────────────────────
    path('promo-banners/',                                 PromoBannerAdminView.as_view(),       name='promo_banners'),
    path('promo-banners/upload-image/',                    PromoBannerImageUploadView.as_view(), name='promo_banner_upload_image'),
    path('promo-banners/active/',                          ActivePromoBannerView.as_view(),      name='active_promo_banner'),
    path('promo-banners/<int:banner_id>/',                 PromoBannerAdminView.as_view(),       name='promo_banner_detail'),

    # ── Subscription Plan Management ───────────────────────────────────────────
    path('plans/',                                         AdminSubscriptionPlanView.as_view(),  name='admin_plans'),
    path('plans/<int:plan_id>/',                           AdminSubscriptionPlanView.as_view(),  name='admin_plan_detail'),
    path('plans/<int:plan_id>/features/',                  AdminPlanFeatureView.as_view(),       name='admin_plan_features'),
    path('plans/<int:plan_id>/features/<str:feature_key>/',AdminPlanFeatureView.as_view(),       name='admin_plan_feature_edit'),

    # ── Reported Users (Trust & Safety) ─────────────────────────────────────────
    # GET+POST '/reports/' is dual-purpose: GET → admin-only list (AdminReportedUsersView),
    # POST → any authenticated user submits a report (ReportUserView).
    path('reports/',                                       AdminReportedUsersView.as_view(),     name='admin_reports_list'),
    path('reports/create/',                                ReportUserView.as_view(),             name='report_user'),
    # User-facing (Trust & Safety Part 8): reports the CURRENT user submitted,
    # never anyone else's. Must come before '<int:report_id>/' so 'mine/'
    # isn't swallowed by that pattern.
    path('reports/mine/',                                  MyReportsView.as_view(),              name='my_reports'),
    path('reports/<int:report_id>/',                       AdminReportActionView.as_view(),      name='admin_report_action'),
    path('reports/<int:report_id>/moderation-actions/',    AdminReportModerationActionsView.as_view(), name='admin_report_moderation_actions'),

    # ── Moderation Actions (Trust & Safety Part 4) ──────────────────────────────
    path('moderation-actions/',                            AdminModerationActionCreateView.as_view(),  name='admin_moderation_action_create'),
    path('moderation-actions/<int:action_id>/reverse/',    AdminModerationActionReverseView.as_view(), name='admin_moderation_action_reverse'),
    path('users/<int:user_id>/moderation-actions/',        AdminUserModerationHistoryView.as_view(),   name='admin_user_moderation_actions'),
    # User-facing (Trust & Safety Part 8): the CURRENT user's own live status,
    # always re-derived server-side — see MyModerationStatusView docstring.
    path('moderation-status/mine/',                        MyModerationStatusView.as_view(),           name='my_moderation_status'),

    # ── Appeals (Trust & Safety Part 6) ─────────────────────────────────────────
    # User-facing (own appeals only):
    path('appeals/create/',                                AppealCreateView.as_view(),                 name='appeal_create'),
    path('appeals/mine/',                                  MyAppealsView.as_view(),                    name='appeal_mine'),
    # Admin-only review:
    path('appeals/',                                       AdminAppealListView.as_view(),              name='admin_appeal_list'),
    path('appeals/<int:appeal_id>/',                       AdminAppealDetailView.as_view(),            name='admin_appeal_detail'),
    path('appeals/<int:appeal_id>/approve/',               AdminAppealApproveView.as_view(),           name='admin_appeal_approve'),
    path('appeals/<int:appeal_id>/reject/',                AdminAppealRejectView.as_view(),            name='admin_appeal_reject'),

    # ── Business Management: Categories & Subcategories ─────────────────────────
    path('categories/',                                    AdminCategoryView.as_view(),          name='admin_categories'),
    path('categories/<int:category_id>/',                  AdminCategoryView.as_view(),          name='admin_category_detail'),
    path('subcategories/',                                 AdminSubCategoryView.as_view(),       name='admin_subcategories'),
    path('subcategories/<int:subcategory_id>/',             AdminSubCategoryView.as_view(),       name='admin_subcategory_detail'),

    # ── Business Management: Payments ───────────────────────────────────────────
    path('payments/',                                      AdminPaymentView.as_view(),           name='admin_payments'),
    path('payments/<int:payment_id>/refund/',               AdminPaymentRefundView.as_view(),     name='admin_payment_refund'),

    # ── Business Management: Revenue ────────────────────────────────────────────
    path('revenue/',                                       AdminRevenueView.as_view(),           name='admin_revenue'),

    # ── Business Management: Subscriptions (active user subs) ───────────────────
    path('subscriptions/',                                 AdminSubscriptionsView.as_view(),     name='admin_subscriptions'),
    path('subscriptions/<int:subscription_id>/',            AdminSubscriptionActionView.as_view(),name='admin_subscription_action'),

    # ── Business Management: Reviews ─────────────────────────────────────────────
    path('reviews/',                                       AdminReviewView.as_view(),            name='admin_reviews'),
    path('reviews/<int:review_id>/',                       AdminReviewView.as_view(),            name='admin_review_delete'),

    # ── Business Management: Complaints ─────────────────────────────────────────
    path('complaints/',                                    AdminComplaintView.as_view(),         name='admin_complaints'),
    path('complaints/<int:complaint_id>/',                 AdminComplaintActionView.as_view(),   name='admin_complaint_action'),

    # ── Business Management: Reports (export hub) ───────────────────────────────
    path('reports-hub/',                                   AdminReportsView.as_view(),           name='admin_reports_hub'),

    # ── Content Management: Notifications (admin broadcast) ─────────────────────
    path('notifications/',                                 AdminNotificationView.as_view(),      name='admin_notifications'),
    path('notifications/<int:broadcast_id>/cancel/',       AdminNotificationCancelView.as_view(), name='admin_notification_cancel'),

    # ── Content Management: Languages ────────────────────────────────────────────
    path('languages/',                                     AdminLanguageView.as_view(),           name='admin_languages'),
    path('languages/<int:language_id>/',                   AdminLanguageDetailView.as_view(),     name='admin_language_detail'),
    path('languages/<int:language_id>/translations/',      AdminTranslationView.as_view(),        name='admin_translations'),
    path('translation-keys/',                              AdminTranslationKeyView.as_view(),     name='admin_translation_keys'),

    # ── Content Management: Countries ────────────────────────────────────────────
    path('countries/',                                     AdminCountryView.as_view(),            name='admin_countries'),
    path('countries/<int:country_id>/',                    AdminCountryDetailView.as_view(),      name='admin_country_detail'),
    path('countries/<int:country_id>/merge/',               AdminCountryMergeView.as_view(),       name='admin_country_merge'),

    # ── Content Management: Cities ───────────────────────────────────────────────
    path('cities/',                                        AdminCityView.as_view(),               name='admin_cities'),
    path('cities/<int:city_id>/',                          AdminCityDetailView.as_view(),         name='admin_city_detail'),
    path('cities/<int:city_id>/merge/',                     AdminCityMergeView.as_view(),          name='admin_city_merge'),

    # ── Content Management: Announcements ────────────────────────────────────────
    path('announcements/',                                 AdminAnnouncementView.as_view(),       name='admin_announcements'),
    # ✅ NEW: public, no-auth — Flutter Guest/Customer/Professional home screens
    # call this to know which announcements to show right now. Must come
    # BEFORE the <int:announcement_id> pattern below so 'active/' doesn't
    # get swallowed by it in some Django versions' matching order.
    path('announcements/active/',                          ActiveAnnouncementView.as_view(),      name='active_announcements'),
    path('announcements/<int:announcement_id>/',           AdminAnnouncementDetailView.as_view(), name='admin_announcement_detail'),

    # ── Content translations (generic: announcement, promobanner, ...) ───────────
    path('translations/<str:label>/<int:object_id>/<int:language_id>/',
         ContentTranslationAdminView.as_view(),                                  name='admin_content_translation'),
]