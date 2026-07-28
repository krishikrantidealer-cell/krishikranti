import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProgressiveImage extends StatefulWidget {
  final String thumbnailUrl;
  final String imageUrl;
  final BoxFit fit;
  final double padding;
  final bool animate;

  const ProgressiveImage({
    super.key,
    required this.thumbnailUrl,
    required this.imageUrl,
    this.fit = BoxFit.contain,
    this.padding = 8.0,
    this.animate = true,
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

    if (_highResUrl.contains('/thumb.webp')) {
      _highResUrl = _highResUrl.replaceAll('/thumb.webp', '/large.webp');
    } else if (_highResUrl.contains('/medium.webp')) {
      _highResUrl = _highResUrl.replaceAll('/medium.webp', '/large.webp');
    }
    
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

    // Optimization: When animate is false (Marquee), we still use the double-layer
    // approach to ensure high-res images swap in correctly, but we disable all durations.
    final fadeIn = widget.animate ? const Duration(milliseconds: 500) : Duration.zero;

    return Padding(
      padding: EdgeInsets.all(widget.padding),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Blurry Thumbnail (cached)
          SizedBox.expand(
            child: CachedNetworkImage(
              imageUrl: widget.thumbnailUrl.contains('drive.google.com/thumbnail')
                  ? widget.thumbnailUrl.replaceAll(RegExp(r'sz=w\d+'), 'sz=w200')
                  : widget.thumbnailUrl,
              fit: widget.fit,
              memCacheWidth: 400,
              memCacheHeight: 400,
              placeholder: (context, url) => Container(
                color: const Color(0xFFF5F5F5),
              ),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.image_outlined, color: Colors.grey),
            ),
          ),
          // High-Res Image (instantly replaces thumbnail if animate is false)
          if (_highResUrl != widget.thumbnailUrl)
            SizedBox.expand(
              child: CachedNetworkImage(
                imageUrl: _highResUrl,
                fit: widget.fit,
                memCacheWidth: 600,
                memCacheHeight: 600,
                fadeInDuration: fadeIn,
                fadeOutDuration: fadeIn,
                errorWidget: (context, url, error) => const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}
