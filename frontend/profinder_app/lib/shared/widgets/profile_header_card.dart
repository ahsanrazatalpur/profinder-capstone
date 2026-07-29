// lib/shared/widgets/profile_header_card.dart
//
// GLOBAL profile header card — Guest, Customer, Professional, Admin
// sab isi ek widget ko use karte hain, bas apna accentColor/data pass
// karo. Design = premium solid-gradient "hero" card (avatar left,
// name/email/status pill right, optional KPI stats strip niche) —
// jo pehle professional ke liye custom bana tha, wahi ab yahan global
// default hai taake sab roles ek hi look share karein.
//
//   - avatar: icon / network image / local image (edit ke dauran
//     picked File/bytes preview) — teeno support hote hain
//   - avatar tap + choti edit-badge overlay (e.g. camera icon)
//   - avatar fallback text (initials) jab photo na ho
//   - naam (bada bold headline) — guest ke liye null rakho
//   - status pill (icon + text) — optional, e.g. "Premium Member"
//   - description text — optional (e.g. email)
//   - optional KPI stats strip (Rating/Experience/Rate, Bookings/Saved..)
//   - action buttons (0, 1 ya 2+ buttons — primary + outlined variants)
//   - accent color se hero gradient derive hota hai (role ke hisaab
//     se badal sakte ho — professional ka purple hi ab default hai)

import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/theme/theme_context_ext.dart';

/// Ek action button ka simple spec — [ProfileHeaderCard] isse render
/// karta hai. `primary: true` = filled white button (jaise "Register"),
/// `primary: false` = outlined white-border button (jaise "Login").
class ProfileHeaderAction {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;

  const ProfileHeaderAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });
}

/// Ek KPI stat item — [ProfileHeaderCard] ke stats row mein use hota
/// hai, e.g. Rating / Experience / Rate (professional), Bookings /
/// Saved (customer). Empty list pass karo to poori strip hi hide ho
/// jati hai (e.g. guest ke liye).
class ProfileHeaderStat {
  final IconData icon;
  final String value;
  final String label;

  const ProfileHeaderStat({
    required this.icon,
    required this.value,
    required this.label,
  });
}

class ProfileHeaderCard extends StatelessWidget {
  /// Bada bold headline — e.g. user ka naam. Guest ke liye null rakho.
  final String? name;

  /// Status pill ke andar text, e.g. "Browsing as Guest" / "Premium
  /// Member" / category name. Null ho to pill hi nahi dikhta.
  final String? statusText;
  /// Status pill ka leading icon.
  final IconData statusIcon;
  /// Naam ke neeche wala subtitle (e.g. email). Null ho to skip.
  final String? description;
  /// 0 se 4 tak buttons — guest ke liye Login/Register, baaki roles
  /// chahe to khali list bhi pass kar sakte hain.
  final List<ProfileHeaderAction> actions;
  /// Optional KPI stats row (Rating / Experience / Rate, Bookings /
  /// Saved, waghera) — role jo bhi real data pass kare wahi dikhta
  /// hai. Empty list = strip hidden (default).
  final List<ProfileHeaderStat> stats;

  /// Avatar ke beech mein dikhne wala icon (jab tak koi image na ho).
  final IconData avatarIcon;
  /// Agar real profile photo network se aani hai, yahan URL pass karo.
  final String? avatarImageUrl;
  /// Agar local image (picked File/bytes preview, edit-mode) dikhani
  /// hai, yahan ImageProvider pass karo — yeh avatarImageUrl se
  /// zyada priority leta hai.
  final ImageProvider? avatarImageProvider;
  /// Jab koi image (local ya network) na ho, iske bajaye yeh text
  /// (e.g. initials "AK") dikhta hai; agar yeh bhi null ho to
  /// avatarIcon fallback hota hai.
  final String? avatarFallbackText;
  /// Avatar tap handler — e.g. edit-mode mein photo change karne ke
  /// liye. Null ho to avatar tap-disabled rehta hai.
  final VoidCallback? onAvatarTap;
  /// Avatar ke bottom-right corner par choti overlay badge — e.g.
  /// camera edit icon. Null ho to koi badge nahi dikhta.
  final Widget? avatarBadge;

  /// (Ab visually use nahi hote — solid hero gradient ki wajah se
  /// background icons dikhte nahi — params sirf backward-compat ke
  /// liye rakhe hain, safely ignore ho jate hain.)
  final IconData decorativeIconPrimary;
  final IconData? decorativeIconSecondary;

  /// Hero gradient inhi do colors se banta hai. Default professional
  /// ka purple hai (jo pehle se tha) — koi bhi role apna color de
  /// sakta hai.
  final Color accentColor;
  final Color accentColorSecondary;

  /// Hero gradient ke exact color stops — pass na karo to accentColor/
  /// accentColorSecondary se hi darker dark-mode variant derive ho
  /// jata hai. Professional ke liye default value bilkul wahi hai jo
  /// pehle hardcoded thi.
  final List<Color>? heroGradientLight;
  final List<Color>? heroGradientDark;

