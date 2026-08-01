import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:krishikranti/features/products/data/models/category_model.dart';
import 'package:krishikranti/features/products/data/models/product_model.dart';
import 'package:krishikranti/features/products/data/models/banner_model.dart';
import 'package:krishikranti/core/favorite_service.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/widgets/home/home_section_title.dart';
import 'package:krishikranti/widgets/product_card.dart';
import 'package:krishikranti/screens/product_list_screen.dart';

class HomeCategoryProductRow extends StatefulWidget {
  final Category category;
  final List<Product> products;
  final FavoriteService favoriteService;
  final String premiumSubtitle;
  final String seeAllLabel;
  final String localizedTitle;
  final BannerModel? stripBanner;

  const HomeCategoryProductRow({
    super.key,
    required this.category,
    required this.products,
    required this.favoriteService,
    required this.premiumSubtitle,
    required this.seeAllLabel,
    required this.localizedTitle,
    this.stripBanner,
  });

  @override
  State<HomeCategoryProductRow> createState() => _HomeCategoryProductRowState();
}

class _HomeCategoryProductRowState extends State<HomeCategoryProductRow> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  Ticker? _ticker;
  Timer? _resumeTimer;
  bool _isUserInteracting = false;
  double _lastElapsedMs = 0;
  
  static const double _itemFullWidth = 184.0;
  static const double _pixelsPerMs = 0.035; // ~35 pixels per second

  @override
  void initState() {
    super.initState();
    // Start at a very large middle offset for virtual infinity
    _scrollController = ScrollController(initialScrollOffset: 1000 * _itemFullWidth);
    
    _ticker = createTicker(_onTick);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ticker?.start();
    });
  }

  void _onTick(Duration elapsed) {
    if (!mounted || _isUserInteracting || !_scrollController.hasClients) {
      _lastElapsedMs = elapsed.inMilliseconds.toDouble();
      return;
    }

    final double elapsedMs = elapsed.inMilliseconds.toDouble();
    if (_lastElapsedMs == 0) {
      _lastElapsedMs = elapsedMs;
      return;
    }

    final double deltaMs = elapsedMs - _lastElapsedMs;
    _lastElapsedMs = elapsedMs;

    final double movement = deltaMs * _pixelsPerMs;
    _scrollController.jumpTo(_scrollController.offset + movement);
  }

  void _handlePointerDown(_) {
    _isUserInteracting = true;
    _resumeTimer?.cancel();
  }

  void _handlePointerUp(_) {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        // Reset the last elapsed time to avoid a huge "jump" after the pause
        _lastElapsedMs = 0; 
        setState(() => _isUserInteracting = false);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _resumeTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: HomeSectionTitle(
            theme: theme,
            title: (widget.category.bannerTitle != null && widget.category.bannerTitle!.trim().isNotEmpty)
                ? widget.category.bannerTitle!
                : widget.localizedTitle,
            onSeeAll: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductListScreen(
                    category: widget.category.name,
                    categoryId: widget.category.id,
                    categoryData: widget.category,
                  ),
                ),
              );
            },
            seeAllLabel: widget.seeAllLabel,
            subtitle: widget.premiumSubtitle,
            stripBanner: widget.stripBanner,
          ),
        ),
        SizedBox(
          height: 275,
          child: Listener(
            onPointerDown: _handlePointerDown,
            onPointerUp: _handlePointerUp,
            onPointerCancel: _handlePointerUp,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              itemExtent: _itemFullWidth,
              itemCount: 10000, 
              cacheExtent: 1500,
              itemBuilder: (context, index) {
                final product = widget.products[index % widget.products.length];
                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: ProductCard(
                    key: ValueKey('cat_${widget.category.id}_${product.id}_$index'),
                    product: product,
                    category: widget.category.name,
                    animateEntrance: false,
                    isFavorite: widget.favoriteService.isFavorite(product.id),
                    onFavoriteToggle: () => widget.favoriteService.toggleFavorite(
                      FavoriteProduct(
                        id: product.id,
                        name: product.title,
                        category: product.brandName ?? widget.category.name,
                        price: product.price.toStringAsFixed(0),
                        imageUrl: product.thumbnail,
                        weight: product.variants.isNotEmpty
                            ? product.variants.first.size
                            : 'N/A',
                      ),
                    ),
                    index: index % widget.products.length,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class HomeCategoryProductRowSkeleton extends StatelessWidget {
  const HomeCategoryProductRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, const Color(0xFF38B058)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 140,
                height: 22,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 275,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, __) => Container(
              width: 170,
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ),
      ],
    );
  }
}

class HomeCategorySection extends StatelessWidget {
  final Category category;
  final List<Product> products;
  final FavoriteService favoriteService;
  final String localizedTitle;
  final BannerModel? stripBanner;

  const HomeCategorySection({
    super.key,
    required this.category,
    required this.products,
    required this.favoriteService,
    required this.localizedTitle,
    this.stripBanner,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return HomeCategoryProductRow(
      category: category,
      products: products,
      favoriteService: favoriteService,
      premiumSubtitle: l10n.premiumFarmingEssentials,
      seeAllLabel: l10n.seeAll,
      localizedTitle: localizedTitle,
      stripBanner: stripBanner,
    );
  }
}
