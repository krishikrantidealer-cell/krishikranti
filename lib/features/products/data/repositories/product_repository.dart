import 'dart:convert';
import 'package:krishikranti/core/constants/api_constants.dart';
import 'package:krishikranti/core/network/http_service.dart';
import 'package:krishikranti/features/products/data/models/product_model.dart';
import 'package:krishikranti/features/products/data/models/category_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductRepository {
  static final Map<String, Future<dynamic>> _productsCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 5);
  static final Map<String, Product> _detailsMemoryCache = {};
  static final Map<String, DateTime> _detailsCacheTimestamps = {};
  static SharedPreferences? _prefs;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<Map<String, dynamic>> getProducts({
    int limit = 20,
    String? cursor,
    String? search,
    String? categoryId,
    String? subCategoryId,
    String? collection,
    bool? isFeatured,
    bool forceRefresh = false,
  }) async {
    final cacheKey =
        'products_${categoryId}_${subCategoryId}_${collection}_${isFeatured}_${cursor}_${limit}_$search';

    await _initPrefs();

    // On forceRefresh: evict memory and disk cache first so we get truly fresh data
    if (forceRefresh && search == null) {
      _productsCache.remove(cacheKey);
      _cacheTimestamps.remove(cacheKey);
      await _prefs?.remove(cacheKey);
    }

    // 1. Check Memory Cache (skip for search queries — must always be real-time)
    if (search == null && _productsCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheDuration) {
        return (await _productsCache[cacheKey]) as Map<String, dynamic>;
      }
    }

    // 2. Check Disk Cache (skip for search queries)
    if (search == null && !_productsCache.containsKey(cacheKey)) {
      final diskData = _prefs?.getString(cacheKey);
      if (diskData != null) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(diskData);
          final List productsJson = decoded['products'] ?? [];
          final result = {
            'products': productsJson.map((j) => Product.fromJson(j)).toList(),
            'nextCursor': decoded['nextCursor'],
            'isFromCache': true,
          };
          // Warm up memory cache
          _productsCache[cacheKey] = Future.value(result);
          _cacheTimestamps[cacheKey] = DateTime.now();
          return result;
        } catch (_) {
          // If disk cache is corrupted, ignore it
        }
      }
    }

    // 3. Fetch Fresh Data
    final fetchFuture = _fetchProductsInternal(
      limit: limit,
      cursor: cursor,
      search: search,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      collection: collection,
      isFeatured: isFeatured,
      cacheKey: cacheKey,
    );

    _productsCache[cacheKey] = fetchFuture;
    _cacheTimestamps[cacheKey] = DateTime.now();

    return await fetchFuture;
  }

  Future<Map<String, dynamic>> _fetchProductsInternal({
    required int limit,
    String? cursor,
    String? search,
    String? categoryId,
    String? subCategoryId,
    String? collection,
    bool? isFeatured,
    required String cacheKey,
  }) async {
    final queryParams = {
      'limit': limit.toString(),
      if (cursor != null) 'cursor': cursor,
      if (search != null) 'search': search,
      if (categoryId != null) 'categoryId': categoryId,
      if (subCategoryId != null) 'subCategoryId': subCategoryId,
      if (collection != null) 'collection': collection,
      if (isFeatured != null) 'isFeatured': isFeatured.toString(),
    };

    final uri = Uri.parse(
      ApiConstants.products,
    ).replace(queryParameters: queryParams);

    try {
      final response = await HttpService.get(uri.toString());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save to disk for persistence
        await _initPrefs();
        _prefs?.setString(cacheKey, response.body);

        final List productsJson = data['products'] ?? [];
        final products = productsJson
            .where((json) => json['title'] != null)
            .map((json) => Product.fromJson(json))
            .toList();

        return {
          'products': products,
          'nextCursor': data['nextCursor'],
          'isFromCache': false,
        };
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Product> getProductDetail(String id, {bool forceRefresh = false}) async {
    final cacheKey = 'product_detail_$id';
    await _initPrefs();

    // 1. Force refresh: clear memory and disk cache first
    if (forceRefresh) {
      _detailsMemoryCache.remove(id);
      _detailsCacheTimestamps.remove(id);
      await _prefs?.remove(cacheKey);
    }

    // 2. Check Memory Cache with TTL expiration check
    if (_detailsMemoryCache.containsKey(id)) {
      final timestamp = _detailsCacheTimestamps[id];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheDuration) {
        return _detailsMemoryCache[id]!;
      }
    }

    // 3. Check Disk Cache (SharedPreferences)
    if (!_detailsMemoryCache.containsKey(id)) {
      final diskData = _prefs?.getString(cacheKey);
      if (diskData != null) {
        try {
          final decoded = jsonDecode(diskData);
          final product = Product.fromJson(decoded['product']);
          _detailsMemoryCache[id] = product;
          _detailsCacheTimestamps[id] = DateTime.now();
          return product;
        } catch (_) {}
      }
    }

    // 4. Fetch Fresh Data from API
    try {
      final response = await HttpService.get(ApiConstants.productDetail(id));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Persist to disk cache
        await _initPrefs();
        _prefs?.setString(cacheKey, response.body);

        final product = Product.fromJson(data['product']);
        _detailsMemoryCache[id] = product;
        _detailsCacheTimestamps[id] = DateTime.now();
        return product;
      } else {
        throw Exception('Failed to load product details');
      }
    } catch (e) {
      rethrow;
    }
  }

  Product? getProductDetailFromCache(String id) {
    return _detailsMemoryCache[id];
  }

  Future<List<Category>> getCategories({bool forceRefresh = false}) async {
    const cacheKey = 'persistent_categories';
    await _initPrefs();

    // On forceRefresh: evict memory and disk cache
    if (forceRefresh) {
      _productsCache.remove(cacheKey);
      _cacheTimestamps.remove(cacheKey);
      await _prefs?.remove(cacheKey);
    }

    // Memory cache with TTL check
    if (_productsCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheDuration) {
        return (await _productsCache[cacheKey]) as List<Category>;
      }
    }

    // Disk cache
    final diskData = _prefs?.getString(cacheKey);
    if (diskData != null) {
      try {
        final List decoded = jsonDecode(diskData);
        final categories = decoded.map((j) => Category.fromJson(j)).toList();
        _productsCache[cacheKey] = Future.value(categories);
        _cacheTimestamps[cacheKey] = DateTime.now();
        return categories;
      } catch (_) {}
    }

    final fetchFuture = _fetchCategoriesInternal(cacheKey);
    _productsCache[cacheKey] = fetchFuture;
    _cacheTimestamps[cacheKey] = DateTime.now();

    return await fetchFuture;
  }

  Future<List<Category>> _fetchCategoriesInternal(String cacheKey) async {
    try {
      final response = await HttpService.get(ApiConstants.categories);
      if (response.statusCode == 200) {
        await _initPrefs();
        _prefs?.setString(cacheKey, response.body);

        final data = jsonDecode(response.body);
        final List categoriesJson = data['categories'] ?? [];
        return categoriesJson.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      rethrow;
    }
  }
}
