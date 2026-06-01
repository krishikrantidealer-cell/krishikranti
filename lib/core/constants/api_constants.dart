class ApiConstants {
  static const String baseUrl = 'https://krishi-backend-123180953109.asia-south1.run.app';

  // Auth Endpoints
  static const String sendOtp = '$baseUrl/api/auth/send-otp';
  static const String verifyOtp = '$baseUrl/api/auth/verify-otp';
  static const String refreshToken = '$baseUrl/api/auth/refresh';
  static const String register = '$baseUrl/api/users/complete-profile';

  // Product Endpoints
  static const String products = '$baseUrl/api/products';
  static const String categories = '$baseUrl/api/products/categories';
  static const String homeDiscovery = '$baseUrl/api/products/discovery';
  static String productDetail(String id) => '$baseUrl/api/products/$id';

  // Notifications
  static const String fcmToken = '$baseUrl/api/users/fcm-token';

  // Cart & Coupon Endpoints
  static const String cart = '$baseUrl/api/cart';
  static const String cartItems = '$baseUrl/api/cart/items';
  static const String applyCoupon = '$baseUrl/api/cart/coupon';
  static const String activeCoupons = '$baseUrl/api/coupons/active';

  // Orders
  static const String orders = '$baseUrl/api/orders';

  // KYC & Profile
  static const String kyc = '$baseUrl/api/users/kyc';
  static const String profile = '$baseUrl/api/users/profile';
  static const String addresses = '$baseUrl/api/users/addresses';
  static String address(String id) => '$baseUrl/api/users/addresses/$id';
  static String addressDefault(String id) =>
      '$baseUrl/api/users/addresses/$id/default';

  // Favourites
  static const String favourites = '$baseUrl/api/favourites';

  // Collections
  static const String collections = '$baseUrl/api/collections';
  static const String collectionsWithProducts =
      '$baseUrl/api/collections/products';
}
