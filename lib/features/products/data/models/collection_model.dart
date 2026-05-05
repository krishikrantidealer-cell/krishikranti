import 'package:krishikranti/features/products/data/models/product_model.dart';

class Collection {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? bannerImage;
  final List<Product> products;

  Collection({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.bannerImage,
    this.products = const [],
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      bannerImage: json['bannerImage'],
      products: (json['products'] as List?)
              ?.map((p) => Product.fromJson(p))
              .toList() ??
          [],
    );
  }
}
