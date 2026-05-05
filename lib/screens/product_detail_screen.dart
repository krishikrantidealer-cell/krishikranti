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
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color lightGreenBg = const Color(0xFFE8F5E9);
  final Color buyNowGreen = const Color(0xFF2E7D32);
  final Color addToCartOrange = const Color(0xFFFF9800);

  final FavoriteService _favoriteService = FavoriteService();
  final ProductRepository _productRepository = ProductRepository();

  late Product _product;
  bool _isLoading = true;
  String? _errorMessage;

  // Selected quantities for each variant
  final Map<String, int> _quantityMap = {};

  @override
  void initState() {
    super.initState();
    _product = widget.product;

    // SMART HYDRATION: If we already have the "heavy" data, don't show the shimmer
    if (_product.details != null && _product.variants.isNotEmpty) {
      _isLoading = false;
    }

    _favoriteService.addListener(_onFavoriteChanged);
    _fetchProductDetails();
  }

  @override
  void dispose() {
    _favoriteService.removeListener(_onFavoriteChanged);
    super.dispose();
  }

  void _onFavoriteChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _fetchProductDetails() async {
    // Sync quantities for any variants we already have
    for (var variant in _product.variants) {
      _quantityMap.putIfAbsent(variant.id, () => 0);
    }

    try {
      final updatedProduct = await _productRepository.getProductDetail(
        widget.product.id,
      );
      if (mounted) {
        setState(() {
          // SAFE MERGE: Keep existing data if new data is missing or invalid
          _product = Product(
            id: updatedProduct.id,
            title: updatedProduct.title.isNotEmpty
                ? updatedProduct.title
                : _product.title,
            thumbnail: updatedProduct.thumbnail.isNotEmpty
                ? updatedProduct.thumbnail
                : _product.thumbnail,
            images: updatedProduct.images.isNotEmpty
                ? updatedProduct.images
                : _product.images,
            minPrice: updatedProduct.minPrice ?? _product.minPrice,
            maxPrice: updatedProduct.maxPrice ?? _product.maxPrice,
            brandName: updatedProduct.brandName ?? _product.brandName,
            technicalName:
                updatedProduct.technicalName ?? _product.technicalName,
            categoryId: updatedProduct.categoryId ?? _product.categoryId,
            subCategoryId:
                updatedProduct.subCategoryId ?? _product.subCategoryId,
            details: updatedProduct.details ?? _product.details,
            variants: updatedProduct.variants.isNotEmpty
                ? updatedProduct.variants
                : _product.variants,
            vendor: updatedProduct.vendor ?? _product.vendor,
            availabilityStatus:
                updatedProduct.availabilityStatus ??
                _product.availabilityStatus,
            averageRating: updatedProduct.averageRating > 0
                ? updatedProduct.averageRating
                : _product.averageRating,
            numReviews: updatedProduct.numReviews > 0
                ? updatedProduct.numReviews
                : _product.numReviews,
          );

          // Ensure all variants from updated product are in the map
          for (var variant in _product.variants) {
            _quantityMap.putIfAbsent(variant.id, () => 0);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // We don't set error message here because we still have the initial product data
          // which is better than showing an error screen.
        });
      }
    }
  }

  void _showQuantityPicker(Variant variant) {
    int currentQty = _quantityMap[variant.id] ?? 0;
    if (currentQty == 0) currentQty = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuantityPickerSheet(
        initialValue: currentQty,
        onApply: (newQty) {
          setState(() {
            _quantityMap[variant.id] = newQty;
          });
        },
      ),
    );
  }

  void _toggleFavorite() {
    _favoriteService.toggleFavorite(
      FavoriteProduct(
        id: _product.id,
        name: _product.title,
        category: _product.categoryId ?? "Agricultural Product",
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
    _quantityMap.forEach((key, value) {
      total += value;
    });
    return total;
  }

  double get grandTotal {
    double total = 0;
    for (var variant in _product.variants) {
      total += (_quantityMap[variant.id] ?? 0) * variant.price;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Error state still shows a full scaffold but with back button
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Section: Image Carousel
                      // Top Section: Image Carousel with Seamless Handover
                      Stack(
                        children: [
                          // 1. Persistent Progressive Image (Hero Source)
                          Hero(
                            tag: 'product_${_product.id}',
                            child: Container(
                              color: Colors.white,
                              width: double.infinity,
                              height: 350,
                              alignment: Alignment.center,
                              child: ProgressiveImage(
                                thumbnailUrl:
                                    widget.thumbnailUrl ?? _product.thumbnail,
                                imageUrl: _product.images.isNotEmpty
                                    ? _product.images.first
                                    : (widget.thumbnailUrl ??
                                          _product.thumbnail),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          // 2. High-Res Gallery (Overlay)
                          if (_product.details?.originalImages.isNotEmpty ??
                              false)
                            CarouselSlider(
                              options: CarouselOptions(
                                height: 350,
                                viewportFraction: 1.0,
                                enableInfiniteScroll:
                                    _product.details!.originalImages.length > 1,
                              ),
                              items: _product.details!.originalImages.map((
                                imageUrl,
                              ) {
                                return Container(
                                  width: MediaQuery.of(context).size.width,
                                  color: Colors.transparent,
                                  alignment: Alignment.center,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.contain,
                                      fadeInDuration: const Duration(
                                        milliseconds: 600,
                                      ),
                                      placeholder: (context, url) =>
                                          CachedNetworkImage(
                                            imageUrl:
                                                widget.thumbnailUrl ??
                                                _product.thumbnail,
                                            fit: BoxFit.contain,
                                          ),
                                      errorWidget: (context, url, error) =>
                                          const SizedBox.shrink(),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildTopIcon(
                                    icon: CupertinoIcons.back,
                                    onTap: () => Navigator.pop(context),
                                  ),
                                  Row(
                                    children: [
                                      _buildTopIcon(
                                        icon: Icons.share_outlined,
                                        onTap: () {
                                          Share.share(
                                            'Check out this product: ${_product.title}',
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 12),
                                      _buildTopIcon(
                                        icon:
                                            _favoriteService.isFavorite(
                                              _product.title,
                                            )
                                            ? CupertinoIcons.heart_fill
                                            : CupertinoIcons.heart,
                                        iconColor:
                                            _favoriteService.isFavorite(
                                              _product.title,
                                            )
                                            ? Colors.red
                                            : Colors.black87,
                                        onTap: _toggleFavorite,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_product.averageRating > 0)
                            Positioned(
                              bottom: 16,
                              left: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryGreen,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _product.averageRating.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.star,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _product.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if ((_product.technicalName != null &&
                                    _product.technicalName!.isNotEmpty) ||
                                (widget.product.technicalName != null &&
                                    widget.product.technicalName!.isNotEmpty))
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  "Technical: ${_product.technicalName ?? widget.product.technicalName}",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 6),
                            if ((_product.brandName != null &&
                                    _product.brandName!.isNotEmpty) ||
                                (widget.product.brandName != null &&
                                    widget.product.brandName!.isNotEmpty))
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: lightGreenBg,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _product.brandName ??
                                        widget.product.brandName!,
                                    style: TextStyle(
                                      color: primaryGreen,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // FEATURES SECTION
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        clipBehavior: Clip.none,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildFeatureCard("Expert Recommended"),
                            const SizedBox(width: 8),
                            _buildFeatureCard("Fast Results"),
                            const SizedBox(width: 8),
                            _buildFeatureCard("Original Product"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // KYC Section
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: lightGreenBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.lock_shield_fill,
                                    color: primaryGreen,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      "Complete KYC to unlock wholesale pricing",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 32,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/kyc');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryGreen,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                      ),
                                      child: const Text(
                                        "Complete KYC",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Price Section
                            if (_isLoading)
                              _buildShimmerLine(120)
                            else
                              Row(
                                children: [
                                  if (_product!.compareAtPrice >
                                      _product!.price)
                                    Text(
                                      "₹${_product!.compareAtPrice.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        decoration: TextDecoration.lineThrough,
                                        fontSize: 16,
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "₹${_product!.price.toStringAsFixed(0)}",
                                    style: TextStyle(
                                      color: primaryGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (_product!.compareAtPrice >
                                      _product!.price)
                                    Text(
                                      "[${((_product!.compareAtPrice - _product!.price) / _product!.compareAtPrice * 100).toStringAsFixed(0)}% OFF]",
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                ],
                              ),
                            const SizedBox(height: 20),

                            const Text(
                              "Select Pack Size",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Pack Size Cards (Variants)
                            if (_isLoading)
                              Column(
                                children: List.generate(
                                  3,
                                  (index) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildShimmerBox(
                                      double.infinity,
                                      80,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ..._product!.variants.map((variant) {
                                return PackSizeCard(
                                  title: variant.size,
                                  pricePerLtr: "Exclusive wholesale price",
                                  price:
                                      (variant.price *
                                              (_quantityMap[variant.id]! > 0
                                                  ? _quantityMap[variant.id]!
                                                  : 1))
                                          .toInt(),
                                  quantity: _quantityMap[variant.id]!,
                                  onTap: () => _showQuantityPicker(variant),
                                );
                              }),

                            const SizedBox(height: 24),

                            // Description Section
                            const Text(
                              "Description",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_isLoading)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildShimmerLine(double.infinity),
                                  const SizedBox(height: 4),
                                  _buildShimmerLine(double.infinity),
                                  const SizedBox(height: 4),
                                  _buildShimmerLine(200),
                                ],
                              )
                            else if (_product?.details != null)
                              Text(
                                _product!.details!.description,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  height: 1.5,
                                ),
                              ),
                            const SizedBox(height: 24),

                            // TOTAL SECTION CARD
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: primaryGreen,
                                  width: 1,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        "Total Items: ",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        "$totalItems",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "Grand Total: ",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                          color: primaryGreen,
                                        ),
                                      ),
                                      Text(
                                        "₹ ${grandTotal.toStringAsFixed(0)}",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: primaryGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            final cartService = Provider.of<CartService>(
                              context,
                              listen: false,
                            );
                            bool added = false;

                            _quantityMap.forEach((variantId, qty) {
                              if (qty > 0) {
                                final variant = _product!.variants.firstWhere(
                                  (v) => v.id == variantId,
                                );
                                cartService.addItem(
                                  productId: _product!.id,
                                  variantId: variant.id,
                                  productName: _product!.title,
                                  productImage: _product!.thumbnail,
                                  technicalName: _product!.technicalName ?? "",
                                  variant: variant.size,
                                  price: variant.price,
                                  qty: qty,
                                );
                                added = true;
                              }
                            });

                            if (added) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CartScreen(),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please select a pack size"),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: addToCartOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            l10n.cart,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            final cartService = Provider.of<CartService>(
                              context,
                              listen: false,
                            );
                            bool added = false;

                            _quantityMap.forEach((variantId, qty) {
                              if (qty > 0) {
                                final variant = _product!.variants.firstWhere(
                                  (v) => v.id == variantId,
                                );
                                cartService.addItem(
                                  productId: _product!.id,
                                  variantId: variant.id,
                                  productName: _product!.title,
                                  productImage: _product!.thumbnail,
                                  technicalName: _product!.technicalName ?? "",
                                  variant: variant.size,
                                  price: variant.price,
                                  qty: qty,
                                );
                                added = true;
                              }
                            });

                            if (added) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ShippingAddressScreen(),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please select a pack size"),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buyNowGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Buy Now",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
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
      ),
    );
  }

  Widget _buildShimmerLine(double width) {
    return Container(
      height: 14,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildShimmerBox(double width, double height) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildFeatureCard(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check,
            color: const Color(0xFF1B5E20),
            size: 16,
            weight: 700,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopIcon({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.black87,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}

class PackSizeCard extends StatelessWidget {
  final String title;
  final String pricePerLtr;
  final int price;
  final int quantity;
  final VoidCallback onTap;

  const PackSizeCard({
    super.key,
    required this.title,
    required this.pricePerLtr,
    required this.price,
    required this.quantity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF2E7D32);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: quantity > 0 ? primaryGreen : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pricePerLtr,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _qtyBtn(CupertinoIcons.minus, onTap),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      "$quantity",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  _qtyBtn(CupertinoIcons.plus, onTap, isAdd: true),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "₹ $price",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap, {bool isAdd = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isAdd ? const Color(0xFF2E7D32) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isAdd ? Colors.white : Colors.black87,
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
  late int selectedQty;
  late FixedExtentScrollController scrollController;
  late TextEditingController textController;

  @override
  void initState() {
    super.initState();
    selectedQty = widget.initialValue;
    scrollController = FixedExtentScrollController(
      initialItem: selectedQty - 1,
    );
    textController = TextEditingController(text: selectedQty.toString());
  }

  @override
  void dispose() {
    scrollController.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Select Quantity",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: textController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Custom Quantity",
              hintText: "Enter quantity",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (val) {
              int? q = int.tryParse(val);
              if (q != null && q > 0 && q <= 100) {
                setState(() {
                  selectedQty = q;
                  scrollController.jumpToItem(q - 1);
                });
              }
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: ListWheelScrollView.useDelegate(
              controller: scrollController,
              itemExtent: 40,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                setState(() {
                  selectedQty = index + 1;
                  textController.text = selectedQty.toString();
                });
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: 100,
                builder: (context, index) {
                  bool isSelected = selectedQty == index + 1;
                  return Center(
                    child: Container(
                      width: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2E7D32)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${index + 1}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(selectedQty);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Apply",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
