// PATH: lib/features/chat/presentation/screens/conversation_list_entry.dart
//
// ✅ NEW — Thin wrapper so both the Customer and Professional "Messages"
// tab can share one implementation instead of each fetching their own
// user id inline. Resolves `/users/me/` once, then renders the real
// ConversationListScreen.

import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_context_ext.dart';
import '../../../../services/api_service.dart';
import 'conversation_list_screen.dart';
import '../../../../l10n/generated/app_localizations.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_failed) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: Center(
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
                  AppLocalizations.of(context)!.messagesLoadError,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.colors.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _load,
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
        ),
      );
    }
    if (_currentUserId == null) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: Center(
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
        ),
      );
    }
    return ConversationListScreen(currentUserId: _currentUserId!, isVisible: widget.isVisible);
  }
}