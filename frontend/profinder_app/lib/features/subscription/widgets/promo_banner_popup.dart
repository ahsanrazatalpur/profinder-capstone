// Centered modal popup presenting active promotional banners.
// Supports countdown skip lock, cached banner graphics, and deep-linked CTAs.

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
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
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
    final hasImage = widget.banner.imageUrl.trim().startsWith('http');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radius28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radius28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header: image ya gradient ─────────────────────────────
            hasImage ? _buildImageHeader() : _buildGradientHeader(),

            // ── Body ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
              child: Column(
                children: [
                  // Title
                  Text(
                    widget.banner.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.background,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  // Description
                  Text(
                    widget.banner.description,
                    style: const TextStyle(
                      fontSize: AppFontSizes.body,
                      color: AppColors.slate500,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 26),

                  // ── CTA Button ──────────────────────────────────────
                  if (widget.banner.buttonLinkType != 'none') _buildCtaButton(),

                  const SizedBox(height: 12),

                  // ── Skip / Countdown ────────────────────────────────
                  _buildSkipButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Image header — cached_network_image se white blank fix ───────────────
  Widget _buildImageHeader() {
    return SizedBox(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Network banner image cached locally with shimmer placeholder and gradient fallback
          CachedNetworkImage(
            imageUrl: widget.banner.imageUrl.trim(),
            fit: BoxFit.cover,
            placeholder: (_, _) => _buildShimmer(),
            errorWidget: (_, _, _) => _buildGradientHeader(),
          ),
          // Subtle gradient overlay to ensure subtitle and title readability
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.15),
                ],
              ),
            ),
          ),
          // Skip/countdown pill — top right
          Positioned(top: 14, right: 14, child: _buildCountdownPill()),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Container(
      height: 220,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.slate200, AppColors.slate50, AppColors.slate200],
        ),
      ),
    );
  }

  // ── Gradient header (no image) ────────────────────────────────────────────
  Widget _buildGradientHeader() {
    return Stack(
      children: [
        Container(
          height: 180,
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
                // Glassy icon circle
                Container(
                  width: 80,
                  height: 80,
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
                      size: 42,
                      color: Colors.amber,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSizes.radiusChip),
                  ),
                  child: Text(
                    AppLocalizations.of(context).subscriptionProfinderPremium,
                    style: TextStyle(
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
        // Skip pill — top right
        Positioned(top: 14, right: 14, child: _buildCountdownPill()),
      ],
    );
  }

  // ── Skip / countdown pill ────────────────────────────────────────────────
  Widget _buildCountdownPill() {
    if (_canSkip) {
      return GestureDetector(
        onTap: _dismiss,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(AppSizes.radiusChip),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context).promoSkip,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSizes.small,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 5),
              Icon(Icons.close_rounded, color: Colors.white, size: 14),
            ],
          ),
        ),
      );
    }

    // Countdown circle
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$_secondsLeft',
          style: const TextStyle(
            color: Colors.white,
            fontSize: AppFontSizes.input,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ── CTA Button ────────────────────────────────────────────────────────────
  Widget _buildCtaButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
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
                  : widget.banner.buttonText,
              style: const TextStyle(
                fontSize: AppFontSizes.title,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Skip/Maybe-Later text button ──────────────────────────────────────────
  Widget _buildSkipButton() {
    return GestureDetector(
      onTap: _canSkip ? _dismiss : null,
      child: AnimatedOpacity(
        opacity: _canSkip ? 1.0 : 0.35,
        duration: const Duration(milliseconds: 300),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _canSkip
                  ? AppLocalizations.of(context).subscriptionNoThanksMaybeLater
                  : AppLocalizations.of(
                      context,
                    ).subscriptionPleaseWaitSeconds('$_secondsLeft'),
              style: const TextStyle(
                fontSize: AppFontSizes.secondary,
                color: AppColors.slate400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
