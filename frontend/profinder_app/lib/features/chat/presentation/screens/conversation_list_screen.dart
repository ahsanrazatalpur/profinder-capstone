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
import '../../../../l10n/generated/app_localizations.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width > 600;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.messagesTitle,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: isTablet ? 18.0 : 16.0,
            letterSpacing: -0.3,
          ),
        ),
        iconTheme: IconThemeData(color: context.colors.textPrimary),
      ),
      body: Consumer<ConversationListProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: AppColors.customerColor,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.messagesLoadingText,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            );
          }
          if (provider.error != null && provider.conversations.isEmpty) {
            return _buildError(provider, isDark);
          }
          if (provider.conversations.isEmpty) {
            return _buildEmpty(isDark, isTablet);
          }
          return RefreshIndicator(
            onRefresh: provider.refresh,
            color: AppColors.customerColor,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(vertical: isTablet ? 8 : 4),
              itemCount: provider.conversations.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 80,
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : context.colors.divider,
              ),
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

  Widget _buildEmpty(bool isDark, bool isTablet) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isTablet ? 100 : 88,
              height: isTablet ? 100 : 88,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: isTablet ? 44 : 40,
                color: isDark
                    ? Colors.white.withOpacity(0.3)
                    : const Color(0xFFD1D5DB),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              AppLocalizations.of(context)!.messagesEmptyTitle,
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.messagesEmptySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 14 : 13,
                color: context.colors.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ConversationListProvider provider, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.colors.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: provider.load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                AppLocalizations.of(context)!.retryCta,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.customerColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}