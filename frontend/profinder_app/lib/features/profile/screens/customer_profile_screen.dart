// lib/features/profile/screens/customer_profile_screen.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../services/auth_provider.dart';
import '../../../services/api_service.dart';
import '../../../services/booking_service.dart';
import '../../../services/favorites_store.dart';
import '../../../core/constants/app_constants.dart';
import '../../notifications/screens/notification_screen.dart';
import '../../subscription/services/subscription_service.dart';
import '../../subscription/screens/subscription_screen.dart';  // ✅ FIX: navigate here
import 'wallet_screen.dart';
import 'payments_screen.dart';
import 'saved_professionals_screen.dart';
import 'my_reviews_screen.dart';
import 'settings_screen.dart';
import 'security_screen.dart';
import 'help_screen.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../shared/widgets/profile_header_card.dart';
import '../../about/screens/about_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  // ── State ────────────────────────────────────────────────
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving  = false;

  // Header stats + notification badge — real counts, no fake numbers
  int  _unreadNotifications = 0;
  int  _bookingsCount       = 0;
  int  _savedCount          = 0;
  bool _isPremium           = false;
  String _planName          = 'Free';

  // Image handling — web aur mobile alag hai
  // Mobile: File object use hota hai
  // Web:    XFile se bytes nikalte hain (File() web pe kaam nahi karta)
  File?      _pickedImage;   // mobile only
  XFile?     _pickedXFile;   // web + mobile dono ke liye reference
  Uint8List? _webImageBytes; // web pe preview ke liye
  String?    _photoUrl;      // Cloudinary HTTPS URL — server se

  // ── Controllers ──────────────────────────────────────────
  final _nameController  = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController  = TextEditingController();
  final _api             = ApiService();
  final _bookingSvc      = BookingService();
  final _favStore        = FavoritesStore();
  final _subSvc          = SubscriptionService();
  final _picker          = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadStats();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  // ── Load Profile ─────────────────────────────────────────
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final meRes      = await _api.get(AppConstants.me);
      final profileRes = await _api.get(AppConstants.userProfile);
      if (!mounted) return;

      final meData      = meRes.data      as Map<String, dynamic>;
      final profileData = profileRes.data as Map<String, dynamic>;

      final merged = {
        ...meData,
        ...profileData,
        'name': (profileData['full_name'] as String?)?.isNotEmpty == true
            ? profileData['full_name']
            : meData['name'] ?? '',
      };

      setState(() {
        _profile   = merged;
        _isLoading = false;
        _photoUrl  = profileData['photo_url'] as String?;
        _nameController.text  = merged['name']  ?? '';
        _phoneController.text = merged['phone'] ?? '';
        _cityController.text  = merged['city']  ?? '';
      });
    } catch (e) {
      // ignore: avoid_print
      print('❌ _loadProfile error: $e'); // TEMP DEBUG — console mein pura error dekhne ke liye
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppHelpers.showError(context, 'Could not load profile');
    }
  }

  // ── Load header stats — real counts, no fake numbers ──────
  Future<void> _loadStats() async {
    try {
      final notifRes  = await _api.get(AppConstants.notifications);
      final notifList = notifRes.data is List ? List<dynamic>.from(notifRes.data) : [];
      final unread    = notifList.where((n) => n['is_read'] != true).length;

      final bookingsRes = await _bookingSvc.getMyBookings();
      final bookings    = bookingsRes['success'] == true ? List<dynamic>.from(bookingsRes['data'] ?? []) : [];

      final saved = await _favStore.getAll();
      final plan  = await _subSvc.getMyPlan();

      if (!mounted) return;
      setState(() {
        _unreadNotifications = unread;
        _bookingsCount       = bookings.length;
        _savedCount          = saved.length;
        _isPremium           = plan?.isPremium ?? false;
        _planName            = plan?.planName ?? 'Free';
      });
    } catch (_) {
      // stats are non-critical — header still renders without them
    }
  }

  // ── Pick Image ───────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // close bottom sheet
    try {
      final picked = await _picker.pickImage(
        source:       source,
        imageQuality: 80,
        maxWidth:     800,
      );
      if (picked == null) return;

      if (kIsWeb) {
        // Web pe File() nahi chalta — bytes read karo preview ke liye
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedXFile    = picked;
          _webImageBytes  = bytes;
        });
      } else {
        // Mobile — normal File
        setState(() {
          _pickedXFile  = picked;
          _pickedImage  = File(picked.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showError(context, 'Could not pick image');
    }
  }

  // ── Show Image Source Sheet ──────────────────────────────
  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Change Profile Photo',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: context.colors.primaryLight, borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.photo_library_outlined, color: context.colors.primary, size: 20),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              // Camera option — web pe hide karo (web me camera support limited hai)
              if (!kIsWeb)
                ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: context.colors.accentLight, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.camera_alt_outlined, color: context.colors.accent, size: 20),
                  ),
                  title: const Text('Take a Photo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  onTap: () => _pickImage(ImageSource.camera),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Save Profile ─────────────────────────────────────────
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      MultipartFile? photoMultipart;

      // Photo file ko multipart mein convert karo
      if (_pickedXFile != null) {
        if (kIsWeb) {
          // Web: bytes se MultipartFile banao
          final bytes = _webImageBytes ?? await _pickedXFile!.readAsBytes();
          photoMultipart = MultipartFile.fromBytes(
            bytes,
            filename: 'profile_photo.jpg',
          );
        } else {
          // Mobile: path se MultipartFile banao
          photoMultipart = await MultipartFile.fromFile(
            _pickedXFile!.path,
            filename: 'profile_photo.jpg',
          );
        }
      }

      final formData = FormData.fromMap({
        'full_name': _nameController.text.trim(),
        'phone':     _phoneController.text.trim(),
        'city':      _cityController.text.trim(),
        if (photoMultipart != null) 'photo': photoMultipart,
      });

      await _api.patchForm(AppConstants.userProfile, formData);

      if (!mounted) return;
      setState(() {
        _isEditing     = false;
        _isSaving      = false;
        _pickedImage   = null;
        _pickedXFile   = null;
        _webImageBytes = null;
      });
      AppHelpers.showSuccess(context, 'Profile updated successfully!');
      _loadProfile();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppHelpers.showError(context, 'Failed to update profile');
    }
  }

  // ── Cancel Edit ──────────────────────────────────────────
  void _cancelEdit() {
    setState(() {
      _isEditing     = false;
      _pickedImage   = null;
      _pickedXFile   = null;
      _webImageBytes = null;
      _nameController.text  = _profile?['name']  ?? '';
      _phoneController.text = _profile?['phone'] ?? '';
      _cityController.text  = _profile?['city']  ?? '';
    });
  }

  // ── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: context.colors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildAvatarSection(),
                    const SizedBox(height: 24),
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                    _buildQuickActions(auth),
                    const SizedBox(height: 16),
                    _buildLogoutButton(auth),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.colors.surface,
      elevation: 0,
      title: Text(
        'My Profile',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: context.colors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())).then((_) => _loadStats()),
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: context.colors.background, shape: BoxShape.circle),
                  child: Icon(Icons.notifications_outlined, color: context.colors.textPrimary, size: 19),
                ),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: -2, top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 17),
                      decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(9), border: Border.all(color: Colors.white, width: 1.5)),
                      child: Text(_unreadNotifications > 9 ? '9+' : '$_unreadNotifications', textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (!_isEditing)
          TextButton.icon(
            onPressed: () => setState(() => _isEditing = true),
            icon: Icon(Icons.edit_outlined, size: 16, color: context.colors.primary),
            label: Text('Edit', style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w600)),
          )
        else ...[
          TextButton(
            onPressed: _isSaving ? null : _cancelEdit,
            child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary, fontWeight: FontWeight.w500)),
          ),
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(
                  onPressed: _saveProfile,
                  child: Text('Save', style: TextStyle(color: context.colors.accent, fontWeight: FontWeight.w700)),
                ),
        ],
      ],
    );
  }

  // ── Avatar ───────────────────────────────────────────────
  // Priority: web bytes preview > mobile file > cloudinary url > initials
  ImageProvider? _getAvatarImage() {
    if (kIsWeb && _webImageBytes != null) return MemoryImage(_webImageBytes!);
    if (!kIsWeb && _pickedImage != null) return FileImage(_pickedImage!);
    if (_photoUrl != null && _photoUrl!.isNotEmpty) return NetworkImage(_photoUrl!);
    return null;
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        // ── Global profile header card (guest ke sath shared widget) ──
        ProfileHeaderCard(
          accentColor: AppColors.customerColor,
          accentColorSecondary: AppColors.heroGradientLight2,
          heroGradientLight: const [AppColors.heroGradientLight1, AppColors.heroGradientLight2],
          heroGradientDark: const [AppColors.heroGradientLight1, AppColors.heroGradientLight2],
          decorativeIconSecondary: null,
          name: _profile?['name'] ?? '',
          avatarImageProvider: _getAvatarImage(),
          avatarFallbackText: AppHelpers.getInitials(_profile?['name'] ?? ''),
          onAvatarTap: _isEditing ? _showImageSourceSheet : null,
          avatarBadge: _isEditing
              ? Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: const Color(0xFFF59E0B), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                )
              : null,
          statusText: _isPremium ? 'Premium Member' : null,
          statusIcon: Icons.workspace_premium_rounded,
          description: (_profile?['email'] as String?)?.isNotEmpty == true ? _profile!['email'] as String : null,
          stats: [
            ProfileHeaderStat(icon: Icons.calendar_today_rounded, value: '$_bookingsCount', label: 'Bookings'),
            ProfileHeaderStat(icon: Icons.favorite_rounded, value: '$_savedCount', label: 'Saved'),
            ProfileHeaderStat(icon: Icons.workspace_premium_rounded, value: _planName, label: 'Plan'),
          ],
        ),
        if (_isEditing && _pickedXFile != null) ...[
          const SizedBox(height: 8),
          const Text('New photo selected — tap Save to upload', style: TextStyle(fontSize: 11, color: Color(0xFFB45309))),
        ],
      ],
    );
  }

  // ── Info Card ────────────────────────────────────────────
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 16, color: context.colors.primary),
              const SizedBox(width: 6),
              Text(
                'Personal Information',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildField('Full Name',    _nameController,  Icons.person_outline_rounded),
          const SizedBox(height: 12),
          _buildField('Phone Number', _phoneController, Icons.phone_outlined, type: TextInputType.phone),
          const SizedBox(height: 12),
          _buildField('City',         _cityController,  Icons.location_city_outlined),
        ],
      ),
    );
  }

  // ── Menu — Wallet, Bookings, Saved, Reviews, Payments, Notifications,
  //          Settings, Security, Help (grouped like a real settings hub) ──
  Widget _buildQuickActions(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _groupLabel('Account'),
        _menuGroup([
          _actionTile(Icons.edit_outlined, 'Edit Profile', 'Update your personal details',
              () => setState(() => _isEditing = true), iconColor: const Color(0xFF3B82F6)),
          _actionTile(Icons.workspace_premium_rounded, 'Subscription',
              _isPremium ? 'You\'re on the $_planName plan' : 'Upgrade to Premium',
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SubscriptionScreen(userRole: 'customer'))),
              iconColor: const Color(0xFFF59E0B)),
          _actionTile(Icons.account_balance_wallet_outlined, 'Wallet', 'Manage your balance',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
              iconColor: const Color(0xFFF97316)),
          _actionTile(Icons.calendar_today_outlined, 'Bookings', 'View your bookings',
              () => Navigator.pushNamed(context, '/bookings'), iconColor: const Color(0xFF06B6D4)),
          _actionTile(Icons.favorite_border_rounded, 'Saved Professionals', 'Your favorite professionals',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedProfessionalsScreen())),
              iconColor: const Color(0xFFEC4899)),
          _actionTile(Icons.rate_review_outlined, 'Reviews', 'Reviews you\'ve written',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReviewsScreen())),
              iconColor: const Color(0xFF8B5CF6)),
          _actionTile(Icons.receipt_long_outlined, 'Payments', 'Your payment history',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentsScreen())),
              iconColor: const Color(0xFF6366F1)),
        ]),

        const SizedBox(height: 16),
        _groupLabel('Preferences & Safety'),
        _menuGroup([
          _actionTile(Icons.notifications_outlined, 'Notifications', 'Manage your notification settings',
              () => Navigator.pushNamed(context, '/notifications'), iconColor: const Color(0xFFF43F5E)),
          _actionTile(Icons.settings_outlined, 'Settings', 'Language, theme & preferences',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
              iconColor: const Color(0xFF64748B)),
          _actionTile(Icons.security_rounded, 'Security', 'Password & account security',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityScreen())),
              iconColor: const Color(0xFF10B981)),
          _actionTile(Icons.help_outline_rounded, 'Help & Support', 'FAQs & contact support',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen())),
              iconColor: const Color(0xFF14B8A6)),
          _actionTile(Icons.info_outline_rounded, 'About', 'Our story, mission & more',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
              iconColor: const Color(0xFF6366F1)),
        ]),
      ],
    );
  }

  Widget _groupLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(text.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.colors.textSecondary, letterSpacing: 0.6)),
      );

  Widget _menuGroup(List<Widget> tiles) {
    final withDividers = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      if (i > 0) withDividers.add(Divider(height: 1, indent: 68, color: context.colors.divider));
      withDividers.add(tiles[i]);
    }
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.divider),
        ),
        child: Column(children: withDividers),
      ),
    );
  }

  // ── Logout ───────────────────────────────────────────────
  Widget _buildLogoutButton(AuthProvider auth) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.divider),
        ),
        child: _actionTile(
          Icons.logout_rounded,
          'Logout',
          null,
          () => _confirmLogout(auth),
          iconColor: AppColors.error,
          titleColor: AppColors.error,
        ),
      ),
    );
  }

  // ── Field Builder ────────────────────────────────────────
  Widget _buildField(String label, TextEditingController controller, IconData icon, {TextInputType? type}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: context.colors.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        _isEditing
            ? TextFormField(
                controller:   controller,
                keyboardType: type,
                style: TextStyle(fontSize: 14, color: context.colors.textPrimary),
                decoration: InputDecoration(
                  prefixIcon:     Icon(icon, size: 18, color: context.colors.textSecondary),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled:    true,
                  fillColor: context.colors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:   BorderSide(color: context.colors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:   BorderSide(color: context.colors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:   BorderSide(color: context.colors.primary, width: 1.5),
                  ),
                ),
              )
            : Row(
                children: [
                  Icon(icon, size: 16, color: context.colors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    controller.text.isEmpty ? 'Not set' : controller.text,
                    style: TextStyle(
                      fontSize:   14,
                      color:      controller.text.isEmpty ? context.colors.textSecondary : context.colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  // ── Action Tile ──────────────────────────────────────────
  Widget _actionTile(IconData icon, String label, String? subtitle, VoidCallback onTap, {Color? iconColor, Color? titleColor}) {
    final c = iconColor ?? context.colors.primary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: c.withOpacity(0.14), borderRadius: BorderRadius.circular(11)),
        child: Icon(icon, color: c, size: 19),
      ),
      title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: titleColor ?? context.colors.textPrimary)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: TextStyle(fontSize: 11.5, color: context.colors.textSecondary)),
      trailing: Icon(Icons.chevron_right_rounded, size: 18, color: context.colors.textSecondary),
      onTap: onTap,
    );
  }

  // ── Logout Dialog ─────────────────────────────────────────
  void _confirmLogout(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              await auth.logout();
              if (!mounted) return;
              // ✅ FIX: pushNamedAndRemoveUntil clears the whole stack.
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}