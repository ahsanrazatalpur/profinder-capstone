// lib/shared/widgets/announcement_banner.dart
//
// Announcement banner — matches the "Final Position" reference design.
// Data loading, dismiss persistence, callbacks and the public API are
// unchanged; only the look was rebuilt:
//   • Full-width banner, soft rounded corners, light outline
//   • Colour follows the announcement type (not too dark)
//   • Icon on the left, bold title + message, close button on the right
//   • Slides in from the top with a fade

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/announcement_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';

class AnnouncementBanner extends StatefulWidget {
  /// 'guest' | 'customer' | 'professional'
  final String audience;

  /// Optional callback when banner is dismissed
  final VoidCallback? onDismiss;

  /// Optional callback when banner is tapped
  final VoidCallback? onTap;

  const AnnouncementBanner({
    super.key,
    required this.audience,
    this.onDismiss,
    this.onTap,
  });

  @override
  State<AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends State<AnnouncementBanner>
    with TickerProviderStateMixin {
  static const _dismissedKey = 'dismissed_announcement_ids';

  final _service = AnnouncementService();
  Map<String, dynamic>? _announcement;
  bool _loading = true;
  bool _isExpanded = false;
  String? _loadedLang; // language the current announcement was fetched in

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _load();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: -0.3, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    // Auto-start animation when widget is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _announcement != null) {
        _animationController.forward();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // App language changed while this banner is on screen -> refetch so the
    // title/message come back in the new language.
    final lang = Localizations.localeOf(context).languageCode;
    if (_loadedLang != null && _loadedLang != lang) _load();
    _loadedLang = lang;
  }

  Future<void> _load() async {
    try {
      final results = await _service.getActiveAnnouncements(widget.audience);
      if (!mounted) return;

      if (results.isEmpty) {
        setState(() { _loading = false; _announcement = null; });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getStringList(_dismissedKey) ?? [];
      final visible = results.firstWhere(
        (a) => !dismissed.contains(a['id'].toString()),
        orElse: () => {},
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
        _announcement = visible.isEmpty ? null : visible;
        if (_announcement != null) {
          _animationController.forward();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; _announcement = null; });
      }
    }
  }

  Future<void> _dismiss() async {
    final id = _announcement?['id']?.toString();
    if (id == null) return;

    // Haptic feedback for mobile
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}

    // Animate out
    await _animationController.reverse();

    // Persist dismissal
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getStringList(_dismissedKey) ?? [];
    if (!dismissed.contains(id)) {
      dismissed.add(id);
      await prefs.setStringList(_dismissedKey, dismissed);
    }

