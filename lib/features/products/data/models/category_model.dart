class Category {
  final String id;
  final String name;
  final List<SubCategory> subCategories;

  Category({
    required this.id,
    required this.name,
    this.subCategories = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
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

  SubCategory({
    required this.id,
    required this.name,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}
