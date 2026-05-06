import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/core/favorite_service.dart';
import 'package:krishikranti/screens/product_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:krishikranti/features/products/data/models/product_model.dart';
import 'package:krishikranti/features/products/data/repositories/product_repository.dart';

import 'package:krishikranti/features/products/data/models/category_model.dart';
import 'package:krishikranti/widgets/progressive_image.dart';
import 'package:krishikranti/widgets/animated_heart.dart';

class ProductListScreen extends StatefulWidget {
  final String category;
  final String? categoryId;
  final Category? categoryData;
  final String? collection;
  final bool isCollection;
  final List<Product>? initialProducts;

  const ProductListScreen({
    super.key,
    required this.category,
    this.categoryId,
    this.categoryData,
    this.collection,
    this.isCollection = false,
    this.initialProducts,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  int _selectedMenuIndex = 0;
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  final FavoriteService _favoriteService = FavoriteService();
  final ProductRepository _productRepository = ProductRepository();
  final ScrollController _scrollController = ScrollController();

  List<Product> _products = [];
  bool _isLoading = true;
  String? _nextCursor;
  bool _isLoadingMore = false;
  String? _errorMessage;
  bool _isPopping = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _subCategories = widget.categoryData?.subCategories ?? [];

    if (widget.initialProducts != null && widget.initialProducts!.isNotEmpty) {
      _products = widget.initialProducts!;
      _isLoading = false;
    }

    _fetchProducts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _nextCursor != null) {
        _loadMoreProducts();
      }
    }
  }

  Future<void> _fetchProducts({bool forceRefresh = false}) async {
    if (!mounted) return;

    if (_products.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      String? subId;
      if (_selectedMenuIndex > 0 &&
          _selectedMenuIndex <= _subCategories.length) {
        subId = _subCategories[_selectedMenuIndex - 1].id;
      }

      final result = await _productRepository.getProducts(
        categoryId: widget.categoryId,
        subCategoryId: subId,
        collection: widget.collection,
        limit: 20,
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          _products = result['products'];
          _nextCursor = result['nextCursor'];
          _isLoading = false;
        });
      }

      if (result['isFromCache'] == true) {
        final freshResult = await _productRepository.getProducts(
          categoryId: widget.categoryId,
          subCategoryId: subId,
          collection: widget.collection,
          limit: 20,
          forceRefresh: true,
        );

        if (mounted && freshResult['isFromCache'] == false) {
          setState(() {
            _products = freshResult['products'];
            _nextCursor = freshResult['nextCursor'];
          });
        }
      }
    } catch (e) {
      if (mounted && _products.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || _nextCursor == null) return;

    setState(() => _isLoadingMore = true);

    try {
      String? subId;
      if (_selectedMenuIndex > 0 &&
          _selectedMenuIndex <= _subCategories.length) {
        subId = _subCategories[_selectedMenuIndex - 1].id;
      }

      final result = await _productRepository.getProducts(
        categoryId: widget.categoryId,
        subCategoryId: subId,
        collection: widget.collection,
        cursor: _nextCursor,
        limit: 20,
      );
      if (mounted) {
        setState(() {
          _products.addAll(result['products'] as List<Product>);
          _nextCursor = result['nextCursor'];
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  List<String> get _menuItems {
    return ['All', ..._subCategories.map((s) => s.name)];
  }

  List<SubCategory> _subCategories = [];

  List<Product> get _filteredProducts {
    List<Product> items = _products;

    if (_searchQuery.isNotEmpty) {
      items = items
          .where(
            (item) =>
                item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (item.technicalName?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    }

    return items;
  }

  void _toggleFavorite(Product product) {
    HapticFeedback.mediumImpact();
    _favoriteService.toggleFavorite(
      FavoriteProduct(
        id: product.id,
        name: product.title,
        category: widget.category,
        price: product.price.toString(),
        imageUrl: product.thumbnail,
        weight: product.variants.isNotEmpty
            ? product.variants.first.size
            : "Standard",
      ),
    );
  }

  IconData _getIconForCategory(String name) {
    switch (name.toLowerCase()) {
      case 'insecticides':
        return Icons.bug_report_rounded;
      case 'fungicides':
        return Icons.science_rounded;
      case 'pgrs':
        return Icons.grass_rounded;
      case 'fertilizers':
        return Icons.eco_rounded;
      case 'herbicides':
        return Icons.agriculture_rounded;
      case 'bio-products':
        return Icons.psychology_alt_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = _filteredProducts;
    final l10n = AppLocalizations.of(context)!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          top: false,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Ultra-Clean Minimalist Header
              SliverAppBar(
                pinned: true,
                floating: true,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                elevation: 0,
                centerTitle: true,
                leadingWidth: 56,
                title: _isSearching
                    ? CupertinoSearchTextField(
                        controller: _searchController,
                        placeholder: l10n.searchProducts,
                        backgroundColor: Colors.grey.shade100,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        onSuffixTap: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = "";
                            _isSearching = false;
                          });
                        },
                      )
                    : Text(
                        widget.category,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                leading: IconButton(
                  icon: const Icon(
                    CupertinoIcons.back,
                    color: Colors.black,
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() => _isPopping = true);
                    Navigator.pop(context);
                  },
                ),
                actions: [
                  if (!_isSearching)
                    IconButton(
                      icon: const Icon(
                        CupertinoIcons.search,
                        color: Colors.black,
                        size: 22,
                      ),
                      onPressed: () => setState(() => _isSearching = true),
                    ),
                  const SizedBox(width: 4),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(color: Colors.grey.shade100, height: 1),
                ),
              ),

              // Professional Sticky Filter Header
              if (!widget.isCollection)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyFilterDelegate(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade100,
                            width: 1,
                          ),
                        ),
                      ),
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: _menuItems.length,
                            itemBuilder: (context, index) {
                              final isSelected = _selectedMenuIndex == index;
                              return TweenAnimationBuilder<double>(
                                duration: Duration(
                                  milliseconds: 300 + (index * 50),
                                ),
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(20 * (1 - value), 0),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      if (_selectedMenuIndex != index) {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _selectedMenuIndex = index;
                                          _products = [];
                                        });
                                        _fetchProducts();
                                      }
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                        border: Border.all(
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : Colors.grey.shade200,
                                          width: 1.2,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: theme
                                                      .colorScheme
                                                      .primary
                                                      .withValues(alpha: 0.25),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ]
                                            : [],
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        _menuItems[index],
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey.shade700,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          fontSize: 11,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Product Grid (High Density)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: _isLoading
                    ? _buildSliverShimmerGrid()
                    : _errorMessage != null
                    ? SliverToBoxAdapter(child: _buildErrorWidget())
                    : products.isEmpty
                    ? SliverToBoxAdapter(child: _buildEmptyWidget())
                    : ListenableBuilder(
                        listenable: _favoriteService,
                        builder: (context, child) {
                          return SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisExtent: 245,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index >= products.length) {
                                  return const ShimmerCard();
                                }
                                final product = products[index];
                                return RepaintBoundary(
                                  child: ProductCard(
                                    key: ValueKey(product.id),
                                    index: index,
                                    product: product,
                                    category: widget.category,
                                    isFavorite: _favoriteService.isFavorite(
                                      product.id,
                                    ),
                                    onFavoriteToggle: () =>
                                        _toggleFavorite(product),
                                    isPopping: _isPopping,
                                  ),
                                );
                              },
                              childCount:
                                  products.length + (_isLoadingMore ? 2 : 0),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverShimmerGrid() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 245,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => const ShimmerCard(),
        childCount: 6,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Oops! Something went wrong",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? "We couldn't load the products. Please try again.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _fetchProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Try Again",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.square_list,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          const Text(
            "No Products Found",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            "We couldn't find any products in this category. Check back later!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class ShimmerCard extends StatefulWidget {
  const ShimmerCard({super.key});

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimmerBlock(height: 130, margin: 8, borderRadius: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    _shimmerBlock(height: 14, width: 80),
                    const SizedBox(height: 6),
                    _shimmerBlock(height: 10, width: 50),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _shimmerBlock(height: 18, width: 40),
                        _shimmerBlock(height: 32, width: 32, borderRadius: 8),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBlock({
    double? height,
    double? width,
    double margin = 0,
    double borderRadius = 4,
  }) {
    return Container(
      height: height,
      width: width,
      margin: EdgeInsets.all(margin),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [
            0.1 + _animation.value * 0.1,
            0.5 + _animation.value * 0.1,
            0.9 + _animation.value * 0.1,
          ],
          colors: [Colors.white, Colors.grey.shade50, Colors.white],
        ),
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  final Product product;
  final String category;
  final bool isFavorite;
  final bool isPopping;
  final int index;
  final VoidCallback onFavoriteToggle;

  const ProductCard({
    super.key,
    required this.product,
    required this.category,
    required this.isFavorite,
    required this.isPopping,
    required this.index,
    required this.onFavoriteToggle,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _appearController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _appearController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + (widget.index % 6) * 100),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _appearController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _appearController, curve: Curves.easeOut),
    );

    _appearController.forward();
  }

  @override
  void dispose() {
    _appearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _appearController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(scale: _scaleAnimation.value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  ProductDetailScreen(
                    product: widget.product,
                    thumbnailUrl: widget.product.thumbnail,
                  ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Container
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(6),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: HeroMode(
                          enabled: !widget.isPopping,
                          child: Hero(
                            tag: 'product_${widget.product.id}',
                            child: ProgressiveImage(
                              thumbnailUrl: widget.product.thumbnail,
                              imageUrl: widget.product.images.isNotEmpty
                                  ? widget.product.images.first
                                  : widget.product.thumbnail,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Wishlist Button
                    Positioned(
                      top: 10,
                      right: 10,
                      child: AnimatedHeart(
                        isFavorite: widget.isFavorite,
                        onTap: widget.onFavoriteToggle,
                      ),
                    ),
                  ],
                ),
              ),

              // Product Info
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF222222),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.product.technicalName ?? "Agri Grade",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "₹${widget.product.price.toStringAsFixed(0)}",
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),

                        // Compact Add Button
                        Container(
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.add,
                            color: Colors.white,
                            size: 16,
                          ),
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
    );
  }
}

class _StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyFilterDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => 50.0;

  @override
  double get minExtent => 50.0;

  @override
  bool shouldRebuild(covariant _StickyFilterDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
