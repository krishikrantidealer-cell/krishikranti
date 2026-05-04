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
  final String group; // "Today", "Yesterday", "Earlier"

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
      description:
          "Your order for 'COXY-50' has been successfully delivered. Rate your experience!",
      time: "2 min ago",
      icon: CupertinoIcons.cube_box_fill,
      color: const Color(0xFF2E7D32),
      group: "Today",
    ),
    NotificationModel(
      id: "2",
      title: "Flash Sale Alert! ⚡",
      description:
          "Organic fertilizers at 30% off for the next 4 hours only. Don't miss out!",
      time: "1 hour ago",
      icon: CupertinoIcons.bolt_fill,
      color: Colors.orange,
      group: "Today",
    ),
    NotificationModel(
      id: "3",
      title: "Security Update",
      description:
          "We've added a new layer of security to your account for better protection.",
      time: "4 hours ago",
      icon: CupertinoIcons.shield_fill,
      color: Colors.indigo,
      group: "Today",
    ),
    NotificationModel(
      id: "4",
      title: "Price Drop: Zinc Power",
      description:
          "The price for 'Zinc Power' dropped to ₹450. Buy now and save ₹50!",
      time: "Yesterday, 4:00 PM",
      icon: CupertinoIcons.graph_circle_fill,
      color: Colors.blue,
      isUnread: false,
      group: "Yesterday",
    ),
    NotificationModel(
      id: "5",
      title: "Payment Confirmed",
      description:
          "Payment for order #KK1234 has been received and is being processed.",
      time: "Yesterday, 10:30 AM",
      icon: CupertinoIcons.creditcard_fill,
      color: Colors.purple,
      isUnread: false,
      group: "Yesterday",
    ),
    NotificationModel(
      id: "6",
      title: "New Product Launch",
      description:
          "Discover our new range of eco-friendly pesticides launched today.",
      time: "2 days ago",
      icon: CupertinoIcons.sparkles,
      color: Colors.teal,
      isUnread: false,
      group: "Earlier",
    ),
  ];

  void _deleteNotification(String id) {
    HapticFeedback.mediumImpact();
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  void _toggleReadStatus(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index].isUnread = false;
      }
    });
  }

  void _markAllAsRead() {
    HapticFeedback.lightImpact();
    setState(() {
      for (var n in _notifications) {
        n.isUnread = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      appBar: AppBar(
        title: Text(
          l10n.notifications,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          if (_notifications.any((n) => n.isUnread))
            IconButton(
              icon: const Icon(CupertinoIcons.clear_circled, size: 20),
              onPressed: _markAllAsRead,
              tooltip: "Mark all as read",
              color: theme.colorScheme.primary,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.lightImpact();
          await Future.delayed(const Duration(seconds: 1));
        },
        color: theme.colorScheme.primary,
        child: _notifications.isEmpty
            ? SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: _buildEmptyState(context, theme),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final current = _notifications[index];
                  final showSection =
                      index == 0 ||
                      current.group != _notifications[index - 1].group;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showSection) _buildSectionTitle(current.group),
                      _buildNotificationCard(current, theme),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.grey.shade400,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    NotificationModel notification,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) => _deleteNotification(notification.id),
        background: _buildDismissBackground(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _toggleReadStatus(notification.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildIconContainer(notification),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontWeight: notification.isUnread
                                        ? FontWeight.w800
                                        : FontWeight.w700,
                                    fontSize: 14,
                                    color: notification.isUnread
                                        ? const Color(0xFF1A1A1A)
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                              if (notification.isUnread)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            notification.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: notification.isUnread
                                  ? Colors.black87
                                  : Colors.grey.shade500,
                              height: 1.3,
                              fontWeight: notification.isUnread
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.time,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade400,
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

  Widget _buildIconContainer(NotificationModel notification) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: notification.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(notification.icon, color: notification.color, size: 18),
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(CupertinoIcons.trash, color: Colors.red, size: 18),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/orders_empty.json',
              height: 160,
              repeat: true,
            ),
            const SizedBox(height: 24),
            Text(
              "No notifications yet",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "We'll keep you posted with the latest updates.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ProductListScreen(category: "All"),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Explore Products",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
