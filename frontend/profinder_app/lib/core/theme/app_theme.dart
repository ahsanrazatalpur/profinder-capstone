// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  // ── Light palette (only used by lightTheme below) ──────────
  static const _lightPrimary       = Color(0xFF2563EB);
  static const _lightBackground    = Color(0xFFF8FAFC);
  static const _lightSurface       = Color(0xFFFFFFFF);
  static const _lightDivider       = Color(0xFFE2E8F0);
  static const _lightTextPrimary   = Color(0xFF0F172A);
  static const _lightTextSecondary = Color(0xFF64748B);
  static const _lightError         = Color(0xFFEF4444);

  static ThemeData get darkTheme => _buildTheme(
        brightness:     Brightness.dark,
        background:     AppColors.background,
        surface:        AppColors.surface,
        primary:        AppColors.primary,
        error:          AppColors.error,
        divider:        AppColors.divider,
        textPrimary:    AppColors.textPrimary,
        textSecondary:  AppColors.textSecondary,
      );

  static ThemeData get lightTheme => _buildTheme(
        brightness:     Brightness.light,
        background:     _lightBackground,
        surface:        _lightSurface,
        primary:        _lightPrimary,
        error:          _lightError,
        divider:        _lightDivider,
        textPrimary:    _lightTextPrimary,
        textSecondary:  _lightTextSecondary,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color primary,
    required Color error,
    required Color divider,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,

      colorScheme: ColorScheme(
        brightness: brightness,
        primary:    primary,
        onPrimary:  AppColors.white,
        secondary:  AppColors.accent,
        onSecondary: AppColors.white,
        surface:    surface,
        onSurface:  textPrimary,
        error:      error,
        onError:    AppColors.white,
        outline:    divider,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation:       0,
        centerTitle:     true,
        titleTextStyle:  AppTextStyles.h3.copyWith(color: textPrimary),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: AppColors.white,
          minimumSize:     const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.button,
          elevation:  0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize:     const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side:      BorderSide(color: primary, width: 1.5),
          textStyle: AppTextStyles.button.copyWith(color: primary),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:      true,
        fillColor:   surface,
        hintStyle:   AppTextStyles.inputHint.copyWith(color: textSecondary),
        labelStyle:  AppTextStyles.inputText.copyWith(color: textSecondary),
        floatingLabelStyle: AppTextStyles.inputText.copyWith(color: primary),
        errorStyle:  AppTextStyles.caption.copyWith(color: error, height: 1.3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical:   14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(color: error),
        ),
      ),

      cardTheme: CardThemeData(
        color:     surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side:         BorderSide(color: divider),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:      surface,
        selectedItemColor:    primary,
        unselectedItemColor:  textSecondary,
        showSelectedLabels:   true,
        showUnselectedLabels: true,
        type:                 BottomNavigationBarType.fixed,
        elevation:            8,
      ),

      dividerTheme: DividerThemeData(
        color:     divider,
        thickness: 1,
        space:     1,
      ),
    );
  }
}