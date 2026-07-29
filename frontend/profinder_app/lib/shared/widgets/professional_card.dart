// lib/shared/widgets/professional_card.dart
//
// PROFESSIONAL CARD — shared premium card used by every professional
// listing section on both the Customer and Guest dashboards (Recommended,
// Nearby, Top Rated, Trending, Recently Added, Popular Professionals, and
// the "See all" full-list sheets).
//
// Pure UI component — reads only from the same `pro` map both screens
// already receive from the backend. No network calls, no backend logic,
// no API changes, no changes to what any button/callback actually DOES —
// only how the card looks, animates, and renders.
//
// Information hierarchy (top to bottom, exactly as specced):
//   1. Professional photo (cached, animated shimmer while loading, initials on error)
//   2. Verified badge          — only when `is_verified == true` (admin-controlled)
//   3. Section status badge    — e.g. "Nearby", "Top Rated", "Trending", "New"
//   4. Profession               — the single most prominent line on the card
//   5. Professional name        — secondary, quieter than the profession
//   6. Rating + review count + experience
//   7. City + distance
//   8. Starting price           — visually stronger than the name
//   9. View Profile button
//  10. Book Now button
//
// ── RESPONSIVENESS (unchanged from the previous pass) ────────────────────
// Every dimension is derived from one screen-width-based scale factor via
// `_scaleFor(context)`, clamped 0.84–1.18. `ProfessionalCard.heightFor` /
// `.widthFor` remain the single source of truth the parent screens use to
// size their list wrappers — none of that sizing math changed here.
//
// ── VISUAL POLISH & PERFORMANCE (this pass) ───────────────────────────────
//   • Press animation   — the whole card scales down slightly on press and
//     springs back on release (`_PressableCard`), instead of giving zero
//     tactile feedback like before.
//   • Hover effect       — on desktop/web (mouse), the border tints toward
//     the brand color and the shadow lifts slightly.
//   • Favorite animation — the heart icon scale+fades between states via
//     `AnimatedSwitcher` instead of snapping instantly.
//   • Animated shimmer   — the loading placeholder now sweeps left-to-right
//     instead of being a static gradient block.
//   • Image loading      — `CachedNetworkImage` now fades in smoothly and
//     is capped to its actual rendered size in memory (`memCacheWidth/
//     Height`) so large source photos don't get decoded at full
//     resolution just to be shown at ~130px — cheaper decode, smoother
//     scrolling.
//   • RepaintBoundary     — wraps the card as a whole, the photo, and the
//     favorite heart separately, so animating any one of them (press,
//     hover, favorite toggle, shimmer sweep) never forces a repaint of
//     sibling cards in the same horizontal list.
//   • Modern buttons      — Book Now gets a soft brand-colored shadow
//     (common "premium CTA" treatment), both buttons keep Material's
//     built-in ripple for press feedback.
// None of this touches what `onTap` / `onBookNow` / `onFavoriteToggle`
// actually do — those are still just whatever the parent screen passed in.

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_helpers.dart';
import '../../core/theme/theme_context_ext.dart';

class ProfessionalCard extends StatelessWidget {
  const ProfessionalCard({
    super.key,
    required this.pro,
    required this.onTap,
    required this.onBookNow,
    this.sectionTag,
    this.sectionTagIcon,
    this.sectionTagColor,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.fullWidth = false,
  });

  /// Raw professional data exactly as returned by the backend — no field
  /// on this map is renamed, added, or removed by this widget.
  final Map pro;

  /// Opens the professional's full profile — used by both the card tap
  /// and the "View Profile" button, matching the previous card's behavior.
  final VoidCallback onTap;

  /// "Book Now" action — customer dashboard opens the booking flow, guest
  /// dashboard prompts login. The widget itself makes no assumption about
  /// which, and this pass doesn't touch that decision at all.
  final VoidCallback onBookNow;

  /// Section status badge text (e.g. "Nearby", "Top Rated", "Trending",
  /// "New", "Recommended", "Popular") — plain text only, never an emoji.
  /// Falls back to an icon-only "PRO" badge when the professional is
  /// premium and no explicit section tag was passed. Mutually exclusive
  /// with the section tag: a card only ever shows ONE badge in this slot.
  final String? sectionTag;
  final IconData? sectionTagIcon;
  final Color? sectionTagColor;

  final bool isFavorite;

