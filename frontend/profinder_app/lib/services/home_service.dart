// lib/services/home_service.dart

import 'api_service.dart';
import '../core/constants/app_constants.dart';

class HomeService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await _api.get(AppConstants.categories);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'data': []};
    }
  }

  /// Admin-curated "Featured Categories" (Guest Home) — max 6, never a
  /// random subset. Falls back server-side to popularity-ranked
  /// categories when nothing has been marked featured yet.
  Future<Map<String, dynamic>> getFeaturedCategories() async {
    try {
      final response = await _api.get(AppConstants.featuredCategories);
      final body = response.data as Map<String, dynamic>? ?? {};
      return {
        'success': true,
        'data':    body['categories'] as List? ?? [],
        'source':  body['source']?.toString() ?? '',
      };
    } catch (e) {
      return {'success': false, 'data': [], 'source': ''};
    }
  }

  /// Real-time suggestions while typing.
  /// Returns 4 sections: popular, professions, categories, professionals.
  Future<Map<String, dynamic>> getSuggestions(String query) async {
    try {
      final q   = Uri.encodeComponent(query.trim());
      final url = '${AppConstants.suggest}${q.isNotEmpty ? '?q=$q' : ''}';
      final res = await _api.get(url);
      final body = res.data as Map<String, dynamic>? ?? {};
      return {
        'success':               true,
        'popular_searches':      body['popular_searches']       as List? ?? [],
        'matching_professions':  body['matching_professions']   as List? ?? [],
        'matching_categories':   body['matching_categories']    as List? ?? [],
        'matching_professionals':body['matching_professionals'] as List? ?? [],
      };
    } catch (_) {
      // Never fail silently — return popular fallback
      return {
        'success':               false,
        'popular_searches':      _fallbackPopular,
        'matching_professions':  [],
        'matching_categories':   [],
        'matching_professionals':[],
      };
    }
  }

  static const _fallbackPopular = [
    'Doctor', 'Lawyer', 'Engineer', 'Teacher', 'Plumber', 'Electrician',
  ];

  /// Single call powering ALL home-dashboard professional sections —
  /// Recommended / Nearby / Top Rated / Trending / Recently Added /
  /// Popular Professionals — each with its own independent backend query
  /// (see HomeFeedView). Now
  /// available to guests too (AllowAny) via optional live GPS params, so
  /// guest and authenticated home screens can share this exact same,
  /// correctly-scoped data source instead of guests reusing the
  /// location-narrowed nearby-professionals list for every section.
  Future<Map<String, dynamic>> getHomeFeed({double? latitude, double? longitude}) async {
    try {
      final params = <String, String>{};
      if (latitude != null && longitude != null && (latitude != 0 || longitude != 0)) {
        params['lat'] = latitude.toString();
        params['lng'] = longitude.toString();
      }
      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final url = queryString.isEmpty
          ? AppConstants.homeFeed
          : '${AppConstants.homeFeed}?$queryString';

      final response = await _api.get(url);
      final body = response.data as Map<String, dynamic>? ?? {};
      // Everything in `body` besides these known list keys IS the location
      // meta (results_source, nearest_city, nearest_distance_km,
      // location_label, city_unavailable_message, nearby_cities_section,
      // other_cities_section, search_radius_km) — spread server-side via
      // `**nearby_location_meta`, so we collect it the same way here.
      const listKeys = {
        'recommended', 'nearby', 'top_rated', 'trending', 'recently_added',
        'popular_professionals',
      };
      final meta = <String, dynamic>{
        for (final entry in body.entries)
          if (!listKeys.contains(entry.key)) entry.key: entry.value,
      };
      return {
        'success':               true,
        'recommended':           body['recommended']              as List? ?? [],
        'nearby':                body['nearby']                    as List? ?? [],
        'top_rated':             body['top_rated']                 as List? ?? [],
        'trending':              body['trending']                  as List? ?? [],
        'recently_added':        body['recently_added']            as List? ?? [],
        'popular_professionals': body['popular_professionals']     as List? ?? [],
        'meta':                  meta,
      };
    } catch (e) {
      return {
        'success': false,
        'recommended': [], 'nearby': [], 'top_rated': [], 'trending': [], 'recently_added': [],
        'popular_professionals': [],
        'meta': <String, dynamic>{},
      };
    }
  }

  Future<Map<String, dynamic>> getNearbyProfessionals({
    double latitude     = 0,
    double longitude    = 0,
    int?   categoryId,
    String query        = '',
    String city         = '',
    double minPrice     = 0,
    double maxPrice     = 999999,
    double minRating    = 0,
    bool   verifiedOnly = false,
    String gender        = '',    // '', 'male', 'female', 'other'
    double minExperience = 0,     // years
    bool   availableOnly = false, // urgent / needs-someone-now intent
    String language       = '',   // e.g. 'urdu', 'english'
    double maxDistance    = 0,    // km — 0 means no distance-radius filter
    String serviceMode    = '',   // 'online', 'home_visit', 'in_office'
  }) async {
    try {
      final params = <String, String>{};
      if (latitude != 0 || longitude != 0) {
        params['lat'] = latitude.toString();
        params['lng'] = longitude.toString();
      }
      if (query.isNotEmpty)   params['q']             = query;
      if (city.isNotEmpty)    params['city']          = city;
      if (categoryId != null) params['category_id']   = categoryId.toString();
      if (minPrice > 0)       params['min_price']     = minPrice.toString();
      if (maxPrice < 999999)  params['max_price']     = maxPrice.toString();
      if (minRating > 0)      params['min_rating']    = minRating.toString();
      if (verifiedOnly)       params['verified_only'] = 'true';
      if (gender.isNotEmpty)  params['gender']         = gender;
      if (minExperience > 0)  params['min_experience'] = minExperience.toString();
      if (availableOnly)      params['available_only'] = 'true';
      if (language.isNotEmpty) params['language']      = language;
      if (maxDistance > 0)     params['max_distance']  = maxDistance.toString();
      if (serviceMode.isNotEmpty) params['service_mode'] = serviceMode;

      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final url = queryString.isEmpty
          ? AppConstants.nearby
          : '${AppConstants.nearby}?$queryString';

      final response = await _api.get(url);
      final body     = response.data;

      if (body is Map<String, dynamic> && body.containsKey('results')) {
        return {
          'success': true,
          'data':    body['results'] as List<dynamic>? ?? [],
          'meta':    body['meta']    as Map<String, dynamic>? ?? {},
        };
      }
      if (body is List) return {'success': true, 'data': body, 'meta': <String, dynamic>{}};
      return {'success': true, 'data': [], 'meta': <String, dynamic>{}};
    } catch (e) {
      // 🐛 FIX: this used to be a bare `{}`, which Dart infers as
      // `Map<dynamic, dynamic>` (not `Map<String, dynamic>`) since there's
      // no downward type context here. Every caller does
      // `result['meta'] as Map<String, dynamic>?` on this value — casting
      // a `Map<dynamic, dynamic>` to `Map<String, dynamic>` throws a
      // TypeError at runtime. Since that throw happened AFTER the caller
      // had already set `_isLoading = true` and BEFORE it could reach the
      // `setState(() => _isLoading = false)` at the end, the search screen
      // got stuck showing its loading/shimmer state forever — exactly the
      // "just keeps loading, no response" symptom, triggered by any
      // network hiccup (timeout, no internet, non-200 response, etc.)
      // that lands in this catch block.
      return {'success': false, 'data': [], 'meta': <String, dynamic>{}};
    }
  }

  Future<Map<String, dynamic>> searchProfessionals(
    String query, {
    double? latitude,
    double? longitude,
  }) async {
    return getNearbyProfessionals(
      query:     query,
      latitude:  latitude  ?? 0,
      longitude: longitude ?? 0,
    );
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final results = await Future.wait([
        _api.get(AppConstants.me),
        _api.get(AppConstants.userProfile),
      ]);

      final meData      = results[0].data as Map<String, dynamic>? ?? {};
      final profileData = results[1].data as Map<String, dynamic>? ?? {};

      final merged = {
        ...meData,
        ...profileData,
        'name': (profileData['full_name'] as String?)?.isNotEmpty == true
            ? profileData['full_name']
            : (meData['name'] ?? ''),
        'photo_url': profileData['photo_url'],
      };

      return {'success': true, 'data': merged};
    } catch (e) {
      return {'success': false, 'message': 'Not logged in'};
    }
  }
}