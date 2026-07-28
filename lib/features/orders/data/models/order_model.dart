class Order {
  final String id;
  final String orderId;
  final List<OrderItem> items;
  final double totalAmount;
  final double discountAmount;
  final String? couponCode;
  final List<FreeItem> freeItems;
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
    required this.freeItems,
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

  static String _parseId(dynamic id) {
    if (id == null) return '';
    if (id is String) return id;
    if (id is Map && id.containsKey('\$oid')) return id['\$oid'].toString();
    return id.toString();
  }

  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is String) return DateTime.tryParse(date)?.toLocal();
    if (date is Map && date.containsKey('\$date')) {
      final dateVal = date['\$date'];
      if (dateVal is String) return DateTime.tryParse(dateVal)?.toLocal();
      if (dateVal is num) {
        return DateTime.fromMillisecondsSinceEpoch(dateVal.toInt()).toLocal();
      }
    }
    return null;
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: _parseId(json['_id']),
      orderId: json['orderId'] ?? '',
      items:
          (json['items'] as List?)
              ?.map((i) => OrderItem.fromJson(i))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      couponCode: json['couponCode'],
      freeItems:
          (json['freeItems'] as List?)
              ?.map((i) => FreeItem.fromJson(i))
              .toList() ??
          [],
      shippingAddress: ShippingAddress.fromJson(json['shippingAddress'] ?? {}),
      paymentMethod: json['paymentMethod'] ?? 'Online',
      paymentStatus: json['paymentStatus'] ?? 'Pending',
      orderStatus: json['orderStatus'] ?? 'Processing',
      createdAt:
          _parseDate(json['createdAt']) ??
          _parseDate(json['placedAt']) ??
          DateTime.now(),
      awbNumber: json['awbNumber'],
      courierName: json['courierName'],
      trackingUrl: json['trackingUrl'],
      advanceAmount:
          json['advanceAmount'] != null
              ? (json['advanceAmount'] as num).toDouble()
              : null,
      remainingAmount:
          json['remainingAmount'] != null
              ? (json['remainingAmount'] as num).toDouble()
              : null,
      placedAt: _parseDate(json['placedAt']),
      processingAt: _parseDate(json['processingAt']),
      shippedAt: _parseDate(json['shippedAt']),
      outForDeliveryAt: _parseDate(json['outForDeliveryAt']),
      deliveredAt: _parseDate(json['deliveredAt']),
      cancelledAt: _parseDate(json['cancelledAt']),
      rtoAt: _parseDate(json['rtoAt']),
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
  final String variant;

  OrderItem({
    required this.id,
    required this.productId,
    required this.variantId,
    required this.title,
    this.image,
    required this.quantity,
    required this.price,
    required this.variant,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final vId = Order._parseId(json['variantId']);
    String variantName = json['variant'] ?? 'Standard';

    if ((variantName == 'Standard' || variantName.isEmpty) && json['product'] is Map && json['product']['variants'] != null) {
      final variants = json['product']['variants'] as List;
      final v = variants.firstWhere(
        (v) => v is Map && Order._parseId(v['_id']) == vId,
        orElse: () => null,
      );
      if (v != null && v is Map) {
        variantName = v['size'] ?? 'Standard';
      }
    }

    return OrderItem(
      id: Order._parseId(json['_id']),
      productId: json['product'] is Map
          ? Order._parseId(json['product']['_id'])
          : Order._parseId(json['product']),
      variantId: vId,
      title: json['title'] ?? '',
      image: json['image'],
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
      variant: variantName,
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

class FreeItem {
  final String name;
  final String? imageUrl;
  final int quantity;
  final bool isFree;

  FreeItem({
    required this.name,
    this.imageUrl,
    required this.quantity,
    this.isFree = true,
  });

  factory FreeItem.fromJson(Map<String, dynamic> json) {
    return FreeItem(
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image'],
      quantity: json['quantity'] ?? 1,
      isFree: json['isFree'] ?? true,
    );
  }
}
