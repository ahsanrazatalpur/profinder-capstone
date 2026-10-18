// lib/features/chat/presentation/widgets/date_separator.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/theme_context_ext.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';

class DateSeparator extends StatelessWidget {
  final DateTime date;
  const DateSeparator({super.key, required this.date});

  static String label(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(date); // e.g. "Tuesday"
    return DateFormat('d MMM yyyy').format(date);
  }

  /// True when [a] and [b] fall on different calendar days — used by the
  /// screen to decide where to insert a separator.
  static bool isDifferentDay(DateTime a, DateTime b) {
    return a.year != b.year || a.month != b.month || a.day != b.day;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? context.colors.divider : const Color(0xFFE9EDF2),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: Text(
            label(date),
            style: TextStyle(
              fontSize: AppFontSizes.small,
              fontWeight: FontWeight.w600,
              color: context.colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
