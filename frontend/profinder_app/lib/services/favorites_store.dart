// lib/services/favorites_store.dart
//
// Favourites are persisted on-device with SharedPreferences (id + a small
// JSON snapshot, so the "Saved Professionals" screen renders instantly
// without a network round-trip) AND, best-effort, synced to the backend's
// `/search/favorites/<id>/toggle/` endpoint (see apps/search/models.py:
// Favorite) — added so favourites can feed into the "Trending This Week"
// signal on the Customer Dashboard. The backend call is fire-and-forget:
// if it fails (offline, logged out, etc.) the local toggle still succeeds,
// so the UI never blocks on network for something this lightweight — it
// just won't count toward Trending until the next successful sync.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../core/constants/app_constants.dart';

class FavoritesStore {
  static const _key = 'favourite_professionals_v1';
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeAll(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data));
  }

  Future<Set<String>> getIds() async => (await _readAll()).keys.toSet();

  Future<bool> isFavorite(String id) async => (await _readAll()).containsKey(id);

  Future<List<Map<String, dynamic>>> getAll() async {
    final all = await _readAll();
    return all.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> toggle(Map<String, dynamic> professional) async {
    final id  = professional['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final all = await _readAll();
    if (all.containsKey(id)) {
      all.remove(id);
    } else {
      all[id] = professional;
    }
    await _writeAll(all);

    // Best-effort backend sync — never lets a network failure block the
    // local toggle the user just saw happen.
    try {
      await _api.post(AppConstants.favoriteToggle(id), {});
    } catch (_) {
      // Offline / guest / server hiccup — local favourite still stands.
    }
  }

  Future<void> remove(String id) async {
    final all = await _readAll();
    all.remove(id);
    await _writeAll(all);
    try {
      await _api.post(AppConstants.favoriteToggle(id), {});
    } catch (_) {}
  }
}