// lib/features/auth/screens/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../services/auth_provider.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../l10n/generated/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent        = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSendPressed() async {
    if (!_formKey.currentState!.validate()) return;

    final auth   = context.read<AuthProvider>();
    final result = await auth.forgotPassword(
      email: _emailController.text.trim(),
    );

    if (!mounted) return;

    if (result) {
      setState(() => _emailSent = true);
    } else {
      // Network/timeout/server errors are real failures worth surfacing —
      // but a successful response always shows the fixed generic message
      // below, regardless of what the backend happened to say, so this
      // endpoint can never be used to confirm whether an email exists.
      AppHelpers.showError(
        context,
        auth.errorMessage ?? AppLocalizations.of(context)!.serverError,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final contentMaxWidth = width > 520 ? 480.0 : width;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.resetPassTitle,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.colors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                child: _emailSent ? _buildSuccessView(isDark) : _buildFormView(auth, isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Form view — shown before sending email
  Widget _buildFormView(AuthProvider auth, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.lg),

          Center(
            child: Container(
              width:  80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.professionalColor.withOpacity(0.15)
                    : context.colors.primaryLight,
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              ),
              child: Icon(
                Icons.lock_reset_outlined,
                size:  40,
                color: AppColors.professionalColor,
              ),
            ),
          ),

          const SizedBox(height: AppSizes.lg),

          Text(
            AppLocalizations.of(context)!.resetPassTitle,
            style: context.textStyles.h2.copyWith(
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            AppLocalizations.of(context)!.resetPassSubtitle,
            style: context.textStyles.bodyMedium.copyWith(
              color: context.colors.textSecondary,
            ),
          ),

          const SizedBox(height: AppSizes.xl),

          TextFormField(
            controller:   _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect:  false,
            style:        context.textStyles.inputText.copyWith(
              color: context.colors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText:  AppStrings.email,
              hintText:   AppLocalizations.of(context)!.emailHint,
              prefixIcon: Icon(
                Icons.email_outlined,
                color: isDark
                    ? context.colors.textSecondary.withOpacity(0.6)
                    : null,
              ),
            ),
            validator: AppValidators.email,
          ),

          const SizedBox(height: AppSizes.xl),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _onSendPressed,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: auth.isLoading
                  ? const SizedBox(
                      height: 22,
                      width:  22,
                      child:  CircularProgressIndicator(
                        color:       AppColors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      AppLocalizations.of(context)!.sendResetLinkCta,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Success view — shown after email is sent
  Widget _buildSuccessView(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: AppSizes.xxl),

        Container(
          width:  100,
          height: 100,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF10B981).withOpacity(0.15)
                : context.colors.accentLight,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            size:  50,
            color: context.colors.accent,
          ),
        ),

        const SizedBox(height: AppSizes.lg),

        Text(
          AppLocalizations.of(context)!.checkEmailTitle,
          style: context.textStyles.h2.copyWith(
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.sm),

        Text(
          AppLocalizations.of(context)!.checkEmailMessage,
          style: context.textStyles.bodyMedium.copyWith(
            color: context.colors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSizes.xs),

        Text(
          AppLocalizations.of(context)!.checkEmailHint,
          style: AppTextStyles.bodySmall.copyWith(
            color: context.colors.textSecondary.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSizes.xxl),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.backToLoginCta,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSizes.md),

        TextButton(
          onPressed: () => setState(() => _emailSent = false),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(
            AppLocalizations.of(context)!.resendEmailCta,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.professionalColor,
            ),
          ),
        ),
      ],
    );
  }
}