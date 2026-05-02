class Product {
  final String id;
  final String title;
  final String thumbnail;
  final double price;
  final ProductDetail? details;

  Product({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.price,
    this.details,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      details: json['details'] != null ? ProductDetail.fromJson(json['details']) : null,
    );
  }
}

class ProductDetail {
  final String description;
  final List<String> mediumImages;
  final List<String> originalImages;

  ProductDetail({
    required this.description,
    required this.mediumImages,
    required this.originalImages,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      description: json['description'] ?? '',
      mediumImages: List<String>.from(json['images']?['medium'] ?? []),
      originalImages: List<String>.from(json['images']?['original'] ?? []),
    );
  }
}
