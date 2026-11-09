// lib/features/professional/widgets/featured_promotion_sheet.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../services/payment_service.dart';

class FeaturedPromotionSheet extends StatefulWidget {
  final int defaultCategoryId;
  final String defaultCategoryName;
  final VoidCallback? onPromotionActivated;

  const FeaturedPromotionSheet({
    super.key,
    required this.defaultCategoryId,
    required this.defaultCategoryName,
    this.onPromotionActivated,
  });

  static Future<void> show(
    BuildContext context, {
    required int defaultCategoryId,
    required String defaultCategoryName,
    VoidCallback? onPromotionActivated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FeaturedPromotionSheet(
        defaultCategoryId: defaultCategoryId,
        defaultCategoryName: defaultCategoryName,
        onPromotionActivated: onPromotionActivated,
      ),
    );
  }

  @override
  State<FeaturedPromotionSheet> createState() => _FeaturedPromotionSheetState();
}

class _FeaturedPromotionSheetState extends State<FeaturedPromotionSheet> {
  final PaymentService _paymentService = PaymentService();
  List<Map<String, dynamic>> _packages = [];
  int? _selectedPackageId;
  bool _loading = true;
  bool _processing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    try {
      final pkgs = await _paymentService.getFeaturedPromotionPackages();
      if (mounted) {
        setState(() {
          _packages = pkgs;
          if (_packages.isNotEmpty) {
            _selectedPackageId = _packages.first['id'] as int?;
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load promotion packages.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _initiateCheckout() async {
    if (_selectedPackageId == null) return;

    setState(() {
      _processing = true;
      _error = null;
    });

    final res = await _paymentService.initializeSafepayCheckout(
      purpose: 'featured_listing',
      packageId: _selectedPackageId,
      categoryId: widget.defaultCategoryId,
    );

    if (!mounted) return;

    if (res['success'] != true) {
      setState(() {
        _processing = false;
        _error = res['error'] ?? 'Checkout initialization failed.';
      });
      return;
    }

    final data = res['data'] as Map<String, dynamic>;
    final checkoutUrl = data['checkout_url']?.toString() ?? '';
    final orderId = data['order_id']?.toString() ?? '';
    final tracker = data['safepay_tracker']?.toString() ?? '';

    setState(() => _processing = false);

    if (checkoutUrl.isNotEmpty) {
      await _paymentService.launchApprovalUrl(checkoutUrl);
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Safepay Payment'),
        content: const Text(
          'Please finish payment in your browser. Once completed, tap "Verify & Activate" below.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
            ),
            child: const Text('Verify & Activate'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _processing = true);
      final verifyRes = await _paymentService.verifySafepayPayment(
        orderId: orderId,
        tracker: tracker.isNotEmpty ? tracker : null,
      );
      setState(() => _processing = false);

      if (!mounted) return;

      if (verifyRes['success'] == true) {
        Navigator.pop(context); // close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Your Featured Listing is now active!'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onPromotionActivated?.call();
      } else {
        setState(() {
          _error = verifyRes['error'] ?? 'Payment verification failed.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFD97706),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Featured Category Promotion',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Pin your profile at the top of ${widget.defaultCategoryName}',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_error != null)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            const Text(
              'Select Duration Package:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            ..._packages.map((pkg) {
              final id = pkg['id'] as int;
              final isSelected = _selectedPackageId == id;
              final days = pkg['duration_days'];
              final price = pkg['formatted_price'] ?? 'PKR ${pkg['price']}';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedPackageId = id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? context.colors.primary
                            : Colors.grey.withValues(alpha: 0.25),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? context.colors.primary.withValues(alpha: 0.05)
                          : Colors.transparent,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: isSelected
                                  ? context.colors.primary
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$days Days Promotion',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          price,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? context.colors.primary
                                : context.colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _processing ? null : _initiateCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _processing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Pay with Safepay & Pin Listing',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
