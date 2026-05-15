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
import 'package:krishikranti/widgets/breathing_mic_icon.dart';
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
import 'package:krishikranti/widgets/category_card.dart';
import 'package:krishikranti/widgets/product_card.dart';
import 'package:krishikranti/widgets/trust_badges.dart';
import 'package:krishikranti/widgets/support_floating_button.dart';

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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAF8),
        body: Stack(
          children: [
            // Background subtle modern decor
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
              top: false,
              child: RefreshIndicator(
                onRefresh: () => _fetchDiscoveryData(forceRefresh: true),
                color: theme.colorScheme.primary,
                child: ListenableBuilder(
                  listenable: _favoriteService,
                  builder: (context, child) {
                    return CustomScrollView(
                      physics: const ClampingScrollPhysics(),
                      slivers: [
                        // Unified Pinned Gradient Header & Search Bar
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _SliverHeaderDelegate(
                            header: _buildHeader(context, theme, l10n),
                            searchBar: _buildSearchBar(context, theme, l10n),
                            topPadding: MediaQuery.paddingOf(context).top,
                          ),
                        ),

                        // Banner Section
                        SliverPadding(
                          padding: const EdgeInsets.only(top: 10),
                          sliver: SliverToBoxAdapter(
                            child: _buildBanner(context, theme),
                          ),
                        ),

                        // Categories Section
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                          sliver: SliverToBoxAdapter(
                            child: _sectionTitle(
                              theme,
                              l10n.categories,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CatalogueScreen(),
                                  ),
                                );
                              },
                              l10n,
                              subtitle: "Explore top agricultural sectors",
                            ),
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
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        SliverToBoxAdapter(
                          child: _buildShopByCrop(context, theme, l10n),
                        ),

                        // Best Offers
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        SliverToBoxAdapter(
                          child: _buildBestOffers(context, theme, l10n),
                        ),

                        // Combined Trust & Footer Section
                        const SliverToBoxAdapter(child: SizedBox(height: 32)),
                        SliverToBoxAdapter(
                          child: _buildFooter(context, theme, l10n),
                        ),

                        // Bottom spacing
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSupportButton(BuildContext context, ThemeData theme) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.heavyImpact();
        final url = Uri.parse("https://wa.me/919399022060");
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          await launchUrl(url, mode: LaunchMode.platformDefault);
        }
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF25D366).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Expert Help",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.white.withValues(alpha: 0.8)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
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
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        _getTimeBasedGreeting(l10n),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('• d MMM').format(DateTime.now()),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    profile.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: Colors.white,
                      letterSpacing: -0.4,
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
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            padding: const EdgeInsets.all(8),
          ),
          icon: count == 0
              ? const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                  size: 22,
                )
              : Badge(
                  label: Text(count > 99 ? '99+' : count.toString()),
                  backgroundColor: Colors.redAccent,
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                    size: 22,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          },
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.search,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position:
                                  Tween<Offset>(
                                    begin: const Offset(0.0, 0.5),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic,
                                    ),
                                  ),
                              child: child,
                            ),
                          );
                        },
                    child: Text(
                      _searchHints[_currentHintIndex],
                      key: ValueKey<int>(_currentHintIndex),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const SearchScreen(startVoiceSearch: true),
                      ),
                    );
                  },
                  child: BreathingMicIcon(
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
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
          key: ValueKey(imagesToDisplay.length),
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
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
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
            height: 165,
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
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    imagesToDisplay.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: safeIndex == i ? 20 : 6,
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
    AppLocalizations l10n, {
    String? subtitle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 5,
                height: subtitle != null ? 28 : 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      const Color(0xFF38B058),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: const Color(0xFF111827),
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                          letterSpacing: 0.3,
                          height: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              HapticFeedback.lightImpact();
              onSeeAll();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "See All",
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
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
          padding: EdgeInsets.zero,
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
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
        ),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          // STAGGERED GRID ANIMATION
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + (index * 100)),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: value,
                  child: CategoryCard(
                    en: cat.name,
                    hi: _getSubtitleForCategory(cat.name),
                    icon: _getIconForCategory(cat.name),
                    image: _getImageForCategory(cat, index),
                    fallbackImage: _getFallbackImageForCategory(cat.name),
                    onTap: () {
                      _productRepository.getProducts(
                        categoryId: cat.id,
                        limit: 20,
                      );
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
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
          child: _sectionTitle(
            theme,
            "Featured Products",
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductListScreen(
                    category: "Featured",
                    isCollection: false,
                  ),
                ),
              );
            },
            l10n,
            subtitle: "Premium farming essentials",
          ),
        ),
        SizedBox(
          height: 275,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _featuredProducts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final product = _featuredProducts[index];
              return SizedBox(
                width: 170,
                child: ProductCard(
                  key: ValueKey(product.id),
                  product: product,
                  category: "Featured",
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
                  index: index,
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
          child: _sectionTitle(
            theme,
            "Shop by Crop",
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const CatalogueScreen(isShowingCollections: true),
                ),
              );
            },
            l10n,
            subtitle: "Solutions for your crops",
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 125,
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
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.25),
                            theme.colorScheme.primary.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.15,
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
                              color: Colors.black.withValues(alpha: 0.08),
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
          child: _sectionTitle(
            theme,
            "Best Offers",
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const ProductListScreen(category: "Offers"),
                ),
              );
            },
            l10n,
            subtitle: "Exclusive deals & discounts",
          ),
        ),
        const SizedBox(height: 8),
        CarouselSlider.builder(
          key: ValueKey(offers.length),
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
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
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
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    offers.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: safeIndex == i ? 20 : 6,
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

  Widget _buildFooter(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade100, width: 1.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      child: Column(
        children: [
          // Trust Badges - Larger & More Visual
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTrustItem(
                Icons.security_outlined,
                "Secure",
                Colors.green.shade600,
              ),
              _buildTrustItem(
                Icons.local_shipping_outlined,
                "Fast",
                Colors.blue.shade600,
              ),
              _buildTrustItem(
                Icons.workspace_premium_outlined,
                "Organic",
                Colors.orange.shade600,
              ),
              _buildTrustItem(
                Icons.verified_user_outlined,
                "Trusted",
                Colors.purple.shade600,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Brand & Support Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/images/app_logo.png',
                      height: 38,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.eco_rounded,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Empowering Indian Farmers since 2026.",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildSocialIcon(Icons.facebook_rounded),
                        const SizedBox(width: 16),
                        _buildSocialIcon(Icons.camera_alt_rounded),
                        const SizedBox(width: 16),
                        _buildSocialIcon(Icons.play_circle_filled_rounded),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: InkWell(
                  onTap: () async {
                    final url = Uri.parse("https://wa.me/919399022060");
                    if (!await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    )) {
                      await launchUrl(url, mode: LaunchMode.platformDefault);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF25D366).withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.chat_bubble_rounded,
                          color: Color(0xFF25D366),
                          size: 18,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Expert Help",
                          style: TextStyle(
                            color: Color(0xFF128C7E),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Bottom Compact Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "© 2026 Krishikranti Organics",
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.eco_rounded,
                      size: 10,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "v2.4.0",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade500,
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

  Widget _buildTrustItem(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 28, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Icon(icon, size: 24, color: Colors.grey.shade400);
  }
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget header;
  final Widget searchBar;
  final double topPadding;

  _SliverHeaderDelegate({
    required this.header,
    required this.searchBar,
    required this.topPadding,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double headerOpacity = (1.0 - (shrinkOffset / 60)).clamp(0.0, 1.0);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF20823C), Color(0xFF38B058)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (headerOpacity > 0)
            Positioned(
              top: topPadding + 10 - (shrinkOffset * 0.4),
              left: 16,
              right: 16,
              child: Opacity(opacity: headerOpacity, child: header),
            ),
          Positioned(bottom: 12, left: 16, right: 16, child: searchBar),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 130 + topPadding;

  @override
  double get minExtent => 70 + topPadding;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
