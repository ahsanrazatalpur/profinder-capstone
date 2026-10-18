// lib/features/auth/screens/otp_verification_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../services/auth_provider.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import 'create_new_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String purpose; // 'signup' or 'forgot_password'
  final String? userName;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.purpose = 'signup',
    this.userName,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const int _codeLength = 6;
  static const int _initialExpirySeconds = 300; // 5 minutes
  static const int _initialCooldownSeconds = 60; // 60s cooldown

  final List<TextEditingController> _controllers = List.generate(
    _codeLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _codeLength,
    (_) => FocusNode(),
  );

  int _expirySeconds = _initialExpirySeconds;
  int _cooldownSeconds = _initialCooldownSeconds;
  Timer? _expiryTimer;
  Timer? _cooldownTimer;

  bool _isSubmitting = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startExpiryTimer();
    _startCooldownTimer();

    // Auto-focus first box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _cooldownTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startExpiryTimer() {
    _expiryTimer?.cancel();
    _expirySeconds = _initialExpirySeconds;
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_expirySeconds > 0) {
        setState(() => _expirySeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _startCooldownTimer([int seconds = _initialCooldownSeconds]) {
    _cooldownTimer?.cancel();
    _cooldownSeconds = seconds;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds > 0) {
        setState(() => _cooldownSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _currentOtp => _controllers.map((c) => c.text).join();

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _onDigitChanged(int index, String value) {
    setState(() => _errorMessage = null);

    // Handle full 6-digit paste
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= _codeLength) {
        for (int i = 0; i < _codeLength; i++) {
          _controllers[i].text = digits[i];
        }
        _focusNodes[_codeLength - 1].requestFocus();
        _verifyOtp();
        return;
      } else {
        _controllers[index].text = digits.isNotEmpty ? digits[0] : '';
      }
    }

    if (value.isNotEmpty) {
      if (index < _codeLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_currentOtp.length == _codeLength) {
          _verifyOtp();
        }
      }
    }
  }

  Future<void> _resendCode() async {
    if (_cooldownSeconds > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final result = await auth.sendOtp(
      email: widget.email,
      purpose: widget.purpose,
    );

    if (!mounted) return;
    setState(() => _isResending = false);

    if (result['success'] == true) {
      final retryAfter =
          result['data']?['cooldown'] as int? ?? _initialCooldownSeconds;
      _startCooldownTimer(retryAfter);
      _startExpiryTimer();
      // Clear inputs
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();

      AppHelpers.showSuccess(
        context,
        'A fresh 6-digit verification code has been sent to your email.',
      );
    } else {
      final msg =
          result['message'] as String? ??
          'Failed to resend code. Please try again.';
      setState(() => _errorMessage = msg);
      AppHelpers.showError(context, msg);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _currentOtp;
    if (otp.length != _codeLength) {
      setState(() => _errorMessage = 'Please enter all 6 digits of the code.');
      return;
    }

    if (_expirySeconds <= 0) {
      setState(
        () =>
            _errorMessage = 'This code has expired. Please request a new one.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final result = await auth.verifyOtp(
      email: widget.email,
      otp: otp,
      purpose: widget.purpose,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      if (widget.purpose == 'signup') {
        _onSignupSuccess(auth);
      } else if (widget.purpose == 'forgot_password') {
        final resetToken = result['data']?['reset_token'] as String?;
        if (resetToken != null && resetToken.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CreateNewPasswordScreen(
                email: widget.email,
                resetToken: resetToken,
              ),
            ),
          );
        } else {
          AppHelpers.showError(
            context,
            'Verification confirmed, but unable to proceed. Please request a new code.',
          );
        }
      }
    } else {
      final msg = result['message'] as String? ?? 'Invalid verification code.';
      setState(() => _errorMessage = msg);
      AppHelpers.showError(context, msg);
    }
  }

  void _onSignupSuccess(AuthProvider auth) {
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
                  color: AppColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  size: 42,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                'Email Verified!',
                style: context.textStyles.h2.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                'Your ProFinder account is now active and ready to use.',
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
                    final role = auth.role;
                    if (role == 'professional') {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.pro,
                        (r) => false,
                      );
                    } else {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.home,
                        (r) => false,
                      );
                    }
                  },
                  child: const Text('Get Started'),
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
    final width = MediaQuery.sizeOf(context).width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentMaxWidth = width > 520 ? 460.0 : width;

    final isSignup = widget.purpose == 'signup';
    final title = isSignup ? 'Verify Your Email' : 'Enter Verification Code';
    final subtitle = isSignup
        ? 'We sent a 6-digit verification code to'
        : 'Enter the 6-digit password reset code sent to';

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: UniversalAppBar(
        title: title,
        icon: Icons.mark_email_read_outlined,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSizes.md),

                  // Hero Icon Badge
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: context.colors.primaryLight,
                      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 42,
                      color: context.colors.primary,
                    ),
                  ),

                  const SizedBox(height: AppSizes.xl),

                  Text(
                    title,
                    style: context.textStyles.h2.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.colors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSizes.xs),

                  Text(
                    subtitle,
                    style: context.textStyles.bodyMedium.copyWith(
                      color: context.colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 4),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          widget.email,
                          style: context.textStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.colors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: AppSizes.fontSm,
                            fontWeight: FontWeight.w700,
                            color: context.colors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.xxl),

                  // 6 Digit PIN Input Boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_codeLength, (index) {
                      return Container(
                        width: 44,
                        height: 56,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Focus(
                          onKeyEvent: (node, event) {
                            if (event is KeyDownEvent &&
                                event.logicalKey ==
                                    LogicalKeyboardKey.backspace) {
                              if (_controllers[index].text.isEmpty &&
                                  index > 0) {
                                _focusNodes[index - 1].requestFocus();
                                _controllers[index - 1].clear();
                                return KeyEventResult.handled;
                              }
                            }
                            return KeyEventResult.ignored;
                          },
                          child: TextFormField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: isDark
                                  ? context.colors.surface
                                  : AppColors.background,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMd,
                                ),
                                borderSide: BorderSide(
                                  color: context.colors.divider,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMd,
                                ),
                                borderSide: BorderSide(
                                  color: context.colors.primary,
                                  width: 2.0,
                                ),
                              ),
                            ),
                            onChanged: (val) => _onDigitChanged(index, val),
                          ),
                        ),
                      );
                    }),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppSizes.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: AppSizes.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 18,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: context.textStyles.bodySmall.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSizes.xl),

                  // Expiry Countdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 18,
                        color: _expirySeconds > 0
                            ? context.colors.textSecondary
                            : AppColors.error,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _expirySeconds > 0
                            ? 'Code expires in ${_formatTime(_expirySeconds)}'
                            : 'Code has expired',
                        style: context.textStyles.bodySmall.copyWith(
                          color: _expirySeconds > 0
                              ? context.colors.textSecondary
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.xl),

                  // Verify CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (_isSubmitting || _currentOtp.length != _codeLength)
                          ? null
                          : _verifyOtp,
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
                          : const Text(
                              'Verify & Continue',
                              style: TextStyle(
                                fontSize: AppSizes.fontLg,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: AppSizes.lg),

                  // Resend Cooldown
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "Didn't receive the code? ",
                        style: context.textStyles.bodySmall.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                      if (_cooldownSeconds > 0)
                        Text(
                          'Resend in ${_cooldownSeconds}s',
                          style: context.textStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.colors.textSecondary.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        )
                      else
                        TextButton(
                          onPressed: _isResending ? null : _resendCode,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: _isResending
                              ? const SizedBox(
                                  height: 14,
                                  width: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Resend Code',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: AppSizes.fontSm,
                                    color: context.colors.primary,
                                  ),
                                ),
                        ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.xxl),

                  // Security notice box
                  Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? context.colors.surface
                          : context.colors.background,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(color: context.colors.divider),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lock_clock_outlined,
                          size: 18,
                          color: context.colors.primary,
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: Text(
                            'Never share your verification code with anyone. ProFinder staff will never ask for your code.',
                            style: context.textStyles.bodySmall.copyWith(
                              color: context.colors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
