// lib/core/utils/app_helpers.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/theme_context_ext.dart';

class AppHelpers {
  AppHelpers._();

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

  // ─── Image URL Fix ──────────────────────────────────────
  // ✅ FIX: Backend se sirf relative path aata tha jaise /media/photos/abc.jpg
  // Flutter ka NetworkImage/Image.network poora URL chahta hai.
  // Yeh helper relative URL ko full URL mein convert karta hai.
  //
  // Usage:
  //   NetworkImage(AppHelpers.getFullImageUrl(photoUrl))
  //   Image.network(AppHelpers.getFullImageUrl(imageUrl))
  static String getFullImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';

    // Pehle se full URL hai — kuch mat karo
    if (url.startsWith('http://') || url.startsWith('https://')) return url;

    // Web aur emulator ke liye alag base URL
    // (same logic jo AppConstants.baseUrl mein hai)
    final base = kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';

    // Leading slash ensure karo
    final path = url.startsWith('/') ? url : '/$url';
    return '$base$path';
  }

  // ─── Snackbar ───────────────────────────────────────────
  // same snackbar for full app
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

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
  // Pehla letter capital karo
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Initialize with name, Used in Avatar (user logo)
  // e.g. "Ahsan Raza" → "AR"
  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}