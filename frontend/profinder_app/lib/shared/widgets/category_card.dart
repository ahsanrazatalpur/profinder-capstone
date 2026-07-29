// lib/shared/widgets/category_card.dart
//
// GLOBAL "popular category" card + grid + "view all" sheet.
//
// Pehle yeh poora UI (card design, grid, aur "view all" bottom sheet)
// guest_home_screen.dart mein likha tha, aur customer_home_screen.dart
// mein ek bilkul alag copy thi. Ab dono screens isi ek widget ko use
// karte hain — jahan bhi "Popular Categories" chahiye, bas yahi import
// karo, dobara code likhne ki zaroorat nahi.

import 'package:flutter/material.dart';
import '../../core/constants/category_style.dart';
import '../../core/theme/theme_context_ext.dart';

class PremiumCategoryCard extends StatelessWidget {
  final Map category;
  final int fallbackIndex;
  final bool isDark;
  final bool selected;
  final VoidCallback? onTap;

  const PremiumCategoryCard({
    super.key,
    required this.category,
    required this.fallbackIndex,
    required this.isDark,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = category['name']?.toString() ?? '';
    final style = CategoryStyles.forName(name, fallbackIndex);
    final color = style.color;
    final gradient = style.gradient
        .map((c) => Color.lerp(c, Colors.white, 0.18)!)
        .toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
                : const [Colors.white, Color(0xFFF8FAFC)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? color
                : (isDark ? Colors.white.withOpacity(0.06) : color.withOpacity(0.15)),
            width: selected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : color.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(style.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxWidth: 80),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                    color: context.colors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 20,
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Popular categories grid (home-screen "Popular Categories" section).
/// [onCategoryTap] gets the raw category Map — caller decides kya karna
/// hai (guest: search screen open; customer: local filter select).
class PopularCategoriesGrid extends StatelessWidget {
  final List<dynamic> categories;
  final bool isDark;
  final void Function(Map category) onCategoryTap;
  final int limit;
  final int crossAxisCount;
  final dynamic selectedId;

  const PopularCategoriesGrid({
    super.key,
    required this.categories,
    required this.isDark,
    required this.onCategoryTap,
    this.limit = 8,
    this.crossAxisCount = 4,
    this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    final items = categories.take(limit).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (_, i) {
        final cat = items[i] as Map;
        return PremiumCategoryCard(
          category: cat,
          fallbackIndex: i,
          isDark: isDark,
          selected: selectedId != null && cat['id'] == selectedId,
          onTap: () => onCategoryTap(cat),
        );
      },
    );
  }
}

/// "View all categories" bottom sheet — shared so every screen that needs
/// the full category grid (guest + customer home, and anywhere else later)
/// opens the exact same sheet.
void showAllCategoriesSheet(
  BuildContext context, {
  required List<dynamic> categories,
  required bool isDark,
  required void Function(Map category) onCategoryTap,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? context.colors.background : context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Categories',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : context.colors.divider.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close_rounded,
                      color: context.colors.textPrimary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 14,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (_, i) {
                final cat = categories[i] as Map;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onCategoryTap(cat);
                  },
                  child: PremiumCategoryCard(
                    category: cat,
                    fallbackIndex: i,
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}