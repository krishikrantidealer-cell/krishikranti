import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:krishikranti/features/products/data/models/collection_model.dart';
import 'package:krishikranti/features/products/data/models/product_model.dart';
import 'package:krishikranti/features/products/data/models/banner_model.dart';
import 'package:krishikranti/core/favorite_service.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/widgets/home/home_section_title.dart';
import 'package:krishikranti/widgets/product_card.dart';
import 'package:krishikranti/screens/product_list_screen.dart';
import 'package:krishikranti/screens/product_detail_screen.dart';
import 'package:krishikranti/widgets/progressive_image.dart';
import 'package:krishikranti/core/dynamic_translation_service.dart';
import 'package:krishikranti/core/utils/translatable_text.dart';
import 'package:provider/provider.dart';
import 'package:krishikranti/core/profile_service.dart';
import 'package:krishikranti/core/utils/guest_barrier_util.dart';
import 'package:krishikranti/widgets/animated_heart.dart';

/// Grid view of products for a [Collection] containing direct products.
class HomeCollectionProductGrid extends StatelessWidget {
  final Collection collection;
  final FavoriteService favoriteService;
  final bool isDealerFirstChoice;
  final BannerModel? stripBanner;

  const HomeCollectionProductGrid({
    super.key,
    required this.collection,
    required this.favoriteService,
    this.isDealerFirstChoice = false,
    this.stripBanner,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final products = collection.products;

    if (products.isEmpty) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: DynamicTranslationService(),
      builder: (context, _) {
        final rawTitle = (collection.bannerTitle != null && collection.bannerTitle!.trim().isNotEmpty)
            ? collection.bannerTitle!
            : collection.name;
        final titleStr = rawTitle.isNotEmpty
            ? rawTitle
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: HomeSectionTitle(
                theme: theme,
                title: translatedTitle,
                onSeeAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductListScreen(
                        category: collection.name,
                        collection: collection.name,
                        isCollection: true,
                      ),
                    ),
                  );
                },
                seeAllLabel: l10n.seeAll,
                subtitle: translatedSubtitle,
                stripBanner: stripBanner,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDealerFirstChoice ? 3 : 2,
                  mainAxisExtent: isDealerFirstChoice ? 192 : 260,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  if (isDealerFirstChoice) {
                    return DealerChoiceProductCard(
                      key: ValueKey('col_${collection.id}_${product.id}'),
                      product: product,
                      category: collection.name,
                      index: index,
                      favoriteService: favoriteService,
                    );
                  }
                  return ProductCard(
                    key: ValueKey('col_${collection.id}_${product.id}'),
                    product: product,
                    category: collection.name,
                    isFavorite: favoriteService.isFavorite(product.id),
                    onFavoriteToggle: () {
                      HapticFeedback.mediumImpact();
                      favoriteService.toggleFavorite(
                        FavoriteProduct(
                          id: product.id,
                          name: product.title,
                          category: product.brandName ?? collection.name,
                          price: product.price.toStringAsFixed(0),
                          imageUrl: product.thumbnail,
                          weight: product.variants.isNotEmpty
                              ? product.variants.first.size
                              : 'N/A',
                        ),
                      );
                    },
                    index: index,
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

// ─── DealerChoiceProductCard (Compact 3-in-a-row Masterwork) ────────────────

class DealerChoiceProductCard extends StatefulWidget {
  final Product product;
  final String category;
  final int index;
  final FavoriteService favoriteService;

  const DealerChoiceProductCard({
    super.key,
    required this.product,
    required this.category,
    required this.index,
    required this.favoriteService,
  });

  @override
  State<DealerChoiceProductCard> createState() =>
      _DealerChoiceProductCardState();
}

class _DealerChoiceProductCardState extends State<DealerChoiceProductCard>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _borderController;
  late Animation<double> _scale;
  late Animation<double> _borderAngle;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );

    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _borderAngle = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _borderController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    _borderController.dispose();
    super.dispose();
  }

