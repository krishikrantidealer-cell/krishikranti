import 'dart:convert';
import 'package:krishikranti/core/constants/api_constants.dart';
import 'package:krishikranti/core/network/http_service.dart';
import 'package:krishikranti/features/products/data/models/product_model.dart';

class ProductRepository {
  Future<Map<String, dynamic>> getProducts({int limit = 20, String? cursor}) async {
    final url = cursor != null
        ? '${ApiConstants.products}?limit=$limit&cursor=$cursor'
        : '${ApiConstants.products}?limit=$limit';

    try {
      final response = await HttpService.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List productsJson = data['products'] ?? [];
        final products = productsJson.map((json) => Product.fromJson(json)).toList();
        
        return {
          'products': products,
          'nextCursor': data['nextCursor'],
        };
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Product> getProductDetail(String id) async {
    try {
      final response = await HttpService.get(ApiConstants.productDetail(id));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Product.fromJson(data['product']);
      } else {
        throw Exception('Failed to load product details');
      }
    } catch (e) {
      rethrow;
    }
  }
}