  const ProfileHeaderCard({
    super.key,
    this.name,
    this.statusText,
    this.description,
    this.statusIcon = Icons.person_outline_rounded,
    this.actions = const [],
    this.stats = const [],
    this.avatarIcon = Icons.person_rounded,
    this.avatarImageUrl,
    this.avatarImageProvider,
    this.avatarFallbackText,
    this.onAvatarTap,
    this.avatarBadge,
    this.decorativeIconPrimary = Icons.person_rounded,
    this.decorativeIconSecondary = Icons.work_rounded,
    this.accentColor = const Color(0xFF6366F1),
    this.accentColorSecondary = const Color(0xFF8B5CF6),
    this.heroGradientLight,
    this.heroGradientDark,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = ResponsiveUtils.scaleForWidth(width);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarRadius = ResponsiveUtils.sp(40, scale, min: 36, max: 44);

    final gradientLight = heroGradientLight ?? [accentColor, accentColorSecondary];
    final gradientDark = heroGradientDark ??
        [
          Color.lerp(accentColor, Colors.black, 0.35)!,
          Color.lerp(accentColorSecondary, Colors.black, 0.55)!,
        ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.sp(20, scale, min: 18, max: 24),
        ResponsiveUtils.sp(24, scale, min: 22, max: 28),
        ResponsiveUtils.sp(20, scale, min: 18, max: 24),
        ResponsiveUtils.sp(20, scale, min: 18, max: 24),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? gradientDark : gradientLight,
        ),
        borderRadius: BorderRadius.circular(ResponsiveUtils.sp(22, scale, min: 20, max: 24)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : accentColor.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Glowing avatar ring
              GestureDetector(
                onTap: onAvatarTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.85), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.25),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: avatarRadius,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: _resolveAvatarImage(),
                        onBackgroundImageError: _resolveAvatarImage() != null ? (_, __) {} : null,
                        child: _resolveAvatarImage() == null ? _avatarFallback(scale) : null,
                      ),
                    ),
                    if (avatarBadge != null)
                      Positioned(right: 0, bottom: 0, child: avatarBadge!),
                  ],
                ),
              ),
              SizedBox(width: ResponsiveUtils.sp(16, scale, min: 14, max: 18)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (name != null) ...[
                      Text(
                        name!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.sp(23, scale, min: 20, max: 26),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.1,
                          height: 1.15,
                        ),
                      ),
                    ],
                    if (description != null) ...[
                      SizedBox(height: name != null ? 3 : 0),
                      Text(
                        description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.sp(12.5, scale, min: 12, max: 13),
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.75),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                    if (statusText != null) ...[
                      SizedBox(height: (name != null || description != null) ? 10 : 0),
                      Container(
                        padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                statusText!,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.sp(13, scale, min: 12.5, max: 13.5),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // KPI stats strip — role jo data pass kare, wahi dikhta hai
          if (stats.isNotEmpty) ...[
            SizedBox(height: ResponsiveUtils.sp(22, scale, min: 18, max: 22)),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  for (int i = 0; i < stats.length; i++) ...[
                    if (i > 0) _statDivider(),
                    Expanded(child: _statColumn(stats[i], scale)),
                  ],
                ],
              ),
            ),
          ],

          if (actions.isNotEmpty) ...[
            SizedBox(height: ResponsiveUtils.sp(18, scale, min: 16, max: 18)),
            Row(
              children: [
                for (int i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(
                    child: _actionButton(action: actions[i], scale: scale),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statColumn(ProfileHeaderStat stat, double scale) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(stat.icon, color: Colors.white, size: 16),
        ),
        const SizedBox(height: 6),
        Text(
          stat.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: ResponsiveUtils.sp(15, scale, min: 14, max: 16),
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          stat.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: ResponsiveUtils.sp(10, scale, min: 10, max: 11),
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 34,
        color: Colors.white.withOpacity(0.15),
      );

  Widget _actionButton({
    required ProfileHeaderAction action,
    required double scale,
  }) {
    if (action.primary) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: accentColor,
          elevation: 0,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        onPressed: action.onPressed,
        icon: Icon(action.icon, size: ResponsiveUtils.sp(18, scale, min: 16, max: 22)),
        label: Text(
          action.label,
          style: TextStyle(
            fontSize: ResponsiveUtils.sp(14, scale, min: 13, max: 17),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withOpacity(0.6), width: 1.5),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      onPressed: action.onPressed,
      icon: Icon(action.icon, size: ResponsiveUtils.sp(18, scale, min: 16, max: 22)),
      label: Text(
        action.label,
        style: TextStyle(
          fontSize: ResponsiveUtils.sp(14, scale, min: 13, max: 17),
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// Local image (edit-preview) > network image > none.
  ImageProvider? _resolveAvatarImage() {
    if (avatarImageProvider != null) return avatarImageProvider;
    if (avatarImageUrl != null && avatarImageUrl!.isNotEmpty) return NetworkImage(avatarImageUrl!);
    return null;
  }

  /// Jab koi image na ho — initials text agar diya ho, warna avatarIcon.
  Widget _avatarFallback(double scale) {
    if (avatarFallbackText != null && avatarFallbackText!.isNotEmpty) {
      return Center(
        child: Text(
          avatarFallbackText!,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveUtils.sp(22, scale, min: 18, max: 24),
          ),
        ),
      );
    }
    return Center(
      child: Icon(
        avatarIcon,
        color: Colors.white,
        size: ResponsiveUtils.sp(28, scale, min: 24, max: 32),
      ),
    );
  }
}