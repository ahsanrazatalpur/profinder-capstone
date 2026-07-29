// lib/features/professional/screens/professional_wallet_screen.dart

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../shared/widgets/cta_banner.dart';

class ProfessionalWalletScreen extends StatefulWidget {
  const ProfessionalWalletScreen({super.key});

  @override
  State<ProfessionalWalletScreen> createState() => _ProfessionalWalletScreenState();
}

class _ProfessionalWalletScreenState extends State<ProfessionalWalletScreen> {
  final _api = ApiService();

  Map<String, dynamic>? _wallet;
  bool _isLoading = true;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get(AppConstants.walletSummary);
      if (!mounted) return;
      setState(() {
        _wallet = res.data as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppHelpers.showError(context, 'Could not load wallet');
    }
  }

  // ── Withdrawal request — bank details missing hone par pehle wahi maangte hain ──
  void _showWithdrawSheet() {
    final bankOnFile = _wallet?['bank_on_file'] ?? false;
    if (bankOnFile != true) {
      _showAddBankNote();
      return;
    }

    final available = (_wallet?['available_balance'] ?? 0).toDouble();
    final minAmount = (_wallet?['min_withdrawal'] ?? 20).toDouble();
    final amountController = TextEditingController();
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Withdraw Earnings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
              const SizedBox(height: 6),
              Text('Available: \$${available.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  hintText:   'Enter amount',
                  errorText:  errorText,
                  filled:     true,
                  fillColor:  context.colors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:   BorderSide(color: context.colors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:   BorderSide(color: context.colors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:   BorderSide(color: AppColors.professionalColor, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text('Minimum withdrawal: \$${minAmount.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRequesting ? null : () async {
                    final amount = double.tryParse(amountController.text.trim());
                    if (amount == null || amount <= 0) {
                      setSheetState(() => errorText = 'Enter a valid amount');
                      return;
                    }
                    if (amount < minAmount) {
                      setSheetState(() => errorText = 'Minimum is \$${minAmount.toStringAsFixed(0)}');
                      return;
                    }
                    if (amount > available) {
                      setSheetState(() => errorText = 'Exceeds available balance');
                      return;
                    }
                    setSheetState(() { errorText = null; });
                    setState(() => _isRequesting = true);
                    try {
                      await _api.post(AppConstants.withdrawals, {'amount': amount});
                      if (!mounted) return;
                      Navigator.pop(sheetContext);
                      AppHelpers.showSuccess(context, 'Withdrawal request submitted');
                      _loadWallet();
                    } catch (e) {
                      String msg = 'Could not submit request';
                      if (e is DioException) {
                        final data = e.response?.data;
                        if (data is Map && data['error'] != null) msg = data['error'].toString();
                      }
                      setSheetState(() => errorText = msg);
                    } finally {
                      if (mounted) setState(() => _isRequesting = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isRequesting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Request Withdrawal', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddBankNote() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Bank Details Required', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'Please add your bank account details in Profile before requesting a withdrawal.',
          style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bankOnFile = _wallet?['bank_on_file'] ?? false;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        title: Text('Wallet & Earnings',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWallet,
              color: AppColors.professionalColor,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildBalanceCard(),
                  if (bankOnFile != true) ...[
                    const SizedBox(height: 12),
                    _buildAddBankBanner(isDark),
                  ],
                  const SizedBox(height: 12),
                  _buildStatsRow(),
                  const SizedBox(height: 20),
                  _buildSectionHeader('Transaction History'),
                  const SizedBox(height: 10),
                  _buildTransactionList(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ── Add Bank Details Banner ──────────────────────────
  // Global CtaBanner widget — yahan wallet ke apne emoji, color aur
  // content ke sath, taaki bina bank details ke withdrawal na attempt
  // ho (upar wale _showWithdrawSheet mein bhi yehi check hai).
  Widget _buildAddBankBanner(bool isDark) {
    return CtaBanner(
      isDark: isDark,
      title: 'Add your bank details',
      subtitle: 'So we can send your withdrawals instantly',
      ctaLabel: 'Add Bank',
      emoji: '🏦',
      accentStart: const Color(0xFF2DD4BF),
      accentEnd: const Color(0xFF14B8A6),
      onTap: _showAddBankNote,
    );
  }

  Widget _buildSectionHeader(String title) => Text(
        title,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
      );

  // ── Available Balance — hero card, Withdraw CTA seedha yahin ──────
  Widget _buildBalanceCard() {
    final available = (_wallet?['available_balance'] ?? 0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Available Balance', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('\$${available.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showWithdrawSheet,
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
              label: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF059669),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final totalEarned = (_wallet?['total_earned'] ?? 0).toDouble();
    final totalWithdrawn = (_wallet?['total_withdrawn'] ?? 0).toDouble();
    final pending = (_wallet?['pending_withdrawal'] ?? 0).toDouble();

    return Row(
      children: [
        Expanded(child: _miniStat('Total Earned', totalEarned, Icons.savings_outlined, context.colors.primary)),
        const SizedBox(width: 10),
        Expanded(child: _miniStat('Withdrawn', totalWithdrawn, Icons.check_circle_outline_rounded, context.colors.accent)),
        const SizedBox(width: 10),
        Expanded(child: _miniStat('Pending', pending, Icons.access_time_rounded, AppColors.warning)),
      ],
    );
  }

  Widget _miniStat(String label, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: context.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 6),
          Text('\$${amount.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
              overflow: TextOverflow.ellipsis),
          Text(label, style: TextStyle(fontSize: 10, color: context.colors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    final transactions = (_wallet?['transactions'] as List?) ?? [];

    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:        context.colors.surface,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: context.colors.divider),
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, color: context.colors.textDisabled, size: 32),
            SizedBox(height: 8),
            Text('No transactions yet', style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
          ],
        ),
      );
    }

    return Column(
      children: transactions.map((t) => _buildTransactionTile(t)).toList(),
    );
  }

  Widget _buildTransactionTile(dynamic t) {
    final isCredit = t['type'] == 'credit';
    final amount   = (t['amount'] ?? 0).toDouble();
    final label    = t['label']?.toString() ?? '';
    final status   = t['status']?.toString() ?? '';
    final date     = t['date']?.toString() ?? '';

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
      case 'approved': statusColor = context.colors.accent;  break;
      case 'rejected': statusColor = AppColors.error;   break;
      default:         statusColor = AppColors.warning; // pending
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: context.colors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:        (isCredit ? context.colors.accent : AppColors.error).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isCredit ? context.colors.accent : AppColors.error,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (date.isNotEmpty)
                  Text(date, style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}\$${amount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: isCredit ? context.colors.accent : context.colors.textPrimary),
              ),
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                child: Text(AppHelpers.capitalize(status),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: statusColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}