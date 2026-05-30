import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:krishikranti/features/products/data/models/category_model.dart';
import 'package:krishikranti/features/products/data/models/product_model.dart';
import 'package:krishikranti/core/favorite_service.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/widgets/home/home_section_title.dart';
import 'package:krishikranti/widgets/product_card.dart';
import 'package:krishikranti/screens/product_list_screen.dart';

/// Horizontal scrolling product row for a single [Category].
///
/// Renders a section header with "See All" navigation and a lazy
/// horizontal [ListView] of [ProductCard]s.
class HomeCategoryProductRow extends StatelessWidget {
  final Category category;
  final List<Product> products;
  final FavoriteService favoriteService;
  final String premiumSubtitle;
  final String seeAllLabel;
  final String localizedTitle;

  const HomeCategoryProductRow({
    super.key,
    required this.category,
    required this.products,
    required this.favoriteService,
    required this.premiumSubtitle,
    required this.seeAllLabel,
    required this.localizedTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: HomeSectionTitle(
            theme: theme,
            title: localizedTitle,
            onSeeAll: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductListScreen(
                    category: category.name,
                    categoryId: category.id,
                    categoryData: category,
                  ),
                ),
              );
            },
            seeAllLabel: seeAllLabel,
            subtitle: premiumSubtitle,
          ),
        ),
        SizedBox(
          height: 275,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: 170,
                child: ProductCard(
                  key: ValueKey('cat_${category.id}_${product.id}'),
                  product: product,
                  category: category.name,
                  isFavorite: favoriteService.isFavorite(product.id),
                  onFavoriteToggle: () {
                    HapticFeedback.mediumImpact();
                    favoriteService.toggleFavorite(
                      FavoriteProduct(
                        id: product.id,
                        name: product.title,
                        category: product.brandName ?? category.name,
                        price: product.price.toStringAsFixed(0),
                        imageUrl: product.thumbnail,
                        weight: product.variants.isNotEmpty
                            ? product.variants.first.size
                            : 'N/A',
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
}

/// Skeleton placeholder shown while category products are loading.
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
                    colors: [
                      theme.colorScheme.primary,
                      const Color(0xFF38B058),
                    ],
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
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
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
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Convenience wrapper that reads [AppLocalizations] and delegates to
/// [HomeCategoryProductRow].
class HomeCategorySection extends StatelessWidget {
  final Category category;
  final List<Product> products;
  final FavoriteService favoriteService;
  final String localizedTitle;

  const HomeCategorySection({
    super.key,
    required this.category,
    required this.products,
    required this.favoriteService,
    required this.localizedTitle,
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
    );
  }
}
