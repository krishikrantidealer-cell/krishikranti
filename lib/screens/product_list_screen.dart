import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/core/favorite_service.dart';
import 'package:krishikranti/screens/product_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:krishikranti/features/products/data/models/product_model.dart';
import 'package:krishikranti/features/products/data/repositories/product_repository.dart';

import 'package:krishikranti/features/products/data/models/category_model.dart';
import 'package:krishikranti/widgets/progressive_image.dart';

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

  @override
  void initState() {
    super.initState();
    _favoriteService.addListener(_onFavoriteChanged);
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
    _favoriteService.removeListener(_onFavoriteChanged);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onFavoriteChanged() {
    if (mounted) setState(() {});
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

    // If we already have products and it's not a forced refresh,
    // we don't show the full-screen loader (Shimmer) to keep the UI stable.
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

      // Step 1: Get cached data (fast)
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

      // Step 2: If the data was from cache, silently fetch fresh data in background (SWR)
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
    _favoriteService.toggleFavorite(
      FavoriteProduct(
        id: product.id,
        name: product.title,
        category: widget.category,
        price: product.price.toString(),
        imageUrl: product.thumbnail,
        weight: product.variants.isNotEmpty ? product.variants.first.size : "Standard",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = _filteredProducts;
    final l10n = AppLocalizations.of(context)!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(
              CupertinoIcons.back,
              color: Colors.black,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: _isSearching
              ? CupertinoSearchTextField(
                  controller: _searchController,
                  placeholder: l10n.searchProducts,
                  backgroundColor: Colors.grey.shade100,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  onSuffixTap: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = "";
                      _isSearching = false;
                    });
                  },
                )
              : Text(
                  widget.isCollection 
                      ? "${widget.category} Collection"
                      : widget.category,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
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
          ],
        ),
        body: SafeArea(
          minimum: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              // Top Category Chips
              Container(
                height: 54,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100, width: 1),
                  ),
                ),
                child: widget.isCollection 
                  ? const Center(
                      child: Text(
                        "All products in this collection",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _menuItems.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedMenuIndex == index;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          if (_selectedMenuIndex != index) {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _selectedMenuIndex = index;
                              _products = []; // Clear for new category
                            });
                            _fetchProducts();
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 0,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.grey.shade200,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            _menuItems[index],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Product Grid
              Expanded(
                child: _isLoading
                    ? _buildShimmerGrid()
                    : _errorMessage != null
                    ? _buildErrorWidget()
                    : products.isEmpty
                    ? _buildEmptyWidget()
                    : RefreshIndicator(
                        onRefresh: () => _fetchProducts(forceRefresh: true),
                        color: theme.colorScheme.primary,
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          cacheExtent:
                              500, // Pre-renders items off-screen for smoothness
                          physics: const BouncingScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisExtent: 295,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                              ),
                          itemCount: products.length + (_isLoadingMore ? 2 : 0),
                          itemBuilder: (context, index) {
                            if (index >= products.length) {
                              return const ShimmerCard();
                            }
                            final product = products[index];
                            return TweenAnimationBuilder<double>(
                              duration: Duration(
                                milliseconds: 300 + (index % 6) * 100,
                              ),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: RepaintBoundary(
                                child: ProductCard(
                                  key: ValueKey(product.id),
                                  product: product,
                                  category: widget.category,
                                  isFavorite: _favoriteService.isFavorite(
                                    product.title,
                                  ),
                                  onFavoriteToggle: () =>
                                      _toggleFavorite(product),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 295,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const ShimmerCard(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage ?? "Something went wrong"),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchProducts, child: const Text("Retry")),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return const Center(child: Text("No products found"));
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
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Shimmer
              _shimmerBlock(height: 140, margin: 8, borderRadius: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _shimmerBlock(height: 16, width: 120),
                    const SizedBox(height: 6),
                    _shimmerBlock(height: 12, width: 80),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _shimmerBlock(height: 20, width: 50),
                        _shimmerBlock(height: 32, width: 65, borderRadius: 8),
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
          colors: [
            Colors.grey.shade100,
            Colors.grey.shade200,
            Colors.grey.shade100,
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  final Product product;
  final String category;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const ProductCard({
    super.key,
    required this.product,
    required this.category,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onAddTap() {
    _scaleController.reverse().then((_) {
      _scaleController.forward();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(
            product: widget.product,
            thumbnailUrl: widget.product.thumbnail,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              product: widget.product,
              thumbnailUrl: widget.product.thumbnail,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
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
                      // Wishlist Button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: widget.onFavoriteToggle,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.isFavorite
                                  ? CupertinoIcons.heart_fill
                                  : CupertinoIcons.heart,
                              size: 16,
                              color: widget.isFavorite
                                  ? Colors.red
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Text Content
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.product.technicalName ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "₹${widget.product.price.toStringAsFixed(0)}",
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      ScaleTransition(
                        scale: _scaleController,
                        child: GestureDetector(
                          onTap: _onAddTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
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
                            child: const Text(
                              "Add",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
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
    );
  }
}
