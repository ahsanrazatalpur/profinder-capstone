// lib/services/api_service.dart

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class ApiService {
  // Singleton pattern — only one instance in the whole app
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _setupDio();
  }

  late final Dio _dio;

  // ✅ FIX: SharedPreferences cache — pehle har request pe
  // SharedPreferences.getInstance() fresh call hoti thi jo slow thi.
  // Ab ek baar load hogi, baad mein cached instance use hoga.
  SharedPreferences? _prefs;
  Future<SharedPreferences> get _getPrefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ✅ FIX: Token refresh — jab 9+ requests ek saath 401 dein (jaisa
  // professional dashboard ka Future.wait karta hai), sirf EK refresh
  // call fire honi chahiye, baaki sab usi ka result share karein.
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

      // Alag Dio instance — is call pe access-token interceptor/onError
      // recursion nahi lagni chahiye.
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
        baseUrl:        AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        // Note: Content-Type is NOT set here as a default
        // For JSON calls: Dio sets it automatically
        // For multipart (FormData): Dio sets it to multipart/form-data automatically
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptor — har request se pehle JWT token attach karo
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // ✅ FIX: Cached _getPrefs use kiya — getInstance() baar baar nahi chalega
          final prefs = await _getPrefs;
          final token = prefs.getString(AppConstants.accessTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          final isRefreshCall  = error.requestOptions.path.contains(AppConstants.tokenRefresh);
          final alreadyRetried = error.requestOptions.extra['retried'] == true;

          if (isUnauthorized && !isRefreshCall && !alreadyRetried) {
            final newAccess = await _refreshAccessToken();
            if (newAccess != null) {
              // Original (failed) request ko naye token ke saath dobara try karo
              final retryOptions = error.requestOptions
                ..headers['Authorization'] = 'Bearer $newAccess'
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
              // Refresh token bhi expire/invalid — session clear karo taake
              // app login screen pe route kare (AuthProvider isko check karta hai).
              final prefs = await _getPrefs;
              await prefs.remove(AppConstants.accessTokenKey);
              await prefs.remove(AppConstants.refreshTokenKey);
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  // ✅ FIX: Bahar se prefs cache set karne ka method — main() mein
  // pre-warmed instance seedha yahan inject kar sakte ho taake
  // pehli request pe bhi delay na ho.
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

  // ── PATCH (JSON) — text-only updates ke liye ─────────────
  Future<Response> patch(String endpoint, Map<String, dynamic> data) async {
    return await _dio.patch(
      endpoint,
      data: data,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
  }

  // ── PATCH (Multipart) — file uploads ke liye ─────────────
  // Jab text + file dono ek saath bhejne ho (profile photo upload, etc.)
  // FormData use karna padta hai — JSON mein binary file nahi bhej sakte
  // Example usage:
  //   final formData = FormData.fromMap({
  //     'full_name': 'Ahsan',
  //     'photo': await MultipartFile.fromFile('/path/to/image.jpg'),
  //   });
  //   await _api.patchForm('/profiles/user/', formData);
  Future<Response> patchForm(String endpoint, FormData formData) async {
    return await _dio.patch(
      endpoint,
      data: formData,
      // Content-Type: multipart/form-data — Dio automatically sets boundary
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );
  }

  // ── POST (Multipart) — file uploads with POST ────────────
  Future<Response> postForm(String endpoint, FormData formData) async {
    return await _dio.post(
      endpoint,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );
  }

  // ── DELETE ───────────────────────────────────────────────
  Future<Response> delete(String endpoint) async {
    return await _dio.delete(endpoint);
  }

  // ── DELETE (with body) ──────────────────────────────────
  // Dio's plain delete() has no `data` param exposed the same way as
  // post/patch — some backends (e.g. review deletion with a required
  // `reason`) expect a JSON body on DELETE. This keeps that payload.
  Future<Response> deleteWithBody(String endpoint, Map<String, dynamic> body) async {
    return await _dio.delete(endpoint, data: body);
  }
}