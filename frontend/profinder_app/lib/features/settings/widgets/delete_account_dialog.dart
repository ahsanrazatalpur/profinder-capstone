// lib/features/settings/widgets/delete_account_dialog.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../services/auth_provider.dart';

/// Modal dialog for permanently deleting a user's account.
/// Implements secure two-factor verification:
/// 1. Primary path: Account Password (for accounts with passwords).
/// 2. Secondary/Fallback path: 6-digit Gmail OTP (for Google sign-in users or forgotten passwords).
class DeleteAccountDialog extends StatefulWidget {
  final bool hasPassword;
  final String userEmail;

  const DeleteAccountDialog({
    super.key,
    required this.hasPassword,
    required this.userEmail,
  });

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  static const int _codeLength = 6;

  late bool _useOtpMode;
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // OTP State
  final List<TextEditingController> _otpControllers = List.generate(
    _codeLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    _codeLength,
    (_) => FocusNode(),
  );

  bool _otpRequested = false;
  bool _isRequestingOtp = false;
  bool _isSubmitting = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _useOtpMode = !widget.hasPassword;
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _passwordController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentOtp => _otpControllers.map((c) => c.text).join();

  void _startCooldown([int seconds = 60]) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds--);
      }
    });
  }

  Future<void> _requestOtp() async {
    if (_isRequestingOtp || _cooldownSeconds > 0) return;
    setState(() {
      _isRequestingOtp = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.requestDeleteAccountOtp();

    if (!mounted) return;
    setState(() => _isRequestingOtp = false);

    if (result['success'] == true) {
      setState(() => _otpRequested = true);
      final cd = result['data']?['cooldown'] as int? ?? 60;
      _startCooldown(cd);
      _otpFocusNodes[0].requestFocus();
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Failed to send verification code.';
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text?.trim() ?? '';
      final digits = text.replaceAll(RegExp(r'\D'), '');

      if (digits.length >= _codeLength) {
        for (int i = 0; i < _codeLength; i++) {
          _otpControllers[i].text = digits[i];
        }
        _otpFocusNodes[_codeLength - 1].requestFocus();
        setState(() => _errorMessage = null);
      } else if (digits.isNotEmpty) {
        for (int i = 0; i < digits.length; i++) {
          _otpControllers[i].text = digits[i];
        }
        _otpFocusNodes[digits.length < _codeLength ? digits.length : _codeLength - 1].requestFocus();
      }
    } catch (_) {}
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= _codeLength) {
        for (int i = 0; i < _codeLength; i++) {
          _otpControllers[i].text = digits[i];
        }
        _otpFocusNodes[_codeLength - 1].requestFocus();
        setState(() {});
        return;
      } else if (digits.isNotEmpty) {
        for (int i = 0; i < digits.length && (index + i) < _codeLength; i++) {
          _otpControllers[index + i].text = digits[i];
        }
        final next = (index + digits.length).clamp(0, _codeLength - 1);
        _otpFocusNodes[next].requestFocus();
        setState(() {});
        return;
      }
    }

    if (value.isNotEmpty) {
      if (index < _codeLength - 1) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        _otpFocusNodes[index].unfocus();
      }
    } else {
      if (index > 0) {
        _otpFocusNodes[index - 1].requestFocus();
      }
    }
    setState(() {});
  }

  Future<void> _submitDelete() async {
    setState(() {
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!_useOtpMode) {
      final pwd = _passwordController.text.trim();
      if (pwd.isEmpty) {
        setState(() => _errorMessage = 'Please enter your password.');
        return;
      }

      setState(() => _isSubmitting = true);
      final res = await authProvider.confirmDeleteAccount(password: pwd);
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (res['success'] == true) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Failed to delete account.';
        });
      }
    } else {
      final otp = _currentOtp;
      if (otp.length != _codeLength) {
        setState(() => _errorMessage = 'Please enter the complete 6-digit code.');
        return;
      }

      setState(() => _isSubmitting = true);
      final res = await authProvider.confirmDeleteAccount(otp: otp);
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (res['success'] == true) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Failed to delete account.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maskedEmail = widget.userEmail.isNotEmpty ? widget.userEmail : 'your email';

    return Dialog(
      backgroundColor: context.colors.surface,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Icon ──
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.delete_forever_rounded,
                      color: AppColors.error,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Title ──
              Text(
                'Delete Account',
                style: context.textStyles.h3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // ── Warning Box ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This action is permanent and cannot be undone. All your bookings, messages, reviews, and profile data will be permanently removed.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Error Message ──
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Mode Switcher & Content ──
              if (!_useOtpMode) ...[
                // ── Password Mode ──
                Text(
                  'Enter your password to authorize account deletion:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.colors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                  onSubmitted: (_) => _submitDelete(),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _useOtpMode = true;
                        _errorMessage = null;
                      });
                      if (!_otpRequested) {
                        _requestOtp();
                      }
                    },
                    icon: const Icon(Icons.mail_outline_rounded, size: 16),
                    label: const Text('Verify with Gmail OTP instead'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.primary,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ] else ...[
                // ── OTP Mode ──
                Text(
                  'Enter the 6-digit confirmation code sent to:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  maskedEmail,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Digit Boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_codeLength, (index) {
                    return Container(
                      width: 44,
                      height: 52,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      child: KeyboardListener(
                        focusNode: FocusNode(),
                        onKeyEvent: (event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey == LogicalKeyboardKey.backspace &&
                              _otpControllers[index].text.isEmpty &&
                              index > 0) {
                            _otpFocusNodes[index - 1].requestFocus();
                            _otpControllers[index - 1].clear();
                          }
                        },
                        child: TextField(
                          controller: _otpControllers[index],
                          focusNode: _otpFocusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(1),
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                              borderSide: BorderSide(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                              borderSide: BorderSide(
                                color: context.colors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (val) => _onDigitChanged(index, val),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),

                // Paste from clipboard button
                Center(
                  child: OutlinedButton.icon(
                    onPressed: _pasteFromClipboard,
                    icon: const Icon(Icons.content_paste_rounded, size: 15),
                    label: const Text('Paste Code from Clipboard'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.primary,
                      side: BorderSide(
                        color: context.colors.primary.withValues(alpha: 0.35),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Resend OTP
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code? ",
                      style: TextStyle(fontSize: 12.5, color: context.colors.textSecondary),
                    ),
                    if (_cooldownSeconds > 0)
                      Text(
                        'Resend in ${_cooldownSeconds}s',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: context.colors.textSecondary.withValues(alpha: 0.7),
                        ),
                      )
                    else
                      TextButton(
                        onPressed: _isRequestingOtp ? null : _requestOtp,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: _isRequestingOtp
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                'Resend Code',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: context.colors.primary,
                                ),
                              ),
                      ),
                  ],
                ),

                if (widget.hasPassword) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _useOtpMode = false;
                          _errorMessage = null;
                        });
                      },
                      icon: const Icon(Icons.password_rounded, size: 15),
                      label: const Text('Use Account Password instead'),
                      style: TextButton.styleFrom(
                        foregroundColor: context.colors.primary,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 24),

              // ── Action Buttons ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitDelete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Delete Account',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
