// lib/shared/widgets/profile_section_header.dart

import 'package:flutter/material.dart';

import '../../core/theme/theme_context_ext.dart';
import '../../core/utils/responsive_utils.dart';

/// Reusable section title for profile and settings screens.
///
/// Provides a consistent heading across all 4 roles (Guest, Customer,
/// Professional, Admin) with optional leading icon and trailing action.
class ProfileSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;
  final double? scale;
  final Color? iconColor;

  const ProfileSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    this.scale,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveScale =
        scale ??
        ResponsiveUtils.scaleForWidth(MediaQuery.sizeOf(context).width);
    final color = iconColor ?? context.colors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2, right: 2),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: ResponsiveUtils.sp(14, effectiveScale, min: 12, max: 16),
                color: color,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: ResponsiveUtils.sp(
                  11.5,
                  effectiveScale,
                  min: 10,
                  max: 13,
                ),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
                color: color,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
