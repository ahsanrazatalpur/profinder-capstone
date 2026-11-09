// lib/shared/widgets/display_ad_banner.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_service.dart';

class DisplayAdBanner extends StatefulWidget {
  final String placementSlot; // 'homepage_masthead', 'category_top', 'feed_native'
  final String? categoryId;
  final String? city;
  final double? height;
  final EdgeInsetsGeometry padding;

  const DisplayAdBanner({
    super.key,
    required this.placementSlot,
    this.categoryId,
    this.city,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  State<DisplayAdBanner> createState() => _DisplayAdBannerState();
}

class _DisplayAdBannerState extends State<DisplayAdBanner> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _ad;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAd();
  }

  Future<void> _fetchAd() async {
    try {
      final queryParams = <String, String>{'placement': widget.placementSlot};
      if (widget.categoryId != null && widget.categoryId!.isNotEmpty) {
        queryParams['category_id'] = widget.categoryId!;
      }
      if (widget.city != null && widget.city!.isNotEmpty) {
        queryParams['city'] = widget.city!;
      }

      final qs = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      final res = await _api.get('${AppConstants.displayAdServe}?$qs');

      if (mounted && res.data is Map && res.data['ad'] != null) {
        setState(() {
          _ad = Map<String, dynamic>.from(res.data['ad']);
          _loading = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _ad = null;
        _loading = false;
      });
    }
  }

  Future<void> _handleClick() async {
    if (_ad == null) return;
    final adId = _ad!['id'];
    final dest = _ad!['destination_url']?.toString() ?? '';

    // Track click asynchronously
    try {
      _api.post(AppConstants.displayAdClick(adId), {});
    } catch (_) {}

    if (dest.isNotEmpty) {
      final uri = Uri.tryParse(dest);
      if (uri != null) {
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _ad == null) {
      return const SizedBox.shrink();
    }

    final imageUrl = _ad!['mobile_banner_url']?.toString().isNotEmpty == true
        ? _ad!['mobile_banner_url'].toString()
        : _ad!['desktop_banner_url']?.toString() ?? '';

    if (imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: widget.padding,
      child: GestureDetector(
        onTap: _handleClick,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity,
                height: widget.height ?? 110,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const SizedBox.shrink(),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Ad',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
