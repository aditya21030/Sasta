import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Complete persisted user state and cached API catalog snapshot.
class SavedAppSnapshot {
  const SavedAppSnapshot({
    this.userName,
    this.userEmail,
    this.userPhone,
    this.phoneVerified,
    this.pincode,
    this.area,
    this.isOnboarded,
    this.isDarkMode,
    this.useLocation,
    this.priceDropAlerts,
    this.backInStockAlerts,
    this.weeklyDigest,
    this.enabledRetailerIds,
    this.sortMode,
    this.hideOos,
    this.showUnitPrice,
    this.deliveryFeeMode,
    this.autoMatchVariants,
    this.basketMode,
    this.selectedPlan,
    this.activeBasketId,
    this.recentlyViewedIds,
    this.apiBaseUrl,
    this.apiKey,
    this.lastSyncedAtIso,
    this.basketEntries,
    this.savedBaskets,
    this.activityLog,
    this.favouriteIds,
    this.alerts,
    this.notifications,
    this.savedLocations,
    this.searchHistory,
    this.tickets,
    this.invoices,
    this.cachedProducts,
  });

  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final bool? phoneVerified;
  final String? pincode;
  final String? area;
  final bool? isOnboarded;
  final bool? isDarkMode;
  final bool? useLocation;
  final bool? priceDropAlerts;
  final bool? backInStockAlerts;
  final bool? weeklyDigest;
  final List<String>? enabledRetailerIds;
  final String? sortMode;
  final bool? hideOos;
  final bool? showUnitPrice;
  final String? deliveryFeeMode;
  final bool? autoMatchVariants;
  final String? basketMode;
  final SastaPlanType? selectedPlan;
  final String? activeBasketId;
  final List<String>? recentlyViewedIds;
  final String? apiBaseUrl;
  final String? apiKey;
  final String? lastSyncedAtIso;
  final List<BasketEntry>? basketEntries;
  final List<SavedBasket>? savedBaskets;
  final List<BasketActivityItem>? activityLog;
  final List<String>? favouriteIds;
  final List<PriceAlert>? alerts;
  final List<SastaNotification>? notifications;
  final List<SavedLocation>? savedLocations;
  final List<SearchHistoryEntry>? searchHistory;
  final List<SupportTicket>? tickets;
  final List<SubscriptionInvoice>? invoices;
  final List<Product>? cachedProducts;

  Map<String, dynamic> toJson() => {
        'v': 1,
        if (userName != null) 'userName': userName,
        if (userEmail != null) 'userEmail': userEmail,
        if (userPhone != null) 'userPhone': userPhone,
        if (phoneVerified != null) 'phoneVerified': phoneVerified,
        if (pincode != null) 'pincode': pincode,
        if (area != null) 'area': area,
        if (isOnboarded != null) 'isOnboarded': isOnboarded,
        if (isDarkMode != null) 'isDarkMode': isDarkMode,
        if (useLocation != null) 'useLocation': useLocation,
        if (priceDropAlerts != null) 'priceDropAlerts': priceDropAlerts,
        if (backInStockAlerts != null) 'backInStockAlerts': backInStockAlerts,
        if (weeklyDigest != null) 'weeklyDigest': weeklyDigest,
        if (enabledRetailerIds != null)
          'enabledRetailerIds': enabledRetailerIds,
        if (sortMode != null) 'sortMode': sortMode,
        if (hideOos != null) 'hideOos': hideOos,
        if (showUnitPrice != null) 'showUnitPrice': showUnitPrice,
        if (deliveryFeeMode != null) 'deliveryFeeMode': deliveryFeeMode,
        if (autoMatchVariants != null) 'autoMatchVariants': autoMatchVariants,
        if (basketMode != null) 'basketMode': basketMode,
        if (selectedPlan != null) 'selectedPlan': selectedPlan!.name,
        if (activeBasketId != null) 'activeBasketId': activeBasketId,
        if (recentlyViewedIds != null) 'recentlyViewedIds': recentlyViewedIds,
        if (apiBaseUrl != null) 'apiBaseUrl': apiBaseUrl,
        if (apiKey != null) 'apiKey': apiKey,
        if (lastSyncedAtIso != null) 'lastSyncedAtIso': lastSyncedAtIso,
        if (basketEntries != null)
          'basketEntries': basketEntries!.map((e) => e.toJson()).toList(),
        if (savedBaskets != null)
          'savedBaskets': savedBaskets!.map((e) => e.toJson()).toList(),
        if (activityLog != null)
          'activityLog': activityLog!.map((e) => e.toJson()).toList(),
        if (favouriteIds != null) 'favouriteIds': favouriteIds,
        if (alerts != null) 'alerts': alerts!.map((e) => e.toJson()).toList(),
        if (notifications != null)
          'notifications': notifications!.map((e) => e.toJson()).toList(),
        if (savedLocations != null)
          'savedLocations': savedLocations!.map((e) => e.toJson()).toList(),
        if (searchHistory != null)
          'searchHistory': searchHistory!.map((e) => e.toJson()).toList(),
        if (tickets != null)
          'tickets': tickets!.map((e) => e.toJson()).toList(),
        if (invoices != null)
          'invoices': invoices!.map((e) => e.toJson()).toList(),
        if (cachedProducts != null)
          'cachedProducts': cachedProducts!.map((e) => e.toJson()).toList(),
      };

