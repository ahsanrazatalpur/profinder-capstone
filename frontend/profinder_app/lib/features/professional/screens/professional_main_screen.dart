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
    // ✅ FIX: same root-pop issue as guest_main_screen.dart — see that
    // file for full explanation.
    return PopScope(
      canPop: false,
      child: Scaffold(
      body: IndexedStack(
        index:    _currentIndex,
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
          border: Border(top: BorderSide(color: context.colors.divider, width: 1)),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset:     const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex:         _currentIndex,
          elevation:            0,
          backgroundColor:      Colors.transparent,
          selectedItemColor:    AppColors.professionalColor,
          unselectedItemColor:  context.colors.textSecondary,
          selectedLabelStyle:   const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed, 
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon:       Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label:      'Dashboard',
            ),
            BottomNavigationBarItem(
              icon:       Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today_rounded),
              label:      'Bookings',
            ),
            BottomNavigationBarItem(
              icon:       UnreadNavBadge(icon: const Icon(Icons.chat_bubble_outline_rounded)),
              activeIcon: UnreadNavBadge(icon: const Icon(Icons.chat_bubble_rounded)),
              label:      'Messages',
            ),
            BottomNavigationBarItem(
              icon:       Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book_rounded),
              label:      'Magazine',
            ),
            BottomNavigationBarItem(
              icon:       Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label:      'Analytics',
            ),
            BottomNavigationBarItem(
              icon:       Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label:      'Profile',
            ),
          ],
        ),
      ),
    ), // Scaffold
    );
  }
}