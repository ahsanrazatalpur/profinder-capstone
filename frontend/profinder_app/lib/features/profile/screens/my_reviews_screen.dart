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
import '../../../shared/widgets/universal_app_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/api_service.dart';
import '../../../services/booking_service.dart';
import '../../../l10n/generated/app_localizations.dart';

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
                'professional_name': proBooking['professional_name'] ?? AppLocalizations.of(context)!.professionalDefaultName,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width > 600;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: UniversalAppBar(
        title: AppLocalizations.of(context)!.myReviewsTitle,
        icon: Icons.star_rounded,
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
          : _myReviews.isEmpty
              ? _empty(isDark)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.customerColor,
                  child: ListView.separated(
                    padding: EdgeInsets.all(isTablet ? 20 : 16),
                    itemCount: _myReviews.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _reviewCard(_myReviews[i], isDark, isTablet),
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
                Icons.rate_review_outlined,
                size: 40,
                color: isDark
                    ? Colors.white.withOpacity(0.3)
                    : const Color(0xFFD1D5DB),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              AppLocalizations.of(context)!.myReviewsEmptyTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)!.myReviewsEmptySubtitle,
              style: TextStyle(
                fontSize: 13,
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _reviewCard(Map<String, dynamic> rv, bool isDark, bool isTablet) {
    final rating  = int.tryParse('${rv['rating']}') ?? 0;
    final comment = rv['comment']?.toString() ?? '';
    final name    = rv['professional_name']?.toString() ?? AppLocalizations.of(context)!.professionalDefaultName;
    final parsedDate = DateTime.tryParse(rv['created_at']?.toString() ?? '');
    final date    = parsedDate != null ? AppHelpers.formatDate(parsedDate) : '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      padding: EdgeInsets.all(isTablet ? 16 : 14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.08)
                : Colors.grey.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: isTablet ? 15.0 : 14.0,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              Text(
                date,
                style: TextStyle(
                  fontSize: isTablet ? 12.0 : 11.0,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (i) => Icon(
              i < rating
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              size: isTablet ? 18 : 16,
              color: const Color(0xFFF59E0B),
            )),
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment,
              style: TextStyle(
                fontSize: isTablet ? 14.0 : 13.0,
                color: context.colors.textPrimary,
                height: 1.5,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}