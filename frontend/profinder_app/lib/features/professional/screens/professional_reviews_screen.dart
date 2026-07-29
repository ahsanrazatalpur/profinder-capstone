// lib/features/professional/screens/professional_reviews_screen.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_context_ext.dart';

class ProfessionalReviewsScreen extends StatefulWidget {
  const ProfessionalReviewsScreen({super.key});

  @override
  State<ProfessionalReviewsScreen> createState() => _ProfessionalReviewsScreenState();
}

class _ProfessionalReviewsScreenState extends State<ProfessionalReviewsScreen> {
  final _api = ApiService();
  List<dynamic> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get(AppConstants.reviews);
      final data = res.data;
      final list = data is List ? data : (data is Map ? (data['results'] ?? data['reviews'] ?? []) as List : []);
      if (!mounted) return;
      setState(() { _reviews = list; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<double>(0, (acc, r) => acc + (r['rating'] ?? 0).toDouble());
    return sum / _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        title: Text('Reviews', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: context.colors.textPrimary), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.professionalColor,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  if (_reviews.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(
                        children: [
                          Icon(Icons.rate_review_outlined, size: 56, color: context.colors.textDisabled),
                          const SizedBox(height: 12),
                          Text('No reviews yet', style: TextStyle(fontSize: 14, color: context.colors.textSecondary)),
                        ],
                      ),
                    )
                  else
                    ..._reviews.map((r) => _buildReviewCard(r)),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(_averageRating.toStringAsFixed(1),
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: List.generate(5, (i) => Icon(
                    i < _averageRating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 16, color: Colors.white,
                  ))),
              const SizedBox(height: 4),
              Text('${_reviews.length} review${_reviews.length == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(dynamic r) {
    final customerName = r['reviewer_name'] ?? r['customer_name'] ?? 'Customer';
    final rating       = (r['rating'] ?? 0).toDouble();
    final comment      = r['comment']?.toString() ?? r['review']?.toString() ?? '';
    final date         = r['created_at']?.toString().split('T').first ?? r['date']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: context.colors.primaryLight,
                child: Text(AppHelpers.getInitials(customerName.toString()),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.colors.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customerName.toString(), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
                    if (date.isNotEmpty) Text(date, style: TextStyle(fontSize: 10.5, color: context.colors.textSecondary)),
                  ],
                ),
              ),
              Row(children: List.generate(5, (i) => Icon(
                    i < rating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 14, color: const Color(0xFFF59E0B),
                  ))),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(comment, style: TextStyle(fontSize: 13, color: context.colors.textPrimary, height: 1.5)),
          ],
        ],
      ),
    );
  }
}