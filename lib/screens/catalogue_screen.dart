import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class CatalogueScreen extends StatelessWidget {
  const CatalogueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Product Catalogue'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.square_grid_2x2_fill,
              size: 100,
              color: Theme.of(context).primaryColor.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text('Browse Catalog', style: Theme.of(context).textTheme.headlineMedium),
            const Text('All fertilizers and seeds in one place.'),
          ],
        ),
      ),
    );
  }
}
