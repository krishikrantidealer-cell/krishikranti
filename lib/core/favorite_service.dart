import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteProduct {
  final String name;
  final String category;
  final String price;
  final String imageUrl;
  final String weight;

  FavoriteProduct({
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    this.weight = "1 unit",
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'price': price,
    'imageUrl': imageUrl,
    'weight': weight,
  };

  factory FavoriteProduct.fromJson(Map<String, dynamic> json) => FavoriteProduct(
    name: json['name'],
    category: json['category'],
    price: json['price'],
    imageUrl: json['imageUrl'],
    weight: json['weight'] ?? "1 unit",
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteProduct &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class FavoriteService extends ChangeNotifier {
  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;
  FavoriteService._internal() {
    _loadFavorites();
  }

  final Set<FavoriteProduct> _favorites = {};

  List<FavoriteProduct> get favorites => _favorites.toList();

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesJson = prefs.getString('favorite_products');
    if (favoritesJson != null) {
      final List<dynamic> decoded = jsonDecode(favoritesJson);
      _favorites.clear();
      _favorites.addAll(decoded.map((item) => FavoriteProduct.fromJson(item)));
      notifyListeners();
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_favorites.map((p) => p.toJson()).toList());
    await prefs.setString('favorite_products', encoded);
  }

  void toggleFavorite(FavoriteProduct product) {
    if (_favorites.contains(product)) {
      _favorites.remove(product);
    } else {
      _favorites.add(product);
    }
    _saveFavorites();
    notifyListeners();
  }

  bool isFavorite(String productName) {
    return _favorites.any((p) => p.name == productName);
  }
}
