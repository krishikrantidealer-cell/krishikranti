import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/core/cart_service.dart';
import 'package:krishikranti/core/favorite_service.dart';
import 'package:krishikranti/screens/shipping_address_screen.dart';
import 'package:krishikranti/screens/cart_screen.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:krishikranti/features/products/data/models/product_model.dart';
import 'package:krishikranti/features/products/data/repositories/product_repository.dart';

import 'package:krishikranti/widgets/progressive_image.dart';
import 'package:krishikranti/widgets/animated_heart.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final String? thumbnailUrl;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.thumbnailUrl,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final Color primaryGreen = const Color(0xFF006D32);
  final Color secondaryGreen = const Color(0xFFE8F5E9);
  final Color accentOrange = const Color(0xFFFF9100);

  final FavoriteService _favoriteService = FavoriteService();
  final ProductRepository _productRepository = ProductRepository();

  late Product _product;
  bool _isLoading = true;
  final Map<String, int> _quantityMap = {};
  late ScrollController _scrollController;
  bool _showStickyHeader = false;

  late CartService _cartService;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _scrollController = ScrollController()..addListener(_onScroll);

    // Synchronously initialize quantities from cart to prevent flicker
    final cartService = Provider.of<CartService>(context, listen: false);
    for (var variant in _product.variants) {
      final cartItem = cartService.items.firstWhere(
        (item) => item.variantId == variant.id,
        orElse: () => CartItem(
          productId: '',
          variantId: '',
          productName: '',
          productImage: '',
          technicalName: '',
          variant: '',
          price: 0,
          qty: 0,
        ),
      );
      _quantityMap[variant.id] = cartItem.qty;
    }

    if (_product.details != null && _product.variants.isNotEmpty) {
      _isLoading = false;
    }

    // Listen to cart changes for subsequent updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _cartService = Provider.of<CartService>(context, listen: false);
      _cartService.addListener(_onCartChanged);
      _fetchProductDetails();
    });
  }

  void _onCartChanged() {
    if (!mounted) return;
    
    final cartService = Provider.of<CartService>(context, listen: false);
    bool changed = false;
    
    for (var variant in _product.variants) {
      final cartItem = cartService.items.firstWhere(
        (item) => item.variantId == variant.id,
        orElse: () => CartItem(
          productId: '',
          variantId: '',
          productName: '',
          productImage: '',
          technicalName: '',
          variant: '',
          price: 0,
          qty: 0,
        ),
      );
      
      if (_quantityMap[variant.id] != cartItem.qty) {
        _quantityMap[variant.id] = cartItem.qty;
        changed = true;
      }
    }
    
    if (changed) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Use the stored reference to safely remove listener during dispose
    _cartService.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 400 && !_showStickyHeader) {
      setState(() => _showStickyHeader = true);
    } else if (_scrollController.offset <= 400 && _showStickyHeader) {
      setState(() => _showStickyHeader = false);
    }
  }

  Future<void> _fetchProductDetails() async {
    final cartService = Provider.of<CartService>(context, listen: false);
    for (var variant in _product.variants) {
      final cartItem = cartService.items.firstWhere(
        (item) => item.variantId == variant.id,
        orElse: () => CartItem(
          productId: '',
          variantId: '',
          productName: '',
          productImage: '',
          technicalName: '',
          variant: '',
          price: 0,
          qty: 0,
        ),
      );
      _quantityMap[variant.id] = cartItem.qty;
    }
    try {
      final updatedProduct = await _productRepository.getProductDetail(
        _product.id,
      );
      if (mounted) {
        setState(() {
          _product = updatedProduct;
          for (var variant in _product.variants) {
            final cartItem = cartService.items.firstWhere(
              (item) => item.variantId == variant.id,
              orElse: () => CartItem(
                productId: '',
                variantId: '',
                productName: '',
                productImage: '',
                technicalName: '',
                variant: '',
                price: 0,
                qty: 0,
              ),
            );
            _quantityMap[variant.id] = cartItem.qty;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleFavorite() {
    _favoriteService.toggleFavorite(
      FavoriteProduct(
        id: _product.id,
        name: _product.title,
        category: _product.categoryId ?? "Agriculture",
        price: _product.price.toString(),
        imageUrl: _product.thumbnail,
        weight: _product.variants.isNotEmpty
            ? _product.variants.first.size
            : "Standard",
      ),
    );
  }

  int get totalItems {
    int total = 0;
    _quantityMap.forEach((_, v) => total += v);
    return total;
  }

  double get grandTotal {
    double total = 0;
    for (var v in _product.variants) {
      total += (_quantityMap[v.id] ?? 0) * v.price;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
              slivers: [
                _buildImageHero(context),
                SliverToBoxAdapter(
                  child: AnimationLimiter(
                    child: Column(
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 600),
                        childAnimationBuilder: (w) => SlideAnimation(
                          verticalOffset: 30,
                          child: FadeInAnimation(child: w),
                        ),
                        children: [
                          _buildPremiumInfoSection(),
                          _buildExpertAnalysis(),
                          _buildVariantSelection(),
                          _buildProductDescription(),
                          const SizedBox(
                            height: 120,
                          ), // Bottom padding for actions
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            _buildFloatingActionBar(),
            if (_showStickyHeader) _buildStickyHeader(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHero(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: _buildHeaderIcon(
        CupertinoIcons.back,
        () => Navigator.pop(context),
      ),
      actions: [
        _buildHeaderIcon(Icons.share_outlined, () {
          Share.share('Check out ${_product.title} on Krishi Kranti');
        }),
        const SizedBox(width: 8),
        ListenableBuilder(
          listenable: _favoriteService,
          builder: (context, _) => _buildHeaderIcon(
            _favoriteService.isFavorite(_product.id)
                ? CupertinoIcons.heart_fill
                : CupertinoIcons.heart,
            _toggleFavorite,
            color: _favoriteService.isFavorite(_product.id)
                ? Colors.red
                : Colors.black87,
          ),
        ),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 80, bottom: 40),
              child: Hero(
                tag: 'product_${_product.id}',
                child: ProgressiveImage(
                  thumbnailUrl: widget.thumbnailUrl ?? _product.thumbnail,
                  imageUrl: _product.images.isNotEmpty
                      ? _product.images.first
                      : _product.thumbnail,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            if (_product.details?.originalImages.isNotEmpty ?? false)
              CarouselSlider(
                options: CarouselOptions(
                  height: 420,
                  viewportFraction: 1.0,
                  enableInfiniteScroll:
                      _product.details!.originalImages.length > 1,
                ),
                items: _product.details!.originalImages
                    .map(
                      (url) => Container(
                        padding: const EdgeInsets.only(top: 80, bottom: 40),
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(
    IconData icon,
    VoidCallback onTap, {
    Color color = Colors.black87,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildPremiumInfoSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_product.brandName?.isNotEmpty ?? false)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: secondaryGreen,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _product.brandName!.toUpperCase(),
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              const Spacer(),
              if (_product.averageRating > 0)
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _product.averageRating.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      " (${_product.numReviews})",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _product.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          if (_product.technicalName?.isNotEmpty ?? false) ...[
            const SizedBox(height: 2),
            Text(
              _product.technicalName!,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpertAnalysis() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildCompactHighlight(Icons.verified_rounded, "Expert Choice"),
            const SizedBox(width: 8),
            _buildCompactHighlight(Icons.bolt_rounded, "Fast Acting"),
            const SizedBox(width: 8),
            _buildCompactHighlight(Icons.security_rounded, "Original"),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHighlight(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryGreen.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primaryGreen, size: 12),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantSelection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select Configuration",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          ..._product.variants.map(
            (v) => _PremiumPackCard(
              variant: v,
              quantity: _quantityMap[v.id] ?? 0,
              onTap: () => _showQuantityPicker(v),
              onChanged: (qty) => setState(() => _quantityMap[v.id] = qty),
              primaryColor: primaryGreen,
              imageUrl: _product.thumbnail,
            ),
          ),
          if (totalItems > 0) ...[
            const SizedBox(height: 12),
            _buildOrderSummaryCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(0, 4, 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.grey.shade800, fontSize: 15),
                children: [
                  const TextSpan(text: "Total Items: "),
                  TextSpan(
                    text: "$totalItems",
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const Spacer(),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  color: primaryGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  const TextSpan(text: "Grand Total: "),
                  TextSpan(
                    text: "₹ ${grandTotal.toStringAsFixed(0)}",
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDescription() {
    if (_product.details == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Product Insights",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _product.details!.description,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFloatingActionBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _ActionBtn(
                label: _isAddingToCart ? "ADDING..." : "ADD TO CART",
                onPressed: _isAddingToCart ? () {} : _handleAddToCart,
                isOutlined: true,
                color: accentOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionBtn(
                label: "BUY NOW",
                onPressed: _handleBuyNow,
                color: primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildHeaderIcon(
                  CupertinoIcons.back,
                  () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _product.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "₹ ${grandTotal.toStringAsFixed(0)} total",
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQuantityPicker(Variant v) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuantityPickerSheet(
        initialValue: _quantityMap[v.id] ?? 1,
        onApply: (qty) => setState(() => _quantityMap[v.id] = qty),
      ),
    );
  }

  bool _isAddingToCart = false;

  void _handleAddToCart() {
    final cartService = Provider.of<CartService>(context, listen: false);
    final selectedEntries = _quantityMap.entries
        .where((e) => e.value > 0)
        .toList();

    if (selectedEntries.isEmpty) {
      _showError("Please select a pack size");
      return;
    }

    // 1. Give instant tactile feedback
    HapticFeedback.mediumImpact();

    // 2. Prepare items
    final List<Map<String, dynamic>> itemsToAdd = selectedEntries.map((
      entry,
    ) {
      final v = _product.variants.firstWhere((x) => x.id == entry.key);
      return {
        'variantId': v.id,
        'quantity': entry.value,
        'productName': _product.title,
        'productImage': _product.thumbnail,
        'technicalName': _product.technicalName ?? "",
        'variant': v.size,
        'price': v.price,
      };
    }).toList();

    // 3. Fire and Forget: Background Sync (Optimistic)
    cartService.addItems(
      productId: _product.id,
      items: itemsToAdd,
      sync: false,
      isReplace: true,
    ).catchError((e) {
      _showError("Sync failed, but items added locally.");
    });

    // 4. Update local state and Navigate INSTANTLY
    setState(() {
      for (var item in itemsToAdd) {
        _quantityMap[item['variantId']] = (item['quantity'] as int);
      }
    });

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  void _handleBuyNow() {
    _handleAddToCart();
    if (totalItems > 0)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ShippingAddressScreen()),
      );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _PremiumPackCard extends StatelessWidget {
  final Variant variant;
  final int quantity;
  final VoidCallback onTap;
  final Function(int) onChanged;
  final Color primaryColor;
  final String imageUrl;

  const _PremiumPackCard({
    required this.variant,
    required this.quantity,
    required this.onTap,
    required this.onChanged,
    required this.primaryColor,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = quantity > 0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ProgressiveImage(
                  thumbnailUrl: imageUrl,
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  padding: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    variant.size,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "₹${variant.price.toStringAsFixed(0)}",
                        style: TextStyle(
                          color: isSelected
                              ? primaryColor
                              : Colors.grey.shade600,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      if (variant.compareAtPrice > variant.price) ...[
                        const SizedBox(width: 6),
                        Text(
                          "₹${variant.compareAtPrice.toStringAsFixed(0)}",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "${((variant.compareAtPrice - variant.price) / variant.compareAtPrice * 100).toStringAsFixed(0)}% OFF",
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.w900,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 4),
                    Text(
                      "$quantity x ₹${variant.price.toStringAsFixed(0)} = ₹${(variant.price * quantity).toStringAsFixed(0)}",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Row(
                children: [
                  _SmallBtn(
                    Icons.remove,
                    () => onChanged(quantity > 1 ? quantity - 1 : 0),
                    primaryColor,
                  ),
                  SizedBox(
                    width: 28,
                    child: Text(
                      quantity.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  _SmallBtn(
                    Icons.add,
                    () => onChanged(quantity + 1),
                    primaryColor,
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "SELECT",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _SmallBtn(this.icon, this.onTap, this.color);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isOutlined;
  final Color color;
  final bool small;
  const _ActionBtn({
    required this.label,
    required this.onPressed,
    this.isOutlined = false,
    required this.color,
    this.small = false,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: small ? 40 : 60,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: small ? 11 : 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                elevation: 8,
                shadowColor: color.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
    );
  }
}

class _QuantityPickerSheet extends StatefulWidget {
  final int initialValue;
  final Function(int) onApply;
  const _QuantityPickerSheet({
    required this.initialValue,
    required this.onApply,
  });
  @override
  State<_QuantityPickerSheet> createState() => _QuantityPickerSheetState();
}

class _QuantityPickerSheetState extends State<_QuantityPickerSheet> {
  late int _value;
  late TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _controller = TextEditingController(text: _value.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _update(int val) {
    if (val >= 0)
      setState(() {
        _value = val;
        _controller.text = _value.toString();
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Adjust Quantity",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _BigBtn(
                  CupertinoIcons.minus,
                  () => _update(_value > 0 ? _value - 1 : 0),
                ),
                const SizedBox(width: 32),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF006D32),
                    ),
                    decoration: const InputDecoration(border: InputBorder.none),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) =>
                        setState(() => _value = int.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 32),
                _BigBtn(CupertinoIcons.plus, () => _update(_value + 1)),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(_value);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006D32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "CONFIRM",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _BigBtn(this.icon, this.onTap);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 28, color: Colors.black87),
      ),
    );
  }
}
