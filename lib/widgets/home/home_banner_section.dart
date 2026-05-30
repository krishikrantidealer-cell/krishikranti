import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:krishikranti/features/products/data/models/banner_model.dart';
import 'package:krishikranti/screens/product_list_screen.dart';

/// Displays the hero banner carousel with dot indicators.
///
/// State ownership stays in [HomeScreen]; this widget is purely presentational.
class HomeBannerSection extends StatelessWidget {
  final List<BannerModel> banners;
  final ValueNotifier<int> currentBanner;

  const HomeBannerSection({
    super.key,
    required this.banners,
    required this.currentBanner,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imagesToDisplay = banners.map((b) => b.imageUrl).toList();

    if (imagesToDisplay.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        CarouselSlider.builder(
          key: ValueKey(imagesToDisplay.length),
          itemCount: imagesToDisplay.length,
          itemBuilder: (context, index, realIndex) {
            final imageUrl = imagesToDisplay[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (index < banners.length) {
                    final banner = banners[index];
                    if (banner.redirectType == 'category' &&
                        banner.redirectTarget != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductListScreen(
                            category: banner.redirectTarget!,
                          ),
                        ),
                      );
                      return;
                    }
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ProductListScreen(category: 'All'),
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
                    child: imageUrl.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (_, __) =>
                                Container(color: Colors.grey[200]),
                            errorWidget: (_, __, ___) => const Center(
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
            onPageChanged: (index, _) {
              currentBanner.value = index;
            },
          ),
        ),
        ValueListenableBuilder<int>(
          valueListenable: currentBanner,
          builder: (_, currentIndex, __) {
            if (imagesToDisplay.length <= 1) return const SizedBox.shrink();
            final safeIndex =
                currentIndex < imagesToDisplay.length ? currentIndex : 0;
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
}
