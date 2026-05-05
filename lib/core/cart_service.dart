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
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    final variantId = json['variantId'];
    
    // Find the variant details from the populated product if possible
    String variantName = "Standard";
    if (product != null && product['variants'] != null) {
      final v = (product['variants'] as List).firstWhere(
        (v) => v['_id'] == variantId, 
        orElse: () => null
      );
      if (v != null) variantName = v['size'] ?? "Standard";
    }

    return CartItem(
      itemId: json['_id'],
      productId: product?['_id'] ?? '',
      variantId: variantId ?? '',
      productName: product?['title'] ?? 'Product',
      productImage: (product?['images'] != null && (product['images'] as List).isNotEmpty)
          ? product['images'][0]
          : '',
      technicalName: product?['technicalName'] ?? 'Generic',
      variant: variantName,
      price: (json['price'] ?? 0).toDouble(),
      qty: json['quantity'] ?? 1,
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

  List<CartItem> get items => _items;
  String? get appliedCoupon => _appliedCoupon;
  double get discountAmount => _discountAmount;
  bool get isLoading => _isLoading;

  Future<void> syncWithBackend() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await HttpService.get(ApiConstants.cartItems);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cartData = data['cart'];
        if (cartData != null) {
          final List itemsJson = cartData['items'] ?? [];
          _items = itemsJson.map((j) => CartItem.fromJson(j)).toList();
          _appliedCoupon = cartData['appliedCoupon'];
          _discountAmount = (cartData['discountAmount'] ?? 0).toDouble();
        }
      }
    } catch (_) {
      // Offline or error, keep local state
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
  }) async {
    // 1. Optimistic UI
    int index = _items.indexWhere((item) => 
        item.productId == productId && item.variantId == variantId);

    if (index != -1) {
      _items[index].qty += qty;
    } else {
      _items.add(CartItem(
        productId: productId,
        variantId: variantId,
        productName: productName,
        productImage: productImage,
        technicalName: technicalName,
        variant: variant,
        price: price,
        qty: qty,
      ));
    }
    notifyListeners();

    // 2. Sync with Backend
    try {
      await HttpService.post(ApiConstants.cartItems, body: {
        'productId': productId,
        'variantId': variantId,
        'quantity': qty,
      });
      await syncWithBackend(); // Get real IDs from server
    } catch (e) {
      // Rollback not implemented for brevity
    }
  }

  Future<void> updateQty(int index, int newQty) async {
    if (index < 0 || index >= _items.length) return;
    final item = _items[index];
    final itemId = item.itemId;

    if (itemId == null) return;

    // 1. Optimistic
    if (newQty <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].qty = newQty;
    }
    notifyListeners();

    // 2. Sync
    try {
      await HttpService.patch("${ApiConstants.cartItems}/$itemId", body: {
        'quantity': newQty,
      });
    } catch (_) {
      await syncWithBackend(); // Restore state on error
    }
  }

  Future<void> removeItem(int index) async {
    if (index < 0 || index >= _items.length) return;
    final itemId = _items[index].itemId;
    if (itemId == null) return;

    // 1. Optimistic
    _items.removeAt(index);
    notifyListeners();

    // 2. Sync
    try {
      await HttpService.delete("${ApiConstants.cartItems}/$itemId");
    } catch (_) {
      await syncWithBackend();
    }
  }

  Future<void> applyCoupon(String code) async {
    try {
      final response = await HttpService.post(ApiConstants.applyCoupon, body: {'code': code});
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

  double get subtotal => _items.fold(0, (sum, item) => sum + (item.price * item.qty));
  double get totalAmount => subtotal - _discountAmount;

  int get totalCount => _items.fold(0, (sum, item) => sum + item.qty);

  Future<void> clear() async {
    _items.clear();
    _appliedCoupon = null;
    _discountAmount = 0;
    notifyListeners();

    try {
      await HttpService.delete(ApiConstants.cartItems);
    } catch (_) {}
  }
}
