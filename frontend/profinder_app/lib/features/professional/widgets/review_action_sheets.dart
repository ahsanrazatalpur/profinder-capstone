// lib/features/professional/widgets/review_action_sheets.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../l10n/generated/app_localizations.dart';

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
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) {
      final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: Container(
              decoration: BoxDecoration(
                color: sheetContext.colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.15)
                                : sheetContext.colors.divider,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.editReviewTitle,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: sheetContext.colors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.editReviewSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: sheetContext.colors.textSecondary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (i) {
                            final star = i + 1;
                            return GestureDetector(
                              onTap: () => setSheetState(() => rating = star),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeOut,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  star <= rating
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 34,
                                  color: star <= rating
                                      ? const Color(0xFFF59E0B)
                                      : sheetContext.colors.textSecondary
                                          .withOpacity(0.3),
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
                        style: TextStyle(
                          fontSize: 13.5,
                          color: sheetContext.colors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.editReviewHint,
                          filled: true,
                          fillColor: sheetContext.colors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: sheetContext.colors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: sheetContext.colors.divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.professionalColor,
                              width: 1.5,
                            ),
                          ),
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
                            backgroundColor: AppColors.professionalColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.saveChangesCta,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// Confirms permanent deletion of the caller's own review. Returns true if confirmed.
Future<bool> showDeleteReviewConfirm(BuildContext context) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: dialogContext.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context)!.deleteConfirmationTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: dialogContext.colors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      content: Text(
        AppLocalizations.of(context)!.deleteReviewConfirmationMessage,
        style: TextStyle(
          fontSize: 14,
          color: dialogContext.colors.textSecondary,
          height: 1.5,
          letterSpacing: 0.2,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          style: TextButton.styleFrom(
            foregroundColor: dialogContext.colors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            AppLocalizations.of(context)!.cancelCta,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: Text(
            AppLocalizations.of(context)!.deleteCta,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
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
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: sheetContext.colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.15)
                            : sheetContext.colors.divider,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.replyTitle,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: sheetContext.colors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.replySubtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: sheetContext.colors.textSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    maxLength: 1000,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: sheetContext.colors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.replyHint,
                      filled: true,
                      fillColor: sheetContext.colors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: sheetContext.colors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: sheetContext.colors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.professionalColor,
                          width: 1.5,
                        ),
                      ),
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
                        backgroundColor: AppColors.professionalColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.postReplyCta,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: Container(
              decoration: BoxDecoration(
                color: sheetContext.colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.15)
                                : sheetContext.colors.divider,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.flag_outlined,
                              color: AppColors.error,
                              size: isDark ? 20 : 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.reportTitle,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: sheetContext.colors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.reportSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: sheetContext.colors.textSecondary,
                          height: 1.4,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...kReportReasons.entries.map((e) => RadioListTile<String>(
                            value: e.key,
                            groupValue: selectedReason,
                            onChanged: (v) => setSheetState(() => selectedReason = v),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            activeColor: AppColors.error,
                            title: Text(
                              e.value,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: selectedReason == e.key
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: selectedReason == e.key
                                    ? AppColors.error
                                    : sheetContext.colors.textPrimary,
                              ),
                            ),
                          )),
                      const SizedBox(height: 8),
                      TextField(
                        controller: noteController,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 13,
                          color: sheetContext.colors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.reportNoteHint,
                          filled: true,
                          fillColor: sheetContext.colors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: sheetContext.colors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: sheetContext.colors.divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.professionalColor,
                              width: 1.5,
                            ),
                          ),
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
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.submitReportCta,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}