import 'dart:convert';
import 'package:krishikranti/core/constants/api_constants.dart';
import 'package:krishikranti/core/network/http_service.dart';
import 'package:krishikranti/features/products/data/models/home_discovery_model.dart';
import 'package:krishikranti/core/dynamic_translation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeRepository {
  static final Map<String, Future<HomeDiscovery>> _discoveryCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 5);
  static SharedPreferences? _prefs;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Clears all cached home discovery data (memory + disk)
  static Future<void> clearCache() async {
    _discoveryCache.clear();
    _cacheTimestamps.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('persistent_home_discovery');
  }

  Future<HomeDiscovery> getHomeDiscovery({bool forceRefresh = false}) async {
    const cacheKey = 'persistent_home_discovery';
    await _initPrefs();

    // On forceRefresh: evict memory and disk cache first so we get truly fresh data
    if (forceRefresh) {
      _discoveryCache.remove(cacheKey);
      _cacheTimestamps.remove(cacheKey);
      await _prefs?.remove(cacheKey);
    }

    // 1. Check Memory Cache
    if (_discoveryCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheDuration) {
        return await _discoveryCache[cacheKey]!;
      }
    }

    // 2. Check Disk Cache
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
        final discovery = HomeDiscovery.fromJson(data);

        // Pre-warm translations for all dynamic text from the home discovery data
        _preWarmHomeTranslations(discovery);

        return discovery;
      } else {
        throw Exception('Failed to load home discovery data');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ── Translation pre-warming helper ──────────────────────────────────────

  static void _preWarmHomeTranslations(HomeDiscovery discovery) {
    final texts = <String>[];
    for (final cat in discovery.categories) {
      if (cat.name.isNotEmpty) texts.add(cat.name);
    }
    for (final col in discovery.collections) {
      if (col.name.isNotEmpty) texts.add(col.name);
      if (col.description?.isNotEmpty ?? false) texts.add(col.description!);
      for (final sub in col.subCollections) {
        if (sub.name.isNotEmpty) texts.add(sub.name);
      }
    }
    DynamicTranslationService().ensureAllTranslated(texts);
  }
}
