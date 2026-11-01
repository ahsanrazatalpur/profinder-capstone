// lib/features/auth/screens/create_new_password_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/auth_provider.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../widgets/password_strength_meter.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  final String email;
  final String resetToken;

  const CreateNewPasswordScreen({
    super.key,
    required this.email,
    required this.resetToken,
  });

  @override
  State<CreateNewPasswordScreen> createState() =>
      _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_refresh);
    _confirmController.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _passwordController.removeListener(_refresh);
    _confirmController.removeListener(_refresh);
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _onResetPressed() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmController.text) {
      AppHelpers.showError(
        context,
        AppLocalizations.of(context).valPasswordsMismatch,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final auth = context.read<AuthProvider>();
    final result = await auth.resetPasswordWithOtp(
      email: widget.email,
      resetToken: widget.resetToken,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      _showSuccessDialog();
    } else {
      final msg =
          result['message'] as String? ??
          'Failed to reset password. Please try again.';
      AppHelpers.showError(context, msg);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 44,
                  color: AppColors.emerald,
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                'Password Reset!',
                style: context.textStyles.h2.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                'Your password has been successfully updated. You can now log in with your new password.',
                style: context.textStyles.bodyMedium.copyWith(
                  color: context.colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (route) => false,
                    );
                  },
                  child: const Text('Back to Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final contentMaxWidth = width > 520 ? 460.0 : width;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: UniversalAppBar(
        title: t.resetPassTitle,
        icon: Icons.lock_outline_rounded,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.screenPadding(width),
                vertical: AppSizes.xl,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSizes.md),

                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: context.colors.primaryLight,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusXl,
                          ),
                        ),
                        child: Icon(
                          Icons.lock_reset_rounded,
                          size: 40,
                          color: context.colors.primary,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSizes.xl),

                    Text(
                      'Set a New Password',
                      style: context.textStyles.h2.copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      'Your new password must be at least 8 characters long with uppercase, lowercase, numbers, and symbols.',
                      style: context.textStyles.bodyMedium.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: AppSizes.xl),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: context.textStyles.inputText.copyWith(
                        color: context.colors.textPrimary,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: t.newPasswordLabel,
                        hintText: t.passwordHint,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (v) => AppValidators.password(v, t),
                    ),

                    const SizedBox(height: AppSizes.xs),
                    PasswordStrengthMeter(password: _passwordController.text),

                    const SizedBox(height: AppSizes.lg),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      style: context.textStyles.inputText.copyWith(
                        color: context.colors.textPrimary,
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _onResetPressed(),
                      decoration: InputDecoration(
                        labelText: t.confirmPasswordLabel,
                        hintText: t.confirmPasswordHint,
                        prefixIcon: const Icon(Icons.lock_clock_outlined),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_confirmController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  _confirmController.text ==
                                          _passwordController.text
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  color: _confirmController.text ==
                                          _passwordController.text
                                      ? AppColors.success
                                      : AppColors.error,
                                  size: 20,
                                ),
                              ),
                            IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                            ),
                          ],
                        ),
                      ),
                      validator: (v) => AppValidators.confirmPassword(
                        v,
                        _passwordController.text,
                        t,
                      ),
                    ),

                    const SizedBox(height: AppSizes.xxl),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _onResetPressed,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMd,
                            ),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                t.resetPassTitle,
                                style: const TextStyle(
                                  fontSize: AppSizes.fontLg,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
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
