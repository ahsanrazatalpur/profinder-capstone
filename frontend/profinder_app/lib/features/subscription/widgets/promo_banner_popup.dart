// lib/features/subscription/widgets/promo_banner_popup.dart
//
// REDESIGNED — Duolingo / Spotify / premium app jesa professional style
// FIXES:
//   • Image white blank — cached_network_image use karo
//   • Skip button kaam nahi — PopScope logic fix
//   • Guest ke liye bhi kaam karta hai
//   • Full-width bottom-sheet style on mobile

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../models/promo_banner_model.dart';
import '../screens/subscription_screen.dart';
import '../../search/screens/search_screen.dart';
import '../../../core/theme/theme_context_ext.dart';

const int _kSkipLockSeconds = 5;

class PromoBannerPopup extends StatefulWidget {
  final PromoBanner banner;
  final String      userRole; // 'customer' | 'professional' | 'guest'

  const PromoBannerPopup({
    super.key,
    required this.banner,
    required this.userRole,
  });

  /// Returns true agar user ne CTA press kiya, false agar dismiss
  static Future<bool> show(
    BuildContext context, {
    required PromoBanner banner,
    required String userRole,
  }) async {
    // Dialog use karo taake banner screen ke CENTER mein aaye
    final result = await showDialog<bool>(
      context:           context,
      barrierDismissible: false,   // lock period mein tap-outside blocked
      barrierColor:      Colors.black.withOpacity(0.65),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:    const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
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
  late Animation<double>   _scaleAnim;

  late int _secondsLeft;
  bool     _canSkip = false;
  Timer?   _timer;

  // ── Role ke hisaab se gradient colors ──────────────────────────────────
  List<Color> get _gradientColors {
    if (widget.userRole == 'professional') {
      return [const Color(0xFF6D28D9), const Color(0xFF4C1D95)]; // purple
    }
    return [const Color(0xFF2563EB), const Color(0xFF1E40AF)]; // blue
  }

  Color get _accentColor =>
      widget.userRole == 'professional' ? const Color(0xFF8B5CF6) : context.colors.primary;

  @override
  void initState() {
    super.initState();

    // Entry animation
    _animCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _animCtrl.forward();

    // Skip countdown
    _secondsLeft = _kSkipLockSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          _secondsLeft = 0;
          _canSkip     = true;
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

  // ── Dismiss — sirf canSkip=true pe ──────────────────────────────────────
  void _dismiss() {
    if (!_canSkip) return;
    _timer?.cancel();
    Navigator.pop(context, false);
  }

  // ── CTA pressed ──────────────────────────────────────────────────────────
  void _handleCta() {
    _timer?.cancel();
    Navigator.pop(context, true);

    switch (widget.banner.buttonLinkType) {
      case 'subscription':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => SubscriptionScreen(userRole: widget.userRole),
        ));
        break;

      case 'category':
        final parts   = widget.banner.buttonLinkValue.split(':');
        final catId   = int.tryParse(parts.first.trim());
        final catName = parts.length > 1 ? parts.last.trim() : 'Professionals';
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => SearchScreen(
            initialCategoryId:   catId,
            initialCategoryName: catName,
          ),
        ));
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
    // PopScope: canPop tab true ho jab _canSkip=true ho
    return PopScope(
      canPop: _canSkip,
      onPopInvokedWithResult: (didPop, _) {
        // Agar system ne pop nahi kiya (blocked tha) — kuch nahi karna
        // Agar kiya — result false (dismiss) already ho gaya
      },
      child: ScaleTransition(
        scale: _scaleAnim,
        child: _buildSheet(),
      ),
    );
  }

  Widget _buildSheet() {
    final hasImage = widget.banner.imageUrl.trim().startsWith('http');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.25),
            blurRadius: 40,
            spreadRadius: 0,
            offset:     const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
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
                      fontSize:      22,
                      fontWeight:    FontWeight.w800,
                      color:         Color(0xFF0F172A),
                      letterSpacing: -0.5,
                      height:        1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  // Description
                  Text(
                    widget.banner.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color:    Color(0xFF64748B),
                      height:   1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 26),

                  // ── CTA Button ──────────────────────────────────────
                  if (widget.banner.buttonLinkType != 'none')
                    _buildCtaButton(),

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
          // Image — StackFit.expand se poora area cover karega, koi white gap nahi
          CachedNetworkImage(
            imageUrl:    widget.banner.imageUrl.trim(),
            fit:         BoxFit.cover,
            // Jab tak load ho raha — shimmer placeholder
            placeholder: (_, __) => _buildShimmer(),
            // Load fail ho — gradient fallback
            errorWidget: (_, __, ___) => _buildGradientHeader(),
          ),
          // Gradient overlay — text readability ke liye
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin:  Alignment.topCenter,
                end:    Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.15),
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
          colors: [Color(0xFFE2E8F0), Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
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
              begin:  Alignment.topLeft,
              end:    Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glassy icon circle
                Container(
                  width:  80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.workspace_premium_rounded,
                        size: 42, color: Colors.amber),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color:        Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ProFinder Premium',
                    style: TextStyle(
                      color:         Colors.white,
                      fontSize:      12,
                      fontWeight:    FontWeight.w700,
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
            color:        Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Skip',
                style: TextStyle(
                  color:      Colors.white,
                  fontSize:   12,
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
      width:  38,
      height: 38,
      decoration: BoxDecoration(
        color:  Colors.black.withOpacity(0.55),
        shape:  BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$_secondsLeft',
          style: const TextStyle(
            color:      Colors.white,
            fontSize:   15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ── CTA Button ────────────────────────────────────────────────────────────
  Widget _buildCtaButton() {
    return SizedBox(
      width:  double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _handleCta,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          elevation:       0,
          shadowColor:     Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              widget.banner.buttonText,
              style: const TextStyle(
                fontSize:      16,
                fontWeight:    FontWeight.w800,
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
        opacity:  _canSkip ? 1.0 : 0.35,
        duration: const Duration(milliseconds: 300),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _canSkip ? 'No thanks, maybe later' : 'Please wait $_secondsLeft seconds...',
              style: const TextStyle(
                fontSize:   13,
                color:      Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}