import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/features/products/data/models/product_model.dart';
import 'package:krishikranti/features/products/data/models/category_model.dart';
import 'package:krishikranti/features/products/data/repositories/product_repository.dart';
import 'package:krishikranti/screens/product_list_screen.dart'; // For ShimmerCard
import 'package:krishikranti/widgets/product_card.dart'; // Standardized Premium ProductCard
import 'package:krishikranti/core/favorite_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'dart:ui';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class SearchScreen extends StatefulWidget {
  final bool startVoiceSearch;
  const SearchScreen({super.key, this.startVoiceSearch = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ProductRepository _productRepository = ProductRepository();
  final FavoriteService _favoriteService = FavoriteService();
  final SpeechToText _speechToText = SpeechToText();

  late AnimationController _pulseController;

  Timer? _debounce;
  List<Product> _searchResults = [];
  bool _isLoading = false;
  String _searchQuery = "";
  String? _errorMessage;

  List<String> _recentSearches = [];
  bool _isVoiceSearching = false;
  static const platform = MethodChannel(
    'com.krishi.dealer.retailer/voice_search',
  );

  List<Category> _allCategories = [];
  List<Category> _randomCategories = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadRandomCategories();

    if (widget.startVoiceSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showBlinkitVoiceSearch();
      });
    }
  }

  Future<void> _loadRandomCategories() async {
    try {
      final categories = await _productRepository.getCategories();
      if (categories.isNotEmpty && mounted) {
        final shuffled = List<Category>.from(categories)..shuffle();
        setState(() {
          _allCategories = categories;
          _randomCategories = shuffled.take(3).toList();
        });
      }
    } catch (e) {
      debugPrint("Error loading categories in search: $e");
    }
  }

  Category? _findCategoryByQuery(String query, AppLocalizations l10n) {
    if (query.trim().isEmpty) return null;
    final cleanQuery = query.trim().toLowerCase();

    // First, look for an exact match (either localized name or database name)
    for (final category in _allCategories) {
      final localizedName = _getLocalizedCategoryName(
        category.name,
        l10n,
      ).toLowerCase();
      final originalName = category.name.toLowerCase();
      if (cleanQuery == localizedName || cleanQuery == originalName) {
        return category;
      }
    }

    // Fallback: look for a fuzzy or partial match if the query is at least 3 characters
    if (cleanQuery.length >= 3) {
      for (final category in _allCategories) {
        final localizedName = _getLocalizedCategoryName(
          category.name,
          l10n,
        ).toLowerCase();
        final originalName = category.name.toLowerCase();
        if (localizedName.contains(cleanQuery) ||
            originalName.contains(cleanQuery)) {
          return category;
        }
      }
    }

    return null;
  }

  IconData _getIconForCategory(String name) {
    switch (name.trim().toLowerCase()) {
      case 'insecticides':
        return Icons.bug_report_rounded;
      case 'fungicides':
        return Icons.science_rounded;
      case 'pgr':
      case 'pgrs':
        return Icons.grass_rounded;
      case 'fertilizers':
        return Icons.eco_rounded;
      case 'herbicides':
        return Icons.agriculture_rounded;
      case 'bio-products':
      case 'bio products':
      case 'bioproducts':
        return Icons.psychology_alt_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  String _getLocalizedCategoryName(String name, AppLocalizations l10n) {
    final clean = name.trim().toLowerCase();
    switch (clean) {
      case 'insecticides':
        return l10n.categoryInsecticides;
      case 'fungicides':
        return l10n.categoryFungicides;
      case 'pgr':
      case 'pgrs':
        return l10n.categoryPgrs;
      case 'fertilizers':
        return l10n.categoryFertilizers;
      case 'herbicides':
        return l10n.categoryHerbicides;
      case 'bio-products':
      case 'bio products':
      case 'bioproducts':
        return l10n.categoryBioProducts;
      default:
        return name;
    }
  }

  Widget _buildLoadingChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 50,
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey.shade200,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBlinkitVoiceSearch() async {
    try {
      final String? result = await platform.invokeMethod('startVoiceSearch');
      if (result != null && result.isNotEmpty) {
        setState(() {
          _searchController.text = result;
          _onSearchChanged(result);
        });
        _saveRecentSearch(result);
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to get voice search: '${e.message}'.");
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _recentSearches = prefs.getStringList('recent_searches') ?? [];
      });
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final currentSearches = prefs.getStringList('recent_searches') ?? [];

    currentSearches.remove(trimmed);
    currentSearches.insert(0, trimmed);

    if (currentSearches.length > 10) {
      currentSearches.removeLast();
    }

    await prefs.setStringList('recent_searches', currentSearches);
    if (mounted) {
      setState(() {
        _recentSearches = currentSearches;
      });
    }
  }

  void _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    if (mounted) {
      setState(() {
        _recentSearches = [];
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    try {
      final l10n = AppLocalizations.of(context)!;
      final matchedCategory = _findCategoryByQuery(query, l10n);

      final Map<String, dynamic> result;
      if (matchedCategory != null) {
        debugPrint(
          "[SearchScreen] Matched query '$query' to category: ${matchedCategory.name} (${matchedCategory.id})",
        );
        result = await _productRepository.getProducts(
          categoryId: matchedCategory.id,
          limit: 50,
        );
      } else {
        result = await _productRepository.getProducts(
          search: query.trim(),
          limit: 50,
        );
      }

      if (mounted && _searchQuery.trim() == query.trim()) {
        setState(() {
          _searchResults = result['products'] as List<Product>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && _searchQuery.trim() == query.trim()) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _toggleFavorite(Product product) {
    HapticFeedback.mediumImpact();
    _favoriteService.toggleFavorite(
      FavoriteProduct(
        id: product.id,
        name: product.title,
        category: "Search",
        price: product.price.toString(),
        imageUrl: product.thumbnail,
        weight: product.variants.isNotEmpty
            ? product.variants.first.size
            : "Standard",
      ),
    );
  }

  Widget _buildModernSearchBar(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(CupertinoIcons.back, color: Colors.black87),
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
            },
          ),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.search,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      cursorColor: theme.colorScheme.primary,
                      controller: _searchController,
                      autofocus: !widget.startVoiceSearch,
                      onChanged: _onSearchChanged,
                      onSubmitted: (value) => _saveRecentSearch(value),
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.searchProducts,
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _searchController.clear();
                        _onSearchChanged("");
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          CupertinoIcons.clear_thick_circled,
                          size: 18,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showBlinkitVoiceSearch,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        CupertinoIcons.mic_fill,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildModernSearchBar(theme, l10n),
                  SizedBox(height: 12),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      layoutBuilder:
                          (
                            Widget? currentChild,
                            List<Widget> previousChildren,
                          ) {
                            return Stack(
                              alignment: Alignment.topLeft,
                              children: <Widget>[
                                ...previousChildren,
                                if (currentChild != null) currentChild,
                              ],
                            );
                          },
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, 0.02),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                      child: _searchQuery.isEmpty
                          ? KeyedSubtree(
                              key: const ValueKey('default_view'),
                              child: _buildDefaultView(theme, l10n),
                            )
                          : KeyedSubtree(
                              key: ValueKey(
                                'search_results_${_isLoading ? "loading" : "loaded"}',
                              ),
                              child: _buildSearchResults(theme, l10n),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultView(ThemeData theme, AppLocalizations l10n) {
    return CustomScrollView(
      slivers: [
        if (_recentSearches.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.recentSearches,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Colors.black87,
                          letterSpacing: -0.3,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _clearRecentSearches();
                        },
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.clearAll,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _recentSearches
                        .map(
                          (search) => GestureDetector(
                            onTap: () {
                              _searchController.text = search;
                              _onSearchChanged(search);
                              _saveRecentSearch(search);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.time,
                                    size: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    search,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: AnimationConfiguration.synchronized(
              duration: const Duration(milliseconds: 600),
              child: FadeInAnimation(
                child: SlideAnimation(
                  verticalOffset: 20,
                  child: ScaleAnimation(
                    scale: 0.95,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Ambient Glow behind Lottie
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.primary.withOpacity(
                                  0.05,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    blurRadius: 60,
                                    spreadRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                            Lottie.asset(
                              'assets/animations/Search.json',
                              width: 140,
                              height: 140,
                              fit: BoxFit.contain,
                              repeat: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DefaultTextStyle(
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: Colors.black,
                          ),
                          child: AnimatedTextKit(
                            animatedTexts: [
                              TypewriterAnimatedText(
                                l10n.whatAreYouLookingFor,
                                speed: const Duration(milliseconds: 100),
                                cursor: '|',
                                textAlign: TextAlign.center,
                              ),
                            ],
                            isRepeatingAnimation: false,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DefaultTextStyle(
                          style: GoogleFonts.outfit(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          child: AnimatedTextKit(
                            animatedTexts: [
                              TypewriterAnimatedText(
                                l10n.searchHintSeeds,
                                speed: const Duration(milliseconds: 80),
                                textAlign: TextAlign.center,
                              ),
                              TypewriterAnimatedText(
                                l10n.searchHintCrops,
                                speed: const Duration(milliseconds: 80),
                                textAlign: TextAlign.center,
                              ),
                              TypewriterAnimatedText(
                                l10n.searchHintMachinery,
                                speed: const Duration(milliseconds: 80),
                                textAlign: TextAlign.center,
                              ),
                              TypewriterAnimatedText(
                                l10n.searchHintBioProducts,
                                speed: const Duration(milliseconds: 80),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            isRepeatingAnimation: true,
                            pause: const Duration(milliseconds: 1500),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Trending / Quick Discovery
                        Column(
                          children: [
                            Text(
                              l10n.quickDiscovery,
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 10,
                              runSpacing: 10,
                              children: _randomCategories.isEmpty
                                  ? [
                                      _buildLoadingChip(),
                                      _buildLoadingChip(),
                                      _buildLoadingChip(),
                                    ]
                                  : _randomCategories.map((category) {
                                      final localizedName =
                                          _getLocalizedCategoryName(
                                            category.name,
                                            l10n,
                                          );
                                      final icon = _getIconForCategory(
                                        category.name,
                                      );
                                      return _buildQuickChip(
                                        localizedName,
                                        icon,
                                      );
                                    }).toList(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickChip(String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _searchController.text = label;
        _onSearchChanged(label);
        _saveRecentSearch(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme, AppLocalizations l10n) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    if (_isLoading) {
      return KeyedSubtree(
        key: const ValueKey('loading'),
        child: GridView.builder(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 245,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 6,
          itemBuilder: (context, index) => const ShimmerCard(),
        ),
      );
    }

    if (_errorMessage != null) {
      return KeyedSubtree(
        key: const ValueKey('error'),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.somethingWentWrong,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _onSearchChanged(_searchQuery),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.tryAgain),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return KeyedSubtree(
        key: const ValueKey('empty'),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/EmptyOrder.json',
                width: 200,
                height: 200,
              ),
              Text(
                l10n.noProducts,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.tryAdjustingSearch,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return KeyedSubtree(
      key: const ValueKey('results'),
      child: ListenableBuilder(
        listenable: _favoriteService,
        builder: (context, child) {
          return GridView.builder(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 245,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final product = _searchResults[index];
              return RepaintBoundary(
                child: ProductCard(
                  key: ValueKey(product.id),
                  product: product,
                  category: "Search Result",
                  isFavorite: _favoriteService.isFavorite(product.id),
                  onFavoriteToggle: () => _toggleFavorite(product),
                  index: index,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
