import 'package:krishikranti/features/products/data/models/product_model.dart';
import 'package:krishikranti/features/products/data/models/category_model.dart';
import 'package:krishikranti/features/products/data/models/collection_model.dart';

class HomeDiscovery {
  final List<Category> categories;
  final List<Product> featuredProducts;
  final List<Collection> collections;

  HomeDiscovery({
    required this.categories,
    required this.featuredProducts,
    required this.collections,
  });

  factory HomeDiscovery.fromJson(Map<String, dynamic> json) {
    return HomeDiscovery(
      categories: (json['categories'] as List? ?? [])
          .map((item) => Category.fromJson(item))
          .toList(),
      featuredProducts: (json['featuredProducts'] as List? ?? [])
          .map((item) => Product.fromJson(item))
          .toList(),
      collections: (json['collections'] as List? ?? [])
          .map((item) => Collection.fromJson(item))
          .toList(),
    );
  }
}
