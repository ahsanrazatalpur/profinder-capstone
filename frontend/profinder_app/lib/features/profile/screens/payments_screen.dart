// lib/features/profile/screens/payments_screen.dart

import 'package:flutter/material.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../services/api_service.dart';
import '../../../l10n/generated/app_localizations.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/payments/');
      final list = res.data is List ? List<dynamic>.from(res.data) : [];
      list.sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
      _payments = list;
    } catch (_) {
      _payments = [];
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'failed':
        return AppColors.error;
      case 'refunded':
        return const Color(0xFF6366F1);
      default:
        return context.colors.textSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return AppLocalizations.of(context)!.paymentStatusCompleted;
      case 'pending':
        return AppLocalizations.of(context)!.paymentStatusPending;
      case 'failed':
        return AppLocalizations.of(context)!.paymentStatusFailed;
      case 'refunded':
        return AppLocalizations.of(context)!.paymentStatusRefunded;
      default:
        return AppHelpers.capitalize(status);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width > 600;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: UniversalAppBar(
        title: AppLocalizations.of(context)!.paymentsTitle,
        icon: Icons.payments_rounded,
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
          : _payments.isEmpty
              ? _empty(isDark)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.customerColor,
                  child: ListView.separated(
                    padding: EdgeInsets.all(isTablet ? 20 : 16),
                    itemCount: _payments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final p = _payments[i];
                      final amount = double.tryParse('${p['amount']}') ?? 0;
                      final currency = p['currency']?.toString() ?? 'USD';
                      final status = p['status']?.toString() ?? 'pending';
                      final parsedDate = DateTime.tryParse(p['created_at']?.toString() ?? '');
                      final date = parsedDate != null ? AppHelpers.formatDate(parsedDate) : '';
                      final statusColor = _statusColor(status);
                      final statusLabel = _statusLabel(status);

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                        padding: EdgeInsets.all(isTablet ? 16 : 14),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : const Color(0xFFE5E7EB),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.receipt_rounded,
                                color: statusColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$currency ${amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: isTablet ? 15.0 : 14.0,
                                      fontWeight: FontWeight.w700,
                                      color: context.colors.textPrimary,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    date,
                                    style: TextStyle(
                                      fontSize: isTablet ? 12.0 : 11.5,
                                      color: context.colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: isTablet ? 11.5 : 11.0,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _empty(bool isDark) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 40,
                color: isDark
                    ? Colors.white.withOpacity(0.3)
                    : const Color(0xFFD1D5DB),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              AppLocalizations.of(context)!.noPaymentsTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)!.noPaymentsSubtitle,
              style: TextStyle(
                fontSize: 13,
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}