// lib/core/utils/category_icons.dart
//
// Single source of truth for mapping a category/profession name to an
// icon. Keyed by keyword so it works for any string the backend sends,
// not just a fixed category list. Falls back to a generic briefcase icon
// when nothing matches.
//
// Used by: search_screen.dart (browse-by-category list, category
// suggestions), professional_card.dart, professional_home_screen.dart.

import 'package:flutter/material.dart';

IconData getCategoryIcon(String category) {
  final c = category.toLowerCase();
  if (c.contains('tutor') || c.contains('educat') || c.contains('teach')) return Icons.menu_book_rounded;
  if (c.contains('doctor') || c.contains('medic') || c.contains('health')) return Icons.medical_services_outlined;
  if (c.contains('lawyer') || c.contains('legal')) return Icons.gavel_outlined;
  if (c.contains('engineer')) return Icons.engineering_outlined;
  if (c.contains('plumb')) return Icons.plumbing_outlined;
  if (c.contains('electric')) return Icons.electrical_services;
  if (c.contains('clean')) return Icons.cleaning_services;
  if (c.contains('carpent')) return Icons.carpenter;
  if (c.contains('paint')) return Icons.format_paint_outlined;
  if (c.contains('architect')) return Icons.architecture;
  if (c.contains('account') || c.contains('financ')) return Icons.account_balance_outlined;
  if (c.contains('comput') || c.contains('it ') || c.contains('developer') || c.contains('software')) return Icons.computer_outlined;
  if (c.contains('beauty') || c.contains('salon') || c.contains('makeup')) return Icons.face_retouching_natural_outlined;
  if (c.contains('fitness') || c.contains('trainer') || c.contains('gym')) return Icons.fitness_center_outlined;
  if (c.contains('photo')) return Icons.camera_alt_outlined;
  return Icons.work_outline_rounded;
}