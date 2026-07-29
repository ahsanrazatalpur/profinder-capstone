// lib/services/location_service.dart
import 'location_service_io.dart'
    if (dart.library.html) 'location_service_web.dart';

class LocationService {
  static Future<({double lat, double lng})?> getCurrentLocation({
    bool forceRefresh = false,
  }) {
    return LocationServiceImpl.getCurrentLocation(forceRefresh: forceRefresh);
  }
}