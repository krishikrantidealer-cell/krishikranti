import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/core/cart_service.dart';
import 'package:krishikranti/core/favorite_service.dart';
import 'package:krishikranti/screens/shipping_address_screen.dart';
import 'package:krishikranti/screens/cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productName;

  const ProductDetailScreen({super.key, required this.productName});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color lightGreenBg = const Color(0xFFE8F5E9);
  final Color buyNowGreen = const Color(0xFF2E7D32);
  final Color addToCartOrange = const Color(0xFFFF9800);

  final FavoriteService _favoriteService = FavoriteService();

  @override
  void initState() {
    super.initState();
    _favoriteService.addListener(_onFavoriteChanged);
  }

  @override
  void dispose() {
    _favoriteService.removeListener(_onFavoriteChanged);
    super.dispose();
  }

  void _onFavoriteChanged() {
    if (mounted) setState(() {});
  }

  void _toggleFavorite() {
    final product = FavoriteProduct(
      name: widget.productName,
      category: "Plant Growth Regulator", 
      price: "450", 
      imageUrl: "https://picsum.photos/600/300",
    );
    _favoriteService.toggleFavorite(product);
  }

  // Base prices for 1 unit of each pack
  final Map<String, int> basePrices = {
    '1LTR x 10 PACK': 4500,
    '500 ML x 20 PACK': 3900,
    '250 ML x 40 PACK': 3800,
  };

  final Map<String, int> pricePerLtr = {
    '1LTR x 10 PACK': 450,
    '500 ML x 20 PACK': 390,
    '250 ML x 40 PACK': 380,
  };

  Map<String, int> quantityMap = {
    '1LTR x 10 PACK': 0,
    '500 ML x 20 PACK': 0,
    '250 ML x 40 PACK': 0,
  };

  final Map<String, int> itemsPerPack = {
    '1LTR x 10 PACK': 10,
    '500 ML x 20 PACK': 20,
    '250 ML x 40 PACK': 40,
  };

  int get totalItems {
    int total = 0;
    quantityMap.forEach((key, value) {
      total += value; // Count number of selected packs only
    });
    return total;
  }

  int get grandTotal {
    int total = 0;
    quantityMap.forEach((key, value) {
      total += value * basePrices[key]!;
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Section: Full Width Image & Plain Icons
                    Stack(
                      children: [
                        Image.network(
                          "https://picsum.photos/600/300",
                          width: double.infinity,
                          height: 280,
                          fit: BoxFit.cover,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildTopIcon(
                                icon: CupertinoIcons.back,
                                onTap: () => Navigator.pop(context),
                              ),
                              Row(
                                children: [
                                  _buildTopIcon(
                                    icon: Icons.share_outlined,
                                    onTap: () {
                                      Share.share('Check out this product: ${widget.productName}');
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  _buildTopIcon(
                                    icon: _favoriteService.isFavorite(widget.productName) ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                                    iconColor: _favoriteService.isFavorite(widget.productName) ? Colors.red : Colors.black87,
                                    onTap: _toggleFavorite,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Text(
                                  "4.2",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                SizedBox(width: 2),
                                Icon(Icons.star, color: Colors.white, size: 12),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.productName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: lightGreenBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Plant Growth Regulator",
                              style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Technical Content: Homobrassinolide 0.04%",
                            style: TextStyle(color: Colors.black87, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 1. FEATURES SECTION
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      clipBehavior: Clip.none,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFeatureCard("Enhances Growth"),
                          const SizedBox(width: 8),
                          _buildFeatureCard("Improves Flowering"),
                          const SizedBox(width: 8),
                          _buildFeatureCard("Increases Yield"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // KYC Section
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: lightGreenBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(CupertinoIcons.lock_shield_fill, color: primaryGreen, size: 24),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    "Complete KYC to unlock wholesale pricing",
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                                  ),
                                ),
                                SizedBox(
                                  height: 32,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/ekyc');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryGreen,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                    ),
                                    child: const Text("Complete KYC", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Price Section
                          const Row(
                            children: [
                              Text(
                                "₹500",
                                style: TextStyle(
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                "₹450",
                                style: TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                "[33% OFF]",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          const Text(
                            "Select Pack Size",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),

                          // Pack Size Cards
                          ...quantityMap.keys.map((pack) {
                            return PackSizeCard(
                              title: pack,
                              pricePerLtr: "price per 1 liter: ₹${pricePerLtr[pack]}",
                              price: basePrices[pack]! * (quantityMap[pack]! > 0 ? quantityMap[pack]! : 1),
                              quantity: quantityMap[pack]!,
                              onAdd: () => setState(() => quantityMap[pack] = quantityMap[pack]! + 1),
                              onRemove: () {
                                if (quantityMap[pack]! > 0) {
                                  setState(() => quantityMap[pack] = quantityMap[pack]! - 1);
                                }
                              },
                            );
                          }),

                          const SizedBox(height: 24),

                          // 2. TOTAL SECTION CARD (MATCH REFERENCE EXACTLY)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primaryGreen, width: 1),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      "Total Items: ",
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Colors.black87),
                                    ),
                                    Text(
                                      "$totalItems",
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "Grand Total: ",
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: primaryGreen),
                                    ),
                                    Text(
                                      "₹ $grandTotal",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          final cartService = CartService();
                          bool added = false;

                          quantityMap.forEach((key, value) {
                            if (value > 0) {
                              cartService.addItem(
                                productId: widget.productName, // Using name as ID for now
                                productName: widget.productName,
                                productImage: "https://picsum.photos/600/300",
                                technicalName: "Homobrassinolide 0.04%",
                                variant: key,
                                price: basePrices[key]!.toDouble(),
                                qty: value,
                              );
                              added = true;
                            }
                          });

                          if (added) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CartScreen()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please select a pack size")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: addToCartOrange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(l10n.cart, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          final cartService = CartService();
                          bool added = false;

                          quantityMap.forEach((key, value) {
                            if (value > 0) {
                              cartService.addItem(
                                productId: widget.productName,
                                productName: widget.productName,
                                productImage: "https://picsum.photos/600/300",
                                technicalName: "Homobrassinolide 0.04%",
                                variant: key,
                                price: basePrices[key]!.toDouble(),
                                qty: value,
                              );
                              added = true;
                            }
                          });

                          if (added) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ShippingAddressScreen()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please select a pack size")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buyNowGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text("Buy Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
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

  Widget _buildFeatureCard(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check,
            color: const Color(0xFF1B5E20), // Darker green
            size: 16,
            weight: 700, // Bold (if supported by font)
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopIcon({required IconData icon, required VoidCallback onTap, Color iconColor = Colors.black87}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}

class PackSizeCard extends StatelessWidget {
  final String title;
  final String pricePerLtr;
  final int price;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const PackSizeCard({
    super.key,
    required this.title,
    required this.pricePerLtr,
    required this.price,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF2E7D32);

    return GestureDetector(
      onTap: onAdd,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: quantity > 0 ? primaryGreen : Colors.grey.shade200, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pricePerLtr,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _qtyBtn(CupertinoIcons.minus, onRemove),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      "$quantity",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  _qtyBtn(CupertinoIcons.plus, onAdd, isAdd: true),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "₹ $price",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryGreen),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap, {bool isAdd = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isAdd ? const Color(0xFF2E7D32) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isAdd ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
