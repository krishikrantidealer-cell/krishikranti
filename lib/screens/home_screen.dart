import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:krishikranti/features/products/data/models/product_model.dart';
import 'package:krishikranti/features/products/data/models/category_model.dart';
import 'package:krishikranti/features/products/data/models/banner_model.dart';
import 'package:krishikranti/features/products/data/repositories/product_repository.dart';
import 'package:krishikranti/features/products/data/models/collection_model.dart';
import 'package:krishikranti/features/products/data/repositories/home_repository.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/core/favorite_service.dart';
import 'package:krishikranti/core/cart_service.dart';
import 'package:krishikranti/core/profile_service.dart';
import 'package:krishikranti/widgets/animated_heart.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:krishikranti/screens/profile_screen.dart';
import 'package:intl/intl.dart';
import 'package:krishikranti/screens/cart_screen.dart';
import 'package:krishikranti/screens/product_list_screen.dart';
import 'package:krishikranti/widgets/progressive_image.dart';
import 'package:krishikranti/screens/product_detail_screen.dart';
import 'package:krishikranti/screens/catalogue_screen.dart';
import 'package:krishikranti/screens/search_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // Carousel state
  final ValueNotifier<int> _currentBanner = ValueNotifier<int>(0);
  final ValueNotifier<int> _currentOfferBanner = ValueNotifier<int>(0);
  final FavoriteService _favoriteService = FavoriteService();
  final ProductRepository _productRepository = ProductRepository();
  final HomeRepository _homeRepository = HomeRepository();
  List<Category> _categories = [];
  List<Collection> _collections = [];
  List<Product> _featuredProducts = [];
  List<BannerModel> _banners = [];
  List<BannerModel> _categoryCardBanners = [];
  List<BannerModel> _bestOffersBanners = [];
  bool _isDiscoveryLoading = true;
  String? _discoveryError;

  final List<String> _searchHints = [
    "Search for 'Fungicides'...",
    "Search for 'Insecticides'...",
    "Search for 'Herbicides'...",
    "Search for 'Bio-Products'...",
    "Search for 'PGRs'...",
    "Search for 'Fertilizers'...",
  ];
  int _currentHintIndex = 0;
  Timer? _hintTimer;
  bool _routeIsCurrent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchDiscoveryData();
    _startHintRotation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user returns to the app from background, silently refresh data
    if (state == AppLifecycleState.resumed) {
      _silentRefresh();
    }
  }

  /// Called whenever dependencies change (including on pop-back to this screen)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      if (_routeIsCurrent == false) {
        // Route just became active again (user navigated back)
        _silentRefresh();
      }
      _routeIsCurrent = true;
    } else {
      _routeIsCurrent = false;
    }
  }

  /// Silent background refresh — updates data without showing a loading spinner
  void _silentRefresh() {
    _homeRepository
        .getHomeDiscovery(forceRefresh: true)
        .then((freshDiscovery) {
          if (mounted) {
            setState(() {
              _categories = freshDiscovery.categories;
              _collections = freshDiscovery.collections;
              _featuredProducts = freshDiscovery.featuredProducts;
              _banners = freshDiscovery.banners;
              _categoryCardBanners = freshDiscovery.categoryCardBanners;
              _bestOffersBanners = freshDiscovery.bestOffersBanners;
            });
          }
        })
        .catchError((_) {
          /* silent — don't disrupt UI on background failure */
        });
  }

  void _startHintRotation() {
    _hintTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentHintIndex = (_currentHintIndex + 1) % _searchHints.length;
        });
      }
    });
  }

  Future<void> _fetchDiscoveryData({bool forceRefresh = false}) async {
    try {
      // Step 1: Get cached data (instantly)
      final discovery = await _homeRepository.getHomeDiscovery(
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          _categories = discovery.categories;
          _collections = discovery.collections;
          _featuredProducts = discovery.featuredProducts;
          _banners = discovery.banners;
          _categoryCardBanners = discovery.categoryCardBanners;
          _bestOffersBanners = discovery.bestOffersBanners;
          _isDiscoveryLoading = false;
          _discoveryError = null;
        });
      }

      // Step 2: Background Refresh (SWR)
      // If we got data from cache, silently fetch fresh data in background
      // This ensures the user sees something instantly, but data stays fresh
      if (!forceRefresh) {
        final freshDiscovery = await _homeRepository.getHomeDiscovery(
          forceRefresh: true,
        );
        if (mounted) {
          setState(() {
            _categories = freshDiscovery.categories;
            _collections = freshDiscovery.collections;
            _featuredProducts = freshDiscovery.featuredProducts;
            _banners = freshDiscovery.banners;
            _categoryCardBanners = freshDiscovery.categoryCardBanners;
            _bestOffersBanners = freshDiscovery.bestOffersBanners;
          });
          _prefetchData(freshDiscovery.categories);
        }
      }
    } catch (e) {
      if (mounted && _categories.isEmpty) {
        setState(() {
          _isDiscoveryLoading = false;
          _discoveryError = "Failed to load home data";
        });
      }
    }
  }

  void _prefetchData(List<Category> categories) {
    // Warm up cache for each main category in background
    for (final cat in categories) {
      _productRepository.getProducts(categoryId: cat.id, limit: 20);
    }
    // Warm up Featured
    _productRepository.getProducts(isFeatured: true, limit: 20);
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
    switch (name.toLowerCase()) {
      case 'insecticides':
        return 'कीटनाशक';
      case 'fungicides':
        return 'कवकनाशी';
      case 'pgrs':
        return 'पादप वृद्धि';
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

  String _getTimeBasedGreeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  String _getFallbackImageForCategory(String name) {
    switch (name.toLowerCase()) {
      case 'insecticides':
        return 'https://images.unsplash.com/photo-1599420186946-7b6fb4e297f0?auto=format&fit=crop&q=80&w=400';
      case 'fungicides':
        return 'https://images.unsplash.com/photo-1574943320219-553eb213f72d?auto=format&fit=crop&q=80&w=400';
      case 'fertilizers':
        return 'https://images.unsplash.com/photo-1585314062340-f1a5a7c9328d?auto=format&fit=crop&q=80&w=400';
      case 'pgrs':
        return 'https://images.unsplash.com/photo-1523348837708-15d4a09cfac2?auto=format&fit=crop&q=80&w=400';
      case 'bio-products':
      case 'bio products':
      case 'bioproducts':
        return 'https://storage.googleapis.com/krishi-product-images/categorycardbanners/Bio-Products.webp';
      case 'herbicides':
        return 'https://images.unsplash.com/photo-1515023115689-589c33041d3c?auto=format&fit=crop&q=80&w=400';
      default:
        return 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&q=80&w=400';
    }
  }

  String _getImageForCategory(Category cat, int index) {
    final String name = cat.name;
    if (_categoryCardBanners.isNotEmpty) {
      final String cleanName = name.trim().toLowerCase();
      final String cleanNameNoHyphen = cleanName
          .replaceAll('-', '')
          .replaceAll(' ', '');

      // 1. Match by redirect target (ID or Category Name)
      for (final banner in _categoryCardBanners) {
        final String? target = banner.redirectTarget?.trim().toLowerCase();
        if (target != null && (target == cat.id || target == cleanName)) {
          return banner.imageUrl;
        }
      }

      // 2. Match by banner title containing Category Name
      for (final banner in _categoryCardBanners) {
        final String title = banner.title.trim().toLowerCase();
        if (title.contains(cleanName) || title.contains(cleanNameNoHyphen)) {
          return banner.imageUrl;
        }
      }

      // 3. Match by array-index formatting ("_card_index", "Category Card Banner {index + 1}")
      for (final banner in _categoryCardBanners) {
        final String bannerId = banner.id;
        final String bannerTitle = banner.title;
        if (bannerId.endsWith('_card_$index') ||
            bannerTitle == 'Category Card Banner ${index + 1}' ||
            banner.priority == index) {
          return banner.imageUrl;
        }
      }

      // 4. Fallback to image URL keyword matching
      for (final banner in _categoryCardBanners) {
        final String cleanUrl = banner.imageUrl.toLowerCase();
        if (cleanUrl.contains('/$cleanName.') ||
            cleanUrl.contains('/$cleanName%') ||
            cleanUrl.contains('_$cleanName') ||
            cleanUrl.contains(cleanName) ||
            cleanUrl.contains(cleanNameNoHyphen)) {
          return banner.imageUrl;
        }
      }

      // 5. Ultimate fallback: Match strictly 1-to-1 by order in the list
      if (index < _categoryCardBanners.length) {
        return _categoryCardBanners[index].imageUrl;
      }
    }

    // Default static assets/Unsplash fallback URLs if no database category banners are matched
    return _getFallbackImageForCategory(name);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _currentBanner.dispose();
    _currentOfferBanner.dispose();
    _hintTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAF8,
      ), // Ultra-light greenish tint for premium feel
      body: Stack(
        children: [
          // Background soft blobs for a modern look
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
              ),
            ),
          ),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: () => _fetchDiscoveryData(forceRefresh: true),
              color: theme.colorScheme.primary,
              child: ListenableBuilder(
                listenable: _favoriteService,
                builder: (context, child) {
                  return CustomScrollView(
                    physics: const ClampingScrollPhysics(),
                    slivers: [
                      // Glassmorphic App Bar / Header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: _buildHeader(context, theme, l10n),
                        ),
                      ),

                      // Floating Search Bar with animations
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverSearchDelegate(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: _buildSearchBar(context, theme, l10n),
                          ),
                        ),
                      ),

                      // Banner Section with slight elevation
                      SliverPadding(
                        padding: const EdgeInsets.only(top: 4),
                        sliver: SliverToBoxAdapter(
                          child: _buildBanner(context, theme),
                        ),
                      ),

                      // Categories Section with Staggered Grid
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                        sliver: SliverToBoxAdapter(
                          child: _sectionTitle(theme, l10n.categories, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CatalogueScreen(),
                              ),
                            );
                          }, l10n),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _buildCategories(context, theme),
                      ),

                      // Featured Products
                      SliverToBoxAdapter(
                        child: _buildFeaturedProducts(context, theme, l10n),
                      ),

                      // Shop by Crop (Collections)
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      SliverToBoxAdapter(
                        child: _buildShopByCrop(context, theme, l10n),
                      ),

                      // Best Offers
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      SliverToBoxAdapter(
                        child: _buildBestOffers(context, theme, l10n),
                      ),

                      // Why Choose Us
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      SliverToBoxAdapter(
                        child: _buildWhyChooseUs(context, theme, l10n),
                      ),

                      // Footer
                      SliverToBoxAdapter(
                        child: _buildFooter(context, theme, l10n),
                      ),

                      // Bottom spacing
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Consumer<ProfileService>(
      builder: (context, profile, child) {
        return Row(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Center(
                    child: Text(
                      profile.avatarLetter,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        _getTimeBasedGreeting(l10n),
                        style: TextStyle(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.8,
                          ),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('• d MMM').format(DateTime.now()),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    profile.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Colors.black87,
                      letterSpacing: -0.7,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildCartButton(context, theme),
          ],
        );
      },
    );
  }

  Widget _buildCartButton(BuildContext context, ThemeData theme) {
    return Consumer<CartService>(
      builder: (context, cart, child) {
        final count = cart.totalCount;
        return IconButton.filled(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          },
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            padding: const EdgeInsets.all(10),
          ),
          icon: count == 0
              ? const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                  size: 24,
                )
              : Badge(
                  label: Text(count > 99 ? '99+' : count.toString()),
                  backgroundColor: Colors.redAccent,
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
      },
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.5),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  _searchHints[_currentHintIndex],
                  key: ValueKey<int>(_currentHintIndex),
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.tune_rounded,
                color: theme.colorScheme.primary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context, ThemeData theme) {
    final List<String> imagesToDisplay = _banners.isNotEmpty
        ? _banners.map((b) => b.imageUrl).toList()
        : const [];

    if (imagesToDisplay.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: imagesToDisplay.length,
          itemBuilder: (context, index, realIndex) {
            final String imageUrl = imagesToDisplay[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (_banners.isNotEmpty && index < _banners.length) {
                    final banner = _banners[index];
                    if (banner.redirectType == 'category' &&
                        banner.redirectTarget != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductListScreen(
                            category: banner.redirectTarget!,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ProductListScreen(category: "All"),
                        ),
                      );
                    }
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ProductListScreen(category: "All"),
                      ),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: imageUrl.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) =>
                                Container(color: Colors.grey[200]),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(
                                Icons.image_outlined,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Image.asset(
                            imageUrl,
                            fit: BoxFit.fill,
                            width: double.infinity,
                          ),
                  ),
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: 160,
            viewportFraction: 1.0,
            autoPlay: imagesToDisplay.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.easeInOutCubic,
            enableInfiniteScroll: imagesToDisplay.length > 1,
            pauseAutoPlayOnTouch: true,
            pauseAutoPlayOnManualNavigate: true,
            scrollPhysics: const BouncingScrollPhysics(),
            onPageChanged: (index, reason) {
              _currentBanner.value = index;
            },
          ),
        ),
        ValueListenableBuilder<int>(
          valueListenable: _currentBanner,
          builder: (context, currentIndex, child) {
            if (imagesToDisplay.length <= 1) return const SizedBox.shrink();
            // Safeguard bounds in case the banner list changed dynamically
            final int safeIndex = currentIndex < imagesToDisplay.length
                ? currentIndex
                : 0;
            return Column(
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    imagesToDisplay.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.all(4),
                      width: safeIndex == i ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: safeIndex == i
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _sectionTitle(
    ThemeData theme,
    String title,
    VoidCallback onSeeAll,
    AppLocalizations l10n,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            onSeeAll();
          },
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: const Row(
            children: [
              Text(
                "See All",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategories(BuildContext context, ThemeData theme) {
    if (_isDiscoveryLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.1,
          ),
          itemBuilder: (context, index) => Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.3,
        ),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return CategoryCard(
            en: cat.name,
            hi: _getSubtitleForCategory(cat.name),
            icon: _getIconForCategory(cat.name),
            image: _getImageForCategory(cat, index),
            fallbackImage: _getFallbackImageForCategory(cat.name),
            onTap: () {
              // Trigger pre-fetch (cached in repository)
              _productRepository.getProducts(categoryId: cat.id, limit: 20);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductListScreen(
                    category: cat.name,
                    categoryId: cat.id,
                    categoryData: cat,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFeaturedProducts(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    if (_isDiscoveryLoading) {
      return const SizedBox.shrink(); // Or a small shimmer
    }

    if (_featuredProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: _sectionTitle(theme, "Featured Products", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProductListScreen(
                  category: "Featured",
                  isCollection: false,
                ),
              ),
            );
          }, l10n),
        ),
        SizedBox(
          height: 265,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _featuredProducts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = _featuredProducts[index];
              return SizedBox(
                width: 165,
                child: ProductCard(
                  product: product,
                  id: product.id,
                  name: product.title,
                  category: product.brandName ?? "Product",
                  weight: product.variants.isNotEmpty
                      ? product.variants.first.size
                      : "N/A",
                  price: product.price.toStringAsFixed(0),
                  imageUrl: product.thumbnail,
                  isFavorite: _favoriteService.isFavorite(product.id),
                  onFavoriteToggle: () {
                    _favoriteService.toggleFavorite(
                      FavoriteProduct(
                        id: product.id,
                        name: product.title,
                        category: product.brandName ?? "Product",
                        price: product.price.toStringAsFixed(0),
                        imageUrl: product.thumbnail,
                        weight: product.variants.isNotEmpty
                            ? product.variants.first.size
                            : "N/A",
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShopByCrop(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    if (_isDiscoveryLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Shop by Crop",
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 125,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: 6,
              separatorBuilder: (context, index) => const SizedBox(width: 20),
              itemBuilder: (context, index) => Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final crops = _collections;
    if (crops.isEmpty || _discoveryError != null)
      return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _sectionTitle(theme, "Shop by Crop", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const CatalogueScreen(isShowingCollections: true),
              ),
            );
          }, l10n),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: crops.length,
            separatorBuilder: (context, index) => const SizedBox(width: 20),
            itemBuilder: (context, index) {
              final crop = crops[index];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductListScreen(
                        category: crop.name,
                        collection: crop.name,
                        initialProducts: crop.products,
                        isCollection: true,
                      ),
                    ),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.2),
                            theme.colorScheme.primary.withValues(alpha: 0.05),
                          ],
                        ),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child:
                              crop.bannerImage != null &&
                                  crop.bannerImage!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: crop.bannerImage!,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: Colors.grey[100],
                                        child: const Icon(
                                          Icons.eco,
                                          color: Colors.green,
                                        ),
                                      ),
                                )
                              : Container(
                                  color: Colors.grey[100],
                                  child: const Icon(
                                    Icons.eco,
                                    color: Colors.green,
                                    size: 30,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      crop.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.black87,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBestOffers(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final List<Map<String, String>> offers = _bestOffersBanners.isNotEmpty
        ? _bestOffersBanners
              .map((b) => {'title': b.title, 'image': b.imageUrl})
              .toList()
        : [
            {
              'title': 'Buy 1 Get 1',
              'image':
                  'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&q=80&w=600',
            },
            {
              'title': 'Flat 20% OFF',
              'image':
                  'https://images.unsplash.com/photo-1523348837708-15d4a09cfac2?auto=format&fit=crop&q=80&w=600',
            },
            {
              'title': 'Limited Time Deal',
              'image':
                  'https://images.unsplash.com/photo-1595113316349-9fa4eb24f884?auto=format&fit=crop&q=80&w=600',
            },
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _sectionTitle(theme, "Best Offers", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const ProductListScreen(category: "Offers"),
              ),
            );
          }, l10n),
        ),
        const SizedBox(height: 16),
        CarouselSlider.builder(
          itemCount: offers.length,
          itemBuilder: (context, index, realIndex) {
            final offer = offers[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ProductListScreen(category: "Offers"),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: offer['image']!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      fadeInDuration: const Duration(milliseconds: 300),
                      placeholder: (context, url) => Container(
                        color: Colors.grey[100],
                        child: const Center(
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        child: Center(
                          child: Icon(
                            Icons.local_offer_outlined,
                            color: theme.colorScheme.primary,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: 180,
            aspectRatio: 16 / 9,
            viewportFraction: 1.0,
            autoPlay: offers.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.easeInOutCubic,
            enableInfiniteScroll: offers.length > 1,
            pauseAutoPlayOnTouch: true,
            pauseAutoPlayOnManualNavigate: true,
            scrollPhysics: const BouncingScrollPhysics(),
            onPageChanged: (index, reason) {
              _currentOfferBanner.value = index;
            },
          ),
        ),
        ValueListenableBuilder<int>(
          valueListenable: _currentOfferBanner,
          builder: (context, currentIndex, child) {
            if (offers.length <= 1) return const SizedBox.shrink();
            final int safeIndex = currentIndex < offers.length
                ? currentIndex
                : 0;
            return Column(
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    offers.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.all(4),
                      width: safeIndex == i ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: safeIndex == i
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildWhyChooseUs(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final items = [
      {'title': 'Trusted by Farmers', 'icon': Icons.verified_user_outlined},
      {'title': 'Fast Delivery', 'icon': Icons.local_shipping_outlined},
      {'title': '100% Genuine', 'icon': Icons.workspace_premium_outlined},
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items.map((item) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['title'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              children: [
                // Logo - Increased visibility
                Image.asset(
                  'assets/images/app_logo.png',
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Text(
                    "Krishi Dealer",
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // WhatsApp Support Button - Compact & Premium
                Center(
                  child: SizedBox(
                    width: 210,
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse("https://wa.me/919399022060");
                        if (!await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        )) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.platformDefault,
                          );
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: const Text(
                        "WhatsApp Support",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 2,
                        shadowColor: Colors.black12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Premium small row - Reduced sizes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFooterIconLabel(
                      Icons.security,
                      "Secure Payment",
                      theme,
                    ),
                    _buildFooterIconLabel(Icons.replay, "Easy Return", theme),
                    _buildFooterIconLabel(
                      Icons.headset_mic,
                      "24/7 Support",
                      theme,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Copyright
                Text(
                  "© 2026 Krishi Dealer",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterIconLabel(IconData icon, String label, ThemeData theme) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
      ],
    );
  }
}

class ProductCard extends StatefulWidget {
  final Product? product;
  final String id, name, category, weight, price, imageUrl;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final String? tag;

  const ProductCard({
    super.key,
    this.product,
    required this.id,
    required this.name,
    required this.category,
    required this.weight,
    required this.price,
    required this.imageUrl,
    this.isFavorite = false,
    required this.onFavoriteToggle,
    this.tag,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final displayProduct =
        widget.product ??
        Product(
          id: widget.id,
          title: widget.name,
          thumbnail: widget.imageUrl,
          images: [widget.imageUrl],
          variants: [
            Variant(
              id: "v_${widget.id}",
              size: widget.weight,
              price:
                  double.tryParse(
                    widget.price.replaceAll(RegExp(r'[^0-9.]'), ''),
                  ) ??
                  0.0,
              compareAtPrice: 0.0,
            ),
          ],
        );

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              product: displayProduct,
              thumbnailUrl: widget.imageUrl,
            ),
          ),
        );
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.zero,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Hero(
                        tag: "product_${widget.id}",
                        child: ProgressiveImage(
                          thumbnailUrl: displayProduct.thumbnail,
                          imageUrl: displayProduct.images.isNotEmpty
                              ? displayProduct.images.first
                              : displayProduct.thumbnail,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.tag != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade700,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.tag!.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (displayProduct.averageRating > 0)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.72),
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.6),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Colors.orange,
                                        size: 11,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        displayProduct.averageRating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 9.5,
                                          letterSpacing: -0.2,
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
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Hero(
                        tag: 'heart_${widget.id}',
                        child: AnimatedHeart(
                          isFavorite: widget.isFavorite,
                          onTap: widget.onFavoriteToggle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Details Section
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category.toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.weight,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "₹${widget.price}",
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 18,
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
        ),
      ),
    );
  }
}

class CategoryCard extends StatefulWidget {
  final String en, hi, image, fallbackImage;
  final IconData icon;
  final VoidCallback onTap;

  const CategoryCard({
    required this.en,
    required this.hi,
    required this.image,
    required this.fallbackImage,
    required this.icon,
    required this.onTap,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: widget.image,
                  fit: BoxFit.fill,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => CachedNetworkImage(
                    imageUrl: widget.fallbackImage,
                    fit: BoxFit.fill,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey[200]),
                    errorWidget: (context, url, error) => Container(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Center(
                        child: Icon(
                          widget.icon,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                          size: 40,
                        ),
                      ),
                    ),
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

class _SliverSearchDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverSearchDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: const Color(0xFFF8FAF8), child: child);
  }

  @override
  double get maxExtent => 70;

  @override
  double get minExtent => 70;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
