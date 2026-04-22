import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:krishikranti/core/cart_service.dart';
import 'package:krishikranti/screens/product_list_screen.dart';

import 'package:krishikranti/screens/complete_payment_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final cartService = CartService();
  final Color primaryGreen = const Color(0xFF2E7D32);

  String? selectedPaymentMethod; // 'online' or 'partial'
  String? selectedCoupon;
  double discountAmount = 0.0;
  int? selectedPartialPercent; // 10, 20, 50

  final List<Map<String, dynamic>> coupons = [
    {'code': 'SAVE10', 'discount': 10, 'type': 'percent'},
    {'code': 'SAVE20', 'discount': 20, 'type': 'percent'},
    {'code': 'SAVE30', 'discount': 30, 'type': 'percent'},
    {'code': 'FLAT500', 'discount': 500.0, 'type': 'flat'},
    {'code': 'SUPER50', 'discount': 50, 'type': 'percent'},
  ];

  double get cartTotal => cartService.totalAmount;

  double get finalTotal => (cartTotal - discountAmount).clamp(0.0, double.infinity);

  double get advanceAmount {
    if (selectedPaymentMethod == 'partial' && selectedPartialPercent != null) {
      return finalTotal * (selectedPartialPercent! / 100);
    }
    return 0.0;
  }

  double get remainingAmount {
    return finalTotal - advanceAmount;
  }

  void _applyCoupon(String? code) {
    if (code == null) {
      setState(() {
        selectedCoupon = null;
        discountAmount = 0.0;
      });
      return;
    }

    final coupon = coupons.firstWhere((c) => c['code'] == code);
    setState(() {
      selectedCoupon = code;
      if (coupon['type'] == 'percent') {
        discountAmount = cartTotal * (coupon['discount'] / 100);
      } else {
        discountAmount = coupon['discount'];
      }
    });

    // Show Success Animation/Snackbar
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text("🎉 ", style: TextStyle(fontSize: 20)),
            Expanded(
              child: Text(
                "Coupon '$code' Applied Successfully!",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
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
          icon: const Icon(CupertinoIcons.back, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Payment",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderSummary(),
            const SizedBox(height: 16),
            _buildCouponSection(),
            if (discountAmount > 0) ...[
              const SizedBox(height: 12),
              _buildSavingsBanner(),
            ],
            const SizedBox(height: 16),
            _buildTrustBadges(),
            const SizedBox(height: 24),
            const Text(
              "Select Payment Method",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildOnlinePaymentOption(),
            const SizedBox(height: 12),
            _buildPartialPaymentOption(),
            const SizedBox(height: 24),
            if (selectedPaymentMethod != null) _buildCalculationSummary(),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomSection(),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Order Total", style: TextStyle(color: Colors.grey, fontSize: 15)),
                Text("₹${cartTotal.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Grand Total", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  "₹${finalTotal.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.w800, 
                    color: Colors.black,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(CupertinoIcons.tag, size: 20, color: Colors.orange),
                const SizedBox(width: 8),
                const Text("Apply Coupon", style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                DropdownButton<String>(
                  hint: const Text("Select Coupon", style: TextStyle(fontSize: 13)),
                  underline: const SizedBox(),
                  value: selectedCoupon,
                  items: coupons.map((coupon) {
                    return DropdownMenuItem<String>(
                      value: coupon['code'],
                      child: Text(coupon['code'], style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (value) => _applyCoupon(value),
                ),
              ],
            ),
            if (selectedCoupon != null) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Coupon Applied: $selectedCoupon",
                    style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  TextButton(
                    onPressed: () => _applyCoupon(null),
                    child: const Text("Remove", style: TextStyle(color: Colors.red, fontSize: 12)),
                  )
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.sparkles, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Text(
            "You saved ₹${discountAmount.toStringAsFixed(0)} with this coupon 🎉",
            style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _trustBadge(CupertinoIcons.lock_shield, "Secure\nPayment"),
        _trustBadge(CupertinoIcons.doc_text, "GST\nInvoice"),
        _trustBadge(Icons.local_shipping_outlined, "Fast\nDelivery"),
      ],
    );
  }

  Widget _trustBadge(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildOnlinePaymentOption() {
    bool isSelected = selectedPaymentMethod == 'online';
    return InkWell(
      onTap: () {
        setState(() {
          selectedPaymentMethod = 'online';
          selectedPartialPercent = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? primaryGreen : Colors.grey.shade200, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? primaryGreen : Colors.grey, width: 2),
              ),
              child: isSelected
                  ? Center(child: Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: primaryGreen)))
                  : null,
            ),
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Online Payment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("Pay full amount using UPI, Card", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPartialPaymentOption() {
    bool isSelected = selectedPaymentMethod == 'partial';
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              selectedPaymentMethod = 'partial';
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? primaryGreen : Colors.grey.shade200, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? primaryGreen : Colors.grey, width: 2),
                  ),
                  child: isSelected
                      ? Center(child: Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: primaryGreen)))
                      : null,
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Partial Payment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Pay a percentage now, rest later", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                Icon(isSelected ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down, size: 20),
              ],
            ),
          ),
        ),
        if (isSelected)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [10, 20, 50].map((percent) {
                bool isPercentSelected = selectedPartialPercent == percent;
                return ChoiceChip(
                  label: Text("$percent%"),
                  selected: isPercentSelected,
                  onSelected: (selected) {
                    setState(() {
                      selectedPartialPercent = selected ? percent : null;
                    });
                  },
                  selectedColor: primaryGreen.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isPercentSelected ? primaryGreen : Colors.black,
                    fontWeight: isPercentSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildCalculationSummary() {
    return Card(
      elevation: 0,
      color: primaryGreen.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _summaryRow("Final Total", finalTotal, isBold: true),
            if (selectedPaymentMethod == 'partial' && selectedPartialPercent != null) ...[
              const SizedBox(height: 8),
              _summaryRow("Advance Payment ($selectedPartialPercent%)", advanceAmount, color: primaryGreen),
              const Divider(),
              _summaryRow("Remaining Amount", remainingAmount, isBold: true),
            ]
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 15)),
        Text(
          "₹${amount.toStringAsFixed(0)}",
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 16 : 15,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    bool isOnline = selectedPaymentMethod == 'online';
    bool isPartial = selectedPaymentMethod == 'partial' && selectedPartialPercent != null;
    bool isEnabled = isOnline || isPartial;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isEnabled) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isOnline ? "Payable Amount:" : "Pay Now:",
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "₹${(isOnline ? finalTotal : advanceAmount).toStringAsFixed(0)}",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: primaryGreen),
                      ),
                    ),
                  ],
                ),
              ),
              if (isPartial)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Remaining Amount:", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                      Text("₹${remainingAmount.toStringAsFixed(0)}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
                    ],
                  ),
                ),
            ],
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isEnabled ? () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => CompletePaymentScreen(
                        finalTotal: finalTotal,
                        paymentType: selectedPaymentMethod!,
                        advanceAmount: advanceAmount,
                      ),
                    ),
                  );
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text("Proceed to Pay", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
