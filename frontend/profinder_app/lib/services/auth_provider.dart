// lib/services/auth_provider.dart

import 'package:flutter/material.dart';
import 'auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool    _isLoading  = false;
  bool    _isLoggedIn = false;
  bool    _isGuest    = false;
  String? _role;
  String? _errorMessage;
  int?    _errorStatusCode;
  String? _loginPreferredLanguage; // ✅ i18n — preferred_language from the login response (nullable)

  bool    get isLoading    => _isLoading;
  bool    get isLoggedIn   => _isLoggedIn;
  bool    get isGuest      => _isGuest;
  String? get role         => _role;
  String? get errorMessage => _errorMessage;
  int?    get errorStatusCode => _errorStatusCode;
  String? get loginPreferredLanguage => _loginPreferredLanguage; // ✅ i18n

  bool get isCustomer     => _role == 'customer';
  bool get isProfessional => _role == 'professional';
  bool get isAdmin        => _role == 'admin';

  Future<void> checkLoginStatus() async {
    _isLoggedIn = await _authService.isLoggedIn();
    _role       = await _authService.getSavedRole();
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String name,
    required String role,
    required String password,
    String? city,
    String? country,
    int?    categoryId,
  }) async {
    _setLoading(true);
    final result = await _authService.register(
      email:      email,
      name:       name,
      role:       role,
      password:   password,
      city:       city,
      country:    country,
      categoryId: categoryId,
    );
    _setLoading(false);
    if (result['success']) return true;
    _errorMessage = result['message'];
    notifyListeners();
    return false;
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    _errorStatusCode = null;
    final result = await _authService.login(email: email, password: password);
    _setLoading(false);
    if (result['success']) {
      _isLoggedIn = true;
      _isGuest    = false;
      _role       = result['data']['role'];
      _loginPreferredLanguage = result['data']['preferred_language']; // ✅ i18n
      notifyListeners();
      return true;
    }
    _errorMessage = result['message'];
    _errorStatusCode = result['statusCode'] as int?;
    notifyListeners();
    return false;
  }

  Future<bool> forgotPassword({required String email}) async {
    _setLoading(true);
    _errorMessage = null;
    final result = await _authService.forgotPassword(email: email);
    _setLoading(false);
    if (result['success']) return true;
    _errorMessage = result['message'];
    notifyListeners();
    return false;
  }

  void setGuest() {
    _isGuest      = true;
    _isLoggedIn   = false;
    _role         = null;
    _errorMessage = null;
    _errorStatusCode = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _isLoggedIn   = false;
    _isGuest      = false;
    _role         = null;
    _errorMessage = null;
    _errorStatusCode = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}