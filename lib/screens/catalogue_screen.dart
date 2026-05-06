import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:krishikranti/features/products/data/repositories/product_repository.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/screens/product_list_screen.dart';
import 'package:krishikranti/screens/search_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:krishikranti/features/products/data/models/category_model.dart';
import 'package:krishikranti/features/products/data/models/collection_model.dart';
import 'package:krishikranti/features/products/data/repositories/home_repository.dart';

class CatalogueScreen extends StatefulWidget {
  final bool isShowingCollections;
  const CatalogueScreen({super.key, this.isShowingCollections = false});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  int _currentBanner = 0;
  bool _isLoading = true;
  List<Category> _categories = [];
  List<Collection> _collections = [];
  final ProductRepository _productRepository = ProductRepository();
  final HomeRepository _homeRepository = HomeRepository();

  final List<String> _bannerImages = [
    'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&q=80&w=800',
    'https://images.unsplash.com/photo-1523348837708-15d4a09cfac2?auto=format&fit=crop&q=80&w=800',
    'https://images.unsplash.com/photo-1595113316349-9fa4eb24f884?auto=format&fit=crop&q=80&w=800',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isShowingCollections) {
      _fetchCollections();
    } else {
      _fetchCategories();
    }
  }

  Future<void> _fetchCollections() async {
    try {
      // Step 1: Try to get cached data instantly
      final discovery = await _homeRepository.getHomeDiscovery(forceRefresh: false);
      if (mounted) {
        setState(() {
          _collections = discovery.collections;
          _isLoading = false;
        });
      }

      // Step 2: Background refresh happens inside HomeRepository if needed
    } catch (e) {
      if (mounted && _collections.isEmpty) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchCategories() async {
    try {
      // Step 1: Check HomeDiscovery cache first (it's often already warmed up by HomeScreen)
      final discovery = await _homeRepository.getHomeDiscovery(forceRefresh: false);
      if (mounted && discovery.categories.isNotEmpty) {
        setState(() {
          _categories = discovery.categories;
          _isLoading = false;
        });
        
        // If we found them in discovery, we can skip the dedicated categories fetch 
        // unless we want to be absolutely sure we have the full list
        return;
      }

      // Step 2: Fallback to dedicated categories fetch if not in discovery
      final categories = await _productRepository.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && _categories.isEmpty) {
        setState(() => _isLoading = false);
      }
    }
  }

  IconData _getIconForCategory(String name) {
    switch (name.toLowerCase()) {
      case 'insecticides':
        return Icons.bug_report;
      case 'fungicides':
        return Icons.science;
      case 'pgrs':
        return Icons.grass;
      case 'fertilizers':
        return Icons.eco;
      case 'herbicides':
        return Icons.agriculture;
      case 'bio-products':
        return Icons.psychology_alt;
      default:
        return Icons.category_outlined;
    }
  }

  String _getSubtitleForCategory(String name) {
    // Add translations for key categories
    switch (name.toLowerCase()) {
      case 'insecticides':
        return 'कीटनाशक';
      case 'fungicides':
        return 'कवकनाशी';
      case 'pgrs':
        return 'पादप वृद्धि नियामक';
      case 'fertilizers':
        return 'उर्वरक';
      case 'herbicides':
        return 'खरपतवार नाशी';
      case 'bio-products':
        return 'जैव उत्पाद';
      default:
        return 'कृषि उत्पाद';
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // REFINED MODERN APP BAR (Matched with Notification - Carefully Padded)
            SliverAppBar(
              expandedHeight: 120.0,
              toolbarHeight: 60.0,
              floating: false,
              pinned: true,
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              automaticallyImplyLeading: false,
              title: Text(
                widget.isShowingCollections ? "Crops" : l10n.categories,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(64),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    ),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.search,
                            size: 18,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Search for products...",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  // TOP BANNER (MORE COMPACT)
                  _buildBanner(context, theme),

                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.isShowingCollections
                              ? "Shop by Crop"
                              : "Browse Categories",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey.shade900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.05,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.isShowingCollections
                                ? "${_collections.length} Crops"
                                : "${_categories.length} Categories",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // COMPACT 3-COLUMN GRID
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    child: _isLoading
                        ? _buildShimmerGrid()
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: widget.isShowingCollections
                                ? _collections.length
                                : _categories.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.82,
                                ),
                            itemBuilder: (context, index) {
                              return _StaggeredEntrance(
                                index: index,
                                child: widget.isShowingCollections
                                    ? _buildCompactCollectionCard(
                                        context,
                                        _collections[index],
                                        theme,
                                      )
                                    : _buildCompactCategoryCard(
                                        context,
                                        _categories[index],
                                        theme,
                                      ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 32),

                  // MINIMAL FEATURE LIST
                  _buildMinimalFeatures(theme),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: _bannerImages.length,
          itemBuilder: (context, index, realIndex) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  _bannerImages[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: 150,
            viewportFraction: 1,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayCurve: Curves.easeInOut,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _bannerImages.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: _currentBanner == i ? 16 : 4,
              height: 4,
              decoration: BoxDecoration(
                color: _currentBanner == i
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade50),
          ),
        );
      },
    );
  }

  Widget _buildCompactCategoryCard(
    BuildContext context,
    Category category,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductListScreen(
              category: category.name,
              categoryId: category.id,
              categoryData: category,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.08),
                    theme.colorScheme.primary.withValues(alpha: 0.02),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  _getIconForCategory(category.name),
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Colors.black,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _getSubtitleForCategory(category.name),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCollectionCard(
    BuildContext context,
    Collection collection,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductListScreen(
              category: collection.name,
              collection: collection.name,
              initialProducts: collection.products,
              isCollection: true,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child:
                    collection.bannerImage != null &&
                        collection.bannerImage!.isNotEmpty
                    ? Image.network(
                        collection.bannerImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.eco,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      )
                    : Icon(
                        Icons.eco,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                collection.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Colors.black,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Crop Collection",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalFeatures(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _minimalBadge(Icons.verified_rounded, "Genuine", theme),
          _minimalBadge(Icons.science_rounded, "Tested", theme),
          _minimalBadge(Icons.local_shipping_rounded, "Express", theme),
        ],
      ),
    );
  }

  Widget _minimalBadge(IconData icon, String label, ThemeData theme) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.primary.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _StaggeredEntrance extends StatefulWidget {
  final Widget child;
  final int index;

  const _StaggeredEntrance({required this.child, required this.index});

  @override
  State<_StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<_StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 40 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: _slide.value * 20,
            child: widget.child,
          ),
        );
      },
    );
  }
}
