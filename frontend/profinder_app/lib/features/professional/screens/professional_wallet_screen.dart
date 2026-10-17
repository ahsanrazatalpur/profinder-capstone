// lib/features/professional/screens/professional_wallet_screen.dart

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../../../shared/widgets/cta_banner.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/content_localizer.dart';

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
      AppHelpers.showError(context, AppLocalizations.of(context).loadWalletError);
    }
  }

  // Displays withdrawal bottom sheet with payout method selection (PayPal or Bank Transfer).
  void _showWithdrawSheet() {
    final bankOnFile = _wallet?['bank_on_file'] ?? false;
    final available = (_wallet?['available_balance'] ?? 0).toDouble();
    final minAmount = (_wallet?['min_withdrawal'] ?? 20).toDouble();
    final amountController = TextEditingController();
    final paypalEmailController = TextEditingController();
    String payoutMethod = 'paypal'; // Default to global PayPal
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusSheet))),
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
              Text(
                AppLocalizations.of(context).withdrawTitle,
                style: TextStyle(fontSize: AppFontSizes.title, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context).availableBalanceLabel(available.toStringAsFixed(2)),
                style: TextStyle(fontSize: AppFontSizes.secondary, color: context.colors.textSecondary),
              ),
              const SizedBox(height: 14),

              // ── Payout Method Selector ──────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payment_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('PayPal'),
                        ],
                      ),
                      selected: payoutMethod == 'paypal',
                      onSelected: (val) {
                        if (val) setSheetState(() => payoutMethod = 'paypal');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Bank Transfer'),
                        ],
                      ),
                      selected: payoutMethod == 'bank_transfer',
                      onSelected: (val) {
                        if (val) {
                          if (!bankOnFile) {
                            _showAddBankNote();
                            return;
                          }
                          setSheetState(() => payoutMethod = 'bank_transfer');
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (payoutMethod == 'paypal') ...[
                TextField(
                  controller: paypalEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'PayPal Email',
                    hintText: 'your-email@paypal.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: context.colors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: AppFontSizes.title),
                decoration: InputDecoration(
                  prefixText: 'Rs ',
                  hintText: AppLocalizations.of(context).enterAmountHint,
                  errorText: errorText,
                  filled: true,
                  fillColor: context.colors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide(color: context.colors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide(color: context.colors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide(color: AppColors.professionalColor, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context).minWithdrawalLabel(minAmount.toStringAsFixed(0)),
                style: TextStyle(fontSize: AppFontSizes.caption, color: context.colors.textSecondary),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRequesting ? null : () async {
                    final amount = double.tryParse(amountController.text.trim());
                    if (amount == null || amount <= 0) {
                      setSheetState(() => errorText = AppLocalizations.of(context).validAmountError);
                      return;
                    }
                    if (amount < minAmount) {
                      setSheetState(() => errorText = AppLocalizations.of(context).minAmountError(minAmount.toStringAsFixed(0)));
                      return;
                    }
                    if (amount > available) {
                      setSheetState(() => errorText = AppLocalizations.of(context).exceedsBalanceError);
                      return;
                    }
                    if (payoutMethod == 'paypal' && paypalEmailController.text.trim().isEmpty) {
                      setSheetState(() => errorText = 'Please enter your PayPal email');
                      return;
                    }
                    setSheetState(() { errorText = null; });
                    setState(() => _isRequesting = true);
                    try {
                      await _api.post(AppConstants.withdrawals, {
                        'amount': amount,
                        'payout_method': payoutMethod,
                        'paypal_email': paypalEmailController.text.trim(),
                      });
                      if (!mounted || !sheetContext.mounted) return;
                      Navigator.pop(sheetContext);
                      AppHelpers.showSuccess(context, AppLocalizations.of(context).withdrawSuccess);
                      _loadWallet();
                    } catch (e) {
                      String msg = AppLocalizations.of(context).withdrawErrorDefault;
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                  ),
                  child: _isRequesting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(AppLocalizations.of(context).requestWithdrawCta, style: const TextStyle(fontWeight: FontWeight.w700)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
        title: Text(
          AppLocalizations.of(context).bankDetailsRequiredTitle,
          style: const TextStyle(fontSize: AppFontSizes.title, fontWeight: FontWeight.w700),
        ),
        content: Text(
          AppLocalizations.of(context).bankDetailsRequiredMessage,
          style: TextStyle(fontSize: AppFontSizes.secondary, color: context.colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).okCta),
          ),
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
      appBar: UniversalAppBar(
        title: AppLocalizations.of(context).walletTitle,
        icon: Icons.account_balance_wallet_rounded,
      ),
      body: _isLoading
          ? Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: AppColors.professionalColor,
                  strokeWidth: 3,
                ),
              ),
            )
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
                  _buildSectionHeader(AppLocalizations.of(context).transactionHistoryTitle),
                  const SizedBox(height: 10),
                  _buildTransactionList(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ── Add Bank Details Banner ──────────────────────────
  // Prompts professionals to configure their payout accounts before withdrawing.
  Widget _buildAddBankBanner(bool isDark) {
    return CtaBanner(
      isDark: isDark,
      title: AppLocalizations.of(context).addBankBannerTitle,
      subtitle: AppLocalizations.of(context).addBankBannerSubtitle,
      ctaLabel: AppLocalizations.of(context).addBankCta,
      emoji: '🏦',
      accentStart: AppColors.tealLight,
      accentEnd: AppColors.teal,
      onTap: _showAddBankNote,
    );
  }

  Widget _buildSectionHeader(String title) => Text(
        title,
        style: TextStyle(fontSize: AppFontSizes.body, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
      );

  // ── Available Balance — hero card, Withdraw CTA seedha yahin ──────
  Widget _buildBalanceCard() {
    final available = (_wallet?['available_balance'] ?? 0).toDouble();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
          clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.emerald, AppColors.successDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(children: [
          Positioned(right: -36, top: -52, child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.10)))),
          Positioned(right: 70, bottom: -64, child: Container(width: 110, height: 110, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)))),
          Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).availableBalanceTitle,
            style: TextStyle(fontSize: AppFontSizes.secondary, color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Rs ${available.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: AppFontSizes.h1, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showWithdrawSheet,
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
              label: Text(AppLocalizations.of(context).withdrawCta, style: const TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.successDeep,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
              ),
            ),
          ),
        ],
      ),
        ]),
    );
  }

  Widget _buildStatsRow() {
    final totalEarned = (_wallet?['total_earned'] ?? 0).toDouble();
    final totalWithdrawn = (_wallet?['total_withdrawn'] ?? 0).toDouble();
    final pending = (_wallet?['pending_withdrawal'] ?? 0).toDouble();

    return Row(
      children: [
        Expanded(child: _miniStat(AppLocalizations.of(context).totalEarnedLabel, totalEarned, Icons.savings_outlined, context.colors.primary)),
        const SizedBox(width: 10),
        Expanded(child: _miniStat(AppLocalizations.of(context).withdrawnLabel, totalWithdrawn, Icons.check_circle_outline_rounded, context.colors.accent)),
        const SizedBox(width: 10),
        Expanded(child: _miniStat(AppLocalizations.of(context).pendingLabel, pending, Icons.access_time_rounded, AppColors.warning)),
      ],
    );
  }

  Widget _miniStat(String label, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: context.colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 6),
          Text(
            'Rs ${amount.toStringAsFixed(0)}',
            style: TextStyle(fontSize: AppFontSizes.body, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
          Text(label, style: TextStyle(fontSize: AppFontSizes.caption, color: context.colors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    final transactions = (_wallet?['transactions'] as List?) ?? [];

    if (transactions.isEmpty) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: context.colors.divider),
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, color: context.colors.textDisabled, size: 32),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).noTransactionsLabel,
              style: TextStyle(fontSize: AppFontSizes.secondary, color: context.colors.textSecondary),
            ),
          ],
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: Column(
        children: transactions.map((t) => _buildTransactionTile(t)).toList(),
      ),
    );
  }

  /// The backend sends the history label as a fixed English sentence
  /// ("Job completed — `<customer>`", "Withdrawal request"). Static wording
  /// comes from the .arb files; only the customer name is dynamic content.
  Widget _txnLabel(String label) {
    final t = AppLocalizations.of(context);
    final style = TextStyle(fontSize: AppFontSizes.secondary, fontWeight: FontWeight.w600, color: context.colors.textPrimary);
    const sep = ' — ';
    if (label == 'Withdrawal request') {
      return Text(t.walletWithdrawalRequestLabel, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    if (label == 'Job completed') {
      return Text(t.walletJobCompleted, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    if (label.startsWith('Job completed$sep')) {
      final name = label.substring('Job completed$sep'.length);
      return ListenableBuilder(
        listenable: ContentLocalizer.instance,
        builder: (context, _) => Text(
          t.walletJobCompletedWithName(ContentLocalizer.instance.peek(name, LocKind.name)),
          style: style, maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
      );
    }
    return Text(label, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
  }

  Widget _buildTransactionTile(dynamic t) {
    final isCredit = t['type'] == 'credit';
    final amount = (t['amount'] ?? 0).toDouble();
    final label = t['label']?.toString() ?? '';
    final status = t['status']?.toString() ?? '';
    final date = t['date']?.toString() ?? '';

    Color statusColor;
    String statusLabel;
    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
      case 'approved':
        statusColor = context.colors.accent;
        statusLabel = AppLocalizations.of(context).statusCompleted;
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusLabel = AppLocalizations.of(context).statusRejected;
        break;
      default:
        statusColor = AppColors.warning;
        statusLabel = AppLocalizations.of(context).statusPending;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: context.colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isCredit ? context.colors.accent : AppColors.error).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
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
                _txnLabel(label),
                if (date.isNotEmpty)
                  Text(date, style: TextStyle(fontSize: AppFontSizes.caption, color: context.colors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}Rs ${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: AppFontSizes.secondary,
                  fontWeight: FontWeight.w700,
                  color: isCredit ? context.colors.accent : context.colors.textPrimary,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusXs),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: AppFontSizes.caption, fontWeight: FontWeight.w600, color: statusColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}