// lib/features/support/widgets/support_category_tile.dart
//
// Accessible, tappable category row for the Help Center (icon, title, optional
// subtitle, chevron). Theme tokens only; chevron mirrors automatically in RTL
// (Icons.chevron_right_* is a text-direction-aware icon).

import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_context_ext.dart';

class SupportCategoryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const SupportCategoryTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;

    return Semantics(
      button: true,
      container: true,
      label: hasSubtitle ? '$title. $subtitle' : title,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: colors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          side: BorderSide(color: colors.divider),
        ),
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            // >= 48dp touch target, grows with large text.
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSizes.md, AppSizes.sm + 4, AppSizes.sm + 4, AppSizes.sm + 4,
              ),
              child: Row(
                children: [
                  Container(
                    width: AppSizes.avatarMd - 4,
                    height: AppSizes.avatarMd - 4,
                    decoration: BoxDecoration(
                      color: colors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: AppSizes.iconMd - 2, color: colors.primary),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                        if (hasSubtitle) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.bodySmall.copyWith(
                              fontSize: AppFontSizes.secondary,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}