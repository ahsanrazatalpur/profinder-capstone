// Universal profile hero header card shared across Guest, Customer, Professional, and Admin roles.
//
// Features customizable gradient themes, network or local avatar providers with initials fallback,
// status badges, and optional KPI metric strips.

import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Action button specification rendered within [ProfileHeaderCard].
/// [primary] indicates whether the button uses filled or outlined styling.
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

/// Represents a metric statistic tile (e.g. Rating, Experience, Bookings)
/// displayed within the KPI summary strip of [ProfileHeaderCard].
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
  /// User full name or headline displayed in the hero section.
  final String? name;

  /// Optional badge label (e.g. 'Browsing as Guest', 'Premium Member').
  final String? statusText;

  /// Leading icon displayed inside the status badge.
  final IconData statusIcon;

  /// Secondary subtitle text, typically displaying user email or profession.
  final String? description;

  /// Action buttons rendered inside the header card.
  final List<ProfileHeaderAction> actions;

  /// Key performance indicator statistics displayed in the summary strip.
  final List<ProfileHeaderStat> stats;

  /// Fallback icon displayed when no image or initials are available.
  final IconData avatarIcon;

  /// Remote image URL for user profile picture.
  final String? avatarImageUrl;

  /// Local or in-memory image provider taking precedence over [avatarImageUrl].
  final ImageProvider? avatarImageProvider;

  /// User initials displayed when no profile image is available.
  final String? avatarFallbackText;

  /// Callback triggered when tapping the profile avatar.
  final VoidCallback? onAvatarTap;

  /// Small overlay badge anchored to the bottom-right corner of the avatar.
  final Widget? avatarBadge;

  /// Decorative icon parameter preserved for API compatibility.
  final IconData decorativeIconPrimary;
  final IconData? decorativeIconSecondary;

  /// Primary accent color used to generate the hero gradient.
  final Color accentColor;
  final Color accentColorSecondary;

  /// Explicit color stops for light theme gradient.
  final List<Color>? heroGradientLight;

  /// Explicit color stops for dark theme gradient.
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
    this.accentColor = AppColors.indigo,
    this.accentColorSecondary = AppColors.violet,
    this.heroGradientLight,
    this.heroGradientDark,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = ResponsiveUtils.scaleForWidth(width);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarRadius = ResponsiveUtils.sp(40, scale, min: 36, max: 44);

    final gradientLight =
        heroGradientLight ?? [accentColor, accentColorSecondary];
    final gradientDark =
        heroGradientDark ??
        [
          Color.lerp(accentColor, Colors.black, 0.35)!,
          Color.lerp(accentColorSecondary, Colors.black, 0.55)!,
        ];

    final radius = BorderRadius.circular(
      ResponsiveUtils.sp(22, scale, min: 20, max: 24),
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? gradientDark : gradientLight,
        ),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : accentColor.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            // Soft translucent-white glass layers (same as the app bar)
            const Positioned(
              right: -36,
              top: -52,
              child: _GlassCircle(size: 150, opacity: 0.10),
            ),
            const Positioned(
              right: 70,
              bottom: -64,
              child: _GlassCircle(size: 110, opacity: 0.08),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                ResponsiveUtils.sp(20, scale, min: 18, max: 24),
                ResponsiveUtils.sp(24, scale, min: 22, max: 28),
                ResponsiveUtils.sp(20, scale, min: 18, max: 24),
                ResponsiveUtils.sp(20, scale, min: 18, max: 24),
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
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    blurRadius: 16,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: avatarRadius,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.2,
                                ),
                                backgroundImage: _resolveAvatarImage(),
                                onBackgroundImageError:
                                    _resolveAvatarImage() != null
                                    ? (_, _) {}
                                    : null,
                                child: _resolveAvatarImage() == null
                                    ? _avatarFallback(scale)
                                    : null,
                              ),
                            ),
                            if (avatarBadge != null)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: avatarBadge!,
                              ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: ResponsiveUtils.sp(16, scale, min: 14, max: 18),
                      ),
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
                                  fontSize: ResponsiveUtils.sp(
                                    23,
                                    scale,
                                    min: 20,
                                    max: 26,
                                  ),
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
                                  fontSize: ResponsiveUtils.sp(
                                    12.5,
                                    scale,
                                    min: 12,
                                    max: 13,
                                  ),
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.75),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                            if (statusText != null) ...[
                              SizedBox(
                                height: (name != null || description != null)
                                    ? 10
                                    : 0,
                              ),
                              Container(
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  6,
                                  12,
                                  6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusChip,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      statusIcon,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        statusText!,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: ResponsiveUtils.sp(
                                            13,
                                            scale,
                                            min: 12.5,
                                            max: 13.5,
                                          ),
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

                  // Optional KPI metric strip rendered dynamically according to role data.
                  if (stats.isNotEmpty) ...[
                    SizedBox(
                      height: ResponsiveUtils.sp(22, scale, min: 18, max: 22),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppSizes.radius18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
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
                    SizedBox(
                      height: ResponsiveUtils.sp(18, scale, min: 16, max: 18),
                    ),
                    Row(
                      children: [
                        for (int i = 0; i < actions.length; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          Expanded(
                            child: _actionButton(
                              action: actions[i],
                              scale: scale,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(ProfileHeaderStat stat, double scale) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
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
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _statDivider() => Container(
    width: 1,
    height: 34,
    color: Colors.white.withValues(alpha: 0.15),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius28),
          ),
        ),
        onPressed: action.onPressed,
        icon: Icon(
          action.icon,
          size: ResponsiveUtils.sp(18, scale, min: 16, max: 22),
        ),
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
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1.5,
        ),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius28),
        ),
      ),
      onPressed: action.onPressed,
      icon: Icon(
        action.icon,
        size: ResponsiveUtils.sp(18, scale, min: 16, max: 22),
      ),
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
    if (avatarImageUrl != null && avatarImageUrl!.isNotEmpty) {
      return NetworkImage(avatarImageUrl!);
    }
    return null;
  }

  /// Fallback content when no image is available (initials text or fallback icon).
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

/// Translucent white circle used for the glass/layered background effect.
class _GlassCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _GlassCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: opacity),
    ),
  );
}
