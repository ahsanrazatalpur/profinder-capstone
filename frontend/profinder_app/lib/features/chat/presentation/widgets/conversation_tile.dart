// lib/features/chat/presentation/widgets/conversation_tile.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_helpers.dart';
import '../../domain/entities/conversation_entity.dart';
import 'online_status_dot.dart';
import '../../../../core/theme/theme_context_ext.dart';

class ConversationTile extends StatelessWidget {
  final ConversationEntity conversation;
  final VoidCallback onTap;

  const ConversationTile({super.key, required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            AvatarWithStatus(
              isOnline: conversation.otherUserOnline,
              size: 52,
              avatar: CircleAvatar(
                radius: 26,
                backgroundColor: context.colors.primaryLight,
                backgroundImage:
                    conversation.otherUserPhoto != null ? CachedNetworkImageProvider(conversation.otherUserPhoto!) : null,
                child: conversation.otherUserPhoto == null
                    ? Text(_initials(conversation.otherUserName),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.primary))
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.otherUserName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                            color: context.colors.textPrimary,
                          ),
                        ),
                      ),
                      if (conversation.lastMessageAt != null)
                        Text(_timeLabel(conversation.lastMessageAt!),
                            style: TextStyle(
                              fontSize: 12,
                              color: hasUnread ? context.colors.primary : context.colors.textSecondary,
                              fontWeight: hasUnread ? FontWeight.w700 : FontWeight.normal,
                            )),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (conversation.lastMessageStatus != null) _buildTickIcon(context, conversation.lastMessageStatus!),
                      Expanded(
                        child: Text(
                          conversation.lastMessage.isEmpty ? 'Say hello 👋' : conversation.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: hasUnread ? context.colors.textPrimary : context.colors.textSecondary,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: context.colors.primary, borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            conversation.unreadCount > 99 ? '99+' : '${conversation.unreadCount}',
                            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTickIcon(BuildContext context, String status) {
    IconData icon = Icons.done;
    Color color = context.colors.textSecondary;
    if (status == 'delivered') icon = Icons.done_all;
    if (status == 'seen') {
      icon = Icons.done_all;
      color = context.colors.primary;
    }
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Icon(icon, size: 14, color: color),
    );
  }

  String _initials(String name) => AppHelpers.getInitials(name);

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    if (target == today) return AppHelpers.formatTime(dt);
    if (today.difference(target).inDays == 1) return 'Yesterday';
    if (today.difference(target).inDays < 7) return DateFormat('EEEE').format(dt);
    return AppHelpers.formatDate(dt);
  }
}