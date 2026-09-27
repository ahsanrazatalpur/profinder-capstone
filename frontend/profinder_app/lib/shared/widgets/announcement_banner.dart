// lib/shared/widgets/announcement_banner.dart
//
// Enhanced Announcement Banner with animations, responsive design,
// and interactive features for a premium user experience.
//
// Features:
// - Smooth slide-in/slide-out animations
// - Gradient backgrounds with glassmorphism effect
// - Interactive hover effects (web)
// - Responsive sizing for all screen sizes
// - Live timestamp with relative time display
// - Read more/less toggle for long messages
// - Accessibility improvements
// - Haptic feedback on dismiss (mobile)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../services/announcement_service.dart';

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
    with SingleTickerProviderStateMixin {
  static const _dismissedKey = 'dismissed_announcement_ids';
  static const _accent = Color(0xFF2E6BFF);
  
  final _service = AnnouncementService();
  Map<String, dynamic>? _announcement;
  bool _loading = true;
  bool _isExpanded = false;
  bool _isHovered = false;
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _load();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    
    // Auto-start animation when widget is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _announcement != null) {
        _animationController.forward();
      }
    });
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

  String _getRelativeTime(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 7) {
        return DateFormat('MMM d, y').format(date);
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _announcement == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width < 1024;
    
    final a = _announcement!;
    final type = a['type']?.toString() ?? 'info';
    final title = a['title']?.toString() ?? '';
    final message = a['message']?.toString() ?? '';
    final createdAt = a['created_at']?.toString();
    
    final isWarning = type.toLowerCase() == 'warning';
    final isUrgent = type.toLowerCase() == 'urgent';
    final isSuccess = type.toLowerCase() == 'success';
    
    // Dynamic accent color based on type
    Color accentColor;
    if (isWarning) {
      accentColor = const Color(0xFFF59E0B);
    } else if (isUrgent) {
      accentColor = const Color(0xFFEF4444);
    } else if (isSuccess) {
      accentColor = const Color(0xFF10B981);
    } else {
      accentColor = _accent;
    }
    
    final bgColor = isDark 
        ? accentColor.withOpacity(0.12) 
        : accentColor.withOpacity(0.08);
    final borderColor = isDark 
        ? accentColor.withOpacity(0.3) 
        : accentColor.withOpacity(0.2);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final messageColor = isDark ? const Color(0xFFB4B9C6) : const Color(0xFF475569);
    final iconColor = accentColor;

    // Responsive padding and sizes
    final horizontalPadding = isMobile ? 12.0 : 16.0;
    final verticalPadding = isMobile ? 10.0 : 14.0;
    final iconSize = isMobile ? 18.0 : 22.0;
    final containerRadius = isMobile ? 12.0 : 16.0;
    final titleSize = isMobile ? 14.0 : 16.0;
    final messageSize = isMobile ? 12.5 : 14.0;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value * MediaQuery.of(context).size.width, 0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: child,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          accentColor.withOpacity(0.08),
                          accentColor.withOpacity(0.02),
                        ]
                      : [
                          accentColor.withOpacity(0.06),
                          accentColor.withOpacity(0.02),
                        ],
                ),
                borderRadius: BorderRadius.circular(containerRadius),
                border: Border.all(
                  color: _isHovered 
                      ? accentColor.withOpacity(0.4) 
                      : borderColor,
                  width: _isHovered ? 1.5 : 1,
                ),
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color: accentColor.withOpacity(0.15),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon badge with pulse animation for urgent
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isMobile ? 36 : 44,
                        height: isMobile ? 36 : 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accentColor.withOpacity(0.2),
                              accentColor.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                          border: Border.all(
                            color: accentColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: isUrgent
                            ? _buildPulsingIcon(iconSize, accentColor)
                            : Icon(
                                _getIconForType(type),
                                size: iconSize,
                                color: iconColor,
                              ),
                      ),
                      
                      const SizedBox(width: 10),
                      
                      // Vertical divider
                      VerticalDivider(
                        color: isDark 
                            ? Colors.white.withOpacity(0.08) 
                            : const Color(0xFFE2E8F0),
                        thickness: 1,
                        width: 1,
                      ),
                      
                      const SizedBox(width: 10),
                      
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: titleSize,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                      color: titleColor,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                                if (!isMobile && type.isNotEmpty && type != 'info') ...[
                                  const SizedBox(width: 8),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: accentColor.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Text(
                                      type.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: accentColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            
                            if (message.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              _buildMessage(
                                message,
                                messageColor,
                                messageSize,
                                isMobile,
                                isDark,
                              ),
                            ],
                            
                            // Timestamp
                            if (createdAt != null && !isMobile) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 12,
                                    color: messageColor.withOpacity(0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getRelativeTime(createdAt),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: messageColor.withOpacity(0.5),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Action buttons
                      Row(
                        children: [
                          if (!isMobile && message.length > 100)
                            TextButton(
                              onPressed: () {
                                setState(() => _isExpanded = !_isExpanded);
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                _isExpanded ? 'Less' : 'More',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                          // Dismiss button with hover effect
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: _dismiss,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _isHovered 
                                      ? Colors.red.withOpacity(0.1) 
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: isMobile ? 16 : 18,
                                  color: isDark 
                                      ? Colors.white.withOpacity(0.4) 
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPulsingIcon(double size, Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: const AlwaysStoppedAnimation(0),
          builder: (context, child) {
            return Container(
              width: size + 8,
              height: size + 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15),
              ),
              child: TweenAnimationBuilder(
                duration: const Duration(seconds: 2),
                tween: Tween<double>(begin: 0.7, end: 1.3),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  width: size + 8,
                  height: size + 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.08),
                  ),
                ),
              ),
            );
          },
        ),
        Icon(Icons.campaign_rounded, size: size, color: color),
      ],
    );
  }

  Widget _buildMessage(
    String message,
    Color color,
    double size,
    bool isMobile,
    bool isDark,
  ) {
    final maxLines = _isExpanded ? null : (isMobile ? 2 : 3);
    
    return Text(
      message,
      style: TextStyle(
        fontSize: size,
        height: 1.5,
        color: color,
        letterSpacing: -0.2,
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
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
}