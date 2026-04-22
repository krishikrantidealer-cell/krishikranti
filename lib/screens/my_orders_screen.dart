import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:lottie/lottie.dart';
import 'package:krishikranti/core/cart_service.dart';
import 'package:krishikranti/screens/order_detail_screen.dart';
import 'package:krishikranti/screens/product_list_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final List<String> _tabs = ["All Orders", "Processing", "Delivered", "Cancelled"];
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF2E7D32);
    final allOrders = OrderService().orders;
    
    final filteredOrders = allOrders.where((order) {
      if (_selectedTabIndex == 0) return true;
      return order.status == _tabs[_selectedTabIndex];
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Orders",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildTabs(primaryGreen),
          Expanded(
            child: filteredOrders.isEmpty
                ? _buildEmptyState(context, primaryGreen)
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _OrderCard(order: filteredOrders[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(Color primaryGreen) {
    return Container(
      color: Colors.white,
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final isSelected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? primaryGreen : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _tabs[index],
                style: TextStyle(
                  color: isSelected ? primaryGreen : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Color primaryGreen) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/orders_empty.json',
              height: 200,
              repeat: true,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Text(
              _selectedTabIndex == 0 ? "No orders yet" : "No orders found",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            if (_selectedTabIndex == 0) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const ProductListScreen(category: "All")),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text("Start Shopping", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF2E7D32);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      "Order ${order.orderId}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.date,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  flex: 2,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...order.items.take(3).map((item) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.productImage,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )),
                        if (order.items.length > 3)
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                "+${order.items.length - 3}",
                                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "₹${order.totalAmount.toStringAsFixed(0)}",
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: primaryGreen),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${order.items.length} items",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailScreen(order: order),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryGreen.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  "View Details",
                  style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case "Processing":
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        break;
      case "Shipped":
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        break;
      case "Delivered":
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case "Cancelled":
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
