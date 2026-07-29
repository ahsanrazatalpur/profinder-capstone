// lib/features/profile/screens/my_reviews_screen.dart
//
// MY REVIEWS — the reviews *I* (the customer) have written.
//
// ⚠ Backend note: there's no dedicated `/reviews/mine/` endpoint yet —
// only GET /reviews/<professional_id>/ (all reviews for a professional).
// So this screen takes the honest approach: look at my completed bookings,
// fetch reviews for each distinct professional I've booked, and keep only
// the ones written by me. Bounded to a sane number of professionals so it
// stays fast. Adding a `/reviews/mine/` endpoint later would make this a
// single call — the UI below won't need to change, only `_load()`.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/api_service.dart';
import '../../../services/booking_service.dart';
import '../../../core/theme/theme_context_ext.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  final ApiService     _api        = ApiService();
  final BookingService _bookingSvc = BookingService();

  List<Map<String, dynamic>> _myReviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final meRes = await _api.get(AppConstants.me);
      final myId  = (meRes.data as Map<String, dynamic>)['id']?.toString();
      final res  = await _bookingSvc.getMyBookings();
      final bookings = res['success'] == true ? List<dynamic>.from(res['data'] ?? []) : [];

      final completed = bookings.where((b) => b['status'] == 'completed').toList();
      final proIds = <String>{};
      for (final b in completed) {
        final pid = b['professional']?.toString();
        if (pid != null && pid.isNotEmpty) proIds.add(pid);
      }

      final reviews = <Map<String, dynamic>>[];
      // Capped — see file header note on why this is client-side derived.
      for (final pid in proIds.take(15)) {
        try {
          final r = await _api.get('${AppConstants.reviewsForProfessionalBase}$pid/reviews/');
          final list = r.data is List ? List<dynamic>.from(r.data) : [];
          for (final rv in list) {
            if (rv['reviewer']?.toString() == myId) {
              final proBooking = completed.firstWhere((b) => b['professional']?.toString() == pid, orElse: () => {});
              reviews.add({
                ...Map<String, dynamic>.from(rv),
                'professional_name': proBooking['professional_name'] ?? 'Professional',
              });
            }
          }
        } catch (_) {
          // skip this professional's reviews on error, keep going
        }
      }
      reviews.sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
      _myReviews = reviews;
    } catch (_) {
      _myReviews = [];
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
        title: const Text('My Reviews', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF374151)), onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _myReviews.isEmpty
              ? _empty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: context.colors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _myReviews.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _reviewCard(_myReviews[i]),
                  ),
                ),
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.rate_review_outlined, size: 56, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 12),
            const Text('No reviews written yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 4),
            const Text('Complete a booking to leave your first review', style: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF))),
          ],
        ),
      );

  Widget _reviewCard(Map<String, dynamic> rv) {
    final rating  = int.tryParse('${rv['rating']}') ?? 0;
    final comment = rv['comment']?.toString() ?? '';
    final name    = rv['professional_name']?.toString() ?? 'Professional';
    final parsedDate = DateTime.tryParse(rv['created_at']?.toString() ?? '');
    final date    = parsedDate != null ? AppHelpers.formatDate(parsedDate) : '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
            Text(date, style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
          ]),
          const SizedBox(height: 6),
          Row(children: List.generate(5, (i) => Icon(
                i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                size: 16, color: const Color(0xFFF59E0B),
              ))),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(comment, style: const TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.4)),
          ],
        ],
      ),
    );
  }
}