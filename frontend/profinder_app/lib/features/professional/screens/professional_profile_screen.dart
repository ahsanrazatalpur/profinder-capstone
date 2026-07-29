// lib/features/professional/screens/professional_profile_screen.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../services/auth_provider.dart';
import '../../../services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../subscription/screens/subscription_screen.dart';
import 'professional_portfolio_screen.dart';
import 'professional_certificates_screen.dart';
import 'professional_gallery_screen.dart';
import 'professional_wallet_screen.dart';
import 'help_support_screen.dart';
import '../widgets/change_password_dialog.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/profile_header_card.dart';
import '../../about/screens/about_screen.dart';

class ProfessionalProfileScreen extends StatefulWidget {
  const ProfessionalProfileScreen({super.key});

  @override
  State<ProfessionalProfileScreen> createState() => _ProfessionalProfileScreenState();
}

class _ProfessionalProfileScreenState extends State<ProfessionalProfileScreen> {
  final _api = ApiService();
  final _picker = ImagePicker();

  Map<String, dynamic>? _user;
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  bool _isAvailable = true;
  bool _isTogglingAvailability = false;

  TimeOfDay _workStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _workEnd = const TimeOfDay(hour: 18, minute: 0);

  List<String> _skills = [];
  final _skillInputController = TextEditingController();

  List<String> _languages = [];
  final _languageInputController = TextEditingController();

  File? _pickedImage;
  XFile? _pickedXFile;
  Uint8List? _webBytes;
  String? _photoUrl;

  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rateController = TextEditingController();
  final _expController = TextEditingController();
  final _educationController = TextEditingController();

