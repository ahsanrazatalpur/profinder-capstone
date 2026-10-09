// lib/features/professional/widgets/review_sort_filter_bar.dart

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../l10n/generated/app_localizations.dart';

class SortOption {
  final String value;
  const SortOption(this.value);

  /// Localized label — resolved at build time so it follows the app language.
  String label(AppLocalizations t) {
    switch (value) {
      case 'newest':  return t.reviewSortNewest;
      case 'highest': return t.reviewSortHighest;
      case 'lowest':  return t.reviewSortLowest;
      case 'helpful': return t.reviewSortHelpful;
      case 'photos':  return t.reviewSortWithPhotos;
      default:        return t.reviewSortRelevant;
    }
  }
}

const kReviewSortOptions = [
  SortOption('relevant'),
  SortOption('newest'),
  SortOption('highest'),
  SortOption('lowest'),
  SortOption('helpful'),
  SortOption('photos'),
];

class ReviewSortFilterBar extends StatelessWidget {
  final String sort;
  final String ratingFilter; // 'all','5','4','3','2','1'
  final ValueChanged<String> onSortChanged;
  final ValueChanged<String> onFilterChanged;

  const ReviewSortFilterBar({
    super.key,
    required this.sort,
    required this.ratingFilter,
    required this.onSortChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final sortLabel = kReviewSortOptions.firstWhere((o) => o.value == sort).label(t);
    final filters = ['all', '5', '4', '3', '2', '1'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Sort dropdown ──
        InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          onTap: () => _openSortSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(color: context.colors.divider),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swap_vert_rounded, size: 16, color: context.colors.textSecondary),
                const SizedBox(width: 6),
                Text(sortLabel,
                    style: TextStyle(
                        fontSize: AppFontSizes.secondary, fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: context.colors.textSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ── Star filter chips ──
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final f = filters[i];
              final selected = f == ratingFilter;
              final label = f == 'all' ? t.reviewFilterAll : '$f★';
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => onFilterChanged(f),
                  labelStyle: TextStyle(
                    fontSize: AppFontSizes.secondary,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : context.colors.textPrimary,
                  ),
                  selectedColor: context.colors.primary,
                  backgroundColor: context.colors.surface,
                  side: BorderSide(color: selected ? context.colors.primary : context.colors.divider),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusSheet)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: sheetContext.colors.divider, borderRadius: BorderRadius.circular(AppSizes.radiusXs)),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(AppLocalizations.of(sheetContext).reviewSortBy,
                      style: TextStyle(
                          fontSize: AppFontSizes.body, fontWeight: FontWeight.w700, color: sheetContext.colors.textPrimary)),
                ),
              ),
              ...kReviewSortOptions.map((opt) => ListTile(
                    title: Text(opt.label(AppLocalizations.of(sheetContext)), style: TextStyle(fontSize: AppFontSizes.body, color: sheetContext.colors.textPrimary)),
                    trailing: opt.value == sort
                        ? Icon(Icons.check_rounded, color: sheetContext.colors.primary)
                        : null,
                    onTap: () {
                      onSortChanged(opt.value);
                      Navigator.pop(sheetContext);
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}