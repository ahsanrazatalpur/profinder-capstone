// lib/core/utils/support_icons.dart
//
// Maps the icon "key" the server sends for Help Center categories (and the
// ticket categories) to a Flutter IconData. Same pattern as about_icons.dart /
// category_icons.dart. Only Material icons that are already used elsewhere in
// the app are listed here (no new icon dependency, never emoji).

import 'package:flutter/material.dart';

const Map<String, IconData> kSupportIconMap = {
  'account':       Icons.person_rounded,
  'booking':       Icons.event_note_rounded,
  'payment':       Icons.payments_rounded,
  'verification':  Icons.verified_user_rounded,
  'technical':     Icons.warning_amber_rounded,
  'privacy':       Icons.privacy_tip_rounded,
  'security':      Icons.lock_rounded,
  'feedback':      Icons.rate_review_rounded,
  'language':      Icons.language_rounded,
  'notifications': Icons.notifications_rounded,
  'chat':          Icons.chat_bubble_rounded,
  'contact':       Icons.support_agent_rounded,
  'article':       Icons.article_rounded,
  'help':          Icons.help_outline_rounded,
  'other':         Icons.help_outline_rounded,
};

IconData resolveSupportIcon(String? key, {IconData fallback = Icons.article_rounded}) {
  final k = (key ?? '').trim().toLowerCase();
  if (k.isEmpty) return fallback;
  return kSupportIconMap[k] ?? fallback;
}