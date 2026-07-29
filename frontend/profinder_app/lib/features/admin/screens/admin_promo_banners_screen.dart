// lib/features/admin/screens/admin_promo_banners_screen.dart
//
// Admin — Promo Banner Management
// Backend endpoints:
//   GET    /api/admin-panel/promo-banners/           → sab banners
//   POST   /api/admin-panel/promo-banners/           → new banner create
//   PATCH  /api/admin-panel/promo-banners/<id>/       → update
//   DELETE /api/admin-panel/promo-banners/<id>/       → delete
//
// Yahan se admin Flutter app ke andar hi banner create/edit/delete/
// activate-deactivate kar sakta hai — Django admin ki zaroorat nahi.

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

class AdminPromoBannersScreen extends StatefulWidget {
  const AdminPromoBannersScreen({super.key});

  @override
  State<AdminPromoBannersScreen> createState() => _AdminPromoBannersScreenState();
}

class _AdminPromoBannersScreenState extends State<AdminPromoBannersScreen> {
  final _api    = ApiService();
  final _picker = ImagePicker();

  bool          _loading = true;
  String?       _error;
  List<dynamic> _banners = [];

  static const _targetChoices = [
    ('everyone',             'Everyone'),
    ('guest',                'Guest Only'),
    ('free_customer',        'Free Customer'),
    ('premium_customer',     'Premium Customer'),
    ('free_professional',    'Free Professional'),
    ('premium_professional', 'Premium Professional'),
    ('all_customers',        'All Customers'),
    ('all_professionals',    'All Professionals'),
  ];

  static const _triggerChoices = [
    ('app_open',     'App Open'),
    ('home',         'Home Page'),
    ('search',       'Search Page'),
    ('ai_search',    'AI Search'),
    ('booking',      'Booking'),
    ('login',        'After Login'),
    ('every_x_days', 'Every X Days'),
  ];

  // ✅ NEW — har trigger ka plain explanation, form me dropdown ke neeche
  // dikhta hai taake admin ko confusion na ho ke kaunsa trigger kahan/kab
  // banner dikhata hai.
  static const _triggerHelp = {
    'app_open':     'Shows the very first time the app opens on any screen (home, search, booking, etc).',
    'home':         'Shows only on the Home screen.',
    'search':       'Shows only on the Search screen.',
    'ai_search':    'Shows when a user turns on AI Search mode.',
    'booking':      'Shows on the Bookings screen — for both customers and professionals.',
    'login':        'Shows once, right after a user logs in (on the screen they land on).',
    'every_x_days': 'Shows on any screen, repeating every X days (set below) instead of every visit.',
  };

