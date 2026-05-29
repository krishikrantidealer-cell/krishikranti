import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/screens/product_list_screen.dart';
import 'package:krishikranti/screens/search_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:krishikranti/features/products/data/models/category_model.dart';
import 'package:krishikranti/features/products/data/models/collection_model.dart';
import 'package:krishikranti/features/products/data/repositories/home_repository.dart';
import 'package:krishikranti/features/products/data/models/banner_model.dart';
import 'package:krishikranti/features/products/data/models/product_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:krishikranti/screens/product_detail_screen.dart';
import 'package:krishikranti/widgets/breathing_mic_icon.dart';

class CatalogueScreen extends StatefulWidget {
  final bool isShowingCollections;
  const CatalogueScreen({super.key, this.isShowingCollections = false});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen>
    with WidgetsBindingObserver {
  int _currentBanner = 0;
  bool _isLoading = true;
  List<Category> _categories = [];
  List<Collection> _collections = [];
  List<BannerModel> _categoryBanners = [];
  List<BannerModel> _categoryCardBanners = [];
  final HomeRepository _homeRepository = HomeRepository();
  bool _routeIsCurrent = false;
  int _currentHintIndex = 0;
  Timer? _hintTimer;
  // 5 rotating hint slots (0-4): crops, seeds, fertilizers, machinery, organic
  static const int _searchHintCount = 5;

  // ── flutter_downloader IsolateNameServer port ───────────────────────────
  static const String _portName = 'catalogue_downloader_port';
  final ReceivePort _port = ReceivePort();
  // taskId → category download info for open-on-complete
  final Map<String, _DownloadInfo> _pendingDownloads = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bindDownloaderPort();
    if (widget.isShowingCollections) {
      _fetchCollections();
    } else {
      _fetchCategories();
    }
    _startHintTimer();
  }

  // ── flutter_downloader port wiring ─────────────────────────────────────
  void _bindDownloaderPort() {
    IsolateNameServer.removePortNameMapping(_portName);
    IsolateNameServer.registerPortWithName(_port.sendPort, _portName);
    _port.listen(_onDownloadUpdate);
    FlutterDownloader.registerCallback(_downloaderCallback);
  }

  @pragma('vm:entry-point')
  static void _downloaderCallback(String id, int status, int progress) {
    final send = IsolateNameServer.lookupPortByName(
      'catalogue_downloader_port',
    );
    send?.send([id, status, progress]);
  }

  void _onDownloadUpdate(dynamic data) {
    final list = data as List<dynamic>;
    final taskId = list[0] as String;
    final status = DownloadTaskStatus.fromInt(list[1] as int);
    final progress = list[2] as int;

    final info = _pendingDownloads[taskId];
    if (info == null) return;

    // Update in-app snackbar progress
    info.progressNotifier.value = progress / 100.0;

    if (status == DownloadTaskStatus.complete) {
      _pendingDownloads.remove(taskId);
      info.progressNotifier.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: const Color(0xFF2E7D32),
            content: Text(
              '${info.categoryName} catalogue downloaded!',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            action: SnackBarAction(
              label: 'Open',
              textColor: const Color(0xFFA5D6A7),
              onPressed: () async {
                final result = await OpenFilex.open(info.savePath);
                if (result.type != ResultType.done) {
                  final webUri = Uri.parse(info.pdfUrl);
                  if (await canLaunchUrl(webUri)) {
                    await launchUrl(
                      webUri,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                }
              },
            ),
          ),
        );
      }
    } else if (status == DownloadTaskStatus.failed ||
        status == DownloadTaskStatus.canceled) {
      _pendingDownloads.remove(taskId);
      info.progressNotifier.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.orange.shade800,
            content: Text(
              'Download failed. Tap to open in browser.',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () async {
                final webUri = Uri.parse(info.pdfUrl);
                if (await canLaunchUrl(webUri)) {
                  await launchUrl(
                    webUri,
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
            ),
          ),
        );
      }
    }
  }

