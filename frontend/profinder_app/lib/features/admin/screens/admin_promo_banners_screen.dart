// lib/features/admin/screens/admin_promo_banners_screen.dart
//
// Admin — Promo Banner Management
// Backend endpoints (UNCHANGED):
//   GET    /api/admin-panel/promo-banners/                → all banners
//   POST   /api/admin-panel/promo-banners/                → create banner
//   PATCH  /api/admin-panel/promo-banners/<id>/            → update
//   DELETE /api/admin-panel/promo-banners/<id>/            → delete
//   POST   /api/admin-panel/promo-banners/upload-image/    → gallery upload
//
// Admins can create/edit/delete/activate banners entirely from the Flutter
// app — no Django admin trip required.

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../subscription/models/promo_banner_model.dart';
import '../../subscription/widgets/promo_banner_popup.dart';
import '../../../shared/widgets/universal_app_bar.dart';

/// Responsive breakpoints used by the banner grid and dialogs.
class _Breakpoints {
  static const double tablet = 700;
  static const double desktop = 1100;
}

class AdminPromoBannersScreen extends StatefulWidget {
  const AdminPromoBannersScreen({super.key});

  @override
  State<AdminPromoBannersScreen> createState() =>
      _AdminPromoBannersScreenState();
}

class _AdminPromoBannersScreenState extends State<AdminPromoBannersScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final _picker = ImagePicker();

  bool _loading = true;
  String? _error;
  List<dynamic> _banners = [];

  /// Drives a staggered entrance for banner cards whenever the list reloads.
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  static const _targetChoices = [
    ('everyone', 'Everyone'),
    ('guest', 'Guest Only'),
    ('free_customer', 'Free Customer'),
    ('premium_customer', 'Premium Customer'),
    ('free_professional', 'Free Professional'),
    ('premium_professional', 'Premium Professional'),
    ('all_customers', 'All Customers'),
    ('all_professionals', 'All Professionals'),
  ];

  static const _triggerChoices = [
    ('app_open', 'App Open'),
    ('home', 'Home Page'),
    ('search', 'Search Page'),
    ('ai_search', 'AI Search'),
    ('booking', 'Booking'),
    ('login', 'After Login'),
    ('every_x_days', 'Every X Days'),
  ];

  /// Plain-language explanation shown under the Trigger dropdown so admins
  /// know exactly where/when each trigger shows the banner.
  static const _triggerHelp = {
    'app_open':
        'Shows the very first time the app opens on any screen (home, search, booking, etc).',
    'home': 'Shows only on the Home screen.',
    'search': 'Shows only on the Search screen.',
    'ai_search': 'Shows when a user turns on AI Search mode.',
    'booking':
        'Shows on the Bookings screen — for both customers and professionals.',
    'login':
        'Shows once, right after a user logs in (on the screen they land on).',
    'every_x_days':
        'Shows on any screen, repeating every X days (set below) instead of every visit.',
  };

  static const _linkTypeChoices = [
    ('subscription', 'Subscription Page'),
    ('category', 'Specific Category'),
    ('external_url', 'External URL'),
    ('offer', 'Offer Page'),
    ('none', 'No Action'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  /// Fetches the banner list. Behavior unchanged from the original.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.get('/admin-panel/promo-banners/');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _banners = res.data is List ? List<dynamic>.from(res.data) : [];
      });
      _entranceController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load banners';
      });
    }
  }

  // ── Toggle Active ──────────────────────────────────────────
  /// Flips the banner's `is_active` flag and replaces the item in-place.
  Future<void> _toggleActive(dynamic banner) async {
    try {
      final res = await _api.patch(
        '/admin-panel/promo-banners/${banner['id']}/',
        {'is_active': !(banner['is_active'] ?? false)},
      );
      if (!mounted) return;
      setState(() {
        final idx = _banners.indexWhere((b) => b['id'] == banner['id']);
        if (idx != -1) _banners[idx] = res.data;
      });
    } catch (e) {
      _showSnack('Update failed. Try again.', AppColors.error);
    }
  }

  // ── Delete ────────────────────────────────────────────────
  /// Confirms then permanently deletes a banner.
  Future<void> _delete(dynamic banner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 18),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Delete this banner?',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          '"${banner['title']}" will be permanently deleted.',
          style: const TextStyle(
              fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _api.delete('/admin-panel/promo-banners/${banner['id']}/');
      if (!mounted) return;
      setState(() => _banners.removeWhere((b) => b['id'] == banner['id']));
      _showSnack('Banner deleted', AppColors.error);
    } catch (e) {
      _showSnack('Delete failed. Try again.', AppColors.error);
    }
  }

  // ── Preview — exact same popup the user sees ─────────────────────────────
  /// Renders the user-facing popup in read-only mode with a PREVIEW MODE
  /// pill overlay so admins can verify appearance before publishing.
  void _previewBanner(dynamic b) {
    final banner = PromoBanner(
      id: b['id'] ?? 0,
      title: b['title'] ?? '',
      description: b['description'] ?? '',
      imageUrl: b['image_url'] ?? '',
      buttonText: b['button_text'] ?? 'Get Premium',
      buttonLinkType: b['button_link_type'] ?? 'none',
      buttonLinkValue: b['button_link_value'] ?? '',
      targetAudience: b['target_audience'] ?? 'everyone',
      trigger: b['trigger'] ?? 'home',
      triggerXDays: b['trigger_x_days'] ?? 3,
      isActive: b['is_active'] ?? false,
      priority: b['priority'] ?? 0,
    );

    // Wrapped in `Dialog` (not bare `Stack`) so it centers exactly like the
    // real user-facing popup — matches `PromoBannerPopup.show()`.
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            PromoBannerPopup(banner: banner, userRole: 'customer'),
            Positioned(
              top: -14,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.adminColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  // Emoji replaced with a proper Flutter icon.
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_rounded,
                          color: Colors.white, size: 13),
                      SizedBox(width: 6),
                      Text(
                        'PREVIEW MODE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Add / Edit Form ──────────────────────────────────────────
  /// Opens the create/edit dialog. All field controllers, validators, image
  /// upload flow, and save logic remain behaviorally identical.
  Future<void> _openForm({dynamic existing}) async {
    final isEdit = existing != null;

    final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
    final descCtrl =
        TextEditingController(text: existing?['description'] ?? '');
    final imageCtrl =
        TextEditingController(text: existing?['image_url'] ?? '');
    final buttonTextCtrl =
        TextEditingController(text: existing?['button_text'] ?? 'Get Premium');
    final linkValueCtrl =
        TextEditingController(text: existing?['button_link_value'] ?? '');
    final priorityCtrl =
        TextEditingController(text: (existing?['priority'] ?? 0).toString());
    final xDaysCtrl = TextEditingController(
        text: (existing?['trigger_x_days'] ?? 3).toString());

    String targetAudience = existing?['target_audience'] ?? 'everyone';
    String trigger = existing?['trigger'] ?? 'home';
    String linkType = existing?['button_link_type'] ?? 'subscription';
    bool isActive = existing?['is_active'] ?? true;
    DateTime? startDate = existing?['start_date'] != null
        ? DateTime.tryParse(existing['start_date'])
        : null;
    DateTime? endDate = existing?['end_date'] != null
        ? DateTime.tryParse(existing['end_date'])
        : null;

    bool saving = false;
    bool uploadingImage = false;
    String? dialogError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> pickDate(bool isStart) async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: ctx,
              initialDate: (isStart ? startDate : endDate) ?? now,
              firstDate: now.subtract(const Duration(days: 365)),
              lastDate: now.add(const Duration(days: 365)),
            );
            if (picked != null) {
              setDialogState(() {
                if (isStart) {
                  startDate = picked;
                } else {
                  endDate = picked;
                }
              });
            }
          }

          /// Picks an image from the gallery, uploads it, and writes the
          /// returned URL straight into `imageCtrl`. Behavior unchanged.
          Future<void> pickImageFromGallery() async {
            final picked = await _picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 85,
            );
            if (picked == null) return;

            setDialogState(() => uploadingImage = true);
            try {
              dio.MultipartFile multipart;
              if (kIsWeb) {
                final bytes = await picked.readAsBytes();
                multipart = dio.MultipartFile.fromBytes(bytes,
                    filename: picked.name);
              } else {
                multipart = await dio.MultipartFile.fromFile(picked.path,
                    filename: picked.name);
              }
              final formData = dio.FormData.fromMap({'image': multipart});
              final res = await _api.postForm(
                  '/admin-panel/promo-banners/upload-image/', formData);
              imageCtrl.text = res.data['url'] ?? '';
              setDialogState(() => uploadingImage = false);
            } catch (e) {
              setDialogState(() {
                uploadingImage = false;
                dialogError = 'Image upload failed. Try again.';
              });
            }
          }

          /// Validates + submits the banner body. Behavior unchanged.
          Future<void> save() async {
            if (titleCtrl.text.trim().isEmpty ||
                descCtrl.text.trim().isEmpty) {
              setDialogState(
                  () => dialogError = 'Title and description are required');
              return;
            }
            setDialogState(() {
              saving = true;
              dialogError = null;
            });

            final body = {
              'title': titleCtrl.text.trim(),
              'description': descCtrl.text.trim(),
              'image_url': imageCtrl.text.trim(),
              'button_text': buttonTextCtrl.text.trim().isEmpty
                  ? 'Get Premium'
                  : buttonTextCtrl.text.trim(),
              'button_link_type': linkType,
              'button_link_value': linkValueCtrl.text.trim(),
              'target_audience': targetAudience,
              'trigger': trigger,
              'trigger_x_days': int.tryParse(xDaysCtrl.text) ?? 3,
              'is_active': isActive,
              'priority': int.tryParse(priorityCtrl.text) ?? 0,
              'start_date': startDate?.toIso8601String(),
              'end_date': endDate?.toIso8601String(),
            };

            try {
              if (isEdit) {
                final res = await _api.patch(
                    '/admin-panel/promo-banners/${existing['id']}/', body);
                final idx = _banners
                    .indexWhere((b) => b['id'] == existing['id']);
                if (idx != -1 && mounted) {
                  setState(() => _banners[idx] = res.data);
                }
              } else {
                final res =
                    await _api.post('/admin-panel/promo-banners/', body);
                if (mounted) setState(() => _banners.insert(0, res.data));
              }
              if (mounted) Navigator.pop(ctx);
              _showSnack(
                  isEdit ? 'Banner updated' : 'Banner created',
                  AppColors.success);
            } catch (e) {
              // Surface the backend's actual validation error when possible.
              String msg = 'Save failed. Please check all fields.';
              try {
                final responseData = (e as dynamic).response?.data;
                if (responseData is Map) {
                  final parts = <String>[];
                  responseData.forEach((key, value) {
                    if (value is List && value.isNotEmpty) {
                      parts.add('$key: ${value.first}');
                    } else if (value is String) {
                      parts.add('$key: $value');
                    }
                  });
                  if (parts.isNotEmpty) msg = parts.join('\n');
                }
              } catch (_) {}
              setDialogState(() {
                saving = false;
                dialogError = msg;
              });
            }
          }

          // Dynamic dialog sizing: subtracts keyboard inset so Cancel/Create
          // buttons never end up behind the keyboard on mobile. This is the
          // exact same calculation as the original — logic preserved.
          final mq = MediaQuery.of(ctx);
          final keyboardHeight = mq.viewInsets.bottom;
          final availableHeight =
              mq.size.height - keyboardHeight - 48; // 48 = top/bottom margin
          final dialogMaxHeight = availableHeight.clamp(280.0, 640.0);
          final dialogMaxWidth =
              mq.size.width > 520 ? 480.0 : mq.size.width - 32;

          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            insetPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: (keyboardHeight > 0 ? 12 : 24),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: dialogMaxWidth, maxHeight: dialogMaxHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ──────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.adminColor, Color(0xFFB91C1C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isEdit
                                ? Icons.edit_outlined
                                : Icons.add_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isEdit ? 'Edit Banner' : 'Create New Banner',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Body ────────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Inline error — visible inside the dialog, never
                          // hidden behind it. Surfaces the actual backend
                          // validation message when available.
                          if (dialogError != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color:
                                        AppColors.error.withOpacity(0.35)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      color: AppColors.error, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      dialogError!,
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setDialogState(
                                        () => dialogError = null),
                                    child: const Icon(Icons.close_rounded,
                                        color: AppColors.error, size: 16),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // ── Section: Content ────────────────
                          _sectionLabel('Content'),
                          const SizedBox(height: 8),
                          _field('Title', titleCtrl),
                          const SizedBox(height: 12),
                          _field('Description', descCtrl, maxLines: 3),
                          const SizedBox(height: 14),

                          // Image preview + gallery picker.
                          _buildImageTile(
                            imageUrl: imageCtrl.text.trim(),
                            uploading: uploadingImage,
                            onPick: uploadingImage
                                ? null
                                : pickImageFromGallery,
                          ),
                          const SizedBox(height: 8),
                          _field('Image URL (optional)', imageCtrl),
                          const SizedBox(height: 12),
                          _field('Button Text', buttonTextCtrl),
                          const SizedBox(height: 14),

                          // ── Section: Behavior ───────────────
                          _sectionLabel('Behavior'),
                          const SizedBox(height: 8),
                          _dropdown('Button Link Type', linkType,
                              _linkTypeChoices,
                              (v) => setDialogState(() => linkType = v)),
                          const SizedBox(height: 12),
                          _field('Button Link Value (URL or category id)',
                              linkValueCtrl),
                          const SizedBox(height: 12),
                          _dropdown('Target Audience', targetAudience,
                              _targetChoices,
                              (v) => setDialogState(
                                  () => targetAudience = v)),
                          const SizedBox(height: 12),
                          _dropdown('Trigger', trigger, _triggerChoices,
                              (v) => setDialogState(() => trigger = v)),
                          const SizedBox(height: 6),
                          Text(
                            _triggerHelp[trigger] ?? '',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9CA3AF),
                                height: 1.4),
                          ),
                          const SizedBox(height: 12),

                          if (trigger == 'every_x_days') ...[
                            _field('Show every X days', xDaysCtrl,
                                isNumber: true),
                            const SizedBox(height: 12),
                          ],

                          _field('Priority (higher = shows first)',
                              priorityCtrl,
                              isNumber: true),
                          const SizedBox(height: 14),

                          // ── Section: Schedule ───────────────
                          _sectionLabel('Schedule'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _dateTile('Start Date', startDate,
                                    () => pickDate(true)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _dateTile('End Date', endDate,
                                    () => pickDate(false)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: isActive,
                            onChanged: (v) =>
                                setDialogState(() => isActive = v),
                            activeColor: AppColors.adminColor,
                            title: const Text('Active',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            subtitle: const Text(
                                'Turning this off hides the banner from everyone',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF9CA3AF))),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Sticky action bar ────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9FAFB),
                      border: Border(
                          top: BorderSide(color: Color(0xFFE5E7EB))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                saving ? null : () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 46),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.adminColor,
                              minimumSize: const Size(0, 46),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: saving ? null : save,
                            child: saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : Text(
                                    isEdit ? 'Save Changes' : 'Create Banner',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Compact section heading used to group form fields in the dialog.
  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.adminColor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  /// Image preview tile with a pick-from-gallery action. Shows an empty
  /// placeholder when no image URL is set yet.
  Widget _buildImageTile({
    required String imageUrl,
    required bool uploading,
    required VoidCallback? onPick,
  }) {
    final hasImage = imageUrl.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          clipBehavior: Clip.hardEdge,
          child: hasImage
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Color(0xFFD1D5DB),
                    size: 28,
                  ),
                )
              : const Icon(
                  Icons.image_outlined,
                  color: Color(0xFFD1D5DB),
                  size: 28,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Banner Image',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Recommended: 1200×600, JPG or PNG',
                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onPick,
                icon: uploading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.photo_library_outlined, size: 15),
                label: Text(
                  uploading ? 'Uploading…' : 'Pick from Gallery',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.adminColor,
                  side: const BorderSide(color: AppColors.adminColor),
                  minimumSize: const Size(0, 40),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Standard text field used across the dialog. Single or multi-line.
  Widget _field(String label, TextEditingController ctrl,
      {int maxLines = 1, bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
    );
  }

  /// Dropdown helper matching the `_field` styling.
  Widget _dropdown(String label, String value, List<(String, String)> choices,
      ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
      items: choices
          .map((c) => DropdownMenuItem(
              value: c.$1,
              child: Text(c.$2, style: const TextStyle(fontSize: 13))))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  /// Tappable date picker tile used for start/end dates.
  Widget _dateTile(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 14, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date == null
                    ? '$label (optional)'
                    : DateFormat('dd MMM yyyy').format(date),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: date == null
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF111827),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: UniversalAppBar(
        title: 'Promo Banners',
        subtitle: '${_banners.length} ${_banners.length == 1 ? 'banner' : 'banners'}',
        icon: Icons.campaign_rounded,
        showBack: false,
        actions: [
          AppBarIconButton(icon: Icons.refresh_rounded, tooltip: 'Refresh', onPressed: _load, onGradient: true),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin_promo_banners_fab',
        backgroundColor: AppColors.adminColor,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Banner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _loading
            ? const Center(
                key: ValueKey('loader'),
                child: CircularProgressIndicator(
                    color: AppColors.adminColor, strokeWidth: 2.5),
              )
            : _error != null
                ? _buildError()
                : _banners.isEmpty
                    ? _buildEmpty()
                    : _buildBannerList(),
      ),
    );
  }

  /// Responsive list/grid of banner cards. 1 col mobile / 2 tablet / 3
  /// desktop. Content is centered with a soft max-width on ultra-wide.
  Widget _buildBannerList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTablet = width >= _Breakpoints.tablet;
        final isDesktop = width >= _Breakpoints.desktop;
        final columns = isDesktop ? 3 : (isTablet ? 2 : 1);
        final hPad = isDesktop ? 24.0 : (isTablet ? 20.0 : 12.0);

        return RefreshIndicator(
          onRefresh: _load,
          color: AppColors.adminColor,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: GridView.builder(
                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 96),
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 300,
                ),
                itemCount: _banners.length,
                itemBuilder: (_, i) =>
                    _buildAnimatedBannerCard(_banners[i], i),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Wraps each banner card in a staggered fade+slide entrance.
  Widget _buildAnimatedBannerCard(dynamic banner, int index) {
    final delayIndex = index.clamp(0, 8);
    final start = (delayIndex * 0.06).clamp(0.0, 0.48);
    final end = (start + 0.4).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(anim),
        child: _buildBannerCard(banner),
      ),
    );
  }

  /// Card showing banner thumbnail, title/description, metadata chips,
  /// live status badge, active toggle, and action buttons.
  Widget _buildBannerCard(dynamic banner) {
    final isActive = banner['is_active'] ?? false;
    final isLive = banner['is_currently_active'] ?? false;
    final title = banner['title'] ?? '';
    final desc = banner['description'] ?? '';
    final target = banner['target_audience'] ?? '';
    final trigger = banner['trigger'] ?? '';
    final priority = banner['priority'] ?? 0;
    final imageUrl = banner['image_url']?.toString() ?? '';
    final startDate = banner['start_date'] != null
        ? DateTime.tryParse(banner['start_date'])
        : null;
    final endDate = banner['end_date'] != null
        ? DateTime.tryParse(banner['end_date'])
        : null;

    return _HoverLift(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ──────────────────────────────
            Stack(
              children: [
                SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFF3F4F6),
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined,
                                  color: Color(0xFFD1D5DB), size: 32),
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.adminColor.withOpacity(0.06),
                          child: Center(
                            child: Icon(
                              Icons.campaign_outlined,
                              color:
                                  AppColors.adminColor.withOpacity(0.35),
                              size: 36,
                            ),
                          ),
                        ),
                ),
                // Bottom veil for badge legibility.
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.18),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                // Live status badge.
                Positioned(
                  top: 8,
                  right: 8,
                  child: _BannerStatusBadge(
                    isActive: isActive,
                    isLive: isLive,
                    startDate: startDate,
                    endDate: endDate,
                  ),
                ),
              ],
            ),

            // ── Body ──────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _chip(Icons.group_outlined, target,
                            const Color(0xFF7C3AED)),
                        _chip(Icons.bolt_outlined, trigger,
                            const Color(0xFF0EA5E9)),
                        _chip(Icons.low_priority_rounded,
                            'priority $priority', const Color(0xFFF59E0B)),
                      ],
                    ),
                    const Spacer(),

                    // ── Footer: active toggle + actions ────
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFF3F4F6)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Semantics(
                            label: 'Toggle banner active',
                            child: Switch(
                              value: isActive,
                              activeColor: AppColors.adminColor,
                              onChanged: (_) => _toggleActive(banner),
                            ),
                          ),
                          Text(
                            isActive ? 'Active' : 'Paused',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? AppColors.success
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                          const Spacer(),
                          _actionIcon(
                            icon: Icons.visibility_outlined,
                            color: AppColors.adminColor,
                            tooltip: 'Preview',
                            onTap: () => _previewBanner(banner),
                          ),
                          _actionIcon(
                            icon: Icons.edit_outlined,
                            color: const Color(0xFF374151),
                            tooltip: 'Edit',
                            onTap: () => _openForm(existing: banner),
                          ),
                          _actionIcon(
                            icon: Icons.delete_outline_rounded,
                            color: AppColors.error,
                            tooltip: 'Delete',
                            onTap: () => _delete(banner),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Small rounded icon button used in the card footer actions.
  Widget _actionIcon({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          margin: const EdgeInsets.only(left: 2),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  /// Metadata chip with icon + label. `_` in the label becomes a space so
  /// enums read naturally (e.g. `free_customer` → `free customer`).
  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label.replaceAll('_', ' '),
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ── Empty / Error ────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      key: const ValueKey('empty'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.adminColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign_outlined,
                  size: 42, color: AppColors.adminColor),
            ),
            const SizedBox(height: 16),
            const Text(
              'No banners yet',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap "New Banner" to create your first one',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 14),
            const Text(
              'Failed to load banners',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151)),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Floating snackbar tinted by the outcome of the action.
  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }
}

// ── Reusable UI primitives ────────────────────────────────────────────────

/// Subtle scale-on-hover for pointer devices. No-op on touch because
/// [MouseRegion] enter/exit never fire from touch input.
class _HoverLift extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final double hoverScale;

  const _HoverLift({
    required this.child,
    required this.borderRadius,
    this.hoverScale = 1.012,
  });

  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (!mounted || _hovered) return;
        setState(() => _hovered = true);
      },
      onExit: (_) {
        if (!mounted || !_hovered) return;
        setState(() => _hovered = false);
      },
      child: AnimatedScale(
        scale: _hovered ? widget.hoverScale : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ── Live status badge ──────────────────────────────────────────────────────
//
// Renders the banner's current lifecycle state:
//   • OFF        → switch is disabled
//   • Starts on  → active but start_date is in the future
//   • Ends in X  → live with an end_date — countdown refreshes every minute
//   • LIVE       → live without an end_date
//   • Ended      → active but end_date has passed
//   • Inactive   → fallback edge case
class _BannerStatusBadge extends StatefulWidget {
  final bool isActive;
  final bool isLive;
  final DateTime? startDate;
  final DateTime? endDate;

  const _BannerStatusBadge({
    required this.isActive,
    required this.isLive,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<_BannerStatusBadge> createState() => _BannerStatusBadgeState();
}

class _BannerStatusBadgeState extends State<_BannerStatusBadge> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Only tick while a countdown is actually displayed — avoids
    // battery/CPU waste for banners that don't need it.
    if (widget.isActive && widget.isLive && widget.endDate != null) {
      _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatRemaining(Duration d) {
    if (d.isNegative) return 'Ending…';
    if (d.inDays >= 1) return '${d.inDays}d ${d.inHours % 24}h left';
    if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes % 60}m left';
    if (d.inMinutes >= 1) return '${d.inMinutes}m left';
    return '<1m left';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    String label;
    Color color;
    IconData icon;

    if (!widget.isActive) {
      label = 'OFF';
      color = const Color(0xFF9CA3AF);
      icon = Icons.pause_circle_outline_rounded;
    } else if (widget.isLive) {
      if (widget.endDate != null) {
        label =
            'Ends in ${_formatRemaining(widget.endDate!.difference(now))}';
      } else {
        label = 'LIVE';
      }
      color = AppColors.success;
      icon = Icons.bolt_rounded;
    } else if (widget.startDate != null && widget.startDate!.isAfter(now)) {
      label =
          'Starts ${DateFormat('d MMM, h:mm a').format(widget.startDate!)}';
      color = const Color(0xFFF59E0B);
      icon = Icons.schedule_rounded;
    } else if (widget.endDate != null && widget.endDate!.isBefore(now)) {
      label = 'Ended';
      color = const Color(0xFF9CA3AF);
      icon = Icons.history_rounded;
    } else {
      label = 'Inactive';
      color = const Color(0xFF9CA3AF);
      icon = Icons.info_outline_rounded;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}