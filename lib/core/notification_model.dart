import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

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
      'isUnread': isUnread,
      'group': group,
      'category': category.name,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final category = NotificationCategory.values.firstWhere(
      (e) => e.name == json['category'],
      orElse: () => NotificationCategory.utility,
    );

    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      time: json['time'] as String,
      icon: category == NotificationCategory.marketing
          ? CupertinoIcons.bolt_fill
          : CupertinoIcons.cube_box_fill,
      color: category == NotificationCategory.marketing
          ? Colors.orange
          : const Color(0xFF2E7D32),
      isUnread: json['isUnread'] as bool,
      group: json['group'] as String,
      category: category,
    );
  }
}
