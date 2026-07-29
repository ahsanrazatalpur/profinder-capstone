// PATH: lib/features/chat/presentation/widgets/unread_nav_badge.dart
//
// ✅ NEW — Wraps a bottom-nav icon with a small red unread-count badge.
// Listens to ConversationListProvider directly so both the Customer and
// Professional bottom navs update instantly whenever the conversation
// list refreshes (poll, socket-triggered refresh, or returning from a chat).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/conversation_list_provider.dart';

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
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}