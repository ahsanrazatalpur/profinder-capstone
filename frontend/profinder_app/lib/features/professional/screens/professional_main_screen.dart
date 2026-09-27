// PATH: lib/features/professional/screens/professional_main_screen.dart
// lib/features/professional/screens/professional_main_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../magazine/screens/magazine_screen.dart'; 
import '../../chat/presentation/screens/conversation_list_entry.dart';   // ✅ FIX: shared entry (was ad-hoc user-id fetch)
import '../../chat/presentation/providers/conversation_list_provider.dart';
import '../../chat/presentation/widgets/unread_nav_badge.dart';          // ✅ NEW — unread badge on nav icon
import 'professional_home_screen.dart';
import 'professional_bookings_screen.dart';
import 'professional_analytics_screen.dart';
import 'professional_profile_screen.dart';
import '../../../l10n/generated/app_localizations.dart';

class ProfessionalMainScreen extends StatefulWidget {
  const ProfessionalMainScreen({super.key});
  static void switchTab(int index) {
    ProfessionalMainScreenState._current?.switchToTab(index);
  }

  @override
  State<ProfessionalMainScreen> createState() => ProfessionalMainScreenState();
}

class ProfessionalMainScreenState extends State<ProfessionalMainScreen> {
  static ProfessionalMainScreenState? _current;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _current = this;
    // ✅ NEW — load the conversation list once at app start (not just when
    // the Messages tab is opened) so the unread badge is accurate from
    // the very first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConversationListProvider>().load();
    });
  }

  @override
  void dispose() {
    if (_current == this) _current = null;
    super.dispose();
  }

  void switchToTab(int index) {
    if (index >= 0 && index < 6) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width > 600;

    // ✅ FIX: same root-pop issue as guest_main_screen.dart — see that
    // file for full explanation.
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            ProfessionalHomeScreen(isVisible: _currentIndex == 0),
            ProfessionalBookingsScreen(isVisible: _currentIndex == 1),
            // ✅ FIX: was `const ProfessionalMessagesScreen()` — the old
            // simple REST-polling chat. Now uses the premium WebSocket-based
            // chat feature (typing, ticks, images, reply, pagination).
            ConversationListEntry(isVisible: _currentIndex == 2),
            const MagazineScreen(),        
            const ProfessionalAnalyticsScreen(),
            ProfessionalProfileScreen(),  
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey.withOpacity(0.15),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              elevation: 0,
              backgroundColor: Colors.transparent,
              selectedItemColor: AppColors.professionalColor,
              unselectedItemColor: context.colors.textSecondary,
              selectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: isTablet ? 12.0 : 10.5,
                letterSpacing: 0.2,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: isTablet ? 12.0 : 10.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
              type: BottomNavigationBarType.fixed,
              showUnselectedLabels: true,
              onTap: (i) => setState(() => _currentIndex = i),
              items: [
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.dashboard_outlined,
                    size: isTablet ? 26.0 : 24.0,
                  ),
                  activeIcon: Icon(
                    Icons.dashboard_rounded,
                    size: isTablet ? 26.0 : 24.0,
                  ),
                  label: AppLocalizations.of(context)!.navDashboard,
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.calendar_today_outlined,
                    size: isTablet ? 26.0 : 24.0,
                  ),
                  activeIcon: Icon(
                    Icons.calendar_today_rounded,
                    size: isTablet ? 26.0 : 24.0,
                  ),
                  label: AppLocalizations.of(context)!.navBookings,
                ),
                BottomNavigationBarItem(
                  icon: UnreadNavBadge(
                    icon: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: isTablet ? 26.0 : 24.0,
                    ),
                  ),
                  activeIcon: UnreadNavBadge(
                    icon: Icon(
                      Icons.chat_bubble_rounded,
                      size: isTablet ? 26.0 : 24.0,
                    ),
                  ),
                  label: AppLocalizations.of(context)!.navMessages,
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.menu_book_outlined,
                    size: isTablet ? 26.0 : 24.0,
                  ),
                  activeIcon: Icon(
                    Icons.menu_book_rounded,
                    size: isTablet ? 26.0 : 24.0,
                  ),
                  label: AppLocalizations.of(context)!.navMagazine,
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.bar_chart_outlined,
                    size: isTablet ? 26.0 : 24.0,
                  ),
                  activeIcon: Icon(
                    Icons.bar_chart_rounded,
                    size: isTablet ? 26.0 : 24.0,
                  ),
                  label: AppLocalizations.of(context)!.navAnalytics,
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.person_outline_rounded,
                    size: isTablet ? 26.0 : 24.0,
                  ),
                  activeIcon: Icon(
                    Icons.person_rounded,
                    size: isTablet ? 26.0 : 24.0,
                  ),
                  label: AppLocalizations.of(context)!.navProfile,
                ),
              ],
            ),
          ),
        ),
      ), // Scaffold
    );
  }
}