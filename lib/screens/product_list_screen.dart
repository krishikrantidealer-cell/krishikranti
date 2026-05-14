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

  // Modern UI layout configurations
  final bool _isGridView = true;
  String _selectedSort =
      "Popularity"; // "Popularity", "Price: Low to High", "Price: High to Low", "Top Rated"
  bool _showOnlyInStock = false;
  bool _showWithDeals = false;

  List<SubCategory> _subCategories = [];

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

  int get _activeFiltersCount {
    int count = 0;
    if (_selectedSort != "Popularity") count++;
    if (_showOnlyInStock) count++;
    if (_showWithDeals) count++;
    return count;
  }

  List<Product> get _filteredProducts {
    List<Product> items = List.from(_products);

    // Apply Search Query locally
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

    // Apply Quick Filters
    if (_showOnlyInStock) {
      items = items.where((item) {
        final status = item.availabilityStatus?.toLowerCase() ?? "";
        return status != "out of stock" && status != "out_of_stock";
      }).toList();
    }

    if (_showWithDeals) {
      items = items.where((item) => item.compareAtPrice > item.price).toList();
    }

    // Apply Local Sorting
    if (_selectedSort == "Price: Low to High") {
      items.sort((a, b) => a.price.compareTo(b.price));
    } else if (_selectedSort == "Price: High to Low") {
      items.sort((a, b) => b.price.compareTo(a.price));
    } else if (_selectedSort == "Top Rated") {
      items.sort((a, b) => b.averageRating.compareTo(a.averageRating));
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

  void _showSortFilterBottomSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.only(
                top: 16,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 34,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sheet Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            color: Color(0xFF298E4D),
                            size: 24,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Sort & Filter",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            _selectedSort = "Popularity";
                            _showOnlyInStock = false;
                            _showWithDeals = false;
                          });
                          setState(() {});
                        },
                        child: const Text(
                          "Reset All",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Sort Section
                  const Text(
                    "SORT BY",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...[
                    "Popularity",
                    "Price: Low to High",
                    "Price: High to Low",
                    "Top Rated",
                  ].map((sortOption) {
                    final isSelected = _selectedSort == sortOption;
                    return GestureDetector(
                      onTap: () {
                        setSheetState(() => _selectedSort = sortOption);
                        setState(() {});
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF298E4D).withOpacity(0.05)
                              : const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF298E4D)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              sortOption,
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFF298E4D)
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF298E4D),
                                size: 20,
                              )
                            else
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),

                  // Filter Section
                  const Text(
                    "FILTER BY",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Switch for Only In Stock
                  _buildFilterToggleRow(
                    title: "In Stock Only",
                    subtitle: "Hide products that are currently unavailable",
                    value: _showOnlyInStock,
                    onChanged: (val) {
                      setSheetState(() => _showOnlyInStock = val);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 10),

                  // Switch for Offers/Deals
                  _buildFilterToggleRow(
                    title: "Exclusive Offers & Deals",
                    subtitle: "Show items with marked down dealer pricing",
                    value: _showWithDeals,
                    onChanged: (val) {
                      setSheetState(() => _showWithDeals = val);
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 24),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF298E4D), Color(0xFF1E6C3A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF298E4D).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          HapticFeedback.mediumImpact();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Apply Filters",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
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
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeColor: const Color(0xFF298E4D),
            onChanged: (val) {
              HapticFeedback.lightImpact();
              onChanged(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStickyMenuBar(ThemeData theme) {
    final activeCount = _activeFiltersCount;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyFilterDelegate(
        height: 56.0,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade100, width: 1.2),
            ),
          ),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Row(
                children: [
                  // Scrollable Subcategories List
                  Expanded(
                    child: widget.isCollection
                        ? Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.auto_awesome_rounded,
                                        color: theme.colorScheme.primary,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Exclusive Collection",
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            itemCount: _menuItems.length,
                            itemBuilder: (context, index) {
                              final isSelected = _selectedMenuIndex == index;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    if (_selectedMenuIndex != index) {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _selectedMenuIndex = index;
                                        _products = [];
                                        _isLoading = true;
                                      });
                                      _fetchProducts();
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? LinearGradient(
                                              colors: [
                                                theme.colorScheme.primary,
                                                theme.colorScheme.primary
                                                    .withOpacity(0.85),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      color: isSelected
                                          ? null
                                          : const Color(0xFFF1F3F5),
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : Colors.transparent,
                                        width: 1,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: theme.colorScheme.primary
                                                    .withOpacity(0.24),
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (index == 0) ...[
                                          Icon(
                                            Icons.all_inclusive_rounded,
                                            size: 13,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 5),
                                        ] else ...[
                                          Icon(
                                            _getIconForCategory(
                                              widget.category,
                                            ),
                                            size: 11,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 5),
                                        ],
                                        Text(
                                          _menuItems[index],
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.grey.shade700,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            fontSize: 11,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Vertical Separator Divider
                  Container(
                    width: 1.2,
                    height: 24,
                    color: Colors.grey.shade200,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),

                  // Sort & Filter Button Icon
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.tune_rounded,
                          color: activeCount > 0
                              ? theme.colorScheme.primary
                              : Colors.black87,
                          size: 20,
                        ),
                        onPressed: _showSortFilterBottomSheet,
                        tooltip: "Sort & Filter",
                      ),
                      if (activeCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFA9527), // Orange Accent
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: 14,
                            ),
                            child: Text(
                              activeCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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
      child: WillPopScope(
        onWillPop: () async {
          setState(() => _isPopping = true);
          return true;
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: SafeArea(
            top: false,
            child: RefreshIndicator(
              onRefresh: () => _fetchProducts(forceRefresh: true),
              color: theme.colorScheme.primary,
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
                              });
                            },
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.category,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isLoading
                                    ? "Loading..."
                                    : "${_filteredProducts.length} items available",
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
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
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) {
                          final isCloseButton =
                              child.key ==
                              const ValueKey('close_search_button');
                          final rotationTween = isCloseButton
                              ? Tween<double>(begin: -0.15, end: 0.0)
                              : Tween<double>(begin: 0.15, end: 0.0);
                          return RotationTransition(
                            turns: rotationTween.animate(anim),
                            child: ScaleTransition(
                              scale: anim,
                              child: FadeTransition(
                                opacity: anim,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: !_isSearching
                            ? IconButton(
                                key: const ValueKey('search_button'),
                                icon: const Icon(
                                  CupertinoIcons.search,
                                  color: Colors.black,
                                  size: 22,
                                ),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  setState(() => _isSearching = true);
                                },
                              )
                            : Padding(
                                key: const ValueKey('close_search_button'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = "";
                                      _isSearching = false;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      CupertinoIcons.xmark,
                                      color: Colors.grey.shade800,
                                      size: 13,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(1),
                      child: Container(color: Colors.grey.shade100, height: 1),
                    ),
                  ),

                  // Professional Sticky Filter Header
                  _buildStickyMenuBar(theme),

                  // Product Grid / List Grid Content
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
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
                                key: const ValueKey('product_sliver_grid'),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: _isGridView ? 2 : 1,
                                      mainAxisExtent: _isGridView ? 260 : 165,
                                      crossAxisSpacing: _isGridView ? 12 : 0,
                                      mainAxisSpacing: 12,
                                    ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    if (index >= products.length) {
                                      return ShimmerCard(
                                        isGridView: _isGridView,
                                      );
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
                                        isGridView: _isGridView,
                                      ),
                                    );
                                  },
                                  childCount:
                                      products.length +
                                      (_isLoadingMore ? 2 : 0),
                                ),
                              );
                            },
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

  Widget _buildSliverShimmerGrid() {
    return SliverGrid(
      key: const ValueKey('shimmer_sliver_grid'),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _isGridView ? 2 : 1,
        mainAxisExtent: _isGridView ? 260 : 165,
        crossAxisSpacing: _isGridView ? 12 : 0,
        mainAxisSpacing: 12,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => ShimmerCard(isGridView: _isGridView),
        childCount: _isGridView ? 6 : 4,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.shade50),
      ),
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
              size: 50,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Oops! Something went wrong",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? "We couldn't load the products. Please try again.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.black87, Colors.black],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: _fetchProducts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Try Again",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF298E4D).withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF298E4D).withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
              const Icon(
                CupertinoIcons.square_stack_3d_up_slash,
                size: 34,
                color: Color(0xFF298E4D),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            "No Products Found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We couldn't find any products matching your current criteria or subcategory.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedSort = "Popularity";
                _showOnlyInStock = false;
                _showWithDeals = false;
                _searchQuery = "";
                _searchController.clear();
                _isSearching = false;
                _selectedMenuIndex = 0;
                _isLoading = true;
              });
              _fetchProducts();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF298E4D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Clear All Filters",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class ShimmerCard extends StatefulWidget {
  final bool isGridView;
  const ShimmerCard({super.key, this.isGridView = true});

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
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: widget.isGridView
              ? Container(
                  key: const ValueKey('shimmer_grid_card'),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBlock(height: 130, margin: 8, borderRadius: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            _shimmerBlock(height: 12, width: 80),
                            const SizedBox(height: 6),
                            _shimmerBlock(height: 14, width: 120),
                            const SizedBox(height: 4),
                            _shimmerBlock(height: 10, width: 60),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _shimmerBlock(height: 18, width: 45),
                                _shimmerBlock(
                                  height: 30,
                                  width: 30,
                                  borderRadius: 8,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : _buildListShimmer(),
        );
      },
    );
  }

  Widget _buildListShimmer() {
    return Container(
      key: const ValueKey('shimmer_list_card'),
      height: 165,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          _shimmerBlock(height: 165, width: 125, borderRadius: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _shimmerBlock(height: 12, width: 60),
                  const SizedBox(height: 8),
                  _shimmerBlock(height: 16, width: 140),
                  const SizedBox(height: 6),
                  _shimmerBlock(height: 12, width: 90),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _shimmerBlock(height: 18, width: 50),
                          const SizedBox(height: 4),
                          _shimmerBlock(height: 10, width: 80),
                        ],
                      ),
                      _shimmerBlock(height: 30, width: 60, borderRadius: 10),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
  final bool isGridView;

  const ProductCard({
    super.key,
    required this.product,
    required this.category,
    required this.isFavorite,
    required this.isPopping,
    required this.index,
    required this.onFavoriteToggle,
    this.isGridView = true,
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
      duration: const Duration(milliseconds: 350),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _appearController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _appearController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );

    final delay = (widget.index % 6) * 60; // 60ms delay per index
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) {
        _appearController.forward();
      }
    });
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: widget.isGridView
              ? KeyedSubtree(
                  key: const ValueKey('grid_card_layout'),
                  child: _buildGridCard(context, theme),
                )
              : KeyedSubtree(
                  key: const ValueKey('list_card_layout'),
                  child: _buildListCard(context, theme),
                ),
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, ThemeData theme) {
    double discountPercent = 0.0;
    if (widget.product.compareAtPrice > widget.product.price &&
        widget.product.compareAtPrice > 0) {
      discountPercent =
          ((widget.product.compareAtPrice - widget.product.price) /
              widget.product.compareAtPrice) *
          100;
    }

    final isOutOfStock =
        widget.product.availabilityStatus?.toLowerCase() == "out of stock" ||
        widget.product.availabilityStatus?.toLowerCase() == "out_of_stock";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: Colors.white,
                    child: Stack(
                      children: [
                        Center(
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
                                padding: 12.0,
                              ),
                            ),
                          ),
                        ),
                        if (isOutOfStock)
                          Container(
                            color: Colors.black.withOpacity(0.4),
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 4,
                                    sigmaY: 4,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    color: Colors.black.withOpacity(0.3),
                                    child: const Text(
                                      "SOLD OUT",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (discountPercent > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFA9527),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "${discountPercent.toStringAsFixed(0)}% OFF",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                          Expanded(
                            child: Text(
                              widget.product.brandName?.toUpperCase() ??
                                  "AGRI PREMIUM",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.product.technicalName ?? "High efficacy formula",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "₹${widget.product.price.toStringAsFixed(0)}",
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15.5,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    if (discountPercent > 0) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        "₹${widget.product.compareAtPrice.toStringAsFixed(0)}",
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 30,
                            width: 30,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary.withOpacity(0.85),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.24,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              CupertinoIcons.right_chevron,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.product.averageRating > 0)
              Positioned(
                top: 8,
                left: 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.72),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFA9527),
                            size: 11,
                          ),
                          const SizedBox(width: 2.5),
                          Text(
                            widget.product.averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontWeight: FontWeight.w900,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            Positioned(
              top: 8,
              right: 8,
              child: HeroMode(
                enabled: !widget.isPopping,
                child: Hero(
                  tag: 'heart_${widget.product.id}',
                  child: AnimatedHeart(
                    isFavorite: widget.isFavorite,
                    onTap: widget.onFavoriteToggle,
                    size: 16,
                    backgroundColor: Colors.white.withOpacity(0.85),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context, ThemeData theme) {
    double discountPercent = 0.0;
    double savingsAmount = 0.0;
    if (widget.product.compareAtPrice > widget.product.price &&
        widget.product.compareAtPrice > 0) {
      discountPercent =
          ((widget.product.compareAtPrice - widget.product.price) /
              widget.product.compareAtPrice) *
          100;
      savingsAmount = widget.product.compareAtPrice - widget.product.price;
    }

    final isOutOfStock =
        widget.product.availabilityStatus?.toLowerCase() == "out of stock" ||
        widget.product.availabilityStatus?.toLowerCase() == "out_of_stock";

    return Container(
      height: 165,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Row(
              children: [
                Container(
                  width: 125,
                  height: 165,
                  color: Colors.white,
                  child: Stack(
                    children: [
                      Center(
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
                              padding: 10.0,
                            ),
                          ),
                        ),
                      ),
                      if (isOutOfStock)
                        Container(
                          color: Colors.black.withOpacity(0.4),
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  color: Colors.black.withOpacity(0.3),
                                  child: const Text(
                                    "SOLD OUT",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (widget.product.averageRating > 0)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.72),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFFA9527),
                                      size: 10,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      widget.product.averageRating
                                          .toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 8.5,
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            if (discountPercent > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFA9527),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "${discountPercent.toStringAsFixed(0)}% OFF",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  widget.product.brandName?.toUpperCase() ??
                                      "PREMIUM GRADE",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.product.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.product.technicalName ??
                              "Crop Safety Formulation",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 6,
                                    runSpacing: 2,
                                    children: [
                                      Text(
                                        "₹${widget.product.price.toStringAsFixed(0)}",
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 17,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      if (discountPercent > 0)
                                        Text(
                                          "₹${widget.product.compareAtPrice.toStringAsFixed(0)}",
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (savingsAmount > 0) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      "Dealer saves ₹${savingsAmount.toStringAsFixed(0)} (${discountPercent.toStringAsFixed(0)}% off)",
                                      style: const TextStyle(
                                        color: Color(0xFFE67E22),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Add",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    color: Colors.white,
                                    size: 10,
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
              ],
            ),

            Positioned(
              top: 8,
              right: 8,
              child: HeroMode(
                enabled: !widget.isPopping,
                child: Hero(
                  tag: 'heart_${widget.product.id}',
                  child: AnimatedHeart(
                    isFavorite: widget.isFavorite,
                    onTap: widget.onFavoriteToggle,
                    size: 16,
                    backgroundColor: Colors.white.withOpacity(0.85),
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

class _StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyFilterDelegate({required this.child, this.height = 56.0});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _StickyFilterDelegate oldDelegate) {
    return child != oldDelegate.child || height != oldDelegate.height;
  }
}
