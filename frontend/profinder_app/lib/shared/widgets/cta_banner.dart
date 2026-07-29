// lib/shared/widgets/cta_banner.dart
//
// GLOBAL small CTA/promo banner card — poore app mein jahan bhi chhota
// promo/CTA card chahiye (guest ko "become a professional" dikhana ho,
// professional ko "upgrade your plan" ya "add bank details" dikhana
// ho, home pe "AI Pick" jaisa highlight card ho, ya kal koi aur role/
// screen ko kuch aur) — sab isi ek widget ko import karke apni values
// pass karte hain. Ek hi jagah maintain hota hai, sab jagah consistent
// dikhta hai.
//
// Naam history: pehle "BecomeProBanner" (sirf guest/customer promo
// samjha jata tha), fir "PromoCard" rakha gaya, lekin ab yeh
// professional home, wallet, aur AI-pick jaisi jagah bhi use ho raha
// hai — isliye "CtaBanner" (generic call-to-action banner) sabse theek
// naam hai, kisi ek role/feature se bandha hua nahi hai.
//
// Leading badge do tarah se dikh sakta hai:
//   - `emoji`  diya ho to emoji dikhta hai (e.g. '🚀', '🏦', '✨')
//   - warna `icon` (IconData) fallback ke taur pe dikhta hai
//
// FIX: pehle jab yeh card kisi tang (narrow) jagah mein render hota
// tha — grid cell, half-width column, chhoti screen — to badge aur
// CTA button apni fixed width le lete the, aur beech mein text ke
// liye itni kam jagah bachti thi ke title ek-ek word alag line pe
// chala jata tha aur lamba word beech mein hi toot jata. Ab
// LayoutBuilder se width check hoti hai: agar jagah tang hai to
// layout khud stack ho jata hai (button neeche, poori width mein) —
// text kabhi ajeeb tarah nahi toot-ta.

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_context_ext.dart';
import '../../core/constants/app_sizes.dart';

class CtaBanner extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final String ctaLabel;

  /// Emoji badge — pass karo to yeh IconData `icon` se zyada priority
  /// leta hai (e.g. '🚀', '🏦', '✨', '👑').
  final String? emoji;
  /// Fallback icon — sirf tab dikhta hai jab `emoji` null ho.
  final IconData icon;

  /// Badge aur CTA button ka gradient — role/screen ke hisaab se
  /// badal sakte ho (guest ke liye indigo, professional ke liye amber,
  /// wallet ke liye teal, wagera). Default AppColors.ctaGradientStart/
  /// End hi hai, jaisa pehle tha.
  final Color accentStart;
  final Color accentEnd;

  const CtaBanner({
    super.key,
    required this.isDark,
    required this.onTap,
    this.title = 'Grow Your Business',
    this.subtitle = 'Join 500+ professionals on ProFinder',
    this.ctaLabel = 'Join Now',
    this.emoji,
    this.icon = Icons.workspace_premium_rounded,
    this.accentStart = AppColors.ctaGradientStart,
    this.accentEnd = AppColors.ctaGradientEnd,
  });

  static const double _narrowBreakpoint = 320;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenPadding - 10,
        vertical: AppSizes.xs,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: isDark
              ? Colors.white.withOpacity(0.05)
              : accentStart.withOpacity(0.1),
          highlightColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
                    : const [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.2)
                    : accentStart.withOpacity(0.35),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : accentStart.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < _narrowBreakpoint;
                return narrow ? _narrowLayout(context) : _wideLayout(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  // Wide layout — badge, text aur button ek hi row mein (side by side).
  Widget _wideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _badge(),
        const SizedBox(width: 14),
        Expanded(child: _texts(context)),
        const SizedBox(width: 10),
        _ctaButton(),
      ],
    );
  }

  // Narrow layout — badge+text upar, CTA button neeche poori width
  // mein. Yahi wajah se tang jagah mein bhi text saaf wrap hota hai,
  // ek-ek word alag line pe nahi bikharta.
  Widget _narrowLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _badge(),
            const SizedBox(width: 12),
            Expanded(child: _texts(context)),
          ],
        ),
        const SizedBox(height: 12),
        _ctaButton(fullWidth: true),
      ],
    );
  }

  // Leading badge — emoji diya ho to emoji, warna icon.
  Widget _badge() {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentStart, accentEnd],
        ),
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: accentStart.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: emoji != null
          ? Text(emoji!, style: const TextStyle(fontSize: 20, height: 1))
          : Icon(icon, color: Colors.white, size: 21),
    );
  }

  Widget _texts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
            letterSpacing: -0.3,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w400,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _ctaButton({bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentStart, accentEnd],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: accentStart.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            ctaLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
        ],
      ),
    );
  }
}