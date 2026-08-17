import 'package:krishikranti/features/products/data/models/product_model.dart';
import 'package:krishikranti/features/products/data/models/category_model.dart';
import 'package:krishikranti/features/products/data/models/collection_model.dart';
import 'package:krishikranti/features/products/data/models/banner_model.dart';

class HomeDiscovery {
  final List<BannerModel> banners;
  final List<BannerModel> categoryBanners;
  final List<BannerModel> categoryCardBanners;
  final List<BannerModel> bestOffersBanners;
  final List<BannerModel> stripBanners;
  final BannerModel? homeTrustBanner;
  final BannerModel? categoryTrustBanner;
  final List<Category> categories;
  final List<Product> featuredProducts;
  final List<Collection> collections;

  HomeDiscovery({
    required this.banners,
    required this.categoryBanners,
    required this.categoryCardBanners,
    required this.bestOffersBanners,
    required this.stripBanners,
    this.homeTrustBanner,
    this.categoryTrustBanner,
    required this.categories,
    required this.featuredProducts,
    required this.collections,
  });

  factory HomeDiscovery.fromJson(Map<String, dynamic> json) {
    final List<Product> featured = (json['featuredProducts'] as List? ?? [])
        .map((item) => Product.fromJson(item))
        .toList();
        
    // Apply custom sorting for featured products
    Product.sortProducts(featured, 'featured');

    return HomeDiscovery(
      banners: (json['banners'] as List? ?? [])
          .map((item) => BannerModel.fromJson(item))
          .toList(),
      categoryBanners: (json['categoryBanners'] as List? ?? [])
          .map((item) => BannerModel.fromJson(item))
          .toList(),
      categoryCardBanners: (json['categoryCardBanners'] as List? ?? [])
          .map((item) => BannerModel.fromJson(item))
          .toList(),
      bestOffersBanners: (json['bestOffersBanners'] as List? ?? [])
          .map((item) => BannerModel.fromJson(item))
          .toList(),
      stripBanners: (json['stripBanners'] as List? ?? [])
          .map((item) => BannerModel.fromJson(item))
          .toList(),
      homeTrustBanner: json['homeTrustBanner'] != null
          ? BannerModel.fromJson(json['homeTrustBanner'])
          : null,
      categoryTrustBanner: json['categoryTrustBanner'] != null
          ? BannerModel.fromJson(json['categoryTrustBanner'])
          : null,
      categories: (json['categories'] as List? ?? [])
          .map((item) => Category.fromJson(item))
          .toList(),
      featuredProducts: featured,
      collections: (json['collections'] as List? ?? [])
          .map((item) => Collection.fromJson(item))
          .toList(),
    );
  }
}
