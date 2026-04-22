import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/core/favorite_service.dart';
import 'package:krishikranti/screens/product_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoriteService _favoriteService = FavoriteService();

  @override
  void initState() {
    super.initState();
    _favoriteService.addListener(_onFavoriteChanged);
  }

  @override
  void dispose() {
    _favoriteService.removeListener(_onFavoriteChanged);
    super.dispose();
  }

  void _onFavoriteChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final favorites = _favoriteService.favorites;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.favorites,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: favorites.isEmpty
          ? _buildEmptyState()
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.7,
              ),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final product = favorites[index];
                return _FavoriteCard(product: product);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.heart, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "No favorites yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            "Start liking products to see them here",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final FavoriteProduct product;

  const _FavoriteCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favoriteService = FavoriteService();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productName: product.name),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(product.imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => favoriteService.toggleFavorite(product),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.heart_fill, size: 18, color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    product.category,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "₹${product.price}",
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Icon(CupertinoIcons.right_chevron, size: 14, color: Colors.grey.shade400),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
