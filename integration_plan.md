# 🚀 Master Integration Guide: Krishi Kranti ERP

This is the definitive guide for integrating the Flutter mobile app with the optimized, high-scale Node.js backend.

---

## 🔐 1. Authentication (OTP Flow)

The system uses a two-step OTP verification with **Master OTP** fallback for testing.

### Step A: Send OTP
**Endpoint**: `POST /api/auth/send-otp`  
**Body**: `{ "phoneNumber": "9876543210" }`

**Response**:
```json
{
  "success": true,
  "message": "OTP sent successfully",
  "cooldown": 60,
  "otp": "123456" // ONLY returned in Development mode
}
```
*   **Developer Note**: Disable the "Resend" button for **60 seconds** (`cooldown`).
*   **Validity**: The OTP is valid for **5 minutes**.

### Step B: Verify OTP
**Endpoint**: `POST /api/auth/verify-otp`  
**Body**: `{ "phoneNumber": "9876543210", "otp": "123456", "deviceId": "uuid-123" }`

**Master OTP**: In testing/live-without-SMS, use **`123456`**.

---

## 📦 2. Product Management (Big ERP Pattern)

We use a **Split-Collection** architecture for speed.

### A. Product Grid (Home/Category)
**Endpoint**: `GET /api/products?limit=20&cursor={nextCursor}`

**Performance Strategy**:
1.  **Image**: Use `thumbnail` (200x200 WebP). 
2.  **Pagination**: Use `nextCursor`. If `nextCursor` is null, you've reached the end.

### B. Product Details (Deep Load)
**Endpoint**: `GET /api/products/:id`

**Response Structure**:
```json
{
  "product": {
    "title": "Organic Urea",
    "thumbnail": "...", // Small
    "details": {
      "description": "Full HTML/Text description",
      "images": {
        "medium": ["url1", "url2"], // 600x600 for Carousel
        "original": ["url1", "url2"] // Full res for Zoom
      }
    }
  }
}
```

---

## 🛒 3. Cart & Smart Coupons

The backend is the "Source of Truth" for all calculations.

### A. Add to Cart
**Endpoint**: `POST /api/cart/items`
**Body**: 
```json
{
  "productId": "...",
  "variantsList": [{ "variantId": "...", "quantity": 2 }]
}
```

### B. Applied Logic (BOGO / Free Gifts)
When a coupon like `BUY1GET1` is applied via `POST /api/cart/coupon`, the response will include a `freeItems` array.
*   **Flutter**: Automatically show these items in the cart with a "FREE" badge.

---

## 💬 4. Reviews & Ratings
**Endpoint**: `GET /api/products/:id/reviews?limit=10&cursor={id}`

*   **Caching**: The first 10 reviews are cached in **Redis** (<10ms load time).
*   **Pagination**: Use `nextCursor` (which is the `_id` of the last review).

---

## 🚀 5. Flutter Performance Checklist

1.  **Image Caching**: Use `cached_network_image`. Google Cloud Storage URLs are perfect for this.
2.  **Debounce Search**: Wait 500ms after the user stops typing before calling the Search API.
3.  **Refresh Tokens**: If an API returns `401`, call `POST /api/auth/refresh` with the stored `refreshToken`.
4.  **Master OTP**: Use `123456` for all your internal testing and video demos.

---

## 📱 6. Flutter Implementation Tips (Dart)

### A. Safe Model Mapping
The `details` field is only present in the `GET /products/:id` response. In your `Product` model in Dart, make sure `details` is nullable:
```dart
class Product {
  final String title;
  final ProductDetail? details; // Nullable for listing view
  // ...
}
```

### B. Handling Free Items in Cart
When displaying the Cart, the `freeItems` array should be mapped to the same UI widget as regular items but with a "FREE" ribbon and the "Delete" button hidden.

### C. Authentication (auth_controller.dart)
Use the **Master OTP `123456`** for your `verifyOTP` call during development to save time.

---

## 🛠 Endpoint Cheat Sheet

| Feature | Method | Endpoint |
| :--- | :--- | :--- |
| **Login/OTP** | `POST` | `/api/auth/send-otp` |
| **Verify** | `POST` | `/api/auth/verify-otp` |
| **Product List** | `GET` | `/api/products` |
| **Product Detail** | `GET` | `/api/products/:id` |
| **Apply Coupon** | `POST` | `/api/cart/coupon` |
| **Orders** | `GET` | `/api/orders` |

---

> [!TIP]
> **Pro Tip**: Use the `thumbnail` image for the Cart and Checkout screens to keep the total payload small and fast.
