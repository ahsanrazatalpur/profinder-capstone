// lib/shared/widgets/universal_app_bar.dart
//
// UNIVERSAL app bar for every inner screen (everything that is not a home
// tab). Same glass look as the home RoleAppBars:
//
//   [ back tile ]  [page icon] Page title ................ [actions]
//
//   • Role colour:  guest / customer → brand blue
//                   professional     → purple
//                   admin            → red
//     (picked automatically from AuthProvider; pass [color] to override)
//   • Rounded bottom corners + soft translucent-white glass layers
//   • Back button = frosted glass tile (hover / press feedback)
//   • Title is left-aligned by default (formal, consistent with the home bar);
//     set [centerTitle] to centre it
//   • Responsive paddings (phone / tablet / desktop)
//   • Optional [subtitle] (small line under the title, e.g. a live count)
//
// Usage (drop-in for Scaffold.appBar):
//
//   Scaffold(
//     appBar: UniversalAppBar(title: t.aboutTitle, icon: Icons.info_outline_rounded),
//     ...
//   )
//
// Tab screens that have no route to pop (e.g. embedded bottom-nav tabs) pass
// [onBack] (e.g. switch to the Home tab) and the back tile still shows.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_context_ext.dart';
import '../../services/auth_provider.dart';
import 'role_app_bar.dart';

export 'role_app_bar.dart' show AppBarIconButton;

const double kUniversalAppBarHeight = 64;

/// Bar colour for the current user's role.
/// guest / customer → brand primary, professional → purple, admin → red.
Color universalBarColor(BuildContext context) {
  try {
    final auth = Provider.of<AuthProvider>(context);
    if (auth.isLoggedIn) {
      if (auth.isProfessional) return AppColors.professionalColor;
      if (auth.isAdmin) return AppColors.adminColor;
    }
  } catch (_) {
    // No AuthProvider above this widget → fall through to the brand colour.
  }
  return context.colors.primary;
}

class _BarGlassCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _BarGlassCircle({required this.size, required this.opacity});

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

/// Frosted back tile — use it inside custom / hero bars too.
class UniversalBackButton extends StatelessWidget {
  /// Called when there is no route to pop (embedded tabs).
  final VoidCallback? onBack;

  /// Always wins over the default pop (e.g. confirm-before-leave screens,
  /// or screens that pop with a result).
  final VoidCallback? onPressed;

  const UniversalBackButton({super.key, this.onBack, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AppBarIconButton(
      icon: Icons.arrow_back_ios_new_rounded,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onGradient: true,
      onPressed: () {
        if (onPressed != null) {
          onPressed!();
        } else if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          onBack?.call();
        }
      },
    );
  }
}

/// Popup-menu action that looks exactly like [AppBarIconButton] (frosted tile),
/// for sort / filter / overflow menus inside a [UniversalAppBar].
class AppBarPopupButton<T> extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final PopupMenuItemBuilder<T> itemBuilder;
  final PopupMenuItemSelected<T>? onSelected;

  const AppBarPopupButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.itemBuilder,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: onSelected,
      itemBuilder: itemBuilder,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white.withOpacity(0.28)),
        ),
        child: Icon(icon, size: 22, color: Colors.white),
      ),
    );
  }
}

class UniversalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  /// Optional custom title content (e.g. avatar + name + status in a chat).
  /// When given it replaces the default icon + [title] row.
  final Widget? titleWidget;

  /// Small line under the title (optional) — e.g. a live count like "12 active".
  final String? subtitle;

  /// Page icon shown before the title (optional).
  final IconData? icon;

  /// Right-side actions — use [AppBarIconButton] (onGradient: true) so they
  /// match the back tile.
  final List<Widget> actions;

  /// Used when there is no route to pop (bottom-nav tabs).
  final VoidCallback? onBack;

  /// Always wins over the default pop (confirm-before-leave, pop with result).
  final VoidCallback? onBackPressed;

  /// Optional row under the title (e.g. a TabBar) — style it in white.
  final PreferredSizeWidget? bottom;

  /// null = auto (shown when the screen can pop, or [onBack] is given).
  final bool? showBack;

  final bool centerTitle;

  /// Override the role colour.
  final Color? color;

  const UniversalAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.subtitle,
    this.icon,
    this.actions = const [],
    this.onBack,
    this.onBackPressed,
    this.bottom,
    this.showBack,
    this.centerTitle = false,
    this.color,
  });

  @override
  Size get preferredSize => Size.fromHeight(
      kUniversalAppBarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 600;
    final pad = roleAppBarHPad(width);
    final bg = color ?? universalBarColor(context);
    final back = showBack ??
        (onBack != null || onBackPressed != null || Navigator.of(context).canPop());

    const radius = BorderRadius.only(
      bottomLeft: Radius.circular(24),
      bottomRight: Radius.circular(24),
    );

    final defaultTitle = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: wide ? 24 : 22, color: Colors.white),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: wide ? 21 : 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  height: subtitle == null ? null : 1.1,
                  color: Colors.white,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    return AppBar(
      primary: true,
      automaticallyImplyLeading: false,
      centerTitle: centerTitle,
      toolbarHeight: kUniversalAppBarHeight,
      bottom: bottom,
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 4,
      shadowColor: bg.withOpacity(0.45),
      shape: const RoundedRectangleBorder(borderRadius: radius),
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: bg),
            const Positioned(
              right: -36,
              top: -52,
              child: _BarGlassCircle(size: 150, opacity: 0.10),
            ),
            const Positioned(
              right: 70,
              bottom: -64,
              child: _BarGlassCircle(size: 110, opacity: 0.08),
            ),
          ],
        ),
      ),
      leadingWidth: back ? pad + 42 + 12 : 0,
      leading: back
          ? Padding(
              padding: EdgeInsets.only(left: pad, right: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: UniversalBackButton(onBack: onBack, onPressed: onBackPressed),
              ),
            )
          : null,
      titleSpacing: back ? 0 : pad,
      title: this.titleWidget ?? defaultTitle,
      actions: [...actions, SizedBox(width: pad)],
    );
  }
}