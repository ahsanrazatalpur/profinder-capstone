// lib/features/auth/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../services/auth_provider.dart';
import '../../../services/push_notification_service.dart';
import 'login_screen.dart';
import '../../../core/theme/theme_context_ext.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _checkAuthAndNavigate();
  }

  void _setupAnimation() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.forward();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final auth = context.read<AuthProvider>();

    // Verify authentication status, loading tokens and role atomically.
    await auth.checkLoginStatus();

    if (!mounted) return;

    // Explicitly check the role string to ensure session consistency.
    final String? role = auth.role;

    if (auth.isLoggedIn && role != null) {
      switch (role) {
        case 'customer':
          // Clear navigation history when entering role dashboard.
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          break;
        case 'professional':
          Navigator.pushNamedAndRemoveUntil(context, '/pro', (route) => false);
          break;
        case 'admin':
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/admin',
            (route) => false,
          );
          break;
        default:
          // Unknown role indicates corrupted session; clear auth state.
          await auth.logout();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
      }
    } else {
      // Handle corrupted session where token exists without a valid role.
      if (auth.isLoggedIn && role == null) {
        await auth.logout();
        if (!mounted) return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }

    // Signal notification service that the app is ready to process cold-start payloads.
    PushNotificationService().onAppReady();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                // Logo — change anytime from app_logo.dart
                AppLogo(
                  size: 130,
                  showName: true,
                  showTagline: true,
                  inverted: true,
                ),

                SizedBox(height: 48),

                // Loader — change anytime from app_loader.dart
                AppSplashLoader(inverted: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
