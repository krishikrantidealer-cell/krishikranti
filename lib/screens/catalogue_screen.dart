import 'package:flutter/material.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/screens/product_list_screen.dart';

class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  int _selectedTab = 0; // 0: All, 1: Chemicals, 2: Bio

  final List<Map<String, dynamic>> _allCategories = [
    {'title': 'Pesticides', 'type': 'Chemicals'},
    {'title': 'Fertilizers', 'type': 'Chemicals'},
    {'title': 'Fungicides', 'type': 'Chemicals'},
    {'title': 'Herbicides', 'type': 'Chemicals'},
    {'title': 'PGRs', 'type': 'Bio'},
    {'title': 'Insecticides', 'type': 'Chemicals'},
    {'title': 'NPK Fertilizers', 'type': 'Chemicals'},
    {'title': 'Bio-Fungicide', 'type': 'Bio'},
    {'title': 'Seeds', 'type': 'Bio'},
    {'title': 'Organic Manure', 'type': 'Bio'},
    {'title': 'Growth Promoters', 'type': 'Bio'},
    {'title': 'Spraying Tools', 'type': 'Chemicals'},
    {'title': 'Soil Nutrition', 'type': 'Chemicals'},
    {'title': 'Weedicides', 'type': 'Chemicals'},
  ];

  List<Map<String, dynamic>> get _filteredCategories {
    if (_selectedTab == 0) return _allCategories;
    
    if (_selectedTab == 1) {
      return _allCategories.where((cat) => 
        ['Pesticides', 'Fertilizers', 'Herbicides', 'Insecticides', 'Fungicides', 'NPK Fertilizers', 'Spraying Tools', 'Soil Nutrition', 'Weedicides'].contains(cat['title'])
      ).toList();
    } else if (_selectedTab == 2) {
      return _allCategories.where((cat) => 
        ['Bio-Fungicide', 'PGRs', 'Seeds', 'Organic Manure', 'Growth Promoters'].contains(cat['title'])
      ).toList();
    }
    
    return _allCategories;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // Floating "Categories" Header (Hide on scroll down, show on scroll up)
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              centerTitle: true,
              pinned: false, // Not sticky
              floating: true,
              snap: true,
              title: Text(
                l10n.categories,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            // Floating Filter Section - Hides on scroll down, shows on scroll up
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              pinned: false, // Not sticky
              floating: true,
              snap: true,
              toolbarHeight: 60,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.tune, color: theme.colorScheme.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All', 0),
                            const SizedBox(width: 8),
                            _buildFilterChip('Chemicals', 1),
                            const SizedBox(width: 8),
                            _buildFilterChip('Bio', 2),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          body: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _filteredCategories.length,
            itemBuilder: (context, index) {
              final category = _filteredCategories[index];
              return CategoryCard(
                title: category['title'],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductListScreen(
                        category: category['title'],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedTab == index;
    final theme = Theme.of(context);
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedTab = index;
        });
      },
      selectedColor: theme.colorScheme.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade600,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
        ),
      ),
      showCheckmark: false,
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Image
              Positioned.fill(
                child: Image.network(
                  "https://picsum.photos/400?random=${title.hashCode}",
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: Colors.grey.shade300);
                  },
                ),
              ),
              
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              // Text Label
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
