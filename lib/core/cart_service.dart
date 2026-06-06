import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:krishikranti/core/constants/api_constants.dart';
import 'package:krishikranti/core/network/http_service.dart';

class CartItem {
  String? itemId; // Backend ID
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
    // Wait for the app's intensive boot activities (Firebase, notifications, frame rendering)
    // to complete before hitting the network. This avoids event loop blockage.
    await Future.delayed(const Duration(milliseconds: 1500));
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
  final Map<String, String> _variantToItemId = {};

  final Map<String, int> _pendingSyncUpdates = {};
  final Map<String, CartItem?> _trueBackupItems = {};
  Completer<void>? _pendingSyncCompleter;

  Future<void> _syncQueue = Future.value();

  Future<void> _enqueueSync(Future<void> Function() task) {
    final completer = Completer<void>();
    _syncQueue = _syncQueue
        .then((_) async {
          try {
            await task();
            completer.complete();
          } catch (e, stack) {
            debugPrint("[CartService Queue] Task failed: $e\n$stack");
            if (!completer.isCompleted) {
              completer.completeError(e, stack);
            }
          }
        })
        .catchError((e) {
          debugPrint("[CartService Queue] Unhandled error in queue: $e");
        });
    return completer.future;
  }

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
        if (response.statusCode == 500 &&
            (response.body.contains("validation failed") ||
                response.body.contains("Path `product` is required"))) {
          debugPrint(
            "[CartService] Corrupted cart document detected on server. Self-healing...",
          );
          await clear(syncWithServer: true);
        }
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

