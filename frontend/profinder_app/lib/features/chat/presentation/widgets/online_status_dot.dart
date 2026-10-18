// lib/features/chat/presentation/widgets/online_status_dot.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_context_ext.dart';

/// Wraps any avatar widget and overlays a green (online) or gray (offline) dot
/// on the bottom-right corner — providing dynamic WhatsApp/Messenger style presence.
class AvatarWithStatus extends StatelessWidget {
  final Widget avatar;
  final bool isOnline;
  final double size;
  final bool showOfflineDot;

  const AvatarWithStatus({
    super.key,
    required this.avatar,
    required this.isOnline,
    this.size = 40,
    this.showOfflineDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final dotSize = (size * 0.28).clamp(8.0, 16.0);
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? context.colors.surface
        : Colors.white;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(width: size, height: size, child: avatar),
          if (isOnline || showOfflineDot)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.emerald : AppColors.neutral400,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: (isOnline ? AppColors.emerald : Colors.black)
                          .withValues(alpha: 0.25),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Standalone colored dot (green for online, gray for offline)
class OnlineStatusDot extends StatelessWidget {
  final bool isOnline;
  final double size;

  const OnlineStatusDot({
    super.key,
    required this.isOnline,
    this.size = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isOnline ? AppColors.emerald : AppColors.neutral400,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// A compact pill showing status dot + "Online" / "Offline" text
class OnlineStatusBadge extends StatelessWidget {
  final bool isOnline;
  final bool isCompact;

  const OnlineStatusBadge({
    super.key,
    required this.isOnline,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isOnline ? AppColors.emerald : AppColors.neutral400;
    final text = isOnline ? 'Online' : 'Offline';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 7 : 9,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: isOnline
            ? (isDark ? AppColors.emerald.withValues(alpha: 0.16) : AppColors.emerald.withValues(alpha: 0.10))
            : (isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.neutral100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isOnline ? 0.35 : 0.20),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OnlineStatusDot(isOnline: isOnline, size: isCompact ? 6 : 7),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: isOnline
                  ? (isDark ? AppColors.emerald : const Color(0xFF059669))
                  : context.colors.textSecondary,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
