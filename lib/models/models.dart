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
