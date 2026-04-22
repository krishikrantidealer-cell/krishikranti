import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/core/cart_service.dart';
import 'package:krishikranti/screens/my_orders_screen.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final Color primaryGreen = const Color(0xFF2E7D32);
  String selectedMethod = "cod";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Payment Method",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildPaymentOption(
            id: "cod",
            title: "Cash on Delivery",
            subtitle: "Pay when you receive the order",
            icon: Icons.payments_outlined,
          ),
          _buildPaymentOption(
            id: "upi",
            title: "UPI (PhonePe / Google Pay / BHIM)",
            subtitle: "Instant payment using any UPI app",
            icon: Icons.account_balance_wallet_outlined,
          ),
          _buildPaymentOption(
            id: "card",
            title: "Credit / Debit Card",
            subtitle: "Visa, Mastercard, RuPay, etc.",
            icon: Icons.credit_card_outlined,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              final cartService = CartService();
              OrderService().placeOrder(
                List.from(cartService.items),
                cartService.totalAmount,
              );
              cartService.clear();
              
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
                (route) => route.isFirst,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text(
              "Confirm & Pay",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = selectedMethod == id;

    return GestureDetector(
      onTap: () => setState(() => selectedMethod = id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryGreen : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? primaryGreen.withValues(alpha: 0.1) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? primaryGreen : Colors.grey, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
              color: isSelected ? primaryGreen : Colors.grey.shade300,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
