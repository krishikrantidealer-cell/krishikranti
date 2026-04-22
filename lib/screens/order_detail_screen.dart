import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:krishikranti/core/cart_service.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF2E7D32);

    return Scaffold(
       backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Order Details",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildOrderInfo(),
            _buildStatusTracker(primaryGreen),
            _buildProductsList(primaryGreen),
            _buildShippingAddress(),
            _buildPriceSummary(primaryGreen),
            const SizedBox(height: 100), // Space for bottom buttons
          ],
        ),
      ),
      bottomSheet: _buildActionButtons(primaryGreen),
    );
  }

  Widget _buildOrderInfo() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Order #${order.orderId}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(
            "Placed on ${order.date}",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTracker(Color primaryGreen) {
    final List<String> steps = ["Order Placed", "Processing", "Shipped", "Delivered"];
    int currentStep = 1; // Default "Processing"
    if (order.status == "Shipped") currentStep = 2;
    if (order.status == "Delivered") currentStep = 3;
    if (order.status == "Cancelled") currentStep = -1;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Order Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 16),
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
                        Expanded(child: Container(height: 2, color: index == 0 ? Colors.transparent : (isCompleted || isCurrent ? primaryGreen : Colors.grey.shade300))),
                        Icon(
                          isCompleted ? Icons.check_circle : (isCurrent ? Icons.radio_button_checked : Icons.radio_button_off),
                          color: isCompleted || isCurrent ? primaryGreen : Colors.grey.shade300,
                          size: 22,
                        ),
                        Expanded(child: Container(height: 2, color: isLast ? Colors.transparent : (isCompleted ? primaryGreen : Colors.grey.shade300))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      steps[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent || isCompleted ? Colors.black87 : Colors.grey,
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

  Widget _buildProductsList(Color primaryGreen) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Products", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            separatorBuilder: (context, index) => Divider(height: 24, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final item = order.items[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(item.productImage, width: 64, height: 64, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(item.variant, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text("Qty: ${item.qty}", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text("₹${(item.price * item.qty).toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShippingAddress() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Shipping Address", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          const Text(
            "Sudhir Singh\nShop 12, Krishi Market, Indore, MP\n+91 9201896606",
            style: TextStyle(height: 1.4, color: Colors.black87, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary(Color primaryGreen) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Price Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          _summaryRow("Items Total", "₹${order.totalAmount.toStringAsFixed(0)}"),
          _summaryRow("Delivery Charges", "FREE", isGreen: true),
          const Divider(height: 24, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Order Total", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("₹${order.totalAmount.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: primaryGreen)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isGreen ? Colors.green : Colors.black)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Color primaryGreen) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.grey.shade50,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  "Download Invoice",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  "Contact Support",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
