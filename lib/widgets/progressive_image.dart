import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProgressiveImage extends StatefulWidget {
  final String thumbnailUrl;
  final String imageUrl;
  final BoxFit fit;
  final double padding;

  const ProgressiveImage({
    super.key,
    required this.thumbnailUrl,
    required this.imageUrl,
    this.fit = BoxFit.contain,
    this.padding = 8.0,
  });

  @override
  State<ProgressiveImage> createState() => _ProgressiveImageState();
}

class _ProgressiveImageState extends State<ProgressiveImage> {
  late String _highResUrl;

  @override
  void initState() {
    super.initState();
    _initHighResUrl();
  }

  @override
  void didUpdateWidget(ProgressiveImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.thumbnailUrl != widget.thumbnailUrl) {
      _initHighResUrl();
    }
  }

  void _initHighResUrl() {
    _highResUrl = widget.imageUrl;

    // Upgrade logic: upgrade thumb or medium to large for the "original" look.
    if (_highResUrl.contains('/thumb.webp')) {
      _highResUrl = _highResUrl.replaceAll('/thumb.webp', '/large.webp');
    } else if (_highResUrl.contains('/medium.webp')) {
      _highResUrl = _highResUrl.replaceAll('/medium.webp', '/large.webp');
    }
    
    // GOOGLE DRIVE LOGIC: 
    // If it's a drive thumbnail, force the high-res version to be large (w2500)
    if (_highResUrl.contains('drive.google.com/thumbnail')) {
      if (_highResUrl.contains('sz=w')) {
        _highResUrl = _highResUrl.replaceAll(RegExp(r'sz=w\d+'), 'sz=w2500');
      } else {
        _highResUrl = "$_highResUrl&sz=w2500";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.isEmpty || widget.thumbnailUrl.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(widget.padding),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.image_outlined, color: Colors.grey, size: 24),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(widget.padding),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Blurry Thumbnail (loads fast & cached)
          SizedBox.expand(
            child: CachedNetworkImage(
              imageUrl: widget.thumbnailUrl.contains('drive.google.com/thumbnail')
                  ? widget.thumbnailUrl.replaceAll(RegExp(r'sz=w\d+'), 'sz=w200')
                  : widget.thumbnailUrl,
              fit: widget.fit,
              memCacheWidth: 400, // Optimize memory for list scrolling
              memCacheHeight: 400,
              placeholder: (context, url) => Container(
                color: const Color(0xFFF5F5F5), // Very light grey
              ),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.image_outlined, color: Colors.grey),
            ),
          ),
          // High-Res/Medium Image (fades in & cached)
          if (_highResUrl != widget.thumbnailUrl)
            SizedBox.expand(
              child: CachedNetworkImage(
                imageUrl: _highResUrl,
                fit: widget.fit,
                memCacheWidth:
                    600, // Higher res for the "pop" but still optimized
                memCacheHeight: 600,
                fadeInDuration: const Duration(milliseconds: 500),
                errorWidget: (context, url, error) => const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}
