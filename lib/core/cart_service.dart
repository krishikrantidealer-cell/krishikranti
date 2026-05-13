import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:krishikranti/core/constants/api_constants.dart';
import 'package:krishikranti/core/network/http_service.dart';

class CartItem {
  final String? itemId; // Backend ID
  final String productId;
  final String variantId;
  final String productName;
  final String productImage;
  final String technicalName;
  final String variant;
  final double price;
  int qty;
  final bool isFree;

  CartItem({
    this.itemId,
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.productImage,
    required this.technicalName,
    required this.variant,
    required this.price,
    required this.qty,
    this.isFree = false,
  });

  static String _parseId(dynamic id) {
    if (id == null) return '';
    if (id is String) return id;
    if (id is Map && id.containsKey('\$oid')) return id['\$oid'].toString();
    return id.toString();
  }

  static String _resolveImageUrl(String path) {
    if (path == null || path.isEmpty) return '';
    if (path.contains('drive.google.com')) {
      final idMatch = RegExp(
        r'(?:id=|\/d\/|folders\/)([a-zA-Z0-9-_]+)',
      ).firstMatch(path);
      if (idMatch != null) {
        final fileId = idMatch.group(1);
        return 'https://drive.google.com/thumbnail?id=$fileId&sz=w1000';
      }
    }
    if (path.startsWith('http')) return path;
    return '${ApiConstants.baseUrl}/${path.startsWith('/') ? path.substring(1) : path}';
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 1;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 1;
    return 1;
  }

