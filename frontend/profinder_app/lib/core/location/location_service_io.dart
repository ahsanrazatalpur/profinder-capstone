// lib/core/location/location_service_io.dart

class LocationServiceImpl {
  static Future<({double lat, double lng})?> getCurrentLocation({
    bool forceRefresh = false,
  }) async {
    return null; // Mobile does not currently use this location service
  }
}
