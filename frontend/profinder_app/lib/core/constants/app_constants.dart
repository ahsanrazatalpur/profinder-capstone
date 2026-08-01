// PATH: lib/core/constants/app_constants.dart
// lib/core/constants/app_constants.dart

import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  static String get baseUrl {
    return 'https://ahsanrazatalpur.pythonanywhere.com/api';
  }

  // ✅ NEW — WebSocket base (same host as baseUrl, ws:// scheme, no /api
  // suffix since Channels routing is mounted at the ASGI root — see
  // backend/apps/messaging/routing.py: `ws/chat/<id>/`).
  static String get wsBaseUrl {
    return 'wss://ahsanrazatalpur.pythonanywhere.com';
  }

  // ─── Auth ────────────────────────────────────────────────
  static const String register       = '/users/register/';
  static const String login          = '/users/login/';
  static const String tokenRefresh   = '/users/token/refresh/';
  static const String me             = '/users/me/';
  static const String forgotPassword = '/users/forgot-password/';
  static const String checkEmail     = '/users/check-email/'; // ✅ NEW — Register Step 1 live email check
  static const String countries      = '/users/countries/';   // ✅ NEW — Register Step 2 location
  static const String cities         = '/users/cities/';      // ✅ NEW — Register Step 2 location (append ?country=<id>)
  static const String changePassword = '/users/change-password/'; // ✅ NEW — logged-in password change
  static const String updateLanguage = '/users/language/'; // ✅ NEW — i18n sync

  // ─── Profiles ────────────────────────────────────────────
  static const String userProfile         = '/profiles/user/';
  static const String professionalProfile = '/profiles/professional/';
  static const String portfolio           = '/profiles/portfolio/';
  static const String adminPortfolio      = '/profiles/admin/portfolio/';
  // ⚠️ BACKEND NOTE: '/profiles/certificates/' endpoint needs a matching
  // model (title, issuing_organization, issue_date, certificate_image,
  // status) + CRUD viewset, same shape as the existing Portfolio model.
  static const String certificates        = '/profiles/certificates/'; // ✅ NEW
  // ⚠️ BACKEND NOTE: '/profiles/gallery/' also needs a new model (image only,
  // no title required) + CRUD viewset — distinct from Portfolio (which has
  // title/description and admin approval).
  static const String gallery              = '/profiles/gallery/'; // ✅ NEW

  // ─── Messaging ───────────────────────────────────────────
  // ✅ NEW APP — apps/messaging (Conversation + Message models)
  static const String conversations = '/messaging/conversations/';
  static String conversationMessages(int conversationId) =>
      '/messaging/conversations/$conversationId/messages/';

  // ✅ NEW — cursor pagination for the messages endpoint. Backward
  // compatible: omitting both query params returns the same "latest page"
  // behavior as before, just capped at `limit` instead of the full thread.
  static String conversationMessagesPage(int conversationId, {String? beforeId, int limit = 30}) {
    final query = <String, String>{'limit': '$limit', if (beforeId != null) 'before_id': beforeId};
    final qs = query.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '/messaging/conversations/$conversationId/messages/?$qs';
  }

  static String markDelivered(int conversationId) => '/messaging/conversations/$conversationId/mark-delivered/';
  static String markSeen(int conversationId) => '/messaging/conversations/$conversationId/mark-seen/';
  static String messageDetail(String messageId) => '/messaging/messages/$messageId/';
  static String wsChat(int conversationId) => '/ws/chat/$conversationId/';

  // ✅ NEW — premium messaging features
  static String conversationSearch(String query) => '/messaging/conversations/?search=${Uri.encodeQueryComponent(query)}';
  static String archivedConversations() => '/messaging/conversations/?archived=true';
  static String conversationState(int conversationId) => '/messaging/conversations/$conversationId/state/';
  static String conversationMedia(int conversationId) => '/messaging/conversations/$conversationId/media/';
  static String messageSearch(int conversationId, String query) =>
      '/messaging/conversations/$conversationId/messages/?search=${Uri.encodeQueryComponent(query)}';
  static String messageReactions(String messageId) => '/messaging/messages/$messageId/reactions/';
  static String deleteForMe(String messageId) => '/messaging/messages/$messageId/?for=me';
  static const String blockedUsers = '/messaging/blocked-users/';
  static String unblockUser(int userId) => '/messaging/blocked-users/$userId/';
  // 🐛 FIX: was '/messaging/reports/', which writes into apps.messaging's
  // OWN UserReport table. The Admin Panel's "Reported Users" screen reads
  // from a completely different, unrelated UserReport model over in
  // apps.admin_panel — so reports were submitting successfully but never
  // showing up for admins. This is the endpoint admin_panel actually reads.
  static const String reportUser = '/admin-panel/reports/create/';

  // ✅ NEW — Analytics
  static const String professionalAnalytics = '/profiles/professional/analytics/';

  // ─── Search ──────────────────────────────────────────────
  static const String categories = '/search/categories/';
  static const String featuredCategories = '/search/categories/featured/';
  static const String nearby     = '/search/nearby/';
  // ✅ NEW — single-call Customer Dashboard feed: Recommended / Nearby /
  // Top Rated / Trending, each properly ranked & de-duplicated server-side.
  static const String homeFeed   = '/search/home-feed/';
  static const String favorites  = '/search/favorites/';
  static String favoriteToggle(String professionalId) => '/search/favorites/$professionalId/toggle/';
  static const String aiSearch       = '/ai/search/';
  static const String aiSearchStatus = '/ai/search-status/';
  static const String aiRecommendations = '/ai/recommendations/';   // ✅ confirmed: apps/ai_engine/urls.py
  static const String aiSearchHistory   = '/ai/search-history/';    // ✅ confirmed: apps/ai_engine/urls.py

  // ⚠️ NO backend endpoint exists for this anywhere in the project.
  // Pointed at '/search/' (closest existing text-search-ish view) so the
  // app compiles, but this will NOT return real autocomplete suggestions
  // until a dedicated view is built. Tell me if you want that built.
  static const String suggest = '/search/';

  // ─── Bookings ─────────────────────────────────────────────
  static const String bookings             = '/bookings/';
  static const String professionalBookings = '/bookings/professional/';
  static const String professionalDashboard = '/bookings/professional/dashboard/'; // ✅ NEW — Home Dashboard (single call)

  // ─── Subscriptions ────────────────────────────────────────
  static const String subscriptions    = '/subscriptions/';
  static const String myPlan           = '/subscriptions/my-plan/';
  static const String subscriptionPlans= '/subscriptions/plans/';
  static const String cancelSub        = '/subscriptions/cancel/';

  // ─── Promo Banners ────────────────────────────────────────
  static const String activeBanner     = '/admin-panel/promo-banners/active/';

  // ─── Others ──────────────────────────────────────────────
  // ✅ FIX: matches new MyReviewsView — logged-in professional's own reviews
  // (used by Dashboard "Recent Reviews" + full Reviews screen)
  static const String reviews       = '/reviews/my-reviews/';
  // ✅ NEW: reviews for a *specific* professional_id (used when viewing
  // someone else's profile, or by MyReviewsScreen to check "did I review them").
  // Actual route: /reviews/professionals/<id>/reviews/
  static const String reviewsForProfessionalBase = '/reviews/professionals/';
  // ✅ NEW — review-level actions. Build with a review id, e.g.
  //   '${AppConstants.reviewDetailBase}42/'          → PATCH edit / DELETE
  //   '${AppConstants.reviewDetailBase}42/helpful/'  → POST toggle helpful
  //   '${AppConstants.reviewDetailBase}42/reply/'    → POST professional reply
  //   '${AppConstants.reviewDetailBase}42/report/'   → POST report
  static const String reviewDetailBase = '/reviews/';
  // ✅ NEW — the logged-in customer's own written reviews, across every
  // professional. Replaces the old N-professional client-side loop.
  static const String myGivenReviews = '/reviews/mine/';

  // ✅ NEW — premium review actions
  static String reviewDetail(int reviewId)  => '/reviews/$reviewId/';
  static String reviewHelpful(int reviewId) => '/reviews/$reviewId/helpful/';
  static String reviewReply(int reviewId)   => '/reviews/$reviewId/reply/';
  static String reviewReport(int reviewId)  => '/reviews/$reviewId/report/';

  static const String notifications = '/notifications/';
  static const String payments      = '/payments/';   // ✅ confirmed: apps/payments/urls.py (PaymentView)

  // ── Wallet & Earnings ──────────────────────────────────────────────
  static const String walletSummary = '/payments/wallet/';       // ✅ NEW
  static const String withdrawals   = '/payments/withdrawals/';  // ✅ NEW

  // ─── Storage Keys ────────────────────────────────────────
  static const String accessTokenKey  = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userRoleKey     = 'user_role';
  static const String userIdKey       = 'user_id';
  static const String isGuestKey      = 'is_guest';

  // ─── App Info ─────────────────────────────────────────────
  static const String appName    = 'ProFinder';
  static const String appVersion = '1.0.0';
}