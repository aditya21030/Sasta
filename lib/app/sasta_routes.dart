import 'package:flutter/material.dart';

import '../models/models.dart';

/// Typed route names and helper navigation calls across all 46 Sasta screens.
abstract final class SastaRouteNames {
  static const homeSearch = '/home/search';
  static const categories = '/home/categories';
  static const searchResults = '/search/results';
  static const productCompare = '/product/compare';
  static const productDetails = '/product/details';
  static const priceHistory = '/product/history';
  static const searchHistory = '/search/history';
  static const notifications = '/notifications';
  static const basketCompare = '/basket/compare';
  static const favouritesPush = '/saved/push';

  // Profile & account
  static const personalInfo = '/profile/personal-info';
  static const locations = '/profile/locations';
  static const security = '/profile/security';
  static const savedBaskets = '/profile/saved-baskets';
  static const comparisonPrefs = '/profile/prefs';
  static const appearance = '/profile/appearance';
  static const notificationSettings = '/profile/notification-settings';
  static const pincodePicker = '/profile/pincode-picker';

  // Sasta+
  static const plusLanding = '/plus/landing';
  static const plusPlans = '/plus/plans';
  static const plusCheckout = '/plus/checkout';
  static const plusSuccess = '/plus/success';
  static const plusManage = '/plus/manage';
  static const plusHistory = '/plus/history';

  // Help & legal
  static const helpCentre = '/help/centre';
  static const faq = '/help/faq';
  static const contactSupport = '/help/contact';
  static const sendFeedback = '/help/feedback';
  static const about = '/help/about';
  static const appInfo = '/help/app-info';
  static const privacy = '/help/privacy';
  static const terms = '/help/terms';
}

class SearchResultsArgs {
  const SearchResultsArgs({
    this.query = '',
    this.categoryId,
    this.titleOverride,
    this.dealsOnly = false,
    this.trendingOnly = false,
  });

  final String query;
  final String? categoryId;
  final String? titleOverride;
  final bool dealsOnly;
  final bool trendingOnly;
}

class ProductRouteArgs {
  const ProductRouteArgs({
    required this.productId,
    this.variantIndex,
  });

  final String productId;
  final int? variantIndex;
}

class BasketCompareArgs {
  const BasketCompareArgs({
    this.initialTab, // 0: Single store, 1: Split basket, 2: Savings
    this.customEntries,
  });

  final int? initialTab;
  final List<BasketEntry>? customEntries;
}

class CheckoutArgs {
  const CheckoutArgs({
    required this.planType,
    this.paymentMethod = 'UPI',
  });
  final SastaPlanType planType;
  final String paymentMethod;
}

abstract final class SastaNav {
  static Future<T?> push<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamed<T>(routeName, arguments: arguments);
  }

  static Future<void> openHomeSearch(BuildContext context) =>
      push(context, SastaRouteNames.homeSearch);

  static Future<void> openCategories(BuildContext context) =>
      push(context, SastaRouteNames.categories);

  static Future<void> openSearchResults(
    BuildContext context, {
    String query = '',
    String? categoryId,
    String? titleOverride,
    bool dealsOnly = false,
    bool trendingOnly = false,
  }) =>
      push(
        context,
        SastaRouteNames.searchResults,
        arguments: SearchResultsArgs(
          query: query,
          categoryId: categoryId,
          titleOverride: titleOverride,
          dealsOnly: dealsOnly,
          trendingOnly: trendingOnly,
        ),
      );

  static Future<void> openProductDetails(
    BuildContext context,
    String productId, {
    int? variantIndex,
  }) =>
      push(
        context,
        SastaRouteNames.productDetails,
        arguments: ProductRouteArgs(
          productId: productId,
          variantIndex: variantIndex,
        ),
      );

  static Future<void> openProductCompare(
    BuildContext context,
    String productId, {
    int? variantIndex,
  }) =>
      push(
        context,
        SastaRouteNames.productCompare,
        arguments: ProductRouteArgs(
          productId: productId,
          variantIndex: variantIndex,
        ),
      );

  static Future<void> openPriceHistory(
    BuildContext context,
    String productId, {
    int? variantIndex,
  }) =>
      push(
        context,
        SastaRouteNames.priceHistory,
        arguments: ProductRouteArgs(
          productId: productId,
          variantIndex: variantIndex,
        ),
      );

  static Future<void> openBasketCompare(
    BuildContext context, {
    int? initialTab,
    List<BasketEntry>? customEntries,
  }) =>
      push(
        context,
        SastaRouteNames.basketCompare,
        arguments: BasketCompareArgs(
          initialTab: initialTab,
          customEntries: customEntries,
        ),
      );
}
