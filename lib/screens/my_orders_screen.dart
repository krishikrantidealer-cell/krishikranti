import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:krishikranti/features/orders/data/models/order_model.dart';
import 'package:krishikranti/features/orders/data/repositories/order_repository.dart';
import 'package:krishikranti/screens/order_detail_screen.dart';
import 'package:krishikranti/screens/product_list_screen.dart';
import 'package:intl/intl.dart';
import 'package:krishikranti/core/utils/translatable_text.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final List<String> _tabs = ["All", "Active", "Delivered", "Cancelled", "RTO"];
  int _selectedTabIndex = 0;
  final OrderRepository _orderRepository = OrderRepository();
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders({bool forceRefresh = false}) async {
    try {
      final orders = await _orderRepository.getMyOrders(
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }

      if (!forceRefresh) {
        final freshOrders = await _orderRepository.getMyOrders(
          forceRefresh: true,
        );
        if (mounted) {
          setState(() => _orders = freshOrders);
        }
      }
    } catch (e) {
      debugPrint("Error fetching/parsing orders: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getLocalizedTabName(String tabName, AppLocalizations l10n) {
    switch (tabName) {
      case "All":
        return l10n.tabAll;
      case "Active":
        return l10n.tabActive;
      case "Delivered":
        return l10n.tabDelivered;
      case "Cancelled":
        return l10n.tabCancelled;
      case "RTO":
        return l10n.tabRto;
      default:
        return tabName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final filteredOrders = _orders.where((order) {
      if (_selectedTabIndex == 0) return true;
      final tabName = _tabs[_selectedTabIndex];
      final status = order.orderStatus.toLowerCase();
      if (tabName == "Active") {
        return status == 'pending' ||
            status == 'processing' ||
            status == 'shipped' ||
            status == 'out for delivery' ||
            status == 'out_for_delivery';
      }
      return status == tabName.toLowerCase();
    }).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          l10n.myOrders,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white.withValues(alpha: 0.75),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: Center(
          child: _TopIconButton(
            icon: CupertinoIcons.chevron_left,
            onTap: () => Navigator.pop(context),
          ),
        ),
        actions: [
          _TopIconButton(
            icon: CupertinoIcons.question_circle,
            onTap: () => _showOrderHelp(context),
            margin: const EdgeInsets.only(right: 16),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background subtle modern glows
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade600.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Main Content
          Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).padding.top + kToolbarHeight + 0,
              ),
              _buildSummaryHeader(theme),
              _buildStatusTabs(theme),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _fetchOrders(forceRefresh: true),
                  color: theme.primaryColor,
                  backgroundColor: Colors.white,
                  child: _isLoading && _orders.isEmpty
                      ? ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
                          itemCount: 5,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) => const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: _OrderShimmerCard(),
                          ),
                        )
                      : filteredOrders.isEmpty
                      ? _buildEmptyState(context, _orders.isEmpty)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
                          itemCount: filteredOrders.length,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          itemBuilder: (context, index) {
                            return TweenAnimationBuilder<double>(
                              duration: Duration(
                                milliseconds: 250 + (index * 50).clamp(0, 300),
                              ),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.easeOutQuart,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 25 * (1 - value)),
                                    child: Transform.scale(
                                      scale: 0.96 + (0.04 * value),
                                      child: child,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _OrderCard(
                                  order: filteredOrders[index],
                                  onRefresh: () =>
                                      _fetchOrders(forceRefresh: true),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(ThemeData theme) {
    if (_isLoading || _orders.isEmpty) return const SizedBox.shrink();

    int activeOrders = _orders
        .where(
          (o) =>
              o.orderStatus.toLowerCase() == 'processing' ||
              o.orderStatus.toLowerCase() == 'shipped',
        )
        .length;

    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.overview,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                activeOrders > 0
                    ? l10n.activeOrdersLabel(activeOrders)
                    : l10n.allOrdersHistory,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          //Note: - This Place use the dynamic list view for the not the order values.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.cube_box_fill,
                  size: 14,
                  color: theme.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.totalOrdersCount(_orders.length),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabs(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final icons = [
      CupertinoIcons.cube_box_fill,
      CupertinoIcons.timer_fill,
      CupertinoIcons.checkmark_seal_fill,
      CupertinoIcons.xmark_circle_fill,
      CupertinoIcons.exclamationmark_triangle_fill,
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final isSelected = _selectedTabIndex == index;
          final tabName = _tabs[index];

          int count = 0;
          if (index == 0) {
            count = _orders.length;
          } else if (tabName == "Active") {
            count = _orders.where((o) {
              final s = o.orderStatus.toLowerCase();
              return s == 'pending' ||
                  s == 'processing' ||
                  s == 'shipped' ||
                  s == 'out for delivery' ||
                  s == 'out_for_delivery';
            }).length;
          } else {
            count = _orders
                .where(
                  (o) => o.orderStatus.toLowerCase() == tabName.toLowerCase(),
                )
                .length;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTabIndex = index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            theme.primaryColor,
                            theme.primaryColor.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icons[index],
                      size: 14,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getLocalizedTabName(tabName, l10n),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: 12,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "$count",
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isEntireListEmpty) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.1),
          Lottie.asset(
            'assets/animations/EmptyOrder.json',
            height: 180,
            repeat: true,
          ),
          const SizedBox(height: 20),
          Text(
            isEntireListEmpty ? l10n.noOrdersYet : l10n.noMatchingOrders,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              isEntireListEmpty
                  ? l10n.orderJourneyBegins
                  : l10n.noOrdersMatchingStatus(
                      _getLocalizedTabName(_tabs[_selectedTabIndex], l10n),
                    ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: 200,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                if (isEntireListEmpty) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ProductListScreen(category: "All"),
                    ),
                  );
                } else {
                  setState(() => _selectedTabIndex = 0);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: theme.primaryColor.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isEntireListEmpty ? l10n.startExploring : l10n.viewAllOrders,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderHelp(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.understandingOrderStatus,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.whatEachStatusMeans,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _buildHelpItem(
              CupertinoIcons.timer_fill,
              l10n.processing,
              l10n.processingDesc,
              Colors.orange.shade600,
            ),
            _buildHelpItem(
              CupertinoIcons.paperplane_fill,
              l10n.shipped,
              l10n.shippedDesc,
              Colors.blue.shade600,
            ),
            _buildHelpItem(
              CupertinoIcons.car_detailed,
              l10n.outForDelivery,
              l10n.outForDeliveryDesc,
              Colors.purple.shade600,
            ),
            _buildHelpItem(
              CupertinoIcons.checkmark_seal_fill,
              l10n.delivered,
              l10n.deliveredDesc,
              theme.primaryColor,
            ),
            _buildHelpItem(
              CupertinoIcons.xmark_circle_fill,
              l10n.cancelled,
              l10n.cancelledDesc,
              Colors.red.shade600,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.headphones,
                      color: theme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.needImmediateHelp,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: theme.primaryColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          l10n.supportStaffReady,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final EdgeInsets? margin;

  const _TopIconButton({required this.icon, required this.onTap, this.margin});

  @override
  State<_TopIconButton> createState() => _TopIconButtonState();
}

class _TopIconButtonState extends State<_TopIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: widget.margin ?? EdgeInsets.zero,
        child: GestureDetector(
          onTapDown: (_) {
            HapticFeedback.lightImpact();
            _controller.forward();
          },
          onTapUp: (_) => _controller.reverse(),
          onTapCancel: () => _controller.reverse(),
          onTap: widget.onTap,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Icon(widget.icon, size: 18, color: Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final Order order;
  final VoidCallback onRefresh;
  const _OrderCard({required this.order, required this.onRefresh});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _cardController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _arrowSlideAnimation;

  String getLocalizedOrderStatus(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'processing':
        return l10n.processing;
      case 'shipped':
        return l10n.shipped;
      case 'out_for_delivery':
      case 'out for delivery':
        return l10n.outForDelivery;
      case 'delivered':
        return l10n.delivered;
      case 'cancelled':
        return l10n.cancelled;
      default:
        return status;
    }
  }

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeInOutCubic),
    );
    _arrowSlideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(4.0, 0.0)).animate(
          CurvedAnimation(
            parent: _cardController,
            curve: Curves.easeInOutCubic,
          ),
        );
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _getStatusColor(widget.order.orderStatus, theme);
    final isPartial = widget.order.paymentMethod.toLowerCase() == 'partial';

    return GestureDetector(
      onTapDown: (_) => _cardController.forward(),
      onTapUp: (_) {
        _cardController.reverse();
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(order: widget.order),
          ),
        ).then((_) {
          widget.onRefresh();
        });
      },
      onTapCancel: () => _cardController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: ID & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            CupertinoIcons.doc_text_fill,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${l10n.orderIdLabel}${widget.order.orderId.substring(widget.order.orderId.length - 8).toUpperCase()}",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey.shade700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    _buildStatusBadge(
                      widget.order.orderStatus,
                      statusColor,
                      l10n,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildDashedDivider(),
                const SizedBox(height: 8),
                // Product details row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildProductPreview(widget.order),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TranslatableText(
                            widget.order.items.first.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.order.orderStatus.toLowerCase() ==
                                    'cancelled'
                                ? "${l10n.itemsCount(widget.order.items.length)} • ${l10n.cancelledOn(DateFormat('dd MMM yyyy').format(widget.order.cancelledAt ?? widget.order.createdAt))}"
                                : "${l10n.itemsCount(widget.order.items.length)} • ${DateFormat('dd MMM yyyy').format(widget.order.placedAt ?? widget.order.createdAt)}",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (!isPartial)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  "₹${widget.order.totalAmount.toStringAsFixed(0)}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: theme.primaryColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    l10n.paid,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _arrowSlideAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: _arrowSlideAnimation.value,
                          child: child,
                        );
                      },
                      child: Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
                // Compact Partial Payment Breakdown Row
                if (isPartial) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade100),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.checkmark_shield_fill,
                              size: 14,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.advancePaid(
                                (widget.order.advanceAmount ?? 0)
                                    .toStringAsFixed(0),
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: theme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 12,
                          color: Colors.orange.shade200,
                        ),
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.clock_fill,
                              size: 14,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.remainingDue(
                                (widget.order.remainingAmount ?? 0)
                                    .toStringAsFixed(0),
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            getLocalizedOrderStatus(status, l10n).toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey.shade200),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductPreview(Order order) {
    final firstItem = order.items.first;
    final url = firstItem.image ?? '';
    final hasMultiple = order.items.length > 1;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: url.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade100,
                      child: const Center(child: CupertinoActivityIndicator()),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      CupertinoIcons.photo,
                      color: Colors.grey,
                      size: 20,
                    ),
                  )
                : const Icon(
                    CupertinoIcons.photo,
                    color: Colors.grey,
                    size: 20,
                  ),
          ),
          if (hasMultiple)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "+${order.items.length - 1}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'processing':
        return Colors.orange.shade600;
      case 'shipped':
        return Colors.blue.shade600;
      case 'out_for_delivery':
      case 'out for delivery':
        return Colors.purple.shade600;
      case 'delivered':
        return theme.primaryColor;
      case 'cancelled':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}

class _OrderShimmerCard extends StatefulWidget {
  const _OrderShimmerCard();

  @override
  State<_OrderShimmerCard> createState() => _OrderShimmerCardState();
}

class _OrderShimmerCardState extends State<_OrderShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _shimmerBlock({
    double? height,
    double? width,
    double margin = 0,
    double borderRadius = 4,
  }) {
    return Container(
      height: height,
      width: width,
      margin: EdgeInsets.all(margin),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [
            0.1 + _animation.value * 0.1,
            0.5 + _animation.value * 0.1,
            0.9 + _animation.value * 0.1,
          ],
          colors: [Colors.white, Colors.grey.shade50, Colors.white],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _shimmerBlock(height: 16, width: 110, borderRadius: 6),
                  _shimmerBlock(height: 24, width: 70, borderRadius: 12),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _shimmerBlock(height: 50, width: 50, borderRadius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmerBlock(height: 14, width: 140, borderRadius: 4),
                        const SizedBox(height: 6),
                        _shimmerBlock(height: 12, width: 90, borderRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _shimmerBlock(height: 14, width: 80, borderRadius: 4),
                  _shimmerBlock(height: 16, width: 60, borderRadius: 4),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
