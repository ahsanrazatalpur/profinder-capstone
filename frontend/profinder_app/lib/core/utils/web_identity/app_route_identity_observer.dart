// lib/core/utils/web_identity/app_route_identity_observer.dart

import 'package:flutter/material.dart';
import 'web_identity.dart';

/// NavigatorObserver that synchronizes browser tab title and favicon with route transitions.
/// Handles browser Back / Forward history, route push, and route pop automatically.
class AppRouteIdentityObserver extends NavigatorObserver {
  static final Map<String, String> _routeTitles = {
    '/': 'ProFinder | Find Trusted Professionals in Pakistan',
    '/home': 'ProFinder | Find Trusted Professionals in Pakistan',
    '/search': 'Search Professionals in Pakistan | ProFinder',
    '/magazine': 'Magazine | ProFinder',
    '/bookings': 'My Bookings | ProFinder',
    '/profile': 'My Profile | ProFinder',
    '/notifications': 'Notifications | ProFinder',
    '/login': 'Sign In | ProFinder',
    '/register': 'Create Account | ProFinder',
    '/forgot-password': 'Reset Password | ProFinder',
    '/pro': 'Professional Dashboard | ProFinder',
    '/pro/bookings': 'Manage Bookings | ProFinder',
    '/pro/profile': 'Professional Profile | ProFinder',
    '/pro/portfolio': 'Portfolio & Work Samples | ProFinder',
    '/admin': 'Admin Console | ProFinder',
  };

  void _applyIdentityForRoute(Route<dynamic>? route) {
    if (route == null) return;
    final name = route.settings.name;
    if (name != null && _routeTitles.containsKey(name)) {
      WebIdentity.setIdentity(
        title: _routeTitles[name]!,
        faviconUrl: WebIdentity.defaultFavicon,
      );
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _applyIdentityForRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _applyIdentityForRoute(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _applyIdentityForRoute(newRoute);
  }
}
