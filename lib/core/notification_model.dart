import 'package:flutter/material.dart';

enum NotificationCategory { utility, marketing }

class NotificationModel {
  final String id;
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color color;
  bool isUnread;
  final String group;
  final NotificationCategory category;

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.color,
    this.isUnread = true,
    required this.group,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'time': time,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'colorValue': color.value,
      'isUnread': isUnread,
      'group': group,
      'category': category.name,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      time: json['time'] as String,
      icon: IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String?,
        fontPackage: json['iconFontPackage'] as String?,
      ),
      color: Color(json['colorValue'] as int),
      isUnread: json['isUnread'] as bool,
      group: json['group'] as String,
      category: NotificationCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => NotificationCategory.utility,
      ),
    );
  }
}
