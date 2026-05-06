import 'package:flutter/foundation.dart';
import 'dart:convert';
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
    syncWithBackend();
  }

  List<CartItem> _items = [];
  String? _appliedCoupon;
  double _discountAmount = 0;
  bool _isLoading = false;
  Future<void>? _pendingSyncTask;

  List<CartItem> get items => _items;
  String? get appliedCoupon => _appliedCoupon;
  double get discountAmount => _discountAmount;
  bool get isLoading => _isLoading;
  Future<void>? get pendingSyncTask => _pendingSyncTask;

  Future<void> syncWithBackend() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await HttpService.get(ApiConstants.cart);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle both wrapped {cart: {...}} and direct {...} responses
        final cartMap = data is Map ? (data['cart'] ?? data) : null;

        if (cartMap != null) {
          final List itemsJson = cartMap['items'] ?? [];
          final List freeItemsJson = cartMap['freeItems'] ?? [];

          final List<CartItem> parsedItems = itemsJson
              .map((j) => CartItem.fromJson(j))
              .toList();
          final List<CartItem> parsedFreeItems = freeItemsJson
              .map((j) => CartItem.fromJson(j, isFree: true))
              .toList();

          _items = [...parsedItems, ...parsedFreeItems];
          _appliedCoupon = cartMap['appliedCoupon'];
          _discountAmount = CartItem._parseDouble(cartMap['discountAmount']);
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
    // 1. Optimistic UI
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

    // 2. Sync with Backend using the batch "variants" array
    _pendingSyncTask = _performAddSync(productId, items, isReplace, sync);
    return _pendingSyncTask;
  }

  Future<void> _performAddSync(
    String productId,
    List<Map<String, dynamic>> items,
    bool isReplace,
    bool sync,
  ) async {
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

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("Failed to sync cart items");
      }

      if (sync) await syncWithBackend();
    } catch (e) {
      debugPrint("Batch add error: $e");
      rethrow;
    } finally {
      _pendingSyncTask = null;
    }
  }

  Future<void> updateQty(int index, int newQty) async {
    if (index < 0 || index >= _items.length) return;
    final item = _items[index];

    // 1. Optimistic UI update
    if (newQty <= 0) {
      _items.removeAt(index);
    } else {
      item.qty = newQty;
    }
    notifyListeners();

    // 2. Sync with Backend
    try {
      // If the item doesn't have a backend ID yet (still syncing from 'add'),
      // we wait a moment or trigger a sync to get the ID.
      String? itemId = item.itemId;
      if (itemId == null) {
        await syncWithBackend();
        // Re-find the item after sync to get the new ID
        final syncedItem = _items.firstWhere(
          (it) =>
              it.productId == item.productId && it.variantId == item.variantId,
          orElse: () => item,
        );
        itemId = syncedItem.itemId;
      }

      if (itemId != null) {
        final response = await HttpService.patch(
          "${ApiConstants.cartItems}/$itemId",
          body: {'quantity': newQty},
        );

        if (response.statusCode != 200) {
          throw Exception("Failed to update quantity");
        }
      }
    } catch (_) {
      // On failure, restore the original state to keep DB and UI in sync
      await syncWithBackend();
    }
  }

  Future<void> removeItem(int index) async {
    if (index < 0 || index >= _items.length) return;
    final item = _items[index];

    // 1. Optimistic
    _items.removeAt(index);
    notifyListeners();

    // 2. Sync
    try {
      String? itemId = item.itemId;
      if (itemId == null) {
        await syncWithBackend();
        return;
      }

      await HttpService.delete("${ApiConstants.cartItems}/$itemId");
    } catch (_) {
      await syncWithBackend();
    }
  }

  Future<void> applyCoupon(String code) async {
    try {
      final response = await HttpService.post(
        ApiConstants.applyCoupon,
        body: {'code': code},
      );
      if (response.statusCode == 200) {
        await syncWithBackend();
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to apply coupon');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeCoupon() async {
    try {
      final response = await HttpService.delete(ApiConstants.applyCoupon);
      if (response.statusCode == 200) {
        await syncWithBackend();
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to remove coupon');
      }
    } catch (e) {
      rethrow;
    }
  }

  double get subtotal =>
      _items.fold(0, (sum, item) => sum + (item.price * item.qty));
  double get totalAmount => subtotal - _discountAmount;

  int get totalCount => _items.fold(0, (sum, item) => sum + item.qty);

  Future<void> clear() async {
    // 1. Optimistic
    _items.clear();
    _appliedCoupon = null;
    _discountAmount = 0;
    notifyListeners();

    // 2. Sync
    try {
      await HttpService.delete(ApiConstants.cart);
    } catch (_) {
      await syncWithBackend();
    }
  }
}
