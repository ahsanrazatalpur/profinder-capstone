// lib/features/professional/screens/professional_wallet_screen.dart

import '../../../core/constants/app_sizes.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../../subscription/screens/subscription_screen.dart';

class ProfessionalWalletScreen extends StatefulWidget {
  const ProfessionalWalletScreen({super.key});

  @override
  State<ProfessionalWalletScreen> createState() =>
      _ProfessionalWalletScreenState();
}

class _ProfessionalWalletScreenState extends State<ProfessionalWalletScreen> {
  final _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _invoices = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/payments/invoices/');
      if (mounted) {
        setState(() {
          _invoices = res.data is List ? res.data : [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: const UniversalAppBar(
        title: 'Payments & Settlement',
        icon: Icons.payments_rounded,
      ),
      body: _isLoading
          ? const Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  color: AppColors.professionalColor,
                  strokeWidth: 3,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.professionalColor,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Hero Settlement Card ──────────────────────────
                  _buildHeroSettlementCard(),
                  const SizedBox(height: 16),

                  // ── How Direct Payments Work ──────────────────────
                  _buildSectionTitle('Accepted Direct Payment Methods'),
                  const SizedBox(height: 10),
                  _buildPaymentMethodTile(
                    icon: Icons.money_rounded,
                    color: Colors.green,
                    title: 'Cash on Visit / Completion',
                    subtitle: 'Collect payment in cash directly from the client at their premises.',
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentMethodTile(
                    icon: Icons.flash_on_rounded,
                    color: Colors.teal,
                    title: 'Raast P2P (Instant 0% Fee)',
                    subtitle: 'Share your registered mobile number for instant bank-to-bank settlement via State Bank Raast.',
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentMethodTile(
                    icon: Icons.account_balance_rounded,
                    color: Colors.blue,
                    title: 'Direct Bank Transfer / IBAN',
                    subtitle: 'Provide your account number or IBAN in chat for direct bank transfer by the client.',
                  ),
                  const SizedBox(height: 20),

                  // ── 0% Platform Commission Policy Card ────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      border: Border.all(color: AppColors.emerald.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified_rounded, color: AppColors.emerald, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '0% Commission Platform Guarantee',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ProFinder does not take cuts from your hard-earned client fees, does not hold client money in escrow, and requires no payout requests. All client payments are 100% yours immediately upon service delivery.',
                          style: TextStyle(fontSize: 12, color: context.colors.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Subscription & Promotion Invoices ─────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Platform Invoices & Plan'),
                      TextButton.icon(
                        icon: const Icon(Icons.workspace_premium_rounded, size: 16),
                        label: const Text('Manage Plan'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SubscriptionScreen(userRole: 'professional')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_invoices.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(color: context.colors.divider),
                      ),
                      child: Text(
                        'No platform invoices found. Your current plan is active.',
                        style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                      ),
                    )
                  else
                    ..._invoices.map((inv) => _buildInvoiceTile(inv)),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: context.colors.textPrimary,
      ),
    );
  }

  Widget _buildHeroSettlementCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF047857).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'DIRECT CLIENT SETTLEMENT',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.8),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Keep 100% of Your Earnings',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Clients pay you directly on visit or completion via Cash, Raast, or Bank Transfer. ProFinder charges zero commission on your jobs.',
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: context.colors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11.5, color: context.colors.textSecondary, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceTile(dynamic inv) {
    final amount = inv['amount'] ?? inv['total'] ?? 0;
    final title = inv['description'] ?? inv['plan_name'] ?? 'Platform Service';
    final date = inv['created_at'] ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: context.colors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title.toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              if (date.toString().isNotEmpty)
                Text(date.toString().split('T').first, style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
            ],
          ),
          Text(
            'PKR $amount',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.emerald),
          ),
        ],
      ),
    );
  }
}
