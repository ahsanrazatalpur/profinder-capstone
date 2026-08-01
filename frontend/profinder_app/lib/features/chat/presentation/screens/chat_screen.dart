// lib/features/chat/presentation/screens/chat_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_helpers.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../providers/chat_provider.dart';
import '../providers/conversation_list_provider.dart';   // ✅ NEW — for mute toggle
import '../widgets/chat_input_bar.dart';
import '../widgets/date_separator.dart';
import '../widgets/message_bubble.dart';
import '../widgets/online_status_dot.dart';
import '../widgets/reply_preview_bar.dart';
import '../widgets/typing_indicator.dart';
import 'media_gallery_screen.dart';       // ✅ NEW
import '../widgets/report_user_dialog.dart'; // ✅ NEW
import '../widgets/message_search_sheet.dart'; // ✅ NEW
import '../../../../core/theme/theme_context_ext.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Sealed-ish helper: one entry in the rendered list is either a message
/// bubble or a date separator. Keeping both in one flat list lets us use a
/// single ListView.builder instead of nesting slivers.
abstract class _ChatListItem {}

class _MessageItem extends _ChatListItem {
  final MessageEntity message;
  _MessageItem(this.message);
}

class _SeparatorItem extends _ChatListItem {
  final DateTime date;
  _SeparatorItem(this.date);
}

class ChatScreen extends StatelessWidget {
  final int conversationId;
  final int currentUserId;
  final String otherUserName;
  final String? otherUserPhoto;
  final ConversationEntity conversationSnapshot;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.currentUserId,
    required this.otherUserName,
    required this.otherUserPhoto,
    required this.conversationSnapshot,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(
        conversationId: conversationId,
        currentUserId: currentUserId,
        initialSnapshot: conversationSnapshot,
      )..init(),
      child: _ChatScreenBody(
        conversationId: conversationId,
        otherUserId: conversationSnapshot.otherUserId,
        otherUserName: otherUserName,
        otherUserPhoto: otherUserPhoto,
      ),
    );
  }
}

class _ChatScreenBody extends StatefulWidget {
  final int conversationId;
  final int otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;

  const _ChatScreenBody({
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserPhoto,
  });

  @override
  State<_ChatScreenBody> createState() => _ChatScreenBodyState();
}

