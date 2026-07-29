// lib/features/home/screens/guest_main_screen.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import 'guest_home_screen.dart';
import '../../search/screens/search_screen.dart';
import '../../magazine/screens/magazine_screen.dart';
import '../../auth/screens/register_screen.dart';
import '../../profile/screens/guest_profile_screen.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../l10n/generated/app_localizations.dart';

class GuestMainScreen extends StatefulWidget {
  const GuestMainScreen({super.key});

  static void switchTab(int index) {
    GuestMainScreenState._current?.switchToTab(index);
  }

  @override
  State<GuestMainScreen> createState() => GuestMainScreenState();
}

class GuestMainScreenState extends State<GuestMainScreen> {
  static GuestMainScreenState? _current;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _current = this;
  }

  @override
  void dispose() {
    if (_current == this) _current = null;
    super.dispose();
  }

  void switchToTab(int index) {
    if (index >= 0 && index < 5) setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = ResponsiveUtils.scaleForWidth(width);
    // Tighter clamp than the standard scale: this bar always holds 5 items
    // including the longest label ("Become Pro"), so growth on tablets is
    // capped harder than most widgets to avoid icons/labels ballooning
    // past what a fixed-width nav item can comfortably hold, while small
    // phones still get a legible floor.
    final iconSize  = ResponsiveUtils.sp(24, scale, min: 22, max: 30);
    final labelSize = ResponsiveUtils.sp(11, scale, min: 10, max: 13);
    final navHeight  = ResponsiveUtils.sp(60, scale, min: 56, max: 74);

    final t = AppLocalizations.of(context)!;

    // ✅ FIX: this screen sits alone at the bottom of the Navigator stack
    // (tabs switch via IndexedStack, not real routes) — pressing back here
    // used to try popping past the root, which on web leaves an empty
    // Navigator (blank white screen) and on mobile could leave the app in
    // a stuck/loading state. PopScope(canPop: false) blocks that pop
    // attempt entirely while this is the root screen.
    return PopScope(
      canPop: false,
      child: Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          GuestHomeScreen(isVisible: _currentIndex == 0),
          // ✅ FIX: SearchScreen sits here as a bottom-nav TAB (IndexedStack),
          // not a pushed route — this screen is also wrapped in
          // PopScope(canPop: false), so SearchScreen's back arrow found
          // `Navigator.canPop(context) == false` and fell through to
          // `onBackWhenEmbedded?.call()`, which was null and did nothing.
          // Passing this callback makes the back arrow switch to the Home
          // tab instead of being a dead button.
          SearchScreen(
            isLoggedIn: false,
            userRole: 'guest',
            onBackWhenEmbedded: () => switchToTab(0),
          ),
          const MagazineScreen(),
          const RegisterScreen(initialRole: 'professional'),
          const GuestProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(top: BorderSide(color: context.colors.divider, width: 1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: navHeight,
            child: BottomNavigationBar(
              currentIndex:         _currentIndex,
              elevation:            0,
              backgroundColor:      Colors.transparent,
              selectedItemColor:    context.colors.primary,
              unselectedItemColor:  context.colors.textSecondary,
              selectedFontSize:     labelSize,
              unselectedFontSize:   labelSize,
              iconSize:             iconSize,
              selectedLabelStyle:   TextStyle(fontWeight: FontWeight.w600, fontSize: labelSize),
              unselectedLabelStyle: TextStyle(fontSize: labelSize),
              type: BottomNavigationBarType.fixed,
              onTap: (i) => setState(() => _currentIndex = i),
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home_rounded), label: t.home,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.search_outlined), activeIcon: const Icon(Icons.search_rounded), label: t.navSearch,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.menu_book_outlined), activeIcon: const Icon(Icons.menu_book_rounded), label: t.homeMagazineNavLabel,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.workspace_premium_outlined), activeIcon: const Icon(Icons.workspace_premium_rounded), label: t.homeBecomePro,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline_rounded), activeIcon: const Icon(Icons.person_rounded), label: t.profile,
                ),
              ],
            ),
          ),
        ),
      ),
    ), // Scaffold
    );
  }
}