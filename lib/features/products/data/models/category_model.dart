class Category {
  final String id;
  final String name;
  final String? bannerImage;
  final String? bannerTitle;
  final String? iconImage;
  final String? cataloguePdf;
  final List<SubCategory> subCategories;

  Category({
    required this.id,
    required this.name,
    this.bannerImage,
    this.bannerTitle,
    this.iconImage,
    this.cataloguePdf,
    this.subCategories = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      bannerImage: json['bannerImage'],
      bannerTitle: (json['bannerTitle'] as String?)?.trim().isNotEmpty == true
          ? json['bannerTitle']
          : json['name'] ?? '',
      iconImage: json['iconImage'] ?? json['icon'],
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
  final String? bannerTitle;

  SubCategory({
    required this.id,
    required this.name,
    this.bannerImage,
    this.bannerTitle,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      bannerImage: json['bannerImage'],
      bannerTitle: (json['bannerTitle'] as String?)?.trim().isNotEmpty == true
          ? json['bannerTitle']
          : json['name'] ?? '',
    );
  }
}
