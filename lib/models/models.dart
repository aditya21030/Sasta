import 'package:flutter/material.dart';

import '../theme/sasta_tokens.dart';

enum RetailerId {
  blinkit(
    id: 'blinkit',
    name: 'Blinkit',
    shortName: 'Blinkit',
    eta: '9 mins',
    color: SastaColors.blinkit,
    deliveryFee: 25,
    schemeUrl: 'blinkit://search',
  ),
  zepto(
    id: 'zepto',
    name: 'Zepto',
    shortName: 'Zepto',
    eta: '8 mins',
    color: SastaColors.zepto,
    deliveryFee: 20,
    schemeUrl: 'zepto://search',
  ),
  instamart(
    id: 'instamart',
    name: 'Swiggy Instamart',
    shortName: 'Instamart',
    eta: '12 mins',
    color: SastaColors.instamart,
    deliveryFee: 29,
    schemeUrl: 'swiggy://instamart',
  ),
  flipkartMinutes(
    id: 'flipkart_minutes',
    name: 'Flipkart Minutes',
    shortName: 'Flipkart Minutes',
    eta: '14 mins',
    color: SastaColors.flipkartMinutes,
    deliveryFee: 20,
    schemeUrl: 'flipkart://minutes',
  );

  const RetailerId({
    required this.id,
    required this.name,
    required this.shortName,
    required this.eta,
    required this.color,
    required this.deliveryFee,
    required this.schemeUrl,
  });

  final String id;
  final String name;
  final String shortName;
  final String eta;
  final Color color;
  final int deliveryFee;
  final String schemeUrl;

  static RetailerId? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final normalized = raw.trim().toLowerCase();
    for (final value in RetailerId.values) {
      if (value.id == normalized || value.name.toLowerCase() == normalized) {
        return value;
      }
    }
    if (normalized == 'swiggy_instamart' || normalized == 'swiggy instamart') {
      return RetailerId.instamart;
    }
    if (normalized == 'flipkart' || normalized == 'minutes') {
      return RetailerId.flipkartMinutes;
    }
    return null;
  }
}

ProductArtKind _parseArtKind(String? raw) {
  if (raw == null || raw.isEmpty) return ProductArtKind.snacks;
  final normalized = raw.trim().toLowerCase().replaceAll('_', '');
  for (final kind in ProductArtKind.values) {
    if (kind.name.toLowerCase() == normalized) return kind;
  }
  return ProductArtKind.snacks;
}

StockStatus _parseStockStatus(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'lowstock':
    case 'low_stock':
      return StockStatus.lowStock;
    case 'outofstock':
    case 'out_of_stock':
      return StockStatus.outOfStock;
    default:
      return StockStatus.inStock;
  }
}

NotificationKind _parseNotificationKind(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'pricedrop':
    case 'price_drop':
      return NotificationKind.priceDrop;
    case 'targetreached':
    case 'target_reached':
      return NotificationKind.targetReached;
    case 'backinstock':
    case 'back_in_stock':
      return NotificationKind.backInStock;
    case 'savings':
      return NotificationKind.savings;
    default:
      return NotificationKind.update;
  }
}

SastaPastel _parsePastel(String? raw) {
  if (raw == null || raw.isEmpty) return SastaPastel.lavender;
  final normalized = raw.trim().toLowerCase();
  for (final p in SastaPastel.values) {
    if (p.name.toLowerCase() == normalized) return p;
  }
  return SastaPastel.lavender;
}

String _str(Map<String, dynamic> j, String a, [String? b, String fallback = '']) {
  final v = j[a] ?? (b != null ? j[b] : null);
  return v == null ? fallback : v.toString();
}