  /// Null hides the favourite heart entirely (kept as a small utility
  /// overlay on the photo — it isn't one of the 10 hierarchy items but was
  /// existing functionality this pass doesn't remove or re-wire).
  final VoidCallback? onFavoriteToggle;

  /// Compact horizontal-list width vs. full-width "See all" sheet variant.
  final bool fullWidth;

  // ── Reference (390px-wide phone) base measurements — never used
  // directly, always passed through `_scaleFor(context)` first.
  //
  // 🎨 VISUAL REDESIGN PASS — hierarchy overhaul (Fiverr/Airbnb-style).
  // Photo grew the most (hero focus), body grew enough to host the
  // bigger profession/price typography below without cramping —
  // total card height is up ~20% overall. Pure sizing/typography
  // change: `heightFor()` / `widthFor()` remain the single source of
  // truth parent screens size their wrappers from, so nothing that
  // reads this card's layout elsewhere needed to change.
  static const double _basePhotoHeight = 168.0;
  static const double _baseBodyHeight  = 210.0;
  static const double _baseCardWidth   = 230.0;
  static const double _cardRadius      = 20.0;

  static double _scaleFor(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Floor raised from 0.84 -> 0.88: on very small/narrow phones the
    // previous floor shrunk the card's box faster than the text inside
    // it (which has its own min font sizes), which is what caused the
    // overflow warning on small screens.
    return (width / 390.0).clamp(0.88, 1.18);
  }

  /// Total card height for this screen — parent screens use this to size
  /// their horizontal `SizedBox`/`ListView` wrapper.
  ///
  /// This previously only factored in screen-width scale, not the user's
  /// accessibility text-size setting. The card's own `build()` clamps its
  /// internal text scaler up to 1.25x, but that extra text height was
  /// never reflected back into the height the PARENT reserves for the
  /// card — so on a device with a larger system font, the card's real
  /// content could end up taller than the box it was placed in and
  /// overflow (the black/yellow striped Flutter overflow warning).
  /// Adding a small proportional buffer here keeps the two in sync.
  static double heightFor(BuildContext context) {
    return _sp(_basePhotoHeight, _scaleFor(context)) + _bodyHeightFor(context);
  }

  // Body height only (everything below the photo) — shared by heightFor()
  // (compact horizontal-list sizing) and build() (fullWidth vertical-list
  // sizing, where the photo height is computed from the real available
  // width instead of this fixed scale).
  static double _bodyHeightFor(BuildContext context) {
    final s = _scaleFor(context);
    final textScale = MediaQuery.textScalerOf(context).clamp(minScaleFactor: 0.9, maxScaleFactor: 1.25).scale(1.0);
    final textBuffer = textScale > 1.0 ? (textScale - 1.0) * 60.0 : 0.0;
    // Raised from 8 -> 16: extra headroom so the card stays overflow-free
    // across small phones, tablets, and different system font scales —
    // not just the bare-minimum measured content height.
    const flatSafetyMargin = 34.0;
    return (_baseBodyHeight * s) + textBuffer + flatSafetyMargin;
  }

  /// Compact-mode card width for this screen (ignored when `fullWidth`).
  static double widthFor(BuildContext context) => (_baseCardWidth * _scaleFor(context)).clamp(190.0, 278.0);

  static double _sp(double base, double scale, {double min = 0, double max = 999}) => (base * scale).clamp(min, max);

  // Hero photo width:height ratio used ONLY in fullWidth (vertical list)
  // mode, where the card is as wide as the screen. Compact carousel mode
  // keeps its own tuned fixed height untouched.
  static const double _fullWidthPhotoAspect = 1.55;

