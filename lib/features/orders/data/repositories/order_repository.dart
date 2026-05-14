import 'dart:convert';
import 'package:krishikranti/core/constants/api_constants.dart';
import 'package:krishikranti/core/network/http_service.dart';
import 'package:krishikranti/features/orders/data/models/order_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderRepository {
  static final Map<String, Future<List<Order>>> _ordersCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 5);
  static SharedPreferences? _prefs;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<List<Order>> getMyOrders({bool forceRefresh = false}) async {
    const cacheKey = 'persistent_my_orders';
    await _initPrefs();

    // On forceRefresh: evict memory and disk cache first
    if (forceRefresh) {
      _ordersCache.remove(cacheKey);
      _cacheTimestamps.remove(cacheKey);
      await _prefs?.remove(cacheKey);
    }

    // 1. Memory Cache with TTL
    if (_ordersCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheDuration) {
        return await _ordersCache[cacheKey]!;
      }
    }

    // 2. Disk Cache
    final diskData = _prefs?.getString(cacheKey);
    if (diskData != null) {
      try {
        final List decoded = jsonDecode(diskData);
        final orders = decoded.map((j) => Order.fromJson(j)).toList();
        _ordersCache[cacheKey] = Future.value(orders);
        _cacheTimestamps[cacheKey] = DateTime.now();
        return orders;
      } catch (_) {}
    }

    // 3. Fresh Fetch
    final fetchFuture = _fetchOrdersInternal(cacheKey);
    _ordersCache[cacheKey] = fetchFuture;
    _cacheTimestamps[cacheKey] = DateTime.now();
    return await fetchFuture;
  }

  /// Invalidates the orders cache — call after placing a new order
  static Future<void> clearCache() async {
    _ordersCache.clear();
    _cacheTimestamps.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('persistent_my_orders');
  }

  Future<List<Order>> _fetchOrdersInternal(String cacheKey) async {
    try {
      final response = await HttpService.get(ApiConstants.orders);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List ordersJson = data['orders'] ?? [];

        // Persist
        await _initPrefs();
        _prefs?.setString(cacheKey, jsonEncode(ordersJson));

        return ordersJson.map((json) => Order.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Order> getOrderDetails(String id) async {
    try {
      final response = await HttpService.get("${ApiConstants.orders}/$id");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data['order']);
      } else {
        throw Exception('Failed to load order details');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> initializePayment({
    required String paymentMethod,
    int? partialPercent,
  }) async {
    try {
      final response = await HttpService.post(
        '${ApiConstants.orders}/initialize',
        body: {
          'paymentMethod': paymentMethod == 'online' ? 'Online' : 'Partial',
          if (partialPercent != null) 'partialPercent': partialPercent,
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data['razorpayOrder']);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to initialize payment');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Order> placeOrder({
    required String paymentMethod,
    required Map<String, dynamic> shippingAddress,
    String? razorpayPaymentId,
    String? razorpayOrderId,
    String? razorpaySignature,
    double? advanceAmount,
    double? remainingAmount,
  }) async {
    try {
      final response = await HttpService.post(
        ApiConstants.orders,
        body: {
          'paymentMethod': paymentMethod,
          'shippingAddress': shippingAddress,
          if (razorpayPaymentId != null) 'razorpayPaymentId': razorpayPaymentId,
          if (razorpayOrderId != null) 'razorpayOrderId': razorpayOrderId,
          if (razorpaySignature != null) 'razorpaySignature': razorpaySignature,
          if (advanceAmount != null) 'advanceAmount': advanceAmount,
          if (remainingAmount != null) 'remainingAmount': remainingAmount,
        },
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Invalidate cache so new order appears immediately next time
        await clearCache();
        return Order.fromJson(data['order']);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to place order');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Order> cancelOrder(String orderId) async {
    try {
      final response = await HttpService.post("${ApiConstants.orders}/$orderId/cancel");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await clearCache();
        return Order.fromJson(data['order']);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to cancel order');
      }
    } catch (e) {
      rethrow;
    }
  }
}