String? _strOrNull(Map<String, dynamic> j, String a, [String? b]) {
  final v = j[a] ?? (b != null ? j[b] : null);
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

int? _intOrNull(Map<String, dynamic> j, String a, [String? b]) {
  final v = j[a] ?? (b != null ? j[b] : null);
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.round();
  return int.tryParse(v.toString());
}

int _int(Map<String, dynamic> j, String a, [String? b, int fallback = 0]) {
  return _intOrNull(j, a, b) ?? fallback;
}

double _double(Map<String, dynamic> j, String a, [String? b, double fallback = 0]) {
  final v = j[a] ?? (b != null ? j[b] : null);
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

bool _bool(Map<String, dynamic> j, String a, [String? b, bool fallback = false]) {
  final v = j[a] ?? (b != null ? j[b] : null);
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is num) return v != 0;
  return v.toString().toLowerCase() == 'true';
}

enum ProductArtKind {
  milk,
  bread,
  eggs,
  rice,
  atta,
  curd,
  oil,
  butter,
  salt,
  noodles,
  tea,
  coffee,
  biscuits,
  veg,
  snacks,
  detergent,
  iceCream,
  babyCare,
  meat,
  beverage,
}

enum StockStatus { inStock, lowStock, outOfStock }

enum CategoryIconKind {
  milk,
  apple,
  cookie,
  cup,
  grain,
  bottle,
  sparkle,
  spray,
  heart,
  snowflake,
  croissant,
  fish,
}

@immutable
class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.pastel,
    required this.iconKind,
  });

  final String id;
  final String name;
  final String subtitle;
  final SastaPastel pastel;
  final CategoryIconKind iconKind;
}

@immutable
class RetailerQuote {
  const RetailerQuote({
    required this.retailer,
    required this.price,
    this.mrp,
    required this.packLabel,
    required this.unitPriceText,
    required this.stockStatus,
    this.lowStockCount,
  });

  final RetailerId retailer;
  final int? price;
  final int? mrp;
  final String packLabel;
  final String unitPriceText;
  final StockStatus stockStatus;
  final int? lowStockCount;

  bool get isAvailable => stockStatus != StockStatus.outOfStock && price != null;

  int? get discountPercent {
    if (price == null || mrp == null || mrp! <= price!) return null;
    return (((mrp! - price!) / mrp!) * 100).round();
  }

  Map<String, dynamic> toJson() => {
        'retailer': retailer.id,
        'price': price,
        'mrp': mrp,
        'packLabel': packLabel,
        'unitPriceText': unitPriceText,
        'stockStatus': stockStatus.name,
        'lowStockCount': lowStockCount,
      };

  factory RetailerQuote.fromJson(Map<String, dynamic> json) {
    final retailer =
        RetailerId.tryParse(_strOrNull(json, 'retailer', 'retailer_id')) ??
            RetailerId.blinkit;
    final price = _intOrNull(json, 'price');
    final rawStatus = _strOrNull(json, 'stockStatus', 'stock_status');
    final stockStatus = rawStatus != null
        ? _parseStockStatus(rawStatus)
        : (price == null ? StockStatus.outOfStock : StockStatus.inStock);
    return RetailerQuote(
      retailer: retailer,
      price: price,
      mrp: _intOrNull(json, 'mrp'),
      packLabel: _str(json, 'packLabel', 'pack_label', '1 unit'),
      unitPriceText: _str(json, 'unitPriceText', 'unit_price_text', ''),
      stockStatus: stockStatus,
      lowStockCount: _intOrNull(json, 'lowStockCount', 'low_stock_count'),
    );
  }
}

@immutable
class PackVariant {
  const PackVariant({
    required this.label,
    required this.quotes,
    this.saveBadge,
  });

  final String label;
  final List<RetailerQuote> quotes;
  final String? saveBadge;

  Map<String, dynamic> toJson() => {
        'label': label,
        'quotes': quotes.map((q) => q.toJson()).toList(),
        if (saveBadge != null) 'saveBadge': saveBadge,
      };

  factory PackVariant.fromJson(Map<String, dynamic> json) {
    final rawQuotes = json['quotes'] as List<dynamic>? ?? const [];
    return PackVariant(
      label: _str(json, 'label', null, 'Standard'),
      quotes: rawQuotes
          .whereType<Map>()
          .map((e) => RetailerQuote.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      saveBadge: _strOrNull(json, 'saveBadge', 'save_badge'),
    );
  }
}

@immutable
class PriceHistorySeries {
  const PriceHistorySeries({
    required this.primaryPoints,
    required this.secondaryPoints,
    required this.startLabel,
    required this.endLabel,
    required this.lowest,
    required this.highest,
    required this.average,
  });

