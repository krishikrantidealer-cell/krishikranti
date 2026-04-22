import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/core/favorite_service.dart';
import 'package:krishikranti/screens/product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  final String category;

  const ProductListScreen({super.key, required this.category});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  int _selectedMenuIndex = 0;
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  final FavoriteService _favoriteService = FavoriteService();

  @override
  void initState() {
    super.initState();
    _favoriteService.addListener(_onFavoriteChanged);
  }

  @override
  void dispose() {
    _favoriteService.removeListener(_onFavoriteChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onFavoriteChanged() {
    if (mounted) setState(() {});
  }

  final List<String> _menuItems = [
    'Chemical Insecticides',
    'Bio Insecticides',
    'Organic Insecticides',
  ];

  List<Map<String, String>> get _filteredProducts {
    int count = 0;
    String prefix = "";
    if (_selectedMenuIndex == 0) { // Chemical
      count = 8;
      prefix = "Chem";
    } else if (_selectedMenuIndex == 1) { // Bio
      count = 3;
      prefix = "Bio";
    } else { // Organic
      count = 5;
      prefix = "Org";
    }

    List<Map<String, String>> items = List.generate(count, (i) {
      String id = "${_selectedMenuIndex}_$i";
      return {
        'id': id,
        'name': i == 0 && _selectedMenuIndex == 0 ? 'ERS GROW Genius' : 'EBS $prefix Product ${i + 1}',
        'desc': i == 0 && _selectedMenuIndex == 0 ? 'Gibberellic Acid 0.0111L' : 'Quality $prefix Solution ${i + 1}',
        'image': 'https://picsum.photos/400?random=${_selectedMenuIndex * 10 + i}',
      };
    });

    if (_searchQuery.isNotEmpty) {
      items = items.where((item) => 
        item['name']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        item['desc']!.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return items;
  }

  void _toggleFavorite(Map<String, String> product) {
    _favoriteService.toggleFavorite(FavoriteProduct(
      name: product['name']!,
      category: widget.category,
      price: "450", 
      imageUrl: product['image']!,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = _filteredProducts;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: theme.colorScheme.primary, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: _isSearching
            ? CupertinoSearchTextField(
                controller: _searchController,
                placeholder: l10n.searchProducts,
                backgroundColor: Colors.grey.shade100,
                onChanged: (value) => setState(() => _searchQuery = value),
                onSuffixTap: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = "";
                    _isSearching = false;
                  });
                },
              )
            : Text(
                widget.category,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: Icon(CupertinoIcons.search, color: theme.colorScheme.primary, size: 24),
              onPressed: () => setState(() => _isSearching = true),
            ),
        ],
      ),
      body: Row(
        children: [
          // Left Side Filter Menu
          Container(
            width: 110,
            color: Colors.grey.shade50,
            child: ListView.builder(
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                return SideMenuItem(
                  title: _menuItems[index],
                  isSelected: _selectedMenuIndex == index,
                  onTap: () {
                    setState(() {
                      _selectedMenuIndex = index;
                    });
                  },
                );
              },
            ),
          ),
          // Right Side Product Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.55,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  name: product['name']!,
                  desc: product['desc']!,
                  imageUrl: product['image']!,
                  isFavorite: _favoriteService.isFavorite(product['name']!),
                  onFavoriteToggle: () => _toggleFavorite(product),
                  onViewMore: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                          productName: product['name']!,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SideMenuItem extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const SideMenuItem({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF455A4F) : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String name;
  final String desc;
  final String imageUrl;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onViewMore;

  const ProductCard({
    super.key,
    required this.name,
    required this.desc,
    required this.imageUrl,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onViewMore,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onViewMore,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section - Full width and Cover style
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onFavoriteToggle,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                          size: 22,
                          color: isFavorite ? Colors.red : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Details Section
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    maxLines: 2, // Allow up to 2 lines
                    overflow: TextOverflow.ellipsis, // Add ellipsis if exceeds 2 lines
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 32, // Slightly smaller button
                    child: ElevatedButton(
                      onPressed: onViewMore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C8C64),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12, // Slightly smaller font
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Text(AppLocalizations.of(context)!.viewMore),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
