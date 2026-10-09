// lib/features/admin/screens/admin_payments_screen.dart
//
// Business Management → Payments
// Read-only listing (no bulk-delete — financial records only ever get
// exported, never destroyed) + single-payment Refund action.
//
// Backend:
//   GET   /api/admin-panel/payments/?status=completed&search=email
//   PATCH /api/admin-panel/payments/<id>/refund/   { "reason": "..." }

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  final _api = ApiService();
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  List<dynamic> _all = [];
  List<dynamic> _filtered = [];
  String _statusFilter = 'all';

  static const _statuses = [
    ('all', 'All', AppColors.gray700),
    ('completed', 'Completed', AppColors.greenDeep),
    ('pending', 'Pending', AppColors.warningAmber),
    ('failed', 'Failed', AppColors.favoriteRed),
    ('refunded', 'Refunded', AppColors.slate500),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final query = _statusFilter == 'all' ? '' : '?status=$_statusFilter';
      final r = await _api.get('/admin-panel/payments/$query');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _all = r.data is List ? List<dynamic>.from(r.data) : [];
      });
      _applySearch();
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load payments'; });
    }
  }

  void _applySearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((p) =>
              (p['user_name'] ?? '').toString().toLowerCase().contains(q) ||
              (p['user_email'] ?? '').toString().toLowerCase().contains(q) ||
              (p['stripe_id'] ?? '').toString().toLowerCase().contains(q)).toList();
    });
  }

  Color _colorFor(String status) =>
      _statuses.firstWhere((s) => s.$1 == status, orElse: () => _statuses[0]).$3;

  @override
  Widget build(BuildContext context) {
    final total = _filtered.fold<double>(
        0, (a, p) => a + (double.tryParse(p['amount']?.toString() ?? '0') ?? 0));

    return Scaffold(
      backgroundColor: AppColors.lightScaffold,
      appBar: UniversalAppBar(
        title: 'Payments',
        subtitle: 'Rs ${total.toStringAsFixed(0)} shown',
        icon: Icons.payments_rounded,
        showBack: false,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _searchAndFilters(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.adminColor))
                  : _error != null
                      ? _errorState()
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.adminColor,
                          child: _filtered.isEmpty
                              ? ListView(children: [_emptyState()])
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                                  itemCount: _filtered.length,
                                  itemBuilder: (_, i) => _paymentCard(_filtered[i]),
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchAndFilters() => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => _applySearch(),
              decoration: InputDecoration(
                hintText: 'Search by name, email, or transaction ID…',
                hintStyle: const TextStyle(fontSize: AppFontSizes.secondary, color: AppColors.neutral400),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true, fillColor: AppColors.lightScaffold,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radius10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _statuses.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final (key, label, color) = _statuses[i];
                  final isActive = _statusFilter == key;
                  return GestureDetector(
                    onTap: () { setState(() => _statusFilter = key); _load(); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isActive ? color.withValues(alpha: 0.12) : AppColors.lightScaffold,
                        borderRadius: BorderRadius.circular(AppSizes.radiusChip),
                        border: Border.all(color: isActive ? color : Colors.transparent),
                      ),
                      alignment: Alignment.center,
                      child: Text(label, style: TextStyle(
                          fontSize: AppFontSizes.small, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive ? color : AppColors.grayDeep)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );

  Widget _paymentCard(dynamic p) {
    final status = p['status']?.toString() ?? 'pending';
    final color = _colorFor(status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSizes.radius14),
          border: Border.all(color: AppColors.neutral200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['user_name']?.toString() ?? '', style: const TextStyle(fontSize: AppFontSizes.secondary, fontWeight: FontWeight.w700)),
                    Text(p['user_email']?.toString() ?? '', style: const TextStyle(fontSize: AppFontSizes.caption, color: AppColors.neutral400)),
                  ],
                ),
              ),
              Text('${p['currency'] ?? 'Rs'} ${p['amount'] ?? '0'}',
                  style: const TextStyle(fontSize: AppFontSizes.input, fontWeight: FontWeight.w800, color: AppColors.greenDeep)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppSizes.radiusChip)),
                child: Text(status.toUpperCase(), style: TextStyle(fontSize: AppFontSizes.nano, fontWeight: FontWeight.w800, color: color)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(p['created_at']?.toString() ?? '',
                    style: const TextStyle(fontSize: 10.5, color: AppColors.neutral400), overflow: TextOverflow.ellipsis),
              ),
              if (status == 'completed')
                TextButton(
                  onPressed: () => _refundDialog(p),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10)),
                  child: const Text('Refund', style: TextStyle(fontSize: AppFontSizes.small, color: AppColors.error, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          if ((p['stripe_id'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Txn: ${p['stripe_id']}', style: const TextStyle(fontSize: AppFontSizes.micro, color: Color(0xFFB0B8C1))),
            ),
        ],
      ),
    );
  }

  void _refundDialog(dynamic payment) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Refund Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Refund Rs ${payment['amount']} to ${payment['user_name']}?',
                style: const TextStyle(fontSize: AppFontSizes.secondary)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(hintText: 'Reason (required)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(dialogContext);
              try {
                await _api.patch('/admin-panel/payments/${payment['id']}/refund/',
                    {'reason': reasonCtrl.text.trim()});
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment refunded.')));
                _load();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Refund failed.')));
              }
            },
            child: const Text('Refund', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Center(
          child: Column(children: [
            Icon(Icons.payments_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            const Text('No payments found', style: TextStyle(fontSize: AppFontSizes.secondary, color: AppColors.neutral400)),
          ]),
        ),
      );

  Widget _errorState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 10),
            const Text('Failed to load payments', style: TextStyle(fontSize: AppFontSizes.body, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminColor),
            ),
          ],
        ),
      );
}