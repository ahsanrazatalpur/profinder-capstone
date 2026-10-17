// lib/features/support/widgets/support_blocks_view.dart
//
// Renders server "blocks" (heading / paragraph / bullet) for Help articles.
// Lays out in the direction of the text itself (isRtl), not the app locale.

import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../models/policy_document.dart';
import 'support_section_heading.dart';

class SupportBlocksView extends StatelessWidget {
  final List<PolicyBlock> blocks;
  final bool isRtl;

  const SupportBlocksView({super.key, required this.blocks, required this.isRtl});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final b in blocks) _block(context, b)],
      ),
    );
  }

  Widget _block(BuildContext context, PolicyBlock block) {
    final colors = context.colors;
    final styles = context.textStyles;
    switch (block.type) {
      case PolicyBlockType.heading:
        return SupportSectionHeading(
          text: block.text,
          padding: const EdgeInsetsDirectional.only(top: AppSizes.md, bottom: AppSizes.sm),
        );
      case PolicyBlockType.bullet:
        return Padding(
          padding: const EdgeInsetsDirectional.only(bottom: AppSizes.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 9, end: AppSizes.sm + 4),
                child: Icon(Icons.circle, size: 6, color: colors.textSecondary),
              ),
              Expanded(
                child: Text(block.text, style: styles.bodyLarge.copyWith(height: 1.55, letterSpacing: 0)),
              ),
            ],
          ),
        );
      case PolicyBlockType.paragraph:
        return Padding(
          padding: const EdgeInsetsDirectional.only(bottom: AppSizes.sm + 4),
          child: Text(block.text, style: styles.bodyLarge.copyWith(height: 1.55, letterSpacing: 0)),
        );
    }
  }
}