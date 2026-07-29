// lib/core/utils/responsive_utils.dart
//
// Shared responsive scaling helper for mobile/tablet layouts (Guest
// Dashboard and friends). Mirrors the same "continuous scale, clamped,
// driven by available width" approach already used by
// `shared/widgets/professional_card.dart`, so the rest of the dashboard
// scales consistently instead of every widget inventing its own
// breakpoints.
//
// Pure sizing/layout helper — no colors, branding, or business logic here.
//
// Design intent (per the responsiveness pass):
//   • Small phones (320dp+) never get crushed below a legible/tappable
//     floor.
//   • Large phones / foldables scale smoothly — no stepped jumps.
//   • Tablets don't just get bigger text/icons forever — past a point,
//     extra width buys MORE columns / wider cards instead, so the screen
//     never looks sparse but also never looks cartoonishly oversized.
//   • Everything is derived from available width (via LayoutBuilder where
//     the caller has it, MediaQuery otherwise) — never a hardcoded device
//     check.

import 'package:flutter/material.dart';

class ResponsiveUtils {
  ResponsiveUtils._();

  /// Reference width: a standard ~390dp phone — the baseline every scaled
  /// value is expressed relative to.
  static const double _baseWidth = 390.0;

  /// Continuous (non-stepped) scale factor derived from the available
  /// width. Clamped at both ends:
  ///   • Below ~0.85 things start becoming illegible/hard to tap, so small
  ///     phones (320–360dp) bottom out there instead of shrinking further.
  ///   • Above ~1.3 icons/text would look oversized rather than "premium",
  ///     so large tablets rely on [gridColumns] / wider cards / more
  ///     content instead of ever-growing glyphs.
  static double scaleForWidth(double width) => (width / _baseWidth).clamp(0.86, 1.3);

  /// Scale factor for the current [context]'s screen width. Prefer
  /// [scaleForWidth] with a `LayoutBuilder`-supplied width when sizing
  /// something that lives inside a narrower parent (a grid cell, a sheet)
  /// than the full screen.
  static double scaleOf(BuildContext context) => scaleForWidth(MediaQuery.sizeOf(context).width);

  /// Scaled pixel value. `min`/`max` guard the legible/tappable floor and
  /// the "still looks intentional, not stretched" ceiling.
  static double sp(double base, double scale, {double? min, double? max}) {
    final value = base * scale;
    return value.clamp(min ?? (base * 0.75), max ?? (base * 1.55));
  }

  static bool isTablet(double width)      => width >= 600;
  static bool isLargeTablet(double width) => width >= 900;

  /// Grid columns for category-style grids (Popular Categories, All
  /// Categories sheet, etc.) — more columns as width grows so cards widen
  /// into the extra space instead of leaving big empty margins, while
  /// never letting a single cell get so wide it looks stretched.
  ///
  /// `base` is the phone column count (kept identical to the original
  /// design); columns only ever grow from there, never shrink below it.
  static int gridColumns(double width, {int base = 4, double targetCellWidth = 88}) {
    final raw = (width / targetCellWidth).floor();
    return raw.clamp(base, base + 4);
  }

  /// Caps how wide a horizontally-scrolling card gets on very large
  /// tablets so a single card never sprawls into something out of
  /// proportion with the rest of the UI, while still letting it grow
  /// noticeably past the phone baseline.
  static double cardWidthFor(double availableWidth, double baseWidth, {double minScale = 0.86, double maxScale = 1.55}) {
    final scale = (availableWidth / _baseWidth).clamp(minScale, maxScale);
    return baseWidth * scale;
  }

  /// Horizontal padding for screen-edge content — scales gently so large
  /// tablets get a bit more breathing room without the phone padding
  /// feeling cramped.
  static double screenPadding(double width, {double base = 20}) => sp(base, scaleForWidth(width), min: base, max: base * 1.6);

  /// Required height for a "category tile" cell (icon box + spacing +
  /// up-to-2-line label) at the given [iconBoxSize]/[fontSize]/[scale].
  ///
  /// Grids that lay these tiles out should pass this as the grid
  /// delegate's `mainAxisExtent` instead of a fixed `childAspectRatio` —
  /// an aspect ratio ties cell height to cell width, so the moment a cell
  /// gets narrower (more columns, a smaller phone) or the label wraps to
  /// two lines, the fixed-ratio cell runs out of room and Flutter throws
  /// a bottom `RenderFlex overflowed` error. Deriving the height directly
  /// from the actual content instead guarantees it always fits, at any
  /// column count or screen width.
  static double categoryTileHeight({
    required double iconBoxSize,
    required double fontSize,
    double labelLines = 2,
    double spacingBelowIcon = 6,
  }) {
    // Line height ~1.25x font size is a safe approximation for the default
    // Material text style used on these labels; a small buffer absorbs
    // minor font-metric/accessibility-scale rounding.
    final labelHeight = fontSize * 1.25 * labelLines;
    const buffer = 6.0;
    return iconBoxSize + spacingBelowIcon + labelHeight + buffer;
  }
}