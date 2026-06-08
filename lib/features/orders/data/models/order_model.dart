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
  final double? advanceAmount;
  final double? remainingAmount;
  final DateTime? placedAt;
  final DateTime? processingAt;
  final DateTime? shippedAt;
  final DateTime? outForDeliveryAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final DateTime? rtoAt;
  final String? courierStatus;

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
    this.advanceAmount,
    this.remainingAmount,
    this.placedAt,
    this.processingAt,
    this.shippedAt,
    this.outForDeliveryAt,
    this.deliveredAt,
    this.cancelledAt,
    this.rtoAt,
    this.courierStatus,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'] ?? '',
      orderId: json['orderId'] ?? '',
      items:
          (json['items'] as List?)
              ?.map((i) => OrderItem.fromJson(i))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      couponCode: json['couponCode'],
      shippingAddress: ShippingAddress.fromJson(json['shippingAddress'] ?? {}),
      paymentMethod: json['paymentMethod'] ?? 'Online',
      paymentStatus: json['paymentStatus'] ?? 'Pending',
      orderStatus: json['orderStatus'] ?? 'Processing',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ).toLocal(),
      awbNumber: json['awbNumber'],
      courierName: json['courierName'],
      trackingUrl: json['trackingUrl'],
      advanceAmount: json['advanceAmount'] != null
          ? (json['advanceAmount'] as num).toDouble()
          : null,
      remainingAmount: json['remainingAmount'] != null
          ? (json['remainingAmount'] as num).toDouble()
          : null,
      placedAt: json['placedAt'] != null
          ? DateTime.parse(json['placedAt']).toLocal()
          : null,
      processingAt: json['processingAt'] != null
          ? DateTime.parse(json['placedAt'] ?? json['processingAt']).toLocal()
          : null,
      shippedAt: json['shippedAt'] != null
          ? DateTime.parse(json['shippedAt']).toLocal()
          : null,
      outForDeliveryAt: json['outForDeliveryAt'] != null
          ? DateTime.parse(json['outForDeliveryAt']).toLocal()
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt']).toLocal()
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt']).toLocal()
          : null,
      rtoAt: json['rtoAt'] != null
          ? DateTime.parse(json['rtoAt']).toLocal()
          : null,
      courierStatus: json['courierStatus'],
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
      productId: json['product'] is Map
          ? (json['product']['_id'] ?? '')
          : (json['product'] ?? ''),
      variantId: json['variantId'] ?? '',
      title: json['title'] ?? '',
      image: json['image'],
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}

class ShippingAddress {
  final String? name;
  final String? phoneNumber;
  final String? villageArea;
  final String? cityTehsil;
  final String? state;
  final String? pincode;

  ShippingAddress({
    this.name,
    this.phoneNumber,
    this.villageArea,
    this.cityTehsil,
    this.state,
    this.pincode,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      villageArea: json['villageArea'],
      cityTehsil: json['cityTehsil'],
      state: json['state'],
      pincode: json['pincode'],
    );
  }
}
