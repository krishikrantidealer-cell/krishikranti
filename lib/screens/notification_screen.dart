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

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
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
      return _notifications
          .where((n) => n.category == NotificationCategory.utility)
          .toList();
    } else if (tabIndex == 2) {
      return _notifications
          .where((n) => n.category == NotificationCategory.marketing)
          .toList();
    }
    return _notifications;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hasUnread = _notifications.any((n) => n.isUnread);

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Slate 50 - extremely professional background
      appBar: AppBar(
        title: Text(
          l10n.notifications,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: const Color(0xFF0F172A), // Slate 900
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          if (hasUnread)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Material(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(30),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: _markAllAsRead,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            size: 13,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.readAll,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9), // Slate 100
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: const Color(0xFF64748B), // Slate 500
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              tabs: [
                Tab(text: l10n.tabAll),
                Tab(text: l10n.tabOrders),
                Tab(text: l10n.tabOffers),
              ],
            ),
          ),
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final current = filteredList[index];
                final showSection =
                    index == 0 ||
                    current.group != filteredList[index - 1].group;

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
    final l10n = AppLocalizations.of(context)!;
    String displayTitle = title;
    final lowerTitle = title.toLowerCase();
    if (lowerTitle == 'today') {
      displayTitle = l10n.today;
    } else if (lowerTitle == 'yesterday') {
      displayTitle = l10n.yesterday;
    } else if (lowerTitle == 'older') {
      displayTitle = l10n.older;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9), // Slate 100
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              displayTitle.toUpperCase(),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B), // Slate 500
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Divider(color: Color(0xFFF1F5F9), thickness: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    NotificationModel notification,
    ThemeData theme,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isUnread = notification.isUnread;
    final cardColor = isUnread
        ? notification.color.withValues(alpha: 0.02)
        : Colors.white;
    final borderColor = isUnread
        ? notification.color.withValues(alpha: 0.12)
        : const Color(0xFFE2E8F0); // Slate 200

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) => _deleteNotification(notification.id),
        background: _buildDismissBackground(),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: isUnread
                ? [
                    BoxShadow(
                      color: notification.color.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.015),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _toggleReadStatus(notification.id),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildIconContainer(notification),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        style: TextStyle(
                                          fontWeight: isUnread
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          fontSize: 13.5,
                                          color: isUnread
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isUnread
                                        ? const Color(0xFF334155)
                                        : const Color(0xFF64748B),
                                    height: 1.3,
                                    fontWeight: isUnread
                                        ? FontWeight.w500
                                        : FontWeight.w400,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      CupertinoIcons.clock,
                                      size: 11,
                                      color: Color(0xFF94A3B8), // Slate 400
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      notification.time.toLowerCase() ==
                                              'just now'
                                          ? l10n.justNow
                                          : notification.time,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF94A3B8), // Slate 400
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isUnread)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: notification.color,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer(NotificationModel notification) {
    final isUnread = notification.isUnread;
    final List<Color> gradientColors =
        notification.category == NotificationCategory.marketing
        ? [
            const Color(0xFFFF9F43),
            const Color(0xFFFF5252),
          ] // Warm orange gradient
        : [const Color(0xFF10B981), const Color(0xFF059669)]; // Green gradient

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUnread
              ? gradientColors
              : gradientColors.map((c) => c.withValues(alpha: 0.4)).toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: isUnread
            ? [
                BoxShadow(
                  color: gradientColors.last.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Icon(notification.icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade600],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        CupertinoIcons.trash_fill,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, int tabIndex) {
    final l10n = AppLocalizations.of(context)!;
    String emptyMessage = l10n.noNotificationsYet;
    if (tabIndex == 1) emptyMessage = l10n.noOrderUpdatesYet;
    if (tabIndex == 2) emptyMessage = l10n.noOffersRightNow;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/EmptyOrder.json',
              height: 120,
              repeat: true,
            ),
            const SizedBox(height: 20),
            Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.keepYouPosted,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
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
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.exploreProducts,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
