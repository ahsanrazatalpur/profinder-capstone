// lib/features/profile/services/favorites_store.dart
//
// Favourites persistence on-device and best-effort backend sync.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_service.dart';

class FavoritesStore {
  static const _key = 'favourite_professionals_v1';
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
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

  Future<bool> isFavorite(String id) async =>
      (await _readAll()).containsKey(id);

  Future<List<Map<String, dynamic>>> getAll() async {
    final all = await _readAll();
    return all.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> toggle(Map<String, dynamic> professional) async {
    final id = professional['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final all = await _readAll();
    if (all.containsKey(id)) {
      all.remove(id);
    } else {
      all[id] = professional;
    }
    await _writeAll(all);

    try {
      await _api.post(AppConstants.favoriteToggle(id), {});
    } catch (_) {}
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
