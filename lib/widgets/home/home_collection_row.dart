import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:krishikranti/features/products/data/models/collection_model.dart';
import 'package:krishikranti/core/dynamic_translation_service.dart';
import 'package:krishikranti/core/utils/translatable_text.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/widgets/home/home_section_title.dart';
import 'package:krishikranti/screens/product_list_screen.dart';
import 'package:krishikranti/screens/sub_collections_screen.dart';

/// Horizontal scrolling sub-collection row for a single [Collection].
///
/// Uses [ListenableBuilder] + [DynamicTranslationService] for live translation
/// of the collection title and subtitle.
class HomeCollectionRow extends StatelessWidget {
  final Collection collection;

  const HomeCollectionRow({super.key, required this.collection});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final subCollections = collection.subCollections
        .where((s) => s.isActive)
        .toList();
    if (subCollections.isEmpty) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: DynamicTranslationService(),
      builder: (context, _) {
        final titleStr = collection.name.isNotEmpty
            ? collection.name
            : l10n.collections;
        final translatedTitle = titleStr == l10n.collections
            ? titleStr
            : context.tr(titleStr);
        if (titleStr != l10n.collections && titleStr.isNotEmpty) {
          DynamicTranslationService().ensureTranslated(titleStr);
        }

        final subtitleStr = collection.description?.isNotEmpty == true
            ? collection.description!
            : l10n.exploreCollection(collection.name);
        String translatedSubtitle;
        if (collection.description?.isNotEmpty == true) {
          translatedSubtitle = context.tr(subtitleStr);
          DynamicTranslationService().ensureTranslated(subtitleStr);
        } else {
          final translatedName = context.tr(collection.name);
          DynamicTranslationService().ensureTranslated(collection.name);
          translatedSubtitle = l10n.exploreCollection(translatedName);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: HomeSectionTitle(
                theme: theme,
                title: translatedTitle,
                onSeeAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SubCollectionsScreen(collection: collection),
                    ),
                  );
                },
                seeAllLabel: l10n.seeAll,
                subtitle: translatedSubtitle,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 125,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: subCollections.length,
                separatorBuilder: (_, __) => const SizedBox(width: 20),
                itemBuilder: (context, index) {
                  final subCrop = subCollections[index];
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductListScreen(
                            category: subCrop.name,
                            collection: subCrop.name,
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
                                theme.colorScheme.primary
                                    .withValues(alpha: 0.25),
                                theme.colorScheme.primary
                                    .withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.15),
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
                              child: Container(
                                color: Colors.grey[100],
                                child: subCrop.image != null &&
                                        subCrop.image!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: subCrop.image!,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                          color: Colors.grey[100],
                                          child: const Center(
                                            child: CircularProgressIndicator
                                                .adaptive(strokeWidth: 2),
                                          ),
                                        ),
                                        errorWidget: (_, __, ___) => const Icon(
                                          Icons.eco,
                                          color: Colors.green,
                                          size: 30,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.eco,
                                        color: Colors.green,
                                        size: 30,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TranslatableText(
                          subCrop.name,
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
      },
    );
  }
}

/// Skeleton placeholder for a collection row.
class HomeCollectionRowSkeleton extends StatelessWidget {
  final String title;

  const HomeCollectionRowSkeleton({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 125,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(width: 20),
            itemBuilder: (_, __) => Container(
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
}
