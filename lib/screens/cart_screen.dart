import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:krishikranti/screens/coupons_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/core/cart_service.dart';
import 'package:krishikranti/screens/product_detail_screen.dart';
import 'package:krishikranti/screens/shipping_address_screen.dart';
import 'package:krishikranti/screens/product_list_screen.dart';
import 'package:krishikranti/features/products/data/models/product_model.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with TickerProviderStateMixin {
  late AnimationController _bgAnimationController;

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    // Sync cart with backend on open to ensure prices are fully updated and healed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<CartService>(context, listen: false).syncWithBackend();
      }
    });
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Consumer<CartService>(
      builder: (context, cartService, child) {
        final items = cartService.items;
        final isEmpty = items.isEmpty;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            extendBody: true,
            appBar: AppBar(
              backgroundColor: Colors.white.withValues(alpha: 0.6),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(color: Colors.transparent),
                ),
              ),
              leading: Center(
                child: _TopIconButton(
                  icon: CupertinoIcons.chevron_left,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              title: Text(
                l10n.cart,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Colors.black,
                  letterSpacing: -0.8,
                ),
              ),
              centerTitle: true,
              actions: [
                if (!isEmpty)
                  _TopIconButton(
                    icon: CupertinoIcons.trash,
                    onTap: () => _showClearCartDialog(context, cartService),
                    margin: const EdgeInsets.only(right: 16),
                  ),
              ],
            ),
            body: Stack(
              children: [
                // Animated Modern Background Blobs
                _buildAnimatedBlobs(theme),

                isEmpty
                    ? _buildEmptyState(l10n)
                    : CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildAnimatedItem(
                                    index,
                                    items[index],
                                    cartService,
                                  ),
                                );
                              }, childCount: items.length),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 160),
                            sliver: SliverToBoxAdapter(
                              child: _CouponTile(cartService: cartService),
                            ),
                          ),
                        ],
                      ),
                if (!isEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildAdvancedBottomPanel(
                      context,
                      l10n,
                      cartService,
                      theme,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedBlobs(ThemeData theme) {
    return AnimatedBuilder(
      animation: _bgAnimationController,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: 50 + (20 * _bgAnimationController.value),
              left: -50 + (30 * _bgAnimationController.value),
              child: _Blob(
                size: 250,
                color: theme.colorScheme.primary.withValues(alpha: 0.04),
              ),
            ),
            Positioned(
              bottom: 100 - (30 * _bgAnimationController.value),
              right: -80 + (40 * _bgAnimationController.value),
              child: _Blob(
                size: 300,
                color: Colors.orange.withValues(alpha: 0.03),
              ),
            ),
            Positioned(
              top: 300 - (50 * _bgAnimationController.value),
              right: 100 + (20 * _bgAnimationController.value),
              child: _Blob(
                size: 150,
                color: Colors.blue.withValues(alpha: 0.03),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedItem(int index, CartItem item, CartService cartService) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + (index * 60)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.95 + (0.05 * value),
            child: Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Dismissible(
                key: Key('cart_item_${item.productId}_${item.variant}_$index'),
                direction: item.isFree
                    ? DismissDirection.none
                    : DismissDirection.endToStart,
                onDismissed: (_) {
                  cartService.removeItem(item.variantId);
                  HapticFeedback.mediumImpact();
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 25),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    CupertinoIcons.trash_fill,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                child: _CartItemRow(
                  item: item,
                  index: index,
                  cartService: cartService,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                          product: Product(
                            id: item.productId,
                            title: item.productName,
                            thumbnail: item.productImage,
                            images: [item.productImage],
                            variants: [
                              Variant(
                                id: item.productId,
                                size: item.variant,
                                price: item.price,
                                compareAtPrice: 0.0,
                              ),
                            ],
                            technicalName: item.technicalName,
                          ),
                          thumbnailUrl: item.productImage,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/EmptyCart.json',
              height: 240,
              repeat: true,
            ),
            const SizedBox(height: 24),
            const Text(
              "Your cart feels light",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Discover premium agricultural products and start your growing journey today.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 36),
            _buildModernButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const ProductListScreen(category: "All"),
                ),
              ),
              text: "Begin Exploring",
              icon: CupertinoIcons.sparkles,
              isSmall: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernButton({
    required VoidCallback onPressed,
    required String text,
    required IconData icon,
    bool isSmall = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onPressed();
      },
      child: Container(
        width: double.infinity,
        height: isSmall ? 54 : 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: isSmall ? 15 : 17,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedBottomPanel(
    BuildContext context,
    AppLocalizations l10n,
    CartService cartService,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "PAYABLE AMOUNT",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "₹${cartService.totalAmount.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "${cartService.totalCount} items",
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildModernButton(
                    onPressed: () async {
                      if (cartService.items.isNotEmpty) {
                        HapticFeedback.heavyImpact();

                        // Sync Guard: Ensure all background adds are finished
                        if (cartService.pendingSyncTask != null) {
                          await cartService.pendingSyncTask;
                        }

                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ShippingAddressScreen(),
                            ),
                          );
                        }
                      }
                    },
                    text: "CONTINUE TO CHECKOUT",
                    icon: CupertinoIcons.creditcard_fill,
                    isSmall: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, CartService cartService) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Clear Cart?"),
        content: const Text(
          "Are you sure you want to remove all items from your cart?",
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              cartService.clear();
              Navigator.pop(context);
            },
            child: const Text("Clear All"),
          ),
        ],
      ),
    );
  }
}

