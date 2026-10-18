// lib/features/support/widgets/support_info_note.dart
//
// Small informational banner (e.g. "shown in English"). Theme tokens only.

import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/theme_context_ext.dart';

class SupportInfoNote extends StatelessWidget {
  final String message;

  const SupportInfoNote({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSizes.sm + 4),
      decoration: BoxDecoration(
        color: colors.infoBg,
        border: Border.all(color: colors.infoBorder),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: AppSizes.iconMd - 4,
            color: colors.infoText,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              message,
              style: context.textStyles.bodySmall.copyWith(
                color: colors.infoText,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
