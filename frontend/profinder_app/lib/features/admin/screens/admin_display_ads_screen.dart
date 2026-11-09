import 'dart:typed_data';
// lib/features/admin/screens/admin_display_ads_screen.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/api_service.dart';
import '../../../shared/widgets/universal_app_bar.dart';

class AdminDisplayAdsScreen extends StatefulWidget {
  const AdminDisplayAdsScreen({super.key});

  @override
  State<AdminDisplayAdsScreen> createState() => _AdminDisplayAdsScreenState();
}

class _AdminDisplayAdsScreenState extends State<AdminDisplayAdsScreen> {
  final ApiService _api = ApiService();

  bool _loading = true;
  String? _error;
  List<dynamic> _campaigns = [];

  // Filter & Search
  String _searchQuery = '';
  String _selectedSlot = 'all';

  static const _slotLabels = {
    'homepage_masthead': 'Homepage Masthead',
    'category_top': 'Category Top',
    'feed_native': 'In-Feed Native',
  };

  @override
  void initState() {
    super.initState();
    _fetchCampaigns();
  }

  Future<void> _fetchCampaigns() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.get(AppConstants.adminDisplayAds);
      if (res.data is List) {
        setState(() {
          _campaigns = res.data;
          _loading = false;
        });
      } else {
        setState(() {
          _campaigns = [];
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load display ad campaigns: $e';
        _loading = false;
      });
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> campaign) async {
    final newStatus = !(campaign['is_active'] == true);
    final id = campaign['id'];
    try {
      try {
        await _api.patch(AppConstants.adminDisplayAdDetail(id), {
          'is_active': newStatus,
        });
      } catch (_) {
        await _api.patch(AppConstants.adminDisplayAds, {
          'id': id,
          'is_active': newStatus,
        });
      }
      setState(() {
        campaign['is_active'] = newStatus;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'Campaign activated!' : 'Campaign paused.'),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      String msg = e.toString();
      if (e is dio.DioException && e.response?.data != null) {
        msg = e.response!.data.toString();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $msg'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteCampaign(dynamic rawId) async {
    final int id = int.tryParse(rawId?.toString() ?? '') ?? 0;
    if (id == 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Ad Campaign?'),
        content: const Text('Are you sure you want to delete this startup advertisement? This cannot be undone.'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(70, 36)),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(80, 36),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      bool deleted = false;
      // 1. Try detail route DELETE /api/admin-panel/ads/<id>/
      try {
        await _api.delete(AppConstants.adminDisplayAdDetail(id));
        deleted = true;
      } catch (_) {}

      // 2. Try query param DELETE /api/admin-panel/ads/?id=<id>
      if (!deleted) {
        try {
          await _api.delete('${AppConstants.adminDisplayAds}?id=$id');
          deleted = true;
        } catch (_) {}
      }

      // 3. Try POST with action='delete'
      if (!deleted) {
        try {
          await _api.post(AppConstants.adminDisplayAds, {'id': id, 'action': 'delete'});
          deleted = true;
        } catch (_) {}
      }

      // 4. Try DELETE with JSON body
      if (!deleted) {
        await _api.deleteWithBody(AppConstants.adminDisplayAds, {'id': id});
      }

      setState(() {
        _campaigns.removeWhere((c) => (int.tryParse(c['id']?.toString() ?? '') ?? 0) == id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign deleted successfully.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      String msg = e.toString();
      if (e is dio.DioException && e.response?.data != null) {
        msg = e.response!.data.toString();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $msg'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openCampaignDialog({dynamic campaign}) {
    final Map<String, dynamic>? map = campaign is Map<String, dynamic>
        ? campaign
        : (campaign is Map ? Map<String, dynamic>.from(campaign) : null);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (ctx) => _CampaignEditorSheet(
        campaign: map,
        onSaved: () {
          Navigator.pop(ctx);
          _fetchCampaigns();
        },
      ),
    );
  }

  List<dynamic> get _filteredCampaigns {
    return _campaigns.where((c) {
      final title = (c['title'] ?? '').toString().toLowerCase();
      final adv = (c['advertiser_name'] ?? '').toString().toLowerCase();
      final matchesQuery = _searchQuery.isEmpty ||
          title.contains(_searchQuery.toLowerCase()) ||
          adv.contains(_searchQuery.toLowerCase());
      final matchesSlot = _selectedSlot == 'all' || c['placement_slot'] == _selectedSlot;
      return matchesQuery && matchesSlot;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final totalAds = _campaigns.length;
    final activeAds = _campaigns.where((c) => c['is_active'] == true).length;
    double totalRevenue = 0;
    int totalImpressions = 0;
    int totalClicks = 0;

    for (var c in _campaigns) {
      totalRevenue += double.tryParse(c['negotiated_price_pkr']?.toString() ?? '0') ?? 0;
      totalImpressions += (c['raw_impressions_count'] as num?)?.toInt() ?? 0;
      totalClicks += (c['raw_clicks_count'] as num?)?.toInt() ?? 0;
    }

    return Scaffold(
      appBar: const UniversalAppBar(
        title: 'Startup Ad Posters',
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
        label: const Text('Add Startup Ad', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _openCampaignDialog(),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCampaigns,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Row
              _buildStatsCard(
                totalAds: totalAds,
                activeAds: activeAds,
                totalRevenue: totalRevenue,
                totalImpressions: totalImpressions,
                totalClicks: totalClicks,
              ),
              const SizedBox(height: AppSizes.md),

              // Search & Filter Bar
              _buildFilterBar(),
              const SizedBox(height: AppSizes.md),

              // Ad List
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(minimumSize: const Size(120, 44)),
                          onPressed: _fetchCampaigns,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_filteredCampaigns.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.campaign_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _campaigns.isEmpty
                              ? 'No paid startup ads created yet.\nTap "+ Add Startup Ad" to place the first poster!'
                              : 'No campaigns match your search.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredCampaigns.length,
                  itemBuilder: (ctx, idx) => _buildCampaignCard(_filteredCampaigns[idx]),
                ),

              const SizedBox(height: 80), // Fab padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard({
    required int totalAds,
    required int activeAds,
    required double totalRevenue,
    required int totalImpressions,
    required int totalClicks,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Total Campaigns', '$totalAds', Icons.campaign_rounded),
              _buildStatItem('Active Posters', '$activeAds', Icons.check_circle_rounded),
              _buildStatItem('Ad Revenue', 'PKR ${NumberFormat('#,##0').format(totalRevenue)}', Icons.payments_rounded),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Views: ${NumberFormat.compact().format(totalImpressions)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Text('Clicks: ${NumberFormat.compact().format(totalClicks)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Text(
                'CTR: ${totalImpressions > 0 ? (totalClicks / totalImpressions * 100).toStringAsFixed(1) : 0}%',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Search by title or startup name...',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (val) => setState(() => _searchQuery = val),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSlotChip('all', 'All Slots'),
              _buildSlotChip('homepage_masthead', 'Homepage Masthead'),
              _buildSlotChip('category_top', 'Category Top'),
              _buildSlotChip('feed_native', 'In-Feed Native'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlotChip(String slotKey, String label) {
    final selected = _selectedSlot == slotKey;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        label: Text(label),
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : Colors.black87,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        onSelected: (_) => setState(() => _selectedSlot = slotKey),
      ),
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> c) {
    final isActive = c['is_active'] == true;
    final isApproved = c['is_approved'] == true;
    final isPaid = c['payment_verified_by_admin'] == true;
    final imageUrl = (c['mobile_banner_url']?.toString().isNotEmpty == true)
        ? c['mobile_banner_url']
        : c['desktop_banner_url'] ?? '';
    final slotLabel = _slotLabels[c['placement_slot']] ?? c['placement_slot'] ?? 'Banner';

    DateTime? startDate;
    DateTime? endDate;
    try {
      if (c['start_datetime'] != null) startDate = DateTime.parse(c['start_datetime']);
      if (c['end_datetime'] != null) endDate = DateTime.parse(c['end_datetime']);
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image Preview
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 140,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 140,
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey)),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        slotLabel,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isActive ? 'LIVE' : 'PAUSED',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Advertiser
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c['title'] ?? 'Untitled Campaign',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.business_rounded, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                c['advertiser_name'] ?? 'Advertiser',
                                style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              if (c['contact_phone_or_whatsapp']?.toString().isNotEmpty == true) ...[
                                const Text(' • ', style: TextStyle(color: Colors.grey)),
                                Text(
                                  c['contact_phone_or_whatsapp'],
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isActive,
                      activeThumbColor: Colors.green,
                      onChanged: (_) => _toggleActive(c),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Link & Location
                if (c['destination_url']?.toString().isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.link_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            c['destination_url'],
                            style: const TextStyle(color: AppColors.primary, fontSize: 12, decoration: TextDecoration.underline),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Badges & Payment
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Chip(
                      label: Text(
                        'PKR ${NumberFormat('#,##0').format(double.tryParse(c['negotiated_price_pkr']?.toString() ?? '0') ?? 0)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      backgroundColor: Colors.green.withValues(alpha: 0.1),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    if (isPaid)
                      Chip(
                        label: const Text('Payment Verified', style: TextStyle(fontSize: 11, color: Colors.teal)),
                        backgroundColor: Colors.teal.withValues(alpha: 0.1),
                        avatar: const Icon(Icons.verified_rounded, size: 14, color: Colors.teal),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    if (isApproved)
                      Chip(
                        label: const Text('Approved', style: TextStyle(fontSize: 11, color: Colors.blue)),
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    if (c['target_city']?.toString().isNotEmpty == true)
                      Chip(
                        label: Text('City: ${c['target_city']}', style: const TextStyle(fontSize: 11)),
                        backgroundColor: Colors.grey[200],
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Schedule & Stats
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Campaign Duration', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Text(
                            startDate != null && endDate != null
                                ? '${DateFormat('d MMM').format(startDate)} - ${DateFormat('d MMM yyyy').format(endDate)}'
                                : 'No dates set',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildMiniStat('Views', '${c['raw_impressions_count'] ?? 0}'),
                          const SizedBox(width: 12),
                          _buildMiniStat('Clicks', '${c['raw_clicks_count'] ?? 0}'),
                          const SizedBox(width: 12),
                          _buildMiniStat('CTR', '${c['ctr_percentage'] ?? 0}%'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit'),
                      onPressed: () => _openCampaignDialog(campaign: c),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Delete'),
                      onPressed: () => _deleteCampaign(c['id']),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Campaign Creation / Editor Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CampaignEditorSheet extends StatefulWidget {
  final Map<String, dynamic>? campaign;
  final VoidCallback onSaved;

  const _CampaignEditorSheet({this.campaign, required this.onSaved});

  @override
  State<_CampaignEditorSheet> createState() => _CampaignEditorSheetState();
}

class _CampaignEditorSheetState extends State<_CampaignEditorSheet> {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _advCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _imageUrlCtrl;
  late TextEditingController _destUrlCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _refCtrl;

  String _placementSlot = 'homepage_masthead';
  bool _isActive = true;
  bool _isApproved = true;
  bool _isPaid = true;

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _saving = false;
  bool _uploadingImage = false;
  Uint8List? _localImageBytes;

  @override
  void initState() {
    super.initState();
    final c = widget.campaign ?? {};
    _titleCtrl = TextEditingController(text: c['title'] ?? '');
    _advCtrl = TextEditingController(text: c['advertiser_name'] ?? '');
    _phoneCtrl = TextEditingController(text: c['contact_phone_or_whatsapp'] ?? '');
    _emailCtrl = TextEditingController(text: c['contact_email'] ?? '');
    _imageUrlCtrl = TextEditingController(text: c['mobile_banner_url'] ?? c['desktop_banner_url'] ?? '');
    _destUrlCtrl = TextEditingController(text: c['destination_url'] ?? '');
    _cityCtrl = TextEditingController(text: c['target_city'] ?? '');
    _priceCtrl = TextEditingController(text: c['negotiated_price_pkr']?.toString() ?? '');
    _refCtrl = TextEditingController(text: c['manual_payment_reference'] ?? '');

    _placementSlot = c['placement_slot'] ?? 'homepage_masthead';
    _isActive = c['is_active'] ?? true;
    _isApproved = c['is_approved'] ?? true;
    _isPaid = c['payment_verified_by_admin'] ?? true;

    if (c['start_datetime'] != null) {
      try { _startDate = DateTime.parse(c['start_datetime']); } catch (_) {}
    }
    if (c['end_datetime'] != null) {
      try { _endDate = DateTime.parse(c['end_datetime']); } catch (_) {}
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _advCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _imageUrlCtrl.dispose();
    _destUrlCtrl.dispose();
    _cityCtrl.dispose();
    _priceCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _localImageBytes = bytes;
      _uploadingImage = true;
    });
    try {
      final bytes = await picked.readAsBytes();
      final filename = picked.name.isNotEmpty && picked.name.contains('.')
          ? picked.name
          : 'ad_poster_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final formData = dio.FormData.fromMap({
        'image': dio.MultipartFile.fromBytes(bytes, filename: filename),
      });

      final res = await _api.postForm('/admin-panel/promo-banners/upload-image/', formData);
      final url = res.data is Map ? (res.data['url'] ?? res.data['image_url']) : null;
      if (url != null && url.toString().isNotEmpty) {
        setState(() {
          _imageUrlCtrl.text = url.toString();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Poster image uploaded successfully!'), backgroundColor: Colors.green),
          );
        }
      } else if (res.data is Map && res.data['error'] != null) {
        throw Exception(res.data['error']);
      }
    } catch (e) {
      String msg = e.toString();
      if (e is dio.DioException && e.response?.data != null) {
        msg = e.response!.data.toString();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $msg\nTip: You can also paste an image URL directly into the field below.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final payload = {
      'title': _titleCtrl.text.trim(),
      'advertiser_name': _advCtrl.text.trim(),
      'contact_phone_or_whatsapp': _phoneCtrl.text.trim(),
      'contact_email': _emailCtrl.text.trim(),
      'placement_slot': _placementSlot,
      'mobile_banner_url': _imageUrlCtrl.text.trim(),
      'desktop_banner_url': _imageUrlCtrl.text.trim(),
      'destination_url': _destUrlCtrl.text.trim(),
      'target_city': _cityCtrl.text.trim(),
      'negotiated_price_pkr': double.tryParse(_priceCtrl.text.trim()) ?? 0,
      'manual_payment_reference': _refCtrl.text.trim(),
      'is_active': _isActive,
      'is_approved': _isApproved,
      'payment_verified_by_admin': _isPaid,
      'start_datetime': _startDate.toIso8601String(),
      'end_datetime': _endDate.toIso8601String(),
    };

    try {
      if (widget.campaign != null) {
        final id = int.tryParse(widget.campaign!['id']?.toString() ?? '') ?? 0;
        payload['id'] = id;
        bool updated = false;

        // 1. Try detail PATCH /api/admin-panel/ads/<id>/
        try {
          await _api.patch(AppConstants.adminDisplayAdDetail(id), payload);
          updated = true;
        } catch (_) {}

        // 2. Try collection PATCH with id in body
        if (!updated) {
          try {
            await _api.patch(AppConstants.adminDisplayAds, payload);
            updated = true;
          } catch (_) {}
        }

        // 3. Try detail PUT /api/admin-panel/ads/<id>/
        if (!updated) {
          try {
            await _api.put(AppConstants.adminDisplayAdDetail(id), payload);
            updated = true;
          } catch (_) {}
        }

        // 4. Try collection PUT with id in body
        if (!updated) {
          try {
            await _api.put(AppConstants.adminDisplayAds, payload);
            updated = true;
          } catch (_) {}
        }

        // 5. Try POST with action='update' and id in body (NEVER plain POST)
        if (!updated) {
          payload['action'] = 'update';
          await _api.post(AppConstants.adminDisplayAds, payload);
        }
      } else {
        // Create new ad only when widget.campaign is null
        await _api.post(AppConstants.adminDisplayAds, payload);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.campaign != null ? 'Startup ad updated successfully!' : 'Startup ad published successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      widget.onSaved();
    } catch (e) {
      String msg = e.toString();
      if (e is dio.DioException && e.response?.data != null) {
        msg = e.response!.data.toString();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save ad: $msg'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 11.5)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: activeColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

    @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final sheetHeight = (mediaQuery.size.height * 0.90).clamp(520.0, 860.0);

    final validSlots = const ['homepage_masthead', 'category_top', 'feed_native'];
    final currentSlot = validSlots.contains(_placementSlot) ? _placementSlot : 'homepage_masthead';

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.campaign != null ? 'Edit Startup Ad' : 'Add Startup Ad Poster',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.md, AppSizes.lg, bottomInset + 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Advertiser / Startup Details
                      Text('Startup Details', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _advCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Startup / Company Name *',
                          hintText: 'e.g. Careem, ByteTech, Daraz',
                          prefixIcon: Icon(Icons.business_rounded),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneCtrl,
                              decoration: const InputDecoration(
                                labelText: 'WhatsApp / Phone *',
                                hintText: '+92 300 1234567',
                                prefixIcon: Icon(Icons.phone_rounded),
                              ),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _emailCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Contact Email',
                                hintText: 'info@startup.com',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Campaign Details
                      Text('Campaign & Placement', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Campaign Title *',
                          hintText: 'e.g. 50% Off Mega Launch Promo',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: currentSlot,
                        decoration: const InputDecoration(
                          labelText: 'Poster Placement Slot *',
                          prefixIcon: Icon(Icons.view_carousel_rounded),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'homepage_masthead', child: Text('Homepage Masthead (Top Banner)')),
                          DropdownMenuItem(value: 'category_top', child: Text('Category Top Leaderboard')),
                          DropdownMenuItem(value: 'feed_native', child: Text('In-Feed Native Discovery Banner')),
                        ],
                        onChanged: (val) => setState(() => _placementSlot = val ?? 'homepage_masthead'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _destUrlCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Redirect / Click URL *',
                          hintText: 'https://startup.com or https://wa.me/92300...',
                          prefixIcon: Icon(Icons.link_rounded),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      // Poster Image Picker
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _imageUrlCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Poster Image URL *',
                                hintText: 'https://res.cloudinary.com/...',
                                prefixIcon: Icon(Icons.image_rounded),
                              ),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: Colors.blueGrey[800],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                              ),
                              icon: _uploadingImage
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 18),
                              label: const Text('Gallery', style: TextStyle(color: Colors.white, fontSize: 12)),
                              onPressed: _uploadingImage ? null : _pickAndUploadImage,
                            ),
                          ),
                        ],
                      ),
                      if (_localImageBytes != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _localImageBytes!,
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ] else if (_imageUrlCtrl.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _imageUrlCtrl.text,
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Financial & Scheduling
                      Text('Pricing & Duration', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Negotiated Price (PKR)',
                                hintText: '15000',
                                prefixIcon: Icon(Icons.money_rounded),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _refCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Payment Reference',
                                hintText: 'Raast / Bank TRX',
                                prefixIcon: Icon(Icons.receipt_rounded),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                                label: Text('From: ${DateFormat('d MMM yyyy').format(_startDate)}', style: const TextStyle(fontSize: 12)),
                                onPressed: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: _startDate,
                                    firstDate: DateTime(2025),
                                    lastDate: DateTime(2030),
                                  );
                                  if (d != null) setState(() => _startDate = d);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                icon: const Icon(Icons.event_rounded, size: 16),
                                label: Text('To: ${DateFormat('d MMM yyyy').format(_endDate)}', style: const TextStyle(fontSize: 12)),
                                onPressed: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: _endDate,
                                    firstDate: _startDate,
                                    lastDate: DateTime(2030),
                                  );
                                  if (d != null) setState(() => _endDate = d);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Status & Controls
                      _buildToggleRow(
                        title: 'Is Active (Live on App)',
                        subtitle: 'Show this poster to customers now across the platform',
                        value: _isActive,
                        activeColor: Colors.green,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                      const Divider(height: 16),
                      _buildToggleRow(
                        title: 'Payment Verified',
                        subtitle: 'Offline payment / bank transfer verified from startup',
                        value: _isPaid,
                        activeColor: Colors.teal,
                        onChanged: (v) => setState(() => _isPaid = v),
                      ),
                      const Divider(height: 16),
                      _buildToggleRow(
                        title: 'Admin Approved',
                        subtitle: 'Ad poster content verified and approved for display',
                        value: _isApproved,
                        activeColor: Colors.blue,
                        onChanged: (v) => setState(() => _isApproved = v),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                          ),
                          onPressed: (_saving || _uploadingImage) ? null : _save,
                          child: _saving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                                  widget.campaign != null ? 'Update Ad Poster' : 'Publish Startup Ad Poster',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
}
