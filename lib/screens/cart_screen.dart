import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:krishikranti/screens/coupons_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/core/cart_service.dart';
import 'package:krishikranti/screens/product_detail_screen.dart';
import 'package:krishikranti/screens/checkout_screen.dart';
import 'package:krishikranti/widgets/checkout_stepper.dart';
import 'package:krishikranti/screens/product_list_screen.dart';
import 'package:krishikranti/features/products/data/models/product_model.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:krishikranti/core/utils/translatable_text.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with TickerProviderStateMixin {
  late AnimationController _bgAnimationController;
  String? _lastAppliedCoupon;
  bool _showCelebration = false;
  bool _isFirstBuild = true;
  bool _isMultiSelectMode = false;
  final Set<String> _selectedVariantIds = {};

  void _triggerCelebration() {
    if (mounted) {
      HapticFeedback.heavyImpact();
      setState(() {
        _showCelebration = true;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showCelebration = false;
          });
        }
      });
    }
  }

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

        // Auto-detect newly applied coupons and trigger the full-screen celebratory animation!
        final appliedCoupon = cartService.appliedCoupon;
        final isFirstRun = _isFirstBuild;
        if (!isFirstRun) {
          if (appliedCoupon != null && appliedCoupon != _lastAppliedCoupon) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _triggerCelebration();
            });
          }
        }
        _lastAppliedCoupon = appliedCoupon;
        _isFirstBuild = false;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: Colors.white,
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
              leadingWidth: _isMultiSelectMode ? 110 : null,
              leading: _isMultiSelectMode
                  ? Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 16),
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          setState(() {
                            final nonFreeItems = items
                                .where((i) => !i.isFree)
                                .toList();
                            if (_selectedVariantIds.length ==
                                nonFreeItems.length) {
                              _selectedVariantIds.clear();
                            } else {
                              _selectedVariantIds.addAll(
                                nonFreeItems.map((i) => i.variantId),
                              );
                            }
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          _selectedVariantIds.length ==
                                  items.where((i) => !i.isFree).length
                              ? l10n.deselectAll
                              : l10n.selectAll,
                          style: const TextStyle(
                            color: Color(0xFF298E4D),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  : Center(
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
                if (!isEmpty) ...[
                  TextButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        _isMultiSelectMode = !_isMultiSelectMode;
                        _selectedVariantIds.clear();
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black87,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(_isMultiSelectMode ? l10n.done : l10n.editLabel),
                  ),
                ],
              ],
            ),
            body: Stack(
              children: [
                // Animated Modern Background Blobs
                _buildAnimatedBlobs(theme),

                isEmpty
                    ? _buildEmptyState(l10n, isFirstRun)
                    : AnimationLimiter(
                        key: const ValueKey('cart_anim_limiter'),
                        child: CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            const SliverToBoxAdapter(
                              child: CheckoutStepper(activeStep: 0),
                            ),
                            // Header & Swipe Instruction
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                              sliver: SliverToBoxAdapter(
                                child: AnimationConfiguration.staggeredList(
                                  position: 0,
                                  duration: isFirstRun
                                      ? const Duration(milliseconds: 375)
                                      : Duration.zero,
                                  child: SlideAnimation(
                                    verticalOffset: isFirstRun ? 30.0 : 0.0,
                                    child: FadeInAnimation(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            l10n.itemCountLabel(items.length),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 10,
                                              color: Colors.grey.shade500,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                          const _AnimatedSecureBadge(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // 1. Active Cart Items
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  return AnimationConfiguration.staggeredList(
                                    position: index + 1,
                                    duration: isFirstRun
                                        ? const Duration(milliseconds: 375)
                                        : Duration.zero,
                                    child: SlideAnimation(
                                      verticalOffset: isFirstRun ? 30.0 : 0.0,
                                      child: FadeInAnimation(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: _buildCartItem(
                                            index,
                                            items[index],
                                            cartService,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }, childCount: items.length),
                              ),
                            ),

                            // 4. Main Offers Tile
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              sliver: SliverToBoxAdapter(
                                child: AnimationConfiguration.staggeredList(
                                  position: items.length + 1,
                                  duration: isFirstRun
                                      ? const Duration(milliseconds: 375)
                                      : Duration.zero,
                                  child: SlideAnimation(
                                    verticalOffset: isFirstRun ? 30.0 : 0.0,
                                    child: FadeInAnimation(
                                      child: _CouponTile(
                                        cartService: cartService,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // 5. Detailed Professional Bill Breakdown Card
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                160,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: AnimationConfiguration.staggeredList(
                                  position: items.length + 2,
                                  duration: isFirstRun
                                      ? const Duration(milliseconds: 375)
                                      : Duration.zero,
                                  child: SlideAnimation(
                                    verticalOffset: isFirstRun ? 30.0 : 0.0,
                                    child: FadeInAnimation(
                                      child: _BillDetailsCard(
                                        cartService: cartService,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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

                // Premium Immersive Fullscreen Celebration Overlay for Coupons Applied
                if (_showCelebration && appliedCoupon != null)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.25),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Lottie.asset(
                                'assets/animations/CongratulationsLottie.json',
                                repeat: false,
                                fit: BoxFit.contain,
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 80),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      CupertinoIcons.checkmark_seal_fill,
                                      color: Color(0xFF298E4D),
                                      size: 40,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      l10n.couponApplied,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        color: Colors.black,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      l10n.couponActiveMessage(appliedCoupon),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
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
                color: const Color(0xFFFA9527).withValues(alpha: 0.03),
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

  Widget _buildCartItem(int index, CartItem item, CartService cartService) {
    final isSelected = _selectedVariantIds.contains(item.variantId);
    return _CartItemRow(
      item: item,
      index: index,
      cartService: cartService,
      isMultiSelectMode: _isMultiSelectMode,
      isSelected: isSelected,
      onTap: _isMultiSelectMode && !item.isFree
          ? () {
              HapticFeedback.lightImpact();
              setState(() {
                if (_selectedVariantIds.contains(item.variantId)) {
                  _selectedVariantIds.remove(item.variantId);
                } else {
                  _selectedVariantIds.add(item.variantId);
                }
              });
            }
          : () {
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
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, bool isFirstRun) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: AnimationLimiter(
          key: const ValueKey('empty_cart_anim_limiter'),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: AnimationConfiguration.toStaggeredList(
              duration: isFirstRun
                  ? const Duration(milliseconds: 500)
                  : Duration.zero,
              childAnimationBuilder: (w) => SlideAnimation(
                verticalOffset: isFirstRun ? 40.0 : 0.0,
                child: FadeInAnimation(child: w),
              ),
              children: [
                Lottie.asset(
                  'assets/animations/EmptyCart.json',
                  height: 240,
                  repeat: true,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.cartFeelsLight,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.discoverAgriProducts,
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
                  text: l10n.beginExploring,
                  icon: CupertinoIcons.sparkles,
                  isSmall: false,
                ),
              ],
            ),
          ),
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
            colors: [Color(0xFF298E4D), Color(0xFF2E9E57)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF298E4D).withValues(alpha: 0.3),
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
    if (_isMultiSelectMode) {
      final selectedCount = _selectedVariantIds.length;
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: GestureDetector(
            onTap: selectedCount == 0
                ? null
                : () {
                    _showBulkDeleteConfirmationDialog(context, cartService);
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: selectedCount == 0
                      ? [Colors.grey.shade400, Colors.grey.shade400]
                      : [const Color(0xFFED4337), const Color(0xFFD32F2F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: selectedCount == 0
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFFED4337).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.trash,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    selectedCount == 0
                        ? l10n.selectItemsToDelete
                        : l10n.deleteSelected(selectedCount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: _PremiumFloatingCheckoutButton(
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
                    builder: (context) => const CheckoutScreen(),
                  ),
                );
              }
            }
          },
          text: l10n.continueToCheckout,
          icon: CupertinoIcons.arrow_right,
          itemCount: cartService.totalCount,
        ),
      ),
    );
  }

  void _showBulkDeleteConfirmationDialog(
    BuildContext context,
    CartService cartService,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.removeItemsTitle(_selectedVariantIds.length)),
        content: Text(
          l10n.removeItemsConfirm,
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              HapticFeedback.heavyImpact();
              for (final variantId in _selectedVariantIds) {
                cartService.removeItem(variantId);
              }
              setState(() {
                _selectedVariantIds.clear();
                _isMultiSelectMode = false;
              });
              Navigator.pop(context);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, CartService cartService) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.clearCartTitle),
        content: Text(
          l10n.clearCartConfirm,
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              cartService.clear();
              Navigator.pop(context);
            },
            child: Text(l10n.clearAll),
          ),
        ],
      ),
    );
  }
}

class _PremiumFloatingCheckoutButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final IconData icon;
  final int itemCount;

  const _PremiumFloatingCheckoutButton({
    required this.onPressed,
    required this.text,
    required this.icon,
    required this.itemCount,
  });

  @override
  State<_PremiumFloatingCheckoutButton> createState() =>
      _PremiumFloatingCheckoutButtonState();
}

class _PremiumFloatingCheckoutButtonState
    extends State<_PremiumFloatingCheckoutButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shineController;
  late final Animation<double> _shineAlignAnimation;

  double _tapScale = 1.0;

  @override
  void initState() {
    super.initState();

    // Subtle glossy sweep animation every 4.5 seconds
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _shineAlignAnimation = Tween<double>(begin: -2.5, end: 2.5).animate(
      CurvedAnimation(parent: _shineController, curve: Curves.easeInOutCubic),
    );

    _startShineLoop();
  }

  void _startShineLoop() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 4, milliseconds: 500));
      if (mounted) {
        await _shineController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _tapScale = 0.95; // Snappy tactile feedback scale
        });
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() {
          _tapScale = 1.0;
        });
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() {
          _tapScale = 1.0;
        });
      },
      child: AnimatedBuilder(
        animation: _shineController,
        builder: (context, child) {
          return Transform.scale(
            scale: _tapScale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFF298E4D), Color(0xFF2E9E57)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF298E4D).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(0xFF2E9E57).withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Stack(
                  children: [
                    // Shine Sweep Layer
                    Positioned.fill(
                      child: ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            begin: Alignment(
                              _shineAlignAnimation.value - 0.5,
                              -1,
                            ),
                            end: Alignment(_shineAlignAnimation.value + 0.5, 1),
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(
                                alpha: 0.25,
                              ), // Highly subtle
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.srcATop,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                    // Button Content
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            // 1. Beautiful item count badge on the left
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, animation) {
                                  return ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  );
                                },
                                child: Text(
                                  "${widget.itemCount}",
                                  key: ValueKey<int>(widget.itemCount),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // 2. Main title text
                            Expanded(
                              child: Text(
                                widget.text,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // 3. Lottie Animated Arrow on the right
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Lottie.asset(
                                'assets/animations/arrow.json',
                                width: 32,
                                height: 32,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CouponTile extends StatelessWidget {
  final CartService cartService;
  const _CouponTile({required this.cartService});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isApplied = cartService.appliedCoupon != null;
    const primaryGreen = Color(0xFF298E4D);
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
            color: isApplied
                ? primaryGreen.withValues(alpha: 0.15)
                : Colors.white,
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
                color: (isApplied ? primaryGreen : primaryGreen).withValues(
                  alpha: 0.1,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isApplied
                    ? CupertinoIcons.checkmark_seal_fill
                    : CupertinoIcons.ticket_fill,
                color: isApplied ? primaryGreen : primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isApplied ? l10n.couponAppliedTitle : l10n.offersAndBenefits,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    isApplied
                        ? (cartService.appliedCoupon == "DEALERDHAMAKA"
                              ? l10n.freeGiftMessage
                              : l10n.couponSavedMessage(cartService.discountAmount.toStringAsFixed(0), cartService.appliedCoupon ?? ""))
                        : l10n.viewCouponsAndOffers,
                    style: TextStyle(
                      color: isApplied
                          ? primaryGreen.withValues(alpha: 0.8)
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
                  l10n.removeLabel,
                  style: TextStyle(
                    color: cartService.isCouponLoading
                        ? Colors.grey
                        : const Color(0xFFED4337),
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
  final bool isMultiSelectMode;
  final bool isSelected;

  const _CartItemRow({
    required this.item,
    required this.index,
    required this.cartService,
    required this.onTap,
    this.isMultiSelectMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isFree = item.isFree;
    final primaryColor = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: isFree
            ? const Color(0xFF298E4D).withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFree
              ? const Color(0xFF298E4D).withValues(alpha: 0.15)
              : Colors.white,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isMultiSelectMode) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF298E4D)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF298E4D)
                            : Colors.grey.shade400,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: isSelected
                        ? const Icon(
                            CupertinoIcons.checkmark,
                            color: Colors.white,
                            size: 11,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                ],
                // 1. Compact Image Container (62x62)
                Hero(
                  tag: 'cart_image_${item.productName}_$index',
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isFree
                            ? const Color(0xFF298E4D).withValues(alpha: 0.15)
                            : Colors.grey.shade100,
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: CachedNetworkImage(
                                imageUrl: item.productImage,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => const Center(
                                  child: CupertinoActivityIndicator(radius: 6),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                      CupertinoIcons.photo,
                                      color: Colors.grey,
                                      size: 16,
                                    ),
                              ),
                            ),
                          ),
                        ),
                        if (isFree)
                          Positioned(
                            top: 2,
                            left: 2,
                            child: Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: const BoxDecoration(
                                color: Color(0xFF298E4D),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.gift_fill,
                                size: 7,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // 2. Details Column (fully expands to fill space)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Title & Details Column on left, Delete Button on right
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Title
                                TranslatableText(
                                  item.productName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: Colors.black87,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                // Badges and Technical Name Row
                                Row(
                                  children: [
                                    if (isFree) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF298E4D),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              CupertinoIcons.gift_fill,
                                              size: 8,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              l10n.giftLabel,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 7.5,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    if (item.variant.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withValues(
                                            alpha: 0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: TranslatableText(
                                          item.variant,
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 8,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    if (item.technicalName.isNotEmpty)
                                      Expanded(
                                        child: TranslatableText(
                                          item.technicalName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (!isFree && !isMultiSelectMode) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                cartService.removeItem(item.variantId);
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFED4337,
                                  ).withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  CupertinoIcons.trash,
                                  color: Color(0xFFED4337),
                                  size: 13,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Bottom Row: Price on left, Quantity Selector on right
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Price Details
                          Text(
                            isFree
                                ? l10n.freeLabel
                                : "₹${(item.price * item.qty).toStringAsFixed(0)}",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: isFree
                                  ? const Color(0xFF298E4D)
                                  : Colors.black,
                            ),
                          ),
                          // Compact Quantity Selector
                          _ModernQtySelector(
                            qty: item.qty,
                            isFree: isFree,
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
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentQty.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          l10n.enterQuantity,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.specifyQuantityHint,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.egQuantity,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Color(0xFF298E4D),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel.toUpperCase(),
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF298E4D), Color(0xFF2E9E57)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () {
                final int? val = int.tryParse(controller.text);
                if (val != null && val >= 0) {
                  onQtyChanged?.call(val);
                }
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Text(
                l10n.updateLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isFree) {
      return Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF298E4D).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF298E4D).withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
        alignment: Alignment.center,
        child: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Text(
              l10n.qtyLabel(qty),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 10,
                color: Color(0xFF298E4D),
              ),
            );
          },
        ),
      );
    }

    return GestureDetector(
      onTap: () {}, // Catch taps to prevent bubbling to parent InkWell
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 28,
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _qtyBtn(
              qty == 1 ? CupertinoIcons.trash_fill : CupertinoIcons.minus,
              isSyncing ? () {} : onMinus,
              size: qty == 1 ? 10 : 11,
              color: qty == 1 ? const Color(0xFFED4337) : Colors.black87,
              isFirst: true,
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 26),
              alignment: Alignment.center,
              child: isSyncing
                  ? const SizedBox(
                      width: 11,
                      height: 11,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Color(0xFF298E4D),
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
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    ),
            ),
            _qtyBtn(
              CupertinoIcons.plus,
              isSyncing ? () {} : onPlus,
              size: 11,
              color: const Color(0xFF298E4D),
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(
    IconData icon,
    VoidCallback onTap, {
    double size = 11,
    required Color color,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 25,
        height: 25,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? const Radius.circular(7) : Radius.zero,
            right: isLast ? const Radius.circular(7) : Radius.zero,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}

class _TopIconButton extends StatefulWidget {
  final IconData? icon;
  final String? assetPath;
  final VoidCallback onTap;
  final EdgeInsets? margin;

  const _TopIconButton({
    this.icon,
    this.assetPath,
    required this.onTap,
    this.margin,
  });

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
            padding: const EdgeInsets.all(10),
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
            child: widget.assetPath != null
                ? Image.asset(
                    widget.assetPath!,
                    width: 18,
                    height: 18,
                    color: Colors.black,
                  )
                : Icon(widget.icon, size: 18, color: Colors.black),
          ),
        ),
      ),
    );
  }
}

class _AnimatedSecureBadge extends StatelessWidget {
  const _AnimatedSecureBadge();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF298E4D).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF298E4D).withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Crisp static shield and checkmark stack
          Stack(
            alignment: Alignment.center,
            children: const [
              Icon(
                CupertinoIcons.shield_fill,
                size: 13,
                color: Color(0xFF298E4D),
              ),
              Positioned(
                top: 3.2,
                child: Icon(
                  CupertinoIcons.checkmark,
                  size: 6,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(width: 5),
          // Clean, solid forest-green secure text
          Text(
            l10n.secureCheckoutBadge,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 9,
              color: Color(0xFF298E4D),
              letterSpacing: 0.5,
            ),
          ),
        ],
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

class _BillDetailsCard extends StatelessWidget {
  final CartService cartService;
  const _BillDetailsCard({required this.cartService});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subtotal = cartService.subtotal;
    final discount = cartService.discountAmount;
    final total = cartService.totalAmount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.5),
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
          Text(
            l10n.billDetails,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 11,
              color: Colors.black,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildBillRow(
            label: l10n.itemTotalSubtotal,
            value: "₹${subtotal.toStringAsFixed(0)}",
            isBold: false,
          ),
          if (discount > 0) ...[
            const SizedBox(height: 12),
            _buildBillRow(
              label: l10n.couponDiscount,
              value: "- ₹${discount.toStringAsFixed(0)}",
              valueColor: const Color(0xFF298E4D),
              isBold: false,
            ),
          ],
          const SizedBox(height: 12),
          _buildBillRow(
            label: l10n.deliveryCharges,
            value: l10n.freeLabel,
            valueColor: const Color(0xFF298E4D),
            isBold: false,
          ),
          const SizedBox(height: 16),
          _DashedDivider(),
          const SizedBox(height: 16),
          _buildBillRow(
            label: l10n.totalAmountPayable,
            value: "₹${total.toStringAsFixed(0)}",
            isBold: true,
            fontSize: 16,
          ),
          if (discount > 0 || cartService.appliedCoupon == "DEALERDHAMAKA") ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF298E4D).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF298E4D).withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    cartService.appliedCoupon == "DEALERDHAMAKA"
                        ? CupertinoIcons.gift_fill
                        : CupertinoIcons.checkmark_seal_fill,
                    color: const Color(0xFF298E4D),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cartService.appliedCoupon == "DEALERDHAMAKA"
                          ? l10n.freeGiftMessage
                          : l10n.couponSavingsSuccess(discount.toStringAsFixed(0)),
                      style: const TextStyle(
                        color: Color(0xFF298E4D),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBillRow({
    required String label,
    required String value,
    Color? valueColor,
    required bool isBold,
    double fontSize = 13,
    String? strikeThroughOriginal,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            color: isBold ? Colors.black : Colors.grey.shade600,
          ),
        ),
        Row(
          children: [
            if (strikeThroughOriginal != null) ...[
              Text(
                strikeThroughOriginal,
                style: TextStyle(
                  fontSize: fontSize - 1,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade400,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              value,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
                color:
                    valueColor ??
                    (isBold ? Colors.black : Colors.grey.shade900),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFEEEEEE)),
              ),
            );
          }),
        );
      },
    );
  }
}