  final _bankNameController = TextEditingController();
  final _bankAccountNameController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _rateController.dispose();
    _expController.dispose();
    _bankNameController.dispose();
    _bankAccountNameController.dispose();
    _bankAccountNumberController.dispose();
    _skillInputController.dispose();
    _languageInputController.dispose();
    _educationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.get(AppConstants.me),
        _api.get(AppConstants.professionalProfile),
        _api.get(AppConstants.userProfile),
      ]);
      if (!mounted) return;

      final user = results[0].data as Map<String, dynamic>;
      final proProf = results[1].data as Map<String, dynamic>;
      final userProf = results[2].data as Map<String, dynamic>;

      setState(() {
        _user = user;
        _profile = {...proProf, ...userProf};
        _isLoading = false;
        _photoUrl = proProf['photo_url']?.toString();

        _bioController.text = proProf['bio'] ?? '';
        _cityController.text = userProf['city'] ?? '';
        _phoneController.text = userProf['phone'] ?? '';
        _rateController.text = (proProf['hourly_rate'] ?? '').toString();
        _expController.text = (proProf['experience_years'] ?? '').toString();
        _bankNameController.text = proProf['bank_name'] ?? '';
        _bankAccountNameController.text = proProf['bank_account_name'] ?? '';
        _bankAccountNumberController.text = proProf['bank_account_number'] ?? '';

        _isAvailable = proProf['is_available'] ?? true;
        final skillsRaw = (proProf['skills'] ?? '').toString();
        _skills = skillsRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

        final languagesRaw = (proProf['languages'] ?? '').toString();
        _languages = languagesRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        _educationController.text = (proProf['education'] ?? '').toString();

        _workStart = _parseTime(proProf['working_hours_start']?.toString()) ?? const TimeOfDay(hour: 9, minute: 0);
        _workEnd = _parseTime(proProf['working_hours_end']?.toString()) ?? const TimeOfDay(hour: 18, minute: 0);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppHelpers.showError(context, 'Could not load profile');
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (picked == null) return;
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedXFile = picked;
          _webBytes = bytes;
        });
      } else {
        setState(() {
          _pickedXFile = picked;
          _pickedImage = File(picked.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showError(context, 'Could not pick image');
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    setState(() {
      _isAvailable = value;
      _isTogglingAvailability = true;
    });
    try {
      await _api.patchForm(
        AppConstants.professionalProfile,
        FormData.fromMap({'is_available': value.toString()}),
      );
      if (!mounted) return;
      AppHelpers.showSuccess(
        context,
        value ? 'You are now available for bookings' : 'You are now marked unavailable',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAvailable = !value);
      AppHelpers.showError(context, 'Could not update availability');
    } finally {
      if (mounted) setState(() => _isTogglingAvailability = false);
    }
  }

  void _addSkill(String raw) {
    final skill = raw.trim();
    if (skill.isEmpty) return;
    if (_skills.any((s) => s.toLowerCase() == skill.toLowerCase())) {
      _skillInputController.clear();
      return;
    }
    setState(() {
      _skills.add(skill);
      _skillInputController.clear();
    });
  }

  void _removeSkill(String skill) {
    setState(() => _skills.remove(skill));
  }

  void _addLanguage(String raw) {
    final lang = raw.trim();
    if (lang.isEmpty) return;
    if (_languages.any((l) => l.toLowerCase() == lang.toLowerCase())) {
      _languageInputController.clear();
      return;
    }
    setState(() {
      _languages.add(lang);
      _languageInputController.clear();
    });
  }

  void _removeLanguage(String lang) {
    setState(() => _languages.remove(lang));
  }

  TimeOfDay? _parseTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickWorkingHour({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _workStart : _workEnd,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _workStart = picked;
      } else {
        _workEnd = picked;
      }
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await _api.patchForm(
        AppConstants.userProfile,
        FormData.fromMap({
          'city': _cityController.text.trim(),
          'phone': _phoneController.text.trim(),
        }),
      );

      MultipartFile? photoMultipart;
      if (_pickedXFile != null) {
        if (kIsWeb) {
          final bytes = _webBytes ?? await _pickedXFile!.readAsBytes();
          photoMultipart = MultipartFile.fromBytes(bytes, filename: 'profile.jpg');
        } else {
          photoMultipart = await MultipartFile.fromFile(_pickedXFile!.path, filename: 'profile.jpg');
        }
      }

      final proForm = FormData.fromMap({
        'bio': _bioController.text.trim(),
        'hourly_rate': _rateController.text.trim(),
        'experience_years': _expController.text.trim(),
        'skills': _skills.join(', '),
        'languages': _languages.join(', '),
        'education': _educationController.text.trim(),
        'working_hours_start': _formatTime(_workStart),
        'working_hours_end': _formatTime(_workEnd),
        'bank_name': _bankNameController.text.trim(),
        'bank_account_name': _bankAccountNameController.text.trim(),
        'bank_account_number': _bankAccountNumberController.text.trim(),
        if (photoMultipart != null) 'photo': photoMultipart,
      });

      await _api.patchForm(AppConstants.professionalProfile, proForm);

      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _isSaving = false;
        _pickedXFile = null;
        _webBytes = null;
        _pickedImage = null;
      });
      AppHelpers.showSuccess(context, 'Profile updated!');
      _loadProfile();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppHelpers.showError(context, 'Failed to save profile');
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _pickedXFile = null;
      _webBytes = null;
      _pickedImage = null;
      _bioController.text = _profile?['bio'] ?? '';
      _cityController.text = _profile?['city'] ?? '';
      _phoneController.text = _profile?['phone'] ?? '';
      _rateController.text = (_profile?['hourly_rate'] ?? '').toString();
      _expController.text = (_profile?['experience_years'] ?? '').toString();
      _bankNameController.text = _profile?['bank_name'] ?? '';
      _bankAccountNameController.text = _profile?['bank_account_name'] ?? '';
      _bankAccountNumberController.text = _profile?['bank_account_number'] ?? '';
      final languagesRaw = (_profile?['languages'] ?? '').toString();
      _languages = languagesRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      _educationController.text = (_profile?['education'] ?? '').toString();
      _workStart = _parseTime(_profile?['working_hours_start']?.toString()) ?? const TimeOfDay(hour: 9, minute: 0);
      _workEnd = _parseTime(_profile?['working_hours_end']?.toString()) ?? const TimeOfDay(hour: 18, minute: 0);
    });
  }

  ImageProvider? _getAvatar() {
    if (kIsWeb && _webBytes != null) return MemoryImage(_webBytes!);
    if (!kIsWeb && _pickedImage != null) return FileImage(_pickedImage!);
    if (_photoUrl != null && _photoUrl!.isNotEmpty) return NetworkImage(_photoUrl!);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = width > 600;
    final isDesktop = width > 900;
    final auth = context.watch<AuthProvider>();
    final padding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);
    final spacing = isDesktop ? 20.0 : (isTablet ? 16.0 : 12.0);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: _buildAppBar(auth, isDark, isTablet, isDesktop),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: AppColors.professionalColor,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading profile...',
                    style: TextStyle(
                      fontSize: isDesktop ? 16.0 : 14.0,
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: AppColors.professionalColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(padding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.sizeOf(context).height - 
                      (isDesktop ? 200.0 : (isTablet ? 180.0 : 160.0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatarSection(isDark, isTablet, isDesktop),
                      SizedBox(height: spacing),
                      _buildAvailabilityCard(isDark, isTablet, isDesktop),
                      SizedBox(height: spacing),
                      _buildWorkingHoursCard(isDark, isTablet, isDesktop),
                      SizedBox(height: spacing),
                      _buildInfoCard(isDark, isTablet, isDesktop),
                      SizedBox(height: spacing),
                      _buildBankDetailsCard(isDark, isTablet, isDesktop),
                      SizedBox(height: spacing),
                      _buildAccountActions(auth, isDark, isTablet, isDesktop),
                      SizedBox(height: isDesktop ? 40.0 : (isTablet ? 32.0 : 24.0)),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(AuthProvider auth, bool isDark, bool isTablet, bool isDesktop) {
    return AppBar(
      backgroundColor: context.colors.surface,
      elevation: 0,
      leadingWidth: isDesktop ? 60 : null,
      leading: isDesktop ? const SizedBox(width: 8) : null,
      title: Text(
        'My Profile',
        style: TextStyle(
          fontSize: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
          fontWeight: FontWeight.w700,
          color: context.colors.textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        if (!_isEditing)
          TextButton.icon(
            onPressed: () => setState(() => _isEditing = true),
            icon: Icon(
              Icons.edit_outlined,
              size: isDesktop ? 20.0 : 16.0,
              color: AppColors.professionalColor,
            ),
            label: Text(
              'Edit',
              style: TextStyle(
                color: AppColors.professionalColor,
                fontWeight: FontWeight.w600,
                fontSize: isDesktop ? 15.0 : (isTablet ? 14.0 : 13.0),
                letterSpacing: 0.2,
              ),
            ),
          )
        else ...[
          TextButton(
            onPressed: _isSaving ? null : _cancelEdit,
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: isDesktop ? 15.0 : (isTablet ? 14.0 : 13.0),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_isSaving)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: isDesktop ? 22.0 : 18.0,
                height: isDesktop ? 22.0 : 18.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.professionalColor,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                'Save',
                style: TextStyle(
                  color: AppColors.professionalColor,
                  fontWeight: FontWeight.w700,
                  fontSize: isDesktop ? 15.0 : (isTablet ? 14.0 : 13.0),
                  letterSpacing: 0.2,
                ),
              ),
            ),
        ],
      ],
    );
  }

  // ── Avatar Section (global ProfileHeaderCard — guest/customer ke
  //    sath shared. Professional apna accent color + real KPI stats
  //    (Rating/Experience/Rate) pass karta hai) ──────────────────
  Widget _buildAvatarSection(bool isDark, bool isTablet, bool isDesktop) {
    final isVerified = _profile?['is_verified'] ?? false;
    final avatar = _getAvatar();
    final categoryName = (_profile?['category_name'] ?? 'Professional').toString();
    final rating = double.tryParse(_profile?['average_rating']?.toString() ?? '0') ?? 0.0;
    final exp = _profile?['experience_years'] ?? 0;
    final rate = _profile?['hourly_rate'] ?? 0;

    return ProfileHeaderCard(
      accentColor: AppColors.professionalColor,
      accentColorSecondary: const Color(0xFF5B21B6),
      heroGradientLight: const [Color(0xFF7C3AED), Color(0xFF5B21B6)],
      heroGradientDark: const [Color(0xFF7C3AED), Color(0xFF5B21B6)],
      decorativeIconPrimary: Icons.work_rounded,
      decorativeIconSecondary: Icons.workspace_premium_rounded,
      name: _user?['name'] ?? '',
      avatarImageProvider: avatar,
      avatarFallbackText: AppHelpers.getInitials(_user?['name'] ?? ''),
      onAvatarTap: _isEditing ? _pickImage : null,
      avatarBadge: _isEditing
          ? Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.professionalColor,
                    AppColors.professionalColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
            )
          : null,
      statusIcon: isVerified ? Icons.verified_rounded : Icons.workspace_premium_rounded,
      statusText: isVerified ? '$categoryName • Verified' : categoryName,
      description: (_user?['email'] as String?)?.isNotEmpty == true ? _user!['email'] as String : null,
      stats: [
        ProfileHeaderStat(
          icon: Icons.star_rounded,
          value: rating > 0 ? rating.toStringAsFixed(1) : '—',
          label: 'Rating',
        ),
        ProfileHeaderStat(
          icon: Icons.work_history_rounded,
          value: '$exp yrs',
          label: 'Experience',
        ),
        ProfileHeaderStat(
          icon: Icons.attach_money_rounded,
          value: '\$$rate/hr',
          label: 'Rate',
        ),
      ],
    );
  }

  // ── Availability Card ──────────────────────────────────
  Widget _buildAvailabilityCard(bool isDark, bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
        vertical: isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0),
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0)),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.1)
                : Colors.grey.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
            height: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _isAvailable
                    ? [
                        context.colors.accent,
                        context.colors.accent.withOpacity(0.7),
                      ]
                    : [
                        context.colors.textSecondary,
                        context.colors.textSecondary.withOpacity(0.5),
                      ],
              ),
              boxShadow: [
                if (_isAvailable)
                  BoxShadow(
                    color: context.colors.accent.withOpacity(0.3),
                    blurRadius: 8,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isAvailable ? 'Available for Bookings' : 'Not Available',
                  style: TextStyle(
                    fontSize: isDesktop ? 16.0 : (isTablet ? 15.0 : 14.0),
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isAvailable
                      ? 'Customers can book you right now'
                      : 'You won\'t appear in new booking requests',
                  style: TextStyle(
                    fontSize: isDesktop ? 13.0 : (isTablet ? 12.0 : 11.0),
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          if (_isTogglingAvailability)
            SizedBox(
              width: isDesktop ? 24.0 : 20.0,
              height: isDesktop ? 24.0 : 20.0,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.professionalColor,
              ),
            )
          else
            Transform.scale(
              scale: isDesktop ? 1.0 : 0.9,
              child: Switch(
                value: _isAvailable,
                onChanged: _toggleAvailability,
                activeColor: context.colors.accent,
                activeTrackColor: context.colors.accent.withOpacity(0.3),
                inactiveTrackColor: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.3),
              ),
            ),
        ],
      ),
    );
  }

  // ── Working Hours Card ─────────────────────────────────
  Widget _buildWorkingHoursCard(bool isDark, bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0)),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0)),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.1)
                : Colors.grey.withOpacity(0.04),
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
                Icons.schedule_outlined,
                size: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
                color: AppColors.professionalColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Working Hours',
                style: TextStyle(
                  fontSize: isDesktop ? 16.0 : (isTablet ? 15.0 : 14.0),
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildTimeField(
                  'Start Time',
                  _workStart,
                  isStart: true,
                  isDark: isDark,
                  isTablet: isTablet,
                  isDesktop: isDesktop,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeField(
                  'End Time',
                  _workEnd,
                  isStart: false,
                  isDark: isDark,
                  isTablet: isTablet,
                  isDesktop: isDesktop,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeField(
    String label,
    TimeOfDay time, {
    required bool isStart,
    required bool isDark,
    required bool isTablet,
    required bool isDesktop,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 12.0 : (isTablet ? 11.0 : 10.0),
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _isEditing ? () => _pickWorkingHour(isStart: isStart) : null,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              vertical: isDesktop ? 12.0 : (isTablet ? 11.0 : 10.0),
            ),
            decoration: BoxDecoration(
              color: _isEditing
                  ? isDark
                      ? Colors.white.withOpacity(0.04)
                      : context.colors.background
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(isDesktop ? 12.0 : (isTablet ? 11.0 : 10.0)),
              border: Border.all(
                color: _isEditing
                    ? isDark
                        ? Colors.white.withOpacity(0.1)
                        : context.colors.divider
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: isDesktop ? 18.0 : (isTablet ? 17.0 : 16.0),
                  color: context.colors.textSecondary,
                ),
                const SizedBox(width: 10),
                Text(
                  time.format(context),
                  style: TextStyle(
                    fontSize: isDesktop ? 15.0 : (isTablet ? 14.0 : 13.0),
                    fontWeight: FontWeight.w600,
                    color: _isEditing
                        ? context.colors.textPrimary
                        : context.colors.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Info Card ──────────────────────────────────────────
  Widget _buildInfoCard(bool isDark, bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0)),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0)),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.1)
                : Colors.grey.withOpacity(0.04),
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
                Icons.info_outline_rounded,
                size: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
                color: AppColors.professionalColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Professional Details',
                style: TextStyle(
                  fontSize: isDesktop ? 16.0 : (isTablet ? 15.0 : 14.0),
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildField('Bio / About', _bioController, Icons.description_outlined,
              maxLines: 3, isDark: isDark, isTablet: isTablet, isDesktop: isDesktop),
          const SizedBox(height: 14),
          _buildField('City', _cityController, Icons.location_city_outlined,
              isDark: isDark, isTablet: isTablet, isDesktop: isDesktop),
          const SizedBox(height: 14),
          _buildField('Phone', _phoneController, Icons.phone_outlined,
              type: TextInputType.phone, isDark: isDark, isTablet: isTablet, isDesktop: isDesktop),
          const SizedBox(height: 14),
          _buildField('Hourly Rate (\$)', _rateController, Icons.attach_money_rounded,
              type: TextInputType.number, isDark: isDark, isTablet: isTablet, isDesktop: isDesktop),
          const SizedBox(height: 14),
          _buildField('Experience (yrs)', _expController, Icons.work_history_outlined,
              type: TextInputType.number, isDark: isDark, isTablet: isTablet, isDesktop: isDesktop),
          const SizedBox(height: 14),
          _buildField('Education', _educationController, Icons.school_outlined,
              maxLines: 2, isDark: isDark, isTablet: isTablet, isDesktop: isDesktop),
          const SizedBox(height: 16),
          _buildSkillsSection(isDark, isTablet, isDesktop),
          const SizedBox(height: 16),
          _buildLanguagesSection(isDark, isTablet, isDesktop),
        ],
      ),
    );
  }

  // ── Field Builder ──────────────────────────────────────
  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? type,
    int maxLines = 1,
    required bool isDark,
    required bool isTablet,
    required bool isDesktop,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 12.0 : (isTablet ? 11.0 : 10.0),
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        _isEditing
            ? TextFormField(
                controller: controller,
                keyboardType: type,
                maxLines: maxLines,
                style: TextStyle(
                  fontSize: isDesktop ? 15.0 : (isTablet ? 14.0 : 13.0),
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  prefixIcon: maxLines == 1
                      ? Icon(icon, size: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0), color: context.colors.textSecondary)
                      : null,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: maxLines > 1 ? 12.0 : 0,
                    vertical: 10.0,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.04)
                      : context.colors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.colors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : context.colors.divider,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.professionalColor,
                      width: 1.5,
                    ),
                  ),
                ),
              )
            : Row(
                crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: isDesktop ? 18.0 : (isTablet ? 17.0 : 16.0),
                    color: context.colors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      controller.text.isEmpty ? 'Not set' : controller.text,
                      style: TextStyle(
                        fontSize: isDesktop ? 15.0 : (isTablet ? 14.0 : 13.0),
                        color: controller.text.isEmpty
                            ? context.colors.textSecondary.withOpacity(0.5)
                            : context.colors.textPrimary,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  // ── Skills Section ─────────────────────────────────────
  Widget _buildSkillsSection(bool isDark, bool isTablet, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skills',
          style: TextStyle(
            fontSize: isDesktop ? 12.0 : (isTablet ? 11.0 : 10.0),
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        if (_skills.isEmpty && !_isEditing)
          Text(
            'No skills added yet',
            style: TextStyle(
              fontSize: isDesktop ? 14.0 : (isTablet ? 13.0 : 12.0),
              color: context.colors.textSecondary.withOpacity(0.5),
              fontWeight: FontWeight.w400,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._skills.map((skill) => Chip(
                    label: Text(
                      skill,
                      style: TextStyle(
                        fontSize: isDesktop ? 13.0 : (isTablet ? 12.0 : 11.0),
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF818CF8) : AppColors.professionalColor,
                      ),
                    ),
                    backgroundColor: isDark
                        ? const Color(0xFF4C1D95).withOpacity(0.2)
                        : const Color(0xFFF5F3FF),
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF818CF8).withOpacity(0.2)
                          : const Color(0xFFDDD6FE),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    deleteIcon: _isEditing
                        ? Icon(
                            Icons.close_rounded,
                            size: isDesktop ? 16.0 : (isTablet ? 15.0 : 14.0),
                            color: isDark ? const Color(0xFF818CF8) : AppColors.professionalColor,
                          )
                        : null,
                    onDeleted: _isEditing ? () => _removeSkill(skill) : null,
                  )),
              if (_isEditing)
                SizedBox(
                  width: isDesktop ? 180.0 : (isTablet ? 160.0 : 140.0),
                  child: TextField(
                    controller: _skillInputController,
                    onSubmitted: _addSkill,
                    style: TextStyle(
                      fontSize: isDesktop ? 13.0 : (isTablet ? 12.0 : 11.0),
                      color: context.colors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: '+ Add skill',
                      hintStyle: TextStyle(
                        fontSize: isDesktop ? 13.0 : (isTablet ? 12.0 : 11.0),
                        color: context.colors.textSecondary.withOpacity(0.5),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.04)
                          : context.colors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : context.colors.divider,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : context.colors.divider,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: AppColors.professionalColor,
                          width: 1.5,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.add_circle_rounded,
                          size: isDesktop ? 20.0 : (isTablet ? 19.0 : 18.0),
                          color: AppColors.professionalColor,
                        ),
                        onPressed: () => _addSkill(_skillInputController.text),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  // ── Languages Section ──────────────────────────────────
  Widget _buildLanguagesSection(bool isDark, bool isTablet, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Languages',
          style: TextStyle(
            fontSize: isDesktop ? 12.0 : (isTablet ? 11.0 : 10.0),
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        if (_languages.isEmpty && !_isEditing)
          Text(
            'No languages added yet',
            style: TextStyle(
              fontSize: isDesktop ? 14.0 : (isTablet ? 13.0 : 12.0),
              color: context.colors.textSecondary.withOpacity(0.5),
              fontWeight: FontWeight.w400,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._languages.map((lang) => Chip(
                    label: Text(
                      lang,
                      style: TextStyle(
                        fontSize: isDesktop ? 13.0 : (isTablet ? 12.0 : 11.0),
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                      ),
                    ),
                    backgroundColor: isDark
                        ? const Color(0xFF065F46).withOpacity(0.2)
                        : const Color(0xFFECFDF5),
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF34D399).withOpacity(0.2)
                          : const Color(0xFFA7F3D0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    deleteIcon: _isEditing
                        ? Icon(
                            Icons.close_rounded,
                            size: isDesktop ? 16.0 : (isTablet ? 15.0 : 14.0),
                            color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                          )
                        : null,
                    onDeleted: _isEditing ? () => _removeLanguage(lang) : null,
                  )),
              if (_isEditing)
                SizedBox(
                  width: isDesktop ? 180.0 : (isTablet ? 160.0 : 140.0),
                  child: TextField(
                    controller: _languageInputController,
                    onSubmitted: _addLanguage,
                    style: TextStyle(
                      fontSize: isDesktop ? 13.0 : (isTablet ? 12.0 : 11.0),
                      color: context.colors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: '+ Add language',
                      hintStyle: TextStyle(
                        fontSize: isDesktop ? 13.0 : (isTablet ? 12.0 : 11.0),
                        color: context.colors.textSecondary.withOpacity(0.5),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.04)
                          : context.colors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : context.colors.divider,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : context.colors.divider,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Color(0xFF059669),
                          width: 1.5,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.add_circle_rounded,
                          size: isDesktop ? 20.0 : (isTablet ? 19.0 : 18.0),
                          color: const Color(0xFF059669),
                        ),
                        onPressed: () => _addLanguage(_languageInputController.text),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  // ── Bank Details Card ──────────────────────────────────
  Widget _buildBankDetailsCard(bool isDark, bool isTablet, bool isDesktop) {
    final hasBankDetails = _bankAccountNumberController.text.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0)),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0)),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.1)
                : Colors.grey.withOpacity(0.04),
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
                Icons.account_balance_outlined,
                size: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
                color: AppColors.professionalColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Bank Details',
                style: TextStyle(
                  fontSize: isDesktop ? 16.0 : (isTablet ? 15.0 : 14.0),
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              if (!_isEditing)
                Icon(
                  Icons.lock_outline_rounded,
                  size: isDesktop ? 18.0 : (isTablet ? 17.0 : 16.0),
                  color: context.colors.textSecondary.withOpacity(0.4),
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (!_isEditing)
            Text(
              hasBankDetails ? 'Used for withdrawal payouts' : 'Add bank details to enable withdrawals',
              style: TextStyle(
                fontSize: isDesktop ? 13.0 : (isTablet ? 12.0 : 11.0),
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
          const SizedBox(height: 16),
          _buildField('Bank Name', _bankNameController, Icons.business_outlined,
              isDark: isDark, isTablet: isTablet, isDesktop: isDesktop),
          const SizedBox(height: 14),
          _buildField('Account Holder', _bankAccountNameController, Icons.person_outline_rounded,
              isDark: isDark, isTablet: isTablet, isDesktop: isDesktop),
          const SizedBox(height: 14),
          _isEditing
              ? _buildField('Account Number', _bankAccountNumberController, Icons.numbers_rounded,
                  type: TextInputType.number, isDark: isDark, isTablet: isTablet, isDesktop: isDesktop)
              : _buildMaskedField('Account Number', _bankAccountNumberController.text, Icons.numbers_rounded,
                  isDark: isDark, isTablet: isTablet, isDesktop: isDesktop),
        ],
      ),
    );
  }

  Widget _buildMaskedField(
    String label,
    String value,
    IconData icon, {
    required bool isDark,
    required bool isTablet,
    required bool isDesktop,
  }) {
    final masked = value.length > 4
        ? '•••• •••• ${value.substring(value.length - 4)}'
        : (value.isEmpty ? 'Not set' : value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 12.0 : (isTablet ? 11.0 : 10.0),
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              icon,
              size: isDesktop ? 18.0 : (isTablet ? 17.0 : 16.0),
              color: context.colors.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              masked,
              style: TextStyle(
                fontSize: isDesktop ? 15.0 : (isTablet ? 14.0 : 13.0),
                letterSpacing: value.isEmpty ? 0 : 1.2,
                color: value.isEmpty
                    ? context.colors.textSecondary.withOpacity(0.5)
                    : context.colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Account Actions ────────────────────────────────────
  Widget _buildAccountActions(AuthProvider auth, bool isDark, bool isTablet, bool isDesktop) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0)),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.grey.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Builder(builder: (context) {
              final themeProvider = context.watch<ThemeProvider>();
              return Column(
                children: [
                  SwitchListTile(
                    secondary: Icon(
                      Icons.dark_mode_rounded,
                      size: isDesktop ? 22.0 : (isTablet ? 20.0 : 18.0),
                      color: AppColors.professionalColor,
                    ),
                    title: Text(
                      'Dark Mode',
                      style: TextStyle(
                        fontSize: isDesktop ? 15.0 : (isTablet ? 14.0 : 13.0),
                        fontWeight: FontWeight.w500,
                        color: context.colors.textPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    subtitle: Text(
                      themeProvider.isDarkMode ? 'On' : 'Off',
                      style: TextStyle(
                        fontSize: isDesktop ? 13.0 : (isTablet ? 12.0 : 11.0),
                        color: context.colors.textSecondary,
                      ),
                    ),
                    value: themeProvider.isDarkMode,
                    activeColor: AppColors.professionalColor,
                    activeTrackColor: AppColors.professionalColor.withOpacity(0.35),
                    inactiveThumbColor: context.colors.textSecondary,
                    inactiveTrackColor: context.colors.divider,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
                    ),
                    onChanged: (v) => context.read<ThemeProvider>().toggleTheme(),
                  ),
                  Divider(height: 1, indent: 56, color: context.colors.divider),
                ],
              );
            }),
            _buildMenuItem(
              icon: Icons.photo_library_outlined,
              title: 'My Portfolio',
              color: AppColors.professionalColor,
              isDark: isDark,
              isTablet: isTablet,
              isDesktop: isDesktop,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfessionalPortfolioScreen()),
              ),
            ),
            Divider(height: 1, indent: 56, color: context.colors.divider),
            _buildMenuItem(
              icon: Icons.card_membership_outlined,
              title: 'Certificates',
              isDark: isDark,
              isTablet: isTablet,
              isDesktop: isDesktop,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfessionalCertificatesScreen()),
              ),
            ),
            Divider(height: 1, indent: 56, color: context.colors.divider),
            _buildMenuItem(
              icon: Icons.photo_outlined,
              title: 'Gallery',
              isDark: isDark,
              isTablet: isTablet,
              isDesktop: isDesktop,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfessionalGalleryScreen()),
              ),
            ),
            Divider(height: 1, indent: 56, color: context.colors.divider),
            _buildMenuItem(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Wallet & Earnings',
              color: const Color(0xFF059669),
              isDark: isDark,
              isTablet: isTablet,
              isDesktop: isDesktop,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfessionalWalletScreen()),
              ),
            ),
            Divider(height: 1, indent: 56, color: context.colors.divider),
            _buildMenuItem(
              icon: Icons.workspace_premium_rounded,
              title: 'Subscription / Upgrade to Premium',
              isDark: isDark,
              isTablet: isTablet,
              isDesktop: isDesktop,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen(userRole: 'professional')),
              ),
            ),
            Divider(height: 1, indent: 56, color: context.colors.divider),
            _buildMenuItem(
              icon: Icons.lock_outline_rounded,
              title: 'Change Password',
              isDark: isDark,
              isTablet: isTablet,
              isDesktop: isDesktop,
              onTap: () => showDialog(
                context: context,
                builder: (_) => const ChangePasswordDialog(),
              ),
            ),
            Divider(height: 1, indent: 56, color: context.colors.divider),
            _buildMenuItem(
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
              isDark: isDark,
              isTablet: isTablet,
              isDesktop: isDesktop,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
              ),
            ),
            Divider(height: 1, indent: 56, color: context.colors.divider),
            _buildMenuItem(
              icon: Icons.info_outline_rounded,
              title: 'About',
              isDark: isDark,
              isTablet: isTablet,
              isDesktop: isDesktop,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              ),
            ),
            Divider(height: 1, indent: 56, color: context.colors.divider),
            _buildMenuItem(
              icon: Icons.logout_rounded,
              title: 'Logout',
              color: AppColors.error,
              isDark: isDark,
              isTablet: isTablet,
              isDesktop: isDesktop,
              showArrow: false,
              onTap: () => _confirmLogout(auth),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isDark,
    required bool isTablet,
    required bool isDesktop,
    required VoidCallback onTap,
    Color? color,
    bool showArrow = true,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: isDesktop ? 22.0 : (isTablet ? 20.0 : 18.0),
        color: color ?? context.colors.textPrimary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: isDesktop ? 15.0 : (isTablet ? 14.0 : 13.0),
          fontWeight: FontWeight.w500,
          color: color ?? context.colors.textPrimary,
          letterSpacing: 0.2,
        ),
      ),
      trailing: showArrow
          ? Icon(
              Icons.arrow_forward_ios_rounded,
              size: isDesktop ? 16.0 : (isTablet ? 15.0 : 13.0),
              color: context.colors.textSecondary.withOpacity(0.4),
            )
          : null,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
        vertical: 4.0,
      ),
      onTap: onTap,
    );
  }

  void _confirmLogout(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: context.colors.surface,
        title: Text(
          'Logout?',
          style: TextStyle(
            fontSize: 17.0,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            fontSize: 14.0,
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
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