// lib/features/chat/presentation/widgets/chat_input_bar.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import 'voice_recorder_button.dart';
import '../../../../core/theme/theme_context_ext.dart';

class ChatInputBar extends StatefulWidget {
  final void Function(String text) onSendText;
  final void Function(File image, {String? caption}) onSendImage;
  final void Function(File audio, int durationSeconds) onSendVoice; // ✅ NEW
  final void Function(String text) onChanged;
  final String initialText; // ✅ NEW — pre-fills from a saved draft

  const ChatInputBar({
    super.key,
    required this.onSendText,
    required this.onSendImage,
    required this.onSendVoice,
    required this.onChanged,
    this.initialText = '',
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  late final _controller = TextEditingController(text: widget.initialText);
  final _focusNode = FocusNode();
  final _picker = ImagePicker();
  bool _hasText = false;
  bool _showEmojiPicker = false; // ✅ NEW

  @override
  void initState() {
    super.initState();
    _hasText = widget.initialText.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSendText(text);
    _controller.clear();
    setState(() => _hasText = false);
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final caption = _controller.text.trim();
    widget.onSendImage(File(picked.path), caption: caption.isEmpty ? null : caption);
    _controller.clear();
    setState(() => _hasText = false);
  }

  // ✅ NEW — emoji picker toggle. Closes the keyboard first so the panel
  // takes over the same screen real-estate rather than stacking on top.
  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      setState(() => _showEmojiPicker = false);
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
      setState(() => _showEmojiPicker = true);
    }
  }

  void _onEmojiSelected(Emoji emoji) {
    _controller.text += emoji.emoji;
    _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
    widget.onChanged(_controller.text);
    if (!_hasText) setState(() => _hasText = true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.only(left: 8, right: 12, top: 8, bottom: MediaQuery.of(context).padding.bottom + 8),
          decoration: BoxDecoration(
            color: context.colors.surface,
            border: Border(top: BorderSide(color: context.colors.divider)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ✅ NEW — emoji toggle
              IconButton(
                icon: Icon(_showEmojiPicker ? Icons.keyboard_alt_outlined : Icons.emoji_emotions_outlined,
                    color: context.colors.textSecondary),
                onPressed: _toggleEmojiPicker,
                tooltip: 'Emoji',
              ),
              IconButton(
                icon: Icon(Icons.image_outlined, color: context.colors.textSecondary),
                onPressed: _pickImage,
                tooltip: 'Send a photo',
              ),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 42),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: context.colors.background,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(fontSize: 14.5, color: context.colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Message',
                      hintStyle: TextStyle(fontSize: 14.5, color: context.colors.textSecondary),
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                    onTap: () {
                      if (_showEmojiPicker) setState(() => _showEmojiPicker = false);
                    },
                    onChanged: (text) {
                      widget.onChanged(text);
                      final hasText = text.trim().isNotEmpty;
                      if (hasText != _hasText) setState(() => _hasText = hasText);
                    },
                    onSubmitted: (_) => _send(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // ✅ CHANGED — mic when empty (WhatsApp-style), send when there's text
              _hasText
                  ? GestureDetector(
                      onTap: _send,
                      child: Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(color: context.colors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                      ),
                    )
                  : VoiceRecorderButton(onRecorded: widget.onSendVoice),
            ],
          ),
        ),
        // ✅ NEW — collapsible emoji panel
        if (_showEmojiPicker)
          SizedBox(
            height: 250,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) => _onEmojiSelected(emoji),
              config: const Config(
                emojiViewConfig: EmojiViewConfig(columns: 8, emojiSizeMax: 26),
              ),
            ),
          ),
      ],
    );
  }
}