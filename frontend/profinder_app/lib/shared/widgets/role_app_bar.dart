// lib/shared/widgets/role_app_bar.dart
//
// Role-specific AppBars for ProFinder. All four share the SAME brand lockup
// (the existing PF mark from AppLogoMark + the app name) and the SAME theme
// colors (context.colors / AppColors) — only the right-hand actions differ:
//
//   Guest         → [search] Login  Register
//   Customer      → notifications (+badge)  avatar
//   Professional  → notifications (+badge)  avatar (verified tick)
//   Admin         → [search] notifications (+badge)  admin avatar, "Admin" tag
//
// The bars are slivers (pinned) so they drop straight into the existing
// CustomScrollViews, right BELOW the AnnouncementBanner:
//
//   Status bar → AnnouncementBanner → Role AppBar → page content
//
// Greeting / name / location / search deliberately do NOT live in the bar;
// use [RoleGreeting] in the page body instead.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_context_ext.dart';
import '../../core/utils/app_helpers.dart';
import '../../core/widgets/app_logo.dart';
import '../../l10n/generated/app_localizations.dart';

const double kRoleAppBarHeight = 60;
const double kRoleAppBarGlassHeight = 70;

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
          color: Colors.white.withOpacity(opacity),
        ),
      );
}

/// Horizontal padding that follows screen width (phone / tablet / desktop+web).
double roleAppBarHPad(double width) {
  final base = width >= 1024 ? 32.0 : (width >= 600 ? 24.0 : 16.0);
  // On very wide screens keep the bar content aligned with the 1280px page body.
  final extra = width > 1280 ? (width - 1280) / 2 : 0.0;
  return base + extra;
}

/// "Good morning" / "Good afternoon" / "Good evening" (existing l10n keys).
String roleTimeGreeting(BuildContext context) {
  final t = AppLocalizations.of(context)!;
  final hour = DateTime.now().hour;
  if (hour < 12) return t.homeGoodMorning;
  if (hour < 17) return t.homeGoodAfternoon;
  return t.homeGoodEvening;
}

// ─────────────────────────────────────────────────────────────────────────
// Brand lockup  [PF mark] ProFinder  (+ optional small role tag)
// ─────────────────────────────────────────────────────────────────────────
class BrandLockup extends StatelessWidget {
  final String? badgeLabel;
  final Color? badgeColor;

  /// true when the bar has a coloured background (white text + glass logo tile).
  final bool onGradient;

  const BrandLockup({super.key, this.badgeLabel, this.badgeColor, this.onGradient = false});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 600;
    final tag = onGradient ? Colors.white : (badgeColor ?? context.colors.primary);

    final logo = onGradient
        // Same PF mark, "inverted" variant (white disc, brand-coloured P/F) so it
        // stays clearly visible on the coloured bar, inside a frosted tile.
        ? Container(
            width: wide ? 50 : 46,
            height: wide ? 50 : 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.32)),
            ),
            child: Center(child: AppLogoMark(size: wide ? 42 : 38, inverted: true)),
          )
        : AppLogoMark(size: wide ? 38 : 34);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        SizedBox(width: onGradient ? 10 : 8),
        Flexible(
          child: Text(
            AppStrings.appName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: wide ? 21 : 19,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: onGradient ? Colors.white : context.colors.textPrimary,
            ),
          ),
        ),
        if (badgeLabel != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tag.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tag.withOpacity(0.35)),
            ),
            child: Text(
              badgeLabel!,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tag),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Shared pinned shell
// ─────────────────────────────────────────────────────────────────────────
class RoleAppBarSliver extends StatelessWidget {
  final Widget leading;
  final List<Widget> actions;

  /// When set, the bar uses this role colour as its background (with the soft
  /// translucent-white circles used by the announcement banner) and white content.
  final Color? backgroundColor;

