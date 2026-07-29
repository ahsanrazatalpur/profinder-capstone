// lib/features/profile/screens/wallet_screen.dart
//
// WALLET — real spend total (sum of completed payments) + current plan.
// There's no stored-balance/top-up concept in the backend yet, so this is
// an honest "spend & plan" summary, not a fake wallet balance.

import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/api_service.dart';
import '../../subscription/screens/subscription_screen.dart';
import 'payments_screen.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../shared/widgets/cta_banner.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ApiService _api = ApiService();

  bool   _loading    = true;
  double _totalSpent = 0;
  int    _txCount    = 0;
  bool   _isPremium  = false;
  String _planName   = 'Free';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.get('/payments/'),
        _api.get('${AppConstants.subscriptions}my-plan/'),
      ]);
      final payments = results[0].data is List ? List<dynamic>.from(results[0].data) : [];
      final completed = payments.where((p) => p['status'] == 'completed').toList();
      _totalSpent = completed.fold(0.0, (sum, p) => sum + (double.tryParse('${p['amount']}') ?? 0));
      _txCount    = payments.length;
      final plan  = results[1].data as Map<String, dynamic>;
      _isPremium  = plan['is_premium'] == true;
      _planName   = plan['plan_name']?.toString() ?? 'Free';
    } catch (_) {
      // keep zeros — screen still renders usefully
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Wallet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF374151)), onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: context.colors.primary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF059669), Color(0xFF10B981)]),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          const Text('Total Spent', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                        ]),
                        const SizedBox(height: 14),
                        Text('\$${_totalSpent.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Across $_txCount transaction${_txCount == 1 ? '' : 's'}',
                            style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  CtaBanner(
                    isDark: false,
                    title: 'Current plan: $_planName',
                    subtitle: _isPremium ? 'You have premium benefits active' : 'Upgrade for premium perks',
                    ctaLabel: _isPremium ? 'Manage' : 'Upgrade',
                    icon: Icons.workspace_premium_rounded,
                    accentStart: const Color(0xFFA78BFA),
                    accentEnd: const Color(0xFF8B5CF6),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen(userRole: 'customer'))),
                  ),
                  const SizedBox(height: 14),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
                      child: ListTile(
                        leading: Icon(Icons.receipt_long_rounded, color: context.colors.primary),
                        title: const Text('Payment History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text('View all your transactions', style: TextStyle(fontSize: 11.5, color: context.colors.textSecondary)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentsScreen())),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}