    if (mounted) {
      setState(() => _announcement = null);
      widget.onDismiss?.call();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ── Look & feel helpers ──────────────────────────────────────────────

  /// Light → slightly deeper (kept soft, not too dark).
  List<Color> _paletteFor(String type) {
    switch (type) {
      case 'warning':
        return const [AppColors.warning, AppColors.warningAmber];
      case 'urgent':
        return const [AppColors.error, AppColors.favoriteRed];
      case 'success':
        return const [AppColors.accent, AppColors.emerald];
      case 'event':
        return const [Color(0xFF38BDF8), AppColors.sky];
      default:
        return const [AppColors.indigo400, AppColors.indigo];
    }
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'warning':
        return Icons.warning_rounded;
      case 'urgent':
        return Icons.priority_high_rounded;
      case 'success':
        return Icons.check_circle_rounded;
      case 'event':
        return Icons.event_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  Widget _buildCloseButton() {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).announcementDismiss,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _dismiss,
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.close_rounded, size: 22, color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _announcement == null) return const SizedBox.shrink();

    final a = _announcement!;
    final type = (a['type']?.toString() ?? 'info').toLowerCase();
    final title = a['title']?.toString() ?? '';
    final message = a['message']?.toString() ?? '';

    final palette = _paletteFor(type);
    const radius = 16.0;
    final isLong = message.length > 70;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 60),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          if (isLong) setState(() => _isExpanded = !_isExpanded);
          widget.onTap?.call();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: palette,
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(_getIconForType(type), size: 30, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title.isNotEmpty)
                      Text(
                        title,
                        maxLines: _isExpanded ? null : 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: AppFontSizes.input,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                          color: Colors.white,
                        ),
                      ),
                    if (message.isNotEmpty) ...[
                      if (title.isNotEmpty) const SizedBox(height: 2),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: Text(
                          message,
                          maxLines: _isExpanded ? null : 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: AppFontSizes.secondary,
                            height: 1.35,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              _buildCloseButton(),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// UniversalCard — gradient card used by the AI pick card on the customer
// home screen (not used by the announcement banner above).
// ════════════════════════════════════════════════════════════════════

/// Default card gradient (matches the announcement card).
const List<Color> kUniversalCardColors = [
  AppColors.indigo, // indigo
  AppColors.violet, // violet
];

class UniversalCard extends StatelessWidget {
  /// Gradient colours. Defaults to [kUniversalCardColors].
  final List<Color>? colors;

  /// Pill badge text (shown upper-cased) and its optional icon.
  /// When [badgeIcon] is null a small dot is shown.
  final String? badge;
  final IconData? badgeIcon;

  /// Small meta text at the right of the badge row (e.g. "16h ago").
  final String? meta;
  final IconData metaIcon;

  /// Frosted icon tile on the left. Pass [leadingIcon] for the standard tile
  /// or [leading] for a custom widget (e.g. an avatar).
  final IconData? leadingIcon;
  final Widget? leading;

  final String? title;
  final double titleSize;
  final int? titleMaxLines;

  /// Replaces [title] when a custom widget is needed (e.g. a loader).
  final Widget? titleWidget;

  final String? subtitle;
  final int? subtitleMaxLines;

  /// Widget at the right of the header (e.g. rating column).
  /// If null and [onClose] is set, a frosted close button is shown.
  final Widget? trailing;
  final VoidCallback? onClose;

  /// Extra body shown under the header, full width.
  final Widget? child;

  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double radius;

  const UniversalCard({
    super.key,
    this.colors,
    this.badge,
    this.badgeIcon,
    this.meta,
    this.metaIcon = Icons.schedule_rounded,
    this.leadingIcon,
    this.leading,
    this.title,
    this.titleSize = 17,
    this.titleMaxLines = 1,
    this.titleWidget,
    this.subtitle,
    this.subtitleMaxLines = 2,
    this.trailing,
    this.onClose,
    this.child,
    this.onTap,
    this.margin = EdgeInsets.zero,
    this.padding = const EdgeInsets.all(14),
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final palette = colors ?? kUniversalCardColors;
    final borderRadius = BorderRadius.circular(radius);

    final hasTopRow = badge != null || meta != null;
    final lead = leading ??
        (leadingIcon != null ? UniversalCardTile(icon: leadingIcon) : null);
    final end = trailing ??
        (onClose != null ? UniversalCardCloseButton(onPressed: onClose!) : null);

    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (lead != null) ...[lead, const SizedBox(width: 12)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasTopRow)
                Row(
                  children: [
                    if (badge != null)
                      Flexible(
                        child: _Pill(label: badge!, icon: badgeIcon),
                      ),
                    if (badge != null && meta != null) const Spacer(),
                    if (badge == null && meta != null) const Spacer(),
                    if (meta != null) ...[
                      Icon(metaIcon, size: 13, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        meta!,
                        style: const TextStyle(
                          fontSize: AppFontSizes.small,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              if (hasTopRow && (titleWidget != null || title != null))
                const SizedBox(height: 8),
              if (titleWidget != null)
                titleWidget!
              else if (title != null)
                Text(
                  title!,
                  maxLines: titleMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    color: Colors.white,
                  ),
                ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  maxLines: subtitleMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppFontSizes.secondary,
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (end != null) ...[const SizedBox(width: 10), end],
      ],
    );

    final content = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          header,
          if (child != null) ...[const SizedBox(height: 12), child!],
        ],
      ),
    );

    return Container(
      margin: margin,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: palette.last.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
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
            Material(
              type: MaterialType.transparency,
              child: onTap == null
                  ? content
                  : InkWell(
                      onTap: onTap,
                      splashColor: Colors.white.withValues(alpha: 0.12),
                      highlightColor: Colors.white.withValues(alpha: 0.06),
                      child: content,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _Pill extends StatelessWidget {
  final String label;
  final IconData? icon;
  const _Pill({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(AppSizes.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 12, color: Colors.white)
          else
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppFontSizes.caption,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted rounded tile that holds an icon or an emoji.
class UniversalCardTile extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final double size;
  const UniversalCardTile({super.key, this.icon, this.emoji, this.size = 46});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppSizes.radius14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: emoji != null
          ? Text(emoji!, style: const TextStyle(fontSize: AppFontSizes.h3, height: 1))
          : Icon(icon, size: 22, color: Colors.white),
    );
  }
}

/// Frosted circular close button.
class UniversalCardCloseButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String? tooltip;
  const UniversalCardCloseButton({
    super.key,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final tip = tooltip ?? AppLocalizations.of(context).tsDismiss;
    return Tooltip(
      message: tip,
      child: Semantics(
        button: true,
        label: tip,
        child: Material(
          color: Colors.white.withValues(alpha: 0.20),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 34,
              height: 34,
              child: Icon(Icons.close_rounded, size: 18, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

/// White call-to-action pill used inside [UniversalCard] bodies.
class UniversalCardButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool fullWidth;
  const UniversalCardButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.indigo,
                    fontSize: AppFontSizes.secondary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, size: 16, color: AppColors.indigo),
            ],
          ),
        ),
      ),
    );
  }
}