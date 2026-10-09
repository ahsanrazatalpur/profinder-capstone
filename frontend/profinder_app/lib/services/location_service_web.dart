// lib/services/location_service_web.dart
import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

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
      final completer = Completer<({double lat, double lng})?>();
      web.window.navigator.geolocation.getCurrentPosition(
        ((web.GeolocationPosition pos) {
          _cachedLat = pos.coords.latitude;
          _cachedLng = pos.coords.longitude;
          if (!completer.isCompleted) {
            completer.complete((lat: _cachedLat!, lng: _cachedLng!));
          }
        }).toJS,
        ((web.GeolocationPositionError _) {
          if (!completer.isCompleted) completer.complete(null);
        }).toJS,
        web.PositionOptions(
          enableHighAccuracy: false,
          timeout: 8000,
          maximumAge: 300000,
        ),
      );
      return await completer.future;
    } catch (_) {
      return null;
    }
  }
}