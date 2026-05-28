import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:krishikranti/features/products/data/models/collection_model.dart';
import 'package:krishikranti/screens/product_list_screen.dart';
import 'package:krishikranti/core/utils/translatable_text.dart';

class SubCollectionsScreen extends StatelessWidget {
  final Collection collection;

  const SubCollectionsScreen({super.key, required this.collection});

  @override
  Widget build(BuildContext context) {
    final subCollections = collection.subCollections
        .where((s) => s.isActive)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          children: [
            TranslatableText(
              collection.name,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              "${subCollections.length} Categories",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.maybePop(context);
          },
        ),
      ),
      body: subCollections.isEmpty
          ? const Center(child: Text("No items available"))
          : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: subCollections.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final subCrop = subCollections[index];
                return _CompactCreativeCard(
                  name: subCrop.name,
                  imageUrl: subCrop.image,
                  index: index,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductListScreen(
                          category: subCrop.name,
                          collection: subCrop.name,
                          isCollection: true,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _CompactCreativeCard extends StatefulWidget {
  final String name;
  final String? imageUrl;
  final int index;
  final VoidCallback onTap;

  const _CompactCreativeCard({
    required this.name,
    this.imageUrl,
    required this.index,
    required this.onTap,
  });

  @override
  State<_CompactCreativeCard> createState() => _CompactCreativeCardState();
}

class _CompactCreativeCardState extends State<_CompactCreativeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAlternate = widget.index % 2 == 0;
    final hasImage = widget.imageUrl != null && widget.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: hasImage
                  ? Colors.white
                  : (isAlternate
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primaryContainer),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: hasImage
                      ? Colors.black.withOpacity(0.08)
                      : (isAlternate
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primaryContainer)
                          .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage) ...[
                    CachedNetworkImage(
                      imageUrl: widget.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[100],
                        child: const Center(
                          child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: isAlternate
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primaryContainer,
                        child: Center(
                          child: Icon(
                            Icons.eco_rounded,
                            color: isAlternate
                                ? Colors.white.withOpacity(0.3)
                                : theme.colorScheme.primary.withOpacity(0.3),
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.4, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TranslatableText(
                            widget.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white,
                              height: 1.1,
                              shadows: [
                                Shadow(
                                  color: Colors.black45,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Positioned(
                      right: -10,
                      bottom: -10,
                      child: Icon(
                        Icons.eco_rounded,
                        size: 60,
                        color: Colors.white.withOpacity(isAlternate ? 0.15 : 0.4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.grid_view_rounded,
                              color: isAlternate
                                  ? Colors.white
                                  : theme.colorScheme.primary,
                              size: 16,
                            ),
                          ),
                          TranslatableText(
                            widget.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isAlternate
                                  ? Colors.white
                                  : theme.colorScheme.onPrimaryContainer,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
