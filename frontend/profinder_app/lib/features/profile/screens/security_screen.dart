// lib/features/profile/screens/security_screen.dart
//
// SECURITY — the backend only exposes an email-based forgot/reset-password
// flow (no authenticated "change password while logged in" endpoint yet).
// So "Reset Password" here honestly triggers that same flow using the
// user's own account email, rather than faking an in-app password form.

import 'package:flutter/material.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_provider.dart';
import '../../../l10n/generated/app_localizations.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final ApiService _api = ApiService();
  String? _email;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    try {
      final res = await _api.get(AppConstants.me);
      _email = (res.data as Map<String, dynamic>)['email']?.toString();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _sendResetLink() async {
    if (_email == null) return;
    setState(() => _sending = true);
    try {
      await _api.post(AppConstants.forgotPassword, {'email': _email});
      if (!mounted) return;
      AppHelpers.showSuccess(context, AppLocalizations.of(context)!.resetLinkSent(_email!));
    } catch (_) {
      if (!mounted) return;
      AppHelpers.showError(context, AppLocalizations.of(context)!.resetLinkError);
    }
    if (!mounted) return;
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width > 600;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: UniversalAppBar(
        title: AppLocalizations.of(context)!.securityTitle,
        icon: Icons.shield_rounded,
      ),
      body: _loading
          ? Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: AppColors.customerColor,
                  strokeWidth: 3,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // ── Reset Password Card ──────────────────
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : const Color(0xFFE5E7EB),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.12)
                              : Colors.grey.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.customerColor.withOpacity(0.15)
                                    : context.colors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.lock_reset_rounded,
                                color: AppColors.customerColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.resetPasswordLabel,
                                style: TextStyle(
                                  fontSize: isTablet ? 15.5 : 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.textPrimary,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          AppLocalizations.of(context)!.resetPasswordDescription(_email ?? AppLocalizations.of(context)!.yourAccountEmailPlaceholder),
                          style: TextStyle(
                            fontSize: isTablet ? 13.0 : 12.5,
                            color: context.colors.textSecondary,
                            height: 1.4,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _sending ? null : _sendResetLink,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.customerColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _sending
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    AppLocalizations.of(context)!.sendResetLinkCta,
                                    style: TextStyle(
                                      fontSize: isTablet ? 15.0 : 14.0,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Logout Card ─────────────────────────
                  Material(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : const Color(0xFFE5E7EB),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.12)
                                : Colors.grey.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.logout_rounded,
                            color: AppColors.error,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          AppLocalizations.of(context)!.logoutActionLabel,
                          style: TextStyle(
                            fontSize: isTablet ? 15.0 : 14.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                            letterSpacing: -0.1,
                          ),
                        ),
                        subtitle: Text(
                          AppLocalizations.of(context)!.logoutActionSubtitle,
                          style: TextStyle(
                            fontSize: isTablet ? 12.0 : 11.5,
                            color: context.colors.textSecondary,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: context.colors.textSecondary,
                          size: 20,
                        ),
                        onTap: () async {
                          await auth.logout();
                          if (!mounted) return;
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (_) => false,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}