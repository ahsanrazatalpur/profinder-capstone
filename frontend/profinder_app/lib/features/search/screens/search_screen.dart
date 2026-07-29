// lib/features/search/screens/search_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../services/home_service.dart';
import '../../../services/location_service.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../subscription/widgets/ai_limit_dialog.dart';
import '../../subscription/services/subscription_service.dart';
import 'professional_detail_screen.dart';
import '../../subscription/widgets/promo_banner_mixin.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/utils/category_icons.dart';
import '../../../l10n/generated/app_localizations.dart';

class SearchScreen extends StatefulWidget {
  final bool   isLoggedIn;
  final String userRole;
  final bool   isPremium;
  final int?   initialCategoryId;
  final String? initialCategoryName;
  final String? initialQuery;

  // ✅ FIX: when SearchScreen is embedded as a bottom-nav TAB (e.g. inside
  // GuestMainScreen's IndexedStack) there's no pushed route to pop, so the
  // back arrow has nothing to do by default. Callers that embed this
  // screen as a tab can pass a callback here (e.g. "switch to Home tab")
  // so the arrow still does something useful instead of being a dead
  // button. Callers that push SearchScreen as its own route (e.g.
  // CustomerHomeScreen) can leave this null — Navigator.pop() handles it.
  final VoidCallback? onBackWhenEmbedded;

  const SearchScreen({
    super.key,
    this.isLoggedIn          = false,
    this.userRole            = 'guest',
    this.isPremium           = false,
    this.initialCategoryId   = null,
    this.initialCategoryName = null,
    this.initialQuery        = null,
    this.onBackWhenEmbedded  = null,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with PromoBannerMixin {
  final _controller = TextEditingController();
  final _focus      = FocusNode();
  final _service    = HomeService();
  final _api        = ApiService();
  final _auth       = AuthService();
  final _subService = SubscriptionService();

  bool   _isLoggedIn   = false;
  String _userRole     = 'guest';
  bool   _isPremium    = false;
  bool   _statusLoaded = false;

  List<dynamic> _results      = [];
  List<dynamic> _categories   = [];
  bool          _isLoading    = false;
  bool          _hasSearched  = false;
  String        _lastQuery    = '';
  String        _sortBy       = 'none';
  bool          _aiMode       = false;
  String?       _aiResult;
  List<dynamic> _aiMatchedPros = [];
  String? _aiAvailabilityMessage;
  Map<String, dynamic> _aiRecommendations = {};
  int           _aiUsed       = 0;
  int           _aiLimit      = 5;

  final List<String> _searchHistory = [];

  // ── Race-condition guard ─────────────────────────────────────────────────
  // Incremented on every new _search()/_aiSearch() call. Each call captures
  // its own id and only applies setState() if it's still the latest request
  // by the time the response arrives — otherwise a slow, stale response
  // (e.g. from a query the user has already changed/replaced) can never
  // overwrite fresher results.
  int _searchRequestId = 0;

  // ── Auto-suggest state ────────────────────────────────────────────────
  Timer?         _debounce;
  bool           _showSuggestions   = false;
  List<String>   _suggestPopular    = [];
  List<String>   _suggestProfessions= [];
  List<dynamic>  _suggestCategories = [];
  List<dynamic>  _suggestPros       = [];

  double _minPrice     = 0;
  double _maxPrice     = 1000;
  double _minRating    = 0;
  bool   _verifiedOnly = false;
  String _cityFilter   = '';
  String _genderFilter    = '';    // '', 'male', 'female'
  double _minExperience   = 0;     // years
  bool   _availableOnly   = false; // "need someone urgent/now"
  String _languageFilter  = '';
  double _maxDistance     = 0;     // km — 0 means no distance-radius filter
  String _serviceModeFilter = '';  // '', 'online', 'home_visit', 'in_office'

  double? _userLat;
  double? _userLng;
  bool    _locationLoading = true;

  bool   _isFallback        = false;
  String _fallbackMessage   = '';
  bool   _spellingCorrected = false;
  String _correctedQuery    = '';

  // ── Intelligent location priority (new) ────────────────────────────────
  String? _cityUnavailableMessage;   // "No Cardiologists found in Karachi."
  String? _citySectionLabel;         // "Available in Nearby Cities" / "...Other Cities"

  // ── Empty state fallback data — from backend when results == 0 ────────
  List<dynamic> _emptySimilar   = [];
  List<dynamic> _emptyNearby    = [];
  List<dynamic> _emptyPopular   = [];
  List<dynamic> _emptyTrending  = [];

  static const int _historyLimit = 10;
  static const String _historyPrefsKey = 'normal_search_recent_history';

  final List<Map<String, dynamic>> _popularSearches = [
    {'label': 'Doctors',      'icon': Icons.medical_services_outlined},
    {'label': 'Lawyers',      'icon': Icons.gavel_outlined},
    {'label': 'Engineers',    'icon': Icons.engineering_outlined},
    {'label': 'Plumbers',     'icon': Icons.plumbing_outlined},
    {'label': 'Electricians', 'icon': Icons.electrical_services},
    {'label': 'Cleaners',     'icon': Icons.cleaning_services},
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadAuthStatus();
    _loadUserLocation();
    _loadSearchHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
      showBannerForScreen('search');
      if (widget.initialCategoryId != null && widget.initialCategoryName != null) {
        _searchByCategory(widget.initialCategoryName!, widget.initialCategoryId);
      } else if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
        _controller.text = widget.initialQuery!;
        _search(widget.initialQuery!);
      }
    });
  }

