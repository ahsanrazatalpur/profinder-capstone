// lib/services/location_service_web.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class LocationServiceImpl {
  static double? _cachedLat;
  static double? _cachedLng;

  static Future<({double lat, double lng})?> getCurrentLocation({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedLat != null && _cachedLng != null) {
      return (lat: _cachedLat!, lng: _cachedLng!);
    }
    try {
      final pos = await html.window.navigator.geolocation.getCurrentPosition(
        enableHighAccuracy: false,
        timeout: const Duration(seconds: 8),
        maximumAge: const Duration(minutes: 5),
      );
      _cachedLat = pos.coords!.latitude!.toDouble();
      _cachedLng = pos.coords!.longitude!.toDouble();
      return (lat: _cachedLat!, lng: _cachedLng!);
    } catch (_) {
      return null;
    }
  }
}