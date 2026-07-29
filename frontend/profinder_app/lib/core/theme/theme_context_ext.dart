// lib/core/theme/theme_context_ext.dart
//
// AppColors.xxx is a compile-time constant — it can't change when the
// user toggles dark/light at runtime. This extension gives the same
// names, resolved live from the current Theme brightness, for any
// screen that needs to respond to the toggle.
//
// Usage: context.colors.background  (instead of AppColors.background)

import 'package:flutter/material.dart';
import 'app_text_styles.dart';

class AdaptiveColors {
  final Brightness brightness;
  const AdaptiveColors(this.brightness);

  bool get _dark => brightness == Brightness.dark;

  Color get background     => _dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  Color get surface        => _dark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
  Color get divider        => _dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  Color get textPrimary    => _dark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
  Color get textSecondary  => _dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get textDisabled   => _dark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1);
  Color get primary        => _dark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);
  Color get primaryDark    => _dark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8);
  Color get primaryLight   => _dark ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE);
  Color get accent         => _dark ? const Color(0xFF34D399) : const Color(0xFF10B981);
  Color get accentLight    => _dark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5);

  // Text-on-white pill buttons (social login etc.) — those keep a fixed
  // white background by design, so this is deliberately NOT dark/light
  // dependent; only exists here so screens don't need a raw literal.
  static const Color onFixedWhite = Color(0xFF0F172A);
}

extension BuildContextColors on BuildContext {
  AdaptiveColors get colors => AdaptiveColors(Theme.of(this).brightness);
}

// AppTextStyles.h1/h2/h3/bodyLarge/bodyMedium bake in AppColors.textPrimary,
// which is a compile-time constant tuned for the dark palette — it doesn't
// move when the user toggles light/dark. Use context.textStyles.xxx instead
// of AppTextStyles.xxx wherever the text needs to stay legible on both
// themes (i.e. anywhere it isn't already given an explicit color).
class AdaptiveTextStyles {
  final AdaptiveColors colors;
  const AdaptiveTextStyles(this.colors);

  TextStyle get h1 => AppTextStyles.h1.copyWith(color: colors.textPrimary);
  TextStyle get h2 => AppTextStyles.h2.copyWith(color: colors.textPrimary);
  TextStyle get h3 => AppTextStyles.h3.copyWith(color: colors.textPrimary);
  TextStyle get bodyLarge => AppTextStyles.bodyLarge.copyWith(color: colors.textPrimary);
  TextStyle get bodyMedium => AppTextStyles.bodyMedium.copyWith(color: colors.textPrimary);
  TextStyle get bodySmall => AppTextStyles.bodySmall.copyWith(color: colors.textSecondary);
  TextStyle get inputText => AppTextStyles.inputText.copyWith(color: colors.textPrimary);
}

extension BuildContextTextStyles on BuildContext {
  AdaptiveTextStyles get textStyles => AdaptiveTextStyles(colors);
}