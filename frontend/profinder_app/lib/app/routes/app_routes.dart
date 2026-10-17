// lib/app/routes/app_routes.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/admin/screens/admin_main_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/bookings/screens/my_bookings_screen.dart';
import '../../features/home/screens/customer_home_screen.dart';
import '../../features/home/screens/guest_main_screen.dart';
import '../../features/magazine/screens/magazine_screen.dart';
import '../../features/notifications/screens/notification_screen.dart';
import '../../features/professional/screens/professional_main_screen.dart';
import '../../features/professional/screens/professional_portfolio_screen.dart';
import '../../features/profile/screens/customer_profile_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../services/auth_provider.dart';

/// Centralized route definitions and route mapping for ProFinder.
class AppRoutes {
  AppRoutes._();

  // ── Route Name Constants ──────────────────────────────────
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String search = '/search';
  static const String bookings = '/bookings';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String magazine = '/magazine';

  // Admin Routes
  static const String admin = '/admin';

  // Professional Routes
  static const String pro = '/pro';
  static const String proBookings = '/pro/bookings';
  static const String proProfile = '/pro/profile';
  static const String proPortfolio = '/pro/portfolio';

  /// Standard route map passed directly to MaterialApp.
  static Map<String, WidgetBuilder> get routes => {
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    forgotPassword: (_) => ForgotPasswordScreen(),
    home: (_) => const HomeGate(),
    search: (_) => const SearchScreen(),
    bookings: (_) => const MyBookingsScreen(),
    profile: (_) => const CustomerProfileScreen(),
    notifications: (_) => const NotificationScreen(),
    magazine: (_) => const MagazineScreen(),

    // Admin
    admin: (_) => const AdminMainScreen(),

    // Professional
    pro: (_) => ProfessionalMainScreen(),
    proBookings: (_) => ProfessionalMainScreen(),
    proProfile: (_) => ProfessionalMainScreen(),
    proPortfolio: (_) => ProfessionalPortfolioScreen(),
  };
}

/// `/home` is shared by both guest & logged-in customers (see login/splash
/// flow). This gate reads AuthProvider once and shows the right screen —
/// no route-map changes needed anywhere else.
class HomeGate extends StatelessWidget {
  const HomeGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return auth.isGuest ? const GuestMainScreen() : const CustomerHomeScreen();
  }
}