  void _startHintTimer() {
    _hintTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentHintIndex = (_currentHintIndex + 1) % _searchHintCount;
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _silentRefresh();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      if (_routeIsCurrent == false) {
        // Route just became active again (user navigated back)
        _silentRefresh();
      }
      _routeIsCurrent = true;
    } else {
      _routeIsCurrent = false;
    }
  }

  void _silentRefresh() {
    _homeRepository
        .getHomeDiscovery(forceRefresh: true)
        .then((freshDiscovery) {
          if (mounted) {
            setState(() {
              _categories = freshDiscovery.categories;
              _collections = freshDiscovery.collections;
              _categoryBanners = freshDiscovery.categoryBanners;
              _categoryCardBanners = freshDiscovery.categoryCardBanners;
            });
          }
        })
        .catchError((_) {});
  }

  Future<void> _fetchCollections() async {
    try {
      // Step 1: Try to get cached data instantly
      final discovery = await _homeRepository.getHomeDiscovery(
        forceRefresh: false,
      );
      if (mounted) {
        setState(() {
          _collections = discovery.collections;
          _categoryBanners = discovery.categoryBanners;
          _categoryCardBanners = discovery.categoryCardBanners;
          _isLoading = false;
        });
      }

      // Step 2: Background refresh (SWR) dynamically
      final freshDiscovery = await _homeRepository.getHomeDiscovery(
        forceRefresh: true,
      );
      if (mounted) {
        setState(() {
          _collections = freshDiscovery.collections;
          _categoryBanners = freshDiscovery.categoryBanners;
          _categoryCardBanners = freshDiscovery.categoryCardBanners;
        });
      }
    } catch (e) {
      if (mounted && _collections.isEmpty) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchCategories() async {
    try {
      // Step 1: Check HomeDiscovery cache first (it's often already warmed up by HomeScreen)
      final discovery = await _homeRepository.getHomeDiscovery(
        forceRefresh: false,
      );
      if (mounted && discovery.categories.isNotEmpty) {
        setState(() {
          _categories = discovery.categories;
          _categoryBanners = discovery.categoryBanners;
          _categoryCardBanners = discovery.categoryCardBanners;
          _isLoading = false;
        });
      }

      // Step 2: Run a background refresh (SWR) to update cached values and pull new category banners
      final freshDiscovery = await _homeRepository.getHomeDiscovery(
        forceRefresh: true,
      );
      if (mounted) {
        setState(() {
          _categories = freshDiscovery.categories;
          _categoryBanners = freshDiscovery.categoryBanners;
          _categoryCardBanners = freshDiscovery.categoryCardBanners;
        });
      }
    } catch (e) {
      if (mounted && _categories.isEmpty) {
        setState(() => _isLoading = false);
      }
    }
  }

  IconData _getIconForCategory(String name) {
    switch (name.toLowerCase()) {
      case 'insecticides':
        return Icons.bug_report;
      case 'fungicides':
        return Icons.science;
      case 'pgrs':
        return Icons.grass;
      case 'fertilizers':
        return Icons.eco;
      case 'herbicides':
        return Icons.agriculture;
      case 'bio-products':
        return Icons.psychology_alt;
      default:
        return Icons.category_outlined;
    }
  }

  String _getFallbackImageForCategory(String name) {
    switch (name.toLowerCase()) {
      case 'insecticides':
        return 'https://images.unsplash.com/photo-1599420186946-7b6fb4e297f0?auto=format&fit=crop&q=80&w=400';
      case 'fungicides':
        return 'https://images.unsplash.com/photo-1574943320219-553eb213f72d?auto=format&fit=crop&q=80&w=400';
      case 'fertilizers':
        return 'https://images.unsplash.com/photo-1585314062340-f1a5a7c9328d?auto=format&fit=crop&q=80&w=400';
      case 'pgrs':
        return 'https://images.unsplash.com/photo-1523348837708-15d4a09cfac2?auto=format&fit=crop&q=80&w=400';
      case 'bio-products':
      case 'bio products':
      case 'bioproducts':
        return 'https://storage.googleapis.com/krishi-product-images/categorycardbanners/Bio-Products.webp';
      case 'herbicides':
        return 'https://images.unsplash.com/photo-1515023115689-589c33041d3c?auto=format&fit=crop&q=80&w=400';
      default:
        return 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&q=80&w=400';
    }
  }

  String _getImageForCategory(Category cat, int index) {
    if (cat.bannerImage != null && cat.bannerImage!.isNotEmpty) {
      return cat.bannerImage!;
    }
    final String name = cat.name;
    if (_categoryCardBanners.isNotEmpty) {
      final String cleanName = name.trim().toLowerCase();
      final String cleanNameNoHyphen = cleanName
          .replaceAll('-', '')
          .replaceAll(' ', '');

      // 1. Match by redirect target (ID or Category Name)
      for (final banner in _categoryCardBanners) {
        final String? target = banner.redirectTarget?.trim().toLowerCase();
        if (target != null && (target == cat.id || target == cleanName)) {
          return banner.imageUrl;
        }
      }

      // 2. Match by banner title containing Category Name
      for (final banner in _categoryCardBanners) {
        final String title = banner.title.trim().toLowerCase();
        if (title.contains(cleanName) || title.contains(cleanNameNoHyphen)) {
          return banner.imageUrl;
        }
      }

      // 3. Match by array-index formatting ("_card_index", "Category Card Banner {index + 1}")
      for (final banner in _categoryCardBanners) {
        final String bannerId = banner.id;
        final String bannerTitle = banner.title;
        if (bannerId.endsWith('_card_$index') ||
            bannerTitle == 'Category Card Banner ${index + 1}' ||
            banner.priority == index) {
          return banner.imageUrl;
        }
      }

      // 4. Fallback to image URL keyword matching
      for (final banner in _categoryCardBanners) {
        final String cleanUrl = banner.imageUrl.toLowerCase();
        if (cleanUrl.contains('/$cleanName.') ||
            cleanUrl.contains('/$cleanName%') ||
            cleanUrl.contains('_$cleanName') ||
            cleanUrl.contains(cleanName) ||
            cleanUrl.contains(cleanNameNoHyphen)) {
          return banner.imageUrl;
        }
      }

      // 5. Ultimate fallback: Match strictly 1-to-1 by order in the list
      if (index < _categoryCardBanners.length) {
        return _categoryCardBanners[index].imageUrl;
      }
    }
    return _getFallbackImageForCategory(name);
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping(_portName);
    _port.close();
    for (final info in _pendingDownloads.values) {
      info.progressNotifier.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    _hintTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // REFINED MODERN APP BAR (Matched with Notification - Carefully Padded)
            SliverAppBar(
              expandedHeight: 120.0,
              toolbarHeight: 60.0,
              floating: false,
              pinned: true,
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              automaticallyImplyLeading: false,
              leading: Navigator.canPop(context)
                  ? IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.maybePop(context);
                      },
                    )
                  : null,
              title: Text(
                widget.isShowingCollections ? l10n.crops : l10n.categories,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(64),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    ),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.search,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                    final offsetAnimation =
                                        Tween<Offset>(
                                          begin: const Offset(0.0, 0.8),
                                          end: Offset.zero,
                                        ).animate(
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutBack,
                                          ),
                                        );
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: offsetAnimation,
                                        child: child,
                                      ),
                                    );
                                  },
                              child: Text(
                                () {
                                  switch (_currentHintIndex) {
                                    case 0:
                                      return l10n.searchHintCrops;
                                    case 1:
                                      return l10n.searchHintSeeds;
                                    case 2:
                                      return l10n.searchHintFertilizers;
                                    case 3:
                                      return l10n.searchHintMachinery;
                                    case 4:
                                      return l10n.searchHintOrganic;
                                    default:
                                      return l10n.searchHintCrops;
                                  }
                                }(),
                                key: ValueKey<int>(_currentHintIndex),
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SearchScreen(
                                    startVoiceSearch: true,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              margin: const EdgeInsets.only(left: 4),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: BreathingMicIcon(
                                size: 20,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  // TOP BANNER (MORE COMPACT)
                  _buildBanner(context, theme),

                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.isShowingCollections
                              ? l10n.shopByCrop
                              : l10n.browseCategories,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey.shade900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.05,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.isShowingCollections
                                ? l10n.cropsCount(_collections.length)
                                : l10n.categoriesCount(_categories.length),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // COMPACT 3-COLUMN GRID
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    child: _isLoading
                        ? _buildShimmerGrid()
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: widget.isShowingCollections
                                ? _collections.length
                                : _categories.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: widget.isShowingCollections
                                      ? 3
                                      : 2,
                                  mainAxisSpacing: widget.isShowingCollections
                                      ? 12
                                      : 8,
                                  crossAxisSpacing: widget.isShowingCollections
                                      ? 12
                                      : 8,
                                  childAspectRatio: widget.isShowingCollections
                                      ? 0.82
                                      : 2.3,
                                ),
                            itemBuilder: (context, index) {
                              return _StaggeredEntrance(
                                index: index,
                                child: widget.isShowingCollections
                                    ? _buildCompactCollectionCard(
                                        context,
                                        _collections[index],
                                        theme,
                                      )
                                    : _buildRectangularCategoryCard(
                                        context,
                                        _categories[index],
                                        theme,
                                        index,
                                      ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 32),

                  // MINIMAL FEATURE LIST
                  _buildMinimalFeatures(theme),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context, ThemeData theme) {
    if (_categoryBanners.isEmpty) {
      return const SizedBox(height: 10);
    }
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: _categoryBanners.length,
          itemBuilder: (context, index, realIndex) {
            final banner = _categoryBanners[index];
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (banner.redirectType == 'category' &&
                    banner.redirectTarget != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductListScreen(category: banner.redirectTarget!),
                    ),
                  );
                } else if (banner.redirectType == 'product' &&
                    banner.redirectTarget != null) {
                  final placeholderProduct = Product(
                    id: banner.redirectTarget!,
                    title: banner.title,
                    thumbnail: banner.imageUrl,
                    variants: const [],
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        product: placeholderProduct,
                        thumbnailUrl: banner.imageUrl,
                      ),
                    ),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: banner.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    fadeInDuration: const Duration(milliseconds: 300),
                    placeholder: (context, url) =>
                        Container(color: const Color(0xFFF5F5F5)),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.image_outlined, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: 150,
            viewportFraction: 1,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayCurve: Curves.easeInOut,
            onPageChanged: (index, reason) {
              setState(() {
                _currentBanner = index;
              });
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _categoryBanners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: _currentBanner == i ? 16 : 4,
              height: 4,
              decoration: BoxDecoration(
                color: _currentBanner == i
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerGrid() {
    final isCol = widget.isShowingCollections;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isCol ? 3 : 2,
        crossAxisSpacing: isCol ? 12 : 8,
        mainAxisSpacing: isCol ? 12 : 8,
        childAspectRatio: isCol ? 0.82 : 2.3,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade50),
          ),
        );
      },
    );
  }

  // ── Catalogue PDF Download ─────────────────────────────────────────────

  Future<void> _downloadCataloguePdf(
    BuildContext ctx,
    String pdfUrl,
    String categoryName,
  ) async {
    final messenger = ScaffoldMessenger.of(ctx);
    messenger.clearSnackBars();

    // Save to the user-visible Downloads folder so the file appears in Files
    final String saveDir = '/storage/emulated/0/Download';
    final safeFileName =
        '${categoryName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_catalogue.pdf';
    final savePath = '$saveDir/$safeFileName';

    // 1. Check if already downloaded (cache-once)
    final localFile = File(savePath);
    if (await localFile.exists() && await localFile.length() > 0) {
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color(0xFF2E7D32),
          content: Text(
            '$categoryName catalogue is already downloaded!',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          action: SnackBarAction(
            label: 'Open',
            textColor: const Color(0xFFA5D6A7),
            onPressed: () async {
              final result = await OpenFilex.open(savePath);
              if (result.type != ResultType.done) {
                final webUri = Uri.parse(pdfUrl);
                if (await canLaunchUrl(webUri)) {
                  await launchUrl(webUri, mode: LaunchMode.externalApplication);
                }
              }
            },
          ),
        ),
      );
      return;
    }

    // 2. Check if already in-progress
    final existing = _pendingDownloads.values
        .where((d) => d.categoryName == categoryName)
        .firstOrNull;
    if (existing != null) {
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF1B5E20),
          content: Text(
            '$categoryName catalogue is already downloading…',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      );
      return;
    }

    // 3. Start download via WorkManager
    final progressNotifier = ValueNotifier<double>(0.0);

    try {
      final taskId = await FlutterDownloader.enqueue(
        url: pdfUrl,
        savedDir: saveDir,
        fileName: safeFileName,
        showNotification: true,          // OS-level notification with progress
        openFileFromNotification: true,  // tap notification → open file
        requiresStorageNotLow: false,
      );

      if (taskId == null) throw Exception('Failed to enqueue download');

      _pendingDownloads[taskId] = _DownloadInfo(
        categoryName: categoryName,
        pdfUrl: pdfUrl,
        savePath: savePath,
        progressNotifier: progressNotifier,
      );

      // Show in-app snackbar with live progress
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(minutes: 10),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF1B5E20),
          content: ValueListenableBuilder<double>(
            valueListenable: progressNotifier,
            builder: (context, progress, child) {
              final pct = (progress * 100).toStringAsFixed(0);
              final rem = (100 - (progress * 100)).toStringAsFixed(0);
              return Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      value: progress > 0 ? progress : null,
                      strokeWidth: 2,
                      color: Colors.white,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      progress > 0
                          ? 'Downloading $categoryName catalogue… $pct% ($rem% left)'
                          : 'Downloading $categoryName catalogue…',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    } catch (e) {
      progressNotifier.dispose();
      if (!ctx.mounted) return;
      messenger.clearSnackBars();
      final uri = Uri.parse(pdfUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.orange.shade800,
          content: const Text(
            'Could not start download. Opened in browser.',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      );
    }
  }


  Widget _buildRectangularCategoryCard(
    BuildContext context,
    Category category,
    ThemeData theme,
    int index,
  ) {
    final imageUrl = _getImageForCategory(category, index);

    return RectangularCategoryCard(
      category: category,
      imageUrl: imageUrl,
      fallbackImage: _getFallbackImageForCategory(category.name),
      icon: _getIconForCategory(category.name),
      onDownloadTap:
          (category.cataloguePdf != null && category.cataloguePdf!.isNotEmpty)
          ? () => _downloadCataloguePdf(
              context,
              category.cataloguePdf!,
              category.name,
            )
          : null,
      onTap: () {
        HapticFeedback.selectionClick();
        // Navigate to product list
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductListScreen(
              category: category.name,
              categoryId: category.id,
              categoryData: category,
            ),
          ),
        );
        // Simultaneously start catalogue download if available
        if (category.cataloguePdf != null &&
            category.cataloguePdf!.isNotEmpty) {
          _downloadCataloguePdf(context, category.cataloguePdf!, category.name);
        }
      },
    );
  }

  Widget _buildCompactCollectionCard(
    BuildContext context,
    Collection collection,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductListScreen(
              category: collection.name,
              collection: collection.name,
              initialProducts: collection.products,
              isCollection: true,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child:
                    collection.bannerImage != null &&
                        collection.bannerImage!.isNotEmpty
                    ? Image.network(
                        collection.bannerImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.eco,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      )
                    : Icon(
                        Icons.eco,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                collection.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Colors.black,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              AppLocalizations.of(context)!.cropsCollection,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalFeatures(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _minimalBadge(Icons.verified_rounded, l10n.badgeGenuine, theme),
          _minimalBadge(Icons.science_rounded, l10n.badgeTested, theme),
          _minimalBadge(Icons.local_shipping_rounded, l10n.badgeExpress, theme),
        ],
      ),
    );
  }

  Widget _minimalBadge(IconData icon, String label, ThemeData theme) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.primary.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _StaggeredEntrance extends StatefulWidget {
  final Widget child;
  final int index;

  const _StaggeredEntrance({required this.child, required this.index});

  @override
  State<_StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<_StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 40 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: _slide.value * 20,
            child: widget.child,
          ),
        );
      },
    );
  }
}

