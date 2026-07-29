// lib/features/auth/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../services/auth_provider.dart';
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
  late Animation<double>   _fadeAnimation;
  late Animation<double>   _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _checkAuthAndNavigate();
  }

  void _setupAnimation() {
    _animController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve:  Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve:  Curves.easeOutBack,
      ),
    );

    _animController.forward();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final auth = context.read<AuthProvider>();

    // ✅ FIX: checkLoginStatus ke andar isLoading set karo taake
    // role aur token dono ek saath load hon — race condition khatam
    await auth.checkLoginStatus();

    if (!mounted) return;

    // ✅ FIX: bool getters (isCustomer/isAdmin) pe rely karne ki
    // jagah directly role string check karo. Agar role null aa jaye
    // (token hai lekin role prefs se delete ho gaya) to logout kar do.
    final String? role = auth.role;

    if (auth.isLoggedIn && role != null) {
      switch (role) {
        case 'customer':
          // ✅ FIX: pushNamedAndRemoveUntil — see login_screen.dart for
          // full explanation of why plain pushReplacementNamed was
          // leaving stale routes in the stack.
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          break;
        case 'professional':
          Navigator.pushNamedAndRemoveUntil(context, '/pro', (route) => false);
          break;
        case 'admin':
          Navigator.pushNamedAndRemoveUntil(context, '/admin', (route) => false);
          break;
        default:
          // Unknown role — corrupt state, logout karke clean slate
          await auth.logout();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
      }
    } else {
      // ✅ FIX: isLoggedIn true ho lekin role null ho (corrupted prefs)
      // — yeh bhi logout karwa do
      if (auth.isLoggedIn && role == null) {
        await auth.logout();
        if (!mounted) return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
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
                  size:        130,
                  showName:    true,
                  showTagline: true,
                  inverted:    true,
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