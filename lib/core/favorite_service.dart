import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:krishikranti/core/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:krishikranti/core/network/http_service.dart';

class FavoriteProduct {
  final String id;
  final String name;
  final String category;
  final String price;
  final String imageUrl;
  final String weight;

  FavoriteProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    this.weight = "1 unit",
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'price': price,
    'imageUrl': imageUrl,
    'weight': weight,
  };

  factory FavoriteProduct.fromJson(Map<String, dynamic> json) =>
      FavoriteProduct(
        id: json['id'] ?? json['product']?['_id'] ?? '',
        name: json['name'] ?? json['product']?['title'] ?? '',
        category: json['category'] ?? 'Product',
        price:
            json['price'] ??
            (json['product']?['variants'] != null
                ? json['product']['variants'][0]['price'].toString()
                : '0'),
        imageUrl:
            json['imageUrl'] ??
            (json['product']?['images'] != null
                ? json['product']['images'][0]
                : ''),
        weight: json['weight'] ?? "1 unit",
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteProduct &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class FavoriteService extends ChangeNotifier {
  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;
  FavoriteService._internal() {
    _loadFromDisk();
    syncWithBackend(); // Background sync
  }

  final Set<FavoriteProduct> _favorites = {};
  bool _isSyncing = false;

  List<FavoriteProduct> get favorites => _favorites.toList();
  bool get isSyncing => _isSyncing;

  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesJson = prefs.getString('favorite_products');
    if (favoritesJson != null) {
      final List<dynamic> decoded = jsonDecode(favoritesJson);
      _favorites.clear();
      _favorites.addAll(decoded.map((item) => FavoriteProduct.fromJson(item)));
      notifyListeners();
    }
  }

  Future<void> syncWithBackend() async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    try {
      final response = await HttpService.get(ApiConstants.favourites);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List favsJson = data['favourites'] ?? [];

        final freshFavs = favsJson
            .map((j) => FavoriteProduct.fromJson(j))
            .toList();

        _favorites.clear();
        _favorites.addAll(freshFavs);
        await _saveToDisk();
      }
    } catch (_) {
      // Background sync failed, we keep local data
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      _favorites.map((p) => p.toJson()).toList(),
    );
    await prefs.setString('favorite_products', encoded);
  }

  Future<void> toggleFavorite(FavoriteProduct product) async {
    final isAdding = !_favorites.contains(product);

    // 1. Optimistic Update
    if (isAdding) {
      _favorites.add(product);
    } else {
      _favorites.remove(product);
    }
    notifyListeners();
    await _saveToDisk();

    // 2. Sync with Backend
    try {
      if (isAdding) {
        await HttpService.post(
          ApiConstants.favourites,
          body: {'productId': product.id},
        );
      } else {
        await HttpService.delete("${ApiConstants.favourites}/${product.id}");
      }
    } catch (e) {
      // 3. Rollback on failure
      if (isAdding) {
        _favorites.remove(product);
      } else {
        _favorites.add(product);
      }
      notifyListeners();
      await _saveToDisk();
    }
  }

  bool isFavorite(String productId) {
    return _favorites.any((p) => p.id == productId);
  }
}
