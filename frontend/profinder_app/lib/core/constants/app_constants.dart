/// Central API endpoint registry, WebSocket URLs, and local storage keys for ProFinder.
class AppConstants {
  AppConstants._();

  static String get baseUrl {
    return 'https://ahsanrazatalpur.pythonanywhere.com/api';
  }

  // WebSocket base URL for real-time messaging using wss:// protocol.
  static String get wsBaseUrl {
    return 'wss://ahsanrazatalpur.pythonanywhere.com';
  }

  // ─── Auth ────────────────────────────────────────────────
  static const String register = '/users/register/';
  static const String login = '/users/login/';
  static const String googleLogin = '/users/google/';
  static const String tokenRefresh = '/users/token/refresh/';
  static const String me = '/users/me/';
  static const String forgotPassword = '/users/forgot-password/';
  static const String sendOtp = '/users/send-otp/';
  static const String verifyOtp = '/users/verify-otp/';
  static const String resetPasswordOtp = '/users/reset-password-otp/';
  static const String checkEmail = '/users/check-email/';
  static const String countries = '/users/countries/';
  static const String cities = '/users/cities/';
  static const String changePassword = '/users/change-password/';
  static const String updateLanguage = '/users/language/';
  static const String deleteAccountRequestOtp = '/users/delete-account/request-otp/';
  static const String deleteAccountConfirm = '/users/delete-account/confirm/';

  // ─── Profiles ────────────────────────────────────────────
  static const String userProfile = '/profiles/user/';
  static const String professionalProfile = '/profiles/professional/';
  static const String portfolio = '/profiles/portfolio/';
  static const String adminPortfolio = '/profiles/admin/portfolio/';
  static const String certificates = '/profiles/certificates/';
  static const String gallery = '/profiles/gallery/';

  // ─── Messaging ───────────────────────────────────────────
  static const String conversations = '/messaging/conversations/';
  static String conversationMessages(int conversationId) =>
      '/messaging/conversations/$conversationId/messages/';

  /// Cursor pagination for conversation messages.
  static String conversationMessagesPage(
    int conversationId, {
    String? beforeId,
    int limit = 30,
  }) {
    final query = <String, String>{'limit': '$limit', 'before_id': ?beforeId};
    final qs = query.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '/messaging/conversations/$conversationId/messages/?$qs';
  }

  static String markDelivered(int conversationId) =>
      '/messaging/conversations/$conversationId/mark-delivered/';
  static String markSeen(int conversationId) =>
      '/messaging/conversations/$conversationId/mark-seen/';
  static String messageDetail(String messageId) =>
      '/messaging/messages/$messageId/';
  static String wsChat(int conversationId) => '/ws/chat/$conversationId/';

  // Messaging search, state, and moderation
  static String conversationSearch(String query) =>
      '/messaging/conversations/?search=${Uri.encodeQueryComponent(query)}';
  static String archivedConversations() =>
      '/messaging/conversations/?archived=true';
  static String conversationState(int conversationId) =>
      '/messaging/conversations/$conversationId/state/';
  static String conversationMedia(int conversationId) =>
      '/messaging/conversations/$conversationId/media/';
  static String messageSearch(int conversationId, String query) =>
      '/messaging/conversations/$conversationId/messages/?search=${Uri.encodeQueryComponent(query)}';
  static String messageReactions(String messageId) =>
      '/messaging/messages/$messageId/reactions/';
  static String deleteForMe(String messageId) =>
      '/messaging/messages/$messageId/?for=me';
  static const String blockedUsers = '/messaging/blocked-users/';
  static String unblockUser(int userId) => '/messaging/blocked-users/$userId/';
  static const String reportUser = '/admin-panel/reports/create/';

  // ─── Trust & Safety ──────────────────────────────────────
  static const String myReports = '/admin-panel/reports/mine/';
  static const String myModerationStatus =
      '/admin-panel/moderation-status/mine/';
  static const String appealCreate = '/admin-panel/appeals/create/';
  static const String myAppeals = '/admin-panel/appeals/mine/';

  // ─── Analytics ───────────────────────────────────────────
  static const String professionalAnalytics =
      '/profiles/professional/analytics/';

  // ─── Search & Recommendations ────────────────────────────
  static const String categories = '/search/categories/';
  static const String featuredCategories = '/search/categories/featured/';
  static const String nearby = '/search/nearby/';
  static const String homeFeed = '/search/home-feed/';
  static const String favorites = '/search/favorites/';
  static String favoriteToggle(String professionalId) =>
      '/search/favorites/$professionalId/toggle/';
  static const String aiSearch = '/ai/search/';
  static const String aiSearchStatus = '/ai/search-status/';
  static const String aiRecommendations = '/ai/recommendations/';
  static const String aiLocalize = '/ai/localize/';
  static const String aiSearchHistory = '/ai/search-history/';
  static const String suggest = '/search/suggest/';

  // ─── Bookings ─────────────────────────────────────────────
  static const String bookings = '/bookings/';
  static const String professionalBookings = '/bookings/professional/';
  static const String professionalDashboard =
      '/bookings/professional/dashboard/';

  // ─── Subscriptions ────────────────────────────────────────
  static const String subscriptions = '/subscriptions/';
  static const String myPlan = '/subscriptions/my-plan/';
  static const String subscriptionPlans = '/subscriptions/plans/';
  static const String cancelSub = '/subscriptions/cancel/';

  // ─── Promo Banners ────────────────────────────────────────
  static const String activeBanner = '/admin-panel/promo-banners/active/';

  // ─── Reviews ──────────────────────────────────────────────
  static const String reviews = '/reviews/my-reviews/';
  static const String reviewsForProfessionalBase = '/reviews/professionals/';
  static const String reviewDetailBase = '/reviews/';
  static const String myGivenReviews = '/reviews/mine/';

  static String reviewDetail(int reviewId) => '/reviews/$reviewId/';
  static String reviewHelpful(int reviewId) => '/reviews/$reviewId/helpful/';
  static String reviewReply(int reviewId) => '/reviews/$reviewId/reply/';
  static String reviewReport(int reviewId) => '/reviews/$reviewId/report/';

  // ─── Notifications & Payments ─────────────────────────────
  static const String notifications = '/notifications/';
  static const String payments = '/payments/';
  static const String paymentBookingCreate = '/payments/booking/create/';
  static const String paymentSubscriptionCreate =
      '/payments/subscription/create/';
  static const String paymentCapture = '/payments/capture/';
  static const String paymentCurrencies = '/payments/currencies/';
  static const String paymentExchangeRates = '/payments/exchange-rates/';

  // ─── Wallet & Withdrawals ─────────────────────────────────
  static const String walletSummary = '/payments/wallet/';
  static const String withdrawals = '/payments/withdrawals/';

  // ─── Storage Keys ────────────────────────────────────────
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userRoleKey = 'user_role';
  static const String userIdKey = 'user_id';
  static const String isGuestKey = 'is_guest';

  // ─── App Info ─────────────────────────────────────────────
  static const String appName = 'ProFinder';
  static const String appVersion = '1.0.0';
}