class RectangularCategoryCard extends StatefulWidget {
  final Category category;
  final String imageUrl;
  final String fallbackImage;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onDownloadTap;

  const RectangularCategoryCard({
    super.key,
    required this.category,
    required this.imageUrl,
    required this.fallbackImage,
    required this.icon,
    required this.onTap,
    this.onDownloadTap,
  });

  @override
  State<RectangularCategoryCard> createState() =>
      _RectangularCategoryCardState();
}

class _RectangularCategoryCardState extends State<RectangularCategoryCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  fit: BoxFit.fill,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => CachedNetworkImage(
                    imageUrl: widget.fallbackImage,
                    fit: BoxFit.fill,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey[200]),
                    errorWidget: (context, url, error) => Container(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Center(
                        child: Icon(
                          widget.icon,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.onDownloadTap != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        widget.onDownloadTap!();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.download_rounded,
                          color: Color(0xFF2E7D32),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Data class for tracking in-flight downloads ────────────────────────────
class _DownloadInfo {
  final String categoryName;
  final String pdfUrl;
  final String savePath;
  final ValueNotifier<double> progressNotifier;

  const _DownloadInfo({
    required this.categoryName,
    required this.pdfUrl,
    required this.savePath,
    required this.progressNotifier,
  });
}
