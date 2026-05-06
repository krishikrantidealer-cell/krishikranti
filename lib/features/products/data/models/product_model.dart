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

  static String _parseId(dynamic id) {
    if (id == null) return '';
    if (id is String) return id;
    if (id is Map && id.containsKey('\$oid')) return id['\$oid'].toString();
    return id.toString();
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
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
      id: _parseId(json['_id']),
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
      averageRating: _parseDouble(json['averageRating']),
      numReviews: json['numReviews'] ?? 0,
      categoryId: _parseId(json['categoryId']),
      subCategoryId: _parseId(json['subCategoryId']),
      tags: List<String>.from(json['tags'] ?? []),
      images: (json['images'] as List?)
              ?.map((img) => _resolveImageUrl(img.toString()))
              .toList() ??
          [],
      details: json['details'] != null
          ? ProductDetail.fromJson(json['details'])
          : null,
      minPrice: json['minPrice'] != null ? _parseDouble(json['minPrice']) : null,
      maxPrice: json['maxPrice'] != null ? _parseDouble(json['maxPrice']) : null,
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
      id: Product._parseId(json['_id']),
      size: json['size'] ?? '',
      price: Product._parseDouble(json['price']),
      compareAtPrice: Product._parseDouble(json['compareAtPrice']),
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
      id: Product._parseId(json['_id']),
      productId: Product._parseId(json['productId']),
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
