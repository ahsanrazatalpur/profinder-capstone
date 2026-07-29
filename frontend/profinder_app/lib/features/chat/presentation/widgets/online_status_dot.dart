// lib/features/chat/presentation/widgets/online_status_dot.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Wraps any avatar widget and overlays a small green/gray dot bottom-right —
/// the familiar WhatsApp/Messenger online indicator.
class AvatarWithStatus extends StatelessWidget {
  final Widget avatar;
  final bool isOnline;
  final double size;

  const AvatarWithStatus({
    super.key,
    required this.avatar,
    required this.isOnline,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final dotSize = size * 0.28;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(width: size, height: size, child: avatar),
          if (isOnline)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}