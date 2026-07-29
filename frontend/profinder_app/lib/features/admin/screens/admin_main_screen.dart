// lib/features/admin/screens/admin_main_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/auth_provider.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_customers_screen.dart';
import 'admin_professionals_screen.dart';
import 'admin_portfolio_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_logs_screen.dart';
import 'admin_promo_banners_screen.dart';
import 'admin_articles_screen.dart';
import 'admin_reported_users_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_payments_screen.dart';
import 'admin_revenue_screen.dart';
import 'admin_subscriptions_screen.dart';
import 'admin_reviews_screen.dart';
import 'admin_complaints_screen.dart';
import 'admin_reports_hub_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_languages_screen.dart';
import 'admin_countries_screen.dart';
import 'admin_cities_screen.dart';
import 'admin_announcements_screen.dart';
import 'admin_blocked_users_screen.dart';
import 'admin_verification_requests_screen.dart';
import 'admin_about_page_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  // ✅ GlobalKey — Scaffold.of(context) crash fix
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _currentIndex = 0;

  late final List<Widget> _screens = [
    AdminDashboardScreen(onNavigateToTab: _goTo),
    const AdminUsersScreen(),
    const AdminCustomersScreen(),
    const AdminProfessionalsScreen(),
    const AdminPortfolioScreen(),
    const AdminBookingsScreen(),
    const AdminLogsScreen(),
    const AdminPromoBannersScreen(),
    const AdminArticlesScreen(),
    const AdminReportedUsersScreen(),
    const AdminAnalyticsScreen(),
    const AdminBlockedUsersScreen(),
    const AdminVerificationRequestsScreen(),
    const AdminCategoriesScreen(),
    const AdminPaymentsScreen(),
    const AdminRevenueScreen(),
    const AdminSubscriptionsScreen(),
    const AdminReviewsScreen(),
    const AdminComplaintsScreen(),
    const AdminReportsHubScreen(),
    const AdminNotificationsScreen(),
    const AdminLanguagesScreen(),
    const AdminCountriesScreen(),
    const AdminCitiesScreen(),
    const AdminAnnouncementsScreen(),
    const AdminAboutPageScreen(),
  ];

  static const _navItems = [
    _NavItem(Icons.dashboard_rounded,     Icons.dashboard_outlined,       'Dashboard'),
    _NavItem(Icons.people_alt_rounded,    Icons.people_alt_outlined,      'Users'),
    _NavItem(Icons.person_rounded,        Icons.person_outline_rounded,   'Customers'),
    _NavItem(Icons.work_rounded,          Icons.work_outline_rounded,     'Professionals'),
    _NavItem(Icons.photo_library_rounded, Icons.photo_library_outlined,   'Portfolio'),
    _NavItem(Icons.calendar_month_rounded,Icons.calendar_month_outlined,  'Bookings'),
    _NavItem(Icons.history_rounded,       Icons.history_outlined,         'Logs'),
    _NavItem(Icons.campaign_rounded,      Icons.campaign_outlined,        'Banners'),
    _NavItem(Icons.menu_book_rounded, Icons.menu_book_outlined, 'Magazine'),
    _NavItem(Icons.flag_rounded,      Icons.flag_outlined,           'Reports'),
    _NavItem(Icons.insights_rounded,  Icons.insights_outlined,       'Analytics'),
    _NavItem(Icons.block_rounded,     Icons.block_outlined,          'Blocked'),
    _NavItem(Icons.verified_user_rounded, Icons.verified_user_outlined, 'Verify'),
    _NavItem(Icons.category_rounded,      Icons.category_outlined,        'Categories'),
    _NavItem(Icons.payments_rounded,      Icons.payments_outlined,        'Payments'),
    _NavItem(Icons.trending_up_rounded,   Icons.trending_up_rounded,      'Revenue'),
    _NavItem(Icons.workspace_premium_rounded, Icons.workspace_premium_outlined, 'Subscriptions'),
    _NavItem(Icons.star_rounded,          Icons.star_outline_rounded,     'Reviews'),
    _NavItem(Icons.report_problem_rounded, Icons.report_problem_outlined, 'Complaints'),
    _NavItem(Icons.summarize_rounded,     Icons.summarize_outlined,       'Reports Hub'),
    _NavItem(Icons.notifications_active_rounded, Icons.notifications_outlined, 'Notifications'),
    _NavItem(Icons.translate_rounded, Icons.translate_rounded, 'Languages'),
    _NavItem(Icons.public_rounded, Icons.public_outlined, 'Countries'),
    _NavItem(Icons.location_city_rounded, Icons.location_city_outlined, 'Cities'),
    _NavItem(Icons.campaign_rounded, Icons.campaign_outlined, 'Announcements'),
    _NavItem(Icons.info_rounded, Icons.info_outline_rounded, 'About Page'),
  ];

  void _goTo(int index) {
    setState(() => _currentIndex = index);
    // Close drawer if open
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: same root-pop issue as guest_main_screen.dart — see that
    // file for full explanation.
    return PopScope(
      canPop: false,
      child: Scaffold(
        key:    _scaffoldKey, // ✅ GlobalKey attach
        drawer: _buildDrawer(),
        body:   IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: _buildBottomNav(),
      ), // Scaffold
    );
  }

  // ── Drawer ────────────────────────────────────────────────
  Widget _buildDrawer() {
    final auth = context.watch<AuthProvider>();

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            width:   double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF991B1B), AppColors.adminColor],
                begin:  Alignment.topLeft,
                end:    Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color:        Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                const Text('ProFinder Admin',
                    style: TextStyle(
                        fontSize:   18,
                        fontWeight: FontWeight.w800,
                        color:      Colors.white)),
                const SizedBox(height: 2),
                Text('Admin Panel',
                    style: TextStyle(
                        fontSize: 12,
                        color:    Colors.white.withOpacity(0.8))),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // All 6 nav items
          Expanded(
            child: ListView.builder(
              padding:     EdgeInsets.zero,
              itemCount:   _navItems.length,
              itemBuilder: (_, i) {
                final item     = _navItems[i];
                final isActive = _currentIndex == i;
                return _buildDrawerTile(
                  icon:     isActive ? item.activeIcon : item.icon,
                  label:    item.label,
                  isActive: isActive,
                  onTap:    () => _goTo(i),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // ✅ FIX: Logout ListTile ko Material mein wrap kiya.
          // Pehle ListTile seedha Column mein tha jiske andar koi
          // Material ancestor nahi tha — isliye "ListTile background
          // color or ink splashes may be invisible" warning aati thi.
          Material(
            color: Colors.transparent,
            child: ListTile(
              leading: const Icon(Icons.logout_rounded,
                  color: AppColors.error, size: 22),
              title: const Text('Logout',
                  style: TextStyle(
                      fontSize:   14,
                      fontWeight: FontWeight.w600,
                      color:      AppColors.error)),
              onTap: () => _confirmLogout(auth),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String   label,
    required bool     isActive,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.adminColor.withOpacity(0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      // ✅ FIX: Drawer ke andar ListView ke ListTile ko bhi Material wrap kiya
      // taake ink splash aur background sahi se render ho.
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          leading: Icon(icon,
              color: isActive ? AppColors.adminColor : const Color(0xFF9CA3AF),
              size:  22),
          title: Text(label,
              style: TextStyle(
                  fontSize:   14,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color:      isActive
                      ? AppColors.adminColor
                      : const Color(0xFF374151))),
          trailing: isActive
              ? Container(
                  width: 4, height: 24,
                  decoration: BoxDecoration(
                    color:        AppColors.adminColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              : null,
          onTap:  onTap,
          dense:  true,
        ),
      ),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset:     const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // First 4 screens
              ...List.generate(4, (i) {
                final item     = _navItems[i];
                final isActive = _currentIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap:    () => _goTo(i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.adminColor.withOpacity(0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            isActive ? item.activeIcon : item.icon,
                            color: isActive
                                ? AppColors.adminColor
                                : const Color(0xFF9CA3AF),
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(item.label,
                            style: TextStyle(
                                fontSize:   10,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isActive
                                    ? AppColors.adminColor
                                    : const Color(0xFF9CA3AF))),
                      ],
                    ),
                  ),
                );
              }),

              // ✅ More button — _scaffoldKey use karo, Scaffold.of(context) nahi
              Expanded(
                child: GestureDetector(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: _currentIndex >= 4
                              ? AppColors.adminColor.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.menu_rounded,
                          color: _currentIndex >= 4
                              ? AppColors.adminColor
                              : const Color(0xFF9CA3AF),
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('More',
                          style: TextStyle(
                              fontSize:   10,
                              fontWeight: _currentIndex >= 4
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _currentIndex >= 4
                                  ? AppColors.adminColor
                                  : const Color(0xFF9CA3AF))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Logout ────────────────────────────────────────────────
  Future<void> _confirmLogout(AuthProvider auth) async {
    Navigator.pop(context); // close drawer
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            SizedBox(width: 8),
            Text('Logout?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text('You will be logged out of the admin panel.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await auth.logout();
      if (!mounted) return;
      // ✅ FIX: pushNamedAndRemoveUntil clears the whole stack on logout —
      // see login_screen.dart for details on the underlying bug.
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }
}

class _NavItem {
  final IconData activeIcon;
  final IconData icon;
  final String   label;
  const _NavItem(this.activeIcon, this.icon, this.label);
}