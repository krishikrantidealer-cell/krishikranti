class ApiConstants {
  static const String baseUrl = 'https://backend-krishi.onrender.com';

  // Auth Endpoints
  static const String sendOtp = '$baseUrl/api/auth/send-otp';
  static const String verifyOtp = '$baseUrl/api/auth/verify-otp';
  static const String refreshToken = '$baseUrl/api/auth/refresh-token';
  static const String register = '$baseUrl/api/users/complete-profile';

  // Product Endpoints
  static const String products = '$baseUrl/api/products';
  static String productDetail(String id) => '$baseUrl/api/products/$id';

  // Cart & Coupon Endpoints
  static const String cartItems = '$baseUrl/api/cart/items';
  static const String applyCoupon = '$baseUrl/api/cart/coupon';

  // Orders
  static const String orders = '$baseUrl/api/orders';

  // KYC & Profile
  static const String kyc = '$baseUrl/api/users/kyc';
  static const String profile = '$baseUrl/api/users/profile';
}