  factory CartItem.fromJson(Map<String, dynamic> json, {bool isFree = false}) {
    final product = json['product'] is Map
        ? json['product'] as Map<String, dynamic>
        : null;
    final vId = _parseId(json['variantId']);

    String variantName = json['variant'] ?? "";
    if (variantName.isEmpty && product != null && product['variants'] != null) {
      final variants = product['variants'] as List;
      final v = variants.firstWhere(
        (v) => _parseId(v?['_id']) == vId,
        orElse: () => null,
      );
      if (v != null) variantName = v['size'] ?? "";
    }

    final rawImage =
        json['productImage'] ??
        json['imageUrl'] ??
        ((product?['images'] != null && (product!['images'] as List).isNotEmpty)
            ? product['images'][0].toString()
            : '');

    return CartItem(
      itemId: _parseId(json['_id']),
      productId: _parseId(
        product?['_id'] ?? json['productId'] ?? json['product'],
      ),
      variantId: vId,
      productName:
          product?['title'] ?? json['productName'] ?? json['name'] ?? 'Product',
      productImage: _resolveImageUrl(rawImage.toString()),
      technicalName: product?['technicalName'] ?? json['technicalName'] ?? '',
      variant: variantName,
      price: isFree ? 0.0 : _parseDouble(json['price']),
      qty: _parseInt(json['quantity']),
      isFree: isFree,
    );
  }
}

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal() {
    _init();
  }

  static SharedPreferences? _prefs;

  Future<void> _init() async {
    await _loadFromCache();
    syncWithBackend();
  }

  Future<void> _loadFromCache() async {
    _prefs ??= await SharedPreferences.getInstance();
    final cachedData = _prefs?.getString('cart_cache');
    if (cachedData != null) {
      try {
        final decoded = jsonDecode(cachedData);
        _updateCartFromJson(decoded, saveToCache: false);
      } catch (e) {
        debugPrint("Error loading cart cache: $e");
      }
    }
  }

  Future<void> _saveToCache(Map cartMap) async {
    _prefs ??= await SharedPreferences.getInstance();
    _prefs?.setString('cart_cache', jsonEncode(cartMap));
  }

  List<CartItem> _items = [];
  String? _appliedCoupon;
  double _discountAmount = 0;
  bool _isLoading = false;
  bool _isCouponLoading = false;
  Future<void>? _pendingSyncTask;
  int _dataVersion = 0;

  List<CartItem> get items => _items;
  String? get appliedCoupon => _appliedCoupon;
  double get discountAmount => _discountAmount;
  bool get isLoading => _isLoading;
  bool get isCouponLoading => _isCouponLoading;
  Future<void>? get pendingSyncTask => _pendingSyncTask;
  Set<String> get syncingVariantIds => _inFlightSyncVariantIds;

  final Map<String, Timer> _addDebounceTimers = {};
  final Map<String, Timer> _updateDebounceTimers = {};
  final Map<String, int> _optimisticTargetQty = {};
  final Set<String> _inFlightSyncVariantIds = {};
  final Map<String, int> _inFlightSyncCounts = {};

  void _incrementInFlight(String variantId) {
    _inFlightSyncCounts[variantId] = (_inFlightSyncCounts[variantId] ?? 0) + 1;
    _inFlightSyncVariantIds.add(variantId);
  }

  void _decrementInFlight(String variantId) {
    final current = _inFlightSyncCounts[variantId] ?? 0;
    if (current <= 1) {
      _inFlightSyncCounts.remove(variantId);
      _inFlightSyncVariantIds.remove(variantId);
    } else {
      _inFlightSyncCounts[variantId] = current - 1;
    }
  }

  // Compile-time compatibility
  Map<String, Timer> get addDebounceTimers => _addDebounceTimers;
  Map<String, Timer> get updateDebounceTimers => _updateDebounceTimers;

  Future<void> syncWithBackend() async {
    _isLoading = true;
    notifyListeners();
    final int currentVersion = _dataVersion;
    final stopwatch = Stopwatch()..start();
    try {
      final response = await HttpService.get(ApiConstants.cart);
      stopwatch.stop();
      debugPrint(
        "[Cart API] GET syncWithBackend took ${stopwatch.elapsedMilliseconds}ms",
      );

      if (currentVersion < _dataVersion) {
        debugPrint(
          "[Cart API] Discarding stale GET response due to newer mutations",
        );
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cartMap = data is Map ? (data['cart'] ?? data) : null;
        if (cartMap != null) {
          _updateCartFromJson(cartMap);
        } else {
          debugPrint("Unrecognized cart response structure: $data");
        }
      } else {
        debugPrint(
          "Cart sync failed: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      debugPrint("Cart sync error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem({
    required String productId,
    required String variantId,
    required String productName,
    required String productImage,
    required String technicalName,
    required String variant,
    required double price,
    required int qty,
    bool sync = true,
  }) async {
    return addItems(
      productId: productId,
      items: [
        {
          'variantId': variantId,
          'quantity': qty,
          'productName': productName,
          'productImage': productImage,
          'technicalName': technicalName,
          'variant': variant,
          'price': price,
        },
      ],
      sync: sync,
    );
  }

  Future<void> addItems({
    required String productId,
    required List<Map<String, dynamic>> items,
    bool sync = true,
    bool isReplace = false,
  }) async {
    if (!sync) {
      // Local addition helper (offline mock operations)
      for (var item in items) {
        int index = _items.indexWhere(
          (existing) =>
              existing.productId == productId &&
              existing.variantId == item['variantId'],
        );
        if (index != -1) {
          if (isReplace) {
            _items[index].qty = (item['quantity'] as int);
          } else {
            _items[index].qty += (item['quantity'] as int);
          }
        } else {
          _items.add(
            CartItem(
              productId: productId,
              variantId: item['variantId'],
              productName: item['productName'] ?? '',
              productImage: item['productImage'] ?? '',
              technicalName: item['technicalName'] ?? '',
              variant: item['variant'] ?? '',
              price: (item['price'] as num).toDouble(),
              qty: item['quantity'] as int,
            ),
          );
        }
      }
      notifyListeners();
      return;
    }

    _dataVersion++;

    // --- OPTIMISTIC UPDATE ---
    // Backup current state for potential rollback
    final oldItems = _items
        .map(
          (it) => CartItem(
            itemId: it.itemId,
            productId: it.productId,
            variantId: it.variantId,
            productName: it.productName,
            productImage: it.productImage,
            technicalName: it.technicalName,
            variant: it.variant,
            price: it.price,
            qty: it.qty,
            isFree: it.isFree,
          ),
        )
        .toList();

    // Instantly apply changes to local state
    for (var item in items) {
      final vId = item['variantId'] as String;
      int index = _items.indexWhere(
        (existing) =>
            existing.productId == productId && existing.variantId == vId,
      );
      if (index != -1) {
        if (isReplace) {
          _items[index].qty = (item['quantity'] as int);
        } else {
          _items[index].qty += (item['quantity'] as int);
        }
        _optimisticTargetQty[vId] = _items[index].qty;
      } else {
        _items.add(
          CartItem(
            productId: productId,
            variantId: vId,
            productName: item['productName'] ?? '',
            productImage: item['productImage'] ?? '',
            technicalName: item['technicalName'] ?? '',
            variant: item['variant'] ?? '',
            price: (item['price'] as num).toDouble(),
            qty: item['quantity'] as int,
          ),
        );
        _optimisticTargetQty[vId] = item['quantity'] as int;
      }
    }
    notifyListeners();

    // Debounce backend sync per product to avoid rapid successive server hits
    _addDebounceTimers[productId]?.cancel();

    final completer = Completer<void>();
    _pendingSyncTask = completer.future;

    _addDebounceTimers[productId] = Timer(
      const Duration(milliseconds: 300),
      () async {
        for (var item in items) {
          _incrementInFlight(item['variantId']);
        }
        final stopwatch = Stopwatch()..start();
        try {
          final variantsPayload = items
              .map(
                (item) => {
                  'variantId': item['variantId'],
                  'quantity': item['quantity'],
                  'isReplace': isReplace,
                },
              )
              .toList();

          final response = await HttpService.post(
            ApiConstants.cartItems,
            body: {'productId': productId, 'variants': variantsPayload},
          );
          stopwatch.stop();
          debugPrint(
            "[Cart API] POST addItems (debounced) took ${stopwatch.elapsedMilliseconds}ms",
          );

          if (response.statusCode != 200 && response.statusCode != 201) {
            throw Exception("Failed to sync cart items");
          }

          final data = jsonDecode(response.body);
          final cartMap = data is Map ? (data['cart'] ?? data) : null;
          if (cartMap != null) {
            _updateCartFromJson(cartMap);
          } else {
            await syncWithBackend();
          }
        } catch (e) {
          debugPrint("Add items error: $e");
          // Rollback
          _items = oldItems;
          notifyListeners();
          await syncWithBackend();
        } finally {
          for (var item in items) {
            final vId = item['variantId'] as String;
            _decrementInFlight(vId);
            final bool hasPendingProductAdd =
                _addDebounceTimers.containsKey(productId) &&
                _addDebounceTimers[productId]?.isActive == true;
            if (!_updateDebounceTimers.containsKey(vId) &&
                !hasPendingProductAdd) {
              _optimisticTargetQty.remove(vId);
            }
          }
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      },
    );

    return _pendingSyncTask;
  }

  int getVariantQty(String variantId) {
    final index = _items.indexWhere((it) => it.variantId == variantId);
    if (index == -1) return 0;
    return _items[index].qty;
  }

  Future<void> updateQty(String variantId, int newQty) async {
    final index = _items.indexWhere((it) => it.variantId == variantId);
    if (index == -1) return;
    final item = _items[index];

    _dataVersion++;

    // --- OPTIMISTIC UPDATE ---
    final oldItems = _items
        .map(
          (it) => CartItem(
            itemId: it.itemId,
            productId: it.productId,
            variantId: it.variantId,
            productName: it.productName,
            productImage: it.productImage,
            technicalName: it.technicalName,
            variant: it.variant,
            price: it.price,
            qty: it.qty,
            isFree: it.isFree,
          ),
        )
        .toList();

    if (newQty <= 0) {
      _items.removeAt(index);
      _optimisticTargetQty[variantId] = 0;
      _addDebounceTimers[item.productId]?.cancel();
      _addDebounceTimers.remove(item.productId);
    } else {
      _items[index].qty = newQty;
      _optimisticTargetQty[variantId] = newQty;
    }
    notifyListeners();

    // Debounce the quantity sync on the server
    _updateDebounceTimers[variantId]?.cancel();

    final completer = Completer<void>();
    _pendingSyncTask = completer.future;

    _updateDebounceTimers[variantId] = Timer(
      const Duration(milliseconds: 300),
      () async {
        _incrementInFlight(variantId);
        final stopwatch = Stopwatch()..start();
        try {
          final String? itemId = item.itemId;
          if (itemId == null) {
            debugPrint(
              "[Cart API] Warning: itemId is null, executing recovery sync first.",
            );
            await syncWithBackend();
          }

          final updatedIdx = _items.indexWhere(
            (it) => it.variantId == variantId,
          );
          final activeItemId = updatedIdx != -1
              ? _items[updatedIdx].itemId
              : item.itemId;

          if (activeItemId != null) {
            if (newQty <= 0) {
              final response = await HttpService.delete(
                "${ApiConstants.cartItems}/$activeItemId",
              );
              stopwatch.stop();
              debugPrint(
                "[Cart API] DELETE removeItem took ${stopwatch.elapsedMilliseconds}ms",
              );

              if (response.statusCode != 200) {
                throw Exception("Failed to remove item");
              }
              final data = jsonDecode(response.body);
              final cartMap = data is Map ? (data['cart'] ?? data) : null;
              if (cartMap != null) {
                _updateCartFromJson(cartMap);
              } else {
                await syncWithBackend();
              }
            } else {
              final response = await HttpService.patch(
                "${ApiConstants.cartItems}/$activeItemId",
                body: {'quantity': newQty},
              );
              stopwatch.stop();
              debugPrint(
                "[Cart API] PATCH updateQty took ${stopwatch.elapsedMilliseconds}ms",
              );

              if (response.statusCode != 200) {
                throw Exception("Failed to update quantity");
              }
              final data = jsonDecode(response.body);
              final cartMap = data is Map ? (data['cart'] ?? data) : null;
              if (cartMap != null) {
                _updateCartFromJson(cartMap);
              } else {
                await syncWithBackend();
              }
            }
          } else {
            stopwatch.stop();
            debugPrint(
              "[Cart API] Error: activeItemId unresolved after recovery sync.",
            );
            await syncWithBackend();
          }
        } catch (e) {
          debugPrint("Error updating quantity: $e");
          // Rollback
          _items = oldItems;
          notifyListeners();
          await syncWithBackend();
        } finally {
          _decrementInFlight(variantId);
          final bool hasPendingProductAdd =
              _addDebounceTimers.containsKey(item.productId) &&
              _addDebounceTimers[item.productId]?.isActive == true;
          if (!_updateDebounceTimers.containsKey(variantId) &&
              !hasPendingProductAdd) {
            _optimisticTargetQty.remove(variantId);
          }
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      },
    );

    return _pendingSyncTask;
  }

  Future<void> removeItem(String variantId) async {
    final index = _items.indexWhere((it) => it.variantId == variantId);
    if (index == -1) return;
    final item = _items[index];

    // Cancel any pending update timer for this variant since it is being removed
    _updateDebounceTimers[variantId]?.cancel();
    _updateDebounceTimers.remove(variantId);

    // Cancel any pending add/replace timer for this product
    _addDebounceTimers[item.productId]?.cancel();
    _addDebounceTimers.remove(item.productId);

    _dataVersion++;

    // --- OPTIMISTIC UPDATE ---
    final oldItems = _items
        .map(
          (it) => CartItem(
            itemId: it.itemId,
            productId: it.productId,
            variantId: it.variantId,
            productName: it.productName,
            productImage: it.productImage,
            technicalName: it.technicalName,
            variant: it.variant,
            price: it.price,
            qty: it.qty,
            isFree: it.isFree,
          ),
        )
        .toList();

    _items.removeAt(index);
    _optimisticTargetQty[variantId] = 0;
    notifyListeners();

    final stopwatch = Stopwatch()..start();

    try {
      _incrementInFlight(variantId);
      final String? itemId = item.itemId;
      if (itemId == null) {
        debugPrint(
          "[Cart API] Warning: itemId is null, executing recovery sync first.",
        );
        await syncWithBackend();
      }

      final activeItemId = item.itemId;
      if (activeItemId != null) {
        final response = await HttpService.delete(
          "${ApiConstants.cartItems}/$activeItemId",
        );
        stopwatch.stop();
        debugPrint(
          "[Cart API] DELETE removeItem took ${stopwatch.elapsedMilliseconds}ms",
        );

        if (response.statusCode != 200) {
          throw Exception("Failed to delete item from cart");
        }
        final data = jsonDecode(response.body);
        final cartMap = data is Map ? (data['cart'] ?? data) : null;
        if (cartMap != null) {
          _updateCartFromJson(cartMap);
        } else {
          await syncWithBackend();
        }
      } else {
        stopwatch.stop();
        debugPrint(
          "[Cart API] Error: activeItemId unresolved after recovery sync.",
        );
        await syncWithBackend();
      }
    } catch (e) {
      debugPrint("Error removing item: $e");
      // Rollback
      _items = oldItems;
      notifyListeners();
      await syncWithBackend();
    } finally {
      _decrementInFlight(variantId);
      _optimisticTargetQty.remove(variantId);
    }
  }

  void _updateCartFromJson(Map cartMap, {bool saveToCache = true}) {
    final List itemsJson = cartMap['items'] ?? [];
    final List freeItemsJson = cartMap['freeItems'] ?? [];

    final List<CartItem> parsedItems = itemsJson
        .map((j) => CartItem.fromJson(j))
        .toList();
    final List<CartItem> parsedFreeItems = freeItemsJson
        .map((j) => CartItem.fromJson(j, isFree: true))
        .toList();

    // Build a list of active syncing/debouncing variant IDs
    final Set<String> activeSyncingIds = {
      ..._updateDebounceTimers.keys,
      ..._inFlightSyncVariantIds,
    };

    // Override quantity of incoming server items with active optimistic values
    final List<CartItem> filteredItems = [];
    final Set<String> processedVariantIds = {};

    for (var item in parsedItems) {
      final vId = item.variantId;
      processedVariantIds.add(vId);

      final bool hasPendingProductAdd =
          _addDebounceTimers.containsKey(item.productId) &&
          _addDebounceTimers[item.productId]?.isActive == true;

      if (activeSyncingIds.contains(vId) || hasPendingProductAdd) {
        final targetQty = _optimisticTargetQty[vId];
        if (targetQty != null) {
          if (targetQty <= 0) {
            // User deleted this item, skip adding to cart list
            continue;
          } else {
            item.qty = targetQty;
          }
        }
      }
      filteredItems.add(item);
    }

    // Retain any pending optimistic items that aren't even present on the server response yet
    for (var localItem in _items) {
      if (localItem.isFree) continue;
      final vId = localItem.variantId;
      final bool hasPendingProductAdd =
          _addDebounceTimers.containsKey(localItem.productId) &&
          _addDebounceTimers[localItem.productId]?.isActive == true;

      if ((activeSyncingIds.contains(vId) || hasPendingProductAdd) &&
          !processedVariantIds.contains(vId)) {
        final targetQty = _optimisticTargetQty[vId];
        if (targetQty != null && targetQty > 0) {
          filteredItems.add(localItem);
        }
      }
    }

    _items = [...filteredItems, ...parsedFreeItems];
    _appliedCoupon = cartMap['appliedCoupon'];
    _discountAmount = CartItem._parseDouble(cartMap['discountAmount']);

    if (saveToCache) {
      _saveToCache(cartMap);
    }

    notifyListeners();
  }

  Future<void> applyCoupon(String code) async {
    _isCouponLoading = true;
    _dataVersion++;
    notifyListeners();

    try {
      final response = await HttpService.post(
        ApiConstants.applyCoupon,
        body: {'code': code},
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final cartMap = data['cart'];
        if (cartMap != null) _updateCartFromJson(cartMap);
      } else {
        throw Exception(data['message'] ?? 'Failed to apply coupon');
      }
    } finally {
      _isCouponLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeCoupon() async {
    _isCouponLoading = true;
    _dataVersion++;

    // Optimistic Update (Instant feedback)
    _appliedCoupon = null;
    _discountAmount = 0;
    _items.removeWhere((item) => item.isFree);
    notifyListeners();

    // Sync
    try {
      final response = await HttpService.delete(ApiConstants.applyCoupon);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cartMap = data['cart'];
        if (cartMap != null) _updateCartFromJson(cartMap);
      } else {
        await syncWithBackend();
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to remove coupon');
      }
    } catch (e) {
      await syncWithBackend();
      rethrow;
    } finally {
      _isCouponLoading = false;
      notifyListeners();
    }
  }

  double get subtotal =>
      _items.fold(0, (sum, item) => sum + (item.price * item.qty));
  double get totalAmount => subtotal - _discountAmount;

  int get totalCount => _items.fold(0, (sum, item) => sum + item.qty);

  Future<void> clear() async {
    for (var timer in _addDebounceTimers.values) {
      timer.cancel();
    }
    _addDebounceTimers.clear();
    for (var timer in _updateDebounceTimers.values) {
      timer.cancel();
    }
    _updateDebounceTimers.clear();
    _optimisticTargetQty.clear();

    _items.clear();
    _appliedCoupon = null;
    _discountAmount = 0;
    _prefs?.remove('cart_cache');
    _dataVersion++;
    notifyListeners();

    try {
      final response = await HttpService.delete(ApiConstants.cart);
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception("Failed to clear cart on server");
      }
    } catch (_) {
      await syncWithBackend();
    }
  }
}
