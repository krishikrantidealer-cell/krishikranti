import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:krishikranti/features/products/data/models/product_model.dart';
import 'package:krishikranti/core/favorite_service.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/widgets/home/home_section_title.dart';
import 'package:krishikranti/widgets/product_card.dart';
import 'package:krishikranti/screens/product_list_screen.dart';

class HomeFeaturedSection extends StatefulWidget {
  final List<Product> products;
  final FavoriteService favoriteService;

  const HomeFeaturedSection({
    super.key,
    required this.products,
    required this.favoriteService,
  });

  @override
  State<HomeFeaturedSection> createState() => _HomeFeaturedSectionState();
}

class _HomeFeaturedSectionState extends State<HomeFeaturedSection> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  Ticker? _ticker;
  Timer? _resumeTimer;
  bool _isUserInteracting = false;
  double _lastElapsedMs = 0;
  
  static const double _itemFullWidth = 184.0;
  static const double _pixelsPerMs = 0.035;

  @override
  void initState() {
    super.initState();
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
    final l10n = AppLocalizations.of(context)!;
    if (widget.products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
          child: HomeSectionTitle(
            theme: theme,
            title: l10n.featuredProducts,
            onSeeAll: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProductListScreen(
                    category: 'Featured',
                    isCollection: false,
                    isFeatured: true,
                  ),
                ),
              );
            },
            seeAllLabel: l10n.seeAll,
            subtitle: l10n.premiumFarmingEssentials,
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
                    key: ValueKey('featured_${product.id}_$index'),
                    product: product,
                    category: 'Featured',
                    animateEntrance: false,
                    isFavorite: widget.favoriteService.isFavorite(product.id),
                    onFavoriteToggle: () => widget.favoriteService.toggleFavorite(
                      FavoriteProduct(
                        id: product.id,
                        name: product.title,
                        category: product.brandName ?? 'Product',
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
