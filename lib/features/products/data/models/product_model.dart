import 'package:krishikranti/core/constants/api_constants.dart';

class Product {
  final String id;
  final String title;
  final String? brandName;
  final String? technicalName;
  final String? vendor;
  final String? availabilityStatus;
  final String thumbnail;
  final List<Variant> variants;
  final double averageRating;
  final int numReviews;
  final String? categoryId;
  final String? subCategoryId;
  final List<String> tags;
  final ProductDetail? details;
  final List<String> images;
  final double? minPrice;
  final double? maxPrice;

  Product({
    required this.id,
    required this.title,
    this.brandName,
    this.technicalName,
    this.vendor,
    this.availabilityStatus,
    required this.thumbnail,
    required this.variants,
    this.averageRating = 0.0,
    this.numReviews = 0,
    this.categoryId,
    this.subCategoryId,
    this.tags = const [],
    this.details,
    this.images = const [],
    this.minPrice,
    this.maxPrice,
  });

  // Helper to get minimum price (uses backend value if available, else calculates)
  double get price {
    if (minPrice != null) return minPrice!;
    if (variants.isEmpty) return 0.0;
    return variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);
  }

  // Helper to get the variant with the lowest price
  Variant? get lowestPriceVariant {
    if (variants.isEmpty) return null;
    return variants.reduce((a, b) => a.price < b.price ? a : b);
  }

  // Helper to get max compareAtPrice
  double get compareAtPrice {
    if (maxPrice != null) return maxPrice!;
    if (variants.isEmpty) return 0.0;
    return variants
        .map((v) => v.compareAtPrice)
        .reduce((a, b) => a > b ? a : b);
  }

  static String _parseId(dynamic id) {
    if (id == null) return '';
    if (id is String) return id;
    if (id is Map && id.containsKey('\$oid')) return id['\$oid'].toString();
    return id.toString();
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static String _resolveImageUrl(String path) {
    if (path.isEmpty) return '';

    // Handle Google Drive links
    if (path.contains('drive.google.com')) {
      final idMatch = RegExp(
        r'(?:id=|\/d\/|folders\/)([a-zA-Z0-9-_]+)',
      ).firstMatch(path);
      if (idMatch != null) {
        final fileId = idMatch.group(1);
        // Using the thumbnail endpoint which is very reliable for Drive images
        return 'https://drive.google.com/thumbnail?id=$fileId&sz=w1000';
      }
    }

    if (path.startsWith('http')) return path;
    // Ensure no double slashes
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${ApiConstants.baseUrl}/$cleanPath';
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _parseId(json['_id']),
      title: json['title'] ?? '',
      brandName: json['brandName'],
      technicalName: json['technicalName'],
      vendor: json['vendor'],
      availabilityStatus: json['availabilityStatus'],
      thumbnail: _resolveImageUrl(json['thumbnail'] ?? ''),
      variants:
          (json['variants'] as List?)
              ?.map((v) => Variant.fromJson(v))
              .toList() ??
          [],
      averageRating: _parseDouble(json['averageRating']),
      numReviews: json['numReviews'] ?? 0,
      categoryId: _parseId(json['categoryId']),
      subCategoryId: _parseId(json['subCategoryId']),
      tags: List<String>.from(json['tags'] ?? []),
      images:
          (json['images'] as List?)
              ?.map((img) => _resolveImageUrl(img.toString()))
              .toList() ??
          [],
      details: json['details'] != null
          ? ProductDetail.fromJson(json['details'])
          : (json['description'] != null || json['specifications'] != null)
          ? ProductDetail(
              id: _parseId(json['_id']),
              productId: _parseId(json['_id']),
              description: json['description'] ?? '',
              mediumImages:
                  (json['mediumImages'] as List?)
                      ?.map((img) => _resolveImageUrl(img.toString()))
                      .toList() ??
                  [],
              originalImages:
                  (json['originalImages'] as List?)
                      ?.map((img) => _resolveImageUrl(img.toString()))
                      .toList() ??
                  [],
              specifications: Map<String, dynamic>.from(
                json['specifications'] ?? {},
              ),
            )
          : null,
      minPrice: json['minPrice'] != null
          ? _parseDouble(json['minPrice'])
          : null,
      maxPrice: json['maxPrice'] != null
          ? _parseDouble(json['maxPrice'])
          : null,
    );
  }
}

