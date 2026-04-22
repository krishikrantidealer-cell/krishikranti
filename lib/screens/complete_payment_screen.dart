import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:krishikranti/core/cart_service.dart';
import 'package:krishikranti/screens/my_orders_screen.dart';

class CompletePaymentScreen extends StatefulWidget {
  final double finalTotal;
  final String paymentType; // 'online' or 'partial'
  final double advanceAmount;

  const CompletePaymentScreen({
    super.key,
    required this.finalTotal,
    required this.paymentType,
    required this.advanceAmount,
  });

  @override
  State<CompletePaymentScreen> createState() => _CompletePaymentScreenState();
}

class _CompletePaymentScreenState extends State<CompletePaymentScreen> {
  final Color primaryGreen = const Color(0xFF2E7D32);
  final cartService = CartService();
  final orderService = OrderService();

  double get amountToPay => widget.paymentType == 'online' ? widget.finalTotal : widget.advanceAmount;

  void _processPayment() {
    // 1. Place Order in Service immediately
    orderService.placeOrder(cartService.items, widget.finalTotal);
    
    // 2. Clear Cart
    cartService.clear();

    // 3. Show Success Animation/Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(CupertinoIcons.check_mark_circled_solid, size: 80, color: primaryGreen),
              ),
              const SizedBox(height: 24),
              const Text(
                "🎉 Order Confirmed!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Your order has been placed successfully.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // 4. Navigate to My Orders
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
                      (route) => route.isFirst,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Go to My Orders", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Complete Payment",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildAmountHeader(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "UPI Options",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption("Google Pay", "assets/images/gpay.png", Icons.account_balance_wallet_outlined),
                  _buildPaymentOption("PhonePe", "assets/images/phonepe.png", Icons.account_balance_wallet_outlined),
                  _buildPaymentOption("Paytm", "assets/images/paytm.png", Icons.account_balance_wallet_outlined),
                  
                  const SizedBox(height: 24),
                  const Text(
                    "Cards (Credit/Debit)",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption("Add New Card", null, CupertinoIcons.creditcard),
                  
                  const SizedBox(height: 24),
                  const Text(
                    "Net Banking",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildNetBankingGrid(),
                  
                  const SizedBox(height: 32),
                  _buildTrustSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildAmountHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      color: Colors.white,
      child: Column(
        children: [
          const Text(
            "Amount to Pay",
            style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            "₹${amountToPay.toStringAsFixed(0)}",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: primaryGreen),
          ),
          if (widget.paymentType == 'partial') ...[
            const SizedBox(height: 8),
            Text(
              "Remaining: ₹${(widget.finalTotal - widget.advanceAmount).toStringAsFixed(0)}",
              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String title, String? assetPath, IconData icon) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryGreen, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(CupertinoIcons.chevron_right, size: 18, color: Colors.grey),
        onTap: () {},
      ),
    );
  }

  Widget _buildNetBankingGrid() {
    final banks = ["SBI", "HDFC", "Axis", "ICICI", "BOB"];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: banks.map((bank) => Container(
        width: (MediaQuery.of(context).size.width - 56) / 3,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text(
            bank,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildTrustSection() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.lock_shield_fill, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Text(
            "Secure Payment with KrishiDealer",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text("Pay Now", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
