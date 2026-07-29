// PATH: lib/features/chat/presentation/screens/conversation_list_entry.dart
//
// ✅ NEW — Thin wrapper so both the Customer and Professional "Messages"
// tab can share one implementation instead of each fetching their own
// user id inline. Resolves `/users/me/` once, then renders the real
// ConversationListScreen.

import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../services/api_service.dart';
import 'conversation_list_screen.dart';

class ConversationListEntry extends StatefulWidget {
  final bool isVisible;
  const ConversationListEntry({super.key, this.isVisible = true});

  @override
  State<ConversationListEntry> createState() => _ConversationListEntryState();
}

class _ConversationListEntryState extends State<ConversationListEntry> {
  int? _currentUserId;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final res = await ApiService().get(AppConstants.me);
      final id = int.tryParse((res.data as Map<String, dynamic>)['id'].toString());
      if (!mounted) return;
      setState(() => _currentUserId = id);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load messages'),
              const SizedBox(height: 8),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_currentUserId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return ConversationListScreen(currentUserId: _currentUserId!, isVisible: widget.isVisible);
  }
}