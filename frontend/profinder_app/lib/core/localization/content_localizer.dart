// lib/core/localization/content_localizer.dart
//
// Localizes dynamic display text that the backend stores in English:
// names, cities, categories, AI text.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../network/api_service.dart';
import 'locale_provider.dart';

class LocKind {
  static const name = 'name';
  static const city = 'city';
  static const category = 'category';
  static const text = 'text';
}

class ContentLocalizer extends ChangeNotifier {
  ContentLocalizer._();
  static final ContentLocalizer instance = ContentLocalizer._();

  static const _maxPersisted = 1500;
  static const _batchSize = 50;

  final ApiService _api = ApiService();

  final Map<String, String> _mem = {};
  final Set<String> _queued = {};
  final Set<String> _inflight = {};
  final Set<String> _misses = {};
  final Set<String> _loadedLangs = {};
  DateTime? _backoffUntil;
  Timer? _flushTimer;
  Timer? _persistTimer;
  Completer<void>? _flushDone;

  static String _k(String lang, String kind, String text) =>
      '$lang|$kind|$text';
  static String get _lang => LocaleProvider.currentCode;
  static final RegExp _arabicScript = RegExp(r'[\u0600-\u06FF]');
  static final RegExp _devanagari = RegExp(r'[\u0900-\u097F]');

  static bool _alreadyTargetScript(String lang, String text) {
    final re = (lang == 'ur' || lang == 'ar')
        ? _arabicScript
        : (lang == 'hi' ? _devanagari : null);
    return re != null && re.hasMatch(text);
  }

  static bool _needsWork(String lang, String text) =>
      lang != 'en' &&
      text.trim().isNotEmpty &&
      !_alreadyTargetScript(lang, text);

  // ── Public API ────────────────────────────────────────────────────

  String peek(String text, String kind) {
    final lang = _lang;
    if (!_needsWork(lang, text)) return text;
    _ensureLoaded(lang);
    final key = _k(lang, kind, text.trim());
    final hit = _mem[key];
    if (hit != null) return hit;
    _enqueue(lang, kind, text.trim());
    return text;
  }

  void register(String lang, String kind, String source, String localized) {
    if (source.trim().isEmpty || localized.trim().isEmpty) return;
    if (localized.trim() == source.trim()) return;
    _mem[_k(lang, kind, source.trim())] = localized.trim();
  }

  Future<void> prefetch(Iterable<String?> texts, String kind) async {
    final lang = _lang;
    if (lang == 'en') return;
    await _ensureLoaded(lang);
    var any = false;
    for (final t in texts) {
      final v = t?.trim() ?? '';
      if (v.isEmpty ||
          !_needsWork(lang, v) ||
          _mem.containsKey(_k(lang, kind, v)))
        continue;
      _enqueue(lang, kind, v, schedule: false);
      any = true;
    }
    if (any) await _flush();
  }

  // ── Internals ─────────────────────────────────────────────────────

  Future<void> _ensureLoaded(String lang) async {
    if (!_loadedLangs.add(lang)) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('content_l10n_$lang');
      if (raw == null) return;
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      map.forEach((k, v) => _mem.putIfAbsent(k, () => v.toString()));
      notifyListeners();
    } catch (_) {}
  }

  void _enqueue(String lang, String kind, String text, {bool schedule = true}) {
    final key = _k(lang, kind, text);
    if (_mem.containsKey(key) ||
        _inflight.contains(key) ||
        _misses.contains(key))
      return;
    if (text.length > 300) return;
    _queued.add(key);
    if (schedule) {
      _flushTimer ??= Timer(const Duration(milliseconds: 60), () {
        _flushTimer = null;
        _flush();
      });
    }
  }

  Future<void> _flush() async {
    if (_flushDone != null) return _flushDone!.future;
    if (_queued.isEmpty) return;
    if (_backoffUntil != null && DateTime.now().isBefore(_backoffUntil!)) {
      _queued.clear();
      return;
    }
    final done = _flushDone = Completer<void>();
    try {
      while (_queued.isNotEmpty) {
        final batch = _queued.take(_batchSize).toList();
        _queued.removeAll(batch);
        _inflight.addAll(batch);
        await _sendBatch(batch);
        _inflight.removeAll(batch);
      }
    } finally {
      _flushDone = null;
      done.complete();
    }
  }

  Future<void> _sendBatch(List<String> keys) async {
    final byLang = <String, List<String>>{};
    for (final k in keys) {
      byLang.putIfAbsent(k.split('|').first, () => []).add(k);
    }
    for (final entry in byLang.entries) {
      final lang = entry.key;
      final parsed = entry.value.map((k) {
        final p = k.split('|');
        return (
          key: k,
          kind: p[1],
          text: k.substring(p[0].length + p[1].length + 2),
        );
      }).toList();
      try {
        final res = await _api.post(AppConstants.aiLocalize, {
          'lang': lang,
          'items': [
            for (final p in parsed) {'text': p.text, 'kind': p.kind},
          ],
        });
        final tr =
            (res.data is Map ? res.data['translations'] : null) as Map? ?? {};
        var changed = false;
        for (final p in parsed) {
          final out = (tr[p.kind] as Map?)?[p.text]?.toString().trim() ?? '';
          if (out.isEmpty || out == p.text) {
            _misses.add(p.key);
          } else {
            _mem[p.key] = out;
            changed = true;
          }
        }
        if (changed) {
          notifyListeners();
          _schedulePersist(lang);
        }
      } catch (_) {
        _backoffUntil = DateTime.now().add(const Duration(minutes: 1));
      }
    }
  }

  void _schedulePersist(String lang) {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(seconds: 2), () async {
      try {
        final prefix = '$lang|';
        final entries = _mem.entries
            .where((e) => e.key.startsWith(prefix))
            .toList();
        final trimmed = entries.length > _maxPersisted
            ? entries.sublist(entries.length - _maxPersisted)
            : entries;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'content_l10n_$lang',
          jsonEncode({for (final e in trimmed) e.key: e.value}),
        );
      } catch (_) {}
    });
  }
}

class LocalizedText extends StatelessWidget {
  const LocalizedText(
    this.text, {
    super.key,
    this.kind = LocKind.text,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.isolate = false,
    this.uppercase = false,
  });

  final String text;
  final String kind;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool isolate;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ContentLocalizer.instance,
      builder: (context, _) {
        var v = ContentLocalizer.instance.peek(text, kind);
        if (uppercase) v = v.toUpperCase();
        return Text(
          isolate ? '\u2068$v\u2069' : v,
          style: style,
          maxLines: maxLines,
          overflow: overflow,
          textAlign: textAlign,
        );
      },
    );
  }
}
