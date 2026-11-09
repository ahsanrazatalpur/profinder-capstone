// Centered modal popup presenting active promotional banners.
// Supports countdown skip lock, cached banner graphics, and deep-linked CTAs.
//
// Displays startup advertisements as clean, responsive, 16:9 horizontal banners
// with 0% edge clipping and floating skip/countdown controls.

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
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
    if (hasImage) {
      return _buildImageBanner();
    }
    return _buildTextSheet();
  }

  // ── 16:9 Horizontal Image Banner Presentation ────────────────────────────
  // Displays complete uploaded banner creative with 0% edge clipping,
  // responsive aspect ratio, and floating skip/countdown pill.
  Widget _buildImageBanner() {
    final imgUrl = widget.banner.imageUrl.trim();
    final hasAction = widget.banner.buttonLinkType != 'none';
    final hasCtaText = widget.banner.buttonText.trim().isNotEmpty;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.40),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: const Color(0xFF0F172A), // Dark slate canvas backdrop
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Crisp uncropped banner image — BoxFit.contain guarantees 0% edge clipping
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: hasAction ? _handleCta : null,
                    child: CachedNetworkImage(
                      imageUrl: imgUrl,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      placeholder: (_, _) => _buildShimmer(),
                      errorWidget: (_, _, _) => _buildTextSheet(),
                    ),
                  ),

                  // 2. Floating CTA Button (if action configured and button text provided)
                  if (hasAction && hasCtaText)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: _handleCta,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _accentColor,
                            borderRadius: BorderRadius.circular(AppSizes.radiusChip),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.banner.buttonText.trim(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // 3. Floating Skip / Countdown pill — top right corner
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _buildCountdownPill(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Fallback Text Announcement Sheet (when no image provided) ─────────────
  Widget _buildTextSheet() {
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
            _buildGradientHeader(),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
              child: Column(
                children: [
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

                  if (widget.banner.buttonLinkType != 'none') _buildCtaButton(),

                  const SizedBox(height: 12),

                  _buildSkipButton(),
                ],
              ),
            ),
          ],
        ),
      ),
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
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(AppSizes.radiusChip),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context).promoSkip,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSizes.small,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 5),
              const Icon(Icons.close_rounded, color: Colors.white, size: 15),
            ],
          ),
        ),
      );
    }

    // Countdown indicator
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(AppSizes.radiusChip),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 14, color: Colors.white70),
          const SizedBox(width: 5),
          Text(
            '${_secondsLeft}s',
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppFontSizes.small,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
