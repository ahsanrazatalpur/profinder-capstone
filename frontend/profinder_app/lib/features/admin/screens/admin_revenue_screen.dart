// lib/features/admin/screens/admin_revenue_screen.dart
//
// Business Management → Revenue
// Read-only reporting page — no destructive actions on purpose (see design
// spec: Revenue is where an admin understands "how are we doing," not
// where they fix something).
//
// Backend: GET /api/admin-panel/revenue/?days=30

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';

class AdminRevenueScreen extends StatefulWidget {
  const AdminRevenueScreen({super.key});

  @override
  State<AdminRevenueScreen> createState() => _AdminRevenueScreenState();
}

class _AdminRevenueScreenState extends State<AdminRevenueScreen> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  int _rangeDays = 30;
  Map<String, dynamic> _data = {};

  static const _ranges = [7, 30, 90];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await _api.get('/admin-panel/revenue/?days=$_rangeDays');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _data = r.data is Map ? Map<String, dynamic>.from(r.data) : {};
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load revenue data'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.adminColor))
            : _error != null
                ? _errorState()
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.adminColor,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _header(),
                          const SizedBox(height: 16),
                          _summaryCard(),
                          const SizedBox(height: 16),
                          const Text('Revenue by Category',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          _categoryBreakdown(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _header() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.adminColor, Color(0xFFB91C1C)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.trending_up_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Revenue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: _ranges.map((d) {
                  final isActive = _rangeDays == d;
                  return GestureDetector(
                    onTap: () { if (_rangeDays != d) { setState(() => _rangeDays = d); _load(); } },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: isActive ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                      child: Text('${d}D', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: isActive ? AppColors.adminColor : Colors.white)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );

  Widget _summaryCard() {
    final total = double.tryParse(_data['total_revenue']?.toString() ?? '0') ?? 0;
    final change = (_data['change_percentage'] as num?)?.toDouble() ?? 0;
    final avgTxn = _data['avg_transaction']?.toString() ?? '0';
    final isUp = change >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rs ${total.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF16A34A))),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 14, color: isUp ? const Color(0xFF16A34A) : AppColors.error),
              Text('${change.abs()}% vs previous $_rangeDays days',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: isUp ? const Color(0xFF16A34A) : AppColors.error)),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stat('Avg. Transaction', 'Rs $avgTxn'),
              _stat('Period', 'Last $_rangeDays days'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF))),
        ],
      );

  Widget _categoryBreakdown() {
    final rows = (_data['by_category'] as List?) ?? [];
    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: const Center(child: Text('No category data yet', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12))),
      );
    }
    final maxTotal = rows
        .map((r) => double.tryParse(r['total']?.toString() ?? '0') ?? 0)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        children: rows.map((r) {
          final total = double.tryParse(r['total']?.toString() ?? '0') ?? 0;
          final ratio = maxTotal == 0 ? 0.0 : total / maxTotal;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(r['category']?.toString() ?? '',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    Text('Rs $total (${r['count']})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: ratio, minHeight: 6,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF16A34A))),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _errorState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 10),
            const Text('Failed to load revenue data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminColor),
            ),
          ],
        ),
      );
}