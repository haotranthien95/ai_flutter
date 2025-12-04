import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Image carousel widget for product images.
class ImageCarousel extends StatefulWidget {
  const ImageCarousel({
    required this.images,
    super.key,
  });

  final List<String> images;

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(
            Icons.image_not_supported_outlined,
            size: 80.0,
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Image PageView
        AspectRatio(
          aspectRatio: 1.0,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return RepaintBoundary(
                child: GestureDetector(
                  onTap: () => _showFullscreenImage(context, index),
                  child: Hero(
                  tag: 'product_image_$index',
                  child: CachedNetworkImage(
                    imageUrl: widget.images[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        size: 80.0,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Dot indicators
        if (widget.images.length > 1)
          Positioned(
            bottom: 16.0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: _currentPage == index ? 12.0 : 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              ),
            ),
          ),

        // Zoom icon hint
        Positioned(
          top: 16.0,
          right: 16.0,
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: const Icon(
              Icons.zoom_in,
              color: Colors.white,
              size: 20.0,
            ),
          ),
        ),
      ],
    );
  }

  void _showFullscreenImage(BuildContext context, int initialIndex) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => _FullscreenImageGallery(
          images: widget.images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

/// Fullscreen image gallery for zooming.
class _FullscreenImageGallery extends StatefulWidget {
  const _FullscreenImageGallery({
    required this.images,
    required this.initialIndex,
  });

  final List<String> images;
  final int initialIndex;

  @override
  State<_FullscreenImageGallery> createState() =>
      _FullscreenImageGalleryState();
}

class _FullscreenImageGalleryState extends State<_FullscreenImageGallery> {
  late PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('${_currentPage + 1}/${widget.images.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Hero(
              tag: 'product_image_$index',
              child: CachedNetworkImage(
                imageUrl: widget.images[index],
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 80.0,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
