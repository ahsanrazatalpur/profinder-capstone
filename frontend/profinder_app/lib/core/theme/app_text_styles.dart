// lib/core/theme/app_text_styles.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Single source of truth for font sizes across the app.
///
/// Type scale (every `fontSize` in the UI should be one of these):
///   caption   11  badges, chips, tiny meta text
///   small     12  meta text, helper text, small labels
///   secondary 13  secondary body, list subtitles
///   body      14  primary body text
///   input     15  text-field text
///   title     16  card / section titles
///   title2    18  sub-headings
///   h3        20  heading 3
///   h2        24  heading 2
///   display   28  big numbers (wallet amount etc.)
///   h1        32  heading 1
///
/// Old in-between values snap like this: 9-11.5 -> caption, 12-12.5 -> small,
/// 13-13.5 -> secondary, 14-15 -> body, 16-17 -> title.
class AppFontSizes {
  AppFontSizes._();

  static const double caption   = 11;
  static const double small     = 12;
  static const double secondary = 13;
  static const double body      = 14;
  static const double input     = 15;
  static const double title     = 16;
  static const double title2    = 18;
  static const double h3        = 20;
  static const double h2        = 24;
  static const double display   = 28;
  static const double h1        = 32;

  // Extra steps found in legacy screens (added)
  static const double nano    = 9;
  static const double micro   = 10;
  static const double titleMd = 17;
}

/// Central typography styling hierarchy using standardized weights and sizes.
class AppTextStyles {
  AppTextStyles._();

  // ─── Headings ───────────────────────────────────────────
  static const TextStyle h1 = TextStyle(
    fontSize: AppFontSizes.h1,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.25,
    letterSpacing: -0.4,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: AppFontSizes.h2,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: AppFontSizes.h3,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.35,
    letterSpacing: -0.2,
  );

  // ─── Body Text ──────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontSize: AppFontSizes.title,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: AppFontSizes.body,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: AppFontSizes.small,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.45,
    letterSpacing: 0.2,
  );

  // ─── Button Text ────────────────────────────────────────
  static const TextStyle button = TextStyle(
    fontSize: AppFontSizes.title,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    height: 1.2,
    letterSpacing: 0.5,
  );

  // ─── Label / Caption ────────────────────────────────────
  static const TextStyle label = TextStyle(
    fontSize: AppFontSizes.small,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
    letterSpacing: 0.6,
  );

  static const TextStyle caption = TextStyle(
    fontSize: AppFontSizes.caption,
    fontWeight: FontWeight.normal,
    color: AppColors.textDisabled,
    height: 1.4,
    letterSpacing: 0.3,
  );

  // ─── Input Field Text ───────────────────────────────────
  static const TextStyle inputText = TextStyle(
    fontSize: AppFontSizes.input,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.4,
    letterSpacing: 0.2,
  );

  static const TextStyle inputHint = TextStyle(
    fontSize: AppFontSizes.input,
    fontWeight: FontWeight.normal,
    color: AppColors.textDisabled,
    height: 1.4,
    letterSpacing: 0.2,
  );
}