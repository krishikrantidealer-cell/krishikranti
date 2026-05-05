import 'package:krishikranti/core/constants/api_constants.dart';

class Product {
  final String id;
  final String title;
  final String? brandName;
  final String? technicalName;
  final String? vendor;
  final String? availabilityStatus;
  final String thumbnail;
  final List<Variant> variants;
  final double averageRating;
  final int numReviews;
  final String? categoryId;
  final String? subCategoryId;
  final List<String> tags;
  final ProductDetail? details;
  final List<String> images;
  final double? minPrice;
  final double? maxPrice;

  Product({
    required this.id,
    required this.title,
    this.brandName,
    this.technicalName,
    this.vendor,
    this.availabilityStatus,
    required this.thumbnail,
    required this.variants,
    this.averageRating = 0.0,
    this.numReviews = 0,
    this.categoryId,
    this.subCategoryId,
    this.tags = const [],
    this.details,
    this.images = const [],
    this.minPrice,
    this.maxPrice,
  });

  // Helper to get minimum price (uses backend value if available, else calculates)
  double get price {
    if (minPrice != null) return minPrice!;
    if (variants.isEmpty) return 0.0;
    return variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);
  }

  // Helper to get max compareAtPrice
  double get compareAtPrice {
    if (maxPrice != null) return maxPrice!;
    if (variants.isEmpty) return 0.0;
    return variants.map((v) => v.compareAtPrice).reduce((a, b) => a > b ? a : b);
  }

  static String _resolveImageUrl(String path) {
    if (path.isEmpty) return '';
    
    // Handle Google Drive links
    if (path.contains('drive.google.com')) {
      final idMatch = RegExp(r'(?:id=|\/d\/|folders\/)([a-zA-Z0-9-_]+)').firstMatch(path);
      if (idMatch != null) {
        final fileId = idMatch.group(1);
        // Using the thumbnail endpoint which is very reliable for Drive images
        return 'https://drive.google.com/thumbnail?id=$fileId&sz=w1000';
      }
    }

    if (path.startsWith('http')) return path;
    // Ensure no double slashes
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${ApiConstants.baseUrl}/$cleanPath';
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      brandName: json['brandName'],
      technicalName: json['technicalName'],
      vendor: json['vendor'],
      availabilityStatus: json['availabilityStatus'],
      thumbnail: _resolveImageUrl(json['thumbnail'] ?? ''),
      variants: (json['variants'] as List?)
              ?.map((v) => Variant.fromJson(v))
              .toList() ??
          [],
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      numReviews: json['numReviews'] ?? 0,
      categoryId: json['categoryId'],
      subCategoryId: json['subCategoryId'],
      tags: List<String>.from(json['tags'] ?? []),
      images: (json['images'] as List?)
              ?.map((img) => _resolveImageUrl(img.toString()))
              .toList() ??
          [],
      details: json['details'] != null
          ? ProductDetail.fromJson(json['details'])
          : null,
      minPrice: json['minPrice'] != null ? (json['minPrice'] as num).toDouble() : null,
      maxPrice: json['maxPrice'] != null ? (json['maxPrice'] as num).toDouble() : null,
    );
  }
}

class Variant {
  final String id;
  final String size;
  final double price;
  final double compareAtPrice;

  Variant({
    required this.id,
    required this.size,
    required this.price,
    required this.compareAtPrice,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      id: json['_id'] ?? '',
      size: json['size'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      compareAtPrice: (json['compareAtPrice'] ?? 0).toDouble(),
    );
  }
}

class ProductDetail {
  final String id;
  final String productId;
  final String description;
  final List<String> mediumImages;
  final List<String> originalImages;
  final Map<String, dynamic> specifications;

  ProductDetail({
    required this.id,
    required this.productId,
    required this.description,
    required this.mediumImages,
    required this.originalImages,
    required this.specifications,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: json['_id'] ?? '',
      productId: json['productId'] ?? '',
      description: json['description'] ?? '',
      mediumImages: List<String>.from(json['images']?['medium'] ?? [])
          .map((img) => Product._resolveImageUrl(img))
          .toList(),
      originalImages: List<String>.from(json['images']?['original'] ?? [])
          .map((img) => Product._resolveImageUrl(img))
          .toList(),
      specifications: json['specifications'] ?? {},
    );
  }
}
