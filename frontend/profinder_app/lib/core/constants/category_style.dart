// lib/core/constants/category_style.dart
//
// GLOBAL category icon + color + gradient + style registry.
// Ab yeh ek complete premium styling system hai with animations,
// dark mode support, and advanced features.

import 'package:flutter/material.dart';

/// Premium category style with enhanced visual properties
class CategoryStyle {
  final IconData icon;
  final Color color;
  final Color darkColor;
  final List<Color> gradient;
  final List<Color> darkGradient;
  final Color backgroundColor;
  final Color darkBackgroundColor;
  final String? emoji;
  final String? label;

  const CategoryStyle({
    required this.icon,
    required this.color,
    this.darkColor = const Color(0xFF94A3B8),
    required this.gradient,
    this.darkGradient = const [],
    this.backgroundColor = const Color(0xFFF1F5F9),
    this.darkBackgroundColor = const Color(0xFF1E293B),
    this.emoji,
    this.label,
  });

  /// Get gradient based on theme
  List<Color> getGradient(bool isDark) {
    if (isDark && darkGradient.isNotEmpty) return darkGradient;
    return gradient;
  }

  /// Get background color based on theme
  Color getBackgroundColor(bool isDark) {
    return isDark ? darkBackgroundColor : backgroundColor;
  }

  /// Get text color based on theme
  Color getTextColor(bool isDark) {
    return isDark ? darkColor : color;
  }
}

class CategoryStyles {
  CategoryStyles._();

