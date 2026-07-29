// lib/features/auth/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../services/auth_provider.dart';
import '../../../core/localization/locale_provider.dart'; // ✅ i18n
import '../../../core/localization/language_sync_service.dart'; // ✅ i18n
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  // Optional — lets callers (e.g. Register's "Sign In Instead" action when
  // an email is already registered) land the user here with the email
  // already filled in.
  final String? initialEmail;

  const LoginScreen({super.key, this.initialEmail});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey            = GlobalKey<FormState>();
  late final _emailController    = TextEditingController(text: widget.initialEmail ?? '');
  final _passwordController = TextEditingController();
  bool _obscurePassword     = true;

  // Login button is disabled only while a required field is empty — no
  // strength/format gating here, that's the job of the validators run on
  // submit (email format) and the backend (actual credential check).
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _updateCanSubmit();
    _emailController.addListener(_updateCanSubmit);
    _passwordController.addListener(_updateCanSubmit);
  }

  void _updateCanSubmit() {
    final canSubmit = _emailController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty;
    if (canSubmit != _canSubmit) {
      setState(() => _canSubmit = canSubmit);
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_updateCanSubmit);
    _passwordController.removeListener(_updateCanSubmit);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();

    final success = await auth.login(
      email:    _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // ✅ i18n — reconcile local vs backend language right after login.
      // Backend's preferred_language wins if set; otherwise we upload
      // whatever's currently selected locally. Best-effort — never
      // blocks navigation below.
      await LanguageSyncService().syncAfterLogin(
        backendLanguage: auth.loginPreferredLanguage,
        localeProvider: context.read<LocaleProvider>(),
      );
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('just_logged_in_banner_flag', true);
      final String? role = auth.role;
      switch (role) {
        case 'customer':
          // ✅ FIX: pushNamedAndRemoveUntil — poora stack clear karta hai.
          // pushReplacementNamed sirf top route (LoginScreen) replace karta
          // tha; agar user guest home se yahan Navigator.push() ke zariye
          // aaya tha (e.g. guest_home_screen "Login" button), to purana
          // GuestHomeScreen route stack mein neeche reh jata tha. Back
          // button dabane pe wahi purana route dobara surface hota tha —
          // aur HomeGate role check nahi karta, isliye customer/admin/
          // professional sab ke liye galat interface (ya stuck loading)
          // dikhta tha.
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          break;
        case 'professional':
          Navigator.pushNamedAndRemoveUntil(context, '/pro', (route) => false);
          break;
        case 'admin':
          Navigator.pushNamedAndRemoveUntil(context, '/admin', (route) => false);
          break;
        default:
          AppHelpers.showError(context, 'Unknown role. Please contact support.');
      }
    } else {
      // 401 = bad credentials. Always show the same generic copy here —
      // never surface whether it was the email or the password that was
      // wrong, and never say "no account with that email".
      final message = auth.errorStatusCode == 401
          ? AppStrings.invalidLoginCredentials
          : (auth.errorMessage ?? AppStrings.serverError);
      AppHelpers.showError(context, message);
    }
  }

  // Guest mode — browse only, cannot book or review
  void _onGuestPressed() {
    context.read<AuthProvider>().setGuest();
    // ✅ FIX: same stack-clear treatment as the logged-in cases above.
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final scale = ResponsiveUtils.scaleForWidth(width);
    // Auth forms stay a comfortable reading/tap width even on large
    // tablets — a full-bleed 1200dp-wide text field would look like a
    // stretched desktop form, not a native mobile screen.
    final contentMaxWidth = width > 520 ? 480.0 : width;
    final logoSize = ResponsiveUtils.sp(110, scale, min: 100, max: 140);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.screenPadding(width),
                vertical:   AppSizes.lg,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSizes.xl),

                    // ── Logo — from app_logo.dart ─────────────
                    AppLogo(
                      size:        logoSize,
                      showName:    true,
                      showTagline: true,
                    ),

                    const SizedBox(height: AppSizes.xl),

                    // ── Heading ───────────────────────────────
                    Text(AppStrings.login, style: AppTextStyles.h2.copyWith(fontSize: ResponsiveUtils.sp(24, scale, min: 22, max: 29), color: context.colors.textPrimary)),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      'Welcome back! Please sign in to continue.',
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: ResponsiveUtils.sp(14, scale, min: 13, max: 17), color: context.colors.textSecondary),
                    ),

                const SizedBox(height: AppSizes.lg),

                // ── Email Field ───────────────────────────
                TextFormField(
                  controller:   _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect:  false,
                  style:        AppTextStyles.inputText.copyWith(color: context.colors.textPrimary),
                  decoration: InputDecoration(
                    labelText:  AppStrings.email,
                    hintText:   'example@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: AppValidators.email,
                ),

                const SizedBox(height: AppSizes.md),

                // ── Password Field ────────────────────────
                TextFormField(
                  controller:  _passwordController,
                  obscureText: _obscurePassword,
                  style:       AppTextStyles.inputText.copyWith(color: context.colors.textPrimary),
                  decoration: InputDecoration(
                    labelText:  AppStrings.password,
                    hintText:   'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: AppValidators.loginPassword,
                ),

                const SizedBox(height: AppSizes.xs),

                // ── Forgot Password ───────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ForgotPasswordScreen(),
                      ),
                    ),
                    child: Text(AppStrings.forgotPass),
                  ),
                ),

                const SizedBox(height: AppSizes.md),

                // ── Login Button ──────────────────────────
                ElevatedButton(
                  onPressed: (auth.isLoading || !_canSubmit) ? null : _onLoginPressed,
                  child: auth.isLoading
                      ? const AppButtonLoader()
                      : Text(AppStrings.login),
                ),

                const SizedBox(height: AppSizes.sm),

                // ── Guest Button ──────────────────────────
                OutlinedButton(
                  onPressed: auth.isLoading ? null : _onGuestPressed,
                  child: Text(AppStrings.continueAsGuest),
                ),

                const SizedBox(height: AppSizes.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        AppStrings.noAccount,
                        style: AppTextStyles.bodyMedium.copyWith(color: context.colors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      ),
                      child: Text(AppStrings.register),
                    ),
                  ],
                ),
              ],
            ),
          ),
            ),
          ),
        ),
      ),
    );
  }
}