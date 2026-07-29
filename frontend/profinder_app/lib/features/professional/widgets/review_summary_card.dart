// lib/features/professional/widgets/review_summary_card.dart

import 'package:flutter/material.dart';
import '../../../core/theme/theme_context_ext.dart';

class ReviewSummaryCard extends StatelessWidget {
  final double averageRating;
  final int totalReviews;
  /// Maps '5'..'1' → percentage (0-100)
  final Map<String, int> distributionPercent;

  const ReviewSummaryCard({
    super.key,
    required this.averageRating,
    required this.totalReviews,
    required this.distributionPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.divider),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: context.colors.textPrimary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (i) => Icon(
                            i < averageRating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 18,
                            color: const Color(0xFFF59E0B),
                          )),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalReviews review${totalReviews == 1 ? '' : 's'}',
                      style: TextStyle(fontSize: 12.5, color: context.colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...[5, 4, 3, 2, 1].map((star) => _DistributionRow(
                star: star,
                percent: distributionPercent['$star'] ?? 0,
              )),
        ],
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  final int star;
  final int percent;
  const _DistributionRow({required this.star, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('$star★', style: TextStyle(fontSize: 11.5, color: context.colors.textSecondary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 7,
                child: Stack(
                  children: [
                    Container(color: context.colors.divider),
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      tween: Tween(begin: 0, end: percent / 100),
                      builder: (context, value, _) => FractionallySizedBox(
                        widthFactor: value.clamp(0, 1),
                        child: Container(color: const Color(0xFFF59E0B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 34,
            child: Text('$percent%',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
          ),
        ],
      ),
    );
  }
}