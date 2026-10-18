// lib/core/utils/app_helpers.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../constants/app_sizes.dart';
import '../theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/universal_dialog.dart';

export '../../shared/widgets/universal_dialog.dart';

class AppHelpers {
  AppHelpers._();

  // ─── Category name localization ─────────────────────────
  // Backend sends category names in English only. This maps the known
  // names to the current app language; unknown names are shown as-is.
  // NOTE: use this for DISPLAY only — keep the original name for search/API.
  static String localizedCategoryName(BuildContext context, String name) {
    final t = AppLocalizations.of(context);
    final n = name
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    switch (n) {
      case 'it and tech':
        return t.categoryItTech;
      case 'engineers':
        return t.categoryEngineers;
      case 'lawyers and legal':
        return t.categoryLawyersLegal;
      case 'doctors and healthcare':
        return t.categoryDoctorsHealthcare;
      case 'architects':
        return t.categoryArchitects;
      case 'electricians':
        return t.categoryElectricians;
      case 'plumbers':
        return t.categoryPlumbers;
      case 'tutors and education':
        return t.categoryTutorsEducation;
      default:
        return name;
    }
  }

  // ─── Date / Time Format ─────────────────────────────────
  // convert Datetime object to readable string
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date); // e.g. 05 May 2026
  }

  static String formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time); // e.g. 02:30 PM
  }

  static String formatDateTime(DateTime dt) {
    return DateFormat('dd MMM yyyy • hh:mm a').format(dt);
  }

  // ─── Image URL Resolution ──────────────────────────────
  /// Resolves relative media paths into absolute URLs using [AppConstants.baseUrl].
  ///
  /// Preserves already absolute URLs (starting with http:// or https://).
  static String getFullImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';

    // Already an absolute URL — return as-is
    if (url.startsWith('http://') || url.startsWith('https://')) return url;

    // Derive media base URL by stripping trailing '/api' from baseUrl
    final base = AppConstants.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

    // Ensure leading slash on relative path
    final path = url.startsWith('/') ? url : '/$url';
    return '$base$path';
  }

  // ─── Universal Toast / Quick Popup ──────────────────────
  static void _showUniversalToast({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        duration: duration,
        action: action,
      ),
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showUniversalToast(
      context: context,
      message: message,
      backgroundColor: AppColors.emerald,
      icon: Icons.check_circle_rounded,
      duration: duration,
      action: action,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showUniversalToast(
      context: context,
      message: message,
      backgroundColor: AppColors.error,
      icon: Icons.error_outline_rounded,
      duration: duration,
      action: action,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showUniversalToast(
      context: context,
      message: message,
      backgroundColor: AppColors.warningAmber,
      icon: Icons.warning_amber_rounded,
      duration: duration,
      action: action,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showUniversalToast(
      context: context,
      message: message,
      backgroundColor: AppColors.customerColor,
      icon: Icons.info_outline_rounded,
      duration: duration,
      action: action,
    );
  }

  // ─── Universal Dialog Forwarders ────────────────────────
  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    UniversalDialogType type = UniversalDialogType.danger,
    IconData? icon,
    Widget? customContent,
  }) => UniversalDialog.showConfirmation(
    context: context,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    type: type,
    icon: icon,
    customContent: customContent,
  );

  static Future<void> showSuccessDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String primaryLabel,
    required VoidCallback onPrimary,
    String? secondaryLabel,
    VoidCallback? onSecondary,
    Widget? customContent,
  }) => UniversalDialog.showSuccess(
    context: context,
    title: title,
    message: message,
    primaryLabel: primaryLabel,
    onPrimary: onPrimary,
    secondaryLabel: secondaryLabel,
    onSecondary: onSecondary,
    customContent: customContent,
  );

  static Future<bool?> showLogoutDialog(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) => UniversalDialog.showLogout(context, onConfirm: onConfirm);

  static Future<bool?> showDeleteDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) => UniversalDialog.showDelete(
    context,
    title: title,
    message: message,
    onConfirm: onConfirm,
  );

  // ─── Role Helper ────────────────────────────────────────
  // return color according to roles
  static Color getRoleColor(String role) {
    switch (role) {
      case 'professional':
        return AppColors.professionalColor;
      case 'admin':
        return AppColors.adminColor;
      default:
        return AppColors.customerColor;
    }
  }

  // ─── Booking Status Color ───────────────────────────────
  static Color getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'completed':
        return AppColors.primary;
      case 'cancelled':
        return AppColors.textSecondary;
      default:
        return AppColors.warning; // pending
    }
  }

  // ─── String Helpers ─────────────────────────────────────
  /// Capitalizes the first character of the given string.
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Initialize with name, Used in Avatar (user logo)
  // e.g. "Ahsan Raza" → "AR"
  static String getInitials(String name) {
    // Split on ANY whitespace and drop empty pieces — "John  Doe" (double
    // space), trailing spaces or an empty name used to give parts[1] == ''
    // and `''[0]` threw RangeError (no indices are valid: 0).
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  // ─── Currency Helpers ────────────────────────────────────
  /// Returns currency symbol ('Rs', '$', '€', '£', etc.)
  /// Inspects currency code, country, or city with default fallback to 'Rs' for Pakistan.
  static String getCurrencySymbol({
    dynamic professional,
    String? currency,
    String? country,
    String? city,
  }) {
    if (professional is Map) {
      if (professional['currency_symbol'] != null &&
          professional['currency_symbol'].toString().trim().isNotEmpty) {
        return professional['currency_symbol'].toString().trim();
      }
      if (professional['currency'] != null &&
          professional['currency'].toString().trim().isNotEmpty) {
        currency = professional['currency'].toString();
      }
      country ??= professional['country']?.toString();
      city ??= professional['city']?.toString();
    }

    if (currency != null && currency.trim().isNotEmpty) {
      final c = currency.trim().toUpperCase();
      switch (c) {
        case 'PKR':
          return 'Rs';
        case 'INR':
          return '₹';
        case 'EUR':
          return '€';
        case 'GBP':
          return '£';
        case 'AED':
          return 'AED';
        case 'SAR':
          return 'SAR';
        case 'CAD':
          return 'CA\$';
        case 'AUD':
          return 'A\$';
        case 'JPY':
          return '¥';
        case 'CNY':
          return '¥';
        case 'USD':
          return '\$';
      }
    }

    final cLower = (country ?? '').trim().toLowerCase();
    final cityLower = (city ?? '').trim().toLowerCase();

    const pkCities = {
      'badin',
      'karachi',
      'lahore',
      'islamabad',
      'rawalpindi',
      'faisalabad',
      'multan',
      'peshawar',
      'quetta',
      'hyderabad',
      'sukkur',
      'gujranwala',
      'sialkot',
      'larkana',
      'abbottabad',
      'bahawalpur',
      'sargodha',
      'mirpurkhas',
      'sheikhupura',
      'jhang',
      'gujrat',
      'kasur',
      'mardan',
      'swat',
      'sahiwal',
      'okara',
      'wah cantt',
      'dera ghazi khan',
      'rahim yar khan',
      'dadu',
      'tando allahyar',
      'tando muhammad khan',
      'khairpur',
      'shikarpur',
      'jacobabad',
      'umerkot',
      'sanghar',
      'matiari',
      'kashmore',
      'ghotki',
    };

    if (cLower == 'pk' ||
        cLower == 'pakistan' ||
        pkCities.contains(cityLower)) {
      return 'Rs';
    }
    if (cLower == 'in' || cLower == 'india') return '₹';
    if (cLower == 'gb' || cLower == 'uk' || cLower == 'united kingdom')
      return '£';
    if (cLower == 'ae' || cLower == 'uae') return 'AED';
    if (cLower == 'sa' || cLower == 'saudi arabia') return 'SAR';
    if (cLower == 'ca' || cLower == 'canada') return 'CA\$';
    if (cLower == 'au' || cLower == 'australia') return 'A\$';
    if (cLower == 'us' || cLower == 'usa' || cLower == 'united states')
      return '\$';

    // ProFinder default currency is PKR (Rs)
    return 'Rs';
  }

  /// Formats hourly rate with dynamic currency symbol: e.g. "Rs 500/hr" or "$50/hr"
  static String formatHourlyRate(
    dynamic rate, {
    dynamic professional,
    String? currency,
    String? country,
    String? city,
  }) {
    final sym = getCurrencySymbol(
      professional: professional,
      currency: currency,
      country: country,
      city: city,
    );
    final val = double.tryParse(rate?.toString() ?? '0') ?? 0.0;
    final formattedVal = val == val.roundToDouble()
        ? val.toStringAsFixed(0)
        : val.toStringAsFixed(2);
    return '$sym $formattedVal/hr';
  }

  /// Formats price amount with dynamic currency symbol: e.g. "Rs 500" or "$50"
  static String formatPrice(
    dynamic amount, {
    dynamic professional,
    String? currency,
    String? country,
    String? city,
    int decimals = 0,
  }) {
    final sym = getCurrencySymbol(
      professional: professional,
      currency: currency,
      country: country,
      city: city,
    );
    final val = double.tryParse(amount?.toString() ?? '0') ?? 0.0;
    return '$sym ${val.toStringAsFixed(decimals)}';
  }
}