  factory SavedAppSnapshot.fromJson(Map<String, dynamic> j) {
    List<T>? decodeList<T>(
      String key,
      T Function(Map<String, dynamic>) mapper,
    ) {
      final raw = j[key];
      if (raw is! List) return null;
      return raw
          .whereType<Map>()
          .map((e) => mapper(Map<String, dynamic>.from(e)))
          .toList();
    }

    List<String>? decodeStrings(String key) {
      final raw = j[key];
      if (raw is! List) return null;
      return raw.map((e) => e.toString()).toList();
    }

    SastaPlanType? parsePlan(String? raw) {
      for (final plan in SastaPlanType.values) {
        if (plan.name == raw) return plan;
      }
      return null;
    }

    return SavedAppSnapshot(
      userName: j['userName']?.toString(),
      userEmail: j['userEmail']?.toString(),
      userPhone: j['userPhone']?.toString(),
      phoneVerified: j['phoneVerified'] as bool?,
      pincode: j['pincode']?.toString(),
      area: j['area']?.toString(),
      isOnboarded: j['isOnboarded'] as bool?,
      isDarkMode: j['isDarkMode'] as bool?,
      useLocation: j['useLocation'] as bool?,
      priceDropAlerts: j['priceDropAlerts'] as bool?,
      backInStockAlerts: j['backInStockAlerts'] as bool?,
      weeklyDigest: j['weeklyDigest'] as bool?,
      enabledRetailerIds: decodeStrings('enabledRetailerIds'),
      sortMode: j['sortMode']?.toString(),
      hideOos: j['hideOos'] as bool?,
      showUnitPrice: j['showUnitPrice'] as bool?,
      deliveryFeeMode: j['deliveryFeeMode']?.toString(),
      autoMatchVariants: j['autoMatchVariants'] as bool?,
      basketMode: j['basketMode']?.toString(),
      selectedPlan: parsePlan(j['selectedPlan']?.toString()),
      activeBasketId: j['activeBasketId']?.toString(),
      recentlyViewedIds: decodeStrings('recentlyViewedIds'),
      apiBaseUrl: j['apiBaseUrl']?.toString(),
      apiKey: j['apiKey']?.toString(),
      lastSyncedAtIso: j['lastSyncedAtIso']?.toString(),
      basketEntries: decodeList('basketEntries', BasketEntry.fromJson),
      savedBaskets: decodeList('savedBaskets', SavedBasket.fromJson),
      activityLog: decodeList('activityLog', BasketActivityItem.fromJson),
      favouriteIds: decodeStrings('favouriteIds'),
      alerts: decodeList('alerts', PriceAlert.fromJson),
      notifications: decodeList('notifications', SastaNotification.fromJson),
      savedLocations: decodeList('savedLocations', SavedLocation.fromJson),
      searchHistory: decodeList('searchHistory', SearchHistoryEntry.fromJson),
      tickets: decodeList('tickets', SupportTicket.fromJson),
      invoices: decodeList('invoices', SubscriptionInvoice.fromJson),
      cachedProducts: decodeList('cachedProducts', Product.fromJson),
    );
  }
}

/// Persists Sasta user state, settings, baskets, and cached catalog in SharedPreferences.
class LocalStorageService {
  LocalStorageService({Future<SharedPreferences> Function()? prefsProvider})
      : _prefsProvider = prefsProvider ?? SharedPreferences.getInstance;

  static const String stateStorageKey = 'sasta_app_state_v1';

  final Future<SharedPreferences> Function() _prefsProvider;

  Future<SavedAppSnapshot?> load() async {
    try {
      final prefs = await _prefsProvider();
      final raw = prefs.getString(stateStorageKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return SavedAppSnapshot.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(SavedAppSnapshot snapshot) async {
    try {
      final prefs = await _prefsProvider();
      await prefs.setString(stateStorageKey, jsonEncode(snapshot.toJson()));
    } catch (_) {
      // Persistence errors should never disrupt active shopping interactions.
    }
  }

  Future<void> clearAll() async {
    try {
      final prefs = await _prefsProvider();
      await prefs.remove(stateStorageKey);
    } catch (_) {
      // Ignore storage clear errors gracefully.
    }
  }
}
