import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:krishikranti/features/orders/data/repositories/order_repository.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:krishikranti/core/cart_service.dart';
import 'package:krishikranti/features/orders/data/models/order_model.dart';
import 'package:intl/intl.dart';
import 'package:krishikranti/core/utils/translatable_text.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order? order;
  final String? orderId;

  const OrderDetailScreen({
    super.key,
    this.order,
    this.orderId,
  }) : assert(order != null || orderId != null, 'Either order or orderId must be provided');

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _pulseController;
  late AnimationController _timelineController;
  Order? _currentOrder;
  bool _isLoading = false;
  bool _isCancelling = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _timelineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (_currentOrder != null) {
      _startAnimations();
    } else if (widget.orderId != null) {
      _fetchOrderDetails();
    }
  }

  Future<void> _fetchOrderDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orderRepo = OrderRepository();
      final order = await orderRepo.getOrderDetails(widget.orderId!);
      if (mounted) {
        setState(() {
          _currentOrder = order;
          _isLoading = false;
        });
        _startAnimations();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _startAnimations() {
    _entranceController.forward().then((_) {
      if (_currentOrder == null) return;
      final status = _currentOrder!.orderStatus.toLowerCase();
      int targetStep = 0;
      if (status == 'processing') {
        targetStep = 1;
      } else if (status == 'shipped') {
        targetStep = 2;
      } else if (status == 'out_for_delivery' || status == 'out for delivery') {
        targetStep = 3;
      } else if (status == 'delivered') {
        targetStep = 4;
      }

      if (targetStep > 0 && mounted) {
        _timelineController.animateTo(
          targetStep / 4,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOutQuart,
        );
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _timelineController.dispose();
    super.dispose();
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

  Widget _buildAnimatedSection({required Widget child, required int index}) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, childWidget) {
        final double start = (index * 0.12).clamp(0.0, 1.0);
        final double end = (start + 0.4).clamp(0.0, 1.0);
        final CurvedAnimation sectionCurve = CurvedAnimation(
          parent: _entranceController,
          curve: Interval(start, end, curve: Curves.easeOutQuart),
        );
        final Animation<Offset> slide = Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(sectionCurve);
        final Animation<double> fade = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(sectionCurve);

        return Opacity(
          opacity: fade.value,
          child: Transform.translate(
            offset: Offset(0, slide.value.dy * 40),
            child: childWidget,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Order Details"),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
        ),
        body: const Center(
          child: CupertinoActivityIndicator(radius: 15),
        ),
      );
    }

    if (_error != null || _currentOrder == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Order Details"),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.exclamationmark_triangle,
                    size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(_error ?? "Failed to load order",
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _fetchOrderDetails,
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final statusColor = _getStatusColor(_currentOrder!.orderStatus, theme);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Order Details",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 17,
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
      ),
      body: Stack(
        children: [
          // Subtle ambient backdrop glows
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            top: 250,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade600.withValues(alpha: 0.03),
              ),
            ),
          ),
          // Scrollable compact sections
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    14,
                    MediaQuery.of(context).padding.top + 56,
                    14,
                    24,
                  ),
                  child: Column(
                    children: [
                      _buildAnimatedSection(
                        index: 0,
                        child: _buildCombinedHeaderAndTracking(
                          theme,
                          statusColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAnimatedSection(
                        index: 1,
                        child: _buildCompactItemsList(theme),
                      ),
                      const SizedBox(height: 12),
                      _buildAnimatedSection(
                        index: 2,
                        child: _buildCompactDeliveryInfo(theme),
                      ),
                      const SizedBox(height: 12),
                      _buildAnimatedSection(
                        index: 3,
                        child: _buildCompactPaymentSummary(theme),
                      ),
                    ],
                  ),
                ),
              ),
              _buildBottomActions(context, theme),
            ],
          ),
        ],
      ),
    );
  }

  DateTime _getStepTimestamp(int index) {
    switch (index) {
      case 0:
        return _currentOrder!.placedAt ?? _currentOrder!.createdAt;
      case 1:
        return _currentOrder!.processingAt ??
            _currentOrder!.createdAt.add(const Duration(hours: 2));
      case 2:
        return _currentOrder!.shippedAt ??
            _currentOrder!.createdAt.add(const Duration(hours: 4));
      case 3:
        return _currentOrder!.outForDeliveryAt ??
            _currentOrder!.createdAt.add(const Duration(hours: 6));
      case 4:
        return _currentOrder!.deliveredAt ??
            _currentOrder!.createdAt.add(const Duration(hours: 8));
      default:
        return _currentOrder!.createdAt;
    }
  }

  Widget _buildCombinedHeaderAndTracking(ThemeData theme, Color statusColor) {
    final List<String> steps = [
      "Order Placed",
      "Processing",
      "Shipped",
      "Out for Delivery",
      "Delivered",
    ];
    final List<String> stepDescriptions = [
      "We have received your order",
      "Your items are being packed",
      "Package is in transit",
      "Out for final delivery today",
      "Package delivered successfully",
    ];

    int currentStep = 0;
    final status = _currentOrder!.orderStatus.toLowerCase();
    if (status == 'processing') {
      currentStep = 1;
    } else if (status == 'shipped') {
      currentStep = 2;
    } else if (status == 'out_for_delivery' || status == 'out for delivery') {
      currentStep = 3;
    } else if (status == 'delivered') {
      currentStep = 4;
    }
    bool isCancelled = status == "cancelled";

    final hasTrackingInfo =
        _currentOrder!.awbNumber?.isNotEmpty == true ||
        _currentOrder!.trackingUrl?.isNotEmpty == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order #${_currentOrder!.orderId}",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Placed on ${DateFormat('dd MMM yyyy, hh:mm a').format(_currentOrder!.placedAt ?? _currentOrder!.createdAt)}",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currentOrder!.orderStatus.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildDashedDivider(),
          const SizedBox(height: 18),

          Text(
            "Tracking History",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 20),

          if (isCancelled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "This order has been cancelled",
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Cancelled on ${DateFormat('dd MMM yyyy, hh:mm a').format(_currentOrder!.cancelledAt ?? _currentOrder!.createdAt)}",
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Vertical Timeline Stepper
            Column(
              children: List.generate(steps.length, (index) {
                bool isCompleted = index <= currentStep;
                bool isCurrent = index == currentStep;
                bool isLast = index == steps.length - 1;

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Node & Vertical Line Column
                      SizedBox(
                        width: 36,
                        child: Column(
                          children: [
                            AnimatedBuilder(
                              animation: Listenable.merge([
                                _timelineController,
                                _pulseController,
                              ]),
                              builder: (context, child) {
                                final nodeActive =
                                    _timelineController.value >=
                                    (index / (steps.length - 1)).clamp(
                                          0.0,
                                          1.0,
                                        ) -
                                        0.05;
                                final nodeCompleted =
                                    index < currentStep && nodeActive;
                                final nodeCurrent =
                                    index == currentStep && nodeActive;

                                return Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: nodeCompleted || nodeCurrent
                                        ? theme.primaryColor
                                        : Colors.white,
                                    border: Border.all(
                                      color: nodeCompleted || nodeCurrent
                                          ? theme.primaryColor
                                          : Colors.grey.shade200,
                                      width: 2.5,
                                    ),
                                    boxShadow: nodeCurrent
                                        ? [
                                            BoxShadow(
                                              color: theme.primaryColor
                                                  .withValues(
                                                    alpha:
                                                        0.35 *
                                                        _pulseController.value,
                                                  ),
                                              blurRadius: 10,
                                              spreadRadius:
                                                  3 * _pulseController.value,
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: nodeCompleted
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                        )
                                      : Center(
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: nodeCurrent
                                                  ? Colors.white
                                                  : Colors.transparent,
                                            ),
                                          ),
                                        ),
                                );
                              },
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2.5,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: index < currentStep
                                        ? theme.primaryColor
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Text & Details Column
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    steps[index],
                                    style: TextStyle(
                                      fontWeight: isCurrent || isCompleted
                                          ? FontWeight.w900
                                          : FontWeight.w600,
                                      color: isCurrent || isCompleted
                                          ? Colors.black87
                                          : Colors.grey.shade400,
                                      fontSize: 15,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  if (isCompleted || isCurrent)
                                    Text(
                                      DateFormat(
                                        'hh:mm a',
                                      ).format(_getStepTimestamp(index)),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isCurrent
                                            ? theme.primaryColor
                                            : Colors.grey.shade500,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                stepDescriptions[index],
                                style: TextStyle(
                                  color: isCurrent || isCompleted
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade400,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),

            // Courier & Backend Tracking Details Box
            if (hasTrackingInfo) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        CupertinoIcons.cube_box_fill,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentOrder!.courierName?.isNotEmpty == true
                                ? "Courier: ${_currentOrder!.courierName!}"
                                : "Delivery Partner: Shiprocket",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.blue.shade900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currentOrder!.awbNumber?.isNotEmpty == true
                                ? "AWB: ${_currentOrder!.awbNumber!}"
                                : "Tracking ID:${_currentOrder!.orderId}",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          if (_currentOrder!.trackingUrl?.isNotEmpty == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Redirecting to ${_currentOrder!.trackingUrl}...",
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else if (_currentOrder!.awbNumber?.isNotEmpty ==
                              true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Redirecting to https://shiprocket.co/tracking/${_currentOrder!.awbNumber!}...",
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Live Shiprocket tracking will activate once AWB is assigned.",
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Track",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCompactItemsList(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Items Ordered (${_currentOrder!.items.length})",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: _currentOrder!.items.length,
            separatorBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: Colors.grey.shade100),
            ),
            itemBuilder: (context, index) {
              final item = _currentOrder!.items[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: CachedNetworkImage(
                        imageUrl: item.image ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade50,
                          child: const Center(
                            child: CupertinoActivityIndicator(radius: 8),
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          CupertinoIcons.photo,
                          color: Colors.grey,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TranslatableText(
                          item.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Variant: Standard",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Qty: ${item.quantity}",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              "₹${(item.price * item.quantity).toStringAsFixed(0)}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: theme.primaryColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDeliveryInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Delivery Address",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.location_solid,
                  color: theme.primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatableText(
                      _currentOrder!.shippingAddress.name?.isNotEmpty == true
                          ? _currentOrder!.shippingAddress.name!
                          : "Shipping Address",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TranslatableText(
                      [
                        if (_currentOrder!
                                .shippingAddress
                                .villageArea
                                ?.isNotEmpty ==
                            true)
                          _currentOrder!.shippingAddress.villageArea!,
                        if (_currentOrder!
                                .shippingAddress
                                .cityTehsil
                                ?.isNotEmpty ==
                            true)
                          _currentOrder!.shippingAddress.cityTehsil!,
                        _currentOrder!.shippingAddress.state?.isNotEmpty == true
                            ? _currentOrder!.shippingAddress.state!
                            : "Maharashtra",
                        if (_currentOrder!.shippingAddress.pincode?.isNotEmpty ==
                            true)
                          "Pin: ${_currentOrder!.shippingAddress.pincode!}",
                      ].join(", "),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                    if (_currentOrder!.shippingAddress.phoneNumber?.isNotEmpty ==
                        true) ...[
                      const SizedBox(height: 4),
                      Text(
                        "Phone: ${_currentOrder!.shippingAddress.phoneNumber!}",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPaymentSummary(ThemeData theme) {
    bool isPartial = _currentOrder!.paymentMethod.toLowerCase() == 'partial';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Payment Summary",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          _summaryRow(
            "Subtotal",
            "₹${_currentOrder!.totalAmount.toStringAsFixed(0)}",
          ),
          _summaryRow("Shipping Fee", "FREE", isGreen: true),
          _summaryRow("Tax (Included)", "₹0"),
          if (isPartial) ...[
            _summaryRow(
              "Paid Advance Deposit",
              "₹${(_currentOrder!.advanceAmount ?? 0).toStringAsFixed(0)}",
              isGreen: true,
            ),
            _summaryRow(
              "Remaining Balance at Delivery",
              "₹${(_currentOrder!.remainingAmount ?? 0).toStringAsFixed(0)}",
              isOrange: true,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPartial ? "Paid Advance Amount" : "Total Amount",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                "₹${(isPartial ? (_currentOrder!.advanceAmount ?? 0) : _currentOrder!.totalAmount).toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: theme.primaryColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          if (isPartial) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Order Total: ₹${_currentOrder!.totalAmount.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPartial ? Colors.orange.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isPartial ? CupertinoIcons.info_circle_fill : Icons.security,
                  color: isPartial
                      ? Colors.orange.shade800
                      : Colors.green.shade700,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isPartial
                        ? "Advance paid via Razorpay. Remaining due at delivery."
                        : "Payment via Razorpay • Secured by SSL",
                    style: TextStyle(
                      fontSize: 11,
                      color: isPartial
                          ? Colors.orange.shade900
                          : Colors.green.shade800,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isGreen = false,
    bool isOrange = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isGreen
                  ? Colors.green.shade700
                  : isOrange
                  ? Colors.orange.shade800
                  : Colors.black87,
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

  Widget _buildBottomActions(BuildContext context, ThemeData theme) {
    final status = _currentOrder!.orderStatus.toLowerCase();
    final canCancel = status == 'pending' || status == 'processing';

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            border: Border(top: BorderSide(color: Colors.grey.shade100)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              if (canCancel) ...[
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _isCancelling
                          ? null
                          : () => _showCancelConfirmation(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.red.shade200,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: Colors.red.shade50.withValues(
                          alpha: 0.5,
                        ),
                        foregroundColor: Colors.red.shade700,
                      ),
                      child: _isCancelling
                          ? const CupertinoActivityIndicator()
                          : const Text(
                              "Cancel Order",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ] else ...[
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pushNamed(context, '/contact');
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                      ),
                      child: const Text(
                        "Support",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      final cartService = Provider.of<CartService>(
                        context,
                        listen: false,
                      );
                      for (var item in _currentOrder!.items) {
                        cartService.addItem(
                          productId: item.productId,
                          variantId: item.variantId,
                          productName: item.title,
                          productImage: item.image ?? '',
                          technicalName: "Generic",
                          variant: "Standard",
                          price: item.price,
                          qty: item.quantity,
                        );
                      }
                      Navigator.pushNamed(context, '/cart');
                    },
                    icon: const Icon(
                      CupertinoIcons.refresh_thick,
                      color: Colors.white,
                      size: 16,
                    ),
                    label: const Text(
                      "Buy it Again",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: -0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: theme.primaryColor.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCancelConfirmation(BuildContext context) async {
    HapticFeedback.heavyImpact();
    final shouldCancel = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Cancel Order?"),
        content: const Text(
          "Are you sure you want to cancel this order? This action cannot be undone.",
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("No"),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("Yes, Cancel"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (shouldCancel == true && mounted) {
      setState(() => _isCancelling = true);
      try {
        final updatedOrder = await OrderRepository().cancelOrder(
          _currentOrder!.id,
        );
        if (mounted) {
          setState(() {
            _currentOrder = updatedOrder;
            _isCancelling = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Order cancelled successfully")),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isCancelling = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Cancellation failed: $e")));
        }
      }
    }
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(widget.icon, size: 18, color: Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}
