// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // Private constructor — koi AppColors() nahi bana sakta
  // Kyun? Ye sirf constants ki class hai, object banana useless hoga
  AppColors._();

  // ─── Primary Brand Colors ────────────────────────────────
  static const Color primary       = Color(0xFF3B82F6); // Blue — brightened for dark bg contrast
  static const Color primaryLight  = Color(0xFF1E3A5F); // Dark blue-tinted surface (was light blue bg)
  static const Color primaryDark   = Color(0xFF60A5FA); // Lighter blue — pressed state pops on dark

  // ─── Secondary / Accent ─────────────────────────────────
  static const Color accent        = Color(0xFF34D399); // Green — success, verified badge
  static const Color accentLight   = Color(0xFF064E3B); // Dark green-tinted surface

  // ─── Neutral Colors ─────────────────────────────────────
  static const Color white         = Color(0xFFFFFFFF);
  static const Color black         = Color(0xFF000000);
  static const Color background    = Color(0xFF0F172A); // App background — slate-900
  static const Color surface       = Color(0xFF1E293B); // Cards, modals — slate-800
  static const Color divider       = Color(0xFF334155); // Lines between items — slate-700

  // ─── Text Colors ────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF1F5F9); // Main text — near white
  static const Color textSecondary = Color(0xFF94A3B8); // Subtitles, hints
  static const Color textDisabled  = Color(0xFF64748B); // Disabled text

  // ─── Status Colors ──────────────────────────────────────
  static const Color success       = Color(0xFF34D399); // Green
  static const Color warning       = Color(0xFFFBBF24); // Yellow
  static const Color error         = Color(0xFFF87171); // Red
  static const Color info          = Color(0xFF60A5FA); // Blue

  // ─── Role Colors ────────────────────────────────────────
  static const Color customerColor     = Color(0xFF2563EB); // Blue — matches PF avatar bg
  static const Color professionalColor = Color(0xFF7C3AED); // Purple — matches "Free plan" banner
  static const Color adminColor        = Color(0xFFF87171); // Red — brightened for dark bg

  // ─── Section Badge Colors (Top Rated / Trending / Popular / New) ──
  // Global taake har home screen (guest, customer, ...) same badge color
  // dikhaye, alag-alag hardcoded hex na likhna pade har jagah.
  static const Color badgeTopRated    = Color(0xFFF59E0B);
  static const Color badgeTrending    = Color(0xFFF97316);
  static const Color badgePopular     = Color(0xFFDB2777);
  static const Color badgeNew         = Color(0xFF10B981);
  static const Color badgeRecommended = Color(0xFF7C3AED);

  // ─── CTA / Promo Gradient (Become Pro banner, etc.) ───────
  static const Color ctaGradientStart = Color(0xFFF59E0B);
  static const Color ctaGradientEnd   = Color(0xFFF97316);

  // ─── Hero Header Gradient (guest/customer home top banner) ─
  static const Color heroGradientDark1  = Color(0xFF0F172A);
  static const Color heroGradientDark2  = Color(0xFF1A1A2E);
  static const Color heroGradientDark3  = Color(0xFF1E293B);
  static const Color heroGradientLight1 = Color(0xFF4F7FE8);
  static const Color heroGradientLight2 = Color(0xFF3B82F6);
}