class _ChatScreenBodyState extends State<_ChatScreenBody> with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    // ConversationListScreen already calls provider.refresh() after this
    // screen is popped (see its onTap), so the list picks up the latest
    // last-message/unread-count without any extra plumbing here.
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-confirm "seen" when the user brings the app back to foreground
    // while this chat screen is still the active route.
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<ChatProvider>().markSeen();
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    // Near the top -> load older history. Preserve the visual scroll
    // position by remembering the extent before prepending new items.
    if (_scrollController.position.pixels <= 80) {
      final provider = context.read<ChatProvider>();
      if (provider.hasMoreHistory && !provider.isLoadingMore) {
        final previousMaxExtent = _scrollController.position.maxScrollExtent;
        provider.loadMoreHistory().then((_) {
          if (!mounted || !_scrollController.hasClients) return;
          final newMaxExtent = _scrollController.position.maxScrollExtent;
          _scrollController.jumpTo(_scrollController.position.pixels + (newMaxExtent - previousMaxExtent));
        });
      }
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    return _scrollController.position.maxScrollExtent - _scrollController.position.pixels < 150;
  }

  List<_ChatListItem> _buildItems(List<MessageEntity> messages) {
    final items = <_ChatListItem>[];
    DateTime? lastDate;
    for (final m in messages) {
      if (lastDate == null || DateSeparator.isDifferentDay(lastDate, m.createdAt)) {
        items.add(_SeparatorItem(m.createdAt));
        lastDate = m.createdAt;
      }
      items.add(_MessageItem(m));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    // 🐛 FIX: PopupMenuButton opens its menu via `showMenu`, which inserts
    // the menu into the Navigator's Overlay — a route detached from this
    // screen's local widget subtree. A Consumer<ChatProvider> placed
    // inside a PopupMenuItem can't find the (locally-scoped) ChatProvider
    // from there and throws "Could not find the correct Provider". Fix:
    // read the values HERE, in the normal build(), where the provider
    // scope is valid — then use the captured plain values inside the menu.
    final chatProvider = context.watch<ChatProvider>();
    final listProvider = context.watch<ConversationListProvider>();
    ConversationEntity? currentConv;
    for (final c in listProvider.conversations) {
      if (c.id == widget.conversationId) { currentConv = c; break; }
    }
    final isMutedNow = currentConv?.isMuted == true;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        titleSpacing: 0,
        title: Consumer<ChatProvider>(
          builder: (context, provider, _) => Row(
            children: [
              AvatarWithStatus(
                isOnline: provider.otherUserOnline,
                size: 36,
                avatar: CircleAvatar(
                  radius: 18,
                  backgroundColor: context.colors.primaryLight,
                  backgroundImage: widget.otherUserPhoto != null ? CachedNetworkImageProvider(widget.otherUserPhoto!) : null,
                  child: widget.otherUserPhoto == null
                      ? Text(AppHelpers.getInitials(widget.otherUserName),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.colors.primary))
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.otherUserName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
                    Text(
                      _statusSubtitle(context, provider),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: provider.otherUserTyping ? context.colors.primary : context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded, color: context.colors.textSecondary),
            tooltip: AppLocalizations.of(context)!.chatSearchChat,
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => MessageSearchSheet(conversationId: widget.conversationId),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: context.colors.textSecondary),
            onSelected: (value) => _onMenuSelected(context, value),
            itemBuilder: (menuContext) => [
              PopupMenuItem(value: 'media', child: Text(AppLocalizations.of(menuContext)!.chatSharedMedia2)),
              PopupMenuItem(
                value: 'mute',
                child: Text(isMutedNow
                    ? AppLocalizations.of(menuContext)!.chatUnmuteConversation
                    : AppLocalizations.of(menuContext)!.chatMuteConversation),
              ),
              PopupMenuItem(
                value: 'block',
                child: Text(chatProvider.isBlockedByMe
                    ? AppLocalizations.of(menuContext)!.chatUnblockUser
                    : AppLocalizations.of(menuContext)!.chatBlockUser),
              ),
              PopupMenuItem(value: 'report', child: Text(AppLocalizations.of(menuContext)!.chatReportUser)),
            ],
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, _) {
          // Auto-scroll: only jump to the very bottom on first load, or
          // when a *new* message lands while the user is already near the
          // bottom (don't yank them down mid-scroll through old history).
          if (provider.messages.length != _lastMessageCount) {
            final grew = provider.messages.length > _lastMessageCount;
            final wasNearBottom = _isNearBottom();
            _lastMessageCount = provider.messages.length;
            if (grew && (wasNearBottom || _lastMessageCount == provider.messages.length)) {
              _scrollToBottom(animated: _lastMessageCount > 1);
            }
          }

          return Column(
            children: [
              Expanded(child: _buildMessageList(provider)),
              if (provider.otherUserTyping)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: Align(alignment: Alignment.centerLeft, child: TypingIndicatorBubble()),
                ),
              if (provider.replyingTo != null)
                ReplyPreviewBar(replyingTo: provider.replyingTo!, onCancel: provider.clearReply),
              if (!provider.canMessage)
                _buildBlockedBanner(context, provider)
              else
                ChatInputBar(
                  initialText: provider.initialDraftText,
                  onChanged: provider.onComposerChanged,
                  onSendText: (text) {
                    provider.stopTypingOnSend();
                    provider.sendText(text);
                  },
                  onSendImage: (file, {caption}) {
                    provider.stopTypingOnSend();
                    provider.sendImage(file, caption: caption);
                  },
                  onSendVoice: (file, duration) {
                    provider.stopTypingOnSend();
                    provider.sendVoice(file, duration);
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  void _onMenuSelected(BuildContext context, String value) {
    switch (value) {
      case 'media':
        Navigator.push(context, MaterialPageRoute(builder: (_) => MediaGalleryScreen(conversationId: widget.conversationId)));
        break;
      case 'mute':
        final listProvider = context.read<ConversationListProvider>();
        ConversationEntity? conv;
        for (final c in listProvider.conversations) {
          if (c.id == widget.conversationId) { conv = c; break; }
        }
        if (conv != null) {
          final willBeMuted = !conv.isMuted;
          listProvider.toggleMute(conv);
          final t = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(willBeMuted ? t.chatConversationMuted : t.chatConversationUnmuted),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        break;
      case 'block':
        if (context.read<ChatProvider>().isBlockedByMe) {
          context.read<ChatProvider>().unblockOtherUser();
        } else {
          _confirmBlock(context);
        }
        break;
      case 'report':
        showDialog(context: context, builder: (_) => ReportUserDialog(userId: widget.otherUserId, userName: widget.otherUserName));
        break;
    }
  }

  void _confirmBlock(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.chatBlock(widget.otherUserName)),
        content: Text(t.chatTheyNoLongerAbleSendMessages),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // Stay in the chat — the blocked banner + disabled input
              // below now reflect the new state immediately (Instagram-style),
              // rather than kicking the user out of the conversation.
              await context.read<ChatProvider>().blockOtherUser();
            },
            child: Text(t.adminBlock, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // ✅ NEW — replaces the input bar whenever `canMessage` is false.
  // Two distinct views:
  //  - I blocked them: explicit "You blocked X" + an Unblock action
  //    (safe to show — it's my own action, Instagram shows this too).
  //  - They blocked me (or role/account issue): a generic "message
  //    unavailable" notice that never confirms who blocked whom.
  Widget _buildBlockedBanner(BuildContext context, ChatProvider provider) {
    final t = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.divider)),
      ),
      child: provider.isBlockedByMe
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t.chatYouBlockedUser(widget.otherUserName),
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.chatBlockedBannerSubtitle,
                        style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () => context.read<ChatProvider>().unblockOtherUser(),
                  child: Text(t.chatUnblockAction),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block_rounded, size: 16, color: context.colors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  t.chatMessageUnavailable,
                  style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
                ),
              ],
            ),
    );
  }

  String _statusSubtitle(BuildContext context, ChatProvider provider) {
    final t = AppLocalizations.of(context)!;
    if (provider.otherUserTyping) return t.chatTyping;
    if (provider.otherUserOnline) return t.searchOnline;
    if (provider.otherUserLastSeen != null) {
      return t.chatLastSeen(AppHelpers.formatTime(provider.otherUserLastSeen!));
    }
    return '';
  }

  Widget _buildMessageList(ChatProvider provider) {
    final t = AppLocalizations.of(context)!;
    if (provider.isLoadingInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.loadError != null && provider.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(provider.loadError!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 8),
            TextButton(onPressed: provider.loadInitialMessages, child: Text(t.retry)),
          ],
        ),
      );
    }
    if (provider.messages.isEmpty) {
      return Center(child: Text(t.chatSayHello, style: TextStyle(fontSize: 14, color: context.colors.textSecondary)));
    }

    final items = _buildItems(provider.messages);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: items.length + (provider.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (provider.isLoadingMore && index == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        final item = items[index - (provider.isLoadingMore ? 1 : 0)];
        if (item is _SeparatorItem) return DateSeparator(date: item.date);

        final message = (item as _MessageItem).message;
        final isMe = message.senderId == provider.currentUserId;
        return MessageBubble(
          message: message,
          isMe: isMe,
          onReply: () => provider.setReplyTo(message),
          onEdit: (newText) => provider.editMessage(message.id, newText),
          onDelete: () => provider.deleteMessage(message.id, forEveryone: true),
          onDeleteForMe: () => provider.deleteMessage(message.id, forEveryone: false),
          onReact: (emoji) => provider.toggleReaction(message.id, emoji),
          onRetry: () => provider.retry(message),
        );
      },
    );
  }
}