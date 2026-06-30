import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:krishikranti/features/products/data/models/product_model.dart';
import 'package:krishikranti/screens/product_detail_screen.dart';
import 'package:krishikranti/widgets/progressive_image.dart';
import 'package:krishikranti/widgets/animated_heart.dart';
import 'package:provider/provider.dart';
import 'package:krishikranti/core/profile_service.dart';
import 'package:krishikranti/core/utils/translatable_text.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final String category;
  final bool isFavorite;
  final bool isPopping;
  final int index;
  final VoidCallback onFavoriteToggle;
  final bool isGridView;
  final String? heroTag;

  const ProductCard({
    super.key,
    required this.product,
    required this.category,
    required this.isFavorite,
    this.isPopping = false,
    this.index = 0,
    required this.onFavoriteToggle,
    this.isGridView = true,
    this.heroTag,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _appearController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  IconData _getVariantUnitIcon(String unit) {
    switch (unit.toLowerCase()) {
      case 'lit':
      case 'l':
      case 'ml':
        return Icons.water_drop_outlined;
      case 'kg':
      case 'g':
      case 'gm':
        return Icons.scale_outlined;
      case 'pcs':
      case 'piece':
      case 'pieces':
      default:
        return Icons.inventory_2_outlined;
    }
  }

  String? _getPackConfig(String sizeStr) {
    final match = RegExp(r'\(([^)]+)\)').firstMatch(sizeStr);
    return match?.group(1);
  }

  String _getCleanSize(String sizeStr) {
    final idx = sizeStr.indexOf('(');
    if (idx != -1) {
      return sizeStr.substring(0, idx).trim();
    }
    return sizeStr.trim();
  }

  String _getFormattedVolumeDetail(Variant variant) {
    final String baseUnit = variant.basePackingUnit;
    final idx = variant.size.indexOf('(');
    final String packSize = idx != -1
        ? variant.size.substring(0, idx).trim()
        : variant.size.trim();

    String? configName =
        variant.basePacking != null && variant.basePacking!.isNotEmpty
        ? variant.basePacking
        : null;

    if (configName == null && idx != -1) {
      final match = RegExp(r'\(([^)]+)\)').firstMatch(variant.size);
      configName = match?.group(1);
    }

    final bool isKg = baseUnit == 'kg';
    final bool isPcs = baseUnit == 'pcs';
    final String unitSuffix = isPcs
        ? "Pcs"
        : isKg
        ? "Kg"
        : "L";

    final String formattedVol = variant.packVolume % 1 == 0
        ? variant.packVolume.toInt().toString()
        : variant.packVolume.toStringAsFixed(
            variant.packVolume < 1
                ? (variant.packVolume * 100 % 10 == 0 ? 1 : 2)
                : 1,
          );

    if (configName == null || configName.toLowerCase() == "single") {
      if (variant.packVolume > 1.0) {
        configName = "$formattedVol $unitSuffix";
      } else {
        return packSize;
      }
    }

    return "$packSize x $configName = $formattedVol $unitSuffix";
  }

  Widget _buildVariantDetails(
    Variant variant,
    ThemeData theme, {
    required bool isGridView,
  }) {
    final displayDetail = _getFormattedVolumeDetail(variant);

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Size Tag (shows packaging detail or size)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade200, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getVariantUnitIcon(variant.basePackingUnit),
                size: 10,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 3),
              TranslatableText(
                displayDetail,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: isGridView ? 8.5 : 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _appearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _appearController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _appearController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );

    final delay = (widget.index % 6) * 60; // 60ms delay per index
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) {
        _appearController.forward();
      }
    });
  }

  @override
  void dispose() {
    _appearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _appearController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(scale: _scaleAnimation.value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  ProductDetailScreen(
                    product: widget.product,
                    thumbnailUrl: widget.product.thumbnail,
                    heroTag:
                        widget.heroTag ??
                        'product_${widget.category}_${widget.product.id}',
                  ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            ),
          );
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: widget.isGridView
              ? KeyedSubtree(
                  key: const ValueKey('grid_card_layout'),
                  child: _buildGridCard(context, theme),
                )
              : KeyedSubtree(
                  key: const ValueKey('list_card_layout'),
                  child: _buildListCard(context, theme),
                ),
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, ThemeData theme) {
    final profileService = Provider.of<ProfileService>(context);
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

    final isOutOfStock =
        widget.product.availabilityStatus?.toLowerCase() == "out of stock" ||
        widget.product.availabilityStatus?.toLowerCase() == "out_of_stock";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: Colors.white,
                    child: Stack(
                      children: [
                        Center(
                          child: HeroMode(
                            enabled: !widget.isPopping,
                            child: Hero(
                              tag:
                                  widget.heroTag ??
                                  'product_${widget.category}_${widget.product.id}',
                              child: ProgressiveImage(
                                thumbnailUrl: widget.product.thumbnail,
                                imageUrl: widget.product.images.isNotEmpty
                                    ? widget.product.images.first
                                    : widget.product.thumbnail,
                                fit: BoxFit.contain,
                                padding: 12.0,
                              ),
                            ),
                          ),
                        ),
                        if (isOutOfStock)
                          Container(
                            color: Colors.black.withOpacity(0.4),
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 4,
                                    sigmaY: 4,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    color: Colors.black.withOpacity(0.3),
                                    child: const Text(
                                      "SOLD OUT",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (discountPercent > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFA9527),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "${discountPercent.toStringAsFixed(0)}% OFF",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                          Expanded(
                            child: TranslatableText(
                              widget.product.brandName?.toUpperCase() ??
                                  "AGRI PREMIUM",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TranslatableText(
                        widget.product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 2),
                      TranslatableText(
                        widget.product.technicalName ?? "High efficacy formula",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (widget.product.lowestPriceVariant != null) ...[
                        const SizedBox(height: 6),
                        _buildVariantDetails(
                          widget.product.lowestPriceVariant!,
                          theme,
                          isGridView: true,
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isKycComplete)
                                  Text(
                                    "KYC Required",
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  )
                                else
                                  Row(
                                    children: [
                                      Text(
                                        "₹${widget.product.price.toStringAsFixed(0)}",
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15.5,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      if (discountPercent > 0) ...[
                                        const SizedBox(width: 4),
                                        Text(
                                          "₹${widget.product.compareAtPrice.toStringAsFixed(0)}",
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          if (isKycComplete)
                            Container(
                              height: 30,
                              width: 30,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.primary.withOpacity(0.85),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.24),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                CupertinoIcons.right_chevron,
                                color: Colors.white,
                                size: 13,
                              ),
                            )
                          else
                            Container(
                              height: 30,
                              width: 30,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                CupertinoIcons.lock_fill,
                                color: Colors.grey,
                                size: 11,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.product.averageRating > 0)
              Positioned(
                top: 8,
                left: 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.72),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFA9527),
                            size: 11,
                          ),
                          const SizedBox(width: 2.5),
                          Text(
                            widget.product.averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontWeight: FontWeight.w900,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
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
                  tag: widget.heroTag != null
                      ? 'heart_${widget.heroTag}'
                      : 'heart_product_${widget.category}_${widget.product.id}',
                  child: AnimatedHeart(
                    isFavorite: widget.isFavorite,
                    onTap: widget.onFavoriteToggle,
                    size: 16,
                    backgroundColor: Colors.white.withOpacity(0.85),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context, ThemeData theme) {
    final profileService = Provider.of<ProfileService>(context);
    final isKycComplete = profileService.user?.isKycComplete ?? false;
    double discountPercent = 0.0;
    double savingsAmount = 0.0;
    if (isKycComplete &&
        widget.product.compareAtPrice > widget.product.price &&
        widget.product.compareAtPrice > 0) {
      discountPercent =
          ((widget.product.compareAtPrice - widget.product.price) /
              widget.product.compareAtPrice) *
          100;
      savingsAmount = widget.product.compareAtPrice - widget.product.price;
    }

    final isOutOfStock =
        widget.product.availabilityStatus?.toLowerCase() == "out of stock" ||
        widget.product.availabilityStatus?.toLowerCase() == "out_of_stock";

    return Container(
      height: 165,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Row(
              children: [
                Container(
                  width: 125,
                  height: 165,
                  color: Colors.white,
                  child: Stack(
                    children: [
                      Center(
                        child: HeroMode(
                          enabled: !widget.isPopping,
                          child: Hero(
                            tag:
                                widget.heroTag ??
                                'product_${widget.category}_${widget.product.id}',
                            child: ProgressiveImage(
                              thumbnailUrl: widget.product.thumbnail,
                              imageUrl: widget.product.images.isNotEmpty
                                  ? widget.product.images.first
                                  : widget.product.thumbnail,
                              fit: BoxFit.contain,
                              padding: 10.0,
                            ),
                          ),
                        ),
                      ),
                      if (isOutOfStock)
                        Container(
                          color: Colors.black.withOpacity(0.4),
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  color: Colors.black.withOpacity(0.3),
                                  child: const Text(
                                    "SOLD OUT",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (widget.product.averageRating > 0)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.72),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFFA9527),
                                      size: 10,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      widget.product.averageRating
                                          .toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 8.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            if (discountPercent > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFA9527),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "${discountPercent.toStringAsFixed(0)}% OFF",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: TranslatableText(
                                  widget.product.brandName?.toUpperCase() ??
                                      "PREMIUM GRADE",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TranslatableText(
                          widget.product.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 2),
                        TranslatableText(
                          widget.product.technicalName ??
                              "Crop Safety Formulation",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        if (widget.product.lowestPriceVariant != null) ...[
                          const SizedBox(height: 6),
                          _buildVariantDetails(
                            widget.product.lowestPriceVariant!,
                            theme,
                            isGridView: false,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isKycComplete)
                                    Text(
                                      "KYC Required",
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    )
                                  else ...[
                                    Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 6,
                                      runSpacing: 2,
                                      children: [
                                        Text(
                                          "₹${widget.product.price.toStringAsFixed(0)}",
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 17,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        if (discountPercent > 0)
                                          Text(
                                            "₹${widget.product.compareAtPrice.toStringAsFixed(0)}",
                                            style: TextStyle(
                                              color: Colors.grey.shade400,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (savingsAmount > 0) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        "Dealer saves ₹${savingsAmount.toStringAsFixed(0)} (${discountPercent.toStringAsFixed(0)}% off)",
                                        style: const TextStyle(
                                          color: Color(0xFFE67E22),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                            if (isKycComplete)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Add",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      CupertinoIcons.chevron_right,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      CupertinoIcons.lock_fill,
                                      color: Colors.grey,
                                      size: 10,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      "Locked",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
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

            Positioned(
              top: 8,
              right: 8,
              child: HeroMode(
                enabled: !widget.isPopping,
                child: Hero(
                  tag: widget.heroTag != null
                      ? 'heart_${widget.heroTag}'
                      : 'heart_product_${widget.category}_${widget.product.id}',
                  child: AnimatedHeart(
                    isFavorite: widget.isFavorite,
                    onTap: widget.onFavoriteToggle,
                    size: 16,
                    backgroundColor: Colors.white.withOpacity(0.85),
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
