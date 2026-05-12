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
import 'package:krishikranti/features/products/data/models/category_model.dart';

import 'package:krishikranti/widgets/progressive_image.dart';
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
  final Color buttonGreen = const Color(0xFF298E4D);
  final Color buttonOrange = const Color(0xFFFA9527);

  final FavoriteService _favoriteService = FavoriteService();
  final ProductRepository _productRepository = ProductRepository();

  late Product _product;
  bool _isLoading = true;
  late ScrollController _scrollController;
  bool _showStickyHeader = false;
  Variant? _selectedVariant;
  String? _selectedPackSize;
  int _activeTab = 0;
  bool _isDescriptionExpanded = false;
  int _currentImageIndex = 0;
  String? _categoryName;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _scrollController = ScrollController()..addListener(_onScroll);
    if (_product.variants.isNotEmpty) {
      _selectedVariant = _product.variants.first;
      _selectedPackSize = _parseSize(_selectedVariant!.size).packSize;
    }

    // Instant Category Name Fallback Resolution on Initial Load
    if (_product.categoryId != null && _product.categoryId!.isNotEmpty) {
      final cleanId = _product.categoryId!.toLowerCase().trim();
      if (cleanId.contains('herbicide')) {
        _categoryName = 'Herbicides';
      } else if (cleanId.contains('insecticide')) {
        _categoryName = 'Insecticides';
      } else if (cleanId.contains('fungicide')) {
        _categoryName = 'Fungicides';
      } else if (cleanId.contains('fertilizer')) {
        _categoryName = 'Fertilizers';
      } else if (cleanId.contains('pgr') || cleanId.contains('growth')) {
        _categoryName = 'PGRs';
      } else if (cleanId.contains('bio')) {
        _categoryName = 'Bio-Products';
      } else if (cleanId.length < 10) {
        _categoryName = _product.categoryId;
      }
    }

    if (_categoryName == null) {
      final combinedText = '${_product.title} ${_product.brandName ?? ""} ${_product.technicalName ?? ""}'.toLowerCase();
      if (combinedText.contains('herbicide')) {
        _categoryName = 'Herbicides';
      } else if (combinedText.contains('insecticide')) {
        _categoryName = 'Insecticides';
      } else if (combinedText.contains('fungicide')) {
        _categoryName = 'Fungicides';
      } else if (combinedText.contains('fertilizer')) {
        _categoryName = 'Fertilizers';
      } else if (combinedText.contains('pgr') || combinedText.contains('growth')) {
        _categoryName = 'PGRs';
      } else if (combinedText.contains('bio')) {
        _categoryName = 'Bio-Products';
      }
    }

    if (_product.details != null && _product.variants.isNotEmpty) {
      _isLoading = false;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchProductDetails();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
    try {
      final results = await Future.wait([
        _productRepository.getProductDetail(_product.id),
        _productRepository.getCategories(),
      ]);
      final updatedProduct = results[0] as Product;
      final categoriesList = results[1] as List<Category>;

      if (mounted) {
        setState(() {
          _product = updatedProduct;
          if (_product.variants.isNotEmpty) {
            _selectedVariant = _product.variants.firstWhere(
              (v) => v.id == _selectedVariant?.id,
              orElse: () => _product.variants.first,
            );
            _selectedPackSize = _parseSize(_selectedVariant!.size).packSize;
          }

          if (_product.categoryId != null) {
            final matchedCat = categoriesList.firstWhere(
              (c) => c.id == _product.categoryId,
              orElse: () => Category(id: '', name: ''),
            );
            if (matchedCat.id.isNotEmpty) {
              _categoryName = matchedCat.name;
            }
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
    final cartService = Provider.of<CartService>(context, listen: false);
    int total = 0;
    for (var v in _product.variants) {
      total += cartService.getVariantQty(v.id);
    }
    return total;
  }

  double get grandTotal {
    final cartService = Provider.of<CartService>(context, listen: false);
    double total = 0;
    for (var v in _product.variants) {
      total += cartService.getVariantQty(v.id) * v.price;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    // Watch CartService for centralized real-time updates across the screen
    Provider.of<CartService>(context);

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
                          _buildProductDescription(),
                          _buildConfigurationCard(),
                          const SizedBox(
                            height: 100,
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
          builder: (context, _) => Hero(
            tag: 'heart_${_product.id}',
            child: _buildHeaderIcon(
              _favoriteService.isFavorite(_product.id)
                  ? CupertinoIcons.heart_fill
                  : CupertinoIcons.heart,
              _toggleFavorite,
              color: _favoriteService.isFavorite(_product.id)
                  ? Colors.red
                  : Colors.black87,
            ),
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
            if (_product.details?.originalImages.isNotEmpty ?? false) ...[
              CarouselSlider(
                options: CarouselOptions(
                  height: 420,
                  viewportFraction: 1.0,
                  enableInfiniteScroll:
                      _product.details!.originalImages.length > 1,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
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
              if (_product.details!.originalImages.length > 1)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _product.details!.originalImages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentImageIndex == index ? 14 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: _currentImageIndex == index
                              ? primaryGreen
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _product.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.2,
              letterSpacing: -0.5,
              color: Colors.black,
            ),
          ),
          if (_product.technicalName?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Text(
              _product.technicalName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (_product.brandName?.isNotEmpty ?? false)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: secondaryGreen,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: primaryGreen.withOpacity(0.1)),
                  ),
                  child: Text(
                    _product.brandName!.toUpperCase(),
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _product.averageRating > 0 ? Colors.orange.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _product.averageRating > 0 ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: _product.averageRating > 0 ? Colors.orange : Colors.grey.shade400,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _product.averageRating > 0 ? _product.averageRating.toString() : "0.0",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _product.averageRating > 0 ? Colors.orange : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _product.averageRating > 0 ? " (${_product.numReviews})" : " (0 reviews)",
                      style: TextStyle(
                        color: _product.averageRating > 0 ? Colors.orange.shade800 : Colors.grey.shade500,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpertAnalysis() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFFF1F8F5), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryGreen.withOpacity(0.12), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTrustFeature(Icons.verified_user_rounded, "Expert Choice"),
            _buildTrustDivider(),
            _buildTrustFeature(Icons.bolt_rounded, "Fast Acting"),
            _buildTrustDivider(),
            _buildTrustFeature(Icons.security_rounded, "100% Original"),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustDivider() {
    return Container(
      width: 1,
      height: 28,
      color: primaryGreen.withOpacity(0.15),
    );
  }

  Widget _buildTrustFeature(IconData icon, String title) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryGreen, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationCard() {
    if (_product.variants.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Packaging & Quantity",
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          ..._product.variants.map((v) {
            final cartService = Provider.of<CartService>(
              context,
              listen: false,
            );
            final int quantity = cartService.getVariantQty(v.id);
            final bool isSyncing = cartService.syncingVariantIds.contains(v.id);
            final bool isSelected = quantity > 0;

            // Dynamic tier price calculation based on total volume of this variant
            double unitPrice = v.price;
            if (isSelected) {
              final double totalVolume = v.packVolume * quantity;
              if (totalVolume > 50.0) {
                unitPrice = v.price50_plus > 0 ? v.price50_plus : v.price;
              } else if (totalVolume > 30.0) {
                unitPrice = v.price30_50 > 0 ? v.price30_50 : v.price;
              } else if (totalVolume >= 10.0) {
                unitPrice = v.price10_30 > 0 ? v.price10_30 : v.price;
              }
            }

            final String? perUnitLabel = _getPerUnitLabel(v.size, unitPrice);
            final parsedSize = _parseSize(v.size);

            final bool isKg =
                v.size.toLowerCase().contains('g') ||
                v.size.toLowerCase().contains('kg') ||
                v.size.toLowerCase().contains('k');
            final String unitSuffix = isKg ? "Kg" : "Litre";
            final String configName =
                parsedSize.configuration.toLowerCase() == "single"
                ? "${v.packVolume.toInt()} $unitSuffix"
                : parsedSize.configuration;

            final String displayConfigName = isSelected
                ? _getUpdatedConfigName(configName, quantity)
                : configName;

            final double displayPrice = isSelected
                ? (unitPrice * v.packVolume * quantity)
                : (v.price * v.packVolume);
            final double displayCompareAtPrice = isSelected
                ? (v.compareAtPrice * v.packVolume * quantity)
                : (v.compareAtPrice * v.packVolume);

            // Calculate bulk discount details
            double minPrice = v.price;
            if (v.price50_plus > 0 && v.price50_plus < minPrice) {
              minPrice = v.price50_plus;
            }
            if (v.price30_50 > 0 && v.price30_50 < minPrice) {
              minPrice = v.price30_50;
            }
            if (v.price10_30 > 0 && v.price10_30 < minPrice) {
              minPrice = v.price10_30;
            }

            final bool hasBulkDiscount = minPrice < v.price;
            final double bulkDiscountPercent = hasBulkDiscount
                ? ((v.price - minPrice) / v.price * 100)
                : 0.0;

            bool isBulkActive = false;
            String activeTierName = "";
            if (isSelected) {
              final double totalVolume = v.packVolume * quantity;
              if (totalVolume > 50.0 && v.price50_plus > 0) {
                isBulkActive = true;
                activeTierName = "50L+ Tier";
              } else if (totalVolume > 30.0 && v.price30_50 > 0) {
                isBulkActive = true;
                activeTierName = "30-50L Tier";
              } else if (totalVolume >= 10.0 && v.price10_30 > 0) {
                isBulkActive = true;
                activeTierName = "10-30L Tier";
              }
            }

            // Parse pack size value and unit for modern vertical stacked layout
            final packSizeStr = parsedSize.packSize;
            final match = RegExp(
              r'^([\d.]+)\s*([a-zA-Z]+)?',
            ).firstMatch(packSizeStr);
            final String val = match != null
                ? (match.group(1) ?? packSizeStr)
                : packSizeStr;
            final String unit = match != null ? (match.group(2) ?? "") : "";

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Card: Pack Size card (Stunning pill badge layout - compacted)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 66,
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      primaryGreen.withOpacity(0.08),
                                      primaryGreen.withOpacity(0.01),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  )
                                : null,
                            color: isSelected ? null : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? primaryGreen
                                  : Colors.grey.shade300,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? primaryGreen.withOpacity(0.08)
                                    : Colors.black.withOpacity(0.01),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          child: unit.isNotEmpty
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      val,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: Theme.of(
                                          context,
                                        ).textTheme.titleLarge?.fontFamily,
                                        fontWeight: FontWeight.w900,
                                        color: isSelected
                                            ? primaryGreen
                                            : Colors.black,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      unit.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontFamily: Theme.of(
                                          context,
                                        ).textTheme.titleLarge?.fontFamily,
                                        fontWeight: FontWeight.w900,
                                        color: isSelected
                                            ? primaryGreen.withOpacity(0.8)
                                            : Colors.black54,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  val,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontFamily: Theme.of(
                                      context,
                                    ).textTheme.titleLarge?.fontFamily,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),

                        // Right Card: Variant Card (Stunning pricing & quantity container - compacted)
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? primaryGreen
                                    : Colors.grey.shade300,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? primaryGreen.withOpacity(0.08)
                                      : Colors.black.withOpacity(0.012),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              displayConfigName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontFamily: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.fontFamily,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          if (isBulkActive) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 1.5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE8F5E9),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: primaryGreen
                                                      .withOpacity(0.2),
                                                  width: 0.5,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.bolt_rounded,
                                                    color: primaryGreen,
                                                    size: 9,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    "$activeTierName Applied",
                                                    style: TextStyle(
                                                      color: primaryGreen,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontSize: 8,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ] else if (hasBulkDiscount) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 1.5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: secondaryGreen,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: primaryGreen
                                                      .withOpacity(0.15),
                                                  width: 0.5,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.trending_down_rounded,
                                                    color: primaryGreen,
                                                    size: 9,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    "Save upto ${bulkDiscountPercent.toStringAsFixed(0)}% bulk",
                                                    style: TextStyle(
                                                      color: primaryGreen,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontSize: 8,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      // Row 1: Selling Price and Per-Unit label
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            "₹${displayPrice.toStringAsFixed(0)}",
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13.5,
                                            ),
                                          ),
                                          if (perUnitLabel != null) ...[
                                            const SizedBox(width: 4),
                                            Text(
                                              "($perUnitLabel)",
                                              style: TextStyle(
                                                color: primaryGreen,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      // Row 2: Original Price and Save Percentage (only if discounted)
                                      if (displayCompareAtPrice >
                                          displayPrice) ...[
                                        const SizedBox(height: 3),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              "₹${displayCompareAtPrice.toStringAsFixed(0)}",
                                              style: const TextStyle(
                                                color: Colors.black54,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 5,
                                                      vertical: 1.5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFFFECEB,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: Colors.red.shade100,
                                                    width: 0.5,
                                                  ),
                                                ),
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    "SAVE ₹${(displayCompareAtPrice - displayPrice).toStringAsFixed(0)}",
                                                    style: TextStyle(
                                                      color:
                                                          Colors.red.shade800,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontSize: 8,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),

                                // Segmented Blinkit-Style quantity controls (Compacted)
                                if (isSelected)
                                  Container(
                                    width: 80,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: primaryGreen,
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryGreen.withOpacity(0.15),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1.5),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                          onTap: isSyncing
                                              ? null
                                              : () {
                                                  final qty = quantity > 1
                                                      ? quantity - 1
                                                      : 0;
                                                  _syncVariantWithCart(v, qty);
                                                },
                                          behavior: HitTestBehavior.opaque,
                                          child: Container(
                                            width: 25,
                                            height: double.infinity,
                                            alignment: Alignment.center,
                                            child: Icon(
                                              quantity == 1
                                                  ? CupertinoIcons.trash_fill
                                                  : Icons.remove_rounded,
                                              size: quantity == 1 ? 12 : 14,
                                              color: isSyncing
                                                  ? Colors.white54
                                                  : Colors.white,
                                            ),
                                          ),
                                        ),
                                        // Clickable number to trigger wholesale quantity input dialog
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: isSyncing
                                                ? null
                                                : () => _showQuantityDialog(
                                                    v.id,
                                                    quantity,
                                                  ),
                                            behavior: HitTestBehavior.opaque,
                                            child: Container(
                                              height: double.infinity,
                                              alignment: Alignment.center,
                                              child: isSyncing
                                                  ? const SizedBox(
                                                      width: 12,
                                                      height: 12,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 1.5,
                                                            color: Colors.white,
                                                          ),
                                                    )
                                                  : AnimatedSwitcher(
                                                      duration: const Duration(
                                                        milliseconds: 150,
                                                      ),
                                                      transitionBuilder:
                                                          (
                                                            child,
                                                            animation,
                                                          ) => ScaleTransition(
                                                            scale: animation,
                                                            child:
                                                                FadeTransition(
                                                                  opacity:
                                                                      animation,
                                                                  child: child,
                                                                ),
                                                          ),
                                                      child: Text(
                                                        quantity.toString(),
                                                        key: ValueKey<int>(
                                                          quantity,
                                                        ),
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          fontSize: 12.5,
                                                          color: Colors.white,
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                          decorationStyle:
                                                              TextDecorationStyle
                                                                  .solid,
                                                          decorationColor:
                                                              Colors.white70,
                                                          decorationThickness:
                                                              1.5,
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: isSyncing
                                              ? null
                                              : () => _syncVariantWithCart(
                                                  v,
                                                  quantity + 1,
                                                ),
                                          behavior: HitTestBehavior.opaque,
                                          child: Container(
                                            width: 25,
                                            height: double.infinity,
                                            alignment: Alignment.center,
                                            child: Icon(
                                              Icons.add_rounded,
                                              size: 14,
                                              color: isSyncing
                                                  ? Colors.white54
                                                  : Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  GestureDetector(
                                    onTap: isSyncing
                                        ? null
                                        : () => _syncVariantWithCart(v, 1),
                                    child: Container(
                                      width: 80,
                                      height: 32,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isSyncing
                                              ? Colors.grey.shade300
                                              : primaryGreen,
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryGreen.withOpacity(
                                              0.04,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1.5),
                                          ),
                                        ],
                                      ),
                                      child: isSyncing
                                          ? SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 1.5,
                                                color: primaryGreen,
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "ADD",
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w900,
                                                    color: primaryGreen,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                const SizedBox(width: 3),
                                                Icon(
                                                  Icons.add_rounded,
                                                  size: 13,
                                                  color: primaryGreen,
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          if (totalItems > 0) ...[
            const SizedBox(height: 12),
            _buildOrderSummaryCard(),
          ],
        ],
      ),
    );
  }

  ParsedSize _parseSize(String sizeStr) {
    if (sizeStr.isEmpty) return ParsedSize("", "");

    final regex = RegExp(r'^([^(]+)(?:\(([^)]+)\))?');
    final match = regex.firstMatch(sizeStr);

    if (match != null) {
      final packSize = match.group(1)!.trim();
      final config = match.group(2)?.trim() ?? "Single";
      return ParsedSize(packSize, config);
    }

    return ParsedSize(sizeStr, "Single");
  }

  String _getUpdatedConfigName(String config, int quantity) {
    if (quantity <= 1) return config;

    // Match numeric prefix followed by any remaining characters
    final regex = RegExp(r'^([\d.]+)(.*)$');
    final match = regex.firstMatch(config);

    if (match != null) {
      final numStr = match.group(1)!;
      final unitStr = match.group(2) ?? "";
      final double? baseVal = double.tryParse(numStr);
      if (baseVal != null) {
        final totalVal = baseVal * quantity;
        final formattedVal = totalVal % 1 == 0
            ? totalVal.toInt().toString()
            : totalVal.toStringAsFixed(1);
        return "$formattedVal$unitStr";
      }
    }
    return config;
  }

  void _syncVariantWithCart(Variant v, int newQty) {
    final cartService = Provider.of<CartService>(context, listen: false);

    if (newQty <= 0) {
      cartService.removeItem(v.id).catchError((e) {
        _showError("Failed to remove item");
      });
    } else {
      double unitPrice = v.price;
      final double totalVolume = v.packVolume * newQty;
      if (totalVolume > 50.0) {
        unitPrice = v.price50_plus > 0 ? v.price50_plus : v.price;
      } else if (totalVolume > 30.0) {
        unitPrice = v.price30_50 > 0 ? v.price30_50 : v.price;
      } else if (totalVolume >= 10.0) {
        unitPrice = v.price10_30 > 0 ? v.price10_30 : v.price;
      }

      final List<Map<String, dynamic>> itemsToAdd = [
        {
          'variantId': v.id,
          'quantity': newQty,
          'productName': _product.title,
          'productImage': _product.thumbnail,
          'technicalName': _product.technicalName ?? "",
          'variant': v.size,
          'price': unitPrice * v.packVolume,
        },
      ];

      cartService
          .addItems(
            productId: _product.id,
            items: itemsToAdd,
            sync: true,
            isReplace: true,
          )
          .catchError((e) {
            _showError("Failed to update cart: $e");
          });
    }
  }

  String? _getPerUnitLabel(String sizeStr, double price) {
    if (sizeStr.isEmpty) return null;

    final isKg =
        sizeStr.toLowerCase().contains('g') ||
        sizeStr.toLowerCase().contains('kg') ||
        sizeStr.toLowerCase().contains('k');
    final String unitLabel = isKg ? 'kg' : 'lit.';

    final formattedPrice = price % 1 == 0
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);

    return '₹$formattedPrice / $unitLabel';
  }

  void _showQuantityDialog(String variantId, int currentQty) {
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
              borderSide: BorderSide(color: primaryGreen, width: 1.5),
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
                final v = _product.variants.firstWhere(
                  (x) => x.id == variantId,
                );
                _syncVariantWithCart(v, val);
              }
              Navigator.pop(context);
            },
            child: Text(
              "UPDATE",
              style: TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black, fontSize: 15),
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
                style: const TextStyle(
                  color: Colors.black,
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
    if (_isLoading) {
      // Beautiful skeleton loader while fetching details
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 20,
              width: 140,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 14,
              width: 180,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    final details = _product.details;
    final List<Widget> specWidgets = [
      if (_product.brandName != null && _product.brandName!.isNotEmpty)
        _buildSpecRow("Brand", _product.brandName!, Icons.bookmark_outline),
      if (_product.vendor != null && _product.vendor!.isNotEmpty)
        _buildSpecRow("Vendor", _product.vendor!, Icons.storefront_outlined),
      if (_categoryName != null && _categoryName!.isNotEmpty)
        _buildSpecRow("Category", _categoryName!, Icons.category_outlined),
      if (details != null && details.specifications.isNotEmpty)
        ...details.specifications.entries
            .where((entry) {
              final lowKey = entry.key.toLowerCase();
              return !lowKey.contains('rating') &&
                  !lowKey.contains('review') &&
                  !lowKey.contains('star');
            })
            .map((entry) {
              final String key = _formatKey(entry.key);
              final String value = entry.value?.toString() ?? "";
              if (value.isEmpty) return const SizedBox.shrink();
              return _buildSpecRow(key, value, Icons.info_outline_rounded);
            })
            .toList(),
    ];

    final hasSpecs = specWidgets.isNotEmpty;
    final hasDescription = details != null && details.description.isNotEmpty;

    // If there is neither specs nor description, return nothing
    if (!hasSpecs && !hasDescription) return const SizedBox.shrink();

    // Case 1: Has both description and specs -> Show the sliding TabBar
    if (hasDescription && hasSpecs) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sliding TabBar
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: secondaryGreen.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _activeTab = 0);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _activeTab == 0
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: _activeTab == 0
                              ? Border.all(
                                  color: primaryGreen.withOpacity(0.08),
                                  width: 0.5,
                                )
                              : null,
                          boxShadow: _activeTab == 0
                              ? [
                                  BoxShadow(
                                    color: primaryGreen.withOpacity(0.12),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_rounded,
                              size: 15,
                              color: _activeTab == 0
                                  ? primaryGreen
                                  : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Details",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _activeTab == 0
                                    ? FontWeight.w900
                                    : FontWeight.bold,
                                color: _activeTab == 0
                                    ? primaryGreen
                                    : Colors.grey.shade600,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _activeTab = 1);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _activeTab == 1
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: _activeTab == 1
                              ? Border.all(
                                  color: primaryGreen.withOpacity(0.08),
                                  width: 0.5,
                                )
                              : null,
                          boxShadow: _activeTab == 1
                              ? [
                                  BoxShadow(
                                    color: primaryGreen.withOpacity(0.12),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fact_check_rounded,
                              size: 15,
                              color: _activeTab == 1
                                  ? primaryGreen
                                  : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Specifications",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _activeTab == 1
                                    ? FontWeight.w900
                                    : FontWeight.bold,
                                color: _activeTab == 1
                                    ? primaryGreen
                                    : Colors.grey.shade600,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab content with AnimatedSize + AnimatedSwitcher for ultra-smooth height & fade transition
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.03),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _activeTab == 0
                    ? Column(
                        key: const ValueKey<int>(0),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Product Description",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildCollapsibleDescription(details.description),
                          const SizedBox(height: 20),
                        ],
                      )
                    : _buildSpecsContainer(specWidgets, key: const ValueKey<int>(1)),
              ),
            ),
          ],
        ),
      );
    }

    // Case 2: Has ONLY description (no specs) -> Show description directly, no tabbar needed
    if (hasDescription) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Product Description",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            _buildCollapsibleDescription(details.description),
            const SizedBox(height: 20),
          ],
        ),
      );
    }

    // Case 3: Has ONLY specs (no description) -> Show specs directly, no tabbar needed
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Specifications",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          _buildSpecsContainer(specWidgets),
        ],
      ),
    );
  }

  Widget _buildCollapsibleDescription(String text) {
    const int maxCollapsedLines = 4;
    return LayoutBuilder(
      builder: (context, constraints) {
        final TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          maxLines: maxCollapsedLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final bool isOverflown = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Text(
                  text,
                  maxLines: _isDescriptionExpanded ? null : maxCollapsedLines,
                  overflow: _isDescriptionExpanded
                      ? TextOverflow.clip
                      : TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                if (isOverflown && !_isDescriptionExpanded)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.9),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (isOverflown) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isDescriptionExpanded = !_isDescriptionExpanded;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isDescriptionExpanded ? "Show Less" : "Show More",
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isDescriptionExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: primaryGreen,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSpecsContainer(List<Widget> specWidgets, {Key? key}) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children:
            specWidgets
                .expand(
                  (widget) => [
                    widget,
                    Divider(
                      height: 1,
                      thickness: 0.8,
                      color: Colors.grey.shade100,
                    ),
                  ],
                )
                .toList()
              ..removeLast(),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: primaryGreen),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    if (key.isEmpty) return "";
    final words = key.split(RegExp(r'[_-\s]+'));
    return words
        .map((w) {
          if (w.isEmpty) return "";
          return w[0].toUpperCase() + w.substring(1).toLowerCase();
        })
        .join(" ");
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
                label: totalItems > 0 ? "GO TO CART" : "ADD TO CART",
                onPressed: _handleAddToCart,
                isOutlined: true,
                color: buttonOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionBtn(
                label: "BUY NOW",
                onPressed: _handleBuyNow,
                color: buttonGreen,
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
    final cartService = Provider.of<CartService>(context, listen: false);
    final qty = cartService.getVariantQty(v.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuantityPickerSheet(
        initialValue: qty == 0 ? 1 : qty,
        onApply: (qty) => _syncVariantWithCart(v, qty),
      ),
    );
  }

  bool _isAddingToCart = false;

  void _handleAddToCart() {
    final cartService = Provider.of<CartService>(context, listen: false);
    final hasItems = _product.variants.any(
      (v) => cartService.getVariantQty(v.id) > 0,
    );

    if (!hasItems) {
      _showError("Please select a pack size");
      return;
    }

    // Give instant tactile feedback
    HapticFeedback.mediumImpact();

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

class ParsedSize {
  final String packSize;
  final String configuration;

  ParsedSize(this.packSize, this.configuration);
}
