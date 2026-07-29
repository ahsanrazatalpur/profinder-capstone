// lib/features/auth/widgets/account_type_card.dart
//
// Premium selectable card for Register Step 3 (Choose Account Type).
// Styled to match the app's "featured" gradient-card look: a solid
// two-tone gradient of the role's own accent color (pure indigo for
// customer, pure purple for professional), a small uppercase eyebrow
// label, a bold left-aligned heading, a subtitle with a trailing
// arrow, and the role's icon — bigger and dulled/muted (soft
// translucent, not solid-bright/"black-looking") — sitting top-right.
// Same treatment for both cards.
//
// Uses the fixed AppColors palette, not the adaptive context.colors,
// so it looks the same rich, on-brand chip whether the app is in
// light or dark mode; it never turns into a plain/white box. The
// gradient is built purely from the accent color's own HSL shades
// (see `_shade`) — no black or slate base blended in — so it reads as
// a clean, pure indigo / pure purple, never a color-mixed-with-black
// look, while staying fully OPAQUE so the light scaffold behind it in
// light mode can never wash it out.
//
// Tap-down gives a tactile press-scale; selection is communicated
// through the border/glow/check-badge — NOT a size change — so the
// two cards (customer / professional) always stay exactly the same
// size as each other, whichever one is selected.

import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AccountTypeCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const AccountTypeCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<AccountTypeCard> createState() => _AccountTypeCardState();
}

class _AccountTypeCardState extends State<AccountTypeCard> {
  bool _pressed = false;

  // Darken/lighten a color by shifting HSL lightness (and optionally
  // desaturating it a bit) while keeping its hue intact.
  Color _shade(Color base, {double lightnessDelta = 0, double saturationDelta = 0}) {
    final hsl = HSLColor.fromColor(base);
    final l = (hsl.lightness + lightnessDelta).clamp(0.0, 1.0);
    final s = (hsl.saturation + saturationDelta).clamp(0.0, 1.0);
    return hsl.withLightness(l).withSaturation(s).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;
    final color    = widget.accentColor;

    // Two-tone gradient of the SAME hue — both stops kept bright and
    // light (calibrated against the reference cards' actual sampled
    // colors, which sit around 60-68% lightness / 85-90% saturation),
    // not a dark-to-light fade. Same formula for both roles, so
    // customer (indigo) and professional (purple) get identical
    // treatment.
    final Color tintTop = _shade(
      color,
      lightnessDelta: selected ? 0.16 : 0.12,
      saturationDelta: 0.05,
    );
    final Color tintBottom = _shade(
      color,
      lightnessDelta: selected ? 0.06 : 0.02,
      saturationDelta: 0.08,
    );

    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: '${widget.title}. ${widget.description}',
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp:   (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            // Press feedback only — selection never changes the card's
            // size, so customer/professional always match each other.
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              constraints: const BoxConstraints(minHeight: 118),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [tintTop, tintBottom],
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(
                  color: selected ? Colors.white.withOpacity(0.55) : Colors.white.withOpacity(0.14),
                  width: selected ? 1.6 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(selected ? 0.35 : 0.20),
                    blurRadius: selected ? 20 : 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ── Thin top sheen — a faint lighter line along the
                    // top edge so the card doesn't read as a flat block ──
                    Positioned(
                      top: 0,
                      left: 16,
                      right: 16,
                      child: IgnorePointer(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0),
                                Colors.white.withOpacity(selected ? 0.35 : 0.16),
                                Colors.white.withOpacity(0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Main content — spread across the full card
                    // height: heading anchored a bit below the icon,
                    // subtitle pinned to the bottom — instead of both
                    // cramped into the top corner. ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 56, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Bold heading — sits in the upper-middle area,
                          // clear of the icon thanks to the right padding.
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Text(
                              widget.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                height: 1.15,
                              ),
                            ),
                          ),
                          // Fixed-height reservation for the subtitle —
                          // guarantees both cards occupy exactly the same
                          // vertical space no matter how long each role's
                          // description text is (1 line vs 2 lines), and
                          // anchors it to the bottom of the card.
                          SizedBox(
                            height: 32,
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Text(
                                '${widget.description} →',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white.withOpacity(0.92),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Role icon — top-right, big and muted, with NO
                    // background chip behind it (just the icon itself,
                    // dulled via opacity), matching the reference. ──
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Icon(
                        widget.icon,
                        color: Colors.white.withOpacity(selected ? 0.55 : 0.40),
                        size: 34,
                      ),
                    ),

                    // ── Selected check — corner badge ──
                    Positioned(
                      top: 10,
                      left: 10,
                      child: AnimatedScale(
                        scale: selected ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.white,
                          ),
                          child: Icon(Icons.check_circle, color: color, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}