  final List<int> primaryPoints;
  final List<int> secondaryPoints;
  final String startLabel;
  final String endLabel;
  final int lowest;
  final int highest;
  final double average;

  Map<String, dynamic> toJson() => {
        'primaryPoints': primaryPoints,
        'secondaryPoints': secondaryPoints,
        'startLabel': startLabel,
        'endLabel': endLabel,
        'lowest': lowest,
        'highest': highest,
        'average': average,
      };

  factory PriceHistorySeries.fromJson(Map<String, dynamic> json) {
    final primaryRaw =
        (json['primaryPoints'] ?? json['primary_points']) as List<dynamic>? ??
            const [];
    final secondaryRaw =
        (json['secondaryPoints'] ?? json['secondary_points']) as List<dynamic>? ??
            const [];
    final primary = primaryRaw
        .map((e) => e is num ? e.round() : int.tryParse(e.toString()) ?? 0)
        .toList();
    final secondary = secondaryRaw
        .map((e) => e is num ? e.round() : int.tryParse(e.toString()) ?? 0)
        .toList();
    final lowest = _intOrNull(json, 'lowest') ??
        (primary.isEmpty ? 0 : primary.reduce((a, b) => a < b ? a : b));
    final highest = _intOrNull(json, 'highest') ??
        (primary.isEmpty ? 0 : primary.reduce((a, b) => a > b ? a : b));
    final average = _double(
      json,
      'average',
      null,
      primary.isEmpty
          ? 0.0
          : primary.fold<int>(0, (s, p) => s + p) / primary.length,
    );
    return PriceHistorySeries(
      primaryPoints: primary,
      secondaryPoints: secondary,
      startLabel: _str(json, 'startLabel', 'start_label', '30d ago'),
      endLabel: _str(json, 'endLabel', 'end_label', 'Today'),
      lowest: lowest,
      highest: highest,
      average: average,
    );
  }
}

@immutable
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.categoryId,
    required this.categoryLabel,
    required this.subtitle,
    required this.artKind,
    required this.pastel,
    required this.variants,
    required this.defaultVariantIndex,
    required this.historyByRange,
    this.trendTag,
    this.isLowestIn30Days = false,
    this.isTrending = false,
    this.isDeal = false,
    this.isPriceDrop = false,
    this.onlyOnRetailer,
    this.oftenAddedNote,
  });

  final String id;
  final String name;
  final String brand;
  final String categoryId;
  final String categoryLabel;
  final String subtitle;
  final ProductArtKind artKind;
  final SastaPastel pastel;
  final List<PackVariant> variants;
  final int defaultVariantIndex;
  final Map<String, PriceHistorySeries> historyByRange;
  final String? trendTag;
  final bool isLowestIn30Days;
  final bool isTrending;
  final bool isDeal;
  final bool isPriceDrop;
  final RetailerId? onlyOnRetailer;
  final String? oftenAddedNote;

  PackVariant variantAt(int index) {
    if (index >= 0 && index < variants.length) return variants[index];
    return variants[defaultVariantIndex];
  }

  RetailerQuote? cheapestQuote(
    int variantIndex, {
    Set<RetailerId>? enabledRetailers,
    bool inStockOnly = false,
  }) {
    final quotes = variantAt(variantIndex).quotes.where((q) {
      if (enabledRetailers != null && !enabledRetailers.contains(q.retailer)) {
        return false;
      }
      if (inStockOnly) return q.isAvailable;
      return q.isAvailable;
    }).toList();
    if (quotes.isEmpty) return null;
    quotes.sort((a, b) => a.price!.compareTo(b.price!));
    return quotes.first;
  }

  List<RetailerQuote> sortedQuotes(
    int variantIndex, {
    Set<RetailerId>? enabledRetailers,
  }) {
    final quotes = variantAt(variantIndex).quotes.where((q) {
      return enabledRetailers == null || enabledRetailers.contains(q.retailer);
    }).toList();
    quotes.sort((a, b) {
      if (a.isAvailable != b.isAvailable) return a.isAvailable ? -1 : 1;
      if (!a.isAvailable && !b.isAvailable) return 0;
      if (a.stockStatus == StockStatus.inStock &&
          b.stockStatus == StockStatus.lowStock) {
        return -1;
      }
      if (a.stockStatus == StockStatus.lowStock &&
          b.stockStatus == StockStatus.inStock) {
        return 1;
      }
      return a.price!.compareTo(b.price!);
    });
    return quotes;
  }

  int availableAppCount(
    int variantIndex, {
    Set<RetailerId>? enabledRetailers,
  }) {
    return variantAt(variantIndex)
        .quotes
        .where((q) =>
            (enabledRetailers == null ||
                enabledRetailers.contains(q.retailer)) &&
            q.isAvailable)
        .length;
  }

  Product copyWith({
    String? name,
    String? brand,
    String? categoryId,
    String? categoryLabel,
    String? subtitle,
    List<PackVariant>? variants,
    int? defaultVariantIndex,
    Map<String, PriceHistorySeries>? historyByRange,
    String? trendTag,
    bool? isLowestIn30Days,
    bool? isTrending,
    bool? isDeal,
    bool? isPriceDrop,
    RetailerId? onlyOnRetailer,
    String? oftenAddedNote,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      categoryId: categoryId ?? this.categoryId,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      subtitle: subtitle ?? this.subtitle,
      artKind: artKind,
      pastel: pastel,
      variants: variants ?? this.variants,
      defaultVariantIndex: defaultVariantIndex ?? this.defaultVariantIndex,
      historyByRange: historyByRange ?? this.historyByRange,
      trendTag: trendTag ?? this.trendTag,
      isLowestIn30Days: isLowestIn30Days ?? this.isLowestIn30Days,
      isTrending: isTrending ?? this.isTrending,
      isDeal: isDeal ?? this.isDeal,
      isPriceDrop: isPriceDrop ?? this.isPriceDrop,
      onlyOnRetailer: onlyOnRetailer ?? this.onlyOnRetailer,
      oftenAddedNote: oftenAddedNote ?? this.oftenAddedNote,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'categoryId': categoryId,
        'categoryLabel': categoryLabel,
        'subtitle': subtitle,
        'artKind': artKind.name,
        'pastel': pastel.name,
        'variants': variants.map((v) => v.toJson()).toList(),
        'defaultVariantIndex': defaultVariantIndex,
        'historyByRange':
            historyByRange.map((k, v) => MapEntry(k, v.toJson())),
        if (trendTag != null) 'trendTag': trendTag,
        'isLowestIn30Days': isLowestIn30Days,
        'isTrending': isTrending,
        'isDeal': isDeal,
        'isPriceDrop': isPriceDrop,
        if (onlyOnRetailer != null) 'onlyOnRetailer': onlyOnRetailer!.id,
        if (oftenAddedNote != null) 'oftenAddedNote': oftenAddedNote,
      };

  factory Product.fromJson(Map<String, dynamic> json) {
    final variantsRaw = json['variants'] as List<dynamic>? ?? const [];
    final variants = variantsRaw
        .whereType<Map>()
        .map((e) => PackVariant.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final historyRaw =
        (json['historyByRange'] ?? json['history_by_range']) as Map?;
    final history = <String, PriceHistorySeries>{};
    if (historyRaw != null) {
      historyRaw.forEach((key, value) {
        if (value is Map) {
          history[key.toString()] = PriceHistorySeries.fromJson(
            Map<String, dynamic>.from(value),
          );
        }
      });
    }
    return Product(
      id: _str(json, 'id'),
      name: _str(json, 'name'),
      brand: _str(json, 'brand'),
      categoryId: _str(json, 'categoryId', 'category_id', 'dairy'),
      categoryLabel:
          _str(json, 'categoryLabel', 'category_label', 'Dairy & Staples'),
      subtitle: _str(json, 'subtitle'),
      artKind: _parseArtKind(_strOrNull(json, 'artKind', 'art_kind')),
      pastel: _parsePastel(_strOrNull(json, 'pastel')),
      variants: variants.isEmpty
          ? const [
              PackVariant(label: '1 unit', quotes: []),
            ]
          : variants,
      defaultVariantIndex:
          _int(json, 'defaultVariantIndex', 'default_variant_index', 0),
      historyByRange: history,
      trendTag: _strOrNull(json, 'trendTag', 'trend_tag'),
      isLowestIn30Days:
          _bool(json, 'isLowestIn30Days', 'is_lowest_in_30_days'),
      isTrending: _bool(json, 'isTrending', 'is_trending'),
      isDeal: _bool(json, 'isDeal', 'is_deal'),
      isPriceDrop: _bool(json, 'isPriceDrop', 'is_price_drop'),
      onlyOnRetailer: RetailerId.tryParse(
        _strOrNull(json, 'onlyOnRetailer', 'only_on_retailer'),
      ),
      oftenAddedNote: _strOrNull(json, 'oftenAddedNote', 'often_added_note'),
    );
  }
}

@immutable
class BasketEntry {
  const BasketEntry({
    required this.productId,
    required this.variantIndex,
    required this.quantity,
  });

  final String productId;
  final int variantIndex;
  final int quantity;

  BasketEntry copyWith({int? variantIndex, int? quantity}) {
    return BasketEntry(
      productId: productId,
      variantIndex: variantIndex ?? this.variantIndex,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'variantIndex': variantIndex,
        'quantity': quantity,
      };

  factory BasketEntry.fromJson(Map<String, dynamic> json) => BasketEntry(
        productId: _str(json, 'productId', 'product_id'),
        variantIndex: _int(json, 'variantIndex', 'variant_index', 0),
        quantity: _int(json, 'quantity', null, 1),
      );
}

@immutable
class SavedBasket {
  const SavedBasket({
    required this.id,
    required this.name,
    required this.entries,
    required this.updatedLabel,
    required this.pastel,
  });

  final String id;
  final String name;
  final List<BasketEntry> entries;
  final String updatedLabel;
  final SastaPastel pastel;

  int get uniqueProducts => entries.length;
  int get totalItems => entries.fold(0, (sum, e) => sum + e.quantity);

  SavedBasket copyWith({
    String? name,
    List<BasketEntry>? entries,
    String? updatedLabel,
    SastaPastel? pastel,
  }) {
    return SavedBasket(
      id: id,
      name: name ?? this.name,
      entries: entries ?? this.entries,
      updatedLabel: updatedLabel ?? this.updatedLabel,
      pastel: pastel ?? this.pastel,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'entries': entries.map((e) => e.toJson()).toList(),
        'updatedLabel': updatedLabel,
        'pastel': pastel.name,
      };

  factory SavedBasket.fromJson(Map<String, dynamic> json) {
    final entriesRaw = json['entries'] as List<dynamic>? ?? const [];
    return SavedBasket(
      id: _str(json, 'id'),
      name: _str(json, 'name', null, 'Basket'),
      entries: entriesRaw
          .whereType<Map>()
          .map((e) => BasketEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      updatedLabel: _str(json, 'updatedLabel', 'updated_label', 'Saved'),
      pastel: _parsePastel(_strOrNull(json, 'pastel')),
    );
  }
}

@immutable
class BasketTemplate {
  const BasketTemplate({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.productIds,
    required this.pastel,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<String> productIds;
  final SastaPastel pastel;
}

@immutable
class BasketActivityItem {
  const BasketActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.kind,
    this.productId,
  });

  final String id;
  final String title;
  final String subtitle;
  final String kind; // added, removed, qty, compared
  final String? productId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'kind': kind,
        if (productId != null) 'productId': productId,
      };

  factory BasketActivityItem.fromJson(Map<String, dynamic> json) =>
      BasketActivityItem(
        id: _str(json, 'id'),
        title: _str(json, 'title'),
        subtitle: _str(json, 'subtitle'),
        kind: _str(json, 'kind', null, 'added'),
        productId: _strOrNull(json, 'productId', 'product_id'),
      );
}

@immutable
class PriceAlert {
  const PriceAlert({
    required this.id,
    required this.productId,
    required this.targetPrice,
    required this.createdLabel,
  });

  final String id;
  final String productId;
  final int targetPrice;
  final String createdLabel;

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'targetPrice': targetPrice,
        'createdLabel': createdLabel,
      };

  factory PriceAlert.fromJson(Map<String, dynamic> json) => PriceAlert(
        id: _str(json, 'id'),
        productId: _str(json, 'productId', 'product_id'),
        targetPrice: _int(json, 'targetPrice', 'target_price', 0),
        createdLabel: _str(json, 'createdLabel', 'created_label', 'Saved'),
      );
}

enum NotificationKind { priceDrop, targetReached, backInStock, savings, update }

@immutable
class SastaNotification {
  const SastaNotification({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.kind,
    required this.isUnread,
    this.productId,
  });

  final String id;
  final String title;
  final String subtitle;
  final String timeLabel;
  final NotificationKind kind;
  final bool isUnread;
  final String? productId;

  SastaNotification copyWith({bool? isUnread}) {
    return SastaNotification(
      id: id,
      title: title,
      subtitle: subtitle,
      timeLabel: timeLabel,
      kind: kind,
      isUnread: isUnread ?? this.isUnread,
      productId: productId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'timeLabel': timeLabel,
        'kind': kind.name,
        'isUnread': isUnread,
        if (productId != null) 'productId': productId,
      };

  factory SastaNotification.fromJson(Map<String, dynamic> json) =>
      SastaNotification(
        id: _str(json, 'id'),
        title: _str(json, 'title'),
        subtitle: _str(json, 'subtitle'),
        timeLabel: _str(json, 'timeLabel', 'time_label', 'Now'),
        kind: _parseNotificationKind(_strOrNull(json, 'kind')),
        isUnread: _bool(json, 'isUnread', 'is_unread', true),
        productId: _strOrNull(json, 'productId', 'product_id'),
      );
}

@immutable
class SavedLocation {
  const SavedLocation({
    required this.id,
    required this.label,
    required this.pincode,
    required this.area,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String pincode;
  final String area;
  final bool isDefault;

  SavedLocation copyWith({
    String? label,
    String? pincode,
    String? area,
    bool? isDefault,
  }) {
    return SavedLocation(
      id: id,
      label: label ?? this.label,
      pincode: pincode ?? this.pincode,
      area: area ?? this.area,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'pincode': pincode,
        'area': area,
        'isDefault': isDefault,
      };

  factory SavedLocation.fromJson(Map<String, dynamic> json) => SavedLocation(
        id: _str(json, 'id'),
        label: _str(json, 'label', null, 'Other'),
        pincode: _str(json, 'pincode'),
        area: _str(json, 'area'),
        isDefault: _bool(json, 'isDefault', 'is_default', false),
      );
}

@immutable
class SearchHistoryEntry {
  const SearchHistoryEntry({
    required this.id,
    required this.query,
    required this.subtitle,
    required this.isToday,
    required this.artKind,
    required this.pastel,
  });

  final String id;
  final String query;
  final String subtitle;
  final bool isToday;
  final ProductArtKind artKind;
  final SastaPastel pastel;

  Map<String, dynamic> toJson() => {
        'id': id,
        'query': query,
        'subtitle': subtitle,
        'isToday': isToday,
        'artKind': artKind.name,
        'pastel': pastel.name,
      };

  factory SearchHistoryEntry.fromJson(Map<String, dynamic> json) =>
      SearchHistoryEntry(
        id: _str(json, 'id'),
        query: _str(json, 'query'),
        subtitle: _str(json, 'subtitle'),
        isToday: _bool(json, 'isToday', 'is_today', true),
        artKind: _parseArtKind(_strOrNull(json, 'artKind', 'art_kind')),
        pastel: _parsePastel(_strOrNull(json, 'pastel')),
      );
}

@immutable
class FaqItem {
  const FaqItem({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
  });

  final String id;
  final String category;
  final String question;
  final String answer;
}

@immutable
class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.topic,
    required this.subject,
    required this.message,
    required this.dateLabel,
    required this.status,
  });

  final String id;
  final String topic;
  final String subject;
  final String message;
  final String dateLabel;
  final String status;

  Map<String, dynamic> toJson() => {
        'id': id,
        'topic': topic,
        'subject': subject,
        'message': message,
        'dateLabel': dateLabel,
        'status': status,
      };

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
        id: _str(json, 'id'),
        topic: _str(json, 'topic'),
        subject: _str(json, 'subject'),
        message: _str(json, 'message'),
        dateLabel: _str(json, 'dateLabel', 'date_label'),
        status: _str(json, 'status', null, 'Open'),
      );
}

enum SastaPlanType { free, monthly, yearly }

@immutable
class SubscriptionInvoice {
  const SubscriptionInvoice({
    required this.id,
    required this.planName,
    required this.dateLabel,
    required this.txnCode,
    required this.amount,
    required this.status, // Paid, Failed, Refunded
  });

  final String id;
  final String planName;
  final String dateLabel;
  final String txnCode;
  final int amount;
  final String status;

  Map<String, dynamic> toJson() => {
        'id': id,
        'planName': planName,
        'dateLabel': dateLabel,
        'txnCode': txnCode,
        'amount': amount,
        'status': status,
      };

  factory SubscriptionInvoice.fromJson(Map<String, dynamic> json) =>
      SubscriptionInvoice(
        id: _str(json, 'id'),
        planName: _str(json, 'planName', 'plan_name'),
        dateLabel: _str(json, 'dateLabel', 'date_label'),
        txnCode: _str(json, 'txnCode', 'txn_code'),
        amount: _int(json, 'amount'),
        status: _str(json, 'status', null, 'Paid'),
      );
}

@immutable
class StoreBasketTotal {
  const StoreBasketTotal({
    required this.retailer,
    required this.totalPrice,
    required this.availableCount,
    required this.totalProducts,
    required this.missingProductNames,
  });

  final RetailerId retailer;
  final int totalPrice;
  final int availableCount;
  final int totalProducts;
  final List<String> missingProductNames;

  bool get isComplete => availableCount == totalProducts && totalProducts > 0;
}

@immutable
class SplitStoreSlice {
  const SplitStoreSlice({
    required this.retailer,
    required this.lines,
    required this.subtotal,
  });

  final RetailerId retailer;
  final List<({Product product, int quantity, String pack, int lineTotal})>
      lines;
  final int subtotal;
}

@immutable
class PerItemSaving {
  const PerItemSaving({
    required this.product,
    required this.bestUnitPrice,
    required this.worstUnitPrice,
    required this.quantity,
  });

  final Product product;
  final int bestUnitPrice;
  final int worstUnitPrice;
  final int quantity;

  int get totalSaved => (worstUnitPrice - bestUnitPrice) * quantity;
}

@immutable
class BasketComparisonResult {
  const BasketComparisonResult({
    required this.storeTotals,
    required this.cheapestCompleteStore,
    required this.priciestCompleteStore,
    required this.splitSlices,
    required this.splitTotal,
    required this.unavailableProducts,
    required this.perItemSavings,
  });

  final List<StoreBasketTotal> storeTotals;
  final StoreBasketTotal? cheapestCompleteStore;
  final StoreBasketTotal? priciestCompleteStore;
  final List<SplitStoreSlice> splitSlices;
  final int splitTotal;
  final List<Product> unavailableProducts;
  final List<PerItemSaving> perItemSavings;

  int get savingsVsPriciest {
    if (cheapestCompleteStore == null || priciestCompleteStore == null) {
      return perItemSavings.fold(0, (s, e) => s + e.totalSaved);
    }
    final diff = priciestCompleteStore!.totalPrice -
        cheapestCompleteStore!.totalPrice;
    return diff > 0 ? diff : 0;
  }

  int get percentSavedVsPriciest {
    if (priciestCompleteStore == null ||
        priciestCompleteStore!.totalPrice <= 0) {
      return 0;
    }
    return ((savingsVsPriciest / priciestCompleteStore!.totalPrice) * 100)
        .round();
  }

  int get splitSavingsOverBestSingle {
    if (cheapestCompleteStore == null) return 0;
    final diff = cheapestCompleteStore!.totalPrice - splitTotal;
    return diff > 0 ? diff : 0;
  }

  bool get isSplitWorthIt =>
      splitSlices.length > 1 && splitSavingsOverBestSingle >= 20;
}
