// PATH: lib/features/chat/presentation/screens/conversation_list_screen.dart
// lib/features/chat/presentation/screens/conversation_list_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_context_ext.dart';
import '../providers/conversation_list_provider.dart';
import '../widgets/conversation_tile.dart';
import 'chat_screen.dart';

class ConversationListScreen extends StatefulWidget {
  final int currentUserId;

  /// ✅ NEW — pass `_currentIndex == messagesTabIndex` when this screen
  /// lives inside an IndexedStack (Professional's bottom nav) so it knows
  /// when it's the ACTIVE tab vs just sitting alive in the background.
  /// Screens pushed via Navigator (Customer side) can leave this `true` —
  /// they're naturally only "visible" while on top of the stack anyway.
  final bool isVisible;

  const ConversationListScreen({super.key, required this.currentUserId, this.isVisible = true});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConversationListProvider>().load();
    });
    if (widget.isVisible) _startPolling();
  }

  @override
  void didUpdateWidget(covariant ConversationListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isVisible && widget.isVisible) {
      // 🐛 FIX: `refresh()` calls `notifyListeners()` synchronously (before
      // any await), and didUpdateWidget runs DURING the framework's build
      // phase (this screen sits inside an IndexedStack whose parent is
      // rebuilding). Calling it directly triggers "setState() or
      // markNeedsBuild() called during build". Deferring with
      // addPostFrameCallback runs it right after the current frame
      // finishes, which is still effectively instant to the user.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<ConversationListProvider>().refresh();
      });
      _startPolling();
    } else if (oldWidget.isVisible && !widget.isVisible) {
      _stopPolling();
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  // ✅ NEW — lightweight fallback so the list (order + unread counts)
  // stays roughly live even while the user is just browsing it rather
  // than inside a specific chat (which has its own WebSocket room).
  // 15s is a deliberate compromise: frequent enough to feel "live" for a
  // list screen, cheap enough to not worry about battery/data.
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) context.read<ConversationListProvider>().refresh();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        title: Text('Messages', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: context.colors.textPrimary),
      ),
      body: Consumer<ConversationListProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.conversations.isEmpty) {
            return _buildError(provider);
          }
          if (provider.conversations.isEmpty) {
            return _buildEmpty();
          }
          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView.separated(
              itemCount: provider.conversations.length,
              separatorBuilder: (_, __) => Divider(height: 1, indent: 80, color: context.colors.divider),
              itemBuilder: (context, index) {
                final conv = provider.conversations[index];
                return ConversationTile(
                  conversation: conv,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        conversationId: conv.id,
                        currentUserId: widget.currentUserId,
                        otherUserName: conv.otherUserName,
                        otherUserPhoto: conv.otherUserPhoto,
                        conversationSnapshot: conv,
                      ),
                    ));
                    if (context.mounted) provider.refresh();
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Builder(builder: (context) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 56, color: context.colors.textDisabled),
            const SizedBox(height: 12),
            Text('No conversations yet', style: TextStyle(fontSize: 14.5, color: context.colors.textSecondary)),
          ],
        ),
      );
    });
  }

  Widget _buildError(ConversationListProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(provider.error!, style: const TextStyle(color: AppColors.error)),
          const SizedBox(height: 12),
          TextButton(onPressed: provider.load, child: const Text('Retry')),
        ],
      ),
    );
  }
}