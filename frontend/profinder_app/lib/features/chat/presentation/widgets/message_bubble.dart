// lib/features/chat/presentation/widgets/message_bubble.dart

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_helpers.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/message_status.dart';
import 'fullscreen_image_viewer.dart';
import 'local_image.dart';
import '../../../../core/theme/theme_context_ext.dart';
import '../../../../l10n/generated/app_localizations.dart';

// ✅ NEW — the 6 quick-pick reactions, WhatsApp-style
const _quickReactions = ['❤️', '👍', '😂', '😮', '😢', '🙏'];

class MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;
  final VoidCallback onReply;
  final void Function(String newText) onEdit;
  final VoidCallback onDelete;         // delete for everyone (sender only)
  final VoidCallback onDeleteForMe;    // ✅ NEW — hide for me only (anyone)
  final void Function(String emoji) onReact; // ✅ NEW
  final VoidCallback onRetry;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
    required this.onDeleteForMe,
    required this.onReact,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) return _buildDeletedBubble(context);

    return GestureDetector(
      onLongPress: () => _showActions(context),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
              decoration: BoxDecoration(
                color: isMe ? context.colors.primary : context.colors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe ? null : Border.all(color: context.colors.divider),
              ),
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.replyTo != null) _buildReplyQuote(context),
                  if (message.hasImage) _buildImage(context),
                  if (message.hasAudio) _buildAudio(),   // ✅ NEW
                  if (message.text.isNotEmpty || (!message.hasImage && !message.hasAudio)) _buildTextRow(context),
                ],
              ),
            ),
            if (message.hasReactions) _buildReactionsRow(context),  // ✅ NEW
          ],
        ),
      ),
    );
  }

  // ✅ NEW — reactions pill row, tap to open the quick-picker again
  Widget _buildReactionsRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, left: 6, right: 6),
      child: Wrap(
        spacing: 4,
        children: message.reactions.entries.map((e) {
          final isMine = message.myReaction == e.key;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: isMine ? context.colors.primary.withOpacity(0.12) : context.colors.background,
              borderRadius: BorderRadius.circular(12),
              border: isMine ? Border.all(color: context.colors.primary, width: 1) : null,
            ),
            child: Text('${e.key} ${e.value}', style: const TextStyle(fontSize: 11.5)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDeletedBubble(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: context.colors.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, size: 15, color: context.colors.textSecondary),
            const SizedBox(width: 6),
            Text(AppLocalizations.of(context)!.chatMessageWasDeleted,
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: context.colors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyQuote(BuildContext context) {
    final r = message.replyTo!;
    final preview = r.text.isNotEmpty ? r.text : (r.hasAttachment ? AppLocalizations.of(context)!.chatPhotoReplyPlaceholder : '');
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.16) : context.colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: isMe ? Colors.white : context.colors.primary, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(r.senderName,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isMe ? Colors.white : context.colors.primary)),
          Text(preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: isMe ? Colors.white70 : context.colors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final heroTag = 'chat_image_${message.id}';
    return Padding(
      padding: const EdgeInsets.all(4),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          FullscreenImageViewer.route(heroTag: heroTag, imageUrl: AppHelpers.getFullImageUrl(message.imageUrl), localPath: message.localImagePath),
        ),
        child: Hero(
          tag: heroTag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: message.localImagePath != null
                ? LocalImagePreview(path: message.localImagePath!, width: 220, height: 220, fit: BoxFit.cover)
                : CachedNetworkImage(
                    imageUrl: AppHelpers.getFullImageUrl(message.imageUrl),
                    width: 220,
                    height: 220,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 220,
                      height: 220,
                      color: context.colors.background,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 220,
                      height: 220,
                      color: context.colors.background,
                      child: Icon(Icons.broken_image, color: context.colors.textSecondary),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ✅ NEW — voice message player
  Widget _buildAudio() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 4),
      child: _VoiceMessagePlayer(
        url: message.audioUrl == null ? null : AppHelpers.getFullImageUrl(message.audioUrl),
        localPath: message.localAudioPath,
        durationSeconds: message.audioDurationSeconds ?? 0,
        isMe: isMe,
      ),
    );
  }

  Widget _buildTextRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 9, 10, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.text.isNotEmpty)
            Flexible(
              child: Text(
                message.text,
                style: TextStyle(fontSize: 14.5, color: isMe ? Colors.white : context.colors.textPrimary, height: 1.3),
              ),
            ),
          const SizedBox(width: 8),
          _buildMeta(context),
        ],
      ),
    );
  }

  Widget _buildMeta(BuildContext context) {
    final time = TimeOfDay.fromDateTime(message.createdAt).format24Hour();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.isEdited)
          Text('${AppLocalizations.of(context)!.chatEdited} ', style: TextStyle(fontSize: 10.5, color: isMe ? Colors.white60 : context.colors.textSecondary)),
        Text(time, style: TextStyle(fontSize: 10.5, color: isMe ? Colors.white70 : context.colors.textSecondary)),
        if (isMe) ...[
          const SizedBox(width: 3),
          _buildStatusIcon(),
        ],
      ],
    );
  }

  Widget _buildStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 11,
          height: 11,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white70),
        );
      case MessageStatus.failed:
        return GestureDetector(
          onTap: onRetry,
          child: const Icon(Icons.error_outline, size: 14, color: Colors.redAccent),
        );
      case MessageStatus.sent:
        return const Icon(Icons.done, size: 14, color: Colors.white70);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 14, color: Colors.white70);
      case MessageStatus.seen:
        return const Icon(Icons.done_all, size: 14, color: Color(0xFF60D1FF)); // WhatsApp-style blue double tick
    }
  }

  void _showActions(BuildContext context) {
    if (message.status == MessageStatus.sending) return; // nothing to do on an in-flight bubble

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ NEW — quick reaction row at the very top of the sheet
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _quickReactions.map((emoji) {
                    final isMine = message.myReaction == emoji;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(sheetContext);
                        onReact(emoji);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isMine ? context.colors.primary.withOpacity(0.12) : Colors.transparent,
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),
              Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.reply),
                    title: Text(AppLocalizations.of(context)!.chatReply),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onReply();
                    },
                  ),
                  if (isMe && message.text.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: Text(AppLocalizations.of(context)!.adminEdit),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _showEditDialog(context);
                      },
                    ),
                  // ✅ NEW — split delete options
                  ListTile(
                    leading: const Icon(Icons.person_remove_outlined),
                    title: Text(AppLocalizations.of(context)!.chatDeleteMe),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onDeleteForMe();
                    },
                  ),
                  if (isMe)
                    ListTile(
                      leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      title: Text(AppLocalizations.of(context)!.chatDeleteEveryone, style: const TextStyle(color: Colors.redAccent)),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        onDelete();
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: message.text);
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.chatEditMessage),
        content: TextField(controller: controller, maxLines: 4, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              final text = controller.text.trim();
              if (text.isNotEmpty) onEdit(text);
            },
            child: Text(t.save),
          ),
        ],
      ),
    );
  }
}