  // Premium fallback palette with enhanced colors
  static const List<CategoryStyle> _fallbackPalette = [
    CategoryStyle(
      icon: Icons.grid_view_rounded,
      color: Color(0xFF3B82F6),
      darkColor: Color(0xFF60A5FA),
      gradient: [Color(0xFF3B82F6), Color(0xFF2563EB)],
      darkGradient: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
      backgroundColor: Color(0xFFEFF6FF),
      darkBackgroundColor: Color(0xFF1E293B),
      label: 'General',
    ),
    CategoryStyle(
      icon: Icons.medical_services_outlined,
      color: Color(0xFFEF4444),
      darkColor: Color(0xFFF87171),
      gradient: [Color(0xFFEF4444), Color(0xFFDC2626)],
      darkGradient: [Color(0xFFF87171), Color(0xFFEF4444)],
      backgroundColor: Color(0xFFFEF2F2),
      darkBackgroundColor: Color(0xFF1E293B),
      emoji: '🏥',
      label: 'Healthcare',
    ),
    CategoryStyle(
      icon: Icons.gavel_outlined,
      color: Color(0xFF8B5CF6),
      darkColor: Color(0xFFA78BFA),
      gradient: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      darkGradient: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
      backgroundColor: Color(0xFFF5F3FF),
      darkBackgroundColor: Color(0xFF1E293B),
      emoji: '⚖️',
      label: 'Legal',
    ),
    CategoryStyle(
      icon: Icons.engineering_outlined,
      color: Color(0xFF3B82F6),
      darkColor: Color(0xFF60A5FA),
      gradient: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      darkGradient: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
      backgroundColor: Color(0xFFEFF6FF),
      darkBackgroundColor: Color(0xFF1E293B),
      emoji: '🔧',
      label: 'Engineering',
    ),
    CategoryStyle(
      icon: Icons.architecture,
      color: Color(0xFF06B6D4),
      darkColor: Color(0xFF22D3EE),
      gradient: [Color(0xFF06B6D4), Color(0xFF0891B2)],
      darkGradient: [Color(0xFF22D3EE), Color(0xFF06B6D4)],
      backgroundColor: Color(0xFFECFEFF),
      darkBackgroundColor: Color(0xFF1E293B),
      emoji: '🏛️',
      label: 'Architecture',
    ),
    CategoryStyle(
      icon: Icons.account_balance_outlined,
      color: Color(0xFFF59E0B),
      darkColor: Color(0xFFFBBF24),
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
      darkGradient: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
      backgroundColor: Color(0xFFFFFBEB),
      darkBackgroundColor: Color(0xFF1E293B),
      emoji: '💰',
      label: 'Finance',
    ),
    CategoryStyle(
      icon: Icons.computer_outlined,
      color: Color(0xFF10B981),
      darkColor: Color(0xFF34D399),
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
      darkGradient: [Color(0xFF34D399), Color(0xFF10B981)],
      backgroundColor: Color(0xFFECFDF5),
      darkBackgroundColor: Color(0xFF1E293B),
      emoji: '💻',
      label: 'Technology',
    ),
    CategoryStyle(
      icon: Icons.school_outlined,
      color: Color(0xFFEC4899),
      darkColor: Color(0xFFF472B6),
      gradient: [Color(0xFFEC4899), Color(0xFFDB2777)],
      darkGradient: [Color(0xFFF472B6), Color(0xFFEC4899)],
      backgroundColor: Color(0xFFFDF2F8),
      darkBackgroundColor: Color(0xFF1E293B),
      emoji: '📚',
      label: 'Education',
    ),
    CategoryStyle(
      icon: Icons.plumbing_outlined,
      color: Color(0xFF6366F1),
      darkColor: Color(0xFF818CF8),
      gradient: [Color(0xFF6366F1), Color(0xFF4F46E5)],
      darkGradient: [Color(0xFF818CF8), Color(0xFF6366F1)],
      backgroundColor: Color(0xFFEEF2FF),
      darkBackgroundColor: Color(0xFF1E293B),
      emoji: '🔧',
      label: 'Plumbing',
    ),
    CategoryStyle(
      icon: Icons.electrical_services,
      color: Color(0xFFF97316),
      darkColor: Color(0xFFFB923C),
      gradient: [Color(0xFFF97316), Color(0xFFEA580C)],
      darkGradient: [Color(0xFFFB923C), Color(0xFFF97316)],
      backgroundColor: Color(0xFFFFF7ED),
      darkBackgroundColor: Color(0xFF1E293B),
      emoji: '⚡',
      label: 'Electrical',
    ),
    CategoryStyle(
      icon: Icons.cleaning_services,
      color: Color(0xFF14B8A6),
      darkColor: Color(0xFF2DD4BF),
      gradient: [Color(0xFF14B8A6), Color(0xFF0D9488)],
      darkGradient: [Color(0xFF2DD4BF), Color(0xFF14B8A6)],
      backgroundColor: Color(0xFFF0FDFA),
      darkBackgroundColor: Color(0xFF1E293B),
      emoji: '🧹',
      label: 'Cleaning',
    ),
    CategoryStyle(
      icon: Icons.carpenter,
      color: Color(0xFF84CC16),
      darkColor: Color(0xFFA3E635),
      gradient: [Color(0xFF84CC16), Color(0xFF65A30D)],
      darkGradient: [Color(0xFFA3E635), Color(0xFF84CC16)],
      backgroundColor: Color(0xFFF7FEE7),
      darkBackgroundColor: Color(0xFF1E293B),
      emoji: '🔨',
      label: 'Carpentry',
    ),
    CategoryStyle(
      icon: Icons.format_paint_outlined,
      color: Color(0xFFF43F5E),
      darkColor: Color(0xFFFB7185),
      gradient: [Color(0xFFF43F5E), Color(0xFFE11D48)],
      darkGradient: [Color(0xFFFB7185), Color(0xFFF43F5E)],
      backgroundColor: Color(0xFFFFF1F2),
      darkBackgroundColor: Color(0xFF1E293B),
      emoji: '🎨',
      label: 'Painting',
    ),
  ];

