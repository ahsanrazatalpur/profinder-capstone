// lib/features/professional/widgets/review_action_sheets.dart

import 'package:flutter/material.dart';
import '../../../core/theme/theme_context_ext.dart';

const Map<String, String> kReportReasons = {
  'spam': 'Spam',
  'fake': 'Fake Review',
  'abusive': 'Abusive Language',
  'harassment': 'Harassment',
  'off_topic': 'Off-topic',
  'conflict_of_interest': 'Conflict of Interest',
  'other': 'Other',
};

/// Opens a bottom sheet for a customer to edit their own review
/// (rating + comment only — matches what the backend allows to change).
/// Returns {'rating': int, 'comment': String}, or null if cancelled.
Future<Map<String, dynamic>?> showEditReviewSheet(
  BuildContext context, {
  required int initialRating,
  required String initialComment,
}) {
  int rating = initialRating;
  final controller = TextEditingController(text: initialComment);

  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 16,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: sheetContext.colors.divider, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                Text('Edit Your Review',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: sheetContext.colors.textPrimary)),
                const SizedBox(height: 14),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      return GestureDetector(
                        onTap: () => setSheetState(() => rating = star),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            star <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 34,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  maxLength: 1000,
                  style: TextStyle(fontSize: 13.5, color: sheetContext.colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Update your comment...',
                    filled: true,
                    fillColor: sheetContext.colors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: sheetContext.colors.divider)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: sheetContext.colors.divider)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: sheetContext.colors.primary, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: rating == 0
                        ? null
                        : () => Navigator.pop(sheetContext, {
                              'rating': rating,
                              'comment': controller.text.trim(),
                            }),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Changes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Confirms permanent deletion of the caller's own review. Returns true if confirmed.
Future<bool> showDeleteReviewConfirm(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: dialogContext.colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Delete Review?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: dialogContext.colors.textPrimary)),
      content: Text('This will permanently remove your review. This cannot be undone.',
          style: TextStyle(fontSize: 13, color: dialogContext.colors.textSecondary, height: 1.4)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text('Cancel', style: TextStyle(color: dialogContext.colors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Opens a bottom sheet to compose a professional reply.
/// Returns the typed text, or null if cancelled.
Future<String?> showReplySheet(BuildContext context, {String? existingText}) {
  final controller = TextEditingController(text: existingText ?? '');
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: sheetContext.colors.divider, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            Text('Reply to Review',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: sheetContext.colors.textPrimary)),
            const SizedBox(height: 4),
            Text('Your reply is public and visible to everyone.',
                style: TextStyle(fontSize: 12, color: sheetContext.colors.textSecondary)),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              maxLines: 4,
              maxLength: 1000,
              autofocus: true,
              style: TextStyle(fontSize: 13.5, color: sheetContext.colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Thank the customer, or address their feedback...',
                filled: true,
                fillColor: sheetContext.colors.background,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: sheetContext.colors.divider)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: sheetContext.colors.divider)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: sheetContext.colors.primary, width: 1.5)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;
                  Navigator.pop(sheetContext, text);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Post Reply', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Opens a bottom sheet to select a report reason (+ optional note).
/// Returns {'reason': ..., 'note': ...}, or null if cancelled.
Future<Map<String, String>?> showReportSheet(BuildContext context) {
  String? selectedReason;
  final noteController = TextEditingController();

  return showModalBottomSheet<Map<String, String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 16,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: sheetContext.colors.divider, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                Text('Report Review',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: sheetContext.colors.textPrimary)),
                const SizedBox(height: 4),
                Text('This sends a report to our moderation team — it will not remove the review immediately.',
                    style: TextStyle(fontSize: 11.5, color: sheetContext.colors.textSecondary, height: 1.4)),
                const SizedBox(height: 12),
                ...kReportReasons.entries.map((e) => RadioListTile<String>(
                      value: e.key,
                      groupValue: selectedReason,
                      onChanged: (v) => setSheetState(() => selectedReason = v),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(e.value, style: TextStyle(fontSize: 13.5, color: sheetContext.colors.textPrimary)),
                    )),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  style: TextStyle(fontSize: 13, color: sheetContext.colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Additional details (optional)',
                    filled: true,
                    fillColor: sheetContext.colors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: sheetContext.colors.divider)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: sheetContext.colors.divider)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: sheetContext.colors.primary, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedReason == null
                        ? null
                        : () => Navigator.pop(sheetContext, {
                              'reason': selectedReason!,
                              'note': noteController.text.trim(),
                            }),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Submit Report', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}