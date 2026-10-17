// Mixin for stateful widgets that triggers and manages promotional banner popups.
//
// Handles frequency capping, cooldown intervals, and role-based audience targeting.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/promo_banner_model.dart';
import '../services/promo_banner_service.dart';
import '../services/subscription_service.dart';
import '../../../services/auth_service.dart';
import '../../../core/constants/app_constants.dart';
import 'promo_banner_popup.dart';

mixin PromoBannerMixin<T extends StatefulWidget> on State<T> {
  final _bannerService = PromoBannerService();
  final _authService   = AuthService();
  final _subService    = SubscriptionService();

  /// Displays an eligible promotional banner for the specified screen trigger.
  /// [trigger]: Screen context ('home', 'search', 'ai_search', 'booking', 'login').
  Future<void> showBannerForScreen(
    String trigger, {
    int delaySeconds = 2,
  }) async {
    debugPrint('[Banner] ▶ showBannerForScreen called — trigger: $trigger');

    final isLoggedIn = await _authService.isLoggedIn();
    final role       = await _authService.getSavedRole() ?? 'guest';
    final prefs      = await SharedPreferences.getInstance();

    debugPrint('[Banner] isLoggedIn=$isLoggedIn  role=$role');

    // Prioritize login-triggered banners immediately following user authentication,
    // falling back to the default screen trigger if none are found.
    final justLoggedIn = prefs.getBool('just_logged_in_banner_flag') ?? false;
    bool tryLoginTriggerFirst = false;
    if (justLoggedIn) {
      // Verify user is authenticated before evaluating login banners.
      if (!isLoggedIn) {
        await prefs.remove('just_logged_in_banner_flag');
        debugPrint('[Banner] ✗ guest + just_logged_in flag — skipping');
        return;
      }
      await prefs.remove('just_logged_in_banner_flag');
      tryLoginTriggerFirst = true;
      debugPrint('[Banner] just logged in — will try login trigger first, then fallback to $trigger');
    }

    // Unique user cache key based on role and token signature
    final userKey = await _getCurrentUserKey(role);
    debugPrint('[Banner] userKey=$userKey');

    // Resolve audience segment according to auth status and plan tier
    String userType = 'guest';
    if (isLoggedIn) {
      bool isPremium = false;
      try {
        final plan = await _subService.getMyPlan();
        isPremium   = plan?.isPremium ?? false;
      } catch (_) {
        isPremium = false;
      }

      if (role == 'professional') {
        userType = isPremium ? 'premium_professional' : 'free_professional';
      } else if (role == 'customer') {
        userType = isPremium ? 'premium_customer' : 'free_customer';
      }
    }
    debugPrint('[Banner] userType=$userType  trigger=$trigger');

    await Future.delayed(Duration(seconds: delaySeconds));
    if (!mounted) {
      debugPrint('[Banner] ✗ widget unmounted after delay — aborting');
      return;
    }

    List<PromoBanner> banners = [];
    try {
      if (tryLoginTriggerFirst) {
        banners = await _bannerService.getActiveBanners(
          trigger:  'login',
          userType: userType,
        );
        debugPrint('[Banner] login-trigger fetch returned ${banners.length} banner(s)');
        if (banners.isEmpty) {
          // Fall back to original screen trigger if no login banner is configured
          banners = await _bannerService.getActiveBanners(
            trigger:  trigger,
            userType: userType,
          );
          debugPrint('[Banner] fallback to "$trigger" returned ${banners.length} banner(s)');
        } else {
          trigger = 'login';
        }
      } else {
        banners = await _bannerService.getActiveBanners(
          trigger:  trigger,
          userType: userType,
        );
      }
    } catch (e) {
      debugPrint('[Banner] ✗ API error: $e');
      return;
    }

    debugPrint('[Banner] API returned ${banners.length} banner(s)');
    for (final b in banners) {
      debugPrint('[Banner]   → id=${b.id} trigger=${b.trigger} audience=${b.targetAudience} title="${b.title}"');
    }

    if (!mounted || banners.isEmpty) {
      debugPrint('[Banner] ✗ no banners returned or widget unmounted');
      return;
    }

    // Select the first eligible banner that is not currently in cooldown
    PromoBanner? toShow;
    for (final b in banners) {
      final recentlyShown = await _wasShownRecently(userKey, b);
      debugPrint('[Banner] #${b.id} wasShownRecently=$recentlyShown');
      if (!recentlyShown) {
        toShow = b;
        break;
      }
    }

    if (toShow == null) {
      debugPrint('[Banner] ✗ all banners in cooldown or permanently dismissed');
    }

    if (toShow == null || !mounted) return;

    debugPrint('[Banner] showing banner #${toShow.id}: "${toShow.title}"');

    // Default guest display role to customer for dialog presentation
    final displayRole = role == 'professional' ? 'professional' : 'customer';

    final userTappedCta = await PromoBannerPopup.show(
      context,
      banner:   toShow,
      userRole: displayRole,
    );

    if (userTappedCta) {
      await _markShown(userKey, toShow.id);
    } else {
      await _incrementDismissCount(userKey, toShow.id);
    }
  }

  // Legacy alias
  Future<void> loadAndShowBanner({
    required String trigger,
    String? userType,
    String? userRole,
    int delaySeconds = 2,
  }) async {
    await showBannerForScreen(trigger, delaySeconds: delaySeconds);
  }

  // ── User Key Resolution ──────────────────────────────────────────────────
  // Creates a stable identifier combining role and token signature for per-user tracking.
  Future<String> _getCurrentUserKey(String role) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.accessTokenKey);
    if (token == null || token.isEmpty) return 'guest';
    final suffix = token.substring((token.length - 30).clamp(0, token.length));
    return '${role}_$suffix';
  }

  // ── Frequency Capping & Cooldown Checks ────────────────────────────────────
  // Checks whether a banner is in its cooldown window or has reached the 3-dismiss cap.
  Future<bool> _wasShownRecently(String userKey, PromoBanner banner) async {
    final prefs      = await SharedPreferences.getInstance();
    final shownKey   = 'banner_${userKey}_${banner.id}';
    final dismissKey = 'banner_dismiss_${userKey}_${banner.id}';

    // Permanently suppress if dismissed 3 or more times
    final dismissCount = prefs.getInt(dismissKey) ?? 0;
    if (dismissCount >= 3) {
      debugPrint('[Banner] #${banner.id} permanently hidden (dismissed $dismissCount times)');
      return true;
    }

    final ts = prefs.getInt(shownKey);
    if (ts == null) return false;

    // Determine cooldown days based on banner configuration
    final int cooldownDays = banner.trigger == 'every_x_days'
        ? banner.triggerXDays.clamp(1, 365)
        : 30;

    final cooldownMs = cooldownDays * 24 * 60 * 60 * 1000;
    final elapsedMs  = DateTime.now().millisecondsSinceEpoch - ts;

    final inCooldown = elapsedMs < cooldownMs;
    if (banner.trigger == 'every_x_days') {
      debugPrint(
        '[Banner] #${banner.id} every_${banner.triggerXDays}_days — '
        'elapsed: ${(elapsedMs / 86400000).toStringAsFixed(1)} days, '
        'cooldown: ${banner.triggerXDays} days, '
        'in_cooldown: $inCooldown',
      );
    }
    return inCooldown;
  }

  Future<void> _markShown(String userKey, int bannerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'banner_${userKey}_$bannerId',
      DateTime.now().millisecondsSinceEpoch,
    );
    debugPrint('[Banner] #$bannerId marked as shown for $userKey');
  }

  Future<void> _incrementDismissCount(String userKey, int bannerId) async {
    final prefs      = await SharedPreferences.getInstance();
    final dismissKey = 'banner_dismiss_${userKey}_$bannerId';
    final shownKey   = 'banner_${userKey}_$bannerId';
    final current    = prefs.getInt(dismissKey) ?? 0;
    await prefs.setInt(dismissKey, current + 1);
    // Reset timestamp for subsequent cooldown calculation
    await prefs.setInt(shownKey, DateTime.now().millisecondsSinceEpoch);
    debugPrint('[Banner] #$bannerId dismiss count: ${current + 1}/3 for $userKey');
  }

  /// Clears persisted banner display timestamps and dismissal counts for testing.
  Future<void> clearBannerCache() async {
    final prefs   = await SharedPreferences.getInstance();
    final role    = await _authService.getSavedRole() ?? 'guest';
    final userKey = await _getCurrentUserKey(role);
    final keys    = prefs.getKeys()
        .where((k) =>
          k.startsWith('banner_${userKey}_') ||
          k.startsWith('banner_dismiss_${userKey}_'))
        .toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
    debugPrint('[Banner] Cache cleared for $userKey (${keys.length} keys removed)');
  }
}