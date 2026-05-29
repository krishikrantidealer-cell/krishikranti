class Category {
  final String id;
  final String name;
  final String? bannerImage;
  final String? cataloguePdf;
  final List<SubCategory> subCategories;

  Category({
    required this.id,
    required this.name,
    this.bannerImage,
    this.cataloguePdf,
    this.subCategories = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      bannerImage: json['bannerImage'],
      cataloguePdf: json['cataloguePdf'],
      subCategories: (json['subCategories'] as List?)
              ?.map((s) => SubCategory.fromJson(s))
              .toList() ??
          [],
    );
  }
}

class SubCategory {
  final String id;
  final String name;
  final String? bannerImage;

  SubCategory({
    required this.id,
    required this.name,
    this.bannerImage,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      bannerImage: json['bannerImage'],
    );
  }
}
