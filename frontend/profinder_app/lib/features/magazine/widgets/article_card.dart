// lib/features/magazine/widgets/article_card.dart

import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../../../core/theme/theme_context_ext.dart';

class ArticleCard extends StatelessWidget {
  final Article      article;
  final VoidCallback onTap;

  const ArticleCard({super.key, required this.article, required this.onTap});

  // ── Responsive height helper — the magazine grid needs to know this
  // card's height BEFORE building it (SliverGrid's mainAxisExtent is
  // fixed per cell), so this mirrors ProfessionalCard.heightFor's
  // pattern: one source of truth both the card and its parent grid use,
  // instead of a hardcoded magic number that silently goes stale the
  // moment fonts, image aspect ratio, or accessibility text scale change.
  //
  // `cardWidth` should be the actual width each grid cell will render at
  // (needed because the cover image's height is now width-proportional,
  // not a fixed 180px, so a 2-column tablet layout gets a shorter image
  // than a 1-column phone layout).
  static double heightFor(BuildContext context, {required double cardWidth}) {
    final imageHeight = _imageHeightFor(cardWidth);
    final textScale = MediaQuery.textScalerOf(context)
        .clamp(minScaleFactor: 0.9, maxScaleFactor: 1.3)
        .scale(1.0);
    // Base text/body area measured at textScale == 1.0 (padding + chip +
    // title(2 lines) + summary(2 lines) + divider + meta row), plus a
    // proportional buffer so larger accessibility font sizes don't blow
    // past the reserved cell height and trigger an overflow.
    const bodyBase = 214.0;
    final body = bodyBase * (1 + (textScale - 1) * 0.6);
    return imageHeight + body;
  }

  static double _imageHeightFor(double cardWidth) => (cardWidth * 0.42).clamp(120.0, 190.0);

  @override
  Widget build(BuildContext context) {
    final catColor = _hexColor(article.categoryColor);
    // Clamp accessibility text scaling so a very large system font size
    // can't push this card's content taller than the buffer heightFor()
    // already reserves for it in the parent grid.
    final clampedTextScaler = MediaQuery.textScalerOf(context).clamp(minScaleFactor: 0.9, maxScaleFactor: 1.3);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: clampedTextScaler),
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color:        context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Cover — height is now proportional to the card's actual
            // rendered width (via LayoutBuilder) instead of a fixed 180px,
            // so it scales correctly whether the grid gives this card the
            // full phone width or a narrower tablet column. ────────────
            LayoutBuilder(
              builder: (context, constraints) {
                final imgHeight = _imageHeightFor(constraints.maxWidth);
                return ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: article.coverImage.isNotEmpty
                      ? Image.network(
                          article.coverImage,
                          height: imgHeight, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderCover(catColor, imgHeight),
                        )
                      : _placeholderCover(catColor, imgHeight),
                );
              },
            ),

            // ── Body ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Category chip
                  if (article.categoryName.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color:        catColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        article.categoryName.toUpperCase(),
                        style: TextStyle(
                          fontSize:      9,
                          fontWeight:    FontWeight.w800,
                          color:         catColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Title
                  Text(
                    article.title,
                    style: TextStyle(
                      fontSize:   16,
                      fontWeight: FontWeight.w800,
                      color:      context.colors.textPrimary,
                      height:     1.3,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Summary
                  if (article.summary.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      article.summary,
                      style: TextStyle(
                        fontSize:      13.5,
                        letterSpacing: 0.15,
                        color:         context.colors.textSecondary,
                        height:        1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 12),
                  Divider(height: 1, color: context.colors.divider),
                  const SizedBox(height: 10),

                  // ── Meta row — editorial label, read time, views ──
                  Row(
                    children: [
                      // Editorial byline — professional, no "admin"
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                color:  catColor.withOpacity(0.12),
                                shape:  BoxShape.circle,
                              ),
                              child: Icon(Icons.edit_rounded,
                                  color: catColor, size: 11),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                article.editorialLabel,
                                style: TextStyle(
                                  fontSize:      11.5,
                                  fontWeight:    FontWeight.w600,
                                  letterSpacing: 0.1,
                                  color:         context.colors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Read time — wrapped in FittedBox so on very
                      // narrow phones (or large accessibility text) it
                      // scales down slightly instead of pushing the row
                      // wider than the card and overflowing sideways.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule_outlined,
                                size: 12, color: context.colors.textSecondary),
                            const SizedBox(width: 3),
                            Text('${article.readTime} min',
                                style: TextStyle(
                                    fontSize: 11.5, letterSpacing: 0.1, color: context.colors.textSecondary)),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Views
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility_outlined,
                                size: 12, color: context.colors.textSecondary),
                            const SizedBox(width: 3),
                            Text(_formatCount(article.viewsCount),
                                style: TextStyle(
                                    fontSize: 11.5, letterSpacing: 0.1, color: context.colors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _placeholderCover(Color catColor, double height) {
    return Container(
      height: height,
      color:  catColor.withOpacity(0.10),
      child: Center(
        child: Icon(Icons.menu_book_rounded, color: catColor.withOpacity(0.4), size: 48),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }

  Color _hexColor(String hex) {
    try { return Color(int.parse(hex.replaceFirst('#', '0xFF'))); }
    catch (_) { return const Color(0xFF2563EB); }
  }
}