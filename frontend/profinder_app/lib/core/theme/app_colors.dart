// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

/// Central color palette defining brand, semantic, surface, and role colors.
class AppColors {
  AppColors._();

  // ─── Primary Brand Colors ────────────────────────────────
  static const Color primary = Color(
    0xFF3B82F6,
  ); // Blue — brightened for dark bg contrast
  static const Color primaryLight = Color(
    0xFF1E3A5F,
  ); // Dark blue-tinted surface (was light blue bg)
  static const Color primaryDark = Color(
    0xFF60A5FA,
  ); // Lighter blue — pressed state pops on dark

  // ─── Secondary / Accent ─────────────────────────────────
  static const Color accent = Color(
    0xFF34D399,
  ); // Green — success, verified badge
  static const Color accentLight = Color(
    0xFF064E3B,
  ); // Dark green-tinted surface

  // ─── Neutral Colors ─────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color background = Color(
    0xFF0F172A,
  ); // App background — slate-900
  static const Color surface = Color(0xFF1E293B); // Cards, modals — slate-800
  static const Color divider = Color(
    0xFF334155,
  ); // Lines between items — slate-700

  // ─── Text Colors ────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF1F5F9); // Main text — near white
  static const Color textSecondary = Color(0xFF94A3B8); // Subtitles, hints
  static const Color textDisabled = Color(0xFF64748B); // Disabled text

  // ─── Status Colors ──────────────────────────────────────
  static const Color success = Color(0xFF34D399); // Green
  static const Color warning = Color(0xFFFBBF24); // Yellow
  static const Color error = Color(0xFFF87171); // Red
  static const Color info = Color(0xFF60A5FA); // Blue

  // ─── Role Colors ────────────────────────────────────────
  static const Color customerColor = Color(
    0xFF2563EB,
  ); // Blue — matches PF avatar bg
  static const Color professionalColor = Color(
    0xFF7C3AED,
  ); // Purple — matches "Free plan" banner
  static const Color adminColor = Color(
    0xFFF87171,
  ); // Red — brightened for dark bg

  // ─── Section Badge Colors (Top Rated / Trending / Popular / New) ──
  // Centralized badge colors shared across guest and customer home screens.
  static const Color badgeTopRated = Color(0xFFF59E0B);
  static const Color badgeTrending = Color(0xFFF97316);
  static const Color badgePopular = Color(0xFFDB2777);
  static const Color badgeNew = Color(0xFF10B981);
  static const Color badgeRecommended = Color(0xFF7C3AED);

  // ─── CTA / Promo Gradient (Become Pro banner, etc.) ───────
  static const Color ctaGradientStart = Color(0xFFF59E0B);
  static const Color ctaGradientEnd = Color(0xFFF97316);

  // ─── Hero Header Gradient (guest/customer home top banner) ─
  static const Color heroGradientDark1 = Color(0xFF0F172A);
  static const Color heroGradientDark2 = Color(0xFF1A1A2E);
  static const Color heroGradientDark3 = Color(0xFF1E293B);
  static const Color heroGradientLight1 = Color(0xFF4F7FE8);
  static const Color heroGradientLight2 = Color(0xFF3B82F6);

  // ─── Fixed semantic / brand accents (same in light & dark) ─
  // Used by customer home quick actions, wallet card, AI card etc., so no
  // screen needs a raw Color(0x...) literal for these.
  static const Color starGold = Color(0xFFFCD34D); // rating star, gold accent
  static const Color warningAmber = Color(
    0xFFF59E0B,
  ); // pending / warning accent
  static const Color favoriteRed = Color(0xFFEF4444); // saved / favourite heart
  static const Color accentPurple = Color(0xFF7C3AED); // AI + help accent
  static const Color walletGradientStart = Color(0xFF059669);
  static const Color walletGradientEnd = Color(0xFF10B981);

  // ─── Extra fixed accents (charts, avatars, online dot) ───
  static const Color violet = Color(0xFF8B5CF6);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color pink = Color(0xFFEC4899);
  static const Color indigo = Color(0xFF6366F1);
  static const Color onlineGreen = Color(0xFF22C55E);
  // Rotating palette for category / avatar tiles (first slot is theme primary,
  // so screens do `[context.colors.primary, ...AppColors.avatarPalette]`).
  static const List<Color> avatarPalette = [
    Color(0xFFEF4444),
    violet,
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    cyan,
    pink,
    indigo,
  ];

  // ─── Light-tint badge palette (distance badges etc.) ───────
  // Background tints + their deep text colours. Badges that use these
  // handle dark mode themselves (tinted translucent bg + lightened text).
  static const Color tintGreen = Color(0xFFECFDF5);
  static const Color tintBlue = Color(0xFFEFF6FF);
  static const Color tintAmber = Color(0xFFFFFBEB);
  static const Color tintOrange = Color(0xFFFFF7ED);
  static const Color tintGray = Color(0xFFF9FAFB);
  static const Color successDeep = Color(0xFF059669);
  static const Color amberDeep = Color(0xFFD97706);
  static const Color orangeDeep = Color(0xFFEA580C);
  static const Color grayDeep = Color(0xFF6B7280);

  // ─── Light-mode neutral greys (Tailwind gray scale) ───────
  // Used in the light branch of manual isDark checks (borders, placeholders,
  // disabled fills). Dark branches already use translucent white.
  static const Color lightScaffold = Color(0xFFF5F7FA); // light page background
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color emerald = Color(0xFF10B981);

  // ─── More fixed accents (settings / profile tile icons) ───
  static const Color sky = Color(0xFF0EA5E9);
  static const Color rose = Color(0xFFF43F5E);
  static const Color teal = Color(0xFF14B8A6);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color indigoDeep = Color(0xFF4F46E5);
  static const Color greenDeep = Color(0xFF16A34A);
  static const Color amberDarkest = Color(0xFFB45309);
  static const Color violetLight = Color(0xFFA78BFA);
  static const Color blueDeep = Color(0xFF1D4ED8);
  static const Color dangerRed = Color(0xFFEF4444);

  // ─── Tint scales used by professional-side tiles / banners ─
  // Light and dark branches of manual isDark checks both pull from these.
  static const Color violet50 = Color(0xFFF5F3FF);
  static const Color violet200 = Color(0xFFDDD6FE);
  static const Color violet300 = Color(0xFFC4B5FD);
  static const Color violet400 = Color(0xFF9F7AEA);
  static const Color violet800 = Color(0xFF5B21B6);
  static const Color violet900 = Color(0xFF4C1D95);
  static const Color indigo400 = Color(0xFF818CF8);
  static const Color indigo900 = Color(0xFF312E81);
  static const Color indigo950 = Color(0xFF1E1B4B);
  static const Color amber200 = Color(0xFFFDE68A);
  static const Color amber800 = Color(0xFF92400E);
  static const Color amber900 = Color(0xFF78350F);
  static const Color amber950 = Color(0xFF451A03);
  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red200 = Color(0xFFFECACA);
  static const Color red300 = Color(0xFFFCA5A5);
  static const Color red800 = Color(0xFF7F1D1D);
  static const Color red950 = Color(0xFF450A0A);
  static const Color green200 = Color(0xFFA7F3D0);
  static const Color green800 = Color(0xFF065F46);
  static const Color tealLight = Color(0xFF2DD4BF);

  // ─── Neutral scale for hardcoded light/dark literals (added) ──
  // Pure value tokens (NOT theme-dependent) — use inside manual isDark
  // branches where the old code had a raw Color(0x...) literal.
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);
  static const Color red600 = Color(0xFFDC2626);
}
