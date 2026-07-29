// lib/features/professional/screens/professional_messages_screen.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import 'professional_chat_screen.dart';
import '../../../core/theme/theme_context_ext.dart';

class ProfessionalMessagesScreen extends StatefulWidget {
  const ProfessionalMessagesScreen({super.key});

  @override
  State<ProfessionalMessagesScreen> createState() => _ProfessionalMessagesScreenState();
}

class _ProfessionalMessagesScreenState extends State<ProfessionalMessagesScreen> {
  final _api = ApiService();
  List<dynamic> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get(AppConstants.conversations);
      final list = res.data is List ? res.data as List : [];
      if (!mounted) return;
      setState(() { _conversations = list; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        title: Text('Messages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.professionalColor,
              child: _conversations.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded, size: 64, color: context.colors.textDisabled),
                              const SizedBox(height: 12),
                              Text('No messages yet', style: TextStyle(fontSize: 15, color: context.colors.textSecondary)),
                              const SizedBox(height: 6),
                              Text('Customer conversations will show up here', style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      itemCount: _conversations.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
                      itemBuilder: (_, i) => _buildConversationTile(_conversations[i]),
                    ),
            ),
    );
  }

  Widget _buildConversationTile(dynamic conv) {
    final name         = conv['other_user_name']?.toString() ?? 'Customer';
    final photo        = conv['other_user_photo']?.toString();
    final lastMessage  = conv['last_message']?.toString() ?? '';
    final unreadCount  = (conv['unread_count'] ?? 0) as int;
    final timeStr      = _timeAgo(conv['last_message_at']?.toString());

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: context.colors.primaryLight,
        backgroundImage: (photo != null && photo.isNotEmpty) ? NetworkImage(photo) : null,
        child: (photo == null || photo.isEmpty)
            ? Text(AppHelpers.getInitials(name), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.colors.primary))
            : null,
      ),
      title: Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
      subtitle: Text(
        lastMessage.isEmpty ? 'Say hello 👋' : lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12.5, color: unreadCount > 0 ? context.colors.textPrimary : context.colors.textSecondary,
            fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal),
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(timeStr, style: TextStyle(fontSize: 10.5, color: context.colors.textSecondary)),
          const SizedBox(height: 6),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: AppColors.professionalColor, borderRadius: BorderRadius.circular(10)),
              child: Text('$unreadCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
        ],
      ),
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(
            builder: (_) => ProfessionalChatScreen(
                conversationId: conv['id'], otherUserName: name, otherUserPhoto: photo)));
        _load(); // refresh unread counts after returning
      },
    );
  }
}