  static const _linkTypeChoices = [
    ('subscription', 'Subscription Page'),
    ('category',     'Specific Category'),
    ('external_url', 'External URL'),
    ('offer',        'Offer Page'),
    ('none',         'No Action'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get('/admin-panel/promo-banners/');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _banners = res.data is List ? List<dynamic>.from(res.data) : [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load banners'; });
    }
  }

  // ── Toggle Active ──────────────────────────────────────────
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
  Future<void> _delete(dynamic banner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete this banner?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: Text('"${banner['title']}" will be permanently deleted.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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

  // ── Preview — exact wahi popup jo user ko dikhta hai ──────────────────────
  void _previewBanner(dynamic b) {
    final banner = PromoBanner(
      id:               b['id']                ?? 0,
      title:            b['title']             ?? '',
      description:      b['description']       ?? '',
      imageUrl:         b['image_url']         ?? '',
      buttonText:       b['button_text']       ?? 'Get Premium',
      buttonLinkType:   b['button_link_type']  ?? 'none',
      buttonLinkValue:  b['button_link_value'] ?? '',
      targetAudience:   b['target_audience']   ?? 'everyone',
      trigger:          b['trigger']           ?? 'home',
      triggerXDays:     b['trigger_x_days']    ?? 3,
      isActive:         b['is_active']         ?? false,
      priority:         b['priority']          ?? 0,
    );

    // Admin ke liye preview — actions fire nahi hongi (sirf UI dikhni hai)
    // ✅ FIX: Pehle 'Stack' seedha showDialog ko diya jaata tha — Dialog
    // widget na hone ki wajah se yeh CENTER mein nahi aata tha (top-left
    // ya random position pe render hota tha). Ab exact wahi 'Dialog' wrapper
    // use kiya hai jo asal user-facing PromoBannerPopup.show() use karta
    // hai — taake admin ko bhi banner bilkul center mein, users jaisa hi dikhe.
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:    const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            PromoBannerPopup(banner: banner, userRole: 'customer'),
            // Preview label — admin ko pata chale yeh preview mode hai
            Positioned(
              top: -14,
              left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.adminColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    '👁  PREVIEW MODE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
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
  Future<void> _openForm({dynamic existing}) async {
    final isEdit = existing != null;

    final titleCtrl       = TextEditingController(text: existing?['title'] ?? '');
    final descCtrl        = TextEditingController(text: existing?['description'] ?? '');
    final imageCtrl       = TextEditingController(text: existing?['image_url'] ?? '');
    final buttonTextCtrl  = TextEditingController(text: existing?['button_text'] ?? 'Get Premium');
    final linkValueCtrl   = TextEditingController(text: existing?['button_link_value'] ?? '');
    final priorityCtrl    = TextEditingController(text: (existing?['priority'] ?? 0).toString());
    final xDaysCtrl       = TextEditingController(text: (existing?['trigger_x_days'] ?? 3).toString());

    String targetAudience = existing?['target_audience'] ?? 'everyone';
    String trigger        = existing?['trigger']          ?? 'home';
    String linkType       = existing?['button_link_type'] ?? 'subscription';
    bool   isActive        = existing?['is_active'] ?? true;
    DateTime? startDate    = existing?['start_date'] != null ? DateTime.tryParse(existing['start_date']) : null;
    DateTime? endDate      = existing?['end_date']   != null ? DateTime.tryParse(existing['end_date'])   : null;

    bool saving         = false;
    bool uploadingImage = false;
    String? dialogError; // ✅ FIX: dialog ke andar hi error dikhao, SnackBar dialog ke peeche chup jaata tha

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
              lastDate:  now.add(const Duration(days: 365)),
            );
            if (picked != null) {
              setDialogState(() {
                if (isStart) startDate = picked; else endDate = picked;
              });
            }
          }

          // ✅ NEW — Gallery se image pick karo aur upload karo, URL
          // automatically Image URL field mein bhar jata hai. Optional —
          // chaho to seedha URL bhi type kar sakte ho.
          Future<void> pickImageFromGallery() async {
            final picked = await _picker.pickImage(
              source:        ImageSource.gallery,
              imageQuality:  85,
            );
            if (picked == null) return;

            setDialogState(() => uploadingImage = true);
            try {
              dio.MultipartFile multipart;
              if (kIsWeb) {
                final bytes = await picked.readAsBytes();
                multipart = dio.MultipartFile.fromBytes(bytes, filename: picked.name);
              } else {
                multipart = await dio.MultipartFile.fromFile(picked.path, filename: picked.name);
              }
              final formData = dio.FormData.fromMap({'image': multipart});
              final res = await _api.postForm(
                  '/admin-panel/promo-banners/upload-image/', formData);
              imageCtrl.text = res.data['url'] ?? '';
              setDialogState(() => uploadingImage = false);
            } catch (e) {
              setDialogState(() {
                uploadingImage = false;
                dialogError    = 'Image upload failed. Try again.';
              });
            }
          }

          Future<void> save() async {
            if (titleCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) {
              setDialogState(() => dialogError = 'Title and description are required');
              return;
            }
            setDialogState(() {
              saving      = true;
              dialogError = null;
            });

            final body = {
              'title':             titleCtrl.text.trim(),
              'description':       descCtrl.text.trim(),
              'image_url':         imageCtrl.text.trim(),
              'button_text':       buttonTextCtrl.text.trim().isEmpty ? 'Get Premium' : buttonTextCtrl.text.trim(),
              'button_link_type':  linkType,
              'button_link_value': linkValueCtrl.text.trim(),
              'target_audience':   targetAudience,
              'trigger':           trigger,
              'trigger_x_days':    int.tryParse(xDaysCtrl.text) ?? 3,
              'is_active':         isActive,
              'priority':          int.tryParse(priorityCtrl.text) ?? 0,
              'start_date':        startDate?.toIso8601String(),
              'end_date':          endDate?.toIso8601String(),
            };

            try {
              if (isEdit) {
                final res = await _api.patch('/admin-panel/promo-banners/${existing['id']}/', body);
                final idx = _banners.indexWhere((b) => b['id'] == existing['id']);
                if (idx != -1 && mounted) setState(() => _banners[idx] = res.data);
              } else {
                final res = await _api.post('/admin-panel/promo-banners/', body);
                if (mounted) setState(() => _banners.insert(0, res.data));
              }
              if (mounted) Navigator.pop(ctx);
              _showSnack(isEdit ? 'Banner updated' : 'Banner created', AppColors.success);
            } catch (e) {
              // ✅ FIX: Backend se actual error message nikalo (validation errors waghera)
              // taake pata chale exact field/wajah kya hai — generic message nahi
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
              } catch (_) {
                // response parse nahi ho saka — generic message hi rahega
              }
              setDialogState(() {
                saving      = false;
                dialogError = msg;
              });
            }
          }

          // ✅ FIX (main bug): Dialog ki height pehle FIXED thi (640).
          // Mobile pe jab keyboard khulta tha to wo fixed height available
          // screen se bari ho jati thi — Cancel/Create buttons screen ke
          // neeche, keyboard ke peeche chale jaate the. Isi liye "Create"
          // tap karne par koi response nahi aata tha (button wahan hota hi
          // nahi tha jahan dikh raha tha). Ab height aur width dono
          // MediaQuery se dynamically calculate hoti hain, keyboard ka
          // space minus karke — buttons hamesha visible/reachable rahenge.
          final mq = MediaQuery.of(ctx);
          final keyboardHeight   = mq.viewInsets.bottom;
          final availableHeight  = mq.size.height - keyboardHeight - 48; // 48 = top/bottom margin
          final dialogMaxHeight  = availableHeight.clamp(280.0, 640.0);
          final dialogMaxWidth   = mq.size.width > 520 ? 480.0 : mq.size.width - 32;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            insetPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical:   (keyboardHeight > 0 ? 12 : 24),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: dialogMaxWidth, maxHeight: dialogMaxHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      color: AppColors.adminColor,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    child: Text(
                      isEdit ? 'Edit Banner' : 'Create New Banner',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✅ FIX: Error ab dialog ke ANDAR dikhta hai — pehle
                          // SnackBar use hoti thi jo dialog ke peeche/behind
                          // chup jaati thi, user ko error samajh hi nahi
                          // aata tha. Ab actual backend error message bhi
                          // saath dikhta hai taake exact wajah pata chale.
                          if (dialogError != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.error.withOpacity(0.4)),
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
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setDialogState(() => dialogError = null),
                                    child: const Icon(Icons.close_rounded,
                                        color: AppColors.error, size: 16),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          _field('Title', titleCtrl),
                          const SizedBox(height: 12),
                          _field('Description', descCtrl, maxLines: 3),
                          const SizedBox(height: 12),

                          _field('Image URL (optional)', imageCtrl),
                          const SizedBox(height: 8),
                          // ✅ NEW — Gallery se bhi select kar sakte ho,
                          // URL field optional hi rehta hai.
                          OutlinedButton.icon(
                            onPressed: uploadingImage ? null : pickImageFromGallery,
                            icon: uploadingImage
                                ? const SizedBox(
                                    width: 14, height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.photo_library_outlined, size: 16),
                            label: Text(
                              uploadingImage ? 'Uploading...' : 'Pick from Gallery',
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.adminColor,
                              side: const BorderSide(color: AppColors.adminColor),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                          ),
                          const SizedBox(height: 12),

                          _field('Button Text', buttonTextCtrl),
                          const SizedBox(height: 12),

                          _dropdown('Button Link Type', linkType, _linkTypeChoices,
                              (v) => setDialogState(() => linkType = v)),
                          const SizedBox(height: 12),
                          _field('Button Link Value (URL or category id)', linkValueCtrl),
                          const SizedBox(height: 12),

                          _dropdown('Target Audience', targetAudience, _targetChoices,
                              (v) => setDialogState(() => targetAudience = v)),
                          const SizedBox(height: 12),
                          _dropdown('Trigger', trigger, _triggerChoices,
                              (v) => setDialogState(() => trigger = v)),
                          const SizedBox(height: 6),
                          // ✅ NEW — 7 trigger options confusing the rahe the
                          // (kab kaunsa dikhega), isi liye chuna hua trigger
                          // ka plain-language explanation yahan show karte hain.
                          Text(
                            _triggerHelp[trigger] ?? '',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                          ),
                          const SizedBox(height: 12),

                          if (trigger == 'every_x_days') ...[
                            _field('Show every X days', xDaysCtrl, isNumber: true),
                            const SizedBox(height: 12),
                          ],

                          _field('Priority (higher = shows first)', priorityCtrl, isNumber: true),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: _dateTile('Start Date', startDate, () => pickDate(true)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _dateTile('End Date', endDate, () => pickDate(false)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: isActive,
                            onChanged: (v) => setDialogState(() => isActive = v),
                            activeColor: AppColors.adminColor,
                            title: const Text('Active',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: const Text('Turning this off hides the banner from everyone',
                                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: saving ? null : () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.adminColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            onPressed: saving ? null : save,
                            child: saving
                                ? const SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : Text(isEdit ? 'Save' : 'Create',
                                    style: const TextStyle(color: Colors.white)),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<(String, String)> choices,
      ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
      items: choices
          .map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$2, style: const TextStyle(fontSize: 13))))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _dateTile(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date == null ? '$label (optional)' : DateFormat('dd MMM yyyy').format(date),
                style: TextStyle(
                    fontSize: 12,
                    color: date == null ? const Color(0xFF9CA3AF) : const Color(0xFF111827)),
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
      appBar: AppBar(
        backgroundColor: AppColors.adminColor,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.campaign_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            // ✅ FIX: Pehle Text ko Row mein bina Flexible/Expanded ke
            // rakha tha — narrow mobile AppBar pe icon + text dono ki
            // natural width available space se zyada ho jaati thi,
            // isi liye "RenderFlex overflowed" error aati thi.
            Flexible(
              child: Text('Promo Banners',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.adminColor,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.adminColor, strokeWidth: 2.5))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.error),
                      const SizedBox(height: 12),
                      const Text('Failed to load banners',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminColor),
                      ),
                    ],
                  ),
                )
              : _banners.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.campaign_outlined, size: 64, color: Color(0xFFD1D5DB)),
                          const SizedBox(height: 14),
                          const Text('No banners yet',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF))),
                          const SizedBox(height: 6),
                          const Text('Tap "+" to create a new banner',
                              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.adminColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                        itemCount: _banners.length,
                        itemBuilder: (_, i) => _buildBannerCard(_banners[i]),
                      ),
                    ),
    );
  }

  Widget _buildBannerCard(dynamic banner) {
    final isActive  = banner['is_active'] ?? false;
    final isLive    = banner['is_currently_active'] ?? false;
    final title     = banner['title'] ?? '';
    final desc      = banner['description'] ?? '';
    final target    = banner['target_audience'] ?? '';
    final trigger   = banner['trigger'] ?? '';
    final priority  = banner['priority'] ?? 0;
    final startDate = banner['start_date'] != null ? DateTime.tryParse(banner['start_date']) : null;
    final endDate   = banner['end_date']   != null ? DateTime.tryParse(banner['end_date'])   : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
                // ✅ FIX: Pehle yahan sirf "LIVE" / "SCHEDULED" / "OFF" likha
                // hota tha — admin ko pata nahi chalta tha ki ad kab khatam
                // hogi ya future date pe kab start hogi. Ab live countdown
                // ("Ends in 2h 15m") ya "Starts on 5 Jul" dikhta hai.
                _BannerStatusBadge(
                  isActive:  isActive,
                  isLive:    isLive,
                  startDate: startDate,
                  endDate:   endDate,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _chip(Icons.group_outlined, target),
                _chip(Icons.bolt_outlined, trigger),
                _chip(Icons.low_priority_rounded, 'priority $priority'),
              ],
            ),
            const Divider(height: 18),
            Row(
              children: [
                Switch(
                  value: isActive,
                  activeColor: AppColors.adminColor,
                  onChanged: (_) => _toggleActive(banner),
                ),
                const Text('Active', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.adminColor),
                  onPressed: () => _previewBanner(banner),
                  tooltip: 'Preview',
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF374151)),
                  onPressed: () => _openForm(existing: banner),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                  onPressed: () => _delete(banner),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF6B7280)),
          const SizedBox(width: 4),
          Text(label.replaceAll('_', ' '),
              style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }
}

