import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter_facebook_app_links/flutter_facebook_app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MetaAnalyticsService {
  static final FacebookAppEvents _facebookAppEvents = FacebookAppEvents();

  /// Keys for SharedPreferences
  static const String _installSourceKey = 'meta_install_source';
  static const String _deepLinkUrlKey = 'meta_deeplink_url';

  /// Initializes the Meta SDK and checks for deferred deep links (attribution)
  static Future<void> initialize() async {
    try {
      debugPrint("📢 Initializing Meta SDK...");

      // 1. Enable advertiser tracking (essential for iOS App Tracking Transparency)
      await _facebookAppEvents.setAdvertiserTracking(enabled: true);

      // 2. Retrieve deferred deep link to check install attribution (ads vs organic)
      final prefs = await SharedPreferences.getInstance();

      // We only check and set the install source once, during the very first app launch
      if (!prefs.containsKey(_installSourceKey)) {
        String? deepLinkUrl;

        try {
          // Initialize Facebook App Links (Deferred Deep Link)
          deepLinkUrl = await FlutterFacebookAppLinks.initFBLinks();

          // On iOS, sometimes we need to call getDeepLink explicitly
          if (Platform.isIOS && (deepLinkUrl == null || deepLinkUrl.isEmpty)) {
            deepLinkUrl = await FlutterFacebookAppLinks.getDeepLink();
          }
        } catch (e) {
          debugPrint("⚠️ Meta SDK: Error fetching deferred deep link: $e");
        }

        if (deepLinkUrl != null && deepLinkUrl.isNotEmpty) {
          debugPrint(
            "🎯 Meta SDK: Attribution source found! User came from ads/campaign. Deep Link: $deepLinkUrl",
          );

          await prefs.setString(_installSourceKey, 'Meta Ads');
          await prefs.setString(_deepLinkUrlKey, deepLinkUrl);

          // Log attribution event to Facebook
          await _facebookAppEvents.logEvent(
            name: 'meta_ad_install_attribution',
            parameters: {'deeplink': deepLinkUrl},
          );
        } else {
          debugPrint(
            "🌱 Meta SDK: No deep link found. User marked as Organic install.",
          );
          await prefs.setString(_installSourceKey, 'Organic');
        }
      } else {
        final existingSource = prefs.getString(_installSourceKey);
        final existingLink = prefs.getString(_deepLinkUrlKey);
        debugPrint(
          "ℹ️ Meta SDK: Existing install source is '$existingSource' ${existingLink != null ? '(Link: $existingLink)' : ''}",
        );
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Meta SDK: Error during initialization: $e\n$stackTrace");
    }
  }

  /// Logs a custom event
  static Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      // Facebook App Events only supports String, num, or bool values in parameters
      final Map<String, dynamic> formattedParams = {};
      if (parameters != null) {
        parameters.forEach((key, value) {
          if (value is String || value is num || value is bool) {
            formattedParams[key] = value;
          } else {
            formattedParams[key] = value.toString();
          }
        });
      }

      await _facebookAppEvents.logEvent(
        name: name,
        parameters: formattedParams,
      );
      debugPrint(
        "📊 Meta SDK logged event: $name with parameters: $formattedParams",
      );
    } catch (e) {
      debugPrint("⚠️ Meta SDK: Failed to log event $name: $e");
    }
  }

  /// Logs when a product is added to the cart
  static Future<void> logAddToCart({
    required String productId,
    required String productName,
    required double price,
    int quantity = 1,
  }) async {
    try {
      await _facebookAppEvents.logAddToCart(
        id: productId,
        type: 'product',
        price: price,
        currency: 'INR',
        parameters: {
          'product_name': productName,
          'quantity': quantity,
        },
      );
      debugPrint("📊 Meta SDK: Logged AddToCart for $productName ($productId), price: $price, qty: $quantity");
    } catch (e) {
      debugPrint("⚠️ Meta SDK: Failed to log AddToCart: $e");
    }
  }

  /// Logs when checkout is initiated
  static Future<void> logInitiateCheckout({
    required double totalAmount,
    required int itemCount,
  }) async {
    try {
      await _facebookAppEvents.logInitiatedCheckout(
        totalPrice: totalAmount,
        currency: 'INR',
        numItems: itemCount,
      );
      debugPrint("📊 Meta SDK: Logged InitiateCheckout, total: $totalAmount, items: $itemCount");
    } catch (e) {
      debugPrint("⚠️ Meta SDK: Failed to log InitiateCheckout: $e");
    }
  }

  /// Logs when a purchase is completed (Revenue)
  static Future<void> logPurchase({
    required double amount,
    required String orderId,
  }) async {
    try {
      await _facebookAppEvents.logPurchase(
        amount: amount,
        currency: 'INR',
        parameters: {
          'order_id': orderId,
        },
      );
      debugPrint("📊 Meta SDK: Logged Purchase of amount: $amount, orderId: $orderId");
    } catch (e) {
      debugPrint("⚠️ Meta SDK: Failed to log Purchase: $e");
    }
  }

  /// Logs when a new user registers
  static Future<void> logCompletedRegistration({
    required String registrationMethod,
  }) async {
    try {
      await _facebookAppEvents.logCompletedRegistration(
        registrationMethod: registrationMethod,
      );
      debugPrint("📊 Meta SDK: Logged CompletedRegistration with method: $registrationMethod");
    } catch (e) {
      debugPrint("⚠️ Meta SDK: Failed to log CompletedRegistration: $e");
    }
  }

  /// Logs when a product details page is viewed
  static Future<void> logViewProduct({
    required String productId,
    required String productName,
    required double price,
  }) async {
    try {
      await _facebookAppEvents.logViewContent(
        id: productId,
        type: 'product',
        price: price,
        currency: 'INR',
        parameters: {
          'product_name': productName,
        },
      );
      debugPrint("📊 Meta SDK: Logged ViewProduct for $productName ($productId)");
    } catch (e) {
      debugPrint("⚠️ Meta SDK: Failed to log ViewProduct: $e");
    }
  }

  /// Logs when a search is performed
  static Future<void> logSearch({
    required String query,
    bool success = true,
  }) async {
    try {
      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_search',
        parameters: {
          'fb_search_string': query,
          'fb_success': success ? 1 : 0,
        },
      );
      debugPrint("📊 Meta SDK: Logged Search for '$query', success: $success");
    } catch (e) {
      debugPrint("⚠️ Meta SDK: Failed to log Search: $e");
    }
  }

  /// Logs a custom event for abandoned checkout
  static Future<void> logAbandonedCheckout({
    required double totalAmount,
    required int itemCount,
  }) async {
    await logEvent(
      name: 'abandoned_checkout',
      parameters: {
        'total_amount': totalAmount,
        'item_count': itemCount,
      },
    );
    debugPrint("📊 Meta SDK: Logged Abandoned Checkout with total amount: $totalAmount, items: $itemCount");
  }

  /// Logs when a product is added to wishlist/favorites
  static Future<void> logAddToWishlist({
    required String productId,
    required String productName,
    required double price,
  }) async {
    try {
      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_add_to_wishlist',
        parameters: {
          'fb_content_id': productId,
          'fb_content_type': 'product',
          'fb_content': productName,
          'fb_price': price,
          'fb_currency': 'INR',
        },
      );
      debugPrint("📊 Meta SDK: Logged AddToWishlist for $productName ($productId)");
    } catch (e) {
      debugPrint("⚠️ Meta SDK: Failed to log AddToWishlist: $e");
    }
  }

  /// Logs when a product is shared
  static Future<void> logShare({
    required String productId,
    required String productName,
  }) async {
    try {
      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_share',
        parameters: {
          'fb_content_id': productId,
          'fb_content_type': 'product',
          'fb_content': productName,
        },
      );
      debugPrint("📊 Meta SDK: Logged Share for $productName ($productId)");
    } catch (e) {
      debugPrint("⚠️ Meta SDK: Failed to log Share: $e");
    }
  }

  /// Logs when an item is removed from cart
  static Future<void> logRemoveFromCart({
    required String productId,
    required String productName,
    required double price,
  }) async {
    try {
      await _facebookAppEvents.logEvent(
        name: 'remove_from_cart',
        parameters: {
          'product_id': productId,
          'product_name': productName,
          'price': price,
        },
      );
      debugPrint("📊 Meta SDK: Logged RemoveFromCart for $productName ($productId)");
    } catch (e) {
      debugPrint("⚠️ Meta SDK: Failed to log RemoveFromCart: $e");
    }
  }

  /// Logs when a coupon code is applied
  static Future<void> logApplyCoupon({
    required String couponCode,
    required double discountAmount,
  }) async {
    try {
      await _facebookAppEvents.logEvent(
        name: 'apply_coupon',
        parameters: {
          'coupon_code': couponCode,
          'discount_amount': discountAmount,
        },
      );
      debugPrint("📊 Meta SDK: Logged ApplyCoupon code: $couponCode, discount: $discountAmount");
    } catch (e) {
      debugPrint("⚠️ Meta SDK: Failed to log ApplyCoupon: $e");
    }
  }

  /// Logs when a user submits eKYC documents
  static Future<void> logKycSubmitted({
    required String kycType,
  }) async {
    try {
      await _facebookAppEvents.logEvent(
        name: 'kyc_submitted',
        parameters: {
          'kyc_type': kycType,
        },
      );
      debugPrint("📊 Meta SDK: Logged KYC Submitted with type: $kycType");
    } catch (e) {
      debugPrint("⚠️ Meta SDK: Failed to log KYC Submitted: $e");
    }
  }

  /// Logs when contact support is clicked
  static Future<void> logContactSupport({
    required String contactMethod, // 'Call', 'WhatsApp', etc.
  }) async {
    try {
      await _facebookAppEvents.logEvent(
        name: 'contact_support',
        parameters: {
          'contact_method': contactMethod,
        },
      );
      debugPrint("📊 Meta SDK: Logged Contact Support via: $contactMethod");
    } catch (e) {
      debugPrint("⚠️ Meta SDK: Failed to log Contact Support: $e");
    }
  }

  /// Logs when a user logs in
  static Future<void> logLogin({
    String loginMethod = 'OTP',
  }) async {
    try {
      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_login',
        parameters: {
          'fb_registration_method': loginMethod,
        },
      );
      debugPrint("📊 Meta SDK: Logged Login with method: $loginMethod");
    } catch (e) {
      debugPrint("⚠️ Meta SDK: Failed to log Login: $e");
    }
  }

  /// Logs when a product category or collection is viewed
  static Future<void> logViewCategory({
    required String categoryName,
    String? categoryId,
    bool isCollection = false,
  }) async {
    try {
      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_content_view',
        parameters: {
          'fb_content_type': isCollection ? 'collection' : 'category',
          'fb_content_id': categoryId ?? '',
          'fb_content': categoryName,
        },
      );
      debugPrint("📊 Meta SDK: Logged ViewCategory: $categoryName, isCollection: $isCollection");
    } catch (e) {
      debugPrint("⚠️ Meta SDK: Failed to log ViewCategory: $e");
    }
  }

  /// Logs when checkout/payment fails
  static Future<void> logCheckoutFailure({
    required String reason,
    String code = 'unknown',
  }) async {
    try {
      await logEvent(
        name: 'checkout_failure',
        parameters: {
          'error_reason': reason,
          'error_code': code,
        },
      );
      debugPrint("📊 Meta SDK: Logged CheckoutFailure: $reason (Code: $code)");
    } catch (e) {
      debugPrint("⚠️ Meta SDK: Failed to log CheckoutFailure: $e");
    }
  }

  /// Logs when a notification is opened/tapped
  static Future<void> logNotificationOpen({
    String? title,
    String? category,
    String? actionRoute,
  }) async {
    try {
      await logEvent(
        name: 'notification_open',
        parameters: {
          'notification_title': title ?? 'unknown',
          'notification_category': category ?? 'utility',
          'action_route': actionRoute ?? 'none',
        },
      );
      debugPrint("📊 Meta SDK: Logged NotificationOpen: $title, category: $category, route: $actionRoute");
    } catch (e) {
      debugPrint("⚠️ Meta SDK: Failed to log NotificationOpen: $e");
    }
  }

  /// Logs when a user rates a product (Helper template for future use)
  static Future<void> logRateProduct({
    required String productId,
    required double rating,
    String? review,
  }) async {
    try {
      await logEvent(
        name: 'rate_product',
        parameters: {
          'product_id': productId,
          'rating_value': rating,
          'review_text': review ?? '',
        },
      );
      debugPrint("📊 Meta SDK: Logged RateProduct for $productId, rating: $rating");
    } catch (e) {
      debugPrint("⚠️ Meta SDK: Failed to log RateProduct: $e");
    }
  }

  /// Helper to get cached install source ('Meta Ads' or 'Organic')
  static Future<String> getInstallSource() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_installSourceKey) ?? 'Organic';
  }

  /// Helper to get cached deep link URL (if any)
  static Future<String?> getDeepLinkUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deepLinkUrlKey);
  }
}
