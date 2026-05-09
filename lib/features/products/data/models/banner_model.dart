class BannerModel {
  final String id;
  final String title;
  final String imageUrl;
  final int priority;
  final String redirectType;
  final String? redirectTarget;

  BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.priority,
    required this.redirectType,
    this.redirectTarget,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      priority: json['priority'] ?? 0,
      redirectType: json['redirectType'] ?? 'none',
      redirectTarget: json['redirectTarget'],
    );
  }
}
