// Decorator widget wrapping navigation icons with real-time unread message counters.
// Listens to [ConversationListProvider] for immediate badge updates across customer and professional interfaces.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/conversation_list_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';

class UnreadNavBadge extends StatelessWidget {
  final Widget icon;
  const UnreadNavBadge({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConversationListProvider>(
      builder: (context, provider, _) {
        final count = provider.totalUnreadCount;
        if (count <= 0) return icon;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            icon,
            Positioned(
              right: -6,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                constraints: const BoxConstraints(minWidth: 16),
                decoration: BoxDecoration(
                  color: AppColors.favoriteRed,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: AppFontSizes.micro, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}