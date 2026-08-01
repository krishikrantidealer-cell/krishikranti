import 'package:krishikranti/core/constants/api_constants.dart';
import 'package:krishikranti/features/products/data/models/product_model.dart';

String _resolveImageUrl(String path) {
  if (path.isEmpty) return '';

  // Handle Google Drive links
  if (path.contains('drive.google.com')) {
    final idMatch = RegExp(
      r'(?:id=|\/d\/|folders\/)([a-zA-Z0-9-_]+)',
    ).firstMatch(path);
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

class SubCollection {
  final String id;
  final String name;
  final String slug;
  final bool isActive;
  final String? image;

  SubCollection({
    required this.id,
    required this.name,
    required this.slug,
    this.isActive = true,
    this.image,
  });

  factory SubCollection.fromJson(Map<String, dynamic> json) {
    final rawImage = json['image'] as String?;
    return SubCollection(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      isActive: json['isActive'] ?? true,
      image: rawImage != null && rawImage.isNotEmpty ? _resolveImageUrl(rawImage) : null,
    );
  }
}

class Collection {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? bannerImage;
  final String? bannerTitle;
  final List<Product> products;
  final List<SubCollection> subCollections;

  Collection({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.bannerImage,
    this.bannerTitle,
    this.products = const [],
    this.subCollections = const [],
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    final rawBanner = json['bannerImage'] as String?;
    final String id = json['_id'] ?? '';
    
    final List<Product> products = (json['products'] as List?)
            ?.map((p) => Product.fromJson(p))
            .toList() ??
        [];
    
    // Automatically sort products based on their position in this collection
    // as defined in the admin panel.
    Product.sortProducts(products, id);

    return Collection(
      id: id,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      bannerImage: rawBanner != null && rawBanner.isNotEmpty ? _resolveImageUrl(rawBanner) : null,
      bannerTitle: (json['bannerTitle'] as String?)?.trim().isNotEmpty == true
          ? json['bannerTitle']
          : json['name'] ?? '',
      products: products,
      subCollections: (json['subCollections'] as List?)
              ?.map((s) => SubCollection.fromJson(s))
              .toList() ??
          [],
    );
  }
}
