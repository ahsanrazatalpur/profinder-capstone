// lib/core/utils/about_icons.dart
//
// Maps the icon "key" an admin picks for an About Page section/item
// (stored as a plain string on the backend) to a Flutter IconData.
// Single source of truth for both the public About page renderer and the
// admin icon-picker grid — same pattern as getCategoryIcon().

import 'package:flutter/material.dart';

const Map<String, IconData> kAboutIconMap = {
  'rocket_launch':   Icons.rocket_launch_rounded,
  'shield_check':    Icons.verified_user_rounded,
  'star':            Icons.star_rounded,
  'users':           Icons.groups_rounded,
  'award':           Icons.emoji_events_rounded,
  'heart':           Icons.favorite_rounded,
  'check_circle':    Icons.check_circle_rounded,
  'handshake':       Icons.handshake_rounded,
  'globe':           Icons.public_rounded,
  'phone':           Icons.phone_rounded,
  'mail':            Icons.email_rounded,
  'clock':           Icons.access_time_rounded,
  'target':          Icons.track_changes_rounded,
  'lightbulb':       Icons.lightbulb_rounded,
  'trending_up':     Icons.trending_up_rounded,
  'lock':            Icons.lock_rounded,
  'thumbs_up':       Icons.thumb_up_rounded,
  'map_pin':         Icons.location_on_rounded,
  'briefcase':       Icons.work_rounded,
  'certificate':     Icons.workspace_premium_rounded,
  'flag':            Icons.flag_rounded,
  'building':        Icons.apartment_rounded,
  'chat':            Icons.chat_bubble_rounded,
  'download':        Icons.download_rounded,
  'search':          Icons.search_rounded,
  'calendar':        Icons.calendar_month_rounded,
  'gift':            Icons.card_giftcard_rounded,
  'zap':             Icons.bolt_rounded,
  'compass':         Icons.explore_rounded,
  'book':            Icons.menu_book_rounded,
};

IconData resolveAboutIcon(String key, {IconData fallback = Icons.stars_rounded}) {
  if (key.trim().isEmpty) return fallback;
  return kAboutIconMap[key.trim().toLowerCase()] ?? fallback;
}