  /// Enhanced featured gradients with premium colors
  static const List<List<Color>> featuredGradients = [
    [Color(0xFF3B82F6), Color(0xFF2563EB)],
    [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    [Color(0xFFF97316), Color(0xFFEA580C)],
    [Color(0xFF10B981), Color(0xFF059669)],
    [Color(0xFFEC4899), Color(0xFFDB2777)],
    [Color(0xFF06B6D4), Color(0xFF0891B2)],
  ];

  /// Premium gradient variants for different card styles
  static const List<List<Color>> premiumGradients = [
    [Color(0xFF667EEA), Color(0xFF764BA2)],
    [Color(0xFFF093FB), Color(0xFFF5576C)],
    [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    [Color(0xFF43E97B), Color(0xFF38F9D7)],
    [Color(0xFFFA709A), Color(0xFFFEE140)],
    [Color(0xFFA8C0FF), Color(0xFF3F2B96)],
  ];

  /// Get category style by name with enhanced matching
  static CategoryStyle forName(String name, int fallbackIndex) {
    final n = name.toLowerCase().trim();

    // Healthcare & Medical
    if (n.contains('doctor') || n.contains('health') || n.contains('medical') || 
        n.contains('dentist') || n.contains('clinic') || n.contains('hospital') ||
        n.contains('physician') || n.contains('nurse') || n.contains('pharma')) {
      return const CategoryStyle(
        icon: Icons.medical_services_outlined,
        color: Color(0xFF3B82F6),
        darkColor: Color(0xFF60A5FA),
        gradient: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        darkGradient: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
        backgroundColor: Color(0xFFEFF6FF),
        darkBackgroundColor: Color(0xFF1E293B),
        emoji: '🏥',
        label: 'Healthcare',
      );
    }

    // Legal & Law
    if (n.contains('lawyer') || n.contains('legal') || n.contains('attorney') || 
        n.contains('law') || n.contains('justice') || n.contains('advocate') ||
        n.contains('notary') || n.contains('paralegal')) {
      return const CategoryStyle(
        icon: Icons.gavel_outlined,
        color: Color(0xFF8B5CF6),
        darkColor: Color(0xFFA78BFA),
        gradient: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        darkGradient: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
        backgroundColor: Color(0xFFF5F3FF),
        darkBackgroundColor: Color(0xFF1E293B),
        emoji: '⚖️',
        label: 'Legal',
      );
    }

    // Engineering
    if (n.contains('engineer') || n.contains('mechanical') || n.contains('civil') ||
        n.contains('structural') || n.contains('electrical engineer') || 
        n.contains('mechatronics') || n.contains('petroleum')) {
      return const CategoryStyle(
        icon: Icons.engineering_outlined,
        color: Color(0xFF3B82F6),
        darkColor: Color(0xFF60A5FA),
        gradient: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        darkGradient: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
        backgroundColor: Color(0xFFEFF6FF),
        darkBackgroundColor: Color(0xFF1E293B),
        emoji: '🔧',
        label: 'Engineering',
      );
    }

    // Technology & IT
    if (n.contains('tech') || n.contains('software') ||
        n.contains('developer') || n.contains('programmer') || n.contains('coding') ||
        n.contains('web') || n.contains('app') || n.contains('ai') || 
        n.contains('machine learning') || n.contains('data')) {
      return const CategoryStyle(
        icon: Icons.computer_outlined,
        color: Color(0xFF10B981),
        darkColor: Color(0xFF34D399),
        gradient: [Color(0xFF10B981), Color(0xFF059669)],
        darkGradient: [Color(0xFF34D399), Color(0xFF10B981)],
        backgroundColor: Color(0xFFECFDF5),
        darkBackgroundColor: Color(0xFF1E293B),
        emoji: '💻',
        label: 'Technology',
      );
    }

    // Education & Tutoring
    if (n.contains('tutor') || n.contains('educat') || n.contains('teach') ||
        n.contains('trainer') || n.contains('instructor') || n.contains('mentor') ||
        n.contains('professor') || n.contains('teacher') || n.contains('coach')) {
      return const CategoryStyle(
        icon: Icons.school_outlined,
        color: Color(0xFFEC4899),
        darkColor: Color(0xFFF472B6),
        gradient: [Color(0xFFEC4899), Color(0xFFDB2777)],
        darkGradient: [Color(0xFFF472B6), Color(0xFFEC4899)],
        backgroundColor: Color(0xFFFDF2F8),
        darkBackgroundColor: Color(0xFF1E293B),
        emoji: '📚',
        label: 'Education',
      );
    }

    // Plumbing
    if (n.contains('plumb') || n.contains('pipe') || n.contains('drain') ||
        n.contains('faucet') || n.contains('water') || n.contains('pump')) {
      return const CategoryStyle(
        icon: Icons.plumbing_outlined,
        color: Color(0xFF6366F1),
        darkColor: Color(0xFF818CF8),
        gradient: [Color(0xFF6366F1), Color(0xFF4F46E5)],
        darkGradient: [Color(0xFF818CF8), Color(0xFF6366F1)],
        backgroundColor: Color(0xFFEEF2FF),
        darkBackgroundColor: Color(0xFF1E293B),
        emoji: '🔧',
        label: 'Plumbing',
      );
    }

    // Electrical
    if (n.contains('electric') || n.contains('wire') || n.contains('circuit') ||
        n.contains('power') || n.contains('lighting') || n.contains('solar')) {
      return const CategoryStyle(
        icon: Icons.electrical_services,
        color: Color(0xFFF97316),
        darkColor: Color(0xFFFB923C),
        gradient: [Color(0xFFF97316), Color(0xFFEA580C)],
        darkGradient: [Color(0xFFFB923C), Color(0xFFF97316)],
        backgroundColor: Color(0xFFFFF7ED),
        darkBackgroundColor: Color(0xFF1E293B),
        emoji: '⚡',
        label: 'Electrical',
      );
    }

    // Architecture & Design
    if (n.contains('architect') || n.contains('design') || n.contains('interior') ||
        n.contains('draft') || n.contains('render') || n.contains('blueprint')) {
      return const CategoryStyle(
        icon: Icons.architecture,
        color: Color(0xFF06B6D4),
        darkColor: Color(0xFF22D3EE),
        gradient: [Color(0xFF06B6D4), Color(0xFF0891B2)],
        darkGradient: [Color(0xFF22D3EE), Color(0xFF06B6D4)],
        backgroundColor: Color(0xFFECFEFF),
        darkBackgroundColor: Color(0xFF1E293B),
        emoji: '🏛️',
        label: 'Architecture',
      );
    }

    // Cleaning Services
    if (n.contains('clean') || n.contains('maid') || n.contains('housekeep') ||
        n.contains('janitor') || n.contains('sanitation') || n.contains('hygiene')) {
      return const CategoryStyle(
        icon: Icons.cleaning_services,
        color: Color(0xFF14B8A6),
        darkColor: Color(0xFF2DD4BF),
        gradient: [Color(0xFF14B8A6), Color(0xFF0D9488)],
        darkGradient: [Color(0xFF2DD4BF), Color(0xFF14B8A6)],
        backgroundColor: Color(0xFFF0FDFA),
        darkBackgroundColor: Color(0xFF1E293B),
        emoji: '🧹',
        label: 'Cleaning',
      );
    }

    // Carpentry & Woodwork
    if (n.contains('carpent') || n.contains('wood') || n.contains('furniture') ||
        n.contains('cabinet') || n.contains('joinery') || n.contains('woodwork')) {
      return const CategoryStyle(
        icon: Icons.carpenter,
        color: Color(0xFF84CC16),
        darkColor: Color(0xFFA3E635),
        gradient: [Color(0xFF84CC16), Color(0xFF65A30D)],
        darkGradient: [Color(0xFFA3E635), Color(0xFF84CC16)],
        backgroundColor: Color(0xFFF7FEE7),
        darkBackgroundColor: Color(0xFF1E293B),
        emoji: '🔨',
        label: 'Carpentry',
      );
    }

    // Painting & Decoration
    if (n.contains('paint') || n.contains('decor') || n.contains('wall') ||
        n.contains('finish') || n.contains('coating') || n.contains('color')) {
      return const CategoryStyle(
        icon: Icons.format_paint_outlined,
        color: Color(0xFFF43F5E),
        darkColor: Color(0xFFFB7185),
        gradient: [Color(0xFFF43F5E), Color(0xFFE11D48)],
        darkGradient: [Color(0xFFFB7185), Color(0xFFF43F5E)],
        backgroundColor: Color(0xFFFFF1F2),
        darkBackgroundColor: Color(0xFF1E293B),
        emoji: '🎨',
        label: 'Painting',
      );
    }

    // Finance & Accounting
    if (n.contains('account') || n.contains('financ') || n.contains('bank') ||
        n.contains('investment') || n.contains('tax') || n.contains('audit') ||
        n.contains('bookkeep') || n.contains('payroll') || n.contains('wealth')) {
      return const CategoryStyle(
        icon: Icons.account_balance_outlined,
        color: Color(0xFFF59E0B),
        darkColor: Color(0xFFFBBF24),
        gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
        darkGradient: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
        backgroundColor: Color(0xFFFFFBEB),
        darkBackgroundColor: Color(0xFF1E293B),
        emoji: '💰',
        label: 'Finance',
      );
    }

    // Photography & Media
    if (n.contains('photo') || n.contains('video') || n.contains('media') ||
        n.contains('camera') || n.contains('content') || n.contains('creative')) {
      return const CategoryStyle(
        icon: Icons.photo_camera_outlined,
        color: Color(0xFF8B5CF6),
        darkColor: Color(0xFFA78BFA),
        gradient: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        darkGradient: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
        backgroundColor: Color(0xFFF5F3FF),
        darkBackgroundColor: Color(0xFF1E293B),
        emoji: '📸',
        label: 'Media',
      );
    }

    // Beauty & Wellness
    if (n.contains('beauty') || n.contains('salon') || n.contains('spa') ||
        n.contains('makeup') || n.contains('hair') || n.contains('nails') ||
        n.contains('massage') || n.contains('wellness')) {
      return const CategoryStyle(
        icon: Icons.spa_outlined,
        color: Color(0xFFEC4899),
        darkColor: Color(0xFFF472B6),
        gradient: [Color(0xFFEC4899), Color(0xFFDB2777)],
        darkGradient: [Color(0xFFF472B6), Color(0xFFEC4899)],
        backgroundColor: Color(0xFFFDF2F8),
        darkBackgroundColor: Color(0xFF1E293B),
        emoji: '💄',
        label: 'Beauty',
      );
    }

    // Fallback
    return _fallbackPalette[fallbackIndex % _fallbackPalette.length];
  }

  /// Get premium gradient for featured cards (cycling through)
  static List<Color> getFeaturedGradient(int index) {
    return featuredGradients[index % featuredGradients.length];
  }

  /// Get premium gradient for cards (cycling through)
  static List<Color> getPremiumGradient(int index) {
    return premiumGradients[index % premiumGradients.length];
  }

  /// Get random premium gradient
  static List<Color> getRandomPremiumGradient() {
    return premiumGradients[DateTime.now().millisecondsSinceEpoch % premiumGradients.length];
  }
}

/// Extension methods for easy category style usage
extension CategoryStyleExtension on CategoryStyle {
  /// Get the appropriate gradient based on theme
  List<Color> gradientForTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return getGradient(isDark);
  }

  /// Get the appropriate background color based on theme
  Color backgroundColorForTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return getBackgroundColor(isDark);
  }

  /// Get the appropriate text color based on theme
  Color textColorForTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return getTextColor(isDark);
  }
}