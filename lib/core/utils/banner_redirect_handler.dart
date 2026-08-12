import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:krishikranti/features/products/data/models/banner_model.dart';
import 'package:krishikranti/features/products/data/models/product_model.dart';
import 'package:krishikranti/screens/product_list_screen.dart';
import 'package:krishikranti/screens/product_detail_screen.dart';
import 'package:krishikranti/screens/cart_screen.dart';
import 'package:krishikranti/features/auth/presentation/pages/ekyc_page.dart';
import 'package:krishikranti/screens/catalogue_screen.dart';

class BannerRedirectHandler {
  /// Handles seamless deep-linking and routing for all app banners
  static Future<void> handleBannerClick(
    BuildContext context,
    BannerModel banner, {
    VoidCallback? fallback,
  }) async {
    HapticFeedback.lightImpact();

    final redirectType = banner.redirectType.trim().toLowerCase();
    final target = banner.redirectTarget?.trim();

    debugPrint("[BannerRedirect] Processing banner '${banner.title}' -> Type: '$redirectType', Target: '$target'");

    if (redirectType == 'none') {
      if (fallback != null) {
        fallback();
      }
      return;
    }

    // 1. Category Redirect
    if (redirectType == 'category' && target != null && target.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductListScreen(
            category: target,
            categoryId: target,
          ),
        ),
      );
      return;
    }

    // 2. Product Detail Redirect
    if (redirectType == 'product' && target != null && target.isNotEmpty) {
      final placeholderProduct = Product(
        id: target,
        title: banner.title.isNotEmpty ? banner.title : 'Product',
        thumbnail: banner.imageUrl,
        variants: const [],
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(
            product: placeholderProduct,
            thumbnailUrl: banner.imageUrl,
          ),
        ),
      );
      return;
    }

    // 3. Collection Redirect
    if (redirectType == 'collection' && target != null && target.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductListScreen(
            category: target,
            collection: target,
            isCollection: true,
          ),
        ),
      );
      return;
    }

    // 4. External Web Link Redirect
    if (redirectType == 'external' && target != null && target.isNotEmpty) {
      try {
        final uri = Uri.parse(target.startsWith('http') ? target : 'https://$target');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (e) {
        debugPrint("[BannerRedirect] Error launching external URL '$target': $e");
      }
    }

    if (!context.mounted) return;

    // 5. Special Route Shortcuts
    if (redirectType == 'cart' || target == 'cart') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CartScreen()),
      );
      return;
    }

    if (redirectType == 'kyc' || target == 'kyc') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EkycPage()),
      );
      return;
    }

    if (redirectType == 'categories' || target == 'categories') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CatalogueScreen()),
      );
      return;
    }

    // Fallback if none of the above matched
    if (fallback != null) {
      fallback();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ProductListScreen(category: 'All'),
        ),
      );
    }
  }
}
