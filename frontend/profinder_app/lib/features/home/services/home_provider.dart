// lib/features/home/services/home_provider.dart

import 'package:flutter/material.dart';
import 'home_service.dart';

class HomeProvider extends ChangeNotifier {
  final HomeService _homeService = HomeService();

  bool _isLoading = false;
  List<dynamic> _categories = [];
  List<dynamic> _featuredCategories = [];
  List<dynamic> _nearbyProfessionals = [];
  Map<String, dynamic>? _userProfile;
  // Location-fallback info from the last loadHomeData() call:
  Map<String, dynamic> _nearbyMeta = {};

  bool get isLoading => _isLoading;
  List<dynamic> get categories => _categories;
  List<dynamic> get featuredCategories => _featuredCategories;
  List<dynamic> get nearbyProfessionals => _nearbyProfessionals;
  Map<String, dynamic>? get userProfile => _userProfile;
  Map<String, dynamic> get nearbyMeta => _nearbyMeta;

  // Home dashboard's professional sections:
  bool _feedLoading = false;
  List<dynamic> _recommended = [];
  List<dynamic> _nearbyInCity = [];
  List<dynamic> _topRated = [];
  List<dynamic> _trending = [];
  List<dynamic> _recentlyAdded = [];
  List<dynamic> _popularProfessionals = [];
  Map<String, dynamic> _feedNearbyMeta = {};

  bool get feedLoading => _feedLoading;
  List<dynamic> get recommended => _recommended;
  List<dynamic> get nearbyInCity => _nearbyInCity;
  List<dynamic> get topRatedFeed => _topRated;
  List<dynamic> get trendingFeed => _trending;
  List<dynamic> get recentlyAddedFeed => _recentlyAdded;
  List<dynamic> get popularProfessionalsFeed => _popularProfessionals;
  Map<String, dynamic> get feedNearbyMeta => _feedNearbyMeta;

  /// `latitude`/`longitude` are optional live-GPS coordinates.
  Future<void> loadHomeFeed({double? latitude, double? longitude}) async {
    _feedLoading = true;
    notifyListeners();

    final result = await _homeService.getHomeFeed(
      latitude: latitude,
      longitude: longitude,
    );

    _recommended = result['recommended'] as List<dynamic>? ?? [];
    _nearbyInCity = result['nearby'] as List<dynamic>? ?? [];
    _topRated = result['top_rated'] as List<dynamic>? ?? [];
    _trending = result['trending'] as List<dynamic>? ?? [];
    _recentlyAdded = result['recently_added'] as List<dynamic>? ?? [];
    _popularProfessionals =
        result['popular_professionals'] as List<dynamic>? ?? [];
    _feedNearbyMeta = result['meta'] as Map<String, dynamic>? ?? {};

    _feedLoading = false;
    notifyListeners();
  }

  Future<void> loadHomeData({
    double latitude = 0.0,
    double longitude = 0.0,
    int? categoryId,
    String query = '',
    String city = '',
    double minPrice = 0,
    double maxPrice = 999999,
    double minRating = 0,
    bool verifiedOnly = false,
  }) async {
    _setLoading(true);

    final results = await Future.wait([
      _homeService.getCategories(),
      _homeService.getFeaturedCategories(),
      _homeService.getNearbyProfessionals(
        latitude: latitude,
        longitude: longitude,
        categoryId: categoryId,
        query: query,
        city: city,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minRating: minRating,
        verifiedOnly: verifiedOnly,
      ),
      _homeService.getMyProfile(),
    ]);

    _setLoading(false);

    if (results[0]['success']) {
      _categories = results[0]['data'] is List ? results[0]['data'] : [];
    }
    if (results[1]['success']) {
      _featuredCategories = results[1]['data'] is List
          ? results[1]['data']
          : [];
    }
    if (results[2]['success']) {
      _nearbyProfessionals = results[2]['data'] is List
          ? results[2]['data']
          : [];
      _nearbyMeta = results[2]['meta'] is Map<String, dynamic>
          ? results[2]['meta']
          : {};
    }
    if (results[3]['success']) {
      _userProfile = results[3]['data'];
    }

    notifyListeners();
  }

  Future<List<dynamic>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final result = await _homeService.searchProfessionals(query);
    if (result['success'] && result['data'] is List) return result['data'];
    return [];
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
