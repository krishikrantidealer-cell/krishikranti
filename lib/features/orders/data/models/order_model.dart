class Order {
  final String id;
  final String orderId;
  final List<OrderItem> items;
  final double totalAmount;
  final double discountAmount;
  final String? couponCode;
  final ShippingAddress shippingAddress;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final DateTime createdAt;
  final String? awbNumber;
  final String? courierName;
  final String? trackingUrl;

  Order({
    required this.id,
    required this.orderId,
    required this.items,
    required this.totalAmount,
    required this.discountAmount,
    this.couponCode,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.createdAt,
    this.awbNumber,
    this.courierName,
    this.trackingUrl,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'] ?? '',
      orderId: json['orderId'] ?? '',
      items: (json['items'] as List?)
              ?.map((i) => OrderItem.fromJson(i))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      couponCode: json['couponCode'],
      shippingAddress: ShippingAddress.fromJson(json['shippingAddress'] ?? {}),
      paymentMethod: json['paymentMethod'] ?? 'COD',
      paymentStatus: json['paymentStatus'] ?? 'Pending',
      orderStatus: json['orderStatus'] ?? 'Pending',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      awbNumber: json['awbNumber'],
      courierName: json['courierName'],
      trackingUrl: json['trackingUrl'],
    );
  }
}

class OrderItem {
  final String id;
  final String productId;
  final String variantId;
  final String title;
  final String? image;
  final int quantity;
  final double price;

  OrderItem({
    required this.id,
    required this.productId,
    required this.variantId,
    required this.title,
    this.image,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['_id'] ?? '',
      productId: json['product'] ?? '',
      variantId: json['variantId'] ?? '',
      title: json['title'] ?? '',
      image: json['image'],
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}

class ShippingAddress {
  final String? villageArea;
  final String? cityTehsil;
  final String? pincode;

  ShippingAddress({
    this.villageArea,
    this.cityTehsil,
    this.pincode,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      villageArea: json['villageArea'],
      cityTehsil: json['cityTehsil'],
      pincode: json['pincode'],
    );
  }
}
