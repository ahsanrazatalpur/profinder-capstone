// lib/features/profile/screens/payments_screen.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/theme_context_ext.dart';

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
      case 'completed': return const Color(0xFF10B981);
      case 'pending':   return const Color(0xFFF59E0B);
      case 'failed':    return AppColors.error;
      case 'refunded':  return const Color(0xFF6366F1);
      default:          return context.colors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Payments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF374151)), onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _payments.isEmpty
              ? _empty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: context.colors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _payments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final p = _payments[i];
                      final amount   = double.tryParse('${p['amount']}') ?? 0;
                      final currency = p['currency']?.toString() ?? 'USD';
                      final status   = p['status']?.toString() ?? 'pending';
                      final parsedDate = DateTime.tryParse(p['created_at']?.toString() ?? '');
                      final date     = parsedDate != null ? AppHelpers.formatDate(parsedDate) : '';
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
                        child: Row(children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.receipt_rounded, color: _statusColor(status), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$currency ${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(date, style: TextStyle(fontSize: 11.5, color: context.colors.textSecondary)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                            child: Text(AppHelpers.capitalize(status),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor(status))),
                          ),
                        ]),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 56, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 12),
            const Text('No payments yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 4),
            const Text('Your transaction history will appear here', style: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF))),
          ],
        ),
      );
}