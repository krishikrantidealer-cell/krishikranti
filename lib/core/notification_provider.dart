import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:krishikranti/core/notification_model.dart';
import 'package:krishikranti/core/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  static final NotificationProvider _instance = NotificationProvider._internal();
  factory NotificationProvider() => _instance;

  NotificationProvider._internal() {
    _loadSavedNotifications();

    // Listen for new notifications in real-time
    _notificationSub = NotificationService.onNewNotification.listen((newNotif) {
      // Check if notification already exists to prevent duplication
      final index = _notifications.indexWhere((n) => n.id == newNotif.id);
      if (index == -1) {
        _notifications.insert(0, newNotif);
        notifyListeners();
      }
    });
  }

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  StreamSubscription? _notificationSub;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get hasUnread => _notifications.any((n) => n.isUnread);
  int get unreadCount => _notifications.where((n) => n.isUnread).length;

  Future<void> _loadSavedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList('local_notifications') ?? [];

      _notifications = savedList.map((str) {
        return NotificationModel.fromJson(jsonDecode(str));
      }).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading notifications in provider: $e");
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveCurrentState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final strList = _notifications.map((n) => jsonEncode(n.toJson())).toList();
      await prefs.setStringList('local_notifications', strList);
    } catch (e) {
      debugPrint("Error saving notifications in provider: $e");
    }
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    _saveCurrentState();
  }

  void toggleReadStatus(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && _notifications[index].isUnread) {
      _notifications[index].isUnread = false;
      notifyListeners();
      _saveCurrentState();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isUnread = false;
    }
    notifyListeners();
    _saveCurrentState();
  }

  Future<void> refreshNotifications() async {
    await _loadSavedNotifications();
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }
}
