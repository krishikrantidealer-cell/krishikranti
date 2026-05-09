import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:lottie/lottie.dart';
import 'package:krishikranti/screens/product_list_screen.dart';
import 'package:krishikranti/core/notification_model.dart';
import 'package:krishikranti/core/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<NotificationModel> _notifications = [];
  StreamSubscription? _notificationSub;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSavedNotifications();

    // Listen for new notifications arriving while the user is on this screen
    _notificationSub = NotificationService.onNewNotification.listen((newNotif) {
      if (mounted) {
        setState(() {
          _notifications.insert(0, newNotif);
        });
      }
    });
  }

  Future<void> _loadSavedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList('local_notifications') ?? [];
      
      final parsedList = savedList.map((str) {
        return NotificationModel.fromJson(jsonDecode(str));
      }).toList();

      if (mounted) {
        setState(() {
          _notifications = parsedList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading notifications: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCurrentState() async {
    final prefs = await SharedPreferences.getInstance();
    final strList = _notifications.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList('local_notifications', strList);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notificationSub?.cancel();
    super.dispose();
  }

  void _deleteNotification(String id) {
    HapticFeedback.mediumImpact();
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
    _saveCurrentState();
  }

  void _toggleReadStatus(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index].isUnread = false;
      }
    });
    _saveCurrentState();
  }

  void _markAllAsRead() {
    HapticFeedback.lightImpact();
    setState(() {
      for (var n in _notifications) {
        n.isUnread = false;
      }
    });
    _saveCurrentState();
  }

  List<NotificationModel> _getFilteredNotifications(int tabIndex) {
    if (tabIndex == 1) {
      return _notifications.where((n) => n.category == NotificationCategory.utility).toList();
    } else if (tabIndex == 2) {
      return _notifications.where((n) => n.category == NotificationCategory.marketing).toList();
    }
    return _notifications;
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey.shade500,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(text: "All"),
            Tab(text: "Orders & Alerts"),
            Tab(text: "Offers"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationList(0, theme),
                _buildNotificationList(1, theme),
                _buildNotificationList(2, theme),
              ],
            ),
    );
  }

  Widget _buildNotificationList(int tabIndex, ThemeData theme) {
    final filteredList = _getFilteredNotifications(tabIndex);

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        await _loadSavedNotifications();
      },
      color: theme.colorScheme.primary,
      child: filteredList.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: _buildEmptyState(context, theme, tabIndex),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final current = filteredList[index];
                // Simple grouping logic for saved state
                final showSection = index == 0 || current.group != filteredList[index - 1].group;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showSection) _buildSectionTitle(current.group),
                    _buildNotificationCard(current, theme),
                  ],
                );
              },
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

  Widget _buildNotificationCard(NotificationModel notification, ThemeData theme) {
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                                    fontWeight: notification.isUnread ? FontWeight.w800 : FontWeight.w700,
                                    fontSize: 14,
                                    color: notification.isUnread ? const Color(0xFF1A1A1A) : Colors.black54,
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
                              color: notification.isUnread ? Colors.black87 : Colors.grey.shade500,
                              height: 1.3,
                              fontWeight: notification.isUnread ? FontWeight.w500 : FontWeight.w400,
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

  Widget _buildEmptyState(BuildContext context, ThemeData theme, int tabIndex) {
    String emptyMessage = "No notifications yet";
    if (tabIndex == 1) emptyMessage = "No order updates yet";
    if (tabIndex == 2) emptyMessage = "No offers right now";

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/EmptyOrder.json',
              height: 160,
              repeat: true,
            ),
            const SizedBox(height: 24),
            Text(
              emptyMessage,
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
                    builder: (context) => const ProductListScreen(category: "All"),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
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
