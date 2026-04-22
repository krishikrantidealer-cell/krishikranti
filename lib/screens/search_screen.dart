import 'package:flutter/material.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/screens/product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _recentSearches = ["Urea", "Zinc", "Fungicide", "Safety Gloves", "Seeds"];
  
  final List<Map<String, String>> _allProducts = [
    {'name': "COXY-50", 'category': "Fungicide", 'price': "650", 'imageUrl': "https://images.unsplash.com/photo-1589927986089-35812388d1f4?auto=format&fit=crop&q=80&w=300"},
    {'name': "Zinc Power", 'category': "Fertilizer", 'price': "490", 'imageUrl': "https://images.unsplash.com/photo-1625246333195-78d9c38ad449?auto=format&fit=crop&q=80&w=300"},
    {'name': "Urea Premium", 'category': "Fertilizer", 'price': "290", 'imageUrl': "https://images.unsplash.com/photo-1560493676-04071c5f467b?auto=format&fit=crop&q=80&w=300"},
    {'name': "Organic Plus", 'category': "Growth", 'price': "850", 'imageUrl': "https://images.unsplash.com/photo-1589927986089-35812388d1f4?auto=format&fit=crop&q=80&w=300"},
    {'name': "Nano Nitrogen", 'category': "Fertilizer", 'price': "550", 'imageUrl': "https://images.unsplash.com/photo-1625246333195-78d9c38ad449?auto=format&fit=crop&q=80&w=300"},
    {'name': "Root Guard", 'category': "Pesticide", 'price': "1200", 'imageUrl': "https://images.unsplash.com/photo-1560493676-04071c5f467b?auto=format&fit=crop&q=80&w=300"},
  ];

  List<Map<String, String>> _searchResults = [];
  bool _isSearching = false;

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = _allProducts.where((product) {
        final name = product['name']!.toLowerCase();
        final category = product['category']!.toLowerCase();
        return name.contains(query.toLowerCase()) || category.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: l10n.searchProducts,
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
            suffixIcon: _searchController.text.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged("");
                  },
                )
              : null,
          ),
        ),
      ),
      body: _isSearching ? _buildSearchResults(theme, l10n) : _buildDefaultView(theme, l10n),
    );
  }

  Widget _buildDefaultView(ThemeData theme, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            const Text(
              "Recent Searches",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _recentSearches.map((search) => GestureDetector(
                onTap: () {
                  _searchController.text = search;
                  _onSearchChanged(search);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(search, style: const TextStyle(fontSize: 14)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 32),
          ],
          const Text(
            "Suggested Products",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: _allProducts.length,
            itemBuilder: (context, index) {
              return _buildSmallProductCard(context, theme, _allProducts[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme, AppLocalizations l10n) {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              l10n.noProducts,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              "Try searching for something else",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  "Suggested for you",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return _buildSmallProductCard(context, theme, _allProducts[index]);
                },
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      separatorBuilder: (_, index) => const Divider(height: 24),
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        return ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(productName: product['name']!),
              ),
            );
          },
          contentPadding: EdgeInsets.zero,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(product['imageUrl']!, width: 50, height: 50, fit: BoxFit.cover),
          ),
          title: Text(
            product['name']!,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(product['category']!),
          trailing: Text(
            "₹${product['price']}",
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSmallProductCard(BuildContext context, ThemeData theme, Map<String, String> product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productName: product['name']!),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(product['imageUrl']!, fit: BoxFit.cover, width: double.infinity),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    product['category']!,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹${product['price']}",
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