  Future<void> _loadUserLocation() async {
    setState(() => _locationLoading = true);
    final location = await LocationService.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _locationLoading = false;
      if (location != null) {
        _userLat = location.lat;
        _userLng = location.lng;
      }
    });
    if (location != null && _hasSearched && _results.isNotEmpty) {
      _search(_lastQuery);
    }
  }

  Future<void> _loadAuthStatus() async {
    final loggedIn = await _auth.isLoggedIn();
    String role = await _auth.getSavedRole() ?? 'guest';
    bool premium = false;
    if (loggedIn) {
      final plan = await _subService.getMyPlan();
      if (plan != null) premium = plan.isPremium;
    }
    if (!mounted) return;
    setState(() {
      _isLoggedIn   = loggedIn;
      _userRole     = role;
      _isPremium    = premium;
      _statusLoaded = true;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final result = await _service.getCategories();
    if (result['success'] && mounted) {
      setState(() => _categories = result['data'] ?? []);
    }
  }

  // ── Recent Searches persistence ──────────────────────────────────────────
  // Stored on-device (SharedPreferences) so it survives screen navigation
  // and app restarts — works for guests too since it never touches the server.
  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_historyPrefsKey);
      if (raw == null || raw.isEmpty) return;
      final List<dynamic> decoded = jsonDecode(raw);
      if (!mounted) return;
      setState(() {
        _searchHistory
          ..clear()
          ..addAll(decoded.map((e) => e.toString()));
      });
    } catch (_) {
      // Corrupt/missing cache — start with empty history, non-fatal.
    }
  }

  Future<void> _saveSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_historyPrefsKey, jsonEncode(_searchHistory));
    } catch (_) {
      // Persistence failure shouldn't break search UX.
    }
  }

  // ── Suggestion loader — debounced 280ms ──────────────────────────────────
  void _onTyping(String value) {
    _debounce?.cancel();

    if (value.isEmpty) {
      setState(() {
        _showSuggestions = false;
        _hasSearched     = false;
        _results         = [];
        _aiResult        = null;
        _aiAvailabilityMessage = null; _aiRecommendations = {};
        _aiMatchedPros   = [];
      });
      return;
    }

    // Show loading state immediately while debounce waits
    setState(() => _showSuggestions = true);

    _debounce = Timer(const Duration(milliseconds: 280), () async {
      final data = await _service.getSuggestions(value);
      if (!mounted) return;
      setState(() {
        _suggestPopular     = List<String>.from(data['popular_searches']    ?? []);
        _suggestProfessions = List<String>.from(data['matching_professions'] ?? []);
        _suggestCategories  = List<dynamic>.from(data['matching_categories']  ?? []);
        _suggestPros        = List<dynamic>.from(data['matching_professionals'] ?? []);
        _showSuggestions    = true;
      });
    });
  }

  void _hideSuggestions() {
    setState(() => _showSuggestions = false);
  }

  // Tap on a suggestion chip/item — fill box and search
  void _selectSuggestion(String query) {
    _controller.text = query;
    _controller.selection = TextSelection.collapsed(offset: query.length);
    _hideSuggestions();
    _search(query);
  }

  void _addToHistory(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      _searchHistory.remove(query);
      _searchHistory.insert(0, query);
      if (_searchHistory.length > _historyLimit) {
        _searchHistory.removeRange(_historyLimit, _searchHistory.length);
      }
    });
    _saveSearchHistory();
  }

  Future<void> _search(String query) async {
    query = query.trim();
    if (query.isEmpty) return;
    _debounce?.cancel();          // kill any pending suggestion-fetch timer
    _showSuggestions = false;     // make sure it can't flip back on mid-search
    if (_aiMode) { await _aiSearch(query); return; }

    // Claim this request's slot — any older in-flight request becomes stale
    // the moment a newer one starts, even before this one's response returns.
    final int requestId = ++_searchRequestId;

    _addToHistory(query);
    _focus.unfocus();
    setState(() {
      _isLoading   = true;
      _hasSearched = true;
      _lastQuery   = query;
      _aiResult    = null;
      _aiAvailabilityMessage = null; _aiRecommendations = {};
      _aiMatchedPros = [];
    });

    // 🐛 FIX: this whole block used to have no try/catch. If anything
    // between here and the final `setState` threw (a network timeout, a
    // dropped connection, or an unexpected response shape), `_isLoading`
    // was NEVER reset back to false — the screen stayed stuck on the
    // loading shimmer forever with no error shown, which is exactly the
    // "just keeps loading, no results, no response" bug. `_aiSearch()`
    // already guarded against this; `_search()` didn't.
    try {
      final result = await _service.getNearbyProfessionals(
        latitude:      _userLat  ?? 0,
        longitude:     _userLng  ?? 0,
        query:         query,
        city:          _cityFilter,
        minPrice:      _minPrice,
        maxPrice:      _maxPrice,
        minRating:     _minRating,
        verifiedOnly:  _verifiedOnly,
        gender:        _genderFilter,
        minExperience: _minExperience,
        availableOnly: _availableOnly,
        language:      _languageFilter,
        maxDistance:   _maxDistance,
        serviceMode:   _serviceModeFilter,
      );

      // Stale response guard: if a newer search started while this one was
      // in flight, drop this result silently — never let an older response
      // overwrite what the newer (still-loading or already-arrived) one shows.
      if (!mounted || requestId != _searchRequestId) return;

      final List<dynamic> list = result['data'] is List ? result['data'] : [];
      final meta = result['meta'] as Map<String, dynamic>? ?? {};
      setState(() {
        _isLoading         = false;
        _isFallback        = meta['is_fallback'] == true;
        _fallbackMessage   = meta['fallback_message'] as String? ?? '';
        _spellingCorrected = meta['spelling_corrected'] == true;
        _correctedQuery    = meta['corrected_query'] as String? ?? '';
        _cityUnavailableMessage = meta['city_unavailable_message'] as String?;
        _citySectionLabel  = (meta['nearby_cities_section'] ?? meta['other_cities_section']) as String?;
        _results           = _sortResults(list);
        // Empty state fallback sections
        _emptySimilar  = List<dynamic>.from(meta['similar_professionals']  ?? []);
        _emptyNearby   = List<dynamic>.from(meta['nearby_professionals']   ?? []);
        _emptyPopular  = List<dynamic>.from(meta['popular_professionals']  ?? []);
        _emptyTrending = List<dynamic>.from(meta['trending_categories']    ?? []);
      });
    } catch (e) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _isLoading = false;
        _results   = [];
      });
      AppHelpers.showError(context, AppLocalizations.of(context)!.searchFailedCheckConnection);
    }
  }

  Future<void> _aiSearch(String query) async {
    if (!_isLoggedIn) { _showLoginPrompt(); return; }

    // Claim this request's slot — see _search() for why this matters.
    final int requestId = ++_searchRequestId;

    _addToHistory(query);
    _focus.unfocus();
    setState(() {
      _isLoading     = true;
      _hasSearched   = true;
      _lastQuery     = query;
      _aiResult      = null;
      _aiAvailabilityMessage = null; _aiRecommendations = {};
      _aiMatchedPros = [];
    });

    try {
      final res  = await _api.post(AppConstants.aiSearch, {
        'query': query,
        if (_userLat != null) 'latitude':  _userLat,
        if (_userLng != null) 'longitude': _userLng,
      });
      if (!mounted || requestId != _searchRequestId) return;
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _isLoading     = false;
        _aiResult      = data['ai_result'];
        _aiMatchedPros = data['matched_professionals'] as List<dynamic>? ?? [];
        _aiUsed        = data['searches_used']  ?? _aiUsed + 1;
        _aiLimit       = data['searches_limit'] ?? _aiLimit;
        _aiAvailabilityMessage = data['availability_fallback_message'] as String?;
        _aiRecommendations = data['recommendations'] as Map<String, dynamic>? ?? {};
        _results       = [];
      });
    } catch (e) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() => _isLoading = false);
      final statusCode = (e as dynamic).response?.statusCode;
      if (statusCode == 429) {
        final data  = (e as dynamic).response?.data as Map<String, dynamic>? ?? {};
        final used  = data['searches_used']  ?? _aiLimit;
        final limit = data['searches_limit'] ?? _aiLimit;
        AiLimitDialog.show(context, used: used, limit: limit, userRole: _userRole);
        setState(() => _aiMode = false);
        return;
      }
      if (statusCode == 401) { _showLoginPrompt(); return; }
      AppHelpers.showError(context, AppLocalizations.of(context)!.searchAiSearchFailedTryNormal);
    }
  }

  void _showLoginPrompt() {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(t.searchLoginRequired),
        content: Text(t.searchPleaseLoginUseAiSearch),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.pushNamed(context, '/login'); },
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 20)),
            child: Text(t.login),
          ),
        ],
      ),
    );
  }

  Future<void> _searchByCategory(String name, int? id) async {
    // Claim this request's slot — same guard as _search()/_aiSearch(), since
    // category taps can also fire in quick succession (double-tap, etc).
    final int requestId = ++_searchRequestId;

    _controller.text = name;
    _addToHistory(name);
    _focus.unfocus();
    setState(() {
      _isLoading     = true;
      _hasSearched   = true;
      _lastQuery     = name;
      _aiResult      = null;
      _aiAvailabilityMessage = null; _aiRecommendations = {};
      _aiMatchedPros = [];
    });

    // 🐛 FIX: same missing try/catch as `_search()` above. This is the
    // function that actually runs when a category chip/card is tapped on
    // the Guest Home dashboard ("Popular"/"Featured"/the top horizontal
    // category row all call this via `_openSearch()`), so this was the
    // direct cause of "tap a category → navigates to Search → stuck
    // loading forever, no results". Any hiccup here (slow/failed network
    // call, the `Map<String,dynamic>` cast fixed in home_service.dart,
    // etc.) previously left `_isLoading` stuck at `true` with nothing
    // shown to the user.
    try {
      final result = await _service.getNearbyProfessionals(
        categoryId: id,
        latitude:   _userLat ?? 0,
        longitude:  _userLng ?? 0,
      );
      if (!mounted || requestId != _searchRequestId) return;

      final List<dynamic> list = result['data'] is List ? result['data'] : [];
      final meta = result['meta'] as Map<String, dynamic>? ?? {};
      setState(() {
        _isLoading         = false;
        _isFallback        = meta['is_fallback'] == true;
        _fallbackMessage   = meta['fallback_message'] as String? ?? '';
        _cityUnavailableMessage = meta['city_unavailable_message'] as String?;
        _citySectionLabel  = (meta['nearby_cities_section'] ?? meta['other_cities_section']) as String?;
        _spellingCorrected = false;  // category search — no typo correction
        _correctedQuery    = '';
        _results           = _sortResults(list);
      });
    } catch (e) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _isLoading = false;
        _results   = [];
      });
      AppHelpers.showError(context, AppLocalizations.of(context)!.searchFailedCheckConnection);
    }
  }

  List<dynamic> _sortResults(List<dynamic> list) {
    final sorted = List<dynamic>.from(list);
    switch (_sortBy) {
      case 'price_asc':
        sorted.sort((a, b) => (a['hourly_rate'] ?? 0).compareTo(b['hourly_rate'] ?? 0));
        break;
      case 'price_desc':
        sorted.sort((a, b) => (b['hourly_rate'] ?? 0).compareTo(a['hourly_rate'] ?? 0));
        break;
      case 'rating_desc':
        sorted.sort((a, b) => (b['average_rating'] ?? 0).compareTo(a['average_rating'] ?? 0));
        break;
    }
    return sorted;
  }

  void _applySort(String value) {
    setState(() { _sortBy = value; _results = _sortResults(_results); });
  }

  void _toggleAiMode() {
    if (!_isLoggedIn) { _showLoginPrompt(); return; }
    setState(() { _aiMode = !_aiMode; _aiResult = null; _aiMatchedPros = []; _aiAvailabilityMessage = null; _aiRecommendations = {}; });
    if (_aiMode) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(_isPremium ? 'AI Search ON — Premium mode active'
              : 'AI Search ON — ${_aiLimit - _aiUsed} searches remaining today'),
        ]),
        backgroundColor: context.colors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ));
      showBannerForScreen('ai_search', delaySeconds: 1);
    }
  }

  void _showAllHistory() {
    final t = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context, backgroundColor: context.colors.surface, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      builder: (_) => SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 36, height: 4, decoration: BoxDecoration(color: context.colors.divider, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(t.searchSearchHistory, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
            GestureDetector(
              onTap: () { setState(() => _searchHistory.clear()); _saveSearchHistory(); Navigator.pop(context); },
              child: Text(t.searchClearAll, style: const TextStyle(fontSize: 13, color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        // Flexible (not shrinkWrap) — the sheet's own `constraints:
        // maxHeight` above bounds this, and a long history list scrolls
        // internally within that bound instead of trying to lay out every
        // item's full height (which is what previously risked a bottom
        // overflow on a long history).
        Flexible(child: _searchHistory.isEmpty
          ? Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text(t.searchNoSearchHistoryYet, style: TextStyle(fontSize: 14, color: context.colors.textSecondary))),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _searchHistory.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final query = _searchHistory[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.history_rounded, color: context.colors.textSecondary, size: 18),
                  title: Text(query, style: TextStyle(fontSize: 14, color: context.colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: GestureDetector(
                    onTap: () => setState(() { _searchHistory.remove(query); _saveSearchHistory(); }),
                    child: Icon(Icons.close, size: 16, color: context.colors.textSecondary),
                  ),
                  onTap: () { Navigator.pop(context); _controller.text = query; _search(query); },
                );
              },
            )),
        ]),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      // Caps the sheet at 90% of screen height so it never tries to grow
      // past the viewport — combined with the SingleChildScrollView below,
      // this is what actually prevents the bottom overflow: this filter
      // list (2 text fields, 3 sliders, 2 switches, 2 chip groups, 2
      // buttons) is taller than many small-phone screens on its own,
      // before the keyboard even opens.
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final t = AppLocalizations.of(ctx)!;
          final scale = ResponsiveUtils.scaleOf(ctx);
          final hPad = ResponsiveUtils.screenPadding(MediaQuery.sizeOf(ctx).width, base: 20);
          final labelStyle = TextStyle(fontSize: ResponsiveUtils.sp(14, scale, min: 13, max: 17), fontWeight: FontWeight.w600, color: context.colors.textPrimary);
          final valueStyle = TextStyle(fontSize: ResponsiveUtils.sp(13, scale, min: 12, max: 16), fontWeight: FontWeight.w600, color: context.colors.textPrimary);
          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(left: hPad, right: hPad, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: context.colors.divider, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text(t.city, style: labelStyle),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _cityFilter, style: ctx.textStyles.inputText,
                  decoration: InputDecoration(hintText: t.searchEGKarachiLahore, prefixIcon: const Icon(Icons.location_city_outlined)),
                  onChanged: (v) => _cityFilter = v,
                ),
                const SizedBox(height: 16),
                Text(t.searchPriceHr('${_minPrice.toInt()}', '${_maxPrice.toInt()}'), style: valueStyle),
                RangeSlider(
                  values: RangeValues(_minPrice, _maxPrice), min: 0, max: 1000, divisions: 20,
                  activeColor: context.colors.primary,
                  onChanged: (v) => setSheet(() { _minPrice = v.start; _maxPrice = v.end; }),
                ),
                Text(t.searchMinRating(_minRating.toStringAsFixed(1)), style: valueStyle),
                Slider(value: _minRating, min: 0, max: 5, divisions: 10, activeColor: context.colors.primary,
                    onChanged: (v) => setSheet(() => _minRating = v)),
                SwitchListTile(
                  title: Text(t.searchVerifiedOnly, style: TextStyle(fontSize: ResponsiveUtils.sp(14, scale, min: 13, max: 17))),
                  value: _verifiedOnly,
                  activeColor: context.colors.primary, contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setSheet(() => _verifiedOnly = v),
                ),
                const SizedBox(height: 8),
                Text(t.searchPreferredGender, style: labelStyle),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  ChoiceChip(
                    label: Text(t.searchAny), selected: _genderFilter.isEmpty,
                    selectedColor: context.colors.primary.withOpacity(0.15),
                    onSelected: (_) => setSheet(() => _genderFilter = ''),
                  ),
                  ChoiceChip(
                    label: Text(t.searchFemale), selected: _genderFilter == 'female',
                    selectedColor: context.colors.primary.withOpacity(0.15),
                    onSelected: (_) => setSheet(() => _genderFilter = 'female'),
                  ),
                  ChoiceChip(
                    label: Text(t.searchMale), selected: _genderFilter == 'male',
                    selectedColor: context.colors.primary.withOpacity(0.15),
                    onSelected: (_) => setSheet(() => _genderFilter = 'male'),
                  ),
                ]),
                const SizedBox(height: 16),
                Text(t.searchMinExperienceYrs('${_minExperience.toInt()}'), style: valueStyle),
                Slider(value: _minExperience, min: 0, max: 15, divisions: 15, activeColor: context.colors.primary,
                    onChanged: (v) => setSheet(() => _minExperience = v)),
                const SizedBox(height: 8),
                Text(t.searchPreferredLanguage, style: labelStyle),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _languageFilter, style: ctx.textStyles.inputText,
                  decoration: InputDecoration(hintText: t.searchEGUrduEnglish, prefixIcon: const Icon(Icons.language_outlined)),
                  onChanged: (v) => _languageFilter = v,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: Text(t.searchNeedSomeoneNowUrgent, style: TextStyle(fontSize: ResponsiveUtils.sp(14, scale, min: 13, max: 17))),
                  value: _availableOnly,
                  activeColor: context.colors.primary, contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setSheet(() => _availableOnly = v),
                ),
                const SizedBox(height: 8),
                Text(
                  _maxDistance == 0
                      ? t.searchDistanceAny
                      : t.searchWithinKm('${_maxDistance.toInt()}'),
                  style: valueStyle,
                ),
                Slider(
                  value: _maxDistance, min: 0, max: 100, divisions: 20,
                  activeColor: context.colors.primary,
                  label: _maxDistance == 0 ? t.searchAny : t.searchKm('${_maxDistance.toInt()}'),
                  onChanged: (v) => setSheet(() => _maxDistance = v),
                ),
                const SizedBox(height: 8),
                Text(t.searchServiceMode, style: labelStyle),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  ChoiceChip(
                    label: Text(t.searchAny), selected: _serviceModeFilter.isEmpty,
                    selectedColor: context.colors.primary.withOpacity(0.15),
                    onSelected: (_) => setSheet(() => _serviceModeFilter = ''),
                  ),
                  ChoiceChip(
                    label: Text(t.searchOnline), selected: _serviceModeFilter == 'online',
                    selectedColor: context.colors.primary.withOpacity(0.15),
                    onSelected: (_) => setSheet(() => _serviceModeFilter = 'online'),
                  ),
                  ChoiceChip(
                    label: Text(t.searchHomeVisit), selected: _serviceModeFilter == 'home_visit',
                    selectedColor: context.colors.primary.withOpacity(0.15),
                    onSelected: (_) => setSheet(() => _serviceModeFilter = 'home_visit'),
                  ),
                  ChoiceChip(
                    label: Text(t.searchInOffice), selected: _serviceModeFilter == 'in_office',
                    selectedColor: context.colors.primary.withOpacity(0.15),
                    onSelected: (_) => setSheet(() => _serviceModeFilter = 'in_office'),
                  ),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: Size(0, ResponsiveUtils.sp(44, scale, min: 42, max: 54))),
                    onPressed: () => setSheet(() {
                      _minPrice = 0; _maxPrice = 1000; _minRating = 0; _verifiedOnly = false; _cityFilter = '';
                      _genderFilter = ''; _minExperience = 0; _availableOnly = false; _languageFilter = '';
                      _maxDistance = 0; _serviceModeFilter = '';
                    }),
                    child: Text(t.searchReset),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: Size(0, ResponsiveUtils.sp(44, scale, min: 42, max: 54))),
                    onPressed: () { Navigator.pop(context); if (_hasSearched) _search(_lastQuery); },
                    child: Text(t.searchApply),
                  )),
                ]),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _sortBtn(String label, String value, IconData icon) {
    final isActive = _sortBy == value;
    final scale = ResponsiveUtils.scaleOf(context);
    return GestureDetector(
      onTap: () => _applySort(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.sp(12, scale, min: 11, max: 16),
            vertical: ResponsiveUtils.sp(7, scale, min: 6, max: 10)),
        decoration: BoxDecoration(
          color: isActive ? context.colors.primary : context.colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? context.colors.primary : context.colors.divider, width: 1.5),
          boxShadow: isActive ? [BoxShadow(color: context.colors.primary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))] : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: ResponsiveUtils.sp(13, scale, min: 12, max: 16), color: isActive ? Colors.white : context.colors.textSecondary),
          SizedBox(width: ResponsiveUtils.sp(4, scale, min: 3, max: 6)),
          Text(label, style: TextStyle(fontSize: ResponsiveUtils.sp(12, scale, min: 11, max: 15), fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : context.colors.textPrimary)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = ResponsiveUtils.scaleForWidth(width);
    final hPad = ResponsiveUtils.screenPadding(width, base: 16);
    final barHeight = ResponsiveUtils.sp(44, scale, min: 42, max: 54);
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(children: [
          // ── Search Bar ─────────────────────────────────────────────
          Container(
            color: context.colors.surface,
            padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
            child: Column(children: [
              Row(children: [
                GestureDetector(
                  // ✅ FIX: pop when there's a real route to pop (SearchScreen
                  // pushed standalone); otherwise fall back to the caller's
                  // onBackWhenEmbedded callback (e.g. switch to Home tab)
                  // when embedded as a bottom-nav tab. Never blindly calls
                  // Navigator.pop() — that was popping the app's root route
                  // and causing a white screen for the Guest Search tab.
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      widget.onBackWhenEmbedded?.call();
                    }
                  },
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: ResponsiveUtils.sp(20, scale, min: 18, max: 24), color: context.colors.textPrimary),
                ),
                SizedBox(width: ResponsiveUtils.sp(10, scale, min: 8, max: 14)),
                Expanded(
                  child: Container(
                    height: barHeight,
                    constraints: BoxConstraints(maxWidth: width > 700 ? 620 : double.infinity),
                    decoration: BoxDecoration(color: context.colors.divider, borderRadius: BorderRadius.circular(12)),
                    child: TextField(
                      controller: _controller, focusNode: _focus,
                      style: context.textStyles.inputText.copyWith(fontSize: ResponsiveUtils.sp(15, scale, min: 14, max: 18)),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (v) { _hideSuggestions(); _search(v); },
                      onChanged:   _onTyping,
                      decoration: InputDecoration(
                        hintText: _aiMode ? AppLocalizations.of(context)!.searchAiHintPlaceholder : AppLocalizations.of(context)!.searchNameCityProfessionHint,
                        hintStyle: TextStyle(fontSize: ResponsiveUtils.sp(14, scale, min: 13, max: 17), color: context.colors.textSecondary),
                        prefixIcon: Icon(_aiMode ? Icons.auto_awesome : Icons.search,
                            color: _aiMode ? context.colors.primary : context.colors.textSecondary, size: ResponsiveUtils.sp(20, scale, min: 18, max: 24)),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close, size: ResponsiveUtils.sp(16, scale, min: 15, max: 20), color: context.colors.textSecondary),
                                onPressed: () { _controller.clear(); setState(() { _hasSearched = false; _results = []; _aiResult = null; _aiMatchedPros = []; _aiAvailabilityMessage = null; _aiRecommendations = {}; }); })
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.sp(8, scale, min: 6, max: 12)),
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    height: barHeight, width: barHeight,
                    decoration: BoxDecoration(color: context.colors.primary, borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.tune_rounded, color: Colors.white, size: ResponsiveUtils.sp(20, scale, min: 18, max: 24)),
                  ),
                ),
              ]),
              SizedBox(height: ResponsiveUtils.sp(8, scale, min: 6, max: 12)),
              // ── AI Toggle ───────────────────────────────────────
              GestureDetector(
                onTap: _toggleAiMode,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.sp(14, scale, min: 12, max: 18),
                      vertical: ResponsiveUtils.sp(8, scale, min: 7, max: 11)),
                  decoration: BoxDecoration(
                    gradient: _aiMode ? const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]) : null,
                    color: _aiMode ? null : context.colors.divider,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _aiMode ? Colors.transparent : context.colors.divider),
                  ),
                  child: Row(children: [
                    Icon(Icons.auto_awesome, size: ResponsiveUtils.sp(16, scale, min: 15, max: 20), color: _aiMode ? Colors.white : context.colors.primary),
                    SizedBox(width: ResponsiveUtils.sp(8, scale, min: 6, max: 12)),
                    Expanded(child: Text(
                      _aiMode ? AppLocalizations.of(context)!.searchAiSearchOnTapDisable : AppLocalizations.of(context)!.searchTryAiSearchSmarterResults,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: ResponsiveUtils.sp(13, scale, min: 12, max: 16), fontWeight: FontWeight.w600,
                          color: _aiMode ? Colors.white : context.colors.primary),
                    )),
                    if (!_aiMode && _isLoggedIn)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: context.colors.primaryLight, borderRadius: BorderRadius.circular(8)),
                        child: Text(_isPremium ? '20/day' : AppLocalizations.of(context)!.searchAiSearchesLeft('${_aiLimit - _aiUsed}'),
                            style: TextStyle(fontSize: ResponsiveUtils.sp(11, scale, min: 10, max: 14), fontWeight: FontWeight.bold, color: context.colors.primary)),
                      ),
                    if (!_isLoggedIn)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: context.colors.primaryLight, borderRadius: BorderRadius.circular(8)),
                        child: Text(AppLocalizations.of(context)!.login, style: TextStyle(fontSize: ResponsiveUtils.sp(11, scale, min: 10, max: 14), fontWeight: FontWeight.bold, color: context.colors.primary)),
                      ),
                    if (_aiMode) Icon(Icons.close, color: Colors.white, size: ResponsiveUtils.sp(16, scale, min: 15, max: 20)),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
            ]),
          ),

          // ── Sort Row ───────────────────────────────────────────────
          if (_hasSearched && _results.isNotEmpty)
            Container(
              color: context.colors.surface,
              padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _sortBtn(AppLocalizations.of(context)!.homeNearbyLabel, 'none', Icons.near_me_rounded),
                  const SizedBox(width: 6),
                  _sortBtn(AppLocalizations.of(context)!.searchSortPriceLowHigh, 'price_asc', Icons.arrow_upward_rounded),
                  const SizedBox(width: 6),
                  _sortBtn(AppLocalizations.of(context)!.searchSortPriceHighLow, 'price_desc', Icons.arrow_downward_rounded),
                  const SizedBox(width: 6),
                  _sortBtn(AppLocalizations.of(context)!.homeTopRatedLabel, 'rating_desc', Icons.star_rounded),
                ]),
              ),
            ),

          Expanded(
            child: _isLoading
                ? (_aiMode ? _buildAiTypingIndicator() : _buildShimmer())
                : _showSuggestions
                    ? _buildSuggestionPanel()
                    : _hasSearched
                        ? (_aiResult != null ? _buildAiResult() : _buildResults())
                        : _buildDiscover(),
          ),
        ]),
      ),
    );
  }

  // ── Rich Empty State ──────────────────────────────────────────────────────
  // Jab koi result na mile — blank page ki jagah 4 helpful sections dikhata hai
  Widget _buildEmptyState() {
    final t = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.colors.divider),
          ),
          child: Column(children: [
            Icon(Icons.search_off_rounded, size: 44, color: context.colors.textDisabled),
            const SizedBox(height: 10),
            Text(t.searchNoResults(_lastQuery),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15,
                    fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
            const SizedBox(height: 4),
            Text(t.searchHereSomeAlternativesMightLike,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
          ]),
        ),
        const SizedBox(height: 20),

        // ── 1. Similar Professionals ──────────────────────────────────
        if (_emptySimilar.isNotEmpty) ...[
          _emptySection(t.searchSimilarProfessionals, Icons.people_outline_rounded,
              context.colors.primary),
          const SizedBox(height: 8),
          ..._emptySimilar.map((p) => _buildResultCard(p)),
          const SizedBox(height: 16),
        ],

        // ── 2. Nearby Professionals ───────────────────────────────────
        if (_emptyNearby.isNotEmpty) ...[
          _emptySection(t.searchProfessionalsNearYou,
              Icons.near_me_rounded, const Color(0xFF059669)),
          const SizedBox(height: 8),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _emptyNearby.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) => _buildNearbyCard(_emptyNearby[i]),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── 3. Popular Professionals ──────────────────────────────────
        if (_emptyPopular.isNotEmpty) ...[
          _emptySection(t.homeTopRatedProfessionals,
              Icons.star_rounded, const Color(0xFFF59E0B)),
          const SizedBox(height: 8),
          ..._emptyPopular.take(3).map((p) => _buildResultCard(p)),
          const SizedBox(height: 16),
        ],

        // ── 4. Trending Categories ────────────────────────────────────
        if (_emptyTrending.isNotEmpty) ...[
          _emptySection(t.searchTrendingCategories,
              Icons.trending_up_rounded, const Color(0xFF8B5CF6)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8,
            children: _emptyTrending.map((cat) {
              return GestureDetector(
                onTap: () => _searchByCategory(
                    cat['name'] as String, cat['id'] as int?),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.colors.divider,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.colors.divider),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(getCategoryIcon(cat['name'] as String? ?? ''),
                        size: 13, color: context.colors.textSecondary),
                    const SizedBox(width: 5),
                    Text(cat['name'] as String? ?? '',
                        style: TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.colors.textPrimary)),
                    if ((cat['pro_count'] ?? 0) > 0) ...[
                      const SizedBox(width: 5),
                      Text('(${cat['pro_count']})',
                          style: TextStyle(
                              fontSize: 10, color: context.colors.textSecondary)),
                    ],
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // Clear search button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              _controller.clear();
              setState(() {
                _hasSearched  = false;
                _results      = [];
                _emptySimilar = _emptyNearby = _emptyPopular = _emptyTrending = [];
              });
            },
            icon:  const Icon(Icons.close, size: 16),
            label: Text(t.searchClearSearch),
          ),
        ),
      ]),
    );
  }

  Widget _emptySection(String title, IconData icon, Color color) {
    return Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 6),
      Text(title, style: TextStyle(fontSize: 14,
          fontWeight: FontWeight.w700, color: color)),
    ]);
  }

  // Horizontal card for nearby section
  Widget _buildNearbyCard(dynamic pro) {
    final name      = pro['name']           ?? '';
    final category  = pro['category_name']  ?? '';
    final rating    = (pro['average_rating'] ?? 0.0).toDouble();
    final photo     = pro['photo_url'];
    final distKm    = pro['distance_km'];
    final verified  = pro['is_verified'] ?? false;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => ProfessionalDetailScreen(
              professional: Map<String, dynamic>.from(pro)))),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.divider),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center, children: [
          Stack(children: [
            CircleAvatar(
              radius: 26, backgroundColor: context.colors.primaryLight,
              backgroundImage: photo != null ? NetworkImage(photo) : null,
              child: photo == null ? Text(AppHelpers.getInitials(name),
                  style: TextStyle(fontSize: 11, color: context.colors.primary,
                      fontWeight: FontWeight.bold)) : null,
            ),
            if (verified) Positioned(right: 0, bottom: 0,
                child: Container(width: 13, height: 13,
                    decoration: BoxDecoration(
                        color: context.colors.accent, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 8))),
          ]),
          const SizedBox(height: 6),
          Text(name, textAlign: TextAlign.center, maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary)),
          if (category.isNotEmpty)
            Text(category, textAlign: TextAlign.center, maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: context.colors.primary)),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 10),
            Text(' ${rating.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 10,
                    fontWeight: FontWeight.w600, color: Color(0xFF92400E))),
          ]),
          if (distKm != null)
            Text(AppLocalizations.of(context)!.searchKm((distKm as num).toStringAsFixed(1)),
                style: TextStyle(fontSize: 9, color: context.colors.textSecondary)),
        ]),
      ),
    );
  }

  // ── Suggestion Panel ──────────────────────────────────────────────────────
  Widget _buildSuggestionPanel() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      children: [

        // Recent Searches
        if (_searchHistory.isNotEmpty) ...[
          _suggestionHeader('Recent', Icons.history_rounded),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 6,
            children: _searchHistory.take(5).map((q) =>
              _suggestionChip(q, Icons.history_rounded,
                  context.colors.divider, context.colors.textSecondary,
                  onTap: () => _selectSuggestion(q)),
            ).toList(),
          ),
          const SizedBox(height: 14),
        ],

        // Popular Searches
        if (_suggestPopular.isNotEmpty) ...[
          _suggestionHeader('Popular', Icons.trending_up_rounded),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 6,
            children: _suggestPopular.map((q) =>
              _suggestionChip(q, Icons.trending_up_rounded,
                  const Color(0xFFFEF3C7), const Color(0xFFD97706),
                  onTap: () => _selectSuggestion(q)),
            ).toList(),
          ),
          const SizedBox(height: 14),
        ],

        // Matching Professions
        if (_suggestProfessions.isNotEmpty) ...[
          _suggestionHeader('Professions', Icons.work_outline_rounded),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 6,
            children: _suggestProfessions.map((p) =>
              _suggestionChip(p, Icons.work_outline_rounded,
                  context.colors.primaryLight, context.colors.primary,
                  onTap: () => _selectSuggestion(p)),
            ).toList(),
          ),
          const SizedBox(height: 14),
        ],

        // Matching Categories
        if (_suggestCategories.isNotEmpty) ...[
          _suggestionHeader('Categories', Icons.category_outlined),
          const SizedBox(height: 6),
          ..._suggestCategories.map((cat) => GestureDetector(
            onTap: () {
              _hideSuggestions();
              _searchByCategory(cat['name'] as String, cat['id'] as int?);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: context.colors.surface, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.colors.divider),
              ),
              child: Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: context.colors.primaryLight,
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(getCategoryIcon(cat['name'] as String? ?? ''),
                      size: 16, color: context.colors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(cat['name'] as String? ?? '',
                    style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600, color: context.colors.textPrimary))),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: context.colors.textSecondary),
              ]),
            ),
          )),
          const SizedBox(height: 8),
        ],

        // Matching Professionals
        if (_suggestPros.isNotEmpty) ...[
          _suggestionHeader('Professionals', Icons.person_outline_rounded),
          const SizedBox(height: 6),
          ..._suggestPros.map((pro) => GestureDetector(
            onTap: () {
              _hideSuggestions();
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ProfessionalDetailScreen(
                    professional: Map<String, dynamic>.from(pro)),
              ));
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: context.colors.surface, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.colors.divider),
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: context.colors.primaryLight,
                  backgroundImage: pro['photo_url'] != null
                      ? NetworkImage(pro['photo_url'] as String) : null,
                  child: pro['photo_url'] == null
                      ? Text(AppHelpers.getInitials(pro['name'] as String? ?? ''),
                          style: TextStyle(fontSize: 11,
                              color: context.colors.primary, fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pro['name'] as String? ?? '',
                        style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
                    if ((pro['category'] as String? ?? '').isNotEmpty)
                      Text('${pro['category']} · ${pro['city'] ?? ''}',
                          style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
                  ],
                )),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: context.colors.textSecondary),
              ]),
            ),
          )),
        ],

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _suggestionHeader(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 13, color: context.colors.textSecondary),
      const SizedBox(width: 5),
      Text(title.toUpperCase(), style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700,
          color: context.colors.textSecondary, letterSpacing: 0.8)),
    ]);
  }

  Widget _suggestionChip(String label, IconData icon,
      Color bg, Color fg, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fg.withOpacity(0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12,
              fontWeight: FontWeight.w600, color: fg)),
        ]),
      ),
    );
  }

  Widget _buildAiResult() {
    final t = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            const _AiAgentAvatar(size: 38, showLiveDot: true),
            const SizedBox(width: 10),
            const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
            const SizedBox(width: 6),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_isPremium ? t.searchAiPremiumResults : t.searchAiSearchResultsTitle,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(t.searchFor(_lastQuery), style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
            if (!_isPremium)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                child: Text(t.searchToday('$_aiUsed', '$_aiLimit'),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
          ]),
        ),
        const SizedBox(height: 16),

        // Availability fallback — "no one available right now, showing nearest available"
        if (_aiAvailabilityMessage != null && _aiAvailabilityMessage!.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.event_busy_rounded, size: 16, color: Color(0xFFD97706)),
              const SizedBox(width: 8),
              Expanded(child: Text(_aiAvailabilityMessage!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w500, height: 1.4))),
            ]),
          ),

        if (_aiMatchedPros.isNotEmpty)
          ..._aiMatchedPros.map((pro) => _buildAiProCard(pro))
        else
          _buildAiRecommendations(),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async { setState(() { _aiMode = false; _aiResult = null; _aiMatchedPros = []; _aiAvailabilityMessage = null; _aiRecommendations = {}; }); await _search(_lastQuery); },
            icon: const Icon(Icons.search, size: 16),
            label: Text(t.searchAlsoShowNormalResults),
          ),
        ),
      ]),
    );
  }

  // ── AI "no exact match" recommendations — 4 explained sections ──────────
  Widget _buildAiRecommendations() {
    final t = AppLocalizations.of(context)!;
    final similar  = List<dynamic>.from(_aiRecommendations['similar_professionals']        ?? []);
    final related  = List<dynamic>.from(_aiRecommendations['related_professions']           ?? []);
    final trending = List<dynamic>.from(_aiRecommendations['trending_professionals']        ?? []);
    final nearby   = List<dynamic>.from(_aiRecommendations['popular_nearby_professionals']  ?? []);

    if (similar.isEmpty && related.isEmpty && trending.isEmpty && nearby.isEmpty) {
      // Absolute last resort — nothing to recommend at all.
      return Container(
        width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.colors.divider)),
        child: Text(_aiResult ?? t.searchNoMatchingProfessionalsFound,
            style: TextStyle(fontSize: 14, color: context.colors.textPrimary, height: 1.6)),
      );
    }

    Widget section(String title, IconData icon, Color color, List<dynamic> items) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          ]),
          const SizedBox(height: 8),
          ...items.map((pro) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if ((pro['recommendation_reason'] as String? ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.info_outline_rounded, size: 13, color: color),
                    const SizedBox(width: 6),
                    Expanded(child: Text(pro['recommendation_reason'] as String,
                        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600))),
                  ]),
                ),
              ),
            _buildResultCard(pro),
          ])),
        ]),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.colors.divider)),
        child: Column(children: [
          Icon(Icons.search_off_rounded, size: 40, color: context.colors.textDisabled),
          const SizedBox(height: 8),
          Text(t.searchNoExactMatch(_lastQuery), textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
          const SizedBox(height: 4),
          Text(t.searchHereSomeRelevantAlternatives, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
        ]),
      ),
      section(t.searchSimilarProfessionals, Icons.people_outline_rounded, context.colors.primary, similar),
      section(t.searchRelatedProfessions, Icons.category_outlined, const Color(0xFF8B5CF6), related),
      section(t.searchTrendingProfessionals, Icons.trending_up_rounded, const Color(0xFFF59E0B), trending),
      section(t.searchPopularNearby, Icons.near_me_rounded, const Color(0xFF059669), nearby),
    ]);
  }

  Widget _buildAiTypingIndicator() {
    final t = AppLocalizations.of(context)!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const _AiAgentAvatar(size: 76, showLiveDot: true),
          const SizedBox(height: 18),
          Text(t.searchAiAgentLive, style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.textPrimary, fontSize: 15)),
          const SizedBox(height: 4),
          Text(t.searchFindingBestMatch(_lastQuery),
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: context.colors.surface, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.colors.divider),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: const _TypingDots(),
          ),
        ]),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16), itemCount: 5,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 10), height: 86,
        decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const SizedBox(width: 14),
          Container(width: 52, height: 52, decoration: BoxDecoration(color: context.colors.divider, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 13, width: 130, color: context.colors.divider),
            const SizedBox(height: 6),
            Container(height: 11, width: 90, color: context.colors.divider),
            const SizedBox(height: 6),
            Container(height: 11, width: 70, color: context.colors.divider),
          ])),
        ]),
      ),
    );
  }

  Widget _buildDiscover() {
    final t = AppLocalizations.of(context)!;
    final visibleHistory = _searchHistory.take(_historyLimit).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_searchHistory.isNotEmpty) ...[
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(t.searchRecentSearches, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
            Row(children: [
              if (_searchHistory.length > _historyLimit) ...[
                GestureDetector(onTap: _showAllHistory,
                    child: Text(t.searchSeeAll('${_searchHistory.length}'),
                        style: TextStyle(fontSize: 12, color: context.colors.primary, fontWeight: FontWeight.w600))),
                const SizedBox(width: 12),
              ],
              GestureDetector(onTap: () => setState(() { _searchHistory.clear(); _saveSearchHistory(); }),
                  child: Text(t.searchClear, style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.w600))),
            ]),
          ]),
          const SizedBox(height: 10),
          ...visibleHistory.map((query) => GestureDetector(
            onTap: () { _controller.text = query; _search(query); },
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: context.colors.divider)),
              child: Row(children: [
                Icon(Icons.history_rounded, size: 16, color: context.colors.textSecondary),
                const SizedBox(width: 10),
                Expanded(child: Text(query, style: TextStyle(fontSize: 13, color: context.colors.textPrimary))),
                GestureDetector(onTap: () => setState(() { _searchHistory.remove(query); _saveSearchHistory(); }),
                    child: Icon(Icons.close, size: 14, color: context.colors.textSecondary)),
              ]),
            ),
          )),
          const SizedBox(height: 20),
        ],

        Text(t.searchPopularSearches, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _popularSearches.map((p) => GestureDetector(
            onTap: () { _controller.text = p['label']; _search(p['label']); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: context.colors.primaryLight, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(p['icon'] as IconData, size: 14, color: context.colors.primary),
                const SizedBox(width: 5),
                Text(p['label'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.primary)),
              ]),
            ),
          )).toList(),
        ),
        const SizedBox(height: 20),
        Text(t.searchBrowseByCategory, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
        const SizedBox(height: 10),
        ..._categories.asMap().entries.map((e) {
          final colors = [context.colors.primary, const Color(0xFFEF4444), const Color(0xFF8B5CF6),
            const Color(0xFF10B981), const Color(0xFFF59E0B), const Color(0xFF06B6D4),
            const Color(0xFFEC4899), const Color(0xFF6366F1)];
          final color = colors[e.key % colors.length];
          final cat   = e.value;
          return GestureDetector(
            onTap: () => _searchByCategory(cat['name'], cat['id']),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.divider)),
              child: Row(children: [
                Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(getCategoryIcon(cat['name']?.toString() ?? ''), color: color, size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Text(cat['name']?.toString() ?? '',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textPrimary))),
                Icon(Icons.arrow_forward_ios_rounded, size: 13, color: context.colors.textSecondary),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  Widget _buildResults() {
    if (_results.isEmpty) {
      return _buildEmptyState();
    }
    final t = AppLocalizations.of(context)!;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // GPS Status bar
      Container(
        color: context.colors.surface,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          Expanded(child: Text(
            t.searchResultFor('${_results.length}', _results.length != 1 ? 's' : '', _lastQuery),
            style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
          )),
          _locationLoading
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(width: 10, height: 10,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: context.colors.primary)),
                  const SizedBox(width: 5),
                  Text(t.searchGettingLocation, style: TextStyle(fontSize: 10, color: context.colors.textSecondary)),
                ])
              : _userLat != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.near_me_rounded, size: 10, color: Color(0xFF059669)),
                        const SizedBox(width: 3),
                        Text(t.searchSortedByDistance, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF059669))),
                      ]),
                    )
                  : GestureDetector(
                      onTap: _loadUserLocation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.location_off_outlined, size: 10, color: Color(0xFFD97706)),
                          const SizedBox(width: 3),
                          Text(t.searchEnableLocation, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFD97706))),
                        ]),
                      ),
                    ),
        ]),
      ),

      // "Did you mean" — spelling correction banner
      if (_spellingCorrected && _correctedQuery.isNotEmpty)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(children: [
            const Icon(Icons.spellcheck_rounded, size: 14, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                  children: [
                    TextSpan(text: AppLocalizations.of(context)!.searchShowingResultsFor),
                    TextSpan(
                      text: _correctedQuery,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),

      // City Fallback Banner
      if (_isFallback && _fallbackMessage.isNotEmpty)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFCD34D)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
            const SizedBox(width: 8),
            Expanded(child: Text(_fallbackMessage,
                style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w500, height: 1.4))),
          ]),
        ),

      // "Not in your city" message — intelligent location priority
      if (_cityUnavailableMessage != null && _cityUnavailableMessage!.isNotEmpty)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFCA5A5)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.location_off_outlined, size: 16, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Expanded(child: Text(_cityUnavailableMessage!,
                style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B), fontWeight: FontWeight.w600, height: 1.4))),
          ]),
        ),

      // Section label — "Available in Nearby Cities" / "Available in Other Cities"
      if (_citySectionLabel != null && _citySectionLabel!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(children: [
            const Icon(Icons.travel_explore_rounded, size: 15, color: Color(0xFF2563EB)),
            const SizedBox(width: 6),
            Text(_citySectionLabel!, style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
          ]),
        ),

      Expanded(child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        itemCount: _results.length,
        itemBuilder: (ctx, i) => _buildResultCard(_results[i]),
      )),
    ]);
  }

  Widget _buildAiProCard(dynamic pro) {
    final reason     = pro['ai_reason']     ?? '';
    final confidence = pro['ai_confidence'] ?? 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (reason.toString().isNotEmpty)
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: context.colors.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.auto_awesome, size: 14, color: context.colors.primary),
            const SizedBox(width: 6),
            Expanded(child: Text(
              confidence > 0 ? '$reason ($confidence/10 match)' : reason,
              style: TextStyle(fontSize: 12, color: context.colors.primary, fontWeight: FontWeight.w600),
            )),
          ]),
        ),
      _buildResultCard(pro),
    ]);
  }

  Widget _buildDistanceBadge(double? distanceKm) {
    if (distanceKm == null) return const SizedBox.shrink();
    final t = AppLocalizations.of(context)!;
    final String label; final Color bgColor; final Color textColor; final IconData icon;
    if (distanceKm < 1.0) {
      final meters = (distanceKm * 1000).round();
      label = t.searchMetersAway('$meters'); bgColor = const Color(0xFFECFDF5); textColor = const Color(0xFF059669); icon = Icons.near_me_rounded;
    } else if (distanceKm <= 5) {
      label = t.searchKmNearYou(distanceKm.toStringAsFixed(1)); bgColor = const Color(0xFFECFDF5); textColor = const Color(0xFF059669); icon = Icons.near_me_rounded;
    } else if (distanceKm <= 15) {
      label = t.searchKmAway(distanceKm.toStringAsFixed(1)); bgColor = const Color(0xFFEFF6FF); textColor = const Color(0xFF2563EB); icon = Icons.directions_outlined;
    } else if (distanceKm <= 30) {
      label = t.searchApproxKm('${distanceKm.round()}'); bgColor = const Color(0xFFFFFBEB); textColor = const Color(0xFFD97706); icon = Icons.route_outlined;
    } else if (distanceKm <= 60) {
      label = t.searchApproxKmNearbyCity('${distanceKm.round()}'); bgColor = const Color(0xFFFFF7ED); textColor = const Color(0xFFEA580C); icon = Icons.location_city_outlined;
    } else {
      label = t.searchDifferentArea; bgColor = const Color(0xFFF9FAFB); textColor = const Color(0xFF6B7280); icon = Icons.public_outlined;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 9, color: textColor),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: textColor)),
      ]),
    );
  }

  Widget _buildResultCard(dynamic pro) {
    final name       = pro['name']            ?? '';
    final city       = pro['city']            ?? '';
    final category   = pro['category_name']   ?? '';
    final rating     = (pro['average_rating'] ?? 0.0).toDouble();
    final isVerified = pro['is_verified']     ?? false;
    final isPremium  = pro['is_premium']      ?? false;
    final photo      = pro['photo_url'];
    final rate       = pro['hourly_rate']     ?? 0;
    final distanceKm = pro['distance_km'] != null ? (pro['distance_km'] as num).toDouble() : null;
    final scale      = ResponsiveUtils.scaleOf(context);
    final avatarR    = ResponsiveUtils.sp(26, scale, min: 24, max: 34);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => ProfessionalDetailScreen(professional: Map<String, dynamic>.from(pro)))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(ResponsiveUtils.sp(14, scale, min: 12, max: 18)),
        decoration: BoxDecoration(
          color: context.colors.surface, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isPremium ? context.colors.primary.withOpacity(0.3) : context.colors.divider, width: isPremium ? 1.5 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            CircleAvatar(
              radius: avatarR, backgroundColor: context.colors.primaryLight,
              backgroundImage: photo != null ? NetworkImage(photo) : null,
              child: photo == null ? Text(AppHelpers.getInitials(name),
                  style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold, fontSize: ResponsiveUtils.sp(13, scale, min: 12, max: 16))) : null,
            ),
            if (isVerified) Positioned(right: 0, bottom: 0,
                child: Container(
                    width: ResponsiveUtils.sp(15, scale, min: 14, max: 19), height: ResponsiveUtils.sp(15, scale, min: 14, max: 19),
                    decoration: BoxDecoration(color: context.colors.accent, shape: BoxShape.circle),
                    child: Icon(Icons.check, color: Colors.white, size: ResponsiveUtils.sp(9, scale, min: 8, max: 12)))),
          ]),
          SizedBox(width: ResponsiveUtils.sp(12, scale, min: 10, max: 16)),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(name,
                  style: TextStyle(fontSize: ResponsiveUtils.sp(14, scale, min: 13, max: 17), fontWeight: FontWeight.w700, color: context.colors.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (isPremium) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]),
                      borderRadius: BorderRadius.circular(6)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.workspace_premium, color: Colors.amber, size: ResponsiveUtils.sp(10, scale, min: 9, max: 13)),
                    const SizedBox(width: 2),
                    Text(AppLocalizations.of(context)!.searchPro, style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.sp(9, scale, min: 8, max: 12), fontWeight: FontWeight.bold)),
                  ]),
                ),
              ],
            ]),
            if (category.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 2),
                  child: Text(category, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: ResponsiveUtils.sp(12, scale, min: 11, max: 15), color: context.colors.primary, fontWeight: FontWeight.w500))),
            const SizedBox(height: 5),
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              if (city.isNotEmpty) ...[
                Icon(Icons.location_on_outlined, size: ResponsiveUtils.sp(11, scale, min: 10, max: 14), color: context.colors.textSecondary),
                const SizedBox(width: 2),
                Flexible(child: Text(city, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: ResponsiveUtils.sp(11, scale, min: 10, max: 14), color: context.colors.textSecondary))),
                if (distanceKm != null) const SizedBox(width: 6),
              ],
              _buildDistanceBadge(distanceKm),
            ]),
            const SizedBox(height: 5),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
                child: Row(children: [
                  Icon(Icons.star_rounded, color: const Color(0xFFF59E0B), size: ResponsiveUtils.sp(11, scale, min: 10, max: 14)),
                  const SizedBox(width: 2),
                  Text(rating.toStringAsFixed(1), style: TextStyle(fontSize: ResponsiveUtils.sp(11, scale, min: 10, max: 14), fontWeight: FontWeight.w600, color: const Color(0xFF92400E))),
                ]),
              ),
              SizedBox(width: ResponsiveUtils.sp(8, scale, min: 6, max: 12)),
              Text(AppLocalizations.of(context)!.searchHr('$rate'), style: TextStyle(fontSize: ResponsiveUtils.sp(12, scale, min: 11, max: 15), fontWeight: FontWeight.w700, color: context.colors.primary)),
            ]),
          ])),
          SizedBox(width: ResponsiveUtils.sp(8, scale, min: 6, max: 12)),
          Padding(padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.arrow_forward_ios_rounded, size: ResponsiveUtils.sp(13, scale, min: 12, max: 16), color: context.colors.textSecondary)),
        ]),
      ),
    );
  }
}

// ── AI Agent avatar ───────────────────────────────────────────────────────────
class _AiAgentAvatar extends StatelessWidget {
  final double size;
  final bool   showLiveDot;
  const _AiAgentAvatar({required this.size, this.showLiveDot = false});

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]),
          boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        padding: EdgeInsets.all(size * 0.06),
        child: CircleAvatar(backgroundColor: Colors.white,
            child: Icon(Icons.support_agent_rounded, size: size * 0.55, color: const Color(0xFF2563EB))),
      ),
      if (showLiveDot) Positioned(right: -1, bottom: -1,
          child: Container(width: size * 0.26, height: size * 0.26,
              decoration: BoxDecoration(color: const Color(0xFF22C55E), shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2)))),
    ]);
  }
}

// ── Bouncing typing dots ──────────────────────────────────────────────────────
class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) {
        final t = (_controller.value - (i * 0.2)) % 1.0;
        final bounce = (t < 0.5) ? t * 2 : (1 - t) * 2;
        return Padding(padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Transform.translate(offset: Offset(0, -bounce * 6),
                child: Container(width: 8, height: 8,
                    decoration: const BoxDecoration(shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF2563EB)])))));
      })),
    );
  }
}