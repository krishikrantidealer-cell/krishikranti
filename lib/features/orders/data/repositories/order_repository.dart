import 'dart:convert';
import 'package:krishikranti/core/constants/api_constants.dart';
import 'package:krishikranti/core/network/http_service.dart';
import 'package:krishikranti/features/orders/data/models/order_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderRepository {
  static final Map<String, Future<List<Order>>> _ordersCache = {};
  static SharedPreferences? _prefs;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<List<Order>> getMyOrders({bool forceRefresh = false}) async {
    const cacheKey = 'persistent_my_orders';
    await _initPrefs();

    // 1. Memory Cache
    if (!forceRefresh && _ordersCache.containsKey(cacheKey)) {
      return await _ordersCache[cacheKey]!;
    }

    // 2. Disk Cache
    if (!forceRefresh) {
      final diskData = _prefs?.getString(cacheKey);
      if (diskData != null) {
        try {
          final List decoded = jsonDecode(diskData);
          final orders = decoded.map((j) => Order.fromJson(j)).toList();
          _ordersCache[cacheKey] = Future.value(orders);
          return orders;
        } catch (_) {}
      }
    }

    // 3. Fresh Fetch
    final fetchFuture = _fetchOrdersInternal(cacheKey);
    _ordersCache[cacheKey] = fetchFuture;
    return await fetchFuture;
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

  Future<Order> placeOrder({
    required String paymentMethod,
    required Map<String, dynamic> shippingAddress,
  }) async {
    try {
      final response = await HttpService.post(
        ApiConstants.orders,
        body: {
          'paymentMethod': paymentMethod,
          'shippingAddress': shippingAddress,
        },
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data['order']);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to place order');
      }
    } catch (e) {
      rethrow;
    }
  }
}
