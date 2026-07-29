// lib/features/chat/presentation/widgets/message_search_sheet.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_helpers.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/message_entity.dart';
import '../../../../core/theme/theme_context_ext.dart';

class MessageSearchSheet extends StatefulWidget {
  final int conversationId;
  const MessageSearchSheet({super.key, required this.conversationId});

  @override
  State<MessageSearchSheet> createState() => _MessageSearchSheetState();
}

class _MessageSearchSheetState extends State<MessageSearchSheet> {
  final _repo = ChatRepositoryImpl();
  final _controller = TextEditingController();
  Timer? _debounce;
  List<MessageEntity> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isSearching = true);
      try {
        final results = await _repo.searchMessages(widget.conversationId, query.trim());
        if (mounted) setState(() { _results = results; _isSearching = false; });
      } catch (_) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(14),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: 'Search messages...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            if (_isSearching) const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)),
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        _controller.text.isEmpty ? 'Type to search this conversation' : 'No messages found',
                        style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _results.length,
                      itemBuilder: (_, i) {
                        final m = _results[i];
                        return ListTile(
                          title: Text(m.senderName, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.colors.primary)),
                          subtitle: Text(m.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5)),
                          trailing: Text(AppHelpers.formatTime(m.createdAt), style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}