class PriceTier {
  final String id;
  final String name;

  PriceTier({required this.id, required this.name});

  factory PriceTier.fromJson(Map<String, dynamic> json) {
    return PriceTier(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class _ParsedTier {
  final String id;
  final String name;
  final double? min;
  final double? max;
  final double rate;

  _ParsedTier({
    required this.id,
    required this.name,
    this.min,
    this.max,
    required this.rate,
  });
}

class Variant {
  final String id;
  final String size;
  final double price;
  final double compareAtPrice;
  final double price10_30;
  final double price30_50;
  final double price50_plus;
  final double packVolume;
  final String? basePacking;
  // Canonical base unit: 'lit', 'kg', or 'pcs' — used for rate suffix display
  final String basePackingUnit;
  final List<PriceTier> priceTiers;
  final Map<String, String> rates;

  Variant({
    required this.id,
    required this.size,
    required this.price,
    required this.compareAtPrice,
    this.price10_30 = 0.0,
    this.price30_50 = 0.0,
    this.price50_plus = 0.0,
    this.packVolume = 1.0,
    this.basePacking,
    this.basePackingUnit = 'lit',
    this.priceTiers = const [],
    this.rates = const {},
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    final double basePrice = Product._parseDouble(json['price']);
    final String sizeStr = json['size'] ?? '';

    List<PriceTier> tiers = [];
    if (json['priceTiers'] != null) {
      try {
        tiers = (json['priceTiers'] as List)
            .map((t) => PriceTier.fromJson(Map<String, dynamic>.from(t)))
            .toList();
      } catch (_) {}
    }

    Map<String, String> ratesMap = {};
    if (json['rates'] != null) {
      try {
        ratesMap = Map<String, String>.from(
          (json['rates'] as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
        );
      } catch (_) {}
    }

    return Variant(
      id: Product._parseId(json['_id']),
      size: sizeStr,
      price: basePrice,
      compareAtPrice: Product._parseDouble(json['compareAtPrice']),
      price10_30: json['price10_30'] != null
          ? Product._parseDouble(json['price10_30'])
          : basePrice,
      price30_50: json['price30_50'] != null
          ? Product._parseDouble(json['price30_50'])
          : basePrice,
      price50_plus: json['price50_plus'] != null
          ? Product._parseDouble(json['price50_plus'])
          : basePrice,
      packVolume: json['packVolume'] != null
          ? Product._parseDouble(json['packVolume'])
          : 1.0,
      basePacking: json['basePacking']?.toString(),
      // Read explicit basePackingUnit; fall back to guessing from basePacking/size string
      basePackingUnit: _parseBasePackingUnit(
        json['basePackingUnit']?.toString(),
        json['basePacking']?.toString(),
        sizeStr,
      ),
      priceTiers: tiers,
      rates: ratesMap,
    );
  }

  /// Resolves the canonical base packing unit with fallback chain:
  /// 1. Explicit `basePackingUnit` field from backend (new field)
  /// 2. Parse from `basePacking` string (e.g. "10lit" -> "lit")
  /// 3. Guess from `size` string (legacy fallback)
  static String _parseBasePackingUnit(
    String? explicitUnit,
    String? basePackingStr,
    String sizeStr,
  ) {
    // 1. Explicit field wins
    if (explicitUnit != null && explicitUnit.isNotEmpty) {
      final u = explicitUnit.toLowerCase().trim();
      if (u == 'pcs' || u == 'piece' || u == 'pieces') return 'pcs';
      if (u == 'kg' || u == 'kilogram') return 'kg';
      if (u == 'lit' || u == 'litre' || u == 'l') return 'lit';
      if (u == 'ml') return 'lit'; // ml -> stored as lit
      if (u == 'gm' || u == 'gram' || u == 'g') return 'kg'; // gm -> stored as kg
      return u;
    }
    // 2. Parse from basePacking string
    if (basePackingStr != null && basePackingStr.isNotEmpty) {
      final clean = basePackingStr.toLowerCase().replaceAll(RegExp(r'\s+'), '');
      final match = RegExp(
        r'^[\d.]+(ml|lit|litre|l|gm|gram|g|kg|kilogram|k|pcs|piece|pieces)$',
      ).firstMatch(clean);
      if (match != null) {
        final raw = match.group(1) ?? '';
        if (raw == 'pcs' || raw == 'piece' || raw == 'pieces') return 'pcs';
        if (raw == 'kg' || raw == 'kilogram' || raw == 'k') return 'kg';
        if (raw == 'gm' || raw == 'gram' || raw == 'g') return 'kg';
        return 'lit'; // ml, lit, litre, l
      }
    }
    // 3. Legacy fallback: guess from size string
    final s = sizeStr.toLowerCase();
    if (s.contains('pcs') || s.contains('piece')) return 'pcs';
    if (s.contains('kg') || s.contains('gm') || s.contains('gram')) return 'kg';
    return 'lit';
  }

  static Map<String, double?> parseTierRange(String name) {
    final regexParentheses = RegExp(r'\(([^)]+)\)');
    final match = regexParentheses.firstMatch(name);
    String content = '';
    if (match != null) {
      content = match.group(1)!;
    } else {
      content = name;
    }

    final clean = content.replaceAll(RegExp(r'[^0-9.\-+]'), '');

    if (clean.endsWith('+')) {
      final minStr = clean.substring(0, clean.length - 1);
      final min = double.tryParse(minStr);
      return {'min': min, 'max': null};
    } else if (clean.contains('-')) {
      final parts = clean.split('-');
      if (parts.length == 2) {
        final min = double.tryParse(parts[0]);
        final max = double.tryParse(parts[1]);
        return {'min': min, 'max': max};
      }
    }

    final numbers = RegExp(r'\d+(?:\.\d+)?')
        .allMatches(clean)
        .map((m) => double.tryParse(m.group(0) ?? ''))
        .toList();
    if (numbers.isNotEmpty) {
      if (clean.contains('+') || numbers.length == 1) {
        return {'min': numbers.first, 'max': null};
      } else if (numbers.length >= 2) {
        return {'min': numbers[0], 'max': numbers[1]};
      }
    }

    return {'min': null, 'max': null};
  }

  static double? parseRateValue(String? rateStr) {
    if (rateStr == null || rateStr.isEmpty) return null;
    final clean = rateStr.split('/').first.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(clean);
  }

  double getTierUnitPriceForVolume(double totalVolume) {
    if (priceTiers.isEmpty || rates.isEmpty) {
      if (totalVolume > 50.0 && price50_plus > 0) {
        return price50_plus;
      } else if (totalVolume > 30.0 && price30_50 > 0) {
        return price30_50;
      } else if (totalVolume >= 10.0 && price10_30 > 0) {
        return price10_30;
      }
      return price;
    }

    List<_ParsedTier> parsedTiers = [];
    for (var tier in priceTiers) {
      final range = parseTierRange(tier.name);
      final rateVal = parseRateValue(rates[tier.id]);
      if (rateVal != null) {
        parsedTiers.add(_ParsedTier(
          id: tier.id,
          name: tier.name,
          min: range['min'],
          max: range['max'],
          rate: rateVal,
        ));
      }
    }

    if (parsedTiers.isEmpty) {
      if (totalVolume > 50.0 && price50_plus > 0) {
        return price50_plus;
      } else if (totalVolume > 30.0 && price30_50 > 0) {
        return price30_50;
      } else if (totalVolume >= 10.0 && price10_30 > 0) {
        return price10_30;
      }
      return price;
    }

    parsedTiers.sort((a, b) {
      final aMin = a.min ?? 0.0;
      final bMin = b.min ?? 0.0;
      return aMin.compareTo(bMin);
    });

    for (int i = 0; i < parsedTiers.length; i++) {
      final tier = parsedTiers[i];
      final min = tier.min;
      final max = tier.max;

      if (i == 0 && min != null && totalVolume < min) {
        return price;
      }

      if (min != null) {
        if (max != null) {
          if (totalVolume >= min && totalVolume < max) {
            return tier.rate;
          }
        } else {
          if (totalVolume >= min) {
            return tier.rate;
          }
        }
      }
    }

    final lastTier = parsedTiers.last;
    if (lastTier.min != null && totalVolume >= lastTier.min!) {
      return lastTier.rate;
    }

    return price;
  }

  String getActiveTierId(double totalVolume) {
    if (priceTiers.isEmpty || rates.isEmpty) return "";

    List<_ParsedTier> parsedTiers = [];
    for (var tier in priceTiers) {
      final range = parseTierRange(tier.name);
      final rateVal = parseRateValue(rates[tier.id]);
      if (rateVal != null) {
        parsedTiers.add(_ParsedTier(
          id: tier.id,
          name: tier.name,
          min: range['min'],
          max: range['max'],
          rate: rateVal,
        ));
      }
    }

    if (parsedTiers.isEmpty) return "";

    parsedTiers.sort((a, b) {
      final aMin = a.min ?? 0.0;
      final bMin = b.min ?? 0.0;
      return aMin.compareTo(bMin);
    });

    for (int i = 0; i < parsedTiers.length; i++) {
      final tier = parsedTiers[i];
      final min = tier.min;
      final max = tier.max;

      if (i == 0 && min != null && totalVolume < min) {
        return "";
      }

      if (min != null) {
        if (max != null) {
          if (totalVolume >= min && totalVolume < max) {
            return tier.id;
          }
        } else {
          if (totalVolume >= min) {
            return tier.id;
          }
        }
      }
    }

    final lastTier = parsedTiers.last;
    if (lastTier.min != null && totalVolume >= lastTier.min!) {
      return lastTier.id;
    }

    return "";
  }

  String getActiveTierName(double totalVolume) {
    if (priceTiers.isEmpty || rates.isEmpty) {
      if (totalVolume > 50.0 && price50_plus > 0) return "50L+ Tier";
      if (totalVolume > 30.0 && price30_50 > 0) return "30-50L Tier";
      if (totalVolume >= 10.0 && price10_30 > 0) return "10-30L Tier";
      return "";
    }

    final tierId = getActiveTierId(totalVolume);
    if (tierId.isNotEmpty) {
      final tier = priceTiers.firstWhere((t) => t.id == tierId);
      return tier.name;
    }

    return "";
  }

  double get minTierPrice {
    double minVal = price;
    if (priceTiers.isEmpty || rates.isEmpty) {
      if (price10_30 > 0 && price10_30 < minVal) minVal = price10_30;
      if (price30_50 > 0 && price30_50 < minVal) minVal = price30_50;
      if (price50_plus > 0 && price50_plus < minVal) minVal = price50_plus;
      return minVal;
    }
    for (var tier in priceTiers) {
      final rateVal = parseRateValue(rates[tier.id]);
      if (rateVal != null && rateVal > 0 && rateVal < minVal) {
        minVal = rateVal;
      }
    }
    return minVal;
  }

  bool get hasBulkDiscount => minTierPrice < price;

  double get bulkDiscountPercent => hasBulkDiscount ? ((price - minTierPrice) / price * 100) : 0.0;
}

class ProductDetail {
  final String id;
  final String productId;
  final String description;
  final List<String> mediumImages;
  final List<String> originalImages;
  final Map<String, dynamic> specifications;

  ProductDetail({
    required this.id,
    required this.productId,
    required this.description,
    required this.mediumImages,
    required this.originalImages,
    required this.specifications,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: Product._parseId(json['_id']),
      productId: Product._parseId(json['productId']),
      description: json['description'] ?? '',
      mediumImages: List<String>.from(
        json['images']?['medium'] ?? [],
      ).map((img) => Product._resolveImageUrl(img)).toList(),
      originalImages: List<String>.from(
        json['images']?['original'] ?? [],
      ).map((img) => Product._resolveImageUrl(img)).toList(),
      specifications: json['specifications'] ?? {},
    );
  }
}
