// lib/shared/widgets/featured_category_card.dart
//
// FEATURED CATEGORY CARD — shared gradient card used by every "Featured
// Categories" section across the app (currently Guest Home; wire in
// Customer Home or anywhere else the same section appears the same way).
//
// Pure UI component — no network calls, no backend logic. Parent passes
// the category map + a tap handler; this file owns only how it looks.
//
// Design notes:
//   • No repeated "FEATURED" eyebrow on every card — the section header
//     above the row already says "Featured Categories".
//   • No trailing arrow glyph on the CTA text.
//   • The category icon is drawn large and bleeds off the bottom-right
//     edge so the card reads as full, not half-empty.

import 'package:flutter/material.dart';
import '../../core/constants/app_sizes.dart';

class FeaturedCategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
  final double width;
  final double height;

  const FeaturedCategoryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.width = 210,
    this.height = 128,
  });

  @override
  Widget build(BuildContext context) {
    final softenedGradient = [
      ...gradient.take(gradient.length - 1),
      Color.lerp(gradient.last, Colors.white, 0.3)!,
    ];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: softenedGradient,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Single icon layer, confined to the right edge and sized off
            // the card height — never taller/wider than the card itself,
            // and kept at a moderate opacity so it reads as a graphic, not
            // a wash that fights with the text.
            Positioned(
              right: -18,
              bottom: -6,
              child: Icon(
                icon,
                size: height * 0.7,
                color: Colors.white.withOpacity(0.45),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Capped at ~58% of card width so the title text can
                  // never run into the icon's zone on the right.
                  SizedBox(
                    width: width * 0.58,
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  ),
                  Text(
                    'Explore experts',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}