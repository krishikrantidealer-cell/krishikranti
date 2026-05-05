import 'dart:convert';
import 'package:krishikranti/core/constants/api_constants.dart';
import 'package:krishikranti/core/network/http_service.dart';
import 'package:krishikranti/features/products/data/models/collection_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CollectionRepository {
  static final Map<String, Future<List<Collection>>> _collectionsCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 30);
  static SharedPreferences? _prefs;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<List<Collection>> getCollectionsWithProducts({bool forceRefresh = false}) async {
    const cacheKey = 'persistent_collections_with_products';
    await _initPrefs();

    // 1. Check Memory Cache
    if (!forceRefresh && _collectionsCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheDuration) {
        return await _collectionsCache[cacheKey]!;
      }
    }

    // 2. Check Disk Cache
    if (!forceRefresh) {
      final diskData = _prefs?.getString(cacheKey);
      if (diskData != null) {
        try {
          final data = jsonDecode(diskData);
          final List collectionsJson = data['collections'] ?? [];
          final collections = collectionsJson.map((json) => Collection.fromJson(json)).toList();
          
          // Warm up memory cache
          _collectionsCache[cacheKey] = Future.value(collections);
          _cacheTimestamps[cacheKey] = DateTime.now();
          return collections;
        } catch (_) {}
      }
    }

    // 3. Fetch Fresh Data
    final fetchFuture = _fetchCollectionsInternal(cacheKey);
    _collectionsCache[cacheKey] = fetchFuture;
    _cacheTimestamps[cacheKey] = DateTime.now();

    return await fetchFuture;
  }

  Future<List<Collection>> _fetchCollectionsInternal(String cacheKey) async {
    try {
      final response = await HttpService.get(ApiConstants.collectionsWithProducts);
      if (response.statusCode == 200) {
        await _initPrefs();
        _prefs?.setString(cacheKey, response.body);

        final data = jsonDecode(response.body);
        final List collectionsJson = data['collections'] ?? [];
        return collectionsJson.map((json) => Collection.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load collections');
      }
    } catch (e) {
      rethrow;
    }
  }
}
