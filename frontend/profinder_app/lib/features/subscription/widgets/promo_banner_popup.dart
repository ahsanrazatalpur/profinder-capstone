// Centered modal popup presenting active promotional banners.
// Supports countdown skip lock, cached banner graphics, and deep-linked CTAs.
//
// Formatted as a unified card:
// - Top: Edge-to-edge 16:9 banner image (0 white padding/margins around image).
// - Inside top right: Countdown circular badge (e.g. "3" or close button).
// - Bottom: Title, Subtitle/Description, Full-width Action Button, Skip text.
// - Below card: Floating circular close button.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../models/promo_banner_model.dart';
import '../screens/subscription_screen.dart';
import '../../search/screens/search_screen.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/generated/app_localizations.dart';

const int _kSkipLockSeconds = 5;

class PromoBannerPopup extends StatefulWidget {
  final PromoBanner banner;
  final String userRole; // 'customer' | 'professional' | 'guest'

  const PromoBannerPopup({
    super.key,
    required this.banner,
    required this.userRole,
  });

  /// Displays the modal dialog, returning true if the user engaged with the CTA.
  static Future<bool> show(
    BuildContext context, {
    required PromoBanner banner,
    required String userRole,
  }) async {
    // Present as a centered modal dialog with an opaque backdrop
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // lock period mein tap-outside blocked
      barrierColor: Colors.black.withValues(alpha: 0.70),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: PromoBannerPopup(banner: banner, userRole: userRole),
      ),
    );
    return result == true;
  }

  @override
  State<PromoBannerPopup> createState() => _PromoBannerPopupState();
}