  const RoleAppBarSliver({
    super.key,
    required this.leading,
    this.actions = const [],
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final pad = roleAppBarHPad(MediaQuery.sizeOf(context).width);

    if (backgroundColor != null) {
      const radius = BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      );
      return SliverAppBar(
        pinned: true,
        primary: true,
        automaticallyImplyLeading: false,
        centerTitle: false,
        toolbarHeight: kRoleAppBarGlassHeight,
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 4,
        shadowColor: backgroundColor!.withOpacity(0.45),
        shape: const RoundedRectangleBorder(borderRadius: radius),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        flexibleSpace: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: backgroundColor!),
              Positioned(
                right: -36,
                top: -52,
                child: _GlassCircle(size: 150, opacity: 0.10),
              ),
              Positioned(
                right: 70,
                bottom: -64,
                child: _GlassCircle(size: 110, opacity: 0.08),
              ),
            ],
          ),
        ),
        titleSpacing: pad,
        title: leading,
        actions: [...actions, SizedBox(width: pad)],
      );
    }

    return SliverAppBar(
      pinned: true,
      primary: true, // adds the status-bar inset itself when no SafeArea wraps it
      automaticallyImplyLeading: false,
      centerTitle: false,
      toolbarHeight: kRoleAppBarHeight,
      backgroundColor: context.colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black.withOpacity(0.12),
      shape: Border(bottom: BorderSide(color: context.colors.divider)),
      titleSpacing: pad,
      title: leading,
      actions: [...actions, SizedBox(width: pad)],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Building blocks
// ─────────────────────────────────────────────────────────────────────────
class AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final int badgeCount;
  final bool onGradient;
  final Color? badgeBorderColor;

  const AppBarIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badgeCount = 0,
    this.onGradient = false,
    this.badgeBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: onGradient ? Colors.white.withOpacity(0.18) : c.primary.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
                side: onGradient
                    ? BorderSide(color: Colors.white.withOpacity(0.28))
                    : BorderSide.none,
              ),
              child: InkWell(
                onTap: onPressed,
                customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(icon, size: 22, color: onGradient ? Colors.white : c.textPrimary),
                ),
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: BoxDecoration(
                    color: onGradient ? AppColors.badgeTopRated : AppColors.error,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: badgeBorderColor ?? c.surface, width: 1.5),
                  ),
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AppBarAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final Color ringColor;
  final String tooltip;
  final VoidCallback onTap;
  final bool isVerified;
  final IconData? fallbackIcon;
  final bool onGradient;

  const AppBarAvatar({
    super.key,
    required this.name,
    required this.ringColor,
    required this.tooltip,
    required this.onTap,
    this.photoUrl,
    this.isVerified = false,
    this.fallbackIcon,
    this.onGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: onGradient ? Colors.white.withOpacity(0.55) : ringColor,
                width: 2,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: onGradient ? 18 : 16,
                  backgroundColor: onGradient ? Colors.white.withOpacity(0.22) : ringColor.withOpacity(0.12),
                  backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
                  child: hasPhoto
                      ? null
                      : (fallbackIcon != null
                          ? Icon(fallbackIcon, size: 18, color: onGradient ? Colors.white : ringColor)
                          : Text(
                              AppHelpers.getInitials(name),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: onGradient ? Colors.white : ringColor,
                              ),
                            )),
                ),
                if (isVerified)
                  Positioned(
                    right: -3,
                    bottom: -3,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: context.colors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.colors.surface, width: 1.5),
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 8),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 1. GUEST — logo, [search], Login, Register. No avatar / notifications.
// ─────────────────────────────────────────────────────────────────────────
class GuestAppBar extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback? onSearch;

  const GuestAppBar({
    super.key,
    required this.onLogin,
    required this.onRegister,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final c = context.colors;
    final width = MediaQuery.sizeOf(context).width;
    // Very narrow phones: drop the search icon (the bottom nav has a Search tab)
    // so Login + Register never overflow.
    final showSearch = onSearch != null && width >= 400;

    return RoleAppBarSliver(
      backgroundColor: c.primary,
      leading: const BrandLockup(onGradient: true),
      actions: [
        if (showSearch) ...[
          AppBarIconButton(
            icon: Icons.search_rounded,
            tooltip: t.navSearch,
            onPressed: onSearch!,
            onGradient: true,
          ),
          const SizedBox(width: 6),
        ],
        TextButton(
          onPressed: onLogin,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          child: Text(t.login),
        ),
        const SizedBox(width: 4),
        FilledButton(
          onPressed: onRegister,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: c.primary,
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          child: Text(t.register),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 2. CUSTOMER and 3. PROFESSIONAL — logo, notifications (+badge), avatar.
// ─────────────────────────────────────────────────────────────────────────
class _AuthedUserAppBar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final int unreadCount;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;
  final Color ringColor;
  final bool isVerified;
  final Color? backgroundColor;

  const _AuthedUserAppBar({
    required this.name,
    required this.photoUrl,
    required this.unreadCount,
    required this.onNotifications,
    required this.onProfile,
    required this.ringColor,
    this.isVerified = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final glass = backgroundColor != null;
    return RoleAppBarSliver(
      backgroundColor: backgroundColor,
      leading: BrandLockup(onGradient: glass),
      actions: [
        AppBarIconButton(
          icon: Icons.notifications_outlined,
          tooltip: t.notifications,
          badgeCount: unreadCount,
          onPressed: onNotifications,
          onGradient: glass,
          badgeBorderColor: backgroundColor,
        ),
        const SizedBox(width: 12),
        AppBarAvatar(
          name: name,
          photoUrl: photoUrl,
          ringColor: ringColor,
          tooltip: t.profile,
          isVerified: isVerified,
          onGradient: glass,
          onTap: onProfile,
        ),
      ],
    );
  }
}

class CustomerAppBar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final int unreadCount;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  const CustomerAppBar({
    super.key,
    required this.name,
    required this.onNotifications,
    required this.onProfile,
    this.photoUrl,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) => _AuthedUserAppBar(
        name: name,
        photoUrl: photoUrl,
        unreadCount: unreadCount,
        onNotifications: onNotifications,
        onProfile: onProfile,
        ringColor: AppColors.customerColor,
        // Same background the customer header always had: theme primary blue.
        backgroundColor: context.colors.primary,
      );
}

class ProfessionalAppBar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final int unreadCount;
  final bool isVerified;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  const ProfessionalAppBar({
    super.key,
    required this.name,
    required this.onNotifications,
    required this.onProfile,
    this.photoUrl,
    this.unreadCount = 0,
    this.isVerified = false,
  });

  @override
  Widget build(BuildContext context) => _AuthedUserAppBar(
        name: name,
        photoUrl: photoUrl,
        unreadCount: unreadCount,
        onNotifications: onNotifications,
        onProfile: onProfile,
        ringColor: AppColors.professionalColor,
        isVerified: isVerified,
        backgroundColor: AppColors.professionalColor,
      );
}

// ─────────────────────────────────────────────────────────────────────────
// 4. ADMIN — logo + "Admin" tag, [search], notifications (+badge), admin avatar.
// ─────────────────────────────────────────────────────────────────────────
class AdminAppBar extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;
  final VoidCallback? onSearch;
  final String name;

  const AdminAppBar({
    super.key,
    required this.onNotifications,
    required this.onProfile,
    this.unreadCount = 0,
    this.onSearch,
    this.name = '',
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final showSearch = onSearch != null && width >= 400;

    return RoleAppBarSliver(
      backgroundColor: AppColors.adminColor,
      leading: BrandLockup(
        badgeLabel: t.tsRoleAdmin,
        badgeColor: AppColors.adminColor,
        onGradient: true,
      ),
      actions: [
        if (showSearch) ...[
          AppBarIconButton(
            icon: Icons.search_rounded,
            tooltip: t.navSearch,
            onPressed: onSearch!,
            onGradient: true,
          ),
          const SizedBox(width: 8),
        ],
        AppBarIconButton(
          icon: Icons.notifications_outlined,
          tooltip: t.notifications,
          badgeCount: unreadCount,
          onPressed: onNotifications,
          onGradient: true,
          badgeBorderColor: AppColors.adminColor,
        ),
        const SizedBox(width: 12),
        AppBarAvatar(
          name: name,
          ringColor: AppColors.adminColor,
          tooltip: t.profile,
          fallbackIcon: Icons.admin_panel_settings_rounded,
          onGradient: true,
          onTap: onProfile,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Page-body greeting (NOT part of the AppBar)
// ─────────────────────────────────────────────────────────────────────────
class RoleGreeting extends StatelessWidget {
  final String greeting; // e.g. "Good evening"
  final String name;
  final String subtitle;
  final Widget? footer;

  const RoleGreeting({
    super.key,
    required this.greeting,
    required this.name,
    required this.subtitle,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final width = MediaQuery.sizeOf(context).width;
    final pad = width >= 600 ? 24.0 : 16.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 18, pad, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting, $name',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: width >= 600 ? 26 : 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.3,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14.5, height: 1.35, color: c.textSecondary),
          ),
          if (footer != null) ...[const SizedBox(height: 8), footer!],
        ],
      ),
    );
  }
}