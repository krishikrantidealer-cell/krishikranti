import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:krishikranti/core/cart_service.dart';
import 'package:krishikranti/features/orders/data/models/order_model.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Order Details",
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildOrderHeader(theme),
            _buildStatusStepper(theme),
            _buildItemsList(theme),
            _buildDeliveryInfo(theme),
            _buildPaymentSummary(theme),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomSheet: _buildBottomActions(context, theme),
    );
  }

  Widget _buildOrderHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Order #${order.orderId}",
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Placed on ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt)}",
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "E-Receipt",
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStepper(ThemeData theme) {
    final List<String> steps = ["Placed", "Processing", "Shipped", "Delivered"];
    int currentStep = 1;
    if (order.orderStatus.toLowerCase() == "shipped") currentStep = 2;
    if (order.orderStatus.toLowerCase() == "delivered") currentStep = 3;
    if (order.orderStatus.toLowerCase() == "cancelled") currentStep = -1;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Track Order",
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: List.generate(steps.length, (index) {
              bool isCompleted = index < currentStep;
              bool isCurrent = index == currentStep;
              bool isLast = index == steps.length - 1;

              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: index == 0
                              ? const SizedBox()
                              : Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: index <= currentStep ? theme.primaryColor : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted || isCurrent ? theme.primaryColor : Colors.white,
                            border: Border.all(
                              color: isCompleted || isCurrent ? theme.primaryColor : Colors.grey.shade300,
                              width: 2,
                            ),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: theme.primaryColor.withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : [],
                          ),
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.white, size: 14)
                              : Center(
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isCurrent ? Colors.white : Colors.transparent,
                                    ),
                                  ),
                                ),
                        ),
                        Expanded(
                          child: isLast
                              ? const SizedBox()
                              : Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: index < currentStep ? theme.primaryColor : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      steps[index],
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: isCurrent || isCompleted ? FontWeight.bold : FontWeight.w500,
                        color: isCurrent || isCompleted ? Colors.black87 : Colors.grey.shade400,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Items (${order.items.length})",
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            separatorBuilder: (context, index) => Divider(height: 32, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final item = order.items[index];
              return Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.network(
                        item.image ?? '',
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 72,
                          height: 72,
                          color: Colors.grey.shade50,
                          child: const Icon(CupertinoIcons.photo, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Variant: Standard", // Backend items might not have variant name yet
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Qty: ${item.quantity}",
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              "₹${(item.price * item.quantity).toStringAsFixed(0)}",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: theme.primaryColor,
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

  Widget _buildDeliveryInfo(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Delivery Address",
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(CupertinoIcons.location_solid, color: theme.primaryColor, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Shipping to",
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${order.shippingAddress.villageArea ?? 'Address'}, ${order.shippingAddress.cityTehsil ?? ''}\nPincode: ${order.shippingAddress.pincode ?? ''}",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Payment Summary",
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _summaryRow(theme, "Subtotal", "₹${order.totalAmount.toStringAsFixed(0)}"),
          _summaryRow(theme, "Shipping Fee", "FREE", isGreen: true),
          _summaryRow(theme, "Tax (Included)", "₹0"),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Amount",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(
                "₹${order.totalAmount.toStringAsFixed(0)}",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: Colors.green.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Payment via Razorpay • Secured by SSL",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w600,
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

  Widget _summaryRow(ThemeData theme, String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isGreen ? Colors.green.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  final cartService = Provider.of<CartService>(context, listen: false);
                  for (var item in order.items) {
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
                icon: const Icon(CupertinoIcons.refresh_thick, color: Colors.white, size: 18),
                label: const Text("Buy it Again"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 54,
              child: OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, '/contact');
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  foregroundColor: Colors.black87,
                ),
                child: const Text("Support"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
