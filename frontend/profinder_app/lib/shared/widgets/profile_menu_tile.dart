// lib/shared/widgets/profile_menu_tile.dart

import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/theme/theme_context_ext.dart';
import '../../core/utils/responsive_utils.dart';

/// Reusable profile menu tile used across Guest, Customer, Professional,
/// and Admin account settings screens.
///
/// Supports:
/// - Custom leading icon with themed background container.
/// - Primary label and optional secondary subtitle.
/// - Custom trailing widget (defaults to chevron).
/// - Locked/disabled state (with dimmed opacity for guest preview).
/// - Responsive scaling for phone, tablet, and desktop screens.
class ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onLockedTap;
  final Widget? trailing;
  final bool isLocked;
  final double? scale;
  final Color? titleColor;
  final EdgeInsetsGeometry? contentPadding;

  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
    this.onLockedTap,
    this.trailing,
    this.isLocked = false,
    this.scale,
    this.titleColor,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveScale =
        scale ??
        ResponsiveUtils.scaleForWidth(MediaQuery.sizeOf(context).width);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leadingSize = ResponsiveUtils.sp(
      38,
      effectiveScale,
      min: 36,
      max: 44,
    );

    final tile = Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.03),
            blurRadius: 4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: InkWell(
          onTap: isLocked ? onLockedTap : onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Padding(
            padding:
                contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: leadingSize,
                  height: leadingSize,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: ResponsiveUtils.sp(
                      20,
                      effectiveScale,
                      min: 18,
                      max: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.sp(
                            14.5,
                            effectiveScale,
                            min: 14,
                            max: 17,
                          ),
                          fontWeight: FontWeight.w600,
                          color: titleColor ?? context.colors.textPrimary,
                          letterSpacing: 0.1,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.sp(
                              12.5,
                              effectiveScale,
                              min: 12,
                              max: 14,
                            ),
                            fontWeight: FontWeight.w400,
                            color: context.colors.textSecondary.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                trailing ??
                    (isLocked
                        ? Icon(
                            Icons.lock_outline_rounded,
                            color: context.colors.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                            size: ResponsiveUtils.sp(
                              18,
                              effectiveScale,
                              min: 16,
                              max: 20,
                            ),
                          )
                        : Icon(
                            Icons.chevron_right_rounded,
                            color: context.colors.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                            size: ResponsiveUtils.sp(
                              20,
                              effectiveScale,
                              min: 18,
                              max: 24,
                            ),
                          )),
              ],
            ),
          ),
        ),
      ),
    );

    if (isLocked) {
      return Opacity(opacity: 0.55, child: tile);
    }

    return tile;
  }
}
