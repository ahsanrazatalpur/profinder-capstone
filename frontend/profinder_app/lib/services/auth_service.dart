// lib/services/auth_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import 'api_service.dart';
import 'push_notification_service.dart'; // ✅ NEW

class AuthService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> register({
    required String email,
    required String name,
    required String role,
    required String password,
    String? city,
    String? country,
    int?    categoryId,
  }) async {
    try {
      final body = <String, dynamic>{
        'email':    email,
        'name':     name,
        'role':     role,
        'password': password,
      };
      if (city != null && city.isNotEmpty) body['city'] = city;
      if (country != null && country.isNotEmpty) body['country'] = country;
      if (categoryId != null) body['category_id'] = categoryId;

      final response = await _api.post(AppConstants.register, body);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post(
        AppConstants.login,
        {'email': email, 'password': password},
      );
      await _saveTokens(
        access:  response.data['access'],
        refresh: response.data['refresh'],
        role:    response.data['role'],
      );
      // ✅ NEW — login hote hi device ka FCM token backend ko bhej do
      await PushNotificationService().registerToken();
      return {'success': true, 'data': response.data};
    } catch (e) {
      return _handleError(e);
    }
  }

  // ✅ NEW — Register Step 1 realtime email availability check.
  // Returns {'success': true, 'available': bool} on a clean response;
  // {'success': false, 'available': null} on network/server error — the
  // caller treats that as "couldn't verify" and stays silent rather than
  // wrongly claiming the email is taken.
  Future<Map<String, dynamic>> checkEmailAvailability(String email) async {
    try {
      final response = await _api.get(
        '${AppConstants.checkEmail}?email=${Uri.encodeQueryComponent(email.trim().toLowerCase())}',
      );
      return {'success': true, 'available': response.data['available'] == true};
    } catch (e) {
      return {'success': false, 'available': null};
    }
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      final response = await _api.post(
        AppConstants.forgotPassword,
        {'email': email},
      );
      return {'success': true, 'data': response.data};
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.accessTokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userRoleKey);
    await prefs.remove(AppConstants.userIdKey);
  }

  Future<void> _saveTokens({
    required String access,
    required String refresh,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.accessTokenKey,  access);
    await prefs.setString(AppConstants.refreshTokenKey, refresh);
    await prefs.setString(AppConstants.userRoleKey,     role);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.accessTokenKey) != null;
  }

  Future<String?> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userRoleKey);
  }

  Map<String, dynamic> _handleError(dynamic e) {
    if (e.runtimeType.toString().contains('DioException')) {
      final dioError = e as dynamic;
      final response = dioError.response;
      if (response != null) {
        final int? statusCode = response.statusCode;
        final data = response.data;
        if (data is Map) {
          if (data.containsKey('error')) {
            return {'success': false, 'message': data['error'], 'statusCode': statusCode};
          }
          if (data.containsKey('detail')) {
            return {'success': false, 'message': data['detail'], 'statusCode': statusCode};
          }
          final messages = <String>[];
          data.forEach((key, value) {
            if (value is List)   messages.add(value.first.toString());
            else if (value is String) messages.add(value);
          });
          if (messages.isNotEmpty) {
            return {'success': false, 'message': messages.join('\n'), 'statusCode': statusCode};
          }
        }
        return {'success': false, 'message': 'Something went wrong. Please try again.', 'statusCode': statusCode};
      }
      // No response reached the client at all — either a timeout or no
      // connection. Dio's `type` tells us which, so we can give a more
      // useful message than a blanket "network error".
      final typeName = dioError.type.toString();
      if (typeName.contains('connectionTimeout') ||
          typeName.contains('sendTimeout') ||
          typeName.contains('receiveTimeout')) {
        return {'success': false, 'message': 'Request timed out. Please check your connection and try again.', 'statusCode': null};
      }
      return {'success': false, 'message': 'Network error. Check your connection.', 'statusCode': null};
    }
    return {'success': false, 'message': 'Something went wrong. Please try again.', 'statusCode': null};
  }
}