// ── Live status badge ──────────────────────────────────────────────────────
//
// Pehle banner card pe sirf "LIVE" / "SCHEDULED" / "OFF" likha hota tha.
// Ab:
//   • OFF        → switch band hai
//   • Starts on  → admin ne is_active on kar diya hai lekin start_date
//                  abhi future me hai
//   • Ends in    → live hai aur end_date set hai — countdown har minute
//                  update hota hai, jaise jaise time kam hota jaata hai
//   • LIVE       → live hai lekin end_date set nahi hai (kabhi nahi rukegi)
//   • ENDED      → active tha lekin end_date guzar gayi hai
class _BannerStatusBadge extends StatefulWidget {
  final bool      isActive;
  final bool      isLive;
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
    // Sirf tab tick karo jab countdown dikhana ho — warna battery/CPU waste
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
    if (d.isNegative) return 'Ending...';
    if (d.inDays >= 1) return '${d.inDays}d ${d.inHours % 24}h left';
    if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes % 60}m left';
    if (d.inMinutes >= 1) return '${d.inMinutes}m left';
    return '<1m left';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    String  label;
    Color   color;

    if (!widget.isActive) {
      label = 'OFF';
      color = const Color(0xFF9CA3AF);
    } else if (widget.isLive) {
      if (widget.endDate != null) {
        label = 'Ends in ${_formatRemaining(widget.endDate!.difference(now))}';
        color = AppColors.success;
      } else {
        label = 'LIVE';
        color = AppColors.success;
      }
    } else if (widget.startDate != null && widget.startDate!.isAfter(now)) {
      label = 'Starts on ${DateFormat('d MMM, h:mm a').format(widget.startDate!)}';
      color = const Color(0xFFF59E0B);
    } else if (widget.endDate != null && widget.endDate!.isBefore(now)) {
      label = 'Ended';
      color = const Color(0xFF9CA3AF);
    } else {
      // Active hai but is_currently_active false aur na start na end set —
      // edge case, generic fallback.
      label = 'Inactive';
      color = const Color(0xFF9CA3AF);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}