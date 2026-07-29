// lib/features/profile/screens/security_screen.dart
//
// SECURITY — the backend only exposes an email-based forgot/reset-password
// flow (no authenticated "change password while logged in" endpoint yet).
// So "Reset Password" here honestly triggers that same flow using the
// user's own account email, rather than faking an in-app password form.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_provider.dart';
import '../../../core/theme/theme_context_ext.dart';

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
      AppHelpers.showSuccess(context, 'Password reset link sent to $_email');
    } catch (_) {
      if (!mounted) return;
      AppHelpers.showError(context, 'Could not send reset link. Try again later.');
    }
    if (!mounted) return;
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Security', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF374151)), onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: context.colors.primaryLight, borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.lock_reset_rounded, color: context.colors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(child: Text('Reset Password', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700))),
                      ]),
                      const SizedBox(height: 10),
                      Text("We'll email a secure reset link to ${_email ?? 'your account email'}.",
                          style: TextStyle(fontSize: 12.5, color: context.colors.textSecondary, height: 1.4)),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _sending ? null : _sendResetLink,
                          child: _sending
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Send Reset Link'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
                    child: ListTile(
                      leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                      title: const Text('Logout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.error)),
                      subtitle: Text('Sign out of this device', style: TextStyle(fontSize: 11.5, color: context.colors.textSecondary)),
                      onTap: () async {
                        await auth.logout();
                        if (!mounted) return;
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}