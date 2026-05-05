import 'dart:convert';
import 'package:krishikranti/core/constants/api_constants.dart';
import 'package:krishikranti/core/network/http_service.dart';
import 'package:krishikranti/features/products/data/models/home_discovery_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeRepository {
  static final Map<String, Future<HomeDiscovery>> _discoveryCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 30);
  static SharedPreferences? _prefs;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<HomeDiscovery> getHomeDiscovery({bool forceRefresh = false}) async {
    const cacheKey = 'persistent_home_discovery';
    await _initPrefs();

    // 1. Check Memory Cache
    if (!forceRefresh && _discoveryCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheDuration) {
        return await _discoveryCache[cacheKey]!;
      }
    }

    // 2. Check Disk Cache
    if (!forceRefresh) {
      final diskData = _prefs?.getString(cacheKey);
      if (diskData != null) {
        try {
          final data = jsonDecode(diskData);
          final discovery = HomeDiscovery.fromJson(data);
          
          // Warm up memory cache
          _discoveryCache[cacheKey] = Future.value(discovery);
          _cacheTimestamps[cacheKey] = DateTime.now();
          return discovery;
        } catch (_) {}
      }
    }

    // 3. Fetch Fresh Data
    final fetchFuture = _fetchDiscoveryInternal(cacheKey);
    _discoveryCache[cacheKey] = fetchFuture;
    _cacheTimestamps[cacheKey] = DateTime.now();

    return await fetchFuture;
  }

  Future<HomeDiscovery> _fetchDiscoveryInternal(String cacheKey) async {
    try {
      final response = await HttpService.get(ApiConstants.homeDiscovery);
      if (response.statusCode == 200) {
        await _initPrefs();
        _prefs?.setString(cacheKey, response.body);

        final data = jsonDecode(response.body);
        return HomeDiscovery.fromJson(data);
      } else {
        throw Exception('Failed to load home discovery data');
      }
    } catch (e) {
      rethrow;
    }
  }
}