  @override
  Widget build(BuildContext context) {
    final scale = _scaleFor(context);
    final dpr   = MediaQuery.devicePixelRatioOf(context);
    // Respect the user's OS text-size accessibility setting, but clamp it
    // — otherwise an extreme system font scale would overflow this
    // fixed-height card no matter how it's built.
    final clampedTextScaler = MediaQuery.textScalerOf(context).clamp(minScaleFactor: 0.9, maxScaleFactor: 1.25);

    final id           = pro['id']?.toString() ?? pro['user_id']?.toString() ?? '';
    final name         = pro['name']?.toString() ?? 'Professional';
    final profession   = pro['category_name']?.toString().trim().isNotEmpty == true
        ? pro['category_name'].toString()
        : (pro['specialization']?.toString() ?? '');
    final photo        = AppHelpers.getFullImageUrl(pro['photo_url']?.toString());
    final rating       = _asDouble(pro['average_rating']);
    final reviews      = pro['reviews_count']; // shown only if the backend returned it
    final experience   = pro['experience_years'];
    final distance     = pro['distance_km'];
    final city         = pro['city']?.toString() ?? '';
    final price        = _asDouble(pro['hourly_rate']);
    final isVerified   = pro['is_verified'] == true; // admin-controlled — never inferred client-side
    final isPremium    = pro['is_premium'] == true;

    final badgeText  = sectionTag ?? (isPremium ? 'PRO' : null);
    final badgeIcon  = sectionTag != null ? sectionTagIcon : (isPremium ? Icons.workspace_premium_rounded : null);
    final badgeColor = sectionTag != null ? (sectionTagColor ?? context.colors.primary) : const Color(0xFF7C3AED);

    final bodyHeight = _bodyHeightFor(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactWidth = _sp(_baseCardWidth, scale, min: 190, max: 278);
        final cardWidth    = fullWidth ? constraints.maxWidth : compactWidth;

        // 🔧 FIX: previously every card used the SAME fixed photo height
        // regardless of card width. That's fine for the narrow ~230px
        // carousel card, but on a fullWidth card (screen-wide, in a
        // vertical list) it made the photo far too short for how wide it
        // now was — BoxFit.cover had to crop most of the face off just
        // to fill that shape (exactly the "dp sahi se nazar nahi aata"
        // bug). fullWidth cards now derive their photo height from the
        // real available width via a sane portrait-friendly aspect
        // ratio instead of reusing the carousel's short fixed height.
        final photoHeight = fullWidth
            ? (cardWidth.isFinite ? (cardWidth / _fullWidthPhotoAspect).clamp(200.0, 280.0) : 240.0)
            : _sp(_basePhotoHeight, scale);
        final totalHeight = photoHeight + bodyHeight;

        // Cap decoded image resolution to roughly what's actually
        // rendered — avoids decoding a full-resolution source photo just
        // to paint it at its rendered size.
        final memCacheH = (photoHeight * dpr).round();
        final memCacheW = ((cardWidth.isFinite ? cardWidth : 360.0) * dpr).round();

        return RepaintBoundary(
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: clampedTextScaler),
            child: _PressableCard(
              key: ValueKey('pro_card_$id'),
              onTap: onTap,
              width: fullWidth ? double.infinity : cardWidth,
              height: totalHeight,
              radius: _cardRadius,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPhoto(context, name, photo, isVerified, badgeText, badgeIcon, badgeColor, photoHeight, scale, memCacheW, memCacheH),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(_sp(14, scale, min: 12, max: 17), _sp(13, scale, min: 11, max: 16),
                          _sp(14, scale, min: 12, max: 17), _sp(10, scale, min: 8, max: 13)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // 4 + 5. Category icon + Profession (bold, primary
                      // color, now the single loudest text on the card)
                      // with the name underneath, clearly secondary.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: _sp(38, scale, min: 34, max: 44),
                            height: _sp(38, scale, min: 34, max: 44),
                            decoration: BoxDecoration(
                              color: context.colors.primaryLight,
                              borderRadius: BorderRadius.circular(_sp(11, scale, min: 9, max: 13)),
                            ),
                            child: Icon(
                              _categoryIcon(profession),
                              color: context.colors.primary,
                              size: _sp(20, scale, min: 18, max: 23),
                            ),
                          ),
                          SizedBox(width: _sp(10, scale, min: 8, max: 12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  profession.isNotEmpty ? profession : 'Service Professional',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize:   _sp(18.5, scale, min: 16.5, max: 21.5),
                                    fontWeight: FontWeight.w800,
                                    color:      context.colors.primary,
                                    height:     1.12,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                SizedBox(height: _sp(3, scale, min: 2, max: 4)),
                                // 5. Name — clearly secondary to the profession above:
                                //    smaller, lighter weight, muted color.
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize:   _sp(13.5, scale, min: 12, max: 15.5),
                                    fontWeight: FontWeight.w500,
                                    color:      context.colors.textSecondary,
                                    letterSpacing: 0.15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: _sp(10, scale, min: 8, max: 12)),
                      // 6. Rating + review count + experience
                      _buildRatingRow(context, rating, reviews, experience, scale),
                      SizedBox(height: _sp(8, scale, min: 6, max: 10)),
                      // 7. City + distance
                      _buildLocationRow(context, city, distance, scale),
                      const Spacer(),
                      // 8. Starting price — now its own visually distinct
                      //    block: quiet uppercase label on top, then a
                      //    large green premium-accent price. This is
                      //    meant to be one of the first things the eye
                      //    lands on, per the redesign brief.
                      Text('STARTING FROM',
                          style: TextStyle(fontSize: _sp(9.5, scale, min: 8.5, max: 11), fontWeight: FontWeight.w700,
                              color: context.colors.textSecondary, letterSpacing: 0.8)),
                      SizedBox(height: _sp(2, scale, min: 1.5, max: 3)),
                      RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(children: [
                          TextSpan(
                            text: '\$${price.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: _sp(23, scale, min: 20, max: 26), fontWeight: FontWeight.w800, color: context.colors.accent, letterSpacing: 0.2),
                          ),
                          TextSpan(
                            text: ' /hr',
                            style: TextStyle(fontSize: _sp(12, scale, min: 10.5, max: 13.5), fontWeight: FontWeight.w600, color: context.colors.textSecondary, letterSpacing: 0.2),
                          ),
                        ]),
                      ),
                      SizedBox(height: _sp(12, scale, min: 10, max: 15)),
                      // 9 + 10. View Profile, then Book Now.
                      _buildActionRow(context, scale),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  // ── 1–3. Photo + Verified badge + Section badge + favourite ──────────
  Widget _buildPhoto(BuildContext context, String name, String photo, bool isVerified, String? badgeText, IconData? badgeIcon, Color badgeColor,
      double photoHeight, double scale, int memCacheW, int memCacheH) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(_cardRadius)),
      child: SizedBox(
        height: photoHeight,
        width:  double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: photo.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl:       photo,
                      fit:            BoxFit.cover,
                      memCacheWidth:  memCacheW,
                      memCacheHeight: memCacheH,
                      fadeInDuration: const Duration(milliseconds: 220),
                      fadeInCurve:    Curves.easeOut,
                      placeholder:    (_, __) => const _ShimmerBox(),
                      errorWidget:    (_, __, ___) => _avatarFallback(context, name, scale),
                    )
                  : _avatarFallback(context, name, scale),
            ),
            // 2. Verified badge — top-left, admin-controlled only.
            if (isVerified)
              Positioned(
                left: _sp(9, scale, min: 7, max: 11), top: _sp(9, scale, min: 7, max: 11),
                child: _pill(color: context.colors.accent, icon: Icons.verified_rounded, text: 'Verified', scale: scale),
              ),
            // 3. Section status badge — top-left, stacked below Verified
            //    when both are present, so neither is ever hidden behind
            //    the other.
            if (badgeText != null)
              Positioned(
                left: _sp(9, scale, min: 7, max: 11), top: isVerified ? _sp(33, scale, min: 27, max: 39) : _sp(9, scale, min: 7, max: 11),
                child: _pill(color: badgeColor, icon: badgeIcon, text: badgeText, scale: scale),
              ),
            // Favourite heart — existing utility action, kept as a small
            // unobtrusive overlay. Now animates between states instead of
            // snapping, isolated in its own RepaintBoundary so toggling it
            // never repaints the photo or badges above it.
            if (onFavoriteToggle != null)
              Positioned(
                right: _sp(8, scale, min: 6, max: 10), top: _sp(8, scale, min: 6, max: 10),
                child: RepaintBoundary(
                  child: GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Container(
                      width: _sp(31, scale, min: 27, max: 35), height: _sp(31, scale, min: 27, max: 35),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutBack,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
                          child: Icon(
                            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            key: ValueKey<bool>(isFavorite),
                            color: isFavorite ? AppColors.error : context.colors.textSecondary,
                            size: _sp(17, scale, min: 15, max: 19),
                          ),
                        ),
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

  Widget _pill({required Color color, IconData? icon, required String text, required double scale}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _sp(8, scale, min: 6.5, max: 10), vertical: _sp(4, scale, min: 3.5, max: 5)),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, color: Colors.white, size: _sp(12, scale, min: 10.5, max: 14)), SizedBox(width: _sp(3, scale, min: 2, max: 4))],
          Text(text, style: TextStyle(color: Colors.white, fontSize: _sp(10.5, scale, min: 9, max: 12), fontWeight: FontWeight.w700, letterSpacing: 0.4)),
        ],
      ),
    );
  }

  // ── 6. Rating + review count + experience ─────────────────────────────
  Widget _buildRatingRow(BuildContext context, double rating, dynamic reviews, dynamic experience, double scale) {
    return Row(children: [
      Container(
        padding: EdgeInsets.symmetric(horizontal: _sp(7, scale, min: 6, max: 8.5), vertical: _sp(3, scale, min: 2.5, max: 4)),
        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.star_rounded, color: const Color(0xFFF59E0B), size: _sp(14.5, scale, min: 13, max: 16.5)),
          SizedBox(width: _sp(2, scale, min: 1.5, max: 3)),
          Text(rating.toStringAsFixed(1),
              style: TextStyle(fontSize: _sp(12, scale, min: 10.5, max: 14), fontWeight: FontWeight.w700, color: const Color(0xFF92400E), letterSpacing: 0.2)),
        ]),
      ),
      if (reviews != null) ...[
        SizedBox(width: _sp(6, scale, min: 5, max: 8)),
        Flexible(
          child: Text('($reviews)',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: _sp(12, scale, min: 10.5, max: 14), color: context.colors.textSecondary, letterSpacing: 0.2)),
        ),
      ],
      if (experience != null) ...[
        SizedBox(width: _sp(8, scale, min: 6, max: 10)),
        Icon(Icons.work_outline_rounded, size: _sp(13, scale, min: 11.5, max: 15), color: context.colors.textSecondary),
        SizedBox(width: _sp(2, scale, min: 1.5, max: 3)),
        Flexible(
          child: Text('${experience}y exp',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: _sp(12, scale, min: 10.5, max: 14), color: context.colors.textSecondary, letterSpacing: 0.2)),
        ),
      ],
    ]);
  }

  // ── 7. City + distance ─────────────────────────────────────────────────
  Widget _buildLocationRow(BuildContext context, String city, dynamic distance, double scale) {
    final label = distance != null
        ? (city.isNotEmpty ? '$city  •  ${distance}km away' : '${distance}km away')
        : (city.isNotEmpty ? city : 'Nearby');
    return Row(children: [
      Icon(Icons.location_on_outlined, size: _sp(14, scale, min: 12.5, max: 16), color: context.colors.textSecondary),
      SizedBox(width: _sp(4, scale, min: 3, max: 5)),
      Expanded(
        child: Text(label,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: _sp(12.5, scale, min: 11, max: 14.5), color: context.colors.textSecondary, letterSpacing: 0.2)),
      ),
    ]);
  }

  // ── 9 + 10. View Profile, Book Now ────────────────────────────────────
  Widget _buildActionRow(BuildContext context, double scale) {
    final vPad  = _sp(15, scale, min: 12.5, max: 18);
    final fSize = _sp(13, scale, min: 11.5, max: 15);
    final btnRadius = BorderRadius.circular(12);
    return Row(children: [
      Expanded(
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding:     EdgeInsets.symmetric(vertical: vPad),
            side:        BorderSide(color: context.colors.divider, width: 1.3),
            shape:       RoundedRectangleBorder(borderRadius: btnRadius),
            foregroundColor: context.colors.textPrimary,
            // 🔧 Without these, Material enforces a hidden 48px minimum
            // touch-target height regardless of our padding — that
            // uncounted extra height was the real cause of the bottom
            // overflow on smaller/narrower phones.
            minimumSize:  Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text('View Profile',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: fSize, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
        ),
      ),
      SizedBox(width: _sp(9, scale, min: 7, max: 11)),
      Expanded(
        // Soft brand-colored shadow under the primary CTA — the modern
        // "elevated pill button" look (Fiverr/LinkedIn-style), instead of
        // a flat, shadowless button competing visually with View Profile.
        child: Container(
          decoration: BoxDecoration(
            borderRadius: btnRadius,
            boxShadow: [BoxShadow(color: context.colors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 5))],
          ),
          child: ElevatedButton(
            onPressed: onBookNow,
            style: ElevatedButton.styleFrom(
              padding:         EdgeInsets.symmetric(vertical: vPad),
              backgroundColor: context.colors.primary,
              foregroundColor: Colors.white,
              elevation:       0,
              shape:           RoundedRectangleBorder(borderRadius: btnRadius),
              // Same fix as View Profile — no hidden 48px min height.
              minimumSize:  Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('Book Now',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: fSize, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
          ),
        ),
      ),
    ]);
  }

  Widget _avatarFallback(BuildContext context, String name, double scale) => Container(
        color: context.colors.primaryLight,
        child: Center(
          child: Text(
            AppHelpers.getInitials(name),
            style: TextStyle(color: context.colors.primary, fontSize: _sp(24, scale, min: 20, max: 28), fontWeight: FontWeight.bold),
          ),
        ),
      );

  double _asDouble(dynamic v) => v == null ? 0.0 : (double.tryParse(v.toString()) ?? 0.0);

  // Best-effort icon for the category/profession chip — matches the icon
  // set already used for category tiles on the home/search screens, keyed
  // by keyword so it works for any profession string the backend sends.
  // Falls back to a generic briefcase icon when nothing matches.
  static IconData _categoryIcon(String profession) {
    final p = profession.toLowerCase();
    if (p.contains('tutor') || p.contains('educat') || p.contains('teach')) return Icons.menu_book_rounded;
    if (p.contains('doctor') || p.contains('medic') || p.contains('health')) return Icons.medical_services_outlined;
    if (p.contains('lawyer') || p.contains('legal')) return Icons.gavel_outlined;
    if (p.contains('engineer')) return Icons.engineering_outlined;
    if (p.contains('plumb')) return Icons.plumbing_outlined;
    if (p.contains('electric')) return Icons.electrical_services;
    if (p.contains('clean')) return Icons.cleaning_services;
    if (p.contains('carpent')) return Icons.carpenter;
    if (p.contains('paint')) return Icons.format_paint_outlined;
    if (p.contains('architect')) return Icons.architecture;
    if (p.contains('account') || p.contains('financ')) return Icons.account_balance_outlined;
    if (p.contains('comput') || p.contains('it ') || p.contains('developer') || p.contains('software')) return Icons.computer_outlined;
    if (p.contains('beauty') || p.contains('salon') || p.contains('makeup')) return Icons.face_retouching_natural_outlined;
    if (p.contains('fitness') || p.contains('trainer') || p.contains('gym')) return Icons.fitness_center_outlined;
    if (p.contains('photo')) return Icons.camera_alt_outlined;
    return Icons.work_outline_rounded;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// _PressableCard — the card's outer shell: background, border, shadow,
// rounded corners, and the interaction animations (press-scale, hover).
// Isolated as its own tiny StatefulWidget so ProfessionalCard itself can
// stay a cheap, stateless, easily-rebuilt widget — only this shell holds
// any animation state.
// ═══════════════════════════════════════════════════════════════════════
class _PressableCard extends StatefulWidget {
  const _PressableCard({
    super.key,
    required this.onTap,
    required this.width,
    required this.height,
    required this.radius,
    required this.child,
  });

  final VoidCallback onTap;
  final double width;
  final double height;
  final double radius;
  final Widget child;

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _pressed   = false;
  bool _hovering  = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(widget.radius);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit:  (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTapDown:   (_) => _setPressed(true),
        onTapCancel: ()  => _setPressed(false),
        onTapUp:     (_) => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale:    _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve:    Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve:    Curves.easeOut,
            width:  widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color:        context.colors.surface,
              borderRadius: borderRadius,
              border:       Border.all(color: _hovering ? context.colors.primary.withOpacity(0.35) : context.colors.divider),
              // Single soft shadow — enough to lift the card off the page
              // without the heavy double-shadow look.
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withOpacity(_hovering ? 0.10 : 0.07),
                  blurRadius: _hovering ? 16 : 12,
                  offset:     Offset(0, _hovering ? 6 : 4),
                ),
              ],
            ),
            child: ClipRRect(borderRadius: borderRadius, child: widget.child),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// _ShimmerBox — animated loading placeholder for the photo. A single
// looping AnimationController sweeps a gradient across the box instead of
// showing a static gradient block, isolated in its own RepaintBoundary
// (via the caller) so the sweep animation never triggers a repaint of
// anything else on the card.
// ═══════════════════════════════════════════════════════════════════════
class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox();

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final sweep = (_controller.value * 3.2) - 1.6; // sweeps well past both edges
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) => LinearGradient(
            begin:  Alignment(sweep - 0.6, 0),
            end:    Alignment(sweep + 0.6, 0),
            colors: const [Color(0xFFE2E8F0), Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
            stops:  const [0.15, 0.5, 0.85],
          ).createShader(rect),
          child: Container(color: const Color(0xFFE2E8F0)),
        );
      },
    );
  }
}