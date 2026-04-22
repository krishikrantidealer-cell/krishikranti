import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/core/favorite_service.dart';
import 'package:krishikranti/core/cart_service.dart';
import 'package:krishikranti/core/profile_service.dart';
import 'package:provider/provider.dart';
import 'package:krishikranti/screens/profile_screen.dart';
import 'package:krishikranti/screens/cart_screen.dart';
import 'package:krishikranti/screens/product_list_screen.dart';
import 'package:krishikranti/screens/product_detail_screen.dart';
import 'package:krishikranti/screens/catalogue_screen.dart';
import 'package:krishikranti/screens/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Infinite loop PageController
  late final PageController _bannerController;
  int _currentBanner = 0;
  Timer? _bannerTimer;
  final FavoriteService _favoriteService = FavoriteService();

  final List<String> _bannerImages = [
    'https://images.unsplash.com/photo-1589927986089-35812388d1f4?auto=format&fit=crop&q=80&w=600',
    'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?auto=format&fit=crop&q=80&w=600',
    'https://images.unsplash.com/photo-1560493676-04071c5f467b?auto=format&fit=crop&q=80&w=600',
  ];

  final List<String> _categories = [
    "Fertilizers", "Pesticides", "Fungicides", "Seeds",
    "Growth", "Tools", "Organic", "Hardware", "Safety"
  ];

  @override
  void initState() {
    super.initState();
    _favoriteService.addListener(_onFavoriteChanged);
    // Starting at a high index for infinite-like scrolling
    _bannerController = PageController(initialPage: _bannerImages.length * 100);
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients) {
        _bannerController.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _favoriteService.removeListener(_onFavoriteChanged);
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  void _onFavoriteChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildHeader(context, theme, l10n),
              ),
              const SizedBox(height: 20),

              // SEARCH
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSearchBar(context, theme, l10n),
              ),
              const SizedBox(height: 20),

              // BANNER
              _buildBanner(context, theme),
              const SizedBox(height: 24),

              // CATEGORIES
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _sectionTitle(theme, l10n.categories, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CatalogueScreen()),
                  );
                }, l10n),
              ),
              const SizedBox(height: 12),
              _buildCategories(context, theme),
              const SizedBox(height: 24),

              // FEATURED PRODUCTS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _sectionTitle(theme, "Featured Products", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProductListScreen(category: "All")),
                  );
                }, l10n),
              ),
              const SizedBox(height: 16),

              // PRODUCTS GRID
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                  children: [
                    ProductCard(
                      name: "COXY-50",
                      category: "Fungicide",
                      weight: "500 ml",
                      price: "650",
                      imageUrl: "https://images.unsplash.com/photo-1589927986089-35812388d1f4?auto=format&fit=crop&q=80&w=300",
                      isFavorite: _favoriteService.isFavorite("COXY-50"),
                      onFavoriteToggle: () {
                        _favoriteService.toggleFavorite(FavoriteProduct(
                          name: "COXY-50",
                          category: "Fungicide",
                          price: "650",
                          imageUrl: "https://images.unsplash.com/photo-1589927986089-35812388d1f4?auto=format&fit=crop&q=80&w=300",
                          weight: "500 ml",
                        ));
                      },
                    ),
                    ProductCard(
                      name: "Zinc Power",
                      category: "Fertilizer",
                      weight: "1 kg",
                      price: "490",
                      imageUrl: "https://images.unsplash.com/photo-1625246333195-78d9c38ad449?auto=format&fit=crop&q=80&w=300",
                      isFavorite: _favoriteService.isFavorite("Zinc Power"),
                      onFavoriteToggle: () {
                        _favoriteService.toggleFavorite(FavoriteProduct(
                          name: "Zinc Power",
                          category: "Fertilizer",
                          price: "490",
                          imageUrl: "https://images.unsplash.com/photo-1625246333195-78d9c38ad449?auto=format&fit=crop&q=80&w=300",
                          weight: "1 kg",
                        ));
                      },
                    ),
                    ProductCard(
                      name: "Urea Premium",
                      category: "Fertilizer",
                      weight: "50 kg",
                      price: "290",
                      imageUrl: "https://images.unsplash.com/photo-1560493676-04071c5f467b?auto=format&fit=crop&q=80&w=300",
                      isFavorite: _favoriteService.isFavorite("Urea Premium"),
                      onFavoriteToggle: () {
                        _favoriteService.toggleFavorite(FavoriteProduct(
                          name: "Urea Premium",
                          category: "Fertilizer",
                          price: "290",
                          imageUrl: "https://images.unsplash.com/photo-1560493676-04071c5f467b?auto=format&fit=crop&q=80&w=300",
                          weight: "50 kg",
                        ));
                      },
                    ),
                    ProductCard(
                      name: "Organic Plus",
                      category: "Growth",
                      weight: "1 Litre",
                      price: "850",
                      imageUrl: "https://images.unsplash.com/photo-1589927986089-35812388d1f4?auto=format&fit=crop&q=80&w=300",
                      isFavorite: _favoriteService.isFavorite("Organic Plus"),
                      onFavoriteToggle: () {
                        _favoriteService.toggleFavorite(FavoriteProduct(
                          name: "Organic Plus",
                          category: "Growth",
                          price: "850",
                          imageUrl: "https://images.unsplash.com/photo-1589927986089-35812388d1f4?auto=format&fit=crop&q=80&w=300",
                          weight: "1 Litre",
                        ));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    return Consumer<ProfileService>(
      builder: (context, profile, child) {
        return Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    profile.avatarLetter,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.welcome,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    profile.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
              icon: Consumer<CartService>(
                builder: (context, cart, child) {
                  final count = cart.totalCount;
                  if (count == 0) {
                    return Icon(Icons.shopping_cart_outlined, color: theme.colorScheme.primary);
                  }
                  return Badge(
                    label: Text(count > 99 ? '99+' : count.toString()),
                    child: Icon(Icons.shopping_cart_outlined, color: theme.colorScheme.primary),
                  );
                },
              ),
            )
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
      },
      child: AbsorbPointer(
        child: TextField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: "Search products",
            prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _bannerController,
            itemBuilder: (context, index) {
              final i = index % _bannerImages.length;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProductListScreen(category: "All")),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(_bannerImages[i], fit: BoxFit.cover),
                  ),
                ),
              );
            },
            onPageChanged: (index) {
              setState(() {
                _currentBanner = index % _bannerImages.length;
              });
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _bannerImages.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.all(4),
              width: _currentBanner == i ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentBanner == i ? theme.colorScheme.primary : theme.colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _sectionTitle(ThemeData theme, String title, VoidCallback onSeeAll, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              // Green block style
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onSeeAll,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "See All",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios, size: 12, color: theme.colorScheme.primary),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildCategories(BuildContext context, ThemeData theme) {
    return SizedBox(
      height: 45,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, i) {
          return FilterChip(
            label: Text(_categories[i]),
            labelStyle: theme.textTheme.bodySmall?.copyWith(
              color: i == 0 ? Colors.white : theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            selected: i == 0,
            selectedColor: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.05),
            onSelected: (bool value) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProductListScreen(category: _categories[i])),
              );
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
            ),
            showCheckmark: false,
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: _categories.length,
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String name, category, weight, price, imageUrl;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const ProductCard({
    super.key,
    required this.name,
    required this.category,
    required this.weight,
    required this.price,
    required this.imageUrl,
    this.isFavorite = false,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProductDetailScreen(productName: name)),
        );
      },
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section - Full width/expanded & Cover style
            Expanded(
              flex: 6,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover, // Cover style
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onFavoriteToggle,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                          size: 18,
                          color: isFavorite ? Colors.red : Colors.grey.shade600,
                        ),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            weight,
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "₹$price",
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 30,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ProductDetailScreen(productName: name)),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: Text(AppLocalizations.of(context)!.add, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
    );
  }
}
