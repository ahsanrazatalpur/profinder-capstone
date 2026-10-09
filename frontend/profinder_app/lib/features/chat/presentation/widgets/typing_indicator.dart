// lib/features/chat/presentation/widgets/typing_indicator.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/theme_context_ext.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';

/// The classic 3-dot "someone is typing" bubble, left-aligned like an
/// incoming message. Dots pulse in a staggered wave.
class TypingIndicatorBubble extends StatefulWidget {
  const TypingIndicatorBubble({super.key});

  @override
  State<TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<TypingIndicatorBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppSizes.radiusLg),
            topRight: Radius.circular(AppSizes.radiusLg),
            bottomRight: Radius.circular(AppSizes.radiusLg),
            bottomLeft: Radius.circular(AppSizes.radiusTiny),
          ),
          border: Border.all(color: context.colors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) => _Dot(controller: _controller, delay: i * 0.2)),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  const _Dot({required this.controller, required this.delay});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        final t = (controller.value + delay) % 1.0;
        final scale = 0.6 + 0.4 * (1 - (2 * t - 1).abs()); // triangle wave, 0.6 -> 1.0 -> 0.6
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(color: AppColors.slate400, shape: BoxShape.circle),
            ),
          ),
        );
      },
    );
  }
}