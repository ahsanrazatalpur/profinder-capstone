// lib/features/admin/screens/admin_reviews_screen.dart
//
// Business Management → Reviews
// Never edit review text — only delete (with a logged reason). Editing
// customer-authored content is an integrity risk.
//
// Backend:
//   GET    /api/admin-panel/reviews/?rating=1&search=name
//   DELETE /api/admin-panel/reviews/<id>/   { reason }

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  final _api = ApiService();
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  String? _error;
  List<dynamic> _all = [];
  List<dynamic> _filtered = [];
  int? _ratingFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final query = _ratingFilter != null ? '?rating=$_ratingFilter' : '';
      final r = await _api.get('/admin-panel/reviews/$query');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _all = r.data is List ? List<dynamic>.from(r.data) : [];
      });
      _applySearch();
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load reviews'; });
    }
  }

  void _applySearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((r) =>
              (r['professional_name'] ?? '').toString().toLowerCase().contains(q) ||
              (r['reviewer_name'] ?? '').toString().toLowerCase().contains(q)).toList();
    });
  }

  Map<int, int> get _distribution {
    final dist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in _all) {
      final rating = (r['rating'] as num?)?.toInt() ?? 0;
      if (dist.containsKey(rating)) dist[rating] = dist[rating]! + 1;
    }
    return dist;
  }

  @override
  Widget build(BuildContext context) {
    final avgRating = _all.isEmpty ? 0.0 :
        _all.fold<double>(0, (a, r) => a + ((r['rating'] as num?)?.toDouble() ?? 0)) / _all.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.adminColor, Color(0xFFB91C1C)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Reviews', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text('Avg rating: ${avgRating.toStringAsFixed(1)} ★ · ${_all.length} total',
                            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.85))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => _applySearch(),
                    decoration: InputDecoration(
                      hintText: 'Search by professional or reviewer…',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true, fillColor: const Color(0xFFF5F7FA),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _ratingChip(null, 'All'),
                        const SizedBox(width: 8),
                        for (var i = 5; i >= 1; i--) ...[
                          _ratingChip(i, '$i★ (${_distribution[i]})'),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
                                  itemBuilder: (_, i) => _reviewCard(_filtered[i]),
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ratingChip(int? rating, String label) {
    final isActive = _ratingFilter == rating;
    return GestureDetector(
      onTap: () { setState(() => _ratingFilter = rating); _load(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF59E0B).withOpacity(0.12) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? const Color(0xFFF59E0B) : Colors.transparent),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? const Color(0xFFF59E0B) : const Color(0xFF6B7280))),
      ),
    );
  }

  Widget _reviewCard(dynamic r) {
    final rating = (r['rating'] as num?)?.toInt() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(r['professional_name']?.toString() ?? '',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              Row(
                children: List.generate(5, (i) => Icon(
                    i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 14, color: const Color(0xFFF59E0B))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('by ${r['reviewer_name'] ?? 'Unknown'}', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          if ((r['comment'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(r['comment'].toString(), style: const TextStyle(fontSize: 12.5, color: Color(0xFF374151))),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text(r['created_at']?.toString() ?? '', style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF))),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _deleteDialog(r),
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                label: const Text('Delete', style: TextStyle(fontSize: 12, color: AppColors.error)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _deleteDialog(dynamic review) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This permanently removes the review. Provide a reason for the audit log.',
                style: TextStyle(fontSize: 12.5)),
            const SizedBox(height: 10),
            TextField(controller: reasonCtrl, decoration: const InputDecoration(hintText: 'Reason (required)'), maxLines: 2),
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
                await _api.deleteWithBody('/admin-panel/reviews/${review['id']}/',
                    {'reason': reasonCtrl.text.trim()});
                _load();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete review.')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Center(
          child: Column(children: [
            Icon(Icons.star_border_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            const Text('No reviews found', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
          ]),
        ),
      );

  Widget _errorState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 10),
            const Text('Failed to load reviews', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminColor),
            ),
          ],
        ),
      );
}