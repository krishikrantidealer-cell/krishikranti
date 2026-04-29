import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:lottie/lottie.dart';
import 'package:krishikranti/screens/product_list_screen.dart';

class NotificationModel {
  final String id;
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color color;
  bool isUnread;
  final String group; // "Today" or "Yesterday"

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.color,
    this.isUnread = true,
    required this.group,
  });
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<NotificationModel> _notifications = [
    NotificationModel(
      id: "1",
      title: "Order Delivered",
      description: "Your order for 'COXY-50' has been successfully delivered.",
      time: "2 min ago",
      icon: CupertinoIcons.check_mark_circled_solid,
      color: Colors.green,
      group: "Today",
    ),
    NotificationModel(
      id: "2",
      title: "New Deals",
      description: "Get up to 20% off on all organic fertilizers this week.",
      time: "1 hour ago",
      icon: CupertinoIcons.tag_fill,
      color: Colors.orange,
      group: "Today",
    ),
    NotificationModel(
      id: "3",
      title: "Price Drop",
      description: "Price for 'Zinc Power' dropped to ₹450. Buy now!",
      time: "Yesterday, 4:00 PM",
      icon: CupertinoIcons.arrow_down_circle_fill,
      color: Colors.blue,
      isUnread: false,
      group: "Yesterday",
    ),
    NotificationModel(
      id: "4",
      title: "Payment Confirmed",
      description: "Payment for order #KK1234 has been received.",
      time: "Yesterday, 10:30 AM",
      icon: CupertinoIcons.creditcard_fill,
      color: Colors.purple,
      isUnread: false,
      group: "Yesterday",
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n.isUnread = false;
      }
    });
  }

  void _clearAll() {
    setState(() {
      _notifications.clear();
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  void _toggleReadStatus(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index].isUnread = !_notifications[index].isUnread;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          title: Text(
            l10n.notifications,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (_notifications.isNotEmpty) ...[
              Center(
                child: GestureDetector(
                  onTap: _markAllAsRead,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Read All",
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _clearAll,
                icon: const Icon(CupertinoIcons.trash, color: Colors.red, size: 20),
                tooltip: "Clear All",
              ),
            ]
          ],
        ),
        body: SafeArea(
          minimum: const EdgeInsets.only(bottom: 10),
          child: _notifications.isEmpty
              ? _buildEmptyState(context, theme)
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    if (_notifications.any((n) => n.group == "Today")) ...[
                      _buildSectionTitle("Today"),
                      ..._notifications
                          .where((n) => n.group == "Today")
                          .map((n) => _buildNotificationCard(n, theme)),
                    ],
                    if (_notifications.any((n) => n.group == "Yesterday")) ...[
                      const SizedBox(height: 16),
                      _buildSectionTitle("Yesterday"),
                      ..._notifications
                          .where((n) => n.group == "Yesterday")
                          .map((n) => _buildNotificationCard(n, theme)),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, ThemeData theme) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.horizontal,
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          // Handled via background action usually, but since it's dismissed...
          // We'll keep it in list if it's just marking as read, but Dismissible deletes it by default.
          // To keep it, we'd need a more complex implementation.
          // For now, let's treat both as "Delete" in UI for simplicity, 
          // or handle logic specifically.
          _deleteNotification(notification.id);
        } else {
          _deleteNotification(notification.id);
        }
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _toggleReadStatus(notification.id);
          return false; // Don't remove from list
        }
        return true; // Remove from list
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          notification.isUnread ? CupertinoIcons.eye_fill : CupertinoIcons.eye_slash_fill,
          color: theme.colorScheme.primary,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(CupertinoIcons.delete, color: Colors.red),
      ),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 500),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: notification.isUnread ? const Color(0xFFE8F5E9) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _toggleReadStatus(notification.id),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Left Border Indicator
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: notification.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Left Icon Style
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: notification.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(notification.icon, color: notification.color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    // Text Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            notification.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notification.time,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/orders_empty.json', // Fallback to existing
              height: 200,
            ),
            const SizedBox(height: 24),
            const Text(
              "No notifications yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "We'll notify you when something important arrives.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProductListScreen(category: "All")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Explore Products",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
