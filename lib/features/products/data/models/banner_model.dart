class BannerModel {
  final String id;
  final String title;
  final String imageUrl;
  final int priority;
  final String redirectType;
  final String? redirectTarget;
  final bool isActive;

  BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.priority,
    required this.redirectType,
    this.redirectTarget,
    this.isActive = true,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: (json["_id"] ?? json["id"] ?? "").toString(),
      title: (json["title"] ?? "").toString(),
      imageUrl: (json["imageUrl"] ?? "").toString(),
      priority: json["priority"] is int ? json["priority"] : (int.tryParse(json["priority"]?.toString() ?? "0") ?? 0),
      redirectType: (json["redirectType"] ?? "none").toString(),
      redirectTarget: json["redirectTarget"]?.toString(),
      isActive: json["isActive"] == null ? true : (json["isActive"] == true || json["isActive"] == "true"),
    );
  }
}
