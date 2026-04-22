import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:lottie/lottie.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/core/cart_service.dart';
import 'package:krishikranti/screens/product_detail_screen.dart';
import 'package:krishikranti/screens/shipping_address_screen.dart';
import 'package:krishikranti/screens/product_list_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Color primaryGreen = const Color(0xFF2E7D32);
  final cartService = CartService();

  @override
  Widget build(BuildContext context) {
    final items = cartService.items;
    bool isEmpty = items.isEmpty;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.cart,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: isEmpty
          ? _buildEmptyState(l10n)
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _CartItemRow(
                        item: item,
                        onDelete: () {
                          setState(() {
                            cartService.removeItem(index);
                          });
                        },
                        onUpdate: () => setState(() {}),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(productName: item.productName),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                _buildSummary(l10n),
              ],
            ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/cart_empty.json',
              height: 180,
              repeat: true,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const Text(
              "Your cart is empty",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
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
                child: const Text("Go to Products", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Items", style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500)),
                Text("${cartService.totalCount}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFEEEEEE), thickness: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Grand Total", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  "₹${cartService.totalAmount.toStringAsFixed(0)}",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: primaryGreen),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (cartService.items.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ShippingAddressScreen()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  l10n.confirmOrder,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  final CartItem item;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;
  final VoidCallback onTap;

  const _CartItemRow({
    required this.item,
    required this.onDelete,
    required this.onUpdate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF2E7D32);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT SECTION: Product Image (fixed size 70–80)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item.productImage,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // RIGHT SECTION (EXPANDED)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TOP ROW: Name and Price
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      height: 1.2,
                                    ),
                                  ),
                                  Text(
                                    item.technicalName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "₹${(item.price * item.qty).toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: primaryGreen,
                              ),
                            ),
                          ],
                        ),
                        // MIDDLE ROW: Pack Size
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.variant,
                              style: const TextStyle(
                                color: primaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        // BOTTOM ROW: Quantity and Delete
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // LEFT: Quantity control
                              Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _qtyBtn(CupertinoIcons.minus, () {
                                      if (item.qty > 1) {
                                        item.qty -= 1;
                                        onUpdate();
                                      } else {
                                        onDelete();
                                      }
                                    }),
                                    Container(
                                      width: 32,
                                      alignment: Alignment.center,
                                      child: Text(
                                        "${item.qty}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    _qtyBtn(CupertinoIcons.plus, () {
                                      item.qty += 1;
                                      onUpdate();
                                    }),
                                  ],
                                ),
                              ),
                              // RIGHT: Delete button
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: onDelete,
                                  borderRadius: BorderRadius.circular(21),
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      CupertinoIcons.trash,
                                      color: Colors.red.shade600,
                                      size: 20,
                                    ),
                                  ),
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
          ),
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 40,
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: Colors.black87),
      ),
    );
  }
}



