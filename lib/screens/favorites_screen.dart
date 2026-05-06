import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/core/favorite_service.dart';
import 'package:krishikranti/screens/product_detail_screen.dart';
import 'package:krishikranti/screens/product_list_screen.dart';
import 'package:krishikranti/features/products/data/models/product_model.dart';
import 'package:krishikranti/widgets/animated_heart.dart';

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
    // Use microtask to ensure sync doesn't clash with the initial build frame
    Future.microtask(() => _favoriteService.syncWithBackend());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAF8),
        body: ListenableBuilder(
          listenable: _favoriteService,
          builder: (context, _) {
            final favorites = _favoriteService.favorites;

            if (favorites.isEmpty && !_favoriteService.isSyncing) {
              return _buildEmptyState(context, l10n);
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(context, favorites.length, l10n),
                if (_favoriteService.isSyncing && favorites.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: CupertinoActivityIndicator()),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 245,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final product = favorites[index];
                        return _buildAdvancedCard(
                          context,
                          index,
                          product,
                          theme,
                        );
                      }, childCount: favorites.length),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    int count,
    AppLocalizations l10n,
  ) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          CupertinoIcons.chevron_left,
          color: Colors.black87,
          size: 22,
        ),
        onPressed: () {
          setState(() => _isPopping = true);
          Navigator.pop(context);
        },
      ),
      title: Text(
        l10n.favorites,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 18,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        if (count > 0)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(
                CupertinoIcons.trash,
                color: Colors.redAccent,
                size: 20,
              ),
              onPressed: () {
                _showClearConfirmation(context);
              },
            ),
          ),
      ],
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Clear Wishlist"),
        content: const Text(
          "Are you sure you want to remove all items from your favorites?",
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              _favoriteService.clearAll();
              Navigator.pop(context);
              HapticFeedback.heavyImpact();
            },
            child: const Text("Clear All"),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedCard(
    BuildContext context,
    int index,
    FavoriteProduct product,
    ThemeData theme,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 80)),
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
      child: GestureDetector(
        onTap: () {
          final heavyProduct = Product(
            id: product.id,
            title: product.name,
            thumbnail: product.imageUrl,
            minPrice: double.tryParse(product.price) ?? 0,
            images: [product.imageUrl],
            brandName: product.category,
            variants: [
              Variant(
                id: "v_${product.id}",
                size: product.weight,
                price: double.tryParse(product.price) ?? 0,
                compareAtPrice: 0,
              ),
            ],
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                product: heavyProduct,
                thumbnailUrl: product.imageUrl,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 12,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: HeroMode(
                          enabled: !_isPopping,
                          child: Hero(
                            tag: 'product_${product.id}',
                            transitionOnUserGestures: true,
                            child: Container(
                              color: Colors.white,
                              padding: const EdgeInsets.all(10),
                              child: Image.network(
                                product.imageUrl,
                                fit: BoxFit.contain,
                                key: ValueKey('fav_img_${product.id}'),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: AnimatedHeart(
                        isFavorite: true,
                        onTap: () => _favoriteService.toggleFavorite(product),
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 8,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            product.weight,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "₹${product.price}",
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
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

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/favorites_empty.json',
              height: 220,
              repeat: true,
            ),
            const SizedBox(height: 20),
            const Text(
              "Your heart is empty!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Save your favorite farming essentials here and access them anytime instantly.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            _buildModernButton(
              context,
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const ProductListScreen(category: "All"),
                ),
              ),
              text: "Explore Shop",
              icon: CupertinoIcons.search,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernButton(
    BuildContext context, {
    required VoidCallback onPressed,
    required String text,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onPressed();
      },
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black87, size: 22),
      ),
    );
  }
}