  void _navigateToDetail(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProductDetailScreen(
          product: widget.product,
          thumbnailUrl: widget.product.thumbnail,
          heroTag: 'dealer_choice_${widget.category}_${widget.product.id}',
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileService = Provider.of<ProfileService>(context);
    final isFavorite = widget.favoriteService.isFavorite(widget.product.id);
    final isKycComplete = profileService.user?.isKycComplete ?? false;

    double discountPercent = 0.0;
    if (isKycComplete &&
        widget.product.compareAtPrice > widget.product.price &&
        widget.product.compareAtPrice > 0) {
      discountPercent =
          ((widget.product.compareAtPrice - widget.product.price) /
                  widget.product.compareAtPrice) *
              100;
    }

    return AnimatedBuilder(
      animation: _borderAngle,
      builder: (context, child) {
        return CustomPaint(
          painter: _DealerBorderPainter(
            angle: _borderAngle.value,
            isPressed: _isPressed,
            borderRadius: 16,
          ),
          child: child,
        );
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: GestureDetector(
          onTapDown: (_) {
            _pressController.forward();
            setState(() => _isPressed = true);
          },
          onTapUp: (_) {
            _pressController.reverse();
            setState(() => _isPressed = false);
            _navigateToDetail(context);
          },
          onTapCancel: () {
            _pressController.reverse();
            setState(() => _isPressed = false);
          },
          child: Container(
            margin: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: const Color(0xFF298E4D)
                      .withValues(alpha: _isPressed ? 0.12 : 0.02),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14.5),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── 1. Image Stage with Green Radial Glow ──────────
                      Expanded(
                        flex: 10,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 0.8,
                              colors: [
                                Color(0xFFE8F7EC),
                                Color(0xFFFFFFFF),
                              ],
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Hero(
                                  tag:
                                      'dealer_choice_${widget.category}_${widget.product.id}',
                                  child: ProgressiveImage(
                                    thumbnailUrl: widget.product.thumbnail,
                                    imageUrl: widget.product.images.isNotEmpty
                                        ? widget.product.images.first
                                        : widget.product.thumbnail,
                                    fit: BoxFit.contain,
                                    padding: 6.0,
                                  ),
                                ),
                              ),
                              // Bottom gradient spotlight blending into text
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                height: 16,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0x00FFFFFF),
                                        Color(0xFAFFFFFF),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── 2. Compact Content Shelf ──────────────────────
                      Expanded(
                        flex: 10,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(6, 2, 6, 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Brand Tag
                                  Text(
                                    (widget.product.brandName ?? 'PREMIUM')
                                        .toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF298E4D),
                                      fontSize: 7,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  // Title
                                  TranslatableText(
                                    widget.product.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 9.5,
                                      height: 1.18,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),

                              // Price / Lock Row
                              profileService.isGuest
                                  ? _buildCompactLock('Login')
                                  : !isKycComplete
                                      ? _buildCompactLock('KYC')
                                      : Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Text(
                                              '₹${widget.product.price.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                color: Color(0xFF298E4D),
                                                fontWeight: FontWeight.w900,
                                                fontSize: 11.5,
                                                letterSpacing: -0.4,
                                              ),
                                            ),
                                            if (discountPercent > 0) ...[
                                              const SizedBox(width: 3),
                                              Text(
                                                '₹${widget.product.compareAtPrice.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade400,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w600,
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),

                              // ── 3. Compact CTA Button ─────────────────
                              _DealerCtaButton(
                                onTap: () => _navigateToDetail(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Top-Left Gold Ribbon CHOICE Badge
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4.5, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B)
                                .withValues(alpha: 0.35),
                            blurRadius: 4,
                            offset: const Offset(0, 1.5),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded,
                              color: Colors.white, size: 7.5),
                          SizedBox(width: 2),
                          Text(
                            'CHOICE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 6.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Top-Right Glass Heart Button
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Hero(
                      tag:
                          'heart_dealer_choice_${widget.category}_${widget.product.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                          child: AnimatedHeart(
                            isFavorite:
                                profileService.isGuest ? false : isFavorite,
                            onTap: () {
                              if (profileService.isGuest) {
                                GuestBarrierUtil.showGuestLoginDialog(context);
                                return;
                              }
                              HapticFeedback.mediumImpact();
                              widget.favoriteService.toggleFavorite(
                                FavoriteProduct(
                                  id: widget.product.id,
                                  name: widget.product.title,
                                  category: widget.product.brandName ??
                                      widget.category,
                                  price:
                                      widget.product.price.toStringAsFixed(0),
                                  imageUrl: widget.product.thumbnail,
                                  weight: widget.product.variants.isNotEmpty
                                      ? widget.product.variants.first.size
                                      : 'N/A',
                                ),
                              );
                            },
                            size: 12,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactLock(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 7.5, color: Colors.grey.shade600),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sweeping Gradient Border Painter ────────────────────────────────────────

class _DealerBorderPainter extends CustomPainter {
  final double angle;
  final bool isPressed;
  final double borderRadius;

  _DealerBorderPainter({
    required this.angle,
    required this.isPressed,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = SweepGradient(
      center: Alignment.center,
      startAngle: angle,
      endAngle: angle + 2 * math.pi,
      colors: const [
        Color(0xFF298E4D),
        Color(0xFF00BFA5),
        Color(0xFFF59E0B),
        Color(0xFF298E4D),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isPressed ? 2.0 : 1.2;

    final rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.8, 0.8, size.width - 1.6, size.height - 1.6),
      Radius.circular(borderRadius),
    );
    canvas.drawRRect(rRect, paint);
  }

  @override
  bool shouldRepaint(_DealerBorderPainter oldDelegate) =>
      oldDelegate.angle != angle || oldDelegate.isPressed != isPressed;
}

// ─── Dealer CTA Button ────────────────────────────────────────────────────────

class _DealerCtaButton extends StatefulWidget {
  final VoidCallback onTap;
  const _DealerCtaButton({required this.onTap});

  @override
  State<_DealerCtaButton> createState() => _DealerCtaButtonState();
}

class _DealerCtaButtonState extends State<_DealerCtaButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _arrowSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _arrowSlide = Tween<double>(begin: 0.0, end: 2.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: Container(
        height: 22,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF298E4D), Color(0xFF00BFA5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF298E4D).withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'View',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 3),
              AnimatedBuilder(
                animation: _arrowSlide,
                builder: (context, child) => Transform.translate(
                  offset: Offset(_arrowSlide.value, 0),
                  child: child,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

