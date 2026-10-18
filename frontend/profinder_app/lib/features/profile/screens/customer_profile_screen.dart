// lib/features/profile/screens/customer_profile_screen.dart

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
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
import '../../../services/geo_service.dart';
import '../../../core/constants/country_flags.dart';
import '../../auth/widgets/searchable_picker_field.dart';
import '../../notifications/screens/notification_screen.dart';
import '../../subscription/services/subscription_service.dart';
import '../../subscription/screens/subscription_screen.dart';
import 'wallet_screen.dart';
import 'payments_screen.dart';
import 'saved_professionals_screen.dart';
import 'my_reviews_screen.dart';
import 'settings_screen.dart';
import 'language_settings_screen.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/localization/supported_languages.dart';
import 'security_screen.dart';
import 'help_screen.dart';
import '../../trust_safety/screens/my_reports_screen.dart';
import '../../trust_safety/screens/account_status_screen.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/theme_mode_picker.dart';
import '../../../shared/widgets/profile_header_card.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../../about/screens/about_screen.dart';
import '../../support/screens/help_center_screen.dart';
import '../../support/screens/my_tickets_screen.dart';
import '../../support/screens/privacy_policy_screen.dart';
import '../../../l10n/generated/app_localizations.dart';

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
  bool _isSaving = false;

  // Header stats + notification badge — real counts, no fake numbers
  int _unreadNotifications = 0;
  int _bookingsCount = 0;
  int _savedCount = 0;
  bool _isPremium = false;
  String _planName = 'Free';

  // Platform-aware image storage: File for mobile IO, in-memory bytes for Web
  File? _pickedImage;
  XFile? _pickedXFile;
  Uint8List? _webImageBytes;
  String? _photoUrl;

  // ── Controllers ──────────────────────────────────────────
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _api = ApiService();
  final _bookingSvc = BookingService();
  final _favStore = FavoritesStore();
  final _subSvc = SubscriptionService();
  final _picker = ImagePicker();

  final _geoService = GeoService();
  List<Map<String, dynamic>> _countries = [];
  List<Map<String, dynamic>> _cities = [];
  Map<String, dynamic>? _selectedCountry;
  Map<String, dynamic>? _selectedCity;
  bool _loadingCountries = false;
  bool _loadingCities = false;

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
    super.dispose();
  }

  // ── Load Profile ─────────────────────────────────────────
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final meRes = await _api.get(AppConstants.me);
      final profileRes = await _api.get(AppConstants.userProfile);
      if (!mounted) return;

      final meData = meRes.data as Map<String, dynamic>;
      final profileData = profileRes.data as Map<String, dynamic>;

      final merged = {
        ...meData,
        ...profileData,
        'name': (profileData['full_name'] as String?)?.isNotEmpty == true
            ? profileData['full_name']
            : meData['name'] ?? '',
      };

      setState(() {
        _profile = merged;
        _isLoading = false;
        _photoUrl = profileData['photo_url'] as String?;
        _nameController.text = merged['name'] ?? '';
        _phoneController.text = merged['phone'] ?? '';
      });
      _loadCountriesAndPreselect(
        merged['country'] as String?,
        merged['city'] as String?,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ _loadProfile error: $e');
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppHelpers.showError(
        context,
        AppLocalizations.of(context).profileLoadError,
      );
    }
  }

  Future<void> _loadCountriesAndPreselect(
    String? countryName,
    String? cityName,
  ) async {
    setState(() => _loadingCountries = true);
    final result = await _geoService.getCountries();
    if (!mounted) return;

    final countries = result['success'] == true
        ? List<Map<String, dynamic>>.from(result['data'] ?? [])
        : <Map<String, dynamic>>[];

    Map<String, dynamic>? matchedCountry;
    if (countryName != null && countryName.isNotEmpty) {
      for (final c in countries) {
        if ((c['name'] as String).toLowerCase() == countryName.toLowerCase()) {
          matchedCountry = c;
          break;
        }
      }
    }

    setState(() {
      _countries = countries;
      _selectedCountry = matchedCountry;
      _loadingCountries = false;
    });

    if (matchedCountry == null) return;

    setState(() => _loadingCities = true);
    final cityResult = await _geoService.getCities(matchedCountry['id'] as int);
    if (!mounted) return;

    final cities = cityResult['success'] == true
        ? List<Map<String, dynamic>>.from(cityResult['data'] ?? [])
        : <Map<String, dynamic>>[];

    Map<String, dynamic>? matchedCity;
    if (cityName != null && cityName.isNotEmpty) {
      for (final c in cities) {
        if ((c['name'] as String).toLowerCase() == cityName.toLowerCase()) {
          matchedCity = c;
          break;
        }
      }
    }

    setState(() {
      _cities = cities;
      _selectedCity = matchedCity;
      _loadingCities = false;
    });
  }

  Future<void> _onCountrySelected(Map<String, dynamic>? country) async {
    if (country == null) return;
    setState(() {
      _selectedCountry = country;
      _selectedCity = null;
      _loadingCities = true;
      _cities = [];
    });
    final result = await _geoService.getCities(country['id'] as int);
    if (!mounted) return;
    setState(() {
      _cities = result['success'] == true
          ? List<Map<String, dynamic>>.from(result['data'] ?? [])
          : [];
      _loadingCities = false;
    });
  }

  // ── Load header stats — real counts, no fake numbers ──────
  Future<void> _loadStats() async {
    try {
      final notifRes = await _api.get(AppConstants.notifications);
      final notifList = notifRes.data is List
          ? List<dynamic>.from(notifRes.data)
          : [];
      final unread = notifList.where((n) => n['is_read'] != true).length;

      final bookingsRes = await _bookingSvc.getMyBookings();
      final bookings = bookingsRes['success'] == true
          ? List<dynamic>.from(bookingsRes['data'] ?? [])
          : [];

      final saved = await _favStore.getAll();
      final plan = await _subSvc.getMyPlan();

      if (!mounted) return;
      setState(() {
        _unreadNotifications = unread;
        _bookingsCount = bookings.length;
        _savedCount = saved.length;
        _isPremium = plan?.isPremium ?? false;
        _planName = plan?.planName ?? 'Free';
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
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (picked == null) return;

      if (kIsWeb) {
        // Read in-memory bytes for Web image preview
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedXFile = picked;
          _webImageBytes = bytes;
        });
      } else {
        // Use local File reference on mobile platforms
        setState(() {
          _pickedXFile = picked;
          _pickedImage = File(picked.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showError(
        context,
        AppLocalizations.of(context).imagePickError,
      );
    }
  }

  // ── Show Image Source Sheet ──────────────────────────────
  void _showImageSourceSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusChip),
        ),
      ),
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusChip),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : AppColors.neutral200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  AppLocalizations.of(context).changeProfilePhotoTitle,
                  style: TextStyle(
                    fontSize: AppFontSizes.body,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.colors.primaryLight,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: context.colors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    AppLocalizations.of(context).galleryOptionLabel,
                    style: TextStyle(
                      fontSize: AppFontSizes.body,
                      fontWeight: FontWeight.w500,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                // Camera option — excluded on Web due to platform sandbox limits
                if (!kIsWeb)
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.colors.accentLight,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: context.colors.accent,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      AppLocalizations.of(context).cameraOptionLabel,
                      style: TextStyle(
                        fontSize: AppFontSizes.body,
                        fontWeight: FontWeight.w500,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                const SizedBox(height: 8),
              ],
            ),
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

      // Convert selected image file into a multipart payload
      if (_pickedXFile != null) {
        if (kIsWeb) {
          // Read bytes in memory for Web multipart upload
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
        'phone': _phoneController.text.trim(),
        'city': _selectedCity?['name'] ?? '',
        'country': _selectedCountry?['name'] ?? '',
        'photo': ?photoMultipart,
      });

      await _api.patchForm(AppConstants.userProfile, formData);

      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _isSaving = false;
        _pickedImage = null;
        _pickedXFile = null;
        _webImageBytes = null;
      });
      AppHelpers.showSuccess(
        context,
        AppLocalizations.of(context).profileUpdateSuccess,
      );
      _loadProfile();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppHelpers.showError(
        context,
        AppLocalizations.of(context).profileUpdateError,
      );
    }
  }

  // ── Cancel Edit ──────────────────────────────────────────
  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _pickedImage = null;
      _pickedXFile = null;
      _webImageBytes = null;
      _nameController.text = _profile?['name'] ?? '';
      _phoneController.text = _profile?['phone'] ?? '';
    });
    _loadCountriesAndPreselect(
      _profile?['country'] as String?,
      _profile?['city'] as String?,
    );
  }

  // ── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: _buildAppBar(isDark),
      body: _isLoading
          ? Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: AppColors.customerColor,
                  strokeWidth: 3,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: AppColors.customerColor,
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
  PreferredSizeWidget _buildAppBar(bool isDark) {
    final t = AppLocalizations.of(context);
    return UniversalAppBar(
      title: t.profileTitle,
      icon: Icons.person_rounded,
      actions: [
        AppBarIconButton(
          icon: Icons.notifications_outlined,
          tooltip: t.notificationsTitle,
          badgeCount: _unreadNotifications,
          onGradient: true,
          badgeBorderColor: universalBarColor(context),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationScreen()),
          ).then((_) => _loadStats()),
        ),
        const SizedBox(width: 8),
        if (!_isEditing)
          AppBarIconButton(
            icon: Icons.edit_outlined,
            tooltip: t.editCta,
            onGradient: true,
            onPressed: () => setState(() => _isEditing = true),
          )
        else ...[
          AppBarIconButton(
            icon: Icons.close_rounded,
            tooltip: t.cancelCta,
            onGradient: true,
            onPressed: _isSaving ? () {} : _cancelEdit,
          ),
          const SizedBox(width: 8),
          _isSaving
              ? const SizedBox(
                  width: 42,
                  height: 42,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : AppBarIconButton(
                  icon: Icons.check_rounded,
                  tooltip: t.saveCta,
                  onGradient: true,
                  onPressed: _saveProfile,
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
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      return NetworkImage(_photoUrl!);
    }
    return null;
  }

  Widget _buildAvatarSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // ── Global profile header card (guest ke sath shared widget) ──
        ProfileHeaderCard(
          accentColor: AppColors.customerColor,
          accentColorSecondary: AppColors.heroGradientLight2,
          heroGradientLight: const [
            AppColors.heroGradientLight1,
            AppColors.heroGradientLight2,
          ],
          heroGradientDark: const [
            AppColors.heroGradientLight1,
            AppColors.heroGradientLight2,
          ],
          decorativeIconSecondary: null,
          name: _profile?['name'] ?? '',
          avatarImageProvider: _getAvatarImage(),
          avatarFallbackText: AppHelpers.getInitials(_profile?['name'] ?? ''),
          onAvatarTap: _isEditing ? _showImageSourceSheet : null,
          avatarBadge: _isEditing
              ? Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.warningAmber,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                )
              : null,
          statusText: _isPremium
              ? AppLocalizations.of(context).premiumMemberLabel
              : null,
          statusIcon: Icons.workspace_premium_rounded,
          description: (_profile?['email'] as String?)?.isNotEmpty == true
              ? _profile!['email'] as String
              : null,
          stats: [
            ProfileHeaderStat(
              icon: Icons.calendar_today_rounded,
              value: '$_bookingsCount',
              label: AppLocalizations.of(context).bookingsStatLabel,
            ),
            ProfileHeaderStat(
              icon: Icons.favorite_rounded,
              value: '$_savedCount',
              label: AppLocalizations.of(context).savedStatLabel,
            ),
            ProfileHeaderStat(
              icon: Icons.workspace_premium_rounded,
              value: _planName,
              label: AppLocalizations.of(context).planStatLabel,
            ),
          ],
        ),
        if (_isEditing && _pickedXFile != null) ...[
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).newPhotoSelectedHint,
            style: TextStyle(
              fontSize: AppFontSizes.caption,
              color: isDark ? AppColors.starGold : AppColors.amberDarkest,
            ),
          ),
        ],
      ],
    );
  }

  // ── Info Card ────────────────────────────────────────────
  Widget _buildInfoCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : context.colors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 16,
                color: AppColors.customerColor,
              ),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).personalInfoLabel,
                style: TextStyle(
                  fontSize: AppFontSizes.body,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildField(
            AppLocalizations.of(context).fullNameLabel,
            _nameController,
            Icons.person_outline_rounded,
          ),
          const SizedBox(height: 12),
          _buildField(
            AppLocalizations.of(context).phoneLabel,
            _phoneController,
            Icons.phone_outlined,
            type: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _buildLocationField(
            label: AppLocalizations.of(context).countryLabel,
            icon: Icons.public_outlined,
            displayValue:
                (_selectedCountry?['name'] as String?) ??
                (_profile?['country'] as String?),
            editingBuilder: () => SearchablePickerField<Map<String, dynamic>>(
              value: _selectedCountry,
              items: _countries,
              itemLabel: (c) => c['name'] as String,
              itemLeading: (c) {
                final flag = CountryFlags.flagFor(c['name'] as String);
                return Text(
                  flag ?? '🌐',
                  style: const TextStyle(fontSize: AppFontSizes.title2),
                );
              },
              label: AppLocalizations.of(context).countryLabel,
              hint: AppLocalizations.of(context).countryHint,
              prefixIcon: Icons.public_outlined,
              loading: _loadingCountries,
              searchHint: AppLocalizations.of(context).countrySearchHint,
              emptyMessage: AppLocalizations.of(context).countryEmptyMessage,
              onChanged: _onCountrySelected,
            ),
          ),
          const SizedBox(height: 12),
          _buildLocationField(
            label: AppLocalizations.of(context).cityLabel,
            icon: Icons.location_city_outlined,
            displayValue:
                (_selectedCity?['name'] as String?) ??
                (_profile?['city'] as String?),
            editingBuilder: () => SearchablePickerField<Map<String, dynamic>>(
              key: ValueKey(_selectedCountry?['id']),
              value: _selectedCity,
              items: _cities,
              itemLabel: (c) => c['name'] as String,
              label: AppLocalizations.of(context).cityLabel,
              hint: AppLocalizations.of(context).cityHint,
              prefixIcon: Icons.location_city_outlined,
              enabled: _selectedCountry != null,
              loading: _loadingCities,
              disabledHint: AppLocalizations.of(context).cityDisabledHint,
              searchHint: AppLocalizations.of(context).citySearchHint,
              emptyMessage: AppLocalizations.of(context).cityEmptyMessage,
              onChanged: (city) => setState(() => _selectedCity = city),
            ),
          ),
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
        _groupLabel(AppLocalizations.of(context).accountGroupLabel),
        _menuGroup([
          _actionTile(
            Icons.edit_outlined,
            AppLocalizations.of(context).editProfileActionLabel,
            AppLocalizations.of(context).editProfileActionSubtitle,
            () => setState(() => _isEditing = true),
            iconColor: AppColors.primary,
          ),
          _actionTile(
            Icons.workspace_premium_rounded,
            AppLocalizations.of(context).subscriptionActionLabel,
            _isPremium
                ? AppLocalizations.of(
                    context,
                  ).subscriptionActiveStatus(_planName)
                : AppLocalizations.of(context).subscriptionUpgradeStatus,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SubscriptionScreen(userRole: 'customer'),
              ),
            ),
            iconColor: AppColors.warningAmber,
          ),
          _actionTile(
            Icons.account_balance_wallet_outlined,
            AppLocalizations.of(context).walletActionLabel,
            AppLocalizations.of(context).walletActionSubtitle,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletScreen()),
            ),
            iconColor: AppColors.badgeTrending,
          ),
          _actionTile(
            Icons.calendar_today_outlined,
            AppLocalizations.of(context).bookingsActionLabel,
            AppLocalizations.of(context).bookingsActionSubtitle,
            () => Navigator.pushNamed(context, '/bookings'),
            iconColor: AppColors.cyan,
          ),
          _actionTile(
            Icons.favorite_border_rounded,
            AppLocalizations.of(context).savedProfessionalsActionLabel,
            AppLocalizations.of(context).savedProfessionalsActionSubtitle,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SavedProfessionalsScreen(),
              ),
            ),
            iconColor: AppColors.pink,
          ),
          _actionTile(
            Icons.rate_review_outlined,
            AppLocalizations.of(context).reviewsActionLabel,
            AppLocalizations.of(context).reviewsActionSubtitle,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyReviewsScreen()),
            ),
            iconColor: AppColors.violet,
          ),
          _actionTile(
            Icons.receipt_long_outlined,
            AppLocalizations.of(context).paymentsActionLabel,
            AppLocalizations.of(context).paymentsActionSubtitle,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentsScreen()),
            ),
            iconColor: AppColors.indigo,
          ),
        ]),

        const SizedBox(height: 16),
        _groupLabel(AppLocalizations.of(context).preferencesGroupLabel),
        _menuGroup([
          _actionTile(
            Icons.notifications_outlined,
            AppLocalizations.of(context).notificationsActionLabel,
            AppLocalizations.of(context).notificationsActionSubtitle,
            () => Navigator.pushNamed(context, '/notifications'),
            iconColor: AppColors.rose,
          ),
          // Direct language selection shortcut displaying current locale
          _actionTile(
            Icons.language_rounded,
            AppLocalizations.of(context).languageLabel,
            SupportedLanguages.byCode(
              context.watch<LocaleProvider>().locale.languageCode,
            ).nativeName,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()),
            ),
            iconColor: AppColors.cyan,
          ),
          // Theme Mode picker (Light, Dark, System) directly on profile screen
          Builder(
            builder: (context) {
              final t = AppLocalizations.of(context);
              final mode = context.watch<ThemeProvider>().themeMode;
              return _actionTile(
                themeModeIcon(mode),
                t.themeModeTitle,
                themeModeLabel(t, mode),
                () => showThemeModeSheet(context),
                iconColor: AppColors.indigo,
              );
            },
          ),
          _actionTile(
            Icons.settings_outlined,
            AppLocalizations.of(context).settingsActionLabel,
            AppLocalizations.of(context).settingsActionSubtitle,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            iconColor: AppColors.slate500,
          ),
          _actionTile(
            Icons.security_rounded,
            AppLocalizations.of(context).securityActionLabel,
            AppLocalizations.of(context).securityActionSubtitle,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SecurityScreen()),
            ),
            iconColor: AppColors.emerald,
          ),
        ]),

        const SizedBox(height: 16),
        _groupLabel(AppLocalizations.of(context).supportSection),
        _menuGroup([
          // Trust & Safety Part 8 — user-facing account status + reports.
          _actionTile(
            Icons.shield_outlined,
            AppLocalizations.of(context).myTsAccountStatusTitle,
            AppLocalizations.of(context).myTsAccountStatusActionSubtitle,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountStatusScreen()),
            ),
            iconColor: AppColors.dangerRed,
          ),
          _actionTile(
            Icons.outlined_flag_rounded,
            AppLocalizations.of(context).myTsMyReportsTitle,
            AppLocalizations.of(context).myTsMyReportsActionSubtitle,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyReportsScreen()),
            ),
            iconColor: AppColors.sky,
          ),
          _actionTile(
            Icons.help_outline_rounded,
            AppLocalizations.of(context).helpActionLabel,
            AppLocalizations.of(context).helpActionSubtitle,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HelpCenterScreen(
                  audience: 'customer',
                  fallbackBuilder: (_) => const HelpScreen(),
                ),
              ),
            ),
            iconColor: AppColors.teal,
          ),
          _actionTile(
            Icons.support_agent_rounded,
            AppLocalizations.of(context).ticketsTitle,
            AppLocalizations.of(context).ticketsTileSubtitle,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyTicketsScreen()),
            ),
            iconColor: AppColors.teal,
          ),
          _actionTile(
            Icons.privacy_tip_outlined,
            AppLocalizations.of(context).profilePrivacyPolicy,
            AppLocalizations.of(context).privacyActionSubtitle,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
            iconColor: AppColors.emerald,
          ),
          _actionTile(
            Icons.info_outline_rounded,
            AppLocalizations.of(context).aboutActionLabel,
            AppLocalizations.of(context).aboutActionSubtitle,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
            iconColor: AppColors.indigo,
          ),
        ]),
      ],
    );
  }

  Widget _groupLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: AppFontSizes.caption,
        fontWeight: FontWeight.bold,
        color: context.colors.textSecondary,
        letterSpacing: 0.6,
      ),
    ),
  );

  Widget _menuGroup(List<Widget> tiles) {
    final withDividers = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      if (i > 0) {
        withDividers.add(
          Divider(height: 1, indent: 68, color: context.colors.divider),
        );
      }
      withDividers.add(tiles[i]);
    }
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
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
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: context.colors.divider),
        ),
        child: _actionTile(
          Icons.logout_rounded,
          AppLocalizations.of(context).logoutActionLabel,
          null,
          () => _confirmLogout(auth),
          iconColor: AppColors.error,
          titleColor: AppColors.error,
        ),
      ),
    );
  }

  // ── Location Field Builder — Country/City picker (view mode shows a
  //    plain row like _buildField; edit mode shows the searchable picker) ──
  Widget _buildLocationField({
    required String label,
    required IconData icon,
    required String? displayValue,
    required Widget Function() editingBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppFontSizes.caption,
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        _isEditing
            ? editingBuilder()
            : Row(
                children: [
                  Icon(icon, size: 16, color: context.colors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    (displayValue == null || displayValue.isEmpty)
                        ? AppLocalizations.of(context).notSetPlaceholder
                        : displayValue,
                    style: TextStyle(
                      fontSize: AppFontSizes.body,
                      color: (displayValue == null || displayValue.isEmpty)
                          ? context.colors.textSecondary
                          : context.colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  // ── Field Builder ────────────────────────────────────────
  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? type,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppFontSizes.caption,
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        _isEditing
            ? TextFormField(
                controller: controller,
                keyboardType: type,
                style: TextStyle(
                  fontSize: AppFontSizes.body,
                  color: context.colors.textPrimary,
                ),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    icon,
                    size: 18,
                    color: context.colors.textSecondary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : context.colors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide(color: context.colors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide(color: context.colors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide(
                      color: AppColors.customerColor,
                      width: 1.5,
                    ),
                  ),
                ),
              )
            : Row(
                children: [
                  Icon(icon, size: 16, color: context.colors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    controller.text.isEmpty
                        ? AppLocalizations.of(context).notSetPlaceholder
                        : controller.text,
                    style: TextStyle(
                      fontSize: AppFontSizes.body,
                      color: controller.text.isEmpty
                          ? context.colors.textSecondary
                          : context.colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  // ── Action Tile ──────────────────────────────────────────
  Widget _actionTile(
    IconData icon,
    String label,
    String? subtitle,
    VoidCallback onTap, {
    Color? iconColor,
    Color? titleColor,
  }) {
    final c = iconColor ?? AppColors.customerColor;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Icon(icon, color: c, size: 19),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: AppFontSizes.body,
          fontWeight: FontWeight.w600,
          color: titleColor ?? context.colors.textPrimary,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: TextStyle(
                fontSize: AppFontSizes.small,
                color: context.colors.textSecondary,
              ),
            ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: context.colors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  // ── Logout Dialog ─────────────────────────────────────────
  Future<void> _confirmLogout(AuthProvider auth) async {
    final confirmed = await UniversalDialog.showLogout(context);
    if (confirmed != true || !mounted) return;
    await auth.logout();
    if (!mounted) return;
    // pushNamedAndRemoveUntil clears the whole stack.
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}
