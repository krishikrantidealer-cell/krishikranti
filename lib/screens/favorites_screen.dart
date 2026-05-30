import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/core/favorite_service.dart';
import 'package:krishikranti/core/cart_service.dart';
import 'package:krishikranti/screens/product_detail_screen.dart';
import 'package:krishikranti/screens/product_list_screen.dart';
import 'package:krishikranti/features/products/data/models/product_model.dart';
import 'package:krishikranti/widgets/animated_heart.dart';
import 'package:krishikranti/widgets/progressive_image.dart';
import 'package:krishikranti/core/utils/translatable_text.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoriteService _favoriteService = FavoriteService();
  bool _isPopping = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _favoriteService.syncWithBackend());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) setState(() => _isPopping = true);
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: ListenableBuilder(
            listenable: _favoriteService,
            builder: (context, _) {
              final favorites = _favoriteService.favorites;

              if (favorites.isEmpty && !_favoriteService.isSyncing) {
                return _buildEmptyState(context, l10n);
              }

              return AnimationLimiter(
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    _buildSliverAppBar(context, favorites.length, l10n, theme),
                    if (_favoriteService.isSyncing && favorites.isEmpty)
                      const SliverFillRemaining(
                        child: Center(child: CupertinoActivityIndicator()),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 12,
                                mainAxisExtent: 228,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final product = favorites[index];
                            return AnimationConfiguration.staggeredGrid(
                              position: index,
                              duration: const Duration(milliseconds: 375),
                              columnCount: 2,
                              child: ScaleAnimation(
                                child: FadeInAnimation(
                                  child: RepaintBoundary(
                                    child: _FavoriteProductCard(
                                      product: product,
                                      isPopping: _isPopping,
                                      favoriteService: _favoriteService,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }, childCount: favorites.length),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    int count,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white.withOpacity(0.92),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(CupertinoIcons.back, color: Colors.black87, size: 24),
        onPressed: () {
          setState(() => _isPopping = true);
          Navigator.pop(context);
        },
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.favorites,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (count > 0)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.trash,
                  color: Colors.red.shade400,
                  size: 18,
                ),
              ),
              onPressed: () => _showClearConfirmation(context),
            ),
          ),
      ],
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.lightImpact();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.clearWishlistTitle),
        content: Text(l10n.clearWishlistConfirm),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              HapticFeedback.heavyImpact();
              _favoriteService.clearAll();
              Navigator.pop(context);
            },
            child: Text(l10n.clearAll),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                Lottie.asset(
                  'assets/animations/favorites_empty.json',
                  height: 200,
                  repeat: true,
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.heart_slash,
                      size: 60,
                      color: Colors.red.shade300,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              l10n.wishlistEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.saveFavoritesInstruction,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 36),
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
                    HapticFeedback.mediumImpact();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ProductListScreen(category: "All"),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.search,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        l10n.exploreShop,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
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
    );
  }
}

class _FavoriteProductCard extends StatefulWidget {
  final FavoriteProduct product;
  final bool isPopping;
  final FavoriteService favoriteService;

  const _FavoriteProductCard({
    required this.product,
    required this.isPopping,
    required this.favoriteService,
  });

  @override
  State<_FavoriteProductCard> createState() => _FavoriteProductCardState();
}

class _FavoriteProductCardState extends State<_FavoriteProductCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final heavyProduct = Product(
      id: widget.product.id,
      title: widget.product.name,
      thumbnail: widget.product.imageUrl,
      minPrice: double.tryParse(widget.product.price) ?? 0,
      images: [widget.product.imageUrl],
      brandName: widget.product.category,
      variants: [
        Variant(
          id: "v_${widget.product.id}",
          size: widget.product.weight,
          price: double.tryParse(widget.product.price) ?? 0,
          compareAtPrice: 0,
        ),
      ],
    );

    return Consumer<CartService>(
      builder: (context, cart, child) {
        final isInCart = cart.items.any(
          (item) => item.productId == widget.product.id,
        );

        return GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 400),
                pageBuilder: (context, animation, secondaryAnimation) =>
                    ProductDetailScreen(
                      product: heavyProduct,
                      thumbnailUrl: widget.product.imageUrl,
                    ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
              ),
            );
          },
          child: AnimatedScale(
            scale: _isPressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 12,
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            color: Colors.white,
                            child: HeroMode(
                              enabled: !widget.isPopping,
                              child: Hero(
                                tag: 'product_${widget.product.id}',
                                child: ProgressiveImage(
                                  thumbnailUrl: widget.product.imageUrl,
                                  imageUrl: widget.product.imageUrl,
                                  fit: BoxFit.contain,
                                  padding: 10.0,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.08,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: TranslatableText(
                                widget.product.category.toUpperCase(),
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
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
                                  isFavorite: true,
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    widget.favoriteService.toggleFavorite(
                                      widget.product,
                                    );
                                  },
                                  size: 14,
                                  backgroundColor: Colors.white.withOpacity(
                                    0.85,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 9,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TranslatableText(
                                  widget.product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    height: 1.15,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                TranslatableText(
                                  widget.product.weight,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Text(
                                    "₹${widget.product.price}",
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        transitionDuration: const Duration(
                                          milliseconds: 400,
                                        ),
                                        pageBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                            ) => ProductDetailScreen(
                                              product: heavyProduct,
                                              thumbnailUrl:
                                                  widget.product.imageUrl,
                                            ),
                                        transitionsBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                              child,
                                            ) {
                                              return FadeTransition(
                                                opacity: animation,
                                                child: child,
                                              );
                                            },
                                      ),
                                    );
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isInCart
                                            ? [
                                                const Color(0xFF2E7D32),
                                                const Color(0xFF1B5E20),
                                              ]
                                            : [
                                                theme.colorScheme.primary,
                                                theme.colorScheme.primary
                                                    .withOpacity(0.85),
                                              ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.colorScheme.primary
                                              .withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          isInCart ? l10n.added : l10n.add,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          isInCart
                                              ? CupertinoIcons.check_mark
                                              : CupertinoIcons.cart_badge_plus,
                                          color: Colors.white,
                                          size: 10,
                                        ),
                                      ],
                                    ),
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
          ),
        );
      },
    );
  }
}
