// lib/core/network/api_service.dart

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../localization/locale_provider.dart';

export 'api_exception.dart';

/// Central HTTP Client for ProFinder.
///
/// Features:
/// - Singleton Dio client with automatic JWT header injection.
/// - Language header synchronization ('X-App-Language') for dynamic i18n.
/// - Thread-safe 401 token refresh queue with single-flight mutex.
/// - Graceful handling of guest vs authenticated sessions.
/// - Multipart and JSON body helpers for standard REST endpoints.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _setupDio();
  }

  late final Dio _dio;

  /// Underlying Dio instance for specialized handlers or tests.
  Dio get client => _dio;

  /// Bumped when a response arrived with some strings still untranslated and a
  /// silent background re-fetch has since finished (server has them cached now).
  static final ValueNotifier<int> contentRevision = ValueNotifier<int>(0);

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _getPrefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Completer<String?>? _refreshCompleter;

  Future<String?> _refreshAccessToken() async {
    if (_refreshCompleter != null) return _refreshCompleter!.future;
    _refreshCompleter = Completer<String?>();

    try {
      final prefs = await _getPrefs;
      final refreshToken = prefs.getString(AppConstants.refreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(null);
        return null;
      }

      final refreshDio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
      final res = await refreshDio.post(
        AppConstants.tokenRefresh,
        data: {'refresh': refreshToken},
      );
      final newAccess = res.data['access']?.toString();
      if (newAccess != null && newAccess.isNotEmpty) {
        await prefs.setString(AppConstants.accessTokenKey, newAccess);
      }
      _refreshCompleter!.complete(newAccess);
      return newAccess;
    } catch (_) {
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  void _setupDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 60),
        headers: {'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['X-App-Language'] = LocaleProvider.currentCode;
          final prefs = await _getPrefs;
          final token = prefs.getString(AppConstants.accessTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            options.extra['sentToken'] = token;
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          final ro = response.requestOptions;
          if (response.headers.value('x-translation-pending') != null &&
              ro.method == 'GET' &&
              ro.extra['i18nRetried'] != true) {
            ro.extra['i18nRetried'] = true;
            Future.delayed(const Duration(seconds: 5), () async {
              try {
                await _dio.fetch(ro);
                contentRevision.value++;
              } catch (_) {
                /* best effort only */
              }
            });
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          final isRefreshCall = error.requestOptions.path.contains(
            AppConstants.tokenRefresh,
          );
          final alreadyRetried = error.requestOptions.extra['retried'] == true;

          if (isUnauthorized && !isRefreshCall && !alreadyRetried) {
            final sentToken =
                error.requestOptions.extra['sentToken'] as String?;

            if (sentToken == null) {
              handler.next(error);
              return;
            }

            final prefs = await _getPrefs;
            final currentToken = prefs.getString(AppConstants.accessTokenKey);
            if (currentToken != null && currentToken != sentToken) {
              try {
                final retryOptions = error.requestOptions
                  ..headers['Authorization'] = 'Bearer $currentToken'
                  ..extra['sentToken'] = currentToken
                  ..extra['retried'] = true;
                final response = await _dio.fetch(retryOptions);
                handler.resolve(response);
                return;
              } catch (_) {
                handler.next(error);
                return;
              }
            }

            final newAccess = await _refreshAccessToken();
            if (newAccess != null) {
              final retryOptions = error.requestOptions
                ..headers['Authorization'] = 'Bearer $newAccess'
                ..extra['sentToken'] = newAccess
                ..extra['retried'] = true;
              try {
                final response = await _dio.fetch(retryOptions);
                handler.resolve(response);
                return;
              } catch (_) {
                handler.next(error);
                return;
              }
            } else {
              final latestToken = prefs.getString(AppConstants.accessTokenKey);
              if (latestToken == null || latestToken == sentToken) {
                await prefs.remove(AppConstants.accessTokenKey);
                await prefs.remove(AppConstants.refreshTokenKey);
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  void setPrefsCache(SharedPreferences prefs) {
    _prefs = prefs;
  }

  // ── GET ─────────────────────────────────────────────────
  Future<Response> get(String endpoint) async {
    return await _dio.get(endpoint);
  }

  // ── POST (JSON) ──────────────────────────────────────────
  Future<Response> post(String endpoint, Map<String, dynamic> data) async {
    return await _dio.post(
      endpoint,
      data: data,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
  }

  // ── PUT (JSON) ───────────────────────────────────────────
  Future<Response> put(String endpoint, Map<String, dynamic> data) async {
    return await _dio.put(
      endpoint,
      data: data,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
  }

  // ── PATCH (JSON) ─────────────────────────────────────────
  Future<Response> patch(String endpoint, Map<String, dynamic> data) async {
    return await _dio.patch(
      endpoint,
      data: data,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
  }

  // ── PATCH (Multipart) ────────────────────────────────────
  Future<Response> patchForm(String endpoint, FormData formData) async {
    return await _dio.patch(
      endpoint,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  // ── POST (Multipart) ─────────────────────────────────────
  Future<Response> postForm(String endpoint, FormData formData) async {
    return await _dio.post(
      endpoint,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  // ── DELETE ───────────────────────────────────────────────
  Future<Response> delete(String endpoint) async {
    return await _dio.delete(endpoint);
  }

  // ── DELETE (with body) ───────────────────────────────────
  Future<Response> deleteWithBody(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    return await _dio.delete(
      endpoint,
      data: body,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
  }
}
