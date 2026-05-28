import 'dart:convert';
import 'package:krishikranti/core/constants/api_constants.dart';
import 'package:krishikranti/core/network/http_service.dart';
import 'package:krishikranti/core/dynamic_translation_service.dart';

class Coupon {
  final String id;
  final String code;
  final String discountType;
  final double discountValue;
  final double minimumPurchaseAmount;
  final bool isFirstOrderOnly;
  final String? freeProductId;
  final int freeProductQuantity;
  final String? applicableCollections;

  Coupon({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minimumPurchaseAmount,
    required this.isFirstOrderOnly,
    this.freeProductId,
    this.freeProductQuantity = 1,
    this.applicableCollections,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['_id'] ?? '',
      code: json['code'] ?? '',
      discountType: json['discountType'] ?? '',
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      minimumPurchaseAmount: (json['minimumPurchaseAmount'] ?? 0).toDouble(),
      isFirstOrderOnly: json['isFirstOrderOnly'] ?? false,
      freeProductId: json['freeProductId'],
      freeProductQuantity: json['freeProductQuantity'] ?? 1,
      applicableCollections: json['applicableCollections'],
    );
  }

  String get description {
    if (discountType == 'Percentage') {
      return 'Get ${discountValue.toStringAsFixed(0)}% OFF on your order';
    } else if (discountType == 'Absolute') {
      return 'Get flat ₹${discountValue.toStringAsFixed(0)} OFF on your order';
    } else if (discountType == 'FreeProduct') {
      return 'Get a FREE product with this coupon';
    }
    return 'Save more with this coupon';
  }
}

class CouponService {
  static Future<List<Coupon>> fetchActiveCoupons() async {
    try {
      final response = await HttpService.get(ApiConstants.activeCoupons);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> couponsJson = data['coupons'] ?? [];
        final coupons =
            couponsJson.map((json) => Coupon.fromJson(json)).toList();

        // Pre-warm translation cache for coupon descriptions
        DynamicTranslationService().ensureAllTranslated(
          coupons.map((c) => c.description).toList(),
        );

        return coupons;
      }
      return [];
    } catch (e) {
      print("Error fetching coupons: $e");
      return [];
    }
  }
}
