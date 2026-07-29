// lib/features/chat/presentation/widgets/reply_preview_bar.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/message_entity.dart';
import '../../../../core/theme/theme_context_ext.dart';

class ReplyPreviewBar extends StatelessWidget {
  final MessageEntity replyingTo;
  final VoidCallback onCancel;

  const ReplyPreviewBar({super.key, required this.replyingTo, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final preview = replyingTo.isDeleted
        ? 'This message was deleted'
        : (replyingTo.text.isNotEmpty ? replyingTo.text : (replyingTo.hasImage ? '📷 Photo' : ''));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 34, color: context.colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(replyingTo.senderName,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.colors.primary)),
                Text(preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
            onPressed: onCancel,
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}