extension _TimeFormat on TimeOfDay {
  String format24Hour() {
    final h = hourOfPeriod == 0 ? 12 : hourOfPeriod;
    final m = minute.toString().padLeft(2, '0');
    final suffix = period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $suffix';
  }
}

// ✅ NEW — minimal play/pause voice-note player. Uses `audioplayers`
// (add to pubspec.yaml). No waveform — just a progress bar + duration,
// which covers "voice messages" without over-scoping the UI work.
class _VoiceMessagePlayer extends StatefulWidget {
  final String? url;
  final String? localPath;
  final int durationSeconds;
  final bool isMe;

  const _VoiceMessagePlayer({
    required this.url,
    required this.localPath,
    required this.durationSeconds,
    required this.isMe,
  });

  @override
  State<_VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<_VoiceMessagePlayer> {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;

  @override
  void initState() {
    super.initState();
    _total = Duration(seconds: widget.durationSeconds);
    _player.onPositionChanged.listen((p) => mounted ? setState(() => _position = p) : null);
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
      return;
    }
    if (widget.localPath != null) {
      await _player.play(DeviceFileSource(widget.localPath!));
    } else if (widget.url != null) {
      await _player.play(UrlSource(widget.url!));
    } else {
      return;
    }
    setState(() => _isPlaying = true);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(1, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isMe ? Colors.white : context.colors.primary;
    final total = _total.inMilliseconds == 0 ? const Duration(seconds: 1) : _total;
    final progress = (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);

    return SizedBox(
      width: 190,
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.15)),
              child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: color, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: color.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isPlaying ? _fmt(_position) : _fmt(_total),
                  style: TextStyle(fontSize: 10.5, color: widget.isMe ? Colors.white70 : context.colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}