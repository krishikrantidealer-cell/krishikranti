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
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:krishikranti/core/network/auth_service.dart';
import 'package:krishikranti/core/network/http_service.dart';
import 'package:krishikranti/core/constants/api_constants.dart';
import 'package:krishikranti/core/meta_analytics_service.dart';

// Background message handler must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background tasks if needed
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");

  // Save to local inbox history first to ensure it's recorded
  final newNotif = await NotificationService.saveNotificationToLocal(message);

  // If it's a data-only message with no system notification, trigger a local one
  // so that images and banners show up based on our showNotification logic.
  if (message.notification == null && message.data.isNotEmpty && newNotif != null) {
    await NotificationService.showNotification(
      title: newNotif.title,
      body: newNotif.description,
      payload: newNotif.payload,
      imageUrl: newNotif.imageUrl,
      category: newNotif.category,
      notificationId: message.messageId.hashCode,
      saveToHistory: false, // Already saved by saveNotificationToLocal above
    );
  }
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
        if (response.actionId != null && response.actionId!.isNotEmpty) {
          handleNotificationAction(response.actionId!, response.payload);
        } else {
          handleNotificationTap(response.payload);
        }
      },
    );

    // 4. Create High Importance Channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'krishikranti_high_importance_channel', // id
      'High Importance Notifications', // name
      description: 'This channel is used for critical app notifications.',
      importance: Importance.high,
    );

    final androidPlugin = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(channel);
    if (Platform.isAndroid) {
      await androidPlugin?.requestNotificationsPermission();
    }

    // 5. Listen to Foreground Messages (When app is active on screen)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final String? titleStr = message.notification?.title ?? message.data['title'];
      final String? bodyStr = message.notification?.body ?? message.data['body'];
      
      debugPrint("Received Foreground Message: $titleStr");

      if (titleStr != null || bodyStr != null) {
        final titleLower = (titleStr ?? "").toLowerCase();
        final bodyLower = (bodyStr ?? "").toLowerCase();
        
        if (titleLower.contains('blocked') ||
            titleLower.contains('suspended') ||
            bodyLower.contains('blocked') ||
            bodyLower.contains('suspended')) {
          await HttpService.forceLogout();
          return;
        }

        String? imageUrl;
        if (Platform.isAndroid) {
          imageUrl = message.notification?.android?.imageUrl;
        } else if (Platform.isIOS) {
          imageUrl = message.notification?.apple?.imageUrl;
        }
        imageUrl ??= message.data['image'];

        // Use our unified showNotification utility
        showNotification(
          title: titleStr ?? "Update",
          body: bodyStr ?? "",
          payload: jsonEncode(message.data),
          imageUrl: imageUrl,
          category: message.data['category'] == 'marketing'
              ? NotificationCategory.marketing
              : NotificationCategory.utility,
          showSystemNotification: true, // Keeps the notification in phone's notification tray
        );

        if (titleLower.contains('kyc') ||
            titleLower.contains('verification') ||
            bodyLower.contains('kyc') ||
            bodyLower.contains('verification')) {
          if (navigatorKey.currentContext != null) {
            try {
              Provider.of<ProfileService>(
                navigatorKey.currentContext!,
                listen: false,
              ).fetchProfileFromServer().catchError((_) => null);
            } catch (e) {
              debugPrint("Error auto-refreshing profile on KYC message: $e");
            }
          }
        }
      }
    });

    // 6. Handle Tap on Notification when app is running in the Background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      saveNotificationToLocal(message).then((newNotif) {
        if (newNotif != null) _notificationStreamController.add(newNotif);
      });
      handleNotificationTap(jsonEncode(message.data));
    });

    // 7. Handle Tap on Notification when app is completely Terminated
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? initialMessage) {
      if (initialMessage != null) {
        saveNotificationToLocal(initialMessage).then((newNotif) {
          if (newNotif != null) _notificationStreamController.add(newNotif);
        });
        Future.delayed(const Duration(milliseconds: 1500), () {
          handleNotificationTap(jsonEncode(initialMessage.data));
        });
      }
    });

    // 8. Listen to token refreshes to keep server token always valid
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      debugPrint("📱 FCM Token refreshed: $newToken");
      final loggedIn = await AuthService.isLoggedIn();
      if (loggedIn) {
        try {
          await HttpService.post(
            ApiConstants.fcmToken,
            body: {"fcmToken": newToken},
          );
          debugPrint("✅ Refreshed FCM Token synced with server.");
        } catch (e) {
          debugPrint("❌ Error syncing refreshed FCM Token: $e");
        }
      }
    });

    // 9. Get FCM Token and sync with server
    syncToken();
  }

  /// Fetches the current FCM token and sends it to the server
  static Future<void> syncToken() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (!loggedIn) {
      debugPrint("📱 Skipping FCM Token sync: User is not logged in.");
      return;
    }

    String? token;
    int retryCount = 0;
    const int maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        if (Platform.isIOS) {
          // On iOS, sometimes we need to wait for the APNS token to be available
          String? apnsToken = await _firebaseMessaging.getAPNSToken();
          if (apnsToken == null) {
            debugPrint("📱 APNS token not ready yet, retrying... ($retryCount)");
            await Future.delayed(const Duration(seconds: 3));
            retryCount++;
            continue;
          }
        }

        token = await _firebaseMessaging.getToken();
        if (token != null) break;
      } catch (e) {
        debugPrint("📱 Error getting FCM token: $e");
        await Future.delayed(const Duration(seconds: 3));
        retryCount++;
      }
    }

    if (token != null) {
      debugPrint("📱 Firebase Messaging Token: $token");

      try {
        await HttpService.post(
          ApiConstants.fcmToken,
          body: {"fcmToken": token},
        );
        debugPrint("✅ FCM Token successfully synced with server.");
      } catch (e) {
        debugPrint("❌ Error syncing FCM Token: $e");
      }
    }
  }

  /// Helper to determine category from content
  static NotificationCategory _determineCategory(String title, String body, Map<String, dynamic> data) {
    final String? dataCat = data['category'];
    if (dataCat != null) {
      final match = NotificationCategory.values.firstWhere(
        (e) => e.name == dataCat,
        orElse: () => NotificationCategory.utility,
      );
      if (match != NotificationCategory.utility) return match;
    }

    final t = title.toLowerCase();
    final b = body.toLowerCase();

    if (t.contains('kyc') || b.contains('kyc') || t.contains('verification') || b.contains('verification') || t.contains('documents') || b.contains('approved') || t.contains('license') || b.contains('license') || t.contains('photo') || b.contains('photo')) {
      return NotificationCategory.kyc;
    }
    if (t.contains('cart') || b.contains('cart')) {
      return NotificationCategory.cart;
    }
    if (t.contains('order') || b.contains('order') || t.contains('payment') || b.contains('payment') || t.contains('delivery') || b.contains('dispatch')) {
      return NotificationCategory.order;
    }
    if (t.contains('wholesale') || b.contains('wholesale') || t.contains('price') || b.contains('price') || t.contains('offer') || b.contains('surprise')) {
      return NotificationCategory.marketing;
    }
    if (t.contains('season') || b.contains('season') || t.contains('kharif') || b.contains('kharif')) {
      return NotificationCategory.seasonal;
    }

    return NotificationCategory.utility;
  }

  /// Manually trigger a local notification and save it to history
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    NotificationCategory? category,
    int? notificationId,
    bool showProgress = false,
    int? progress,
    int? maxProgress,
    bool indeterminate = false,
    String? imageUrl,
    bool saveToHistory = true,
    bool showSystemNotification = true,
  }) async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'krishikranti_high_importance_channel',
      'High Importance Notifications',
      importance: Importance.high,
    );

    final resolvedCategory = category ?? _determineCategory(title, body, payload != null ? jsonDecode(payload) : {});

    // Only save progress notification to local inbox history when it is at start (0) or completion (100 or completed state)
    final shouldSaveToHistory = saveToHistory && (!showProgress || progress == 0 || progress == 100);

    if (shouldSaveToHistory) {
      // Determine UI elements based on category
      IconData icon;
      Color color;

      switch (resolvedCategory) {
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

      final newNotif = NotificationModel(
        id:
            notificationId?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: body,
        timestamp: DateTime.now(),
        icon: icon,
        color: color,
        isUnread: true,
        category: resolvedCategory,
        payload: payload,
        imageUrl: imageUrl,
      );

      // Save to local storage for the Notification Screen
      await _saveManualNotificationToLocal(newNotif);
      _notificationStreamController.add(newNotif);
    }

    final notifId = notificationId ?? DateTime.now().hashCode;

    String? bigPicturePath;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        bigPicturePath = await _downloadAndSaveFile(
          imageUrl,
          'notification_img_$notifId',
        );
      } catch (e) {
        debugPrint("Error downloading notification image: $e");
      }
    }

    // Configure 1-tap quick action buttons matching the segment/category
    List<AndroidNotificationAction>? actions;
    if (resolvedCategory == NotificationCategory.kyc) {
      actions = const [
        AndroidNotificationAction(
          'action_kyc',
          '⚡ Complete KYC',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'action_help',
          '📞 Help',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ];
    } else if (resolvedCategory == NotificationCategory.cart) {
      actions = const [
        AndroidNotificationAction(
          'action_cart',
          '🛒 Open Cart',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ];
    } else if (resolvedCategory == NotificationCategory.order) {
      actions = const [
        AndroidNotificationAction(
          'action_orders',
          '📦 View Orders',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ];
    } else {
      actions = const [
        AndroidNotificationAction(
          'action_explore',
          '🌾 Explore Deals',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ];
    }

    // Show the actual system notification if requested (e.g. background/standalone)
    if (showSystemNotification) {
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
            importance: Importance.max,
            priority: Priority.max,
            color: const Color(0xFF2E7D32),
            showProgress: showProgress,
            maxProgress: maxProgress ?? 100,
            progress: progress ?? 0,
            indeterminate: indeterminate,
            onlyAlertOnce: true, // Prevents notification alert noise/buzz on every progress tick
            largeIcon:
                bigPicturePath != null
                    ? FilePathAndroidBitmap(bigPicturePath)
                    : null,
            styleInformation:
                bigPicturePath != null
                    ? BigPictureStyleInformation(
                      FilePathAndroidBitmap(bigPicturePath),
                      hideExpandedLargeIcon: true,
                      contentTitle: title,
                      summaryText: body,
                    )
                    : null,
            actions: actions,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            attachments:
                bigPicturePath != null
                    ? [DarwinNotificationAttachment(bigPicturePath)]
                    : null,
          ),
        ),
        payload: payload,
      );
    }
  }

  static Future<String> _downloadAndSaveFile(
    String url,
    String fileName,
  ) async {
    final Directory directory = await getTemporaryDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
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
    // Only save if it has a notification body or data fields that look like a notification
    if (message.notification == null && message.data.isEmpty) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> existingNotifs =
          prefs.getStringList('local_notifications') ?? [];

      final String title = message.notification?.title ?? message.data['title'] ?? "Alert";
      final String body = message.notification?.body ?? message.data['body'] ?? "New Update";
      
      final String id = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();

      // Check for duplicates
      final bool alreadyExists = existingNotifs.any((n) {
        try {
          return jsonDecode(n)['id'] == id;
        } catch (_) {
          return false;
        }
      });
      if (alreadyExists) {
        debugPrint("Notification $id already exists in local history. Skipping save.");
        return null;
      }

      // Determine category based on content
      final NotificationCategory category = _determineCategory(title, body, message.data);

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

      String? imageUrl;
      if (Platform.isAndroid) {
        imageUrl = message.notification?.android?.imageUrl;
      } else if (Platform.isIOS) {
        imageUrl = message.notification?.apple?.imageUrl;
      }
      imageUrl ??= message.data['image'];

      // Create model
      final NotificationModel newNotif = NotificationModel(
        id: id,
        title: title,
        description: body,
        timestamp: message.sentTime ?? DateTime.now(),
        icon: icon,
        color: color,
        isUnread: true,
        category: category,
        imageUrl: imageUrl,
        payload: jsonEncode(message.data),
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

  /// Handles quick action button clicks from the notification tray
  static void handleNotificationAction(String actionId, String? payload) async {
    debugPrint("Notification Action Clicked: $actionId");
    if (actionId == 'action_kyc') {
      navigatorKey.currentState?.pushNamed('/kyc');
    } else if (actionId == 'action_help') {
      final Uri uri = Uri.parse('tel:+918800000000');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else if (actionId == 'action_cart') {
      navigatorKey.currentState?.pushNamed('/cart');
    } else if (actionId == 'action_orders') {
      navigatorKey.currentState?.pushNamed('/dashboard');
    } else if (actionId == 'action_explore') {
      navigatorKey.currentState?.pushNamed('/dashboard');
    } else {
      handleNotificationTap(payload);
    }
  }

  /// Handles routing logic when a notification is tapped (both system tray and inside the app inbox)
  static void handleNotificationTap(String? payload) async {
    if (payload == null) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;

      // Log notification open to Meta SDK
      MetaAnalyticsService.logNotificationOpen(
        title: data['title'] ?? data['body'] ?? 'Notification Tap',
        category: data['category'] ?? 'utility',
        actionRoute: data['action_route'],
      );

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

      // If notification indicates blocked/suspended account, logout immediately
      final payloadString = payload.toLowerCase();
      if (payloadString.contains('blocked') || payloadString.contains('suspended')) {
        await HttpService.forceLogout();
        return;
      }

      // If notification contains kyc/profile info, refresh profile
      if (payloadString.contains('kyc') || payloadString.contains('verification')) {
        if (navigatorKey.currentContext != null) {
          try {
            Provider.of<ProfileService>(
              navigatorKey.currentContext!,
              listen: false,
            ).fetchProfileFromServer().catchError((_) => null);
          } catch (e) {
            debugPrint("Error fetching profile on notification tap: $e");
          }
        }
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
      timestamp: DateTime.now(),
      icon: category == NotificationCategory.marketing
          ? CupertinoIcons.bolt_fill
          : CupertinoIcons.cube_box_fill,
      color: category == NotificationCategory.marketing
          ? Colors.orange
          : const Color(0xFF2E7D32),
      isUnread: true,
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
            timestamp: DateTime.now(),
            icon: CupertinoIcons.cube_box_fill,
            color: const Color(0xFF2E7D32),
            isUnread: true,
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
            timestamp: DateTime.now(),
            icon: CupertinoIcons.cube_box_fill,
            color: Colors.red,
            isUnread: true,
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