    for (var item in items) {
      final vId = item['variantId'] as String;
      final targetQty = _optimisticTargetQty[vId] ?? 0;
      _scheduleSync(vId, targetQty, oldItems);
    }

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
    } else {
      _items[index].qty = newQty;
    }
    notifyListeners();

    _scheduleSync(variantId, newQty, oldItems);

    return _pendingSyncTask;
  }

  Future<void> removeItem(String variantId) async {
    final index = _items.indexWhere((it) => it.variantId == variantId);
    if (index == -1) return;

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
    notifyListeners();

    _scheduleSync(variantId, 0, oldItems);

    return _pendingSyncTask;
  }

  void _scheduleSync(String variantId, int targetQty, List<CartItem> backup) {
    // 1. Capture backup if we are starting a new batch
    if (_pendingSyncUpdates.isEmpty) {
      _pendingSyncCompleter = Completer<void>();
      _pendingSyncTask = _pendingSyncCompleter!.future;
    }

    // Capture true backup for this variant if a sync sequence is starting for it
    if (!_inFlightSyncCounts.containsKey(variantId)) {
      final backupItemIndex = backup.indexWhere((it) => it.variantId == variantId);
      if (backupItemIndex != -1) {
        final item = backup[backupItemIndex];
        _trueBackupItems[variantId] = CartItem(
          itemId: item.itemId,
          productId: item.productId,
          variantId: item.variantId,
          productName: item.productName,
          productImage: item.productImage,
          technicalName: item.technicalName,
          variant: item.variant,
          price: item.price,
          qty: item.qty,
          isFree: item.isFree,
        );
      } else {
        _trueBackupItems[variantId] = null;
      }
    }

    // 2. Track this update
    _pendingSyncUpdates[variantId] = targetQty;
    _optimisticTargetQty[variantId] = targetQty;

    // 3. Manage in-flight state: cancel any existing pending timers
    if (_updateDebounceTimers.containsKey(variantId)) {
      _updateDebounceTimers[variantId]?.cancel();
    }

    // 4. Set/Reset global debounce timer
    // If the variant isn't in the cart yet, use a faster debounce (50ms) to add it instantly
    final isNewItem = !_variantToItemId.containsKey(variantId);
    final delayMs = isNewItem ? 50 : 150;

    _updateDebounceTimers[variantId] = Timer(Duration(milliseconds: delayMs), () {
      _updateDebounceTimers.remove(variantId);

      // If this is the last pending timer to fire in this batch, execute the sync!
      if (_updateDebounceTimers.isEmpty) {
        final updatesToSync = Map<String, int>.from(_pendingSyncUpdates);
        final currentCompleter = _pendingSyncCompleter;

        _pendingSyncUpdates.clear();
        _pendingSyncCompleter = null;

        // Increment in-flight status for all variants in this batch right before enqueuing
        for (final vId in updatesToSync.keys) {
          _incrementInFlight(vId);
        }
        notifyListeners();

        _enqueueSync(() async {
          final stopwatch = Stopwatch()..start();
          try {
            final List<Map<String, dynamic>> itemsPayload = [];
            updatesToSync.forEach((vId, qty) {
              // Only sync if this is still the latest target quantity the user wanted
              if (_optimisticTargetQty[vId] == qty) {
                itemsPayload.add({
                  'variantId': vId,
                  'quantity': qty,
                });
              } else {
                debugPrint(
                  "[Cart API] Skipping obsolete sync for $vId: queued $qty, current ${_optimisticTargetQty[vId]}",
                );
              }
            });

            if (itemsPayload.isEmpty) {
              debugPrint(
                "[Cart API] Skipping batch sync request because all items are obsolete.",
              );
              return;
            }

            final response = await HttpService.post(
              ApiConstants.cartSync,
              body: {'items': itemsPayload},
            ).timeout(const Duration(seconds: 10));
            stopwatch.stop();
            debugPrint(
              "[Cart API] Batch Sync of ${itemsPayload.length} items took ${stopwatch.elapsedMilliseconds}ms",
            );

            if (response.statusCode == 429) {
              debugPrint("[Cart API] Sync rate-limited (429). Keeping local changes.");
              return;
            }

            if (response.statusCode >= 500) {
              debugPrint("[Cart API] Server error (${response.statusCode}). Keeping local changes.");
              return;
            }

            if (response.statusCode != 200 && response.statusCode != 201) {
              throw Exception("Failed to sync cart: ${response.statusCode}");
            }

            final data = jsonDecode(response.body);
            final cartMap = data is Map ? (data['cart'] ?? data) : null;
            if (cartMap != null) {
              _updateCartFromJson(cartMap);
            } else {
              await syncWithBackend();
            }
          } catch (e) {
            debugPrint("Error in Batch Sync: $e");
            // Check for temporary network or timeout issues
            final isNetworkError = e is TimeoutException ||
                e.toString().contains('SocketException') ||
                e.toString().contains('HandshakeException') ||
                e.toString().contains('ClientException') ||
                e.toString().contains('NetworkIsUnreachable') ||
                e.toString().contains('ConnectionTimedOut');

            if (isNetworkError) {
              debugPrint("[Cart API] Network error. Keeping optimistic changes locally.");
            } else {
              // Rollback only the variants in this batch that don't have newer updates
              for (final vId in updatesToSync.keys) {
                final hasNewerUpdate = (_inFlightSyncCounts[vId] ?? 0) > 1 || _updateDebounceTimers.containsKey(vId);
                if (!hasNewerUpdate) {
                  final localItemIndex = _items.indexWhere((it) => it.variantId == vId);
                  if (_trueBackupItems.containsKey(vId)) {
                    final backupItem = _trueBackupItems[vId];
                    if (backupItem != null) {
                      if (localItemIndex != -1) {
                        _items[localItemIndex].qty = backupItem.qty;
                      } else {
                        _items.add(backupItem);
                      }
                    } else {
                      if (localItemIndex != -1) {
                        _items.removeAt(localItemIndex);
                      }
                    }
                  }
                }
              }
              notifyListeners();
            }
          } finally {
            // Decrement in-flight count for all synced variants
            for (final vId in updatesToSync.keys) {
              _decrementInFlight(vId);
              if (!_inFlightSyncCounts.containsKey(vId) && !_updateDebounceTimers.containsKey(vId)) {
                _optimisticTargetQty.remove(vId);
                _trueBackupItems.remove(vId);
              }
            }
            notifyListeners();
            if (currentCompleter != null && !currentCompleter.isCompleted) {
              currentCompleter.complete();
            }
          }
        });
      }
    });
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

    // Populate variantId to itemId map
    _variantToItemId.clear();
    for (var item in parsedItems) {
      if (item.itemId != null && item.itemId!.isNotEmpty) {
        _variantToItemId[item.variantId] = item.itemId!;
      }
    }

    // Update _trueBackupItems with latest server quantities
    for (var item in parsedItems) {
      final vId = item.variantId;
      if (_trueBackupItems.containsKey(vId)) {
        _trueBackupItems[vId] = CartItem(
          itemId: item.itemId,
          productId: item.productId,
          variantId: item.variantId,
          productName: item.productName,
          productImage: item.productImage,
          technicalName: item.technicalName,
          variant: item.variant,
          price: item.price,
          qty: item.qty,
          isFree: item.isFree,
        );
      }
    }
    // If a variant is in _trueBackupItems but NOT in parsedItems, it means it's not in the cart on the server.
    for (final vId in _trueBackupItems.keys) {
      final existsOnServer = parsedItems.any((it) => it.variantId == vId);
      if (!existsOnServer) {
        _trueBackupItems[vId] = null;
      }
    }

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

      if (activeSyncingIds.contains(vId)) {
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

      if (activeSyncingIds.contains(vId) &&
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

  Future<void> clear({bool syncWithServer = true}) async {
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

    if (syncWithServer) {
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
}
