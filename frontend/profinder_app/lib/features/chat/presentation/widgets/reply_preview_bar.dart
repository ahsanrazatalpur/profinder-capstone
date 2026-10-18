// lib/features/chat/presentation/widgets/reply_preview_bar.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/message_entity.dart';
import '../../../../core/theme/theme_context_ext.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/generated/app_localizations.dart';

class ReplyPreviewBar extends StatelessWidget {
  final MessageEntity replyingTo;
  final VoidCallback onCancel;

  const ReplyPreviewBar({
    super.key,
    required this.replyingTo,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final preview = replyingTo.isDeleted
        ? AppLocalizations.of(context).chatMessageWasDeleted
        : (replyingTo.text.isNotEmpty
              ? replyingTo.text
              : (replyingTo.hasImage
                    ? AppLocalizations.of(context).chatPhotoPreview
                    : ''));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? context.colors.background
            : AppColors.slate100,
        border: Border(bottom: BorderSide(color: context.colors.divider)),
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
                Text(
                  replyingTo.senderName,
                  style: TextStyle(
                    fontSize: AppFontSizes.secondary,
                    fontWeight: FontWeight.w700,
                    color: context.colors.primary,
                  ),
                ),
                Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppFontSizes.secondary,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              size: 18,
              color: context.colors.textSecondary,
            ),
            onPressed: onCancel,
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}
