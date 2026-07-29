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
        auth.errorMessage ?? AppStrings.serverError,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final contentMaxWidth = width > 520 ? 480.0 : width;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title:   Text(AppStrings.resetPass),
        leading: IconButton(
          icon:      const Icon(Icons.arrow_back_ios),
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
              child: _emailSent ? _buildSuccessView() : _buildFormView(auth),
            ),
          ),
        ),
      ),
    );
  }

  // Form view — shown before sending email
  Widget _buildFormView(AuthProvider auth) {
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
                color:        context.colors.primaryLight,
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              ),
              child: Icon(
                Icons.lock_reset_outlined,
                size:  40,
                color: context.colors.primary,
              ),
            ),
          ),

          const SizedBox(height: AppSizes.lg),

          Text(AppStrings.resetPass, style: context.textStyles.h2),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Enter your registered email. We will send a password reset link.',
            style: context.textStyles.bodyMedium,
          ),

          const SizedBox(height: AppSizes.xl),

          TextFormField(
            controller:   _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect:  false,
            style:        context.textStyles.inputText,
            decoration: InputDecoration(
              labelText:  AppStrings.email,
              hintText:   'example@email.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: AppValidators.email,
          ),

          const SizedBox(height: AppSizes.xl),

          ElevatedButton(
            onPressed: auth.isLoading ? null : _onSendPressed,
            child: auth.isLoading
                ? const SizedBox(
                    height: 22,
                    width:  22,
                    child:  CircularProgressIndicator(
                      color:       AppColors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(AppStrings.sendResetLink),
          ),
        ],
      ),
    );
  }

  // Success view — shown after email is sent
  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: AppSizes.xxl),

        Container(
          width:  100,
          height: 100,
          decoration: BoxDecoration(
            color:        context.colors.accentLight,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            size:  50,
            color: context.colors.accent,
          ),
        ),

        const SizedBox(height: AppSizes.lg),

        Text('Check Your Email', style: context.textStyles.h2),
        const SizedBox(height: AppSizes.sm),

        Text(
          AppStrings.forgotPasswordGenericMessage,
          style:     context.textStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSizes.xs),

        Text(
          'If it doesn\'t arrive in a few minutes, check your spam folder or try again.',
          style:     AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSizes.xxl),

        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child:     Text(AppStrings.backToLogin),
        ),

        const SizedBox(height: AppSizes.md),

        TextButton(
          onPressed: () => setState(() => _emailSent = false),
          child:     Text(AppStrings.resendEmail),
        ),
      ],
    );
  }
}