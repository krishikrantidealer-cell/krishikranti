import 'package:flutter/foundation.dart';

class OrderItem {
  final String productName;
  final String productImage;
  final String variant;
  final double price;
  final int qty;

  OrderItem({
    required this.productName,
    required this.productImage,
    required this.variant,
    required this.price,
    required this.qty,
  });
}

class Order {
  final String orderId;
  final String date;
  final String status;
  final List<OrderItem> items;
  final double totalAmount;

  Order({
    required this.orderId,
    required this.date,
    required this.status,
    required this.items,
    required this.totalAmount,
  });
}

class OrderService extends ChangeNotifier {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final List<Order> _orders = [];
  List<Order> get orders => _orders;

  void placeOrder(List<CartItem> cartItems, double totalAmount) {
    final orderId = "#KD${10000 + _orders.length + 1}";
    final now = DateTime.now();
    final dateStr = "${now.day} ${_getMonth(now.month)} ${now.year}";

    final orderItems = cartItems.map((item) => OrderItem(
      productName: item.productName,
      productImage: item.productImage,
      variant: item.variant,
      price: item.price,
      qty: item.qty,
    )).toList();

    _orders.insert(0, Order(
      orderId: orderId,
      date: dateStr,
      status: "Processing",
      items: orderItems,
      totalAmount: totalAmount,
    ));
    notifyListeners();
  }

  String _getMonth(int month) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
  }
}

class CartItem {
  final String productId;
  final String productName;
  final String productImage;
  final String technicalName;
  final String variant;
  final double price;
  int qty;

  CartItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.technicalName,
    required this.variant,
    required this.price,
    required this.qty,
  });
}

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  void addItem({
    required String productId,
    required String productName,
    required String productImage,
    required String technicalName,
    required String variant,
    required double price,
    required int qty,
  }) {
    // Check if same product + same variant exists
    int index = _items.indexWhere((item) => 
        item.productId == productId && item.variant == variant);

    if (index != -1) {
      _items[index].qty += qty;
    } else {
      _items.add(CartItem(
        productId: productId,
        productName: productName,
        productImage: productImage,
        technicalName: technicalName,
        variant: variant,
        price: price,
        qty: qty,
      ));
    }
    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void updateQty(int index, int newQty) {
    if (index >= 0 && index < _items.length) {
      if (newQty <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].qty = newQty;
      }
      notifyListeners();
    }
  }

  double get totalAmount {
    return _items.fold(0, (sum, item) => sum + (item.price * item.qty));
   }

  int get totalCount {
    return _items.fold(0, (sum, item) => sum + item.qty);
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  void addToCart(String productName, double price, String productImage) {
    addItem(
      productId: productName,
      productName: productName,
      productImage: productImage,
      technicalName: "Generic",
      variant: "Standard",
      price: price,
      qty: 1,
    );
  }
}
