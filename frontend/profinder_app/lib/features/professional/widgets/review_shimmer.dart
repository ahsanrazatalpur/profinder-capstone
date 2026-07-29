// lib/features/professional/widgets/review_shimmer.dart
//
// Animated shimmer skeletons shown while reviews are loading — never a
// bare CircularProgressIndicator. Uses the same sweeping-gradient technique
// as shared/widgets/professional_card.dart's _ShimmerBox so it matches the
// rest of the app's loading language.

import 'package:flutter/material.dart';
import '../../../core/theme/theme_context_ext.dart';

class _ShimmerBlock extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const _ShimmerBlock({
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.colors.divider;
    final highlight = context.colors.surface;
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final sweep = (_controller.value * 3.2) - 1.6;
            return ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (rect) => LinearGradient(
                begin: Alignment(sweep - 0.6, 0),
                end: Alignment(sweep + 0.6, 0),
                colors: [base, highlight, base],
                stops: const [0.15, 0.5, 0.85],
              ).createShader(rect),
              child: Container(color: base),
            );
          },
        ),
      ),
    );
  }
}

class ReviewSummaryShimmer extends StatelessWidget {
  const ReviewSummaryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _ShimmerBlock(width: 64, height: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBlock(width: 120, height: 14, borderRadius: BorderRadius.circular(4)),
                    const SizedBox(height: 8),
                    _ShimmerBlock(width: 90, height: 12, borderRadius: BorderRadius.circular(4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...List.generate(5, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ShimmerBlock(
                    width: double.infinity, height: 10, borderRadius: BorderRadius.circular(6)),
              )),
        ],
      ),
    );
  }
}

class ReviewCardShimmer extends StatelessWidget {
  const ReviewCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _ShimmerBlock(
                  width: 40, height: 40, borderRadius: BorderRadius.all(Radius.circular(20))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBlock(width: 100, height: 12, borderRadius: BorderRadius.circular(4)),
                    const SizedBox(height: 6),
                    _ShimmerBlock(width: 70, height: 10, borderRadius: BorderRadius.circular(4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ShimmerBlock(width: double.infinity, height: 10, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 6),
          _ShimmerBlock(width: 200, height: 10, borderRadius: BorderRadius.circular(4)),
        ],
      ),
    );
  }
}