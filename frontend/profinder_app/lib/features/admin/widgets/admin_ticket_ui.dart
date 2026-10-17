// lib/features/admin/widgets/admin_ticket_ui.dart
//
// English-only labels, colours and small widgets shared by the admin support
// ticket screens (the admin panel is English-only by design).

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

const Map<String, String> kAdminTicketStatusLabels = {
  'open': 'Open',
  'in_progress': 'In progress',
  'awaiting_user': 'Awaiting user',
  'resolved': 'Resolved',
  'closed': 'Closed',
};

const Map<String, String> kAdminTicketPriorityLabels = {
  'low': 'Low',
  'normal': 'Normal',
  'high': 'High',
};

const Map<String, String> kAdminTicketCategoryLabels = {
  'account': 'Account',
  'booking': 'Booking',
  'payment': 'Payment or withdrawal',
  'verification': 'Verification',
  'technical': 'Technical problem',
  'privacy': 'Privacy or data request',
  'feedback': 'Feedback',
  'other': 'Other',
};

String adminTicketStatusLabel(String key) => kAdminTicketStatusLabels[key] ?? key;
String adminTicketPriorityLabel(String key) => kAdminTicketPriorityLabels[key] ?? key;
String adminTicketCategoryLabel(String key) => kAdminTicketCategoryLabels[key] ?? key;

Color adminTicketStatusColor(String status) {
  switch (status) {
    case 'open':
      return AppColors.warningAmber;
    case 'in_progress':
      return AppColors.primary;
    case 'awaiting_user':
      return AppColors.slate500;
    case 'resolved':
      return AppColors.greenDeep;
    default:
      return AppColors.neutral400;
  }
}

IconData adminTicketStatusIcon(String status) {
  switch (status) {
    case 'open':
      return Icons.mark_email_unread_rounded;
    case 'in_progress':
      return Icons.sync_rounded;
    case 'awaiting_user':
      return Icons.hourglass_top_rounded;
    case 'resolved':
      return Icons.check_circle_rounded;
    default:
      return Icons.lock_rounded;
  }
}

String adminTicketTime(BuildContext context, DateTime? time) {
  if (time == null) return '';
  final m = MaterialLocalizations.of(context);
  return '${m.formatShortDate(time)} ${m.formatTimeOfDay(TimeOfDay.fromDateTime(time))}';
}

/// Small pill: icon + text (never colour alone).
class AdminTicketPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const AdminTicketPill({super.key, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: AppFontSizes.caption, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }
}