class _CouponTile extends StatelessWidget {
  final CartService cartService;
  const _CouponTile({required this.cartService});

  @override
  Widget build(BuildContext context) {
    final isApplied = cartService.appliedCoupon != null;
    const primaryGreen = Color(0xFF1B5E20);

    return GestureDetector(
      onTap: cartService.isCouponLoading
          ? null
          : () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CouponsScreen()),
              );
            },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isApplied ? Colors.green.shade100 : Colors.white,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isApplied ? Colors.green : primaryGreen).withValues(
                  alpha: 0.1,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isApplied
                    ? CupertinoIcons.checkmark_seal_fill
                    : CupertinoIcons.ticket_fill,
                color: isApplied ? Colors.green : primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isApplied ? "Coupon Applied!" : "Offers & Benefits",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    isApplied
                        ? "You saved ₹${cartService.discountAmount.toStringAsFixed(0)} with ${cartService.appliedCoupon}"
                        : "View available coupons and offers",
                    style: TextStyle(
                      color: isApplied
                          ? Colors.green.shade600
                          : Colors.grey.shade500,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (cartService.isCouponLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            else if (isApplied)
              TextButton(
                onPressed: cartService.isCouponLoading
                    ? null
                    : () async {
                        HapticFeedback.mediumImpact();
                        try {
                          await cartService.removeCoupon();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      },
                child: Text(
                  "REMOVE",
                  style: TextStyle(
                    color: cartService.isCouponLoading
                        ? Colors.grey
                        : Colors.red.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
            else
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  final CartItem item;
  final int index;
  final CartService cartService;
  final VoidCallback onTap;

  const _CartItemRow({
    required this.item,
    required this.index,
    required this.cartService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Hero(
                  tag: 'cart_image_${item.productName}_$index',
                  child: Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        item.productImage,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if (item.isFree)
                                  Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      "FREE GIFT",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    item.productName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: Colors.black,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!item.isFree)
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                cartService.removeItem(item.variantId);
                              },
                              child: Icon(
                                CupertinoIcons.trash,
                                size: 16,
                                color: Colors.red.shade400,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        item.technicalName.isNotEmpty
                            ? item.technicalName
                            : (item.isFree ? "Promotional Gift" : ""),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.variant.isNotEmpty
                                      ? item.variant
                                      : "Standard",
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.isFree
                                    ? "FREE"
                                    : "₹${(item.price * item.qty).toStringAsFixed(0)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: item.isFree
                                      ? Colors.green
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          _ModernQtySelector(
                            qty: item.qty,
                            isFree: item.isFree,
                            isSyncing: cartService.syncingVariantIds.contains(
                              item.variantId,
                            ),
                            onMinus: () {
                              if (item.qty > 1) {
                                cartService.updateQty(
                                  item.variantId,
                                  item.qty - 1,
                                );
                                HapticFeedback.lightImpact();
                              } else {
                                HapticFeedback.mediumImpact();
                                cartService.removeItem(item.variantId);
                              }
                            },
                            onPlus: () {
                              cartService.updateQty(
                                item.variantId,
                                item.qty + 1,
                              );
                              HapticFeedback.lightImpact();
                            },
                            onQtyChanged: (newQty) {
                              if (newQty <= 0) {
                                cartService.removeItem(item.variantId);
                                HapticFeedback.mediumImpact();
                              } else {
                                cartService.updateQty(item.variantId, newQty);
                                HapticFeedback.lightImpact();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernQtySelector extends StatelessWidget {
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final bool isFree;
  final bool isSyncing;
  final ValueChanged<int>? onQtyChanged;

  const _ModernQtySelector({
    required this.qty,
    required this.onMinus,
    required this.onPlus,
    this.isFree = false,
    this.isSyncing = false,
    this.onQtyChanged,
  });

  void _showQuantityEditDialog(BuildContext context, int currentQty) {
    final controller = TextEditingController(text: currentQty.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Enter Quantity",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Enter value",
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Color(0xFF1B5E20),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "CANCEL",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final int? val = int.tryParse(controller.text);
              if (val != null && val >= 0) {
                onQtyChanged?.call(val);
              }
              Navigator.pop(context);
            },
            child: const Text(
              "UPDATE",
              style: TextStyle(
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // Catch taps to prevent bubbling to parent InkWell
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isFree)
              _qtyBtn(
                qty == 1 ? CupertinoIcons.trash_fill : CupertinoIcons.minus,
                isSyncing ? () {} : onMinus,
                size: qty == 1 ? 12 : 14,
              ),
            Container(
              constraints: const BoxConstraints(minWidth: 32),
              alignment: Alignment.center,
              child: isSyncing
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.black54,
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: isSyncing || isFree || onQtyChanged == null
                          ? null
                          : () => _showQuantityEditDialog(context, qty),
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        "$qty",
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: Colors.black,
                          decoration: TextDecoration.underline,
                          decorationStyle: TextDecorationStyle.dashed,
                          decorationColor: Colors.black45,
                          decorationThickness: 1.5,
                        ),
                      ),
                    ),
            ),
            if (!isFree)
              _qtyBtn(CupertinoIcons.plus, isSyncing ? () {} : onPlus),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap, {double size = 14}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40, // Increased touch area
        height: 36, // Increased touch area
        alignment: Alignment.center,
        child: Icon(icon, size: size, color: Colors.black87),
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
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(widget.icon, size: 18, color: Colors.black),
          ),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;

  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
