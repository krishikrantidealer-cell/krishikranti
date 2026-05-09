import 'package:krishikranti/features/products/data/models/product_model.dart';
import 'package:krishikranti/features/products/data/models/category_model.dart';
import 'package:krishikranti/features/products/data/models/collection_model.dart';
import 'package:krishikranti/features/products/data/models/banner_model.dart';

class HomeDiscovery {
  final List<BannerModel> banners;
  final List<BannerModel> categoryBanners;
  final List<BannerModel> categoryCardBanners;
  final List<BannerModel> bestOffersBanners;
  final List<Category> categories;
  final List<Product> featuredProducts;
  final List<Collection> collections;

  HomeDiscovery({
    required this.banners,
    required this.categoryBanners,
    required this.categoryCardBanners,
    required this.bestOffersBanners,
    required this.categories,
    required this.featuredProducts,
    required this.collections,
  });

  factory HomeDiscovery.fromJson(Map<String, dynamic> json) {
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
