// lib/features/auth/widgets/searchable_picker_field.dart
//
// Generic searchable dropdown used for Country and City on Register
// Step 2. Renders like a normal TextFormField (so it sits flush with the
// rest of the form and shows validation errors the same way), but tapping
// it opens a search sheet instead of a keyboard — this is also what
// structurally prevents "invalid" free-typed cities: the value can only
// ever be one of the items handed to it.
//
// Responsive: a bottom sheet on phones/tablets, a centered dialog on wide
// (desktop/web) screens.

import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_context_ext.dart';

class SearchablePickerField<T> extends FormField<T> {
  SearchablePickerField({
    super.key,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    Widget Function(T)? itemLeading,
    required String label,
    String hint = 'Tap to select',
    IconData prefixIcon = Icons.list_alt_outlined,
    bool enabled = true,
    bool loading = false,
    String emptyMessage = 'No results found',
    String searchHint = 'Search...',
    String disabledHint = 'Select above first',
    required ValueChanged<T?> onChanged,
    FormFieldValidator<T>? validator,
  }) : super(
          initialValue: value,
          validator: validator,
          builder: (state) {
            Future<void> openPicker() async {
              if (!enabled || loading) return;
              final selected = await _showPicker<T>(
                context:     state.context,
                items:       items,
                itemLabel:   itemLabel,
                itemLeading: itemLeading,
                title:       label,
                searchHint:  searchHint,
                emptyMessage: emptyMessage,
              );
              if (selected != null) {
                state.didChange(selected);
                onChanged(selected);
              }
            }

            final hasValue = state.value != null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(label, style: AppTextStyles.label),
                ),
                InkWell(
                  onTap: openPicker,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      hintText:   !enabled ? disabledHint : hint,
                      prefixIcon: Icon(prefixIcon),
                      errorText:  state.errorText,
                      suffixIcon: loading
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : const Icon(Icons.expand_more_rounded),
                      enabled: enabled,
                    ),
                    child: Row(
                      children: [
                        if (hasValue && itemLeading != null) ...[
                          itemLeading(state.value as T),
                          const SizedBox(width: AppSizes.sm),
                        ],
                        Expanded(
                          child: Text(
                            hasValue ? itemLabel(state.value as T) : '',
                            style: state.context.textStyles.inputText,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );

  static Future<T?> _showPicker<T>({
    required BuildContext context,
    required List<T> items,
    required String Function(T) itemLabel,
    Widget Function(T)? itemLeading,
    required String title,
    required String searchHint,
    required String emptyMessage,
  }) {
    final isWide = MediaQuery.of(context).size.width > 700;
    final content = _PickerSheet<T>(
      items:        items,
      itemLabel:    itemLabel,
      itemLeading:  itemLeading,
      title:        title,
      searchHint:   searchHint,
      emptyMessage: emptyMessage,
    );

    if (isWide) {
      return showDialog<T>(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: SizedBox(width: 420, height: 520, child: content),
        ),
      );
    }

    return showModalBottomSheet<T>(
      context:        context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: content,
      ),
    );
  }
}

class _PickerSheet<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) itemLabel;
  final Widget Function(T)? itemLeading;
  final String title;
  final String searchHint;
  final String emptyMessage;

  const _PickerSheet({
    required this.items,
    required this.itemLabel,
    required this.itemLeading,
    required this.title,
    required this.searchHint,
    required this.emptyMessage,
  });

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  final _searchController = TextEditingController();
  late List<T> _filtered = widget.items;

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.items
          : widget.items
              .where((item) => widget.itemLabel(item).toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSizes.sm),
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: context.colors.divider,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: context.textStyles.h3),
              const SizedBox(height: AppSizes.sm),
              TextField(
                controller: _searchController,
                autofocus:  true,
                onChanged:  _onSearchChanged,
                decoration: InputDecoration(
                  hintText:   widget.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  isDense:    true,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Text(widget.emptyMessage, style: context.textStyles.bodyMedium),
                )
              : ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final item = _filtered[index];
                    return ListTile(
                      leading: widget.itemLeading?.call(item),
                      title:   Text(widget.itemLabel(item)),
                      onTap:   () => Navigator.pop(context, item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}