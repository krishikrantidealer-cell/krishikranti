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
import 'package:krishikranti/core/meta_analytics_service.dart';
import 'package:krishikranti/core/utils/guest_barrier_util.dart';
import 'package:krishikranti/widgets/kyc_barrier_widget.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:krishikranti/screens/profile_screen.dart';
import 'package:intl/intl.dart';
import 'package:krishikranti/screens/cart_screen.dart';
import 'package:krishikranti/screens/product_list_screen.dart';
import 'package:krishikranti/screens/catalogue_screen.dart';
import 'package:krishikranti/screens/search_screen.dart';
import 'package:krishikranti/screens/favorites_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:krishikranti/widgets/category_card.dart';
import 'package:krishikranti/widgets/product_card.dart';
import 'package:krishikranti/core/utils/translatable_text.dart';
// ── Extracted home widgets ──────────────────────────────────────────────────
import 'package:krishikranti/widgets/home/home_banner_section.dart';
import 'package:krishikranti/widgets/home/home_section_title.dart';
import 'package:krishikranti/widgets/home/home_category_section.dart';
import 'package:krishikranti/widgets/home/home_collection_row.dart';
import 'package:krishikranti/widgets/home/home_collection_product_grid.dart';
import 'package:krishikranti/widgets/home/home_featured_section.dart';

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
  List<BannerModel> _stripBanners = [];
  bool _isDiscoveryLoading = true;
  String? _discoveryError;
  // Category-wise products for the "Shop by Category" section
  Map<String, List<Product>> _categoryProducts = {};

  bool _routeIsCurrent = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchDiscoveryData();
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
              _stripBanners = freshDiscovery.stripBanners;
            });
            if (_categoryProducts.isEmpty) {
              _fetchCategoryProducts(freshDiscovery.categories);
            }
          }
        })
        .catchError((_) {
          /* silent — don't disrupt UI on background failure */
        });
  }

  /// Fetch up to 4 products for each category to populate the browse-by-category section.
  /// All categories are fetched in parallel and applied in a single setState to avoid
  /// multiple rebuilds that cause scroll flicker.
  Future<void> _fetchCategoryProducts(List<Category> categories) async {
    final Map<String, List<Product>> newCategoryProducts = {};
    
    await Future.wait(categories.map((cat) async {
      try {
        final result = await _productRepository.getProducts(
          categoryId: cat.id,
          limit: 10,
        );
        final List<Product> allProducts = (result['products'] as List<Product>? ?? []);
        Product.sortProducts(allProducts, cat.id);
        final displayProducts = allProducts.take(4).toList();

        if (displayProducts.isNotEmpty) {
          newCategoryProducts[cat.id] = displayProducts;
        }
      } catch (_) {}
    }));

    if (mounted && newCategoryProducts.isNotEmpty) {
      setState(() {
        _categoryProducts = {..._categoryProducts, ...newCategoryProducts};
      });
    }
  }

  BannerModel? _findStripBanner(String key) {
    String normalize(String input) {
      return input
          .toLowerCase()
          .replaceAll(RegExp(r"['’]s\b"), '')
          .replaceAll(RegExp(r"[^a-z0-9]"), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    final cleanKey = normalize(key);
    if (cleanKey.isEmpty) return null;

    for (final banner in _stripBanners) {
      final title = normalize(banner.title);
      final target = normalize(banner.redirectTarget ?? '');

      if (title == cleanKey || target == cleanKey) {
        return banner;
      }
      if (title.isNotEmpty && (title.contains(cleanKey) || cleanKey.contains(title))) {
        return banner;
      }
      if (target.isNotEmpty && (target.contains(cleanKey) || cleanKey.contains(target))) {
        return banner;
      }
    }
    return null;
  }

  Future<void> _fetchDiscoveryData({bool forceRefresh = false}) async {
    if (forceRefresh) {
      if (mounted) {
        setState(() {
          _categoryProducts.clear();
        });
      }
    }
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
          _stripBanners = discovery.stripBanners;
          _isDiscoveryLoading = false;
          _discoveryError = null;
        });
        // Start loading category products in background
        if (_categoryProducts.isEmpty) {
          _fetchCategoryProducts(discovery.categories);
        }
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
            _stripBanners = freshDiscovery.stripBanners;
          });
          if (_categoryProducts.isEmpty) {
            _fetchCategoryProducts(freshDiscovery.categories);
          }
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

  String _getLocalizedCategoryName(String name, AppLocalizations l10n) {
    final clean = name.trim().toLowerCase();
    switch (clean) {
      case 'insecticides':
        return l10n.categoryInsecticides;
      case 'fungicides':
        return l10n.categoryFungicides;
      case 'pgr':
      case 'pgrs':
        return l10n.categoryPgrs;
      case 'fertilizers':
        return l10n.categoryFertilizers;
      case 'herbicides':
        return l10n.categoryHerbicides;
      case 'bio-products':
      case 'bio products':
      case 'bioproducts':
        return l10n.categoryBioProducts;
      default:
        return name;
    }
  }

  String _getSubtitleForCategory(String name, AppLocalizations l10n) {
    final clean = name.trim().toLowerCase();
    switch (clean) {
      case 'insecticides':
        return l10n.categoryInsecticides;
      case 'fungicides':
        return l10n.categoryFungicides;
      case 'pgr':
      case 'pgrs':
        return l10n.categoryPgrs;
      case 'fertilizers':
        return l10n.categoryFertilizers;
      case 'herbicides':
        return l10n.categoryHerbicides;
      case 'bio-products':
      case 'bio products':
      case 'bioproducts':
        return l10n.categoryBioProducts;
      default:
        return l10n.categoryDefault;
    }
  }

  String _getTimeBasedGreeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.goodMorning;
    if (hour < 17) return l10n.goodAfternoon;
    return l10n.goodEvening;
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
    if (cat.bannerImage != null && cat.bannerImage!.isNotEmpty) {
      return cat.bannerImage!;
    }
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
                onRefresh: () async {
                  await Future.wait([
                    _fetchDiscoveryData(forceRefresh: true),
                    if (mounted)
                      Provider.of<ProfileService>(context, listen: false)
                          .fetchProfileFromServer()
                          .catchError((_) => null),
                  ]);
                },
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
                            child: HomeBannerSection(
                              banners: _banners,
                              currentBanner: _currentBanner,
                            ),
                          ),
                        ),

                        // Categories Section
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                          sliver: SliverToBoxAdapter(
                            child: HomeSectionTitle(
                              theme: theme,
                              title: l10n.categories,
                              onSeeAll: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CatalogueScreen(),
                                  ),
                                );
                              },
                              seeAllLabel: l10n.seeAll,
                              subtitle: l10n.exploreTopSectors,
                              stripBanner: _findStripBanner('categories') ?? _findStripBanner('category'),
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

                        // Shop by Crop (Collections) & Browse by Category alternated
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        SliverToBoxAdapter(
                          child: _buildAlternatingSections(
                            context,
                            theme,
                            l10n,
                          ),
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
                if (profile.isGuest) {
                  GuestBarrierUtil.showGuestLoginDialog(context);
                  return;
                }
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
                    colors: [
                      Colors.white,
                      Colors.white.withValues(alpha: 0.8),
                    ],
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
                    child: TranslatableText(
                      profile.isGuest ? 'G' : profile.avatarLetter,
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
                      TranslatableText(
                        _getTimeBasedGreeting(l10n),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      TranslatableText(
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
                  TranslatableText(
                    profile.isGuest ? 'Guest' : profile.name,
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
            _buildFavoriteButton(context, theme),
            const SizedBox(width: 8),
            _buildCartButton(context, theme),
          ],
        );
      },
    );
  }

  Widget _buildFavoriteButton(BuildContext context, ThemeData theme) {
    return Consumer<FavoriteService>(
      builder: (context, favService, child) {
        final count = favService.favorites.length;
        return IconButton.filled(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavoritesScreen()),
            );
          },
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            padding: const EdgeInsets.all(8),
          ),
          icon: count == 0
              ? const Icon(
                  Icons.favorite_border_rounded,
                  color: Colors.white,
                  size: 22,
                )
              : Badge(
                  label: Text(count > 99 ? '99+' : count.toString()),
                  backgroundColor: Colors.redAccent,
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
        );
      },
    );
  }

  Widget _buildCartButton(BuildContext context, ThemeData theme) {
    final profile = Provider.of<ProfileService>(context, listen: false);
    return Consumer<CartService>(
      builder: (context, cart, child) {
        final count = profile.isGuest ? 0 : cart.totalCount;
        return IconButton.filled(
          onPressed: () {
            HapticFeedback.lightImpact();
            if (profile.isGuest) {
              GuestBarrierUtil.showGuestLoginDialog(context);
              return;
            }
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
    return _RotatingSearchBar(l10n: l10n, theme: theme);
  }

  Widget _buildCategories(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
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
                  opacity: value.clamp(0.0, 1.0),
                  child: CategoryCard(
                    en: cat.name,
                    hi: _getSubtitleForCategory(cat.name, l10n),
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
    if (_isDiscoveryLoading) return const SizedBox.shrink();
    if (_featuredProducts.isEmpty) return const SizedBox.shrink();

    return HomeFeaturedSection(
      products: _featuredProducts,
      favoriteService: _favoriteService,
      stripBanner: _findStripBanner('featured') ?? _findStripBanner('featured_products'),
    );
  }

  Widget _buildAlternatingSections(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    if (_isDiscoveryLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeCollectionRowSkeleton(title: l10n.collections),
          const SizedBox(height: 16),
          const HomeCategoryProductRowSkeleton(),
          const SizedBox(height: 36),
          HomeCollectionRowSkeleton(title: l10n.collections),
          const SizedBox(height: 16),
          const HomeCategoryProductRowSkeleton(),
          const SizedBox(height: 36),
        ],
      );
    }

    final Collection? dealerFirstChoice = () {
      for (final c in _collections) {
        final name = c.name.toLowerCase().trim();
        final slug = c.slug.toLowerCase().trim();
        if (name == 'dealer first choice' ||
            name == 'dealer\'s first choice' ||
            name == 'dealer’s first choice' ||
            name == 'dealers first choice' ||
            slug == 'dealer-first-choice' ||
            slug == 'dealer-s-first-choice') {
          return c;
        }
      }
      return null;
    }();

    final activeCollections = _collections.where((c) {
      final name = c.name.toLowerCase().trim();
      final slug = c.slug.toLowerCase().trim();
      if (name == 'dealer first choice' ||
          name == 'dealer\'s first choice' ||
          name == 'dealer’s first choice' ||
          name == 'dealers first choice' ||
          slug == 'dealer-first-choice' ||
          slug == 'dealer-s-first-choice') {
        return false;
      }
      return c.subCollections.where((s) => s.isActive).isNotEmpty;
    }).toList();

    final activeCategories = _categories.where((cat) {
      return _categoryProducts.containsKey(cat.id) &&
          _categoryProducts[cat.id]!.isNotEmpty;
    }).toList();

    if (activeCollections.isEmpty && activeCategories.isEmpty && dealerFirstChoice == null) {
      return const SizedBox.shrink();
    }

    final List<Widget> children = [];

    // 1. Add first active collection (Shop by Crop)
    bool hasAddedFirstCollection = false;
    if (activeCollections.isNotEmpty) {
      final col = activeCollections[0];
      final colTitleKey = col.bannerTitle?.trim() ?? '';
      children.add(
        HomeCollectionRow(
          collection: col,
          stripBanner: (colTitleKey.isNotEmpty ? _findStripBanner(colTitleKey) : null) ??
              _findStripBanner(col.name) ??
              _findStripBanner('crop') ??
              _findStripBanner('shop_by_crop'),
        ),
      );
      hasAddedFirstCollection = true;
    }

    // 2. Add Dealer First Choice right under the first collection
    if (dealerFirstChoice != null && dealerFirstChoice.products.isNotEmpty) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 36));
      }
      final dealerTitleKey = dealerFirstChoice.bannerTitle?.trim() ?? '';
      children.add(
        HomeCollectionProductGrid(
          collection: dealerFirstChoice,
          favoriteService: _favoriteService,
          isDealerFirstChoice: true,
          stripBanner: (dealerTitleKey.isNotEmpty ? _findStripBanner(dealerTitleKey) : null) ??
              _findStripBanner('dealer_first_choice') ??
              _findStripBanner('dealer first choice') ??
              _findStripBanner('dealer') ??
              _findStripBanner(dealerFirstChoice.name),
        ),
      );
    }

    // 3. Alternate the rest of the collections and categories
    int catIdx = 0;
    int colIdx = hasAddedFirstCollection ? 1 : 0;

    while (catIdx < activeCategories.length || colIdx < activeCollections.length) {
      // Add a category
      if (catIdx < activeCategories.length) {
        if (children.isNotEmpty) {
          children.add(const SizedBox(height: 36));
        }
        final cat = activeCategories[catIdx];
        final catTitleKey = cat.bannerTitle?.trim() ?? '';
        children.add(
          HomeCategorySection(
            category: cat,
            products: _categoryProducts[cat.id]!,
            favoriteService: _favoriteService,
            localizedTitle: _getLocalizedCategoryName(cat.name, l10n),
            stripBanner: (catTitleKey.isNotEmpty ? _findStripBanner(catTitleKey) : null) ??
                _findStripBanner(cat.name) ??
                _findStripBanner(cat.id),
          ),
        );
        catIdx++;
      }

      // Add a collection
      if (colIdx < activeCollections.length) {
        if (children.isNotEmpty) {
          children.add(const SizedBox(height: 36));
        }
        final col = activeCollections[colIdx];
        final colTitleKey = col.bannerTitle?.trim() ?? '';
        children.add(
          HomeCollectionRow(
            collection: col,
            stripBanner: (colTitleKey.isNotEmpty ? _findStripBanner(colTitleKey) : null) ??
                _findStripBanner(col.name) ??
                _findStripBanner(col.slug),
          ),
        );
        colIdx++;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Column(
        children: [
          // Trust Badges - Larger & More Visual
          Row(
            children: [
              Expanded(
                child: _buildTrustItem(
                  Icons.security_outlined,
                  l10n.footerBadgeSecure,
                  Colors.green.shade600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTrustItem(
                  Icons.local_shipping_outlined,
                  l10n.footerBadgeFast,
                  Colors.blue.shade600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTrustItem(
                  Icons.workspace_premium_outlined,
                  l10n.footerBadgeOrganic,
                  Colors.orange.shade600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTrustItem(
                  Icons.verified_user_outlined,
                  l10n.footerBadgeTrusted,
                  Colors.purple.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Brand & Support Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.empoweringFarmers,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildSocialIcon(
                          "assets/icons/facebook-circle-logo-png.png",
                          "https://www.facebook.com/krishikrantiorganics12/",
                          isFirst: true,
                        ),
                        _buildSocialIcon(
                          "assets/icons/1725819461instagram-logo.png",
                          "https://www.instagram.com/krishikranti_organics?igsh=MW83OTBpNjd0ODRxcA==",
                        ),
                        _buildSocialIcon(
                          "assets/icons/1701508703YouTube-Icon-PNG.png",
                          "https://www.youtube.com/@krishikrantiorganics",
                        ),
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
                    MetaAnalyticsService.logContactSupport(contactMethod: 'WhatsApp Home Footer');
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
                        Text(
                          l10n.expertHelp,
                          style: const TextStyle(
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.12), color.withOpacity(0.03)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.15), width: 1),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 8),
          TranslatableText(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(
    String assetPath,
    String urlString, {
    bool isFirst = false,
  }) {
    return InkWell(
      onTap: () async {
        HapticFeedback.lightImpact();
        final url = Uri.parse(urlString);
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          await launchUrl(url, mode: LaunchMode.platformDefault);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.fromLTRB(isFirst ? 0.0 : 8.0, 0.0, 8.0, 0.0),
        child: Image.asset(
          assetPath,
          width: 32,
          height: 32,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _RotatingSearchBar extends StatefulWidget {
  final AppLocalizations l10n;
  final ThemeData theme;

  const _RotatingSearchBar({required this.l10n, required this.theme});

  @override
  State<_RotatingSearchBar> createState() => _RotatingSearchBarState();
}

class _RotatingSearchBarState extends State<_RotatingSearchBar> {
  int _currentHintIndex = 0;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    _hintTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentHintIndex = (_currentHintIndex + 1) % 6;
        });
      }
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  List<String> _getSearchHints(AppLocalizations l10n) {
    return [
      l10n.searchHintFungicides,
      l10n.searchHintInsecticides,
      l10n.searchHintHerbicides,
      l10n.searchHintBioProducts,
      l10n.searchHintPgrs,
      l10n.searchHintFertilizers,
    ];
  }

  @override
  Widget build(BuildContext context) {
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
                  color: widget.theme.colorScheme.primary,
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
                    child: TranslatableText(
                      _getSearchHints(widget.l10n)[_currentHintIndex],
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
              ],
            ),
          ),
        ),
      ),
    );
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
