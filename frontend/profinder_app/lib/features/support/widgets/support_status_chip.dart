// lib/features/support/widgets/support_status_chip.dart
//
// Status chip that always pairs an icon with text (never color alone), using
// the adaptive warning / info / danger / success tokens so it reads in both
// light and dark themes.

import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_context_ext.dart';

enum SupportChipTone { neutral, info, success, warning, danger }

class SupportStatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final SupportChipTone tone;

  const SupportStatusChip({
    super.key,
    required this.label,
    required this.icon,
    this.tone = SupportChipTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    late final Color bg;
    late final Color fg;
    late final Color border;
    switch (tone) {
      case SupportChipTone.info:
        bg = c.infoBg; fg = c.infoText; border = c.infoBorder;
        break;
      case SupportChipTone.success:
        bg = c.accentLight; fg = c.successText; border = c.successText.withValues(alpha: 0.35);
        break;
      case SupportChipTone.warning:
        bg = c.warningBg; fg = c.warningText; border = c.warningBorder;
        break;
      case SupportChipTone.danger:
        bg = c.dangerBg; fg = c.dangerText; border = c.dangerBorder;
        break;
      case SupportChipTone.neutral:
        bg = c.divider.withValues(alpha: 0.35); fg = c.textSecondary; border = c.divider;
        break;
    }

    return Semantics(
      container: true,
      label: label,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppSizes.iconSm, color: fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppFontSizes.small,
                    fontWeight: FontWeight.w600,
                    color: fg,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}