class _PromoBannerPopupState extends State<PromoBannerPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  late int _secondsLeft;
  bool _canSkip = false;
  Timer? _timer;

  // ── Role ke hisaab se gradient colors ──────────────────────────────────
  List<Color> get _gradientColors {
    if (widget.userRole == 'professional') {
      return [const Color(0xFF6D28D9), AppColors.violet900]; // purple
    }
    return [AppColors.customerColor, const Color(0xFF1E40AF)]; // blue
  }

  Color get _accentColor => widget.userRole == 'professional'
      ? AppColors.violet
      : context.colors.primary;

  @override
  void initState() {
    super.initState();

    // Entry animation
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _animCtrl.forward();

    // Skip countdown
    _secondsLeft = _kSkipLockSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          _secondsLeft = 0;
          _canSkip = true;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Dismiss Action ───────────────────────────────────────────────────────
  void _dismiss() {
    if (!_canSkip) return;
    _timer?.cancel();
    Navigator.pop(context, false);
  }

  // ── CTA Pressed ──────────────────────────────────────────────────────────
  void _handleCta() {
    _timer?.cancel();
    Navigator.pop(context, true);

    switch (widget.banner.buttonLinkType) {
      case 'subscription':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubscriptionScreen(userRole: widget.userRole),
          ),
        );
        break;

      case 'category':
        final parts = widget.banner.buttonLinkValue.split(':');
        final catId = int.tryParse(parts.first.trim());
        final catName = parts.length > 1 ? parts.last.trim() : 'Professionals';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchScreen(
              initialCategoryId: catId,
              initialCategoryName: catName,
            ),
          ),
        );
        break;

      case 'external_url':
      case 'offer':
        _launchUrl(widget.banner.buttonLinkValue);
        break;

      case 'none':
      default:
        break;
    }
  }

  Future<void> _launchUrl(String urlStr) async {
    if (urlStr.trim().isEmpty) return;
    final uri = Uri.tryParse(urlStr.trim());
    if (uri == null) return;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[Banner] URL launch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Intercept back navigation until the countdown timer enables skipping
    return PopScope(
      canPop: _canSkip,
      onPopInvokedWithResult: (didPop, _) {
        // Prevent dismissal while skip lock is active
      },
      child: ScaleTransition(scale: _scaleAnim, child: _buildSheet()),
    );
  }

  Widget _buildSheet() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Main Promo Card ───────────────────────────────────────────────
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 36,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top: Banner image bleeding edge-to-edge (0 padding / margins)
                    _buildTopMedia(),

                    // Bottom: Title, description, CTA button, skip text
                    _buildCardBody(),
                  ],
                ),
              ),
            ),

            // ── Floating Bottom Close Button (matches design reference) ───────
            const SizedBox(height: 20),
            _buildBottomCloseButton(),
          ],
        ),
      ),
    );
  }

  // ── Top Image / Media Section ─────────────────────────────────────────────
  Widget _buildTopMedia() {
    final imgUrl = widget.banner.imageUrl.trim();
    final hasImage = imgUrl.startsWith('http');
    final hasAction = widget.banner.buttonLinkType != 'none';

    if (!hasImage) {
      return _buildGradientHeader();
    }

    return Stack(
      children: [
        // Edge-to-edge 16:9 banner image without internal padding
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: hasAction ? _handleCta : null,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: CachedNetworkImage(
              imageUrl: imgUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (_, _) => _buildShimmer(),
              errorWidget: (_, _, _) => _buildGradientHeader(),
            ),
          ),
        ),

        // Countdown circular badge (top-right overlay)
        Positioned(
          top: 12,
          right: 12,
          child: _buildCountdownBadge(),
        ),
      ],
    );
  }

  // ── Countdown Badge / Skip Pill (Top Right) ───────────────────────────────
  Widget _buildCountdownBadge() {
    if (_canSkip) {
      return GestureDetector(
        onTap: _dismiss,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.65),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }

    // Circular countdown badge displaying remaining seconds (e.g. "3")
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.65),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$_secondsLeft',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ── Card Body (Title, Description, CTA, Skip Text) ────────────────────────
  Widget _buildCardBody() {
    final hasAction = widget.banner.buttonLinkType != 'none';

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          if (widget.banner.title.trim().isNotEmpty) ...[
            Text(
              widget.banner.title.trim(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.background,
                letterSpacing: -0.4,
                height: 1.25,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],

          // Description
          if (widget.banner.description.trim().isNotEmpty) ...[
            Text(
              widget.banner.description.trim(),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.slate500,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
          ],

          // CTA Action Button
          if (hasAction) ...[
            _buildCtaButton(),
            const SizedBox(height: 12),
          ],

          // Skip text
          _buildSkipButton(),
        ],
      ),
    );
  }

  // ── Fallback Gradient Header (when no image provided) ─────────────────────
  Widget _buildGradientHeader() {
    return Stack(
      children: [
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      size: 40,
                      color: Colors.amber,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSizes.radiusChip),
                  ),
                  child: Text(
                    AppLocalizations.of(context).subscriptionProfinderPremium,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppFontSizes.small,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: _buildCountdownBadge(),
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return Container(
      color: const Color(0xFF1E293B),
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white54,
          ),
        ),
      ),
    );
  }

  // ── Full-Width CTA Button ─────────────────────────────────────────────────
  Widget _buildCtaButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _handleCta,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              widget.banner.buttonText.trim().isEmpty
                  ? AppLocalizations.of(context).promoGetPremium
                  : widget.banner.buttonText.trim(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Skip / Countdown Text Below Button ────────────────────────────────────
  Widget _buildSkipButton() {
    return GestureDetector(
      onTap: _canSkip ? _dismiss : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        opacity: _canSkip ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 300),
        child: Text(
          _canSkip
              ? AppLocalizations.of(context).subscriptionNoThanksMaybeLater
              : AppLocalizations.of(
                  context,
                ).subscriptionPleaseWaitSeconds('$_secondsLeft'),
          style: TextStyle(
            fontSize: AppFontSizes.secondary,
            color: _canSkip ? AppColors.slate500 : AppColors.slate400,
            fontWeight: _canSkip ? FontWeight.w600 : FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ── Floating Bottom Close Button (Circular X Icon) ────────────────────────
  Widget _buildBottomCloseButton() {
    return GestureDetector(
      onTap: _canSkip ? _dismiss : null,
      child: AnimatedOpacity(
        opacity: _canSkip ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 250),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.55),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
