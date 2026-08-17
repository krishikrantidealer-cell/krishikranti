class Category {
  final String id;
  final String name;
  final String? slug;
  final String? bannerImage;
  final String? bannerTitle;
  final String? iconImage;
  final String? cataloguePdf;
  final List<SubCategory> subCategories;

  Category({
    required this.id,
    required this.name,
    this.slug,
    this.bannerImage,
    this.bannerTitle,
    this.iconImage,
    this.cataloguePdf,
    this.subCategories = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json["_id"] ?? json["id"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
      slug: json["slug"]?.toString(),
      bannerImage: json["bannerImage"]?.toString(),
      bannerTitle: (json["bannerTitle"] as String?)?.trim().isNotEmpty == true
          ? json["bannerTitle"].toString()
          : (json["name"] ?? "").toString(),
      iconImage: (json["iconImage"] ?? json["icon"])?.toString(),
      cataloguePdf: json["cataloguePdf"]?.toString(),
      subCategories: (json["subCategories"] as List?)
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
      id: (json["_id"] ?? json["id"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
      bannerImage: json["bannerImage"]?.toString(),
      bannerTitle: (json["bannerTitle"] as String?)?.trim().isNotEmpty == true
          ? json["bannerTitle"].toString()
          : (json["name"] ?? "").toString(),
    );
  }
}
