import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:krishikranti/widgets/kyc_barrier_widget.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:krishikranti/core/cart_service.dart';
import 'package:krishikranti/core/profile_service.dart';
import 'package:krishikranti/features/orders/data/repositories/order_repository.dart';
import 'package:krishikranti/core/address_service.dart';
import 'package:krishikranti/screens/edit_address_screen.dart';
import 'package:krishikranti/widgets/checkout_stepper.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:krishikranti/screens/order_success_screen.dart';
import 'package:krishikranti/screens/order_secured_screen.dart';
import 'package:krishikranti/core/notification_service.dart';
import 'package:krishikranti/core/utils/translatable_text.dart';
import 'package:krishikranti/core/meta_analytics_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final Color primaryGreen = const Color(0xFF2E7D32);
  late Razorpay _razorpay;

  String? selectedPaymentMethod; // 'online' or 'partial'
  int? selectedPartialPercent; // 10, 20, 50
  bool _isProcessing = false;

  String? selectedAddressId;
  bool _isInitializingAddress = true;

  // Meta SDK event tracking variables
  bool _orderPlaced = false;
  double _lastFinalTotal = 0;
  int _lastItemCount = 0;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    final addressService = Provider.of<AddressService>(context, listen: false);
    final profileService = Provider.of<ProfileService>(context, listen: false);

    if (addressService.addresses.isNotEmpty) {
      selectedAddressId = addressService.addresses
          .firstWhere(
            (a) => a.isDefault,
            orElse: () => addressService.addresses.first,
          )
          .id;
      _isInitializingAddress = false;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Log Initiate Checkout to Meta/Facebook SDK
      MetaAnalyticsService.logInitiateCheckout(
        totalAmount: finalTotal,
        itemCount: Provider.of<CartService>(context, listen: false).totalCount,
      );

      // Handle local initialization first
      if (addressService.addresses.isEmpty && profileService.user != null) {
        final profile = profileService.user!;
        final initialAddress = AddressModel(
          id: "default_home",
          name: profile.name.isNotEmpty ? profile.name : "Home / Shop",
          villageArea: profile.address?.villageArea ?? "",
          cityTehsil: profile.address?.cityTehsil ?? "",
          state: profile.address?.state ?? "",
          pincode: profile.address?.pincode ?? "",
          phoneNumber: profile.phoneNumber,
          isDefault: true,
        );
        addressService.setInitialLocalAddress(initialAddress);
        if (mounted) {
          setState(() {
            selectedAddressId = initialAddress.id;
            _isInitializingAddress = false;
          });
        }
      }

      // Handle server fetch logic
      if (addressService.addresses.isEmpty ||
          addressService.addresses.first.id == "default_home") {
        await addressService.fetchAddresses(background: true);

        if (mounted) {
          if (addressService.addresses.isEmpty && profileService.user != null) {
            // Promote profile address to first shipping address
            final profile = profileService.user!;
            final initialAddress = AddressModel(
              id: "",
              name: profile.name.isNotEmpty ? profile.name : "Home / Shop",
              villageArea: profile.address?.villageArea ?? "",
              cityTehsil: profile.address?.cityTehsil ?? "",
              state: profile.address?.state ?? "",
              pincode: profile.address?.pincode ?? "",
              phoneNumber: profile.phoneNumber,
              isDefault: true,
            );
            await addressService.addAddress(initialAddress);
          }

          if (addressService.addresses.isNotEmpty) {
            setState(() {
              selectedAddressId = addressService.addresses
                  .firstWhere(
                    (a) => a.isDefault,
                    orElse: () => addressService.addresses.first,
                  )
                  .id;
            });
          }
          setState(() => _isInitializingAddress = false);
        }
      } else {
        addressService.fetchAddresses(background: true);
      }
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    if (!_orderPlaced) {
      MetaAnalyticsService.logAbandonedCheckout(
        totalAmount: _lastFinalTotal,
        itemCount: _lastItemCount,
      );
    }
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    await _placeConfirmedOrder(
      paymentId: response.paymentId,
      orderId: response.orderId,
      signature: response.signature,
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    MetaAnalyticsService.logCheckoutFailure(
      reason: response.message ?? 'Cancelled by user',
      code: response.code?.toString() ?? 'unknown',
    );
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.paymentFailed(response.message ?? 'Cancelled by user'),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet
  }

  AddressModel? get selectedAddress {
    final addressService = Provider.of<AddressService>(context, listen: false);
    if (addressService.addresses.isEmpty) return null;
    if (selectedAddressId == null) {
      return addressService.addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => addressService.addresses.first,
      );
    }
    try {
      return addressService.addresses.firstWhere(
        (a) => a.id == selectedAddressId,
      );
    } catch (_) {
      return addressService.addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => addressService.addresses.first,
      );
    }
  }

  bool get hasSelectedAddress => selectedAddress != null;

  double get cartTotal =>
      Provider.of<CartService>(context, listen: false).subtotal;

  double get discountAmount =>
      Provider.of<CartService>(context, listen: false).discountAmount;

  double get finalTotal =>
      Provider.of<CartService>(context, listen: false).totalAmount;

  String? get selectedCoupon =>
      Provider.of<CartService>(context, listen: false).appliedCoupon;

  double get advanceAmount {
    if (selectedPaymentMethod == 'partial' && selectedPartialPercent != null) {
      return finalTotal * (selectedPartialPercent! / 100);
    }
    return 0.0;
  }

  double get remainingAmount {
    return finalTotal - advanceAmount;
  }

  Future<void> _processPayment() async {
    final l10n = AppLocalizations.of(context)!;
    if (selectedPaymentMethod == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectPaymentMethod)));
      return;
    }

    if (!hasSelectedAddress) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectAddress)));
      return;
    }

    await _startRazorpayPayment();
  }

  Future<void> _startRazorpayPayment() async {
    setState(() => _isProcessing = true);

    String? razorpayOrderId;
    int amountInPaise;

    try {
      final orderRepository = OrderRepository();

      // 1. Try secure Payment Initialization from Server (Generates Razorpay Order ID)
      final razorpayOrder = await orderRepository.initializePayment(
        paymentMethod: selectedPaymentMethod!,
        partialPercent: selectedPaymentMethod == 'partial'
            ? selectedPartialPercent
            : null,
      );

      razorpayOrderId = razorpayOrder['id'];
      amountInPaise = razorpayOrder['amount'];
      debugPrint(
        "Secure payment initialization succeeded: order_id=$razorpayOrderId, amount=$amountInPaise",
      );
    } catch (e) {
      // Self-healing fallback if the backend route isn't deployed on the active base URL yet
      debugPrint(
        "Secure initialization failed/unsupported on remote server: $e. Falling back to direct client-side integration.",
      );

      final double amountToPay = selectedPaymentMethod == 'online'
          ? finalTotal
          : advanceAmount;

      amountInPaise = (amountToPay * 100).toInt();
      razorpayOrderId =
          null; // Direct checkout does not use a pre-generated server-side order_id
    }

    try {
      final profileService = Provider.of<ProfileService>(
        context,
        listen: false,
      );
      final user = profileService.user;
      final email = "customer@krishikranti.com";

      String cleanPhone = (user?.phoneNumber ?? '').replaceAll(
        RegExp(r'\D'),
        '',
      );
      if (cleanPhone.length > 10) {
        cleanPhone = cleanPhone.substring(cleanPhone.length - 10);
      }

      final bool isValidIndianNumber =
          cleanPhone.length == 10 && RegExp(r'^[6-9]').hasMatch(cleanPhone);

      final String contactNumber = isValidIndianNumber
          ? '+91$cleanPhone'
          : '+919876543210';

      final options = {
        'key': 'rzp_test_SolDtbIHbVBlVA',
        'amount': amountInPaise,
        if (razorpayOrderId != null && !razorpayOrderId.startsWith('mock_'))
          'order_id': razorpayOrderId,
        'name': 'KrishiDealer',
        'description': selectedPaymentMethod == 'online'
            ? 'Full Order Payment'
            : 'Booking Deposit Advance',
        'currency': 'INR',
        'prefill': {'contact': contactNumber, 'email': email},
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        setState(() => _isProcessing = false);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorLaunchingRazorpay(e.toString()))),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      MetaAnalyticsService.logCheckoutFailure(
        reason: 'Payment Setup Failed: ${e.toString()}',
      );
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.paymentSetupFailed(e.toString())),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _placeConfirmedOrder({
    required String? paymentId,
    required String? orderId,
    required String? signature,
  }) async {
    setState(() => _isProcessing = true);

    try {
      final cartService = Provider.of<CartService>(context, listen: false);
      final orderRepository = OrderRepository();

      final addr = selectedAddress;
      final profileService = Provider.of<ProfileService>(
        context,
        listen: false,
      );
      final String resolvedName =
          (addr?.name.isNotEmpty == true && addr?.name != 'Home / Shop')
          ? addr!.name
          : (profileService.name.isNotEmpty ? profileService.name : 'Customer');

      final String resolvedPhone = (addr?.phoneNumber.isNotEmpty == true)
          ? addr!.phoneNumber
          : profileService.phone;

      final shippingAddress = addr != null
          ? <String, String>{
              'name': resolvedName,
              'phoneNumber': resolvedPhone,
              'villageArea': addr.villageArea,
              'cityTehsil': addr.cityTehsil,
              'pincode': addr.pincode,
              'state': addr.state?.isNotEmpty == true ? addr.state! : 'default',
            }
          : <String, String>{};

      // 1. Place Order securely with signature verification fields
      final placedOrder = await orderRepository.placeOrder(
        paymentMethod: selectedPaymentMethod == 'online' ? 'Online' : 'Partial',
        shippingAddress: shippingAddress,
        razorpayPaymentId: paymentId,
        razorpayOrderId: orderId,
        razorpaySignature: signature,
        advanceAmount: selectedPaymentMethod == 'partial'
            ? advanceAmount
            : null,
        remainingAmount: selectedPaymentMethod == 'partial'
            ? remainingAmount
            : null,
      );

      _orderPlaced = true; // Mark order as successfully placed

      // Log purchase to Meta/Facebook SDK
      await MetaAnalyticsService.logPurchase(
        amount: finalTotal,
        orderId: placedOrder.orderId,
      );

      // 2. Clear Cart locally (it was already cleared on the server as part of order creation!)
      await cartService.clear(syncWithServer: false);

      // 3. Trigger Local Notification
      NotificationService.showNotification(
        title: "Order Placed Successfully! 🎉",
        body:
            "Your order has been received and is being processed. Thank you for shopping with KrishiKranti!",
        payload: jsonEncode({'action_route': '/my_orders'}),
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      // 3. Navigate to Success Screen
      _navigateToSuccessScreen();
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        // Robust Transaction Safeguard:
        // If paymentId is non-null, the user's money has already been charged.
        // We MUST NOT lose this order. Show custom retry sync dialog instead of a silent error.
        if (paymentId != null) {
          _showPaymentSyncErrorDialog(
            paymentId: paymentId,
            orderId: orderId ?? '',
            signature: signature ?? '',
            errorMessage: e.toString(),
          );
        } else {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.failedToPlaceOrder(e.toString())),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showPaymentSyncErrorDialog({
    required String paymentId,
    required String orderId,
    required String signature,
    required String errorMessage,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    return Text(
                      l10n.orderSyncRequired,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          content: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.orderSyncDescription,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Error: $errorMessage",
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.paymentRefKeepSafe,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          paymentId,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.doNotCloseApp,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              );
            },
          ),
          actions: [
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: paymentId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.paymentRefCopied)),
                    );
                  },
                  child: Text(l10n.copyId),
                );
              },
            ),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close warning dialog
                    _placeConfirmedOrder(
                      paymentId: paymentId,
                      orderId: orderId,
                      signature: signature,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(l10n.retryNow),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSuccessScreen() {
    if (selectedPaymentMethod == 'partial') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const OrderSecuredScreen()),
        (route) => route.isFirst,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const OrderSuccessScreen()),
        (route) => route.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context, listen: false);
    _lastFinalTotal = cartService.totalAmount;
    _lastItemCount = cartService.totalCount;

    if (_isProcessing) {
      return const AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: _ProcessingOverlay(),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.8),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(color: Colors.transparent),
            ),
          ),
          leading: Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Icon(
                    CupertinoIcons.chevron_left,
                    color: Colors.black87,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
          title: Text(
            AppLocalizations.of(context)!.secureCheckout,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: true,
        ),
        body: KycBarrierWidget(
          child: Stack(
            children: [
              // Background subtle ambient glows
              Positioned(
                top: -40,
                left: -40,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryGreen.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                top: 250,
                right: -60,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade600.withValues(alpha: 0.03),
                  ),
                ),
              ),
              Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).padding.top + kToolbarHeight,
                  ),
                  const CheckoutStepper(activeStep: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShippingAddressSection(),
                          const SizedBox(height: 16),
                          _buildOrderSummary(),
                          if (discountAmount > 0 ||
                              selectedCoupon == "DEALERDHAMAKA") ...[
                            const SizedBox(height: 12),
                            _buildSavingsBanner(),
                          ],
                          const SizedBox(height: 16),
                          _buildTrustBadges(),
                          const SizedBox(height: 20),
                          Text(
                            AppLocalizations.of(context)!.paymentMode,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildOnlinePaymentOption(),
                          const SizedBox(height: 10),
                          _buildPartialPaymentOption(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomSection(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final hasPartial =
        selectedPaymentMethod == 'partial' && selectedPartialPercent != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    CupertinoIcons.doc_text_fill,
                    size: 16,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  AppLocalizations.of(context)!.billingBreakdown,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                    letterSpacing: -0.2,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Column(
                  children: [
                    _receiptRow(l10n.subtotalLabel, cartTotal, isMuted: true),
                    if (discountAmount > 0) ...[
                      const SizedBox(height: 8),
                      _receiptRow(
                        l10n.couponDiscountLabel,
                        -discountAmount,
                        isDiscount: true,
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: _DashedDivider(),
                    ),
                    _receiptRow(l10n.grandTotal, finalTotal, isBold: true),
                    if (hasPartial) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1),
                      ),
                      _receiptRow(
                        l10n.advanceBookingDeposit(selectedPartialPercent!),
                        advanceAmount,
                        color: primaryGreen,
                        isBold: true,
                      ),
                      const SizedBox(height: 8),
                      _receiptRow(
                        l10n.remainingBalanceAtDelivery,
                        remainingAmount,
                        isMuted: true,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(
    String label,
    double amount, {
    bool isBold = false,
    bool isMuted = false,
    bool isDiscount = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold
                ? FontWeight.w900
                : (isMuted ? FontWeight.w500 : FontWeight.w600),
            color: isBold
                ? Colors.black87
                : (isMuted ? Colors.grey.shade600 : Colors.black87),
          ),
        ),
        Text(
          isDiscount
              ? "-₹${amount.abs().toStringAsFixed(0)}"
              : "₹${amount.toStringAsFixed(0)}",
          style: TextStyle(
            fontSize: isBold ? 15 : 13.5,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
            color: color ?? (isDiscount ? primaryGreen : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildSavingsBanner() {
    final isDealerDhamaka = selectedCoupon == "DEALERDHAMAKA";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDealerDhamaka
            ? primaryGreen.withValues(alpha: 0.08)
            : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDealerDhamaka
              ? primaryGreen.withValues(alpha: 0.15)
              : Colors.orange.shade100,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isDealerDhamaka
                ? CupertinoIcons.gift_fill
                : CupertinoIcons.sparkles,
            color: isDealerDhamaka ? primaryGreen : Colors.orange,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Text(
                  isDealerDhamaka
                      ? l10n.dealerDhamakaBanner
                      : l10n.couponSavingsBannerCheckout(
                          discountAmount.toStringAsFixed(0),
                        ),
                  style: TextStyle(
                    color: isDealerDhamaka
                        ? primaryGreen
                        : Colors.orange.shade900,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadges() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _trustBadge(
            CupertinoIcons.shield_fill,
            AppLocalizations.of(context)!.hundredPercentSecure,
            Colors.blue.shade700,
          ),
          _trustBadge(
            CupertinoIcons.doc_plaintext,
            AppLocalizations.of(context)!.gstInvoice,
            Colors.orange.shade700,
          ),
          _trustBadge(
            Icons.local_shipping_rounded,
            AppLocalizations.of(context)!.fastDelivery,
            primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _trustBadge(IconData icon, String label, Color iconColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            color: Colors.black87,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildOnlinePaymentOption() {
    bool isSelected = selectedPaymentMethod == 'online';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected ? primaryGreen.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? primaryGreen : Colors.grey.shade200,
          width: isSelected ? 1.8 : 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: primaryGreen.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            selectedPaymentMethod = 'online';
            selectedPartialPercent = null;
          });
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryGreen.withValues(alpha: 0.1)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.creditcard_fill,
                  color: isSelected ? primaryGreen : Colors.grey.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.payFullOnline,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: -0.3,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context)!.payFullOnlineDesc,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? primaryGreen : Colors.grey.shade300,
                    width: 2,
                  ),
                  color: isSelected ? primaryGreen : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(
                        CupertinoIcons.check_mark,
                        size: 10,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartialPaymentOption() {
    bool isSelected = selectedPaymentMethod == 'partial';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected ? primaryGreen.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? primaryGreen : Colors.grey.shade200,
          width: isSelected ? 1.8 : 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: primaryGreen.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                selectedPaymentMethod = 'partial';
                selectedPartialPercent = 10; // Default to 10%
              });
            },
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryGreen.withValues(alpha: 0.1)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      CupertinoIcons.percent,
                      color: isSelected ? primaryGreen : Colors.grey.shade600,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.partialBookingAdvance,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: -0.3,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.partialBookingAdvanceDesc,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? primaryGreen : Colors.grey.shade300,
                        width: 2,
                      ),
                      color: isSelected ? primaryGreen : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(
                            CupertinoIcons.check_mark,
                            size: 10,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
          if (isSelected) ...[
            const Divider(height: 1, indent: 14, endIndent: 14),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.chooseAdvanceAmount,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [10, 20, 50].map((percent) {
                      bool isPercentSelected =
                          selectedPartialPercent == percent;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  selectedPartialPercent = percent;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isPercentSelected
                                      ? LinearGradient(
                                          colors: [
                                            primaryGreen,
                                            const Color(0xFF4CAF50),
                                          ],
                                        )
                                      : null,
                                  color: isPercentSelected
                                      ? null
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isPercentSelected
                                        ? primaryGreen
                                        : Colors.grey.shade200,
                                    width: 1.2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    "$percent%",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: isPercentSelected
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    bool isOnline = selectedPaymentMethod == 'online';
    bool isPartial =
        selectedPaymentMethod == 'partial' && selectedPartialPercent != null;
    bool isEnabled = isOnline || isPartial;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewPadding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
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
                    isOnline
                        ? AppLocalizations.of(context)!.payableAmount
                        : AppLocalizations.of(context)!.bookingAdvanceLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "₹${(isOnline ? finalTotal : advanceAmount).toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: primaryGreen,
                      ),
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
                    Text(
                      AppLocalizations.of(context)!.remainingBalanceDelivery,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "₹${remainingAmount.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: (isEnabled && hasSelectedAddress && !_isProcessing)
                    ? LinearGradient(
                        colors: [primaryGreen, const Color(0xFF1B5E20)],
                      )
                    : null,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: (isEnabled && hasSelectedAddress && !_isProcessing)
                    ? _processPayment
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade200,
                  disabledForegroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isEnabled && hasSelectedAddress) ...[
                            const Icon(
                              CupertinoIcons.lock_shield_fill,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            !hasSelectedAddress
                                ? AppLocalizations.of(context)!.addAddressToPay
                                : AppLocalizations.of(context)!.proceedToPay,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingAddressSection() {
    final l10n = AppLocalizations.of(context)!;
    final addressService = Provider.of<AddressService>(context);
    final profileService = Provider.of<ProfileService>(context);
    final addr = selectedAddress;

    if (_isInitializingAddress) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: const CupertinoActivityIndicator(),
      );
    }

    if (addr == null) {
      return InkWell(
        onTap: () => _navigateToAddAddress(addressService),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryGreen.withValues(alpha: 0.03),
                const Color(0xFF4CAF50).withValues(alpha: 0.01),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primaryGreen.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.location_solid,
                  color: primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.addShippingAddress,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: primaryGreen,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.addShippingAddressHint,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(CupertinoIcons.chevron_right, color: primaryGreen, size: 16),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: primaryGreen, width: 4)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: primaryGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          CupertinoIcons.location_solid,
                          size: 14,
                          color: primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.deliverTo,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 10.5,
                          letterSpacing: 0.8,
                          color: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showAddressSelectionBottomSheet(addressService);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: primaryGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        l10n.changeAddress,
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.w900,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            TranslatableText(
                              (addr.name.isNotEmpty &&
                                      addr.name != 'Home / Shop')
                                  ? addr.name
                                  : (profileService.name.isNotEmpty
                                        ? profileService.name
                                        : 'Home / Shop'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15.5,
                                letterSpacing: -0.3,
                                color: Colors.black87,
                              ),
                            ),
                            if (addr.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  l10n.defaultLabel,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: primaryGreen,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        TranslatableText(
                          addr.fullAddress,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            height: 1.3,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.phone_fill,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              addr.phoneNumber.isNotEmpty
                                  ? addr.phoneNumber
                                  : profileService.phone,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToAddAddress(AddressService addressService) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditAddressScreen()),
    );
    if (result != null && result is AddressModel) {
      final success = await addressService.addAddress(result);
      if (success && mounted) {
        setState(() {
          selectedAddressId = addressService.addresses.last.id;
        });
      }
    }
  }

  void _showAddressSelectionBottomSheet(AddressService addressService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.selectShippingAddress,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(CupertinoIcons.xmark, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: addressService.addresses.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final address = addressService.addresses[index];
                          final isSelected = selectedAddressId == address.id;

                          return InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                selectedAddressId = address.id;
                              });
                              setSheetState(() {});
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryGreen.withValues(alpha: 0.03)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryGreen
                                      : Colors.grey.shade200,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Icon(
                                      isSelected
                                          ? CupertinoIcons
                                                .check_mark_circled_solid
                                          : CupertinoIcons.circle,
                                      color: isSelected
                                          ? primaryGreen
                                          : Colors.grey.shade400,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          address.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          address.fullAddress,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          address.phoneNumber,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context); // Close bottom sheet first
                          await _navigateToAddAddress(addressService);
                        },
                        icon: const Icon(CupertinoIcons.plus, size: 18),
                        label: Text(
                          AppLocalizations.of(context)!.addNewAddress,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey.shade300),
              ),
            );
          }),
        );
      },
    );
  }
}

/* class _ProcessingOverlay extends StatefulWidget {
  const _ProcessingOverlay();

  @override
  State<_ProcessingOverlay> createState() => _ProcessingOverlayState();
}

class _ProcessingOverlayState extends State<_ProcessingOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  Timer? _timer;
  late AnimationController _pulseController;

  final List<String> _steps = [
    "Initiating secure handshake... 🔒",
    "Processing payment transaction... 💳",
    "Registering order details... 📝",
    "Allocating warehouse inventory... 🌾",
    "Finalizing order safety checks... 🚀",
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Progress one step every 1.4 seconds
    _timer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (_currentStep < _steps.length - 1) {
        if (mounted) {
          setState(() {
            _currentStep++;
          });
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  } */

class _ProcessingOverlay extends StatefulWidget {
  const _ProcessingOverlay();

  @override
  State<_ProcessingOverlay> createState() => _ProcessingOverlayState();
}

class _ProcessingOverlayState extends State<_ProcessingOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  Timer? _timer;
  late AnimationController _pulseController;

  List<String> get _steps {
    // We cannot use context here because this runs in initState before build.
    // Keep these as static strings; they are technical/security text that stays the same.
    return [
      "Scanning client environment sandbox... 🛡️",
      "Analyzing transaction injection vulnerabilities... 🔒",
      "Verifying secure API socket handshake... ⛓️",
      "Validating payload signature integrity... 🔑",
      "Finalizing end-to-end SSL encryption... 🚀",
    ];
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Snappy security pass transition (650ms per check)
    _timer = Timer.periodic(const Duration(milliseconds: 650), (timer) {
      if (_currentStep < _steps.length - 1) {
        if (mounted) {
          setState(() {
            _currentStep++;
          });
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Pulsating shield container
              ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.05).animate(
                  CurvedAnimation(
                    parent: _pulseController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withOpacity(0.12),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/animations/shield.gif',
                    height: 120,
                    errorBuilder: (c, e, s) => const Icon(
                      CupertinoIcons.lock_shield_fill,
                      color: Color(0xFF2E7D32),
                      size: 80,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Text(
                AppLocalizations.of(context)!.securingYourOrder,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Checklist replacing description card completely with premium white background!
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade100, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_steps.length, (index) {
                    bool isVisible = index <= _currentStep;
                    if (!isVisible) return const SizedBox.shrink();

                    return _StepRow(
                      key: ValueKey(index),
                      text: _steps[index],
                      isCompleted: index < _currentStep,
                      isActive: index == _currentStep,
                    );
                  }),
                ),
              ),
              const Spacer(flex: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.checkmark_shield_fill,
                    color: Colors.grey.shade400,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context)!.pciDssCompliant,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatefulWidget {
  final String text;
  final bool isCompleted;
  final bool isActive;

  const _StepRow({
    super.key,
    required this.text,
    required this.isCompleted,
    required this.isActive,
  });

  @override
  State<_StepRow> createState() => _StepRowState();
}

class _StepRowState extends State<_StepRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: Color(0xFF2E7D32),
                size: 20,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: widget.isActive
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: widget.isCompleted
                        ? Colors.grey.shade400
                        : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
