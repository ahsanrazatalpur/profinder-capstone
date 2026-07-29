// lib/features/professional/screens/professional_chat_screen.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_context_ext.dart';

class ProfessionalChatScreen extends StatefulWidget {
  final int conversationId;
  final String otherUserName;
  final String? otherUserPhoto;

  const ProfessionalChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    this.otherUserPhoto,
  });

  @override
  State<ProfessionalChatScreen> createState() => _ProfessionalChatScreenState();
}

class _ProfessionalChatScreenState extends State<ProfessionalChatScreen> {
  final _api = ApiService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _loadMyId();
    _load();
  }

  Future<void> _loadMyId() async {
    try {
      final res = await _api.get(AppConstants.me);
      if (!mounted) return;
      setState(() => _myUserId = (res.data as Map<String, dynamic>)['id']?.toString());
    } catch (_) {
      // ignore — bubbles will just all render as "their" messages until this resolves
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get(AppConstants.conversationMessages(widget.conversationId));
      // ✅ Backend now returns {results, has_more} instead of a bare list
      // (see backend_patch/apps/messaging/views.py) so the new chat feature
      // can paginate. This simple screen just takes the first page.
      final data = res.data;
      final list = data is Map<String, dynamic> && data['results'] is List
          ? data['results'] as List
          : (data is List ? data : []);
      if (!mounted) return;
      setState(() { _messages = list; _isLoading = false; });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _textController.clear();
    try {
      final res = await _api.post(AppConstants.conversationMessages(widget.conversationId), {'text': text});
      if (!mounted) return;
      setState(() {
        _messages.add(res.data);
        _isSending = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      AppHelpers.showError(context, 'Could not send message');
      _textController.text = text; // restore so they don't lose it
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: context.colors.primaryLight,
              backgroundImage: (widget.otherUserPhoto != null && widget.otherUserPhoto!.isNotEmpty)
                  ? NetworkImage(widget.otherUserPhoto!) : null,
              child: (widget.otherUserPhoto == null || widget.otherUserPhoto!.isEmpty)
                  ? Text(AppHelpers.getInitials(widget.otherUserName), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.colors.primary))
                  : null,
            ),
            const SizedBox(width: 10),
            Text(widget.otherUserName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text('Say hello 👋', style: TextStyle(fontSize: 14, color: context.colors.textSecondary)))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(14),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _buildBubble(_messages[i]),
                      ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildBubble(dynamic msg) {
    final isMe = msg['sender']?.toString() == _myUserId;
    final text = msg['text']?.toString() ?? '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? AppColors.professionalColor : context.colors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMe ? 14 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 14),
          ),
          border: isMe ? null : Border.all(color: context.colors.divider),
        ),
        child: Text(text, style: TextStyle(fontSize: 13.5, color: isMe ? Colors.white : context.colors.textPrimary)),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(left: 12, right: 12, top: 10, bottom: MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              minLines: 1,
              maxLines: 4,
              style: TextStyle(fontSize: 14, color: context.colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(fontSize: 13, color: context.colors.textSecondary),
                filled: true,
                fillColor: context.colors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: context.colors.divider)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: context.colors.divider)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: AppColors.professionalColor, width: 1.5)),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(color: AppColors.professionalColor, shape: BoxShape.circle),
              child: _isSending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}