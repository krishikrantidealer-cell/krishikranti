import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'dart:async';
import 'dart:ui';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:krishikranti/core/cart_service.dart';
import 'package:krishikranti/core/favorite_service.dart';
import 'package:krishikranti/screens/checkout_screen.dart';
import 'package:krishikranti/screens/cart_screen.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:krishikranti/features/products/data/models/product_model.dart';
import 'package:krishikranti/features/products/data/repositories/product_repository.dart';
import 'package:krishikranti/features/products/data/models/category_model.dart';
import 'package:krishikranti/core/utils/translatable_text.dart';
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
  late AppLocalizations l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context)!;
  }

  final Color primaryGreen = const Color(0xFF298E4D);
  final Color secondaryGreen = const Color(0xFFE8F5E9);
  final Color accentOrange = const Color(0xFFFA9527);
  final Color buttonGreen = const Color(0xFF298E4D);
  final Color buttonOrange = const Color(0xFFFA9527);
  final Color buttonRed = const Color(0xFFED4337);

  final FavoriteService _favoriteService = FavoriteService();
  final ProductRepository _productRepository = ProductRepository();

  late Product _product;
  bool _isLoading = true;
  late ScrollController _scrollController;
  final ValueNotifier<bool> _showStickyHeaderNotifier = ValueNotifier<bool>(
    false,
  );
  Variant? _selectedVariant;
  String? _selectedPackSize;
  int _activeTab = 0;
  bool _isDescriptionExpanded = false;
  final ValueNotifier<int> _currentImageIndexNotifier = ValueNotifier<int>(0);
  String? _categoryName;
  String? _unlockedTierLabel;
  bool _showSuccessAnimation = false;
  Timer? _celebrationTimer;
  LottieComposition? _successComposition;

  void _showUnlockCelebration(String tierLabel) {
    _celebrationTimer?.cancel();

    // Trigger dual strong haptic feedback sequence to accompany the celebration burst
    HapticFeedback.vibrate();
    Future.delayed(const Duration(milliseconds: 150), () {
      HapticFeedback.vibrate();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _unlockedTierLabel = tierLabel;
          _showSuccessAnimation = true;
        });
      }
    });

    _celebrationTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _showSuccessAnimation = false;
          _unlockedTierLabel = null;
        });
      }
    });
  }

  Widget _buildSuccessAnimationOverlay() {
    if (_successComposition == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: Lottie(
            composition: _successComposition,
            repeat: false,
            fit: BoxFit.contain,
            frameRate: FrameRate.max,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _product = widget.product;

    // Synchronously check if full details are cached in memory to bypass loading screens entirely
    final cachedProduct = _productRepository.getProductDetailFromCache(
      _product.id,
    );
    if (cachedProduct != null) {
      _product = cachedProduct;
    }

    _scrollController = ScrollController()..addListener(_onScroll);

    // Preload animation for zero-jank playback
    AssetLottie('assets/animations/CongratulationsLottie.json')
        .load()
        .then((composition) {
          if (mounted) {
            setState(() {
              _successComposition = composition;
            });
          }
        })
        .catchError((_) {});

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
      final combinedText =
          '${_product.title} ${_product.brandName ?? ""} ${_product.technicalName ?? ""}'
              .toLowerCase();
      if (combinedText.contains('herbicide')) {
        _categoryName = 'Herbicides';
      } else if (combinedText.contains('insecticide')) {
        _categoryName = 'Insecticides';
      } else if (combinedText.contains('fungicide')) {
        _categoryName = 'Fungicides';
      } else if (combinedText.contains('fertilizer')) {
        _categoryName = 'Fertilizers';
      } else if (combinedText.contains('pgr') ||
          combinedText.contains('growth')) {
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
    _showStickyHeaderNotifier.dispose();
    _currentImageIndexNotifier.dispose();
    _celebrationTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 400 && !_showStickyHeaderNotifier.value) {
      _showStickyHeaderNotifier.value = true;
    } else if (_scrollController.offset <= 400 &&
        _showStickyHeaderNotifier.value) {
      _showStickyHeaderNotifier.value = false;
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

      // Kick off silent background network synchronization to update the cache
      _performBackgroundSync();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _performBackgroundSync() {
    _productRepository
        .getProductDetail(_product.id, forceRefresh: true)
        .then((freshProduct) {
          if (mounted) {
            setState(() {
              _product = freshProduct;
              if (_product.variants.isNotEmpty) {
                _selectedVariant = _product.variants.firstWhere(
                  (v) => v.id == _selectedVariant?.id,
                  orElse: () => _product.variants.first,
                );
                _selectedPackSize = _parseSize(_selectedVariant!.size).packSize;
              }
            });
          }
        })
        .catchError((_) {});
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

  List<String> get _displayImages {
    if (_product.details != null &&
        _product.details!.originalImages.isNotEmpty) {
      return _product.details!.originalImages;
    }
    if (_product.images.isNotEmpty) {
      return _product.images;
    }
    return [_product.thumbnail];
  }

  void _openFullscreenGallery(int initialIndex) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (context, _, __) => _FullscreenImageGallery(
          images: _displayImages,
          initialIndex: initialIndex,
          productId: _product.id,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
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
      final qty = cartService.getVariantQty(v.id);
      if (qty > 0) {
        double unitPrice = v.price;
        final double totalVolume = v.packVolume * qty;
        if (totalVolume > 50.0) {
          unitPrice = v.price50_plus > 0 ? v.price50_plus : v.price;
        } else if (totalVolume > 30.0) {
          unitPrice = v.price30_50 > 0 ? v.price30_50 : v.price;
        } else if (totalVolume >= 10.0) {
          unitPrice = v.price10_30 > 0 ? v.price10_30 : v.price;
        }
        total += qty * (unitPrice * v.packVolume);
      }
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
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                _buildImageHero(context),
                SliverToBoxAdapter(
                  child: AnimationLimiter(
                    key: const ValueKey('product_anim_limiter'),
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
                          _buildConfigurationCard(),
                          _buildProductDescription(),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100), // Bottom padding for actions
                ),
              ],
            ),
            Consumer<CartService>(
              builder: (context, cart, child) => _buildFloatingActionBar(),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _showStickyHeaderNotifier,
              builder: (context, showSticky, child) {
                if (showSticky) {
                  return Consumer<CartService>(
                    builder: (context, cart, child) => _buildStickyHeader(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            if (_showSuccessAnimation) _buildSuccessAnimationOverlay(),
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
                  ? buttonRed
                  : Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 80, bottom: 40),
                child: GestureDetector(
                  onTap: () => _openFullscreenGallery(0),
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
              ),
              if (_product.details?.originalImages.isNotEmpty ?? false) ...[
                CarouselSlider(
                  options: CarouselOptions(
                    height: 420,
                    viewportFraction: 1.0,
                    enableInfiniteScroll:
                        _product.details!.originalImages.length > 1,
                    onPageChanged: (index, reason) {
                      _currentImageIndexNotifier.value = index;
                    },
                  ),
                  items: _product.details!.originalImages.asMap().entries.map((
                    entry,
                  ) {
                    final index = entry.key;
                    final url = entry.value;
                    return GestureDetector(
                      onTap: () => _openFullscreenGallery(index),
                      child: Container(
                        padding: const EdgeInsets.only(top: 80, bottom: 40),
                        child: Hero(
                          tag: 'product_image_${_product.id}_$index',
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_product.details!.originalImages.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: ValueListenableBuilder<int>(
                      valueListenable: _currentImageIndexNotifier,
                      builder: (context, currentIndex, child) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _product.details!.originalImages.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: currentIndex == index ? 14 : 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: currentIndex == index
                                    ? primaryGreen
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ],
          ),
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
          TranslatableText(
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
            TranslatableText(
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
                  child: TranslatableText(
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _product.averageRating > 0
                      ? Colors.orange.shade50
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _product.averageRating > 0
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: _product.averageRating > 0
                          ? Colors.orange
                          : Colors.grey.shade400,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _product.averageRating > 0
                          ? _product.averageRating.toString()
                          : "0.0",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _product.averageRating > 0
                            ? Colors.orange
                            : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _product.averageRating > 0
                          ? " (${_product.numReviews})"
                          : " (0 reviews)",
                      style: TextStyle(
                        color: _product.averageRating > 0
                            ? Colors.orange.shade800
                            : Colors.grey.shade500,
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
            _buildTrustFeature(Icons.verified_user_rounded, l10n.expertChoice),
            _buildTrustDivider(),
            _buildTrustFeature(Icons.bolt_rounded, l10n.fastActing),
            _buildTrustDivider(),
            _buildTrustFeature(
              Icons.security_rounded,
              l10n.hundredPercentOriginal,
            ),
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

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.selectPackagingQuantity,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            ..._product.variants.map((v) {
              return Selector<CartService, String>(
                selector: (context, cart) =>
                    '${cart.getVariantQty(v.id)}_${cart.syncingVariantIds.contains(v.id)}',
                builder: (context, stateStr, child) {
                  final parts = stateStr.split('_');
                  final int quantity = int.parse(parts[0]);
                  final bool isSyncing = parts[1] == 'true';
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

                  final String? perUnitLabel = _getPerUnitLabel(
                    v.size,
                    unitPrice,
                  );
                  final parsedSize = _parseSize(v.size);

                  final bool isKg =
                      v.size.toLowerCase().contains('g') ||
                      v.size.toLowerCase().contains('kg') ||
                      v.size.toLowerCase().contains('k');
                  final String unitSuffix = isKg ? "Kg" : "Litre";
                  final String formattedVol = v.packVolume % 1 == 0
                      ? v.packVolume.toInt().toString()
                      : v.packVolume.toStringAsFixed(
                          v.packVolume < 1
                              ? (v.packVolume * 100 % 10 == 0 ? 1 : 2)
                              : 1,
                        );
                  final String configName =
                      parsedSize.configuration.toLowerCase() == "single"
                      ? "$formattedVol $unitSuffix"
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
                  final String unit = match != null
                      ? (match.group(2) ?? "")
                      : "";

                  return Padding(
                    key: ValueKey(v.id),
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
                                  color: isSelected
                                      ? null
                                      : Colors.grey.shade50,
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            val,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontFamily: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.fontFamily,
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
                                              fontFamily: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.fontFamily,
                                              fontWeight: FontWeight.w900,
                                              color: isSelected
                                                  ? primaryGreen.withOpacity(
                                                      0.8,
                                                    )
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    displayConfigName,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 13.5,
                                                      fontFamily:
                                                          Theme.of(context)
                                                              .textTheme
                                                              .titleLarge
                                                              ?.fontFamily,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            // Row 1: Selling Price and Per-Unit label
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.baseline,
                                              textBaseline:
                                                  TextBaseline.alphabetic,
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
                                                      fontWeight:
                                                          FontWeight.w900,
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
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                        border: Border.all(
                                                          color: Colors
                                                              .red
                                                              .shade100,
                                                          width: 0.5,
                                                        ),
                                                      ),
                                                      child: FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        child: Text(
                                                          l10n.saveAmount(
                                                            (displayCompareAtPrice -
                                                                    displayPrice)
                                                                .toStringAsFixed(
                                                                  0,
                                                                ),
                                                          ),
                                                          style: TextStyle(
                                                            color: Colors
                                                                .red
                                                                .shade800,
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
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: primaryGreen.withOpacity(
                                                  0.15,
                                                ),
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
                                                        _syncVariantWithCart(
                                                          v,
                                                          qty,
                                                        );
                                                      },
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                child: Container(
                                                  width: 25,
                                                  height: double.infinity,
                                                  alignment: Alignment.center,
                                                  child: Icon(
                                                    quantity == 1
                                                        ? CupertinoIcons
                                                              .trash_fill
                                                        : Icons.remove_rounded,
                                                    size: quantity == 1
                                                        ? 12
                                                        : 14,
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
                                                      : () =>
                                                            _showQuantityDialog(
                                                              v.id,
                                                              quantity,
                                                            ),
                                                  behavior:
                                                      HitTestBehavior.opaque,
                                                  child: Container(
                                                    height: double.infinity,
                                                    alignment: Alignment.center,
                                                    child: AnimatedSwitcher(
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
                                                    : () =>
                                                          _syncVariantWithCart(
                                                            v,
                                                            quantity + 1,
                                                          ),
                                                behavior:
                                                    HitTestBehavior.opaque,
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
                                              : () =>
                                                    _syncVariantWithCart(v, 1),
                                          child: Container(
                                            width: 80,
                                            height: 32,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: isSyncing
                                                    ? Colors.grey.shade300
                                                    : primaryGreen,
                                                width: 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: primaryGreen
                                                      .withOpacity(0.04),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 1.5),
                                                ),
                                              ],
                                            ),
                                            child: isSyncing
                                                ? SizedBox(
                                                    width: 12,
                                                    height: 12,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 1.5,
                                                          color: primaryGreen,
                                                        ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        l10n.addLabel,
                                                        style: TextStyle(
                                                          fontSize: 11.5,
                                                          fontWeight:
                                                              FontWeight.w900,
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
                        _buildTierMilestonesRow(v, quantity, isKg),
                      ],
                    ),
                  );
                },
              );
            }).toList(),
          ],
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          l10n.adjustQuantity,
          style: const TextStyle(
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
            hintText: l10n.enterValueHint,
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
              l10n.cancelLabel,
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
              l10n.updateLabel2,
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
            Text(
              l10n.totalItems(totalItems),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              l10n.grandTotalLabel(grandTotal.toStringAsFixed(0)),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w900,
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
                              l10n.details,
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
                              l10n.specifications,
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
                          Text(
                            l10n.productDescription,
                            style: const TextStyle(
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
                    : _buildSpecsContainer(
                        specWidgets,
                        key: const ValueKey<int>(1),
                      ),
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
            Text(
              l10n.productDescription,
              style: const TextStyle(
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
          Text(
            l10n.specifications,
            style: const TextStyle(
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

  Widget _buildCollapsibleDescription(String rawText) {
    const int maxCollapsedLines = 4;

    // Convert HTML blocks to newlines
    String text = rawText
        .replaceAll(RegExp(r"<\/?p[^>]*>", caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r"<br\s*\/?>", caseSensitive: false), '\n')
        .replaceAll(RegExp(r"<li>", caseSensitive: false), '\n• ')
        .replaceAll(RegExp(r"<\/?div[^>]*>", caseSensitive: false), '\n\n')
        .replaceAll('&nbsp;', ' ');

    // Strip remaining HTML tags
    text = text.replaceAll(RegExp(r"<[^>]*>", multiLine: true), '').trim();

    // Normalize excessive newlines
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

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
                TranslatableText(
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
                      _isDescriptionExpanded ? l10n.showLess : l10n.showMore,
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
            child: TranslatableText(
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
            child: TranslatableText(
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
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    return Positioned(
      bottom: bottomPadding > 0 ? bottomPadding * 0.4 : 10,
      left: 16,
      right: 16,
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionBtn(
                        label: l10n.goToCart,
                        onPressed: _handleAddToCart,
                        isOutlined: false,
                        color: buttonOrange,
                        icon: CupertinoIcons.cart_fill,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionBtn(
                        label: l10n.buyNow,
                        onPressed: _handleBuyNow,
                        color: buttonGreen,
                        icon: CupertinoIcons.bolt_fill,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
                      TranslatableText(
                        _product.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        l10n.grandTotalLabel(grandTotal.toStringAsFixed(0)),
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
      final targetVariant =
          _selectedVariant ??
          (_product.variants.isNotEmpty ? _product.variants.first : null);
      if (targetVariant != null) {
        _syncVariantWithCart(targetVariant, 1);
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartScreen()),
        );
      } else {
        _showError(l10n.pleaseSelectPackSize);
      }
      return;
    }

    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  void _handleBuyNow() {
    final cartService = Provider.of<CartService>(context, listen: false);
    final hasItems = _product.variants.any(
      (v) => cartService.getVariantQty(v.id) > 0,
    );

    if (!hasItems) {
      final targetVariant =
          _selectedVariant ??
          (_product.variants.isNotEmpty ? _product.variants.first : null);
      if (targetVariant != null) {
        _syncVariantWithCart(targetVariant, 1);
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CheckoutScreen()),
        );
      } else {
        _showError(l10n.pleaseSelectPackSize);
      }
      return;
    }

    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: buttonRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<TierInfo> _getValidTiers(Variant v, bool isKg) {
    final List<TierInfo> list = [];
    final String suffix = isKg ? "Kg" : "L";

    if (v.price10_30 > 0) {
      list.add(
        TierInfo(
          label: "10-30$suffix Tier",
          threshold: 10.0,
          price: v.price10_30,
          key: "10_30",
        ),
      );
    }
    if (v.price30_50 > 0) {
      list.add(
        TierInfo(
          label: "30-50$suffix Tier",
          threshold: 30.0,
          price: v.price30_50,
          key: "30_50",
        ),
      );
    }
    if (v.price50_plus > 0) {
      list.add(
        TierInfo(
          label: "50$suffix+ Tier",
          threshold: 50.0,
          price: v.price50_plus,
          key: "50_plus",
        ),
      );
    }
    return list;
  }

  Widget _buildTierMilestonesRow(Variant v, int quantity, bool isKg) {
    final double totalVolume = v.packVolume * quantity;
    final List<TierInfo> validTiers = _getValidTiers(v, isKg);

    if (validTiers.isEmpty || quantity <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Wholesale Tier Pricing",
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey.shade700,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              if (quantity > 0) ...[
                Text(
                  "Current Volume: ${(v.packVolume * quantity) % 1 == 0 ? (v.packVolume * quantity).toInt() : (v.packVolume * quantity).toStringAsFixed(1)}${isKg ? 'Kg' : 'L'}",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: validTiers.asMap().entries.map((entry) {
              final int index = entry.key;
              final t = entry.value;

              bool isTierUnlocked = false;
              if (t.key == "10_30") {
                isTierUnlocked = totalVolume >= 10.0;
              } else if (t.key == "30_50") {
                isTierUnlocked = totalVolume > 30.0;
              } else if (t.key == "50_plus") {
                isTierUnlocked = totalVolume > 50.0;
              }

              // Resolve the highest unlocked tier as the currently active tier
              String activeTierKey = "";
              if (totalVolume > 50.0 && v.price50_plus > 0) {
                activeTierKey = "50_plus";
              } else if (totalVolume > 30.0 && v.price30_50 > 0) {
                activeTierKey = "30_50";
              } else if (totalVolume >= 10.0 && v.price10_30 > 0) {
                activeTierKey = "10_30";
              }

              final bool isActiveTier = (t.key == activeTierKey);

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0.0 : 8.0),
                  child: TierMilestoneCard(
                    key: ValueKey(t.key),
                    label: t.label,
                    threshold: t.threshold,
                    price: t.price,
                    isUnlocked: isTierUnlocked,
                    isActive: isActiveTier,
                    isKg: isKg,
                    variant: v,
                    primaryGreen: primaryGreen,
                    secondaryGreen: secondaryGreen,
                    onUnlocked: () {
                      _showUnlockCelebration(t.label);
                    },
                    onTap: () {
                      if (isTierUnlocked) {
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "You have unlocked ${t.label}! Enjoying ₹${t.price.toStringAsFixed(0)}/${isKg ? 'kg' : 'lit.'} pricing. 🎉",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: primaryGreen,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } else {
                        _showUnlockTierSheet(v, t, quantity, isKg);
                      }
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  int getRequiredQtyForTier(Variant v, String tierKey) {
    int qty = 1;
    while (true) {
      final double vol = v.packVolume * qty;
      bool unlocked = false;
      if (tierKey == "10_30") {
        unlocked = vol >= 10.0;
      } else if (tierKey == "30_50") {
        unlocked = vol > 30.0;
      } else if (tierKey == "50_plus") {
        unlocked = vol > 50.0;
      }
      if (unlocked) {
        return qty;
      }
      qty++;
      if (qty > 10000) break;
    }
    return qty;
  }

  double getUnitPriceForQty(Variant v, int qty) {
    double unitPrice = v.price;
    if (qty > 0) {
      final double totalVolume = v.packVolume * qty;
      if (totalVolume > 50.0) {
        unitPrice = v.price50_plus > 0 ? v.price50_plus : v.price;
      } else if (totalVolume > 30.0) {
        unitPrice = v.price30_50 > 0 ? v.price30_50 : v.price;
      } else if (totalVolume >= 10.0) {
        unitPrice = v.price10_30 > 0 ? v.price10_30 : v.price;
      }
    }
    return unitPrice;
  }

  void _showUnlockTierSheet(Variant v, TierInfo t, int currentQty, bool isKg) {
    final int requiredQty = getRequiredQtyForTier(v, t.key);
    final int diffQty = requiredQty - currentQty;

    final double currentUnitPrice = getUnitPriceForQty(v, currentQty);
    final double targetUnitPrice = t.price;
    final double basePrice = v.price;

    final String unitLabel = isKg ? 'kg' : 'lit.';
    final double currentVol = v.packVolume * currentQty;
    final double targetVol = v.packVolume * requiredQty;

    final double regularCostForRequired =
        requiredQty * (basePrice * v.packVolume);
    final double discountedCostForRequired =
        requiredQty * (targetUnitPrice * v.packVolume);
    final double savings = regularCostForRequired - discountedCostForRequired;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            24 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_open_rounded,
                      color: primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Unlock ${t.label} Pricing!",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Get wholesale rates on bulk volume",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [secondaryGreen.withOpacity(0.5), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryGreen.withOpacity(0.15)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Regular Price",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "₹${currentUnitPrice.toStringAsFixed(0)} / $unitLabel",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: primaryGreen,
                          size: 20,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: primaryGreen,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "WHOLESALE RATE",
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "₹${targetUnitPrice.toStringAsFixed(0)} / $unitLabel",
                              style: TextStyle(
                                fontSize: 20,
                                color: primaryGreen,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (savings > 0) ...[
                      const Divider(height: 24, thickness: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            color: accentOrange,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Total Bulk Savings: ₹${savings.toStringAsFixed(0)}!",
                            style: TextStyle(
                              fontSize: 13,
                              color: accentOrange,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Required Volume Progression",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double fillPercent = (currentVol / t.threshold)
                            .clamp(0.0, 1.0);
                        return Container(
                          width: constraints.maxWidth * fillPercent,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryGreen.withOpacity(0.5),
                                primaryGreen,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Current: ${currentVol.toStringAsFixed(1)} $unitLabel ($currentQty packs)",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "Target: ${t.threshold.toStringAsFixed(1)} $unitLabel ($requiredQty packs)",
                    style: TextStyle(
                      fontSize: 11,
                      color: primaryGreen,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200, width: 0.5),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.orange.shade800,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Adding $diffQty more packs of this size unlocks ₹${(targetUnitPrice - currentUnitPrice).abs().toStringAsFixed(0)} discount per $unitLabel on ALL units!",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "KEEP CURRENT",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _syncVariantWithCart(v, requiredQty);
                        HapticFeedback.mediumImpact();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                        shadowColor: primaryGreen.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "ADD $diffQty & SAVE",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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

class _ActionBtn extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isOutlined;
  final Color color;
  final bool small;
  final IconData? icon;
  const _ActionBtn({
    required this.label,
    required this.onPressed,
    this.isOutlined = false,
    required this.color,
    this.small = false,
    this.icon,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.animateTo(0.94);
  }

  void _onTapUp(TapUpDetails details) {
    _controller.animateTo(1.0);
  }

  void _onTapCancel() {
    _controller.animateTo(1.0);
  }

  @override
  Widget build(BuildContext context) {
    final double buttonHeight = widget.small ? 38 : 52;
    final double buttonRadius = widget.small ? 19 : 26;
    final Color contentColor = widget.isOutlined ? widget.color : Colors.white;

    final BoxDecoration decoration = widget.isOutlined
        ? BoxDecoration(
            color: Colors.white,
            border: Border.all(color: widget.color, width: 2),
            borderRadius: BorderRadius.circular(buttonRadius),
          )
        : BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(buttonRadius),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          );

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          height: buttonHeight,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            decoration: decoration,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 18),
                      child: TweenAnimationBuilder<Color?>(
                        duration: const Duration(milliseconds: 250),
                        tween: ColorTween(
                          begin: contentColor,
                          end: contentColor,
                        ),
                        builder: (context, color, child) {
                          return Icon(
                            widget.icon,
                            size: widget.small ? 14 : 18,
                            color: color,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Padding(
                    padding: EdgeInsets.only(
                      left: widget.icon == null ? 20 : 0,
                      right: 20,
                    ),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      style: TextStyle(
                        color: contentColor,
                        fontWeight: FontWeight.w900,
                        fontSize: widget.small ? 11.5 : 14,
                        letterSpacing: 0.8,
                      ),
                      child: Text(widget.label, maxLines: 1),
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
                      color: Color(0xFF298E4D),
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
                  backgroundColor: const Color(0xFF298E4D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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

class TierInfo {
  final String label;
  final double threshold;
  final double price;
  final String key;

  TierInfo({
    required this.label,
    required this.threshold,
    required this.price,
    required this.key,
  });
}

class TierMilestoneCard extends StatefulWidget {
  final String label;
  final double threshold;
  final double price;
  final bool isUnlocked;
  final bool isActive;
  final bool isKg;
  final Variant variant;
  final Color primaryGreen;
  final Color secondaryGreen;

  final VoidCallback? onUnlocked;
  final VoidCallback? onTap;

  const TierMilestoneCard({
    Key? key,
    required this.label,
    required this.threshold,
    required this.price,
    required this.isUnlocked,
    this.isActive = false,
    required this.isKg,
    required this.variant,
    required this.primaryGreen,
    required this.secondaryGreen,
    this.onUnlocked,
    this.onTap,
  }) : super(key: key);

  @override
  _TierMilestoneCardState createState() => _TierMilestoneCardState();
}

class _TierMilestoneCardState extends State<TierMilestoneCard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.15,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40.0,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 1.15,
          end: 0.95,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30.0,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 0.95,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30.0,
      ),
    ]).animate(_controller);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 0.0, end: 6.0),
            weight: 15,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 6.0, end: -6.0),
            weight: 20,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: -6.0, end: 4.0),
            weight: 15,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 4.0, end: -4.0),
            weight: 15,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: -4.0, end: 2.0),
            weight: 15,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 2.0, end: 0.0),
            weight: 20,
          ),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );

    if (widget.isUnlocked) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant TierMilestoneCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isUnlocked && !oldWidget.isUnlocked) {
      _controller.forward(from: 0.0);
      if (widget.onUnlocked != null) {
        widget.onUnlocked!();
      }
    } else if (!widget.isUnlocked && oldWidget.isUnlocked) {
      _controller.reverse(from: 1.0);
    } else if (widget.isUnlocked) {
      _controller.value = 1.0;
    } else {
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String unitLabel = widget.isKg ? 'kg' : 'lit.';
    final formattedPrice = widget.price % 1 == 0
        ? widget.price.toStringAsFixed(0)
        : widget.price.toStringAsFixed(2);
    final String perUnitStr = "₹$formattedPrice/$unitLabel";

    return GestureDetector(
      onTap: () {
        if (!widget.isUnlocked) {
          _shakeController.forward(from: 0.0);
          HapticFeedback.vibrate();
        }
        if (widget.onTap != null) {
          widget.onTap!();
        }
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_controller, _shakeAnimation]),
        builder: (context, child) {
          final double animValue = _controller.value;

          final Color backgroundColor = Color.lerp(
            Colors.grey.shade100,
            widget.secondaryGreen,
            animValue,
          )!;

          final Color borderColor = Color.lerp(
            Colors.grey.shade300,
            widget.primaryGreen,
            animValue,
          )!;

          final Color textColor = Color.lerp(
            Colors.grey.shade700,
            widget.primaryGreen,
            animValue,
          )!;

          final Color subtextColor = Color.lerp(
            Colors.grey.shade500,
            widget.primaryGreen.withOpacity(0.85),
            animValue,
          )!;

          final double shadowOpacity = animValue * 0.15;

          final double cardOpacity = !widget.isUnlocked
              ? 1.0
              : widget.isActive
              ? 1.0
              : 0.55;

          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Opacity(
                opacity: cardOpacity,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: borderColor,
                      width: animValue > 0.5 ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.primaryGreen.withOpacity(shadowOpacity),
                        blurRadius: 6 * animValue,
                        spreadRadius: 1 * animValue,
                        offset: Offset(0, 2 * animValue),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: (1.0 - animValue).clamp(0.0, 1.0),
                            child: Icon(
                              Icons.lock_outline_rounded,
                              color: Colors.grey.shade500,
                              size: 13,
                            ),
                          ),
                          Opacity(
                            opacity: animValue.clamp(0.0, 1.0),
                            child: Icon(
                              Icons.verified_rounded,
                              color: widget.primaryGreen,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                widget.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 1),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                perUnitStr,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: subtextColor,
                                  decoration:
                                      (widget.isUnlocked && !widget.isActive)
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
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
            ),
          );
        },
      ),
    );
  }
}

class _FullscreenImageGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String productId;

  const _FullscreenImageGallery({
    required this.images,
    required this.initialIndex,
    required this.productId,
  });

  @override
  State<_FullscreenImageGallery> createState() =>
      _FullscreenImageGalleryState();
}

class _FullscreenImageGalleryState extends State<_FullscreenImageGallery> {
  late PageController _pageController;
  late int _currentIndex;
  double _currentScale = 1.0;

  double _dragOffset = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  double get _dragScale =>
      (1.0 - (_dragOffset.abs() / 1500.0)).clamp(0.75, 1.0);
  double get _dragOpacity =>
      (1.0 - (_dragOffset.abs() / 400.0)).clamp(0.0, 1.0);

  void _onVerticalDragStart(DragStartDetails details) {
    if (_currentScale <= 1.01) {
      _isDragging = true;
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    setState(() {
      _dragOffset += details.primaryDelta ?? 0.0;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    if (_dragOffset.abs() > 100.0) {
      Navigator.pop(context);
    } else {
      setState(() {
        _dragOffset = 0.0;
        _isDragging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double opacity = 0.95 * _dragOpacity;
    final double blurSigma = 10.0 * _dragOpacity;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Color overlay with dynamic opacity
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(opacity)),
          ),

          // Background Blur with dynamic blur sigma
          if (blurSigma > 0.1)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: const SizedBox.shrink(),
              ),
            ),

          // Main Gallery PageView wrapped in vertical drag gesture detector and smooth scale/translate transform
          Positioned.fill(
            child: GestureDetector(
              onVerticalDragStart: _onVerticalDragStart,
              onVerticalDragUpdate: _onVerticalDragUpdate,
              onVerticalDragEnd: _onVerticalDragEnd,
              behavior: HitTestBehavior.opaque,
              child: Transform.translate(
                offset: Offset(0, _dragOffset),
                child: Transform.scale(
                  scale: _dragScale,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.images.length,
                    physics: _currentScale > 1.01 || _isDragging
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                        _currentScale = 1.0; // Reset scale on page change
                      });
                    },
                    itemBuilder: (context, index) {
                      final String url = widget.images[index];
                      final String heroTag = widget.images.length == 1
                          ? 'product_${widget.productId}'
                          : 'product_image_${widget.productId}_$index';

                      return Hero(
                        tag: heroTag,
                        child: _FullscreenImageItem(
                          imageUrl: url,
                          onScaleChanged: (scale) {
                            if (scale != _currentScale) {
                              setState(() {
                                _currentScale = scale;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Header Controls: Close button (fades out as you drag)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Opacity(
              opacity: _dragOpacity,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white12, width: 1),
                ),
                child: IconButton(
                  icon: const Icon(
                    CupertinoIcons.xmark,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // Bottom Index Indicator (fades out as you drag)
          if (widget.images.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: _dragOpacity,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12, width: 1),
                    ),
                    child: Text(
                      "${_currentIndex + 1} / ${widget.images.length}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FullscreenImageItem extends StatefulWidget {
  final String imageUrl;
  final ValueChanged<double> onScaleChanged;

  const _FullscreenImageItem({
    required this.imageUrl,
    required this.onScaleChanged,
  });

  @override
  State<_FullscreenImageItem> createState() => _FullscreenImageItemState();
}

class _FullscreenImageItemState extends State<_FullscreenImageItem>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  TapDownDetails? _doubleTapDetails;

  late AnimationController _animationController;
  Animation<Matrix4>? _zoomAnimation;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final Matrix4 startMatrix = _transformationController.value;
    final Matrix4 endMatrix;

    if (startMatrix != Matrix4.identity()) {
      // Zoom out to normal
      endMatrix = Matrix4.identity();
    } else {
      // Zoom in to double tap location
      final position = _doubleTapDetails!.localPosition;
      final double scale = 2.5;
      final x = -position.dx * (scale - 1);
      final y = -position.dy * (scale - 1);

      endMatrix = Matrix4.identity()
        ..translate(x, y)
        ..scale(scale);
    }

    _zoomAnimation = Matrix4Tween(begin: startMatrix, end: endMatrix).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastOutSlowIn,
      ),
    );

    _animationController.addListener(_onZoomAnimationUpdate);
    _animationController.forward(from: 0.0).then((_) {
      _animationController.removeListener(_onZoomAnimationUpdate);
    });
  }

  void _onZoomAnimationUpdate() {
    if (_zoomAnimation != null) {
      _transformationController.value = _zoomAnimation!.value;
      widget.onScaleChanged(
        _transformationController.value.getMaxScaleOnAxis(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapDetails = details,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1.0,
        maxScale: 4.0,
        onInteractionUpdate: (details) {
          final double currentScale = _transformationController.value
              .getMaxScaleOnAxis();
          widget.onScaleChanged(currentScale);
        },
        onInteractionEnd: (details) {
          final double currentScale = _transformationController.value
              .getMaxScaleOnAxis();
          widget.onScaleChanged(currentScale);
        },
        child: Center(
          child: CachedNetworkImage(
            imageUrl: widget.imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CupertinoActivityIndicator(color: Colors.white),
            ),
            errorWidget: (context, url, error) => const Icon(
              Icons.broken_image_rounded,
              color: Colors.white54,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}
