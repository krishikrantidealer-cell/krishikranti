import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:krishikranti/core/profile_service.dart';
import 'package:krishikranti/main.dart'; // To access navigatorKey
import 'package:krishikranti/core/notification_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Background message handler must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background tasks if needed
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
  await NotificationService.saveNotificationToLocal(message);
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final ReceivePort _port = ReceivePort();

  // Stream to notify the active screen when a new notification arrives
  static final StreamController<NotificationModel>
  _notificationStreamController =
      StreamController<NotificationModel>.broadcast();

  static Stream<NotificationModel> get onNewNotification =>
      _notificationStreamController.stream;

  static Future<void> initialize() async {
    // Register port for background download updates
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      if (data is List) {
        final String id = data[0];
        final int status = data[1];
        final int progress = data[2];
        handleMainIsolateDownloadUpdate(id, status, progress);
      }
    });

    // Clear stale download keys in SharedPreferences on boot
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('download_task_') ||
            key.startsWith('download_path_') ||
            key.startsWith('download_url_')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('Error clearing stale download keys: $e');
    }

    // 1. Request Permission from the user
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permissions');
    }

    // 2. Setup Background Message Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Setup Local Notifications (for showing notifications when app is OPEN)
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _localNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        handleNotificationTap(response.payload);
      },
    );

    // 4. Create High Importance Channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'krishikranti_high_importance_channel', // id
      'High Importance Notifications', // name
      description: 'This channel is used for critical app notifications.',
      importance: Importance.high,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // 5. Listen to Foreground Messages (When app is active on screen)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint("Received Foreground Message: ${message.notification?.title}");

      if (message.notification != null) {
        // Use our unified showNotification utility
        showNotification(
          title: message.notification!.title ?? "Update",
          body: message.notification!.body ?? "",
          payload: jsonEncode(message.data),
          category: message.data['category'] == 'marketing'
              ? NotificationCategory.marketing
              : NotificationCategory.utility,
        );
      }
    });

    // 6. Handle Tap on Notification when app is running in the Background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleNotificationTap(jsonEncode(message.data));
    });

    // 7. Handle Tap on Notification when app is completely Terminated
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        handleNotificationTap(jsonEncode(initialMessage.data));
      });
    }

    // 8. Get FCM Token and sync with server
    syncToken();
  }

  /// Fetches the current FCM token and sends it to the server
  static Future<void> syncToken() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      debugPrint("📱 Firebase Messaging Token: $token");

      if (navigatorKey.currentContext != null) {
        try {
          final profileService = Provider.of<ProfileService>(
            navigatorKey.currentContext!,
            listen: false,
          );
          await profileService.updateFcmToken(token);
        } catch (e) {
          debugPrint("Note: ProfileService not yet available for token sync.");
        }
      }
    }
  }

  /// Manually trigger a local notification and save it to history
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    NotificationCategory category = NotificationCategory.utility,
    int? notificationId,
    bool showProgress = false,
    int? progress,
    int? maxProgress,
    bool indeterminate = false,
  }) async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'krishikranti_high_importance_channel',
      'High Importance Notifications',
      importance: Importance.high,
    );

    // Only save progress notification to local inbox history when it is at start (0) or completion (100 or completed state)
    final shouldSaveToHistory = !showProgress || progress == 0 || progress == 100;

    if (shouldSaveToHistory) {
      final newNotif = NotificationModel(
        id: notificationId?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: body,
        time: "Just now",
        icon: category == NotificationCategory.marketing
            ? CupertinoIcons.bolt_fill
            : CupertinoIcons.cube_box_fill,
        color: category == NotificationCategory.marketing
            ? Colors.orange
            : const Color(0xFF2E7D32),
        isUnread: true,
        group: "Today",
        category: category,
        payload: payload,
      );

      // Save to local storage for the Notification Screen
      await _saveManualNotificationToLocal(newNotif);
      _notificationStreamController.add(newNotif);
    }

    final notifId = notificationId ?? DateTime.now().hashCode;

    // Show the actual system notification
    await _localNotificationsPlugin.show(
      id: notifId,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF2E7D32),
          showProgress: showProgress,
          maxProgress: maxProgress ?? 100,
          progress: progress ?? 0,
          indeterminate: indeterminate,
          onlyAlertOnce: true, // Prevents notification alert noise/buzz on every progress tick
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Helper to save manually triggered notifications
  static Future<void> _saveManualNotificationToLocal(
    NotificationModel notification,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> existingNotifs =
          prefs.getStringList('local_notifications') ?? [];
      existingNotifs.insert(0, jsonEncode(notification.toJson()));
      if (existingNotifs.length > 50) existingNotifs.removeLast();
      await prefs.setStringList('local_notifications', existingNotifs);
    } catch (e) {
      debugPrint("Error saving manual notification: $e");
    }
  }

  /// Parses and saves the incoming FCM message into SharedPreferences
  static Future<NotificationModel?> saveNotificationToLocal(
    RemoteMessage message,
  ) async {
    if (message.notification == null) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> existingNotifs =
          prefs.getStringList('local_notifications') ?? [];

      // Parse payload
      final String categoryStr = message.data['category'] ?? 'utility';
      final NotificationCategory category = categoryStr == 'marketing'
          ? NotificationCategory.marketing
          : NotificationCategory.utility;

      // Determine UI elements based on category
      final IconData icon = category == NotificationCategory.marketing
          ? CupertinoIcons.bolt_fill
          : CupertinoIcons.cube_box_fill;
      final Color color = category == NotificationCategory.marketing
          ? Colors.orange
          : const Color(0xFF2E7D32);

      // Create model
      final NotificationModel newNotif = NotificationModel(
        id:
            message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification!.title ?? "New Alert",
        description: message.notification!.body ?? "",
        time: "Just now",
        icon: icon,
        color: color,
        isUnread: true,
        group: "Today",
        category: category,
      );

      // Save to list (add to top)
      existingNotifs.insert(0, jsonEncode(newNotif.toJson()));

      // Limit cache to 50 items to prevent massive storage use
      if (existingNotifs.length > 50) {
        existingNotifs.removeLast();
      }

      await prefs.setStringList('local_notifications', existingNotifs);
      debugPrint("Successfully saved notification locally.");
      return newNotif;
    } catch (e) {
      debugPrint("Error saving notification: $e");
      return null;
    }
  }

  /// Handles routing logic when a notification is tapped (both system tray and inside the app inbox)
  static void handleNotificationTap(String? payload) async {
    if (payload == null) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;

      // 1. Handle File Opening Callback
      if (data['type'] == 'open_file') {
        final path = data['path'] as String;
        final pdfUrl = data['pdfUrl'] as String?;
        final file = File(path);
        if (await file.exists() && await file.length() > 0) {
          final result = await OpenFilex.open(path);
          if (result.type == ResultType.done) return;
        }
        // Fallback: open in browser if file is missing or cannot be opened by OS
        if (pdfUrl != null) {
          final webUri = Uri.parse(pdfUrl);
          if (await canLaunchUrl(webUri)) {
            await launchUrl(webUri, mode: LaunchMode.externalApplication);
          }
        }
        return;
      }

      // 2. Handle Action Route Redirects
      final route = data['action_route'];
      if (route != null && navigatorKey.currentState != null) {
        debugPrint("Redirecting user to: $route");
        navigatorKey.currentState!.pushNamed(route);
      }
    } catch (e) {
      debugPrint("Error parsing notification payload: $e");
    }
  }

  /// Add a notification silently to the local history list without triggering a system alert pop-up
  static Future<void> addSilentNotification({
    required String title,
    required String body,
    String? payload,
    NotificationCategory category = NotificationCategory.utility,
  }) async {
    final newNotif = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: body,
      time: "Just now",
      icon: category == NotificationCategory.marketing
          ? CupertinoIcons.bolt_fill
          : CupertinoIcons.cube_box_fill,
      color: category == NotificationCategory.marketing
          ? Colors.orange
          : const Color(0xFF2E7D32),
      isUnread: true,
      group: "Today",
      category: category,
      payload: payload,
    );

    await _saveManualNotificationToLocal(newNotif);
    _notificationStreamController.add(newNotif);
  }

  // ── Global flutter_downloader Isolate background callback ──
  static Future<void> handleMainIsolateDownloadUpdate(String id, int status, int progress) async {
    try {
      debugPrint('=== handleMainIsolateDownloadUpdate entry: id=$id, status=$status, progress=$progress ===');
      final downloadStatus = DownloadTaskStatus.fromInt(status);
      
      final isComplete = downloadStatus == DownloadTaskStatus.complete;
      final isFailed = downloadStatus == DownloadTaskStatus.failed || downloadStatus == DownloadTaskStatus.canceled;

      if (isComplete || isFailed) {
        final prefs = await SharedPreferences.getInstance();
        
        final categoryName = prefs.getString('download_task_$id');
        if (categoryName == null) {
          debugPrint('=== [DownloadUpdate] categoryName is null for task $id ===');
          return;
        }

        final savePath = prefs.getString('download_path_$id');
        final pdfUrl = prefs.getString('download_url_$id');
        final notificationId = id.hashCode;

        debugPrint('=== [DownloadUpdate] task: $categoryName ($id), status: $status, progress: $progress ===');

        if (isComplete) {
          final payloadData = {
            'type': 'open_file',
            'path': savePath ?? '',
            'pdfUrl': pdfUrl ?? '',
          };

          // Save to local inbox history
          final newNotif = NotificationModel(
            id: notificationId.toString(),
            title: '$categoryName Catalogue Ready',
            description: 'Tap to view the downloaded $categoryName catalogue.',
            time: "Just now",
            icon: CupertinoIcons.cube_box_fill,
            color: const Color(0xFF2E7D32),
            isUnread: true,
            group: "Today",
            category: NotificationCategory.utility,
            payload: jsonEncode(payloadData),
          );

          final List<String> existingNotifs =
              prefs.getStringList('local_notifications') ?? [];
          existingNotifs.insert(0, jsonEncode(newNotif.toJson()));
          if (existingNotifs.length > 50) existingNotifs.removeLast();
          await prefs.setStringList('local_notifications', existingNotifs);
          _notificationStreamController.add(newNotif);

          // Show completion snackbar
          messengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('$categoryName catalogue downloaded successfully!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF2E7D32),
            ),
          );

          // Cleanup SharedPreferences task data
          await prefs.remove('download_task_$id');
          await prefs.remove('download_path_$id');
          await prefs.remove('download_url_$id');
        } else if (isFailed) {
          // Log failure silently to inbox
          final newNotif = NotificationModel(
            id: notificationId.toString(),
            title: '$categoryName Download Failed',
            description: 'Could not download the catalogue PDF.',
            time: "Just now",
            icon: CupertinoIcons.cube_box_fill,
            color: Colors.red,
            isUnread: true,
            group: "Today",
            category: NotificationCategory.utility,
          );

          final List<String> existingNotifs =
              prefs.getStringList('local_notifications') ?? [];
          existingNotifs.insert(0, jsonEncode(newNotif.toJson()));
          if (existingNotifs.length > 50) existingNotifs.removeLast();
          await prefs.setStringList('local_notifications', existingNotifs);
          _notificationStreamController.add(newNotif);

          // Show failure snackbar
          messengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('Failed to download $categoryName catalogue.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );

          // Cleanup
          await prefs.remove('download_task_$id');
          await prefs.remove('download_path_$id');
          await prefs.remove('download_url_$id');
        }
      }
    } catch (e, stack) {
      debugPrint('=== ERROR in handleMainIsolateDownloadUpdate: $e ===\n$stack');
    }
  }
}
