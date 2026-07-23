import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

enum NotificationCategory { utility, marketing, kyc, order, cart, seasonal }

class NotificationModel {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final IconData icon;
  final Color color;
  bool isUnread;
  final NotificationCategory category;
  final String? payload;
  final String? imageUrl;

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.icon,
    required this.color,
    this.isUnread = true,
    required this.category,
    this.payload,
    this.imageUrl,
  });

  String get time {
    final now = DateTime.now();
    final localTime = timestamp.toLocal();
    final difference = now.difference(localTime);

    if (difference.isNegative || difference.inSeconds < 60) {
      return "Just now";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}h ago";
    } else if (difference.inDays < 7) {
      return "${difference.inDays}d ago";
    } else {
      return DateFormat('dd MMM').format(localTime);
    }
  }

  String get group {
    final now = DateTime.now();
    final localTime = timestamp.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notifDate = DateTime(localTime.year, localTime.month, localTime.day);

    if (notifDate == today) {
      return "Today";
    } else if (notifDate == yesterday) {
      return "Yesterday";
    } else {
      return "Older";
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'isUnread': isUnread,
      'category': category.name,
      if (payload != null) 'payload': payload,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final category = NotificationCategory.values.firstWhere(
      (e) => e.name == json['category'],
      orElse: () => NotificationCategory.utility,
    );

    // Determine UI elements based on category
    IconData icon;
    Color color;

    switch (category) {
      case NotificationCategory.kyc:
        icon = CupertinoIcons.shield_fill;
        color = Colors.blue;
        break;
      case NotificationCategory.order:
        icon = CupertinoIcons.cube_box_fill;
        color = const Color(0xFF2E7D32);
        break;
      case NotificationCategory.cart:
        icon = CupertinoIcons.cart_fill;
        color = Colors.orange;
        break;
      case NotificationCategory.marketing:
        icon = CupertinoIcons.bolt_fill;
        color = Colors.orange;
        break;
      case NotificationCategory.seasonal:
        icon = CupertinoIcons.clear_fill;
        color = Colors.lightGreen;
        break;
      default:
        icon = CupertinoIcons.bell_fill;
        color = const Color(0xFF2E7D32);
    }

    // Handle migration from old 'time' field if 'timestamp' is missing
    DateTime parsedTimestamp;
    if (json.containsKey('timestamp')) {
      parsedTimestamp = DateTime.parse(json['timestamp'] as String);
    } else {
      try {
        final idStr = json['id'] as String;
        final idInt = int.tryParse(idStr);
        if (idInt != null && idInt > 1000000000000) {
          parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(idInt);
        } else {
          parsedTimestamp = DateTime.now();
        }
      } catch (_) {
        parsedTimestamp = DateTime.now();
      }
    }

    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      timestamp: parsedTimestamp,
      icon: icon,
      color: color,
      isUnread: json['isUnread'] as bool,
      category: category,
      payload: json['payload'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
