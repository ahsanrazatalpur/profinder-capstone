// lib/features/support/widgets/support_section_heading.dart
//
// Small section heading for the Help Center / Privacy screens. Theme-aware
// (context.colors / context.textStyles), direction-aware, announced as a
// heading to screen readers.

import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/theme_context_ext.dart';

class SupportSectionHeading extends StatelessWidget {
  final String text;
  final IconData? icon;
  final EdgeInsetsGeometry padding;

  const SupportSectionHeading({
    super.key,
    required this.text,
    this.icon,
    this.padding = const EdgeInsetsDirectional.only(
      top: AppSizes.md,
      bottom: AppSizes.sm,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: padding,
      child: Semantics(
        header: true,
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppSizes.iconMd - 4, color: colors.primary),
              const SizedBox(width: AppSizes.sm),
            ],
            Expanded(
              child: Text(
                text,
                // letterSpacing 0: negative spacing breaks joined Arabic/Urdu script.
                style: context.textStyles.h3.copyWith(letterSpacing: 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
