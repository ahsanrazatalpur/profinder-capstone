// lib/features/support/widgets/ticket_compose_fields.dart
//
// Category chips + subject + message fields shared by the "new ticket" and the
// guest "contact support" forms. Chips (not a dropdown) so every category is
// visible and reachable with one tap, with a text label on each.

import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/utils/support_icons.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/ticket_models.dart';
import 'ticket_labels.dart';

class TicketCategoryChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const TicketCategoryChips({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = context.colors;
    return Wrap(
      spacing: AppSizes.sm,
      runSpacing: AppSizes.sm,
      children: [
        for (final key in kTicketCategories)
          _chip(colors, t, key, selected == key),
      ],
    );
  }

  Widget _chip(AdaptiveColors colors, AppLocalizations t, String key, bool isSelected) {
    final Color accent = colors.primary;
    return ChoiceChip(
      showCheckmark: false,
      avatar: Icon(
        resolveSupportIcon(key),
        size: AppSizes.iconSm,
        color: isSelected ? accent : colors.textSecondary,
      ),
      label: Text(
        ticketCategoryLabel(t, key),
        style: TextStyle(
          letterSpacing: 0,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? accent : colors.textPrimary,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(key),
      backgroundColor: colors.surface,
      selectedColor: colors.primaryLight,
      surfaceTintColor: Colors.transparent,
      side: BorderSide(color: isSelected ? accent : colors.divider, width: isSelected ? 1.5 : 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
    );
  }
}

class TicketComposeFields extends StatelessWidget {
  final TextEditingController subject;
  final TextEditingController body;
  final String category;
  final ValueChanged<String> onCategory;
  final bool enabled;

  const TicketComposeFields({
    super.key,
    required this.subject,
    required this.body,
    required this.category,
    required this.onCategory,
    this.enabled = true,
  });

  static String? _required(String? value, String message) =>
      (value == null || value.trim().isEmpty) ? message : null;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final styles = context.textStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.ticketCategoryLabel, style: styles.bodyMedium.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0)),
        const SizedBox(height: AppSizes.sm),
        TicketCategoryChips(selected: category, onSelected: enabled ? onCategory : (_) {}),
        const SizedBox(height: AppSizes.md),
        TextFormField(
          controller: subject,
          enabled: enabled,
          maxLength: kTicketSubjectMax,
          textInputAction: TextInputAction.next,
          style: styles.inputText.copyWith(letterSpacing: 0),
          decoration: InputDecoration(labelText: t.ticketSubjectLabel, hintText: t.ticketSubjectHint),
          validator: (v) => _required(v, t.ticketFieldRequired),
        ),
        const SizedBox(height: AppSizes.sm),
        TextFormField(
          controller: body,
          enabled: enabled,
          maxLength: kTicketBodyMax,
          minLines: 5,
          maxLines: 12,
          keyboardType: TextInputType.multiline,
          style: styles.inputText.copyWith(letterSpacing: 0),
          decoration: InputDecoration(
            labelText: t.ticketMessageLabel,
            hintText: t.ticketMessageHint,
            alignLabelWithHint: true,
          ),
          validator: (v) => _required(v, t.ticketFieldRequired),
        ),
      ],
    );
  }
}

/// Inline error line shown under a form after a failed submit.
class TicketFormError extends StatelessWidget {
  final String message;

  const TicketFormError({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: AppSizes.iconMd - 4, color: colors.danger),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              message,
              style: context.textStyles.bodySmall.copyWith(color: colors.danger, letterSpacing: 0),
            ),
          ),
        ],
      ),
    );
  }
}