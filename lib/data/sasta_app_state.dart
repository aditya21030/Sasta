import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/sasta_tokens.dart';
import 'mock_catalog.dart';

/// Root reactive application state shared across all Sasta tabs and pushed flows.
class SastaAppState extends ChangeNotifier {
  // Flow & demo states
  bool _hasCompletedSplash = false;
  bool _hasSeenOnboarding = false;
  bool _hasSetPincode = false;
  bool _firstTimeUserMode = false;
  bool _homeOfflineError = false;
  bool _basketOfflineError = false;
  bool _isLoggedOut = false;

  // Theme
  ThemeMode _themeMode = ThemeMode.light;

  // Navigation tab (0: Home, 1: Basket, 2: Saved, 3: Profile)
  int _activeTabIndex = 0;

  // Profile details
  String _fullName = 'Your name';
  String _email = 'you@example.com';
  String _phone = '+91 98765 43210';
  final bool _emailVerified = true;
  bool _phoneVerified = false;
  bool _pushNotificationsAll = true;
  bool _priceDropsNotif = true;
  bool _targetAlertsNotif = true;
  bool _backInStockNotif = true;
  bool _newDealsNotif = false;
  bool _basketSavingsNotif = true;
  bool _weeklySummaryNotif = true;
  bool _appUpdatesNotif = false;

  // Comparison preferences
  final Set<RetailerId> _enabledRetailers = {
    RetailerId.blinkit,
    RetailerId.zepto,
    RetailerId.instamart,
    RetailerId.flipkartMinutes,
  };
  String _defaultSort = 'Lowest price'; // Lowest price, Best unit price, Availability
  bool _showUnitPrices = true;
  bool _includeUnavailable = true;
  bool _matchPackSizes = true;
  bool _suggestAlternatives = true;
  String _defaultBasketMode = 'Cheapest complete'; // Cheapest complete, Fewer retailers

  // Locations
  final List<SavedLocation> _locations = [
    const SavedLocation(
      id: 'loc_1',
      label: 'Home',
      pincode: '110001',
      area: 'Central Delhi',
      isDefault: true,
    ),
    const SavedLocation(
      id: 'loc_2',
      label: 'Work',
      pincode: '560001',
      area: 'Bengaluru',
    ),
    const SavedLocation(
      id: 'loc_3',
      label: 'Other',
      pincode: '400001',
      area: 'Mumbai',
    ),
  ];

  // Saved / Favourites
  final Set<String> _favouriteIds = {
    'amul_milk',
    'fortune_oil',
    'aashirvaad_atta',
    'basmati_rice',
  };

  // Price alerts
  final List<PriceAlert> _priceAlerts = [
    const PriceAlert(
      id: 'pa_1',
      productId: 'amul_milk',
      targetPrice: 26,
      createdLabel: 'Active',
    ),
    const PriceAlert(
      id: 'pa_2',
      productId: 'basmati_rice',
      targetPrice: 115,
      createdLabel: 'Active',
    ),
    const PriceAlert(
      id: 'pa_3',
      productId: 'fortune_oil',
      targetPrice: 138,
      createdLabel: 'Active',
    ),
  ];

  // Search history
  final List<SearchHistoryEntry> _searchHistory = [
    const SearchHistoryEntry(
      id: 'sh_1',
      query: 'Milk',
      subtitle: '4 apps · 2 min ago',
      isToday: true,
      artKind: ProductArtKind.milk,
      pastel: SastaPastel.sky,
    ),
    const SearchHistoryEntry(
      id: 'sh_2',
      query: 'Brown bread',
      subtitle: '4 apps · 1 hour ago',
      isToday: true,
      artKind: ProductArtKind.bread,
      pastel: SastaPastel.peach,
    ),
    const SearchHistoryEntry(
      id: 'sh_3',
      query: 'Basmati rice 1 kg',
      subtitle: 'Yesterday',
      isToday: false,
      artKind: ProductArtKind.rice,
      pastel: SastaPastel.lavender,
    ),
    const SearchHistoryEntry(
      id: 'sh_4',
      query: 'Cooking oil',
      subtitle: '3 days ago',
      isToday: false,
      artKind: ProductArtKind.oil,
      pastel: SastaPastel.butter,
    ),
    const SearchHistoryEntry(
      id: 'sh_5',
      query: 'Farm eggs 6 pcs',
      subtitle: 'Last week',
      isToday: false,
      artKind: ProductArtKind.eggs,
      pastel: SastaPastel.mint,
    ),
  ];

  // Notifications
  final List<SastaNotification> _notifications = [
    const SastaNotification(
      id: 'n_1',
      title: 'Toned milk dropped by ₹2 on Zepto',
      subtitle: 'Now ₹27 · cheapest near 110001',
      timeLabel: '2 min ago',
      kind: NotificationKind.priceDrop,
      isUnread: true,
      productId: 'amul_milk',
    ),
    const SastaNotification(
      id: 'n_2',
      title: 'Basmati rice hit ₹118',
      subtitle: 'Lowest price in 30 days',
      timeLabel: '1 hour ago',
      kind: NotificationKind.targetReached,
      isUnread: true,
      productId: 'basmati_rice',
    ),
    const SastaNotification(
      id: 'n_3',
      title: 'Amul Dahi back in stock on Blinkit',
      subtitle: 'Available at ₹32 for 400 g',
      timeLabel: '3 hours ago',
      kind: NotificationKind.backInStock,
      isUnread: true,
      productId: 'amul_dahi',
    ),
    const SastaNotification(
      id: 'n_4',
      title: 'You saved ~₹312 this month',
      subtitle: 'Up 16% from last month\'s estimated savings',
      timeLabel: 'Yesterday',
      kind: NotificationKind.savings,
      isUnread: false,
    ),
    const SastaNotification(
      id: 'n_5',
      title: 'New app update available',
      subtitle: 'Faster unit price & basket split insights',
      timeLabel: '2 days ago',
      kind: NotificationKind.update,
      isUnread: false,
    ),
  ];

  // Smart Baskets
  final List<SavedBasket> _savedBaskets = [
    const SavedBasket(
      id: 'b_weekly',
      name: 'Weekly Essentials',
      updatedLabel: 'Edited recently',
      pastel: SastaPastel.lavender,
      entries: [
        BasketEntry(productId: 'amul_milk', variantIndex: 1, quantity: 2),
        BasketEntry(productId: 'brown_bread', variantIndex: 0, quantity: 1),
        BasketEntry(productId: 'farm_eggs', variantIndex: 0, quantity: 1),
        BasketEntry(productId: 'basmati_rice', variantIndex: 0, quantity: 1),
      ],
    ),
    const SavedBasket(
      id: 'b_monthly',
      name: 'Monthly Groceries',
      updatedLabel: 'Edited yesterday',
      pastel: SastaPastel.sky,
      entries: [
        BasketEntry(productId: 'aashirvaad_atta', variantIndex: 0, quantity: 1),
        BasketEntry(productId: 'fortune_oil', variantIndex: 0, quantity: 2),
        BasketEntry(productId: 'basmati_rice', variantIndex: 1, quantity: 1),
        BasketEntry(productId: 'tata_salt', variantIndex: 0, quantity: 2),
        BasketEntry(productId: 'tata_tea', variantIndex: 0, quantity: 1),
        BasketEntry(productId: 'surf_excel', variantIndex: 0, quantity: 1),
      ],
    ),
    const SavedBasket(
      id: 'b_breakfast',
      name: 'Breakfast basics',
      updatedLabel: 'Edited 3 days ago',
      pastel: SastaPastel.butter,
      entries: [
        BasketEntry(productId: 'amul_milk', variantIndex: 1, quantity: 2),
        BasketEntry(productId: 'brown_bread', variantIndex: 0, quantity: 1),
        BasketEntry(productId: 'farm_eggs', variantIndex: 0, quantity: 1),
        BasketEntry(productId: 'amul_butter', variantIndex: 0, quantity: 1),
        BasketEntry(productId: 'amul_dahi', variantIndex: 0, quantity: 1),
      ],
    ),
    const SavedBasket(
      id: 'b_party',
      name: 'Party snacks',
      updatedLabel: 'Edited last week',
      pastel: SastaPastel.peach,
      entries: [
        BasketEntry(productId: 'maggi_noodles', variantIndex: 0, quantity: 2),
        BasketEntry(productId: 'parle_g', variantIndex: 0, quantity: 1),
        BasketEntry(productId: 'milkshake_mix', variantIndex: 0, quantity: 1),
      ],
    ),
  ];
  String _activeBasketId = 'b_weekly';
  final Set<String> _dismissedPickIds = {};
  final Set<String> _dismissedSuggestionIds = {};
  final List<BasketActivityItem> _basketActivities = [
    const BasketActivityItem(
      id: 'act_1',
      title: 'Added Farm Eggs',
      subtitle: '2 minutes ago',
      kind: 'added',
      productId: 'farm_eggs',
    ),
    const BasketActivityItem(
      id: 'act_2',
      title: 'Removed Amul Dahi',
      subtitle: '1 hour ago',
      kind: 'removed',
      productId: 'amul_dahi',
    ),
    const BasketActivityItem(
      id: 'act_3',
      title: 'Milk quantity 1 → 2',
      subtitle: 'Today',
      kind: 'qty',
      productId: 'amul_milk',
    ),
    const BasketActivityItem(
      id: 'act_4',
      title: 'Compared this basket',
      subtitle: '2 hours ago',
      kind: 'compared',
    ),
  ];

  // Recently viewed
  final List<String> _recentlyViewedIds = [
    'amul_milk',
    'farm_eggs',
    'fortune_oil',
    'basmati_rice',
    'brown_bread',
  ];

  // Sasta+ subscription
  SastaPlanType _planType = SastaPlanType.free;
  bool _autoRenew = true;
  final List<SubscriptionInvoice> _invoices = List.of(MockCatalog.defaultInvoices);

  // Support tickets
  final List<SupportTicket> _supportTickets = [
    const SupportTicket(
      id: 'tk_1',
      topic: 'Incorrect price',
      subject: 'Incorrect price on eggs',
      message: 'Price dropped in store app.',
      dateLabel: '2 Nov',
      status: 'Resolved',
    ),
    const SupportTicket(
      id: 'tk_2',
      topic: 'Location issue',
      subject: 'Pincode not found',
      message: 'Adding new PIN code area.',
      dateLabel: '28 Oct',
      status: 'In review',
    ),
  ];

  // Getters
  bool get hasCompletedSplash => _hasCompletedSplash;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  bool get hasSetPincode => _hasSetPincode;
  bool get firstTimeUserMode => _firstTimeUserMode;
  bool get homeOfflineError => _homeOfflineError;
  bool get basketOfflineError => _basketOfflineError;
  bool get isLoggedOut => _isLoggedOut;
  ThemeMode get themeMode => _themeMode;
  int get activeTabIndex => _activeTabIndex;

  String get fullName => _fullName;
  String get email => _email;
  String get phone => _phone;
  String get maskedPhone {
    if (_phone.length >= 10) {
      return '+91 ••••• ${_phone.substring(_phone.length - 5)}';
    }
    return '+91 ••••• •••••';
  }

  bool get emailVerified => _emailVerified;
  bool get phoneVerified => _phoneVerified;
  bool get pushNotificationsAll => _pushNotificationsAll;
  bool get priceDropsNotif => _priceDropsNotif;
  bool get targetAlertsNotif => _targetAlertsNotif;
  bool get backInStockNotif => _backInStockNotif;
  bool get newDealsNotif => _newDealsNotif;
  bool get basketSavingsNotif => _basketSavingsNotif;
  bool get weeklySummaryNotif => _weeklySummaryNotif;
  bool get appUpdatesNotif => _appUpdatesNotif;

  Set<RetailerId> get enabledRetailers => Set.unmodifiable(_enabledRetailers);
  String get defaultSort => _defaultSort;
  bool get showUnitPrices => _showUnitPrices;
  bool get includeUnavailable => _includeUnavailable;
  bool get matchPackSizes => _matchPackSizes;
  bool get suggestAlternatives => _suggestAlternatives;
  String get defaultBasketMode => _defaultBasketMode;

  List<SavedLocation> get locations => List.unmodifiable(_locations);
  SavedLocation get activeLocation => _locations.firstWhere(
        (l) => l.isDefault,
        orElse: () => _locations.first,
      );

  Set<String> get favouriteIds => Set.unmodifiable(_favouriteIds);
  List<PriceAlert> get priceAlerts => List.unmodifiable(_priceAlerts);
  List<SearchHistoryEntry> get searchHistory =>
      List.unmodifiable(_searchHistory);
  List<SastaNotification> get notifications =>
      List.unmodifiable(_notifications);
  int get unreadNotificationCount =>
      _notifications.where((n) => n.isUnread).length;

  List<SavedBasket> get savedBaskets => List.unmodifiable(_savedBaskets);
  SavedBasket get activeBasket => _savedBaskets.firstWhere(
        (b) => b.id == _activeBasketId,
        orElse: () => _savedBaskets.first,
      );
  List<BasketActivityItem> get basketActivities =>
      List.unmodifiable(_basketActivities);

  Set<String> get dismissedPickIds => Set.unmodifiable(_dismissedPickIds);
  Set<String> get dismissedSuggestionIds =>
      Set.unmodifiable(_dismissedSuggestionIds);

  List<Product> get recentlyViewedProducts => _recentlyViewedIds
      .map(productById)
      .whereType<Product>()
      .toList();

  SastaPlanType get planType => _planType;
  bool get isPlusActive => _planType != SastaPlanType.free;
  bool get autoRenew => _autoRenew;
  List<SubscriptionInvoice> get invoices => List.unmodifiable(_invoices);
  List<SupportTicket> get supportTickets => List.unmodifiable(_supportTickets);

  Product? productById(String id) {
    for (final p in MockCatalog.products) {
      if (p.id == id) return p;
    }
    return null;
  }

  // Actions
  void completeSplash() {
    if (_hasCompletedSplash) return;
    _hasCompletedSplash = true;
    notifyListeners();
  }

  void completeOnboarding() {
    _hasSeenOnboarding = true;
    notifyListeners();
  }

  void reopenOnboarding() {
    _hasSeenOnboarding = false;
    notifyListeners();
  }

  void completePincode(String pincode, {String area = 'Central Delhi'}) {
    final cleaned = pincode.trim();
    if (cleaned.length == 6) {
      final idx = _locations.indexWhere((l) => l.pincode == cleaned);
      if (idx != -1) {
        setDefaultLocation(_locations[idx].id);
      } else {
        for (var i = 0; i < _locations.length; i++) {
          _locations[i] = _locations[i].copyWith(isDefault: false);
        }
        _locations.insert(
          0,
          SavedLocation(
            id: 'loc_${DateTime.now().millisecondsSinceEpoch}',
            label: 'Home',
            pincode: cleaned,
            area: area,
            isDefault: true,
          ),
        );
      }
    }
    _hasSeenOnboarding = true;
    _hasSetPincode = true;
    _isLoggedOut = false;
    notifyListeners();
  }

  void setActiveTab(int index) {
    if (_activeTabIndex == index) return;
    _activeTabIndex = index;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setFirstTimeUserMode(bool value) {
    _firstTimeUserMode = value;
    notifyListeners();
  }

  void setHomeOfflineError(bool value) {
    _homeOfflineError = value;
    notifyListeners();
  }

  void setBasketOfflineError(bool value) {
    _basketOfflineError = value;
    notifyListeners();
  }

  void setDefaultLocation(String id) {
    for (var i = 0; i < _locations.length; i++) {
      _locations[i] = _locations[i].copyWith(isDefault: _locations[i].id == id);
    }
    notifyListeners();
  }

  void addLocation({
    required String label,
    required String pincode,
    required String area,
    bool makeDefault = false,
  }) {
    if (makeDefault) {
      for (var i = 0; i < _locations.length; i++) {
        _locations[i] = _locations[i].copyWith(isDefault: false);
      }
    }
    _locations.add(
      SavedLocation(
        id: 'loc_${DateTime.now().millisecondsSinceEpoch}',
        label: label,
        pincode: pincode,
        area: area,
        isDefault: makeDefault || _locations.isEmpty,
      ),
    );
    notifyListeners();
  }

  void updateLocation(SavedLocation updated) {
    final idx = _locations.indexWhere((l) => l.id == updated.id);
    if (idx != -1) {
      _locations[idx] = updated;
      notifyListeners();
    }
  }

  void deleteLocation(String id) {
    if (_locations.length <= 1) return;
    final wasDefault = _locations.any((l) => l.id == id && l.isDefault);
    _locations.removeWhere((l) => l.id == id);
    if (wasDefault && _locations.isNotEmpty) {
      _locations[0] = _locations[0].copyWith(isDefault: true);
    }
    notifyListeners();
  }

  bool isFavourite(String productId) => _favouriteIds.contains(productId);

  void toggleFavourite(String productId) {
    if (_favouriteIds.contains(productId)) {
      _favouriteIds.remove(productId);
    } else {
      _favouriteIds.add(productId);
    }
    notifyListeners();
  }

  void addToRecentlyViewed(String productId) {
    _recentlyViewedIds.remove(productId);
    _recentlyViewedIds.insert(0, productId);
    if (_recentlyViewedIds.length > 8) {
      _recentlyViewedIds.removeLast();
    }
    notifyListeners();
  }

  void addSearchQuery(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    _searchHistory.removeWhere(
      (entry) => entry.query.toLowerCase() == q.toLowerCase(),
    );
    final match = searchProducts(q);
    _searchHistory.insert(
      0,
      SearchHistoryEntry(
        id: 'sh_${DateTime.now().millisecondsSinceEpoch}',
        query: q,
        subtitle: '4 apps · just now',
        isToday: true,
        artKind: match.isNotEmpty ? match.first.artKind : ProductArtKind.milk,
        pastel: match.isNotEmpty ? match.first.pastel : SastaPastel.lavender,
      ),
    );
    notifyListeners();
  }

  void removeSearchHistory(String id) {
    _searchHistory.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void clearSearchHistory() {
    _searchHistory.clear();
    notifyListeners();
  }

  void markNotificationRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && _notifications[idx].isUnread) {
      _notifications[idx] = _notifications[idx].copyWith(isUnread: false);
      notifyListeners();
    }
  }

  void markAllNotificationsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isUnread: false);
    }
    notifyListeners();
  }

  void addPriceAlert(String productId, int targetPrice) {
    _priceAlerts.removeWhere((a) => a.productId == productId);
    _priceAlerts.insert(
      0,
      PriceAlert(
        id: 'pa_${DateTime.now().millisecondsSinceEpoch}',
        productId: productId,
        targetPrice: targetPrice,
        createdLabel: 'Just now',
      ),
    );
    notifyListeners();
  }

  void removePriceAlert(String id) {
    _priceAlerts.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  void dismissSmartPick(String id) {
    _dismissedPickIds.add(id);
    notifyListeners();
  }

  void dismissBasketSuggestion(String id) {
    _dismissedSuggestionIds.add(id);
    notifyListeners();
  }

  // Basket CRUD
  void selectActiveBasket(String id) {
    if (_savedBaskets.any((b) => b.id == id)) {
      _activeBasketId = id;
      notifyListeners();
    }
  }

  int quantityInActiveBasket(String productId, {int? variantIndex}) {
    for (final e in activeBasket.entries) {
      if (e.productId == productId &&
          (variantIndex == null || e.variantIndex == variantIndex)) {
        return e.quantity;
      }
    }
    return 0;
  }

  void addToBasket(
    String productId, {
    int? variantIndex,
    int delta = 1,
    String? basketId,
  }) {
    final targetId = basketId ?? _activeBasketId;
    final bIdx = _savedBaskets.indexWhere((b) => b.id == targetId);
    if (bIdx == -1) return;
    final basket = _savedBaskets[bIdx];
    final product = productById(productId);
    if (product == null) return;
    final resolvedVariant = variantIndex ?? product.defaultVariantIndex;

    final entries = List<BasketEntry>.from(basket.entries);
    final eIdx = entries.indexWhere((e) => e.productId == productId);
    if (eIdx != -1) {
      final current = entries[eIdx];
      final nextQty = current.quantity + delta;
      if (nextQty <= 0) {
        entries.removeAt(eIdx);
        _pushBasketActivity(
          'Removed ${product.name}',
          'Just now',
          'removed',
          productId: productId,
        );
      } else {
        entries[eIdx] = current.copyWith(
          variantIndex: variantIndex ?? current.variantIndex,
          quantity: nextQty,
        );
        if (delta > 0 && current.quantity == 1 && nextQty == 2) {
          _pushBasketActivity(
            '${product.name} quantity 1 → 2',
            'Just now',
            'qty',
            productId: productId,
          );
        }
      }
    } else if (delta > 0) {
      entries.add(
        BasketEntry(
          productId: productId,
          variantIndex: resolvedVariant,
          quantity: delta,
        ),
      );
      _pushBasketActivity(
        'Added ${product.name}',
        'Just now',
        'added',
        productId: productId,
      );
    }

    _savedBaskets[bIdx] = basket.copyWith(
      entries: entries,
      updatedLabel: 'Edited just now',
    );
    notifyListeners();
  }

  void updateBasketItemQuantity(String productId, int newQuantity) {
    final bIdx = _savedBaskets.indexWhere((b) => b.id == _activeBasketId);
    if (bIdx == -1) return;
    final basket = _savedBaskets[bIdx];
    final entries = List<BasketEntry>.from(basket.entries);
    final eIdx = entries.indexWhere((e) => e.productId == productId);
    if (eIdx == -1) return;

    final product = productById(productId);
    if (newQuantity <= 0) {
      entries.removeAt(eIdx);
      if (product != null) {
        _pushBasketActivity(
          'Removed ${product.name}',
          'Just now',
          'removed',
          productId: productId,
        );
      }
    } else {
      final old = entries[eIdx].quantity;
      entries[eIdx] = entries[eIdx].copyWith(quantity: newQuantity);
      if (product != null) {
        _pushBasketActivity(
          '${product.name} quantity $old → $newQuantity',
          'Just now',
          'qty',
          productId: productId,
        );
      }
    }
    _savedBaskets[bIdx] = basket.copyWith(
      entries: entries,
      updatedLabel: 'Edited just now',
    );
    notifyListeners();
  }

  void clearActiveBasket() {
    final bIdx = _savedBaskets.indexWhere((b) => b.id == _activeBasketId);
    if (bIdx == -1) return;
    _savedBaskets[bIdx] = _savedBaskets[bIdx].copyWith(
      entries: const [],
      updatedLabel: 'Cleared just now',
    );
    notifyListeners();
  }

  void removeBasketItems(Set<String> productIds) {
    final bIdx = _savedBaskets.indexWhere((b) => b.id == _activeBasketId);
    if (bIdx == -1) return;
    final entries = _savedBaskets[bIdx]
        .entries
        .where((e) => !productIds.contains(e.productId))
        .toList();
    _savedBaskets[bIdx] = _savedBaskets[bIdx].copyWith(
      entries: entries,
      updatedLabel: 'Edited just now',
    );
    notifyListeners();
  }

  void renameBasket(String id, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    final idx = _savedBaskets.indexWhere((b) => b.id == id);
    if (idx != -1) {
      _savedBaskets[idx] = _savedBaskets[idx].copyWith(
        name: trimmed,
        updatedLabel: 'Renamed just now',
      );
      notifyListeners();
    }
  }

  SavedBasket createNewBasket(String name, {List<BasketEntry>? initialEntries}) {
    final pastries = SastaPastel.values;
    final basket = SavedBasket(
      id: 'b_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'My Basket ${_savedBaskets.length + 1}' : name.trim(),
      entries: initialEntries ?? const [],
      updatedLabel: 'Created just now',
      pastel: pastries[_savedBaskets.length % pastries.length],
    );
    _savedBaskets.insert(0, basket);
    _activeBasketId = basket.id;
    notifyListeners();
    return basket;
  }

  void duplicateBasket(String id) {
    final src = _savedBaskets.firstWhere((b) => b.id == id);
    createNewBasket(
      '${src.name} (Copy)',
      initialEntries: List.of(src.entries),
    );
  }

  void deleteBasket(String id) {
    if (_savedBaskets.length <= 1) {
      clearActiveBasket();
      return;
    }
    _savedBaskets.removeWhere((b) => b.id == id);
    if (_activeBasketId == id) {
      _activeBasketId = _savedBaskets.first.id;
    }
    notifyListeners();
  }

  void applyTemplateToNewOrActiveBasket(BasketTemplate template) {
    final entries = <BasketEntry>[];
    for (final id in template.productIds) {
      final p = productById(id);
      if (p != null) {
        entries.add(
          BasketEntry(
            productId: id,
            variantIndex: p.defaultVariantIndex,
            quantity: 1,
          ),
        );
      }
    }
    createNewBasket(template.title, initialEntries: entries);
  }

  void _pushBasketActivity(
    String title,
    String subtitle,
    String kind, {
    String? productId,
  }) {
    _basketActivities.insert(
      0,
      BasketActivityItem(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        subtitle: subtitle,
        kind: kind,
        productId: productId,
      ),
    );
    if (_basketActivities.length > 10) {
      _basketActivities.removeLast();
    }
  }

  // Search & Filter engine
  List<Product> searchProducts(
    String query, {
    String? categoryId,
    RetailerId? retailerFilter,
    bool inStockOnly = false,
    int? maxPrice,
    String? sortBy,
  }) {
    final q = query.trim().toLowerCase();
    final filtered = MockCatalog.products.where((p) {
      if (categoryId != null && categoryId.isNotEmpty && p.categoryId != categoryId) {
        return false;
      }
      if (q.isNotEmpty) {
        final haystack =
            '${p.name} ${p.brand} ${p.categoryLabel} ${p.subtitle}'.toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      final cheapest = p.cheapestQuote(
        p.defaultVariantIndex,
        enabledRetailers:
            retailerFilter != null ? {retailerFilter} : _enabledRetailers,
      );
      if (inStockOnly && cheapest == null) return false;
      if (maxPrice != null && (cheapest?.price ?? 999999) > maxPrice) {
        return false;
      }
      return true;
    }).toList();

    final resolvedSort = sortBy ?? _defaultSort;
    if (resolvedSort == 'Lowest price') {
      filtered.sort((a, b) {
        final ap = a.cheapestQuote(a.defaultVariantIndex)?.price ?? 999999;
        final bp = b.cheapestQuote(b.defaultVariantIndex)?.price ?? 999999;
        return ap.compareTo(bp);
      });
    } else if (resolvedSort == 'Discount') {
      filtered.sort((a, b) {
        final ad =
            a.cheapestQuote(a.defaultVariantIndex)?.discountPercent ?? 0;
        final bd =
            b.cheapestQuote(b.defaultVariantIndex)?.discountPercent ?? 0;
        return bd.compareTo(ad);
      });
    }
    return filtered;
  }

  // Basket comparison calculation (single-store, split-basket, savings)
  BasketComparisonResult computeBasketComparison({
    List<BasketEntry>? customEntries,
  }) {
    final entries = customEntries ?? activeBasket.entries;
    final activeRetailers =
        _enabledRetailers.isEmpty ? RetailerId.values.toSet() : _enabledRetailers;

    final storeTotals = <StoreBasketTotal>[];
    final perItemSavings = <PerItemSaving>[];
    final unavailableProducts = <Product>[];
    final splitMap = <RetailerId,
        List<({Product product, int quantity, String pack, int lineTotal})>>{};

    // Precompute per-item best & worst & split winner
    for (final entry in entries) {
      final p = productById(entry.productId);
      if (p == null) continue;
      final variant = p.variantAt(entry.variantIndex);
      final availableQuotes = variant.quotes
          .where((q) => activeRetailers.contains(q.retailer) && q.isAvailable)
          .toList();

      if (availableQuotes.isEmpty) {
        unavailableProducts.add(p);
        continue;
      }

      // If matching pack sizes strictly for split winner, prefer exact pack match
      List<RetailerQuote> splitCandidates = availableQuotes;
      if (_matchPackSizes) {
        final exactPack = availableQuotes
            .where((q) => q.packLabel == variant.label)
            .toList();
        if (exactPack.isNotEmpty) {
          splitCandidates = exactPack;
        }
      }
      splitCandidates.sort((a, b) => a.price!.compareTo(b.price!));
      final bestForItem = splitCandidates.first;

      final prices = availableQuotes.map((q) => q.price!).toList()..sort();
      perItemSavings.add(
        PerItemSaving(
          product: p,
          bestUnitPrice: bestForItem.price!,
          worstUnitPrice: prices.last,
          quantity: entry.quantity,
        ),
      );

      splitMap.putIfAbsent(bestForItem.retailer, () => []).add((
        product: p,
        quantity: entry.quantity,
        pack: bestForItem.packLabel,
        lineTotal: bestForItem.price! * entry.quantity,
      ));
    }

    for (final r in activeRetailers) {
      var total = 0;
      var availableCount = 0;
      final missing = <String>[];
      for (final entry in entries) {
        final p = productById(entry.productId);
        if (p == null) continue;
        final variant = p.variantAt(entry.variantIndex);
        RetailerQuote? match;
        for (final q in variant.quotes) {
          if (q.retailer == r && q.isAvailable) {
            match = q;
            break;
          }
        }
        if (match != null) {
          total += match.price! * entry.quantity;
          availableCount++;
        } else {
          missing.add(p.name);
        }
      }
      storeTotals.add(
        StoreBasketTotal(
          retailer: r,
          totalPrice: total,
          availableCount: availableCount,
          totalProducts: entries.length,
          missingProductNames: missing,
        ),
      );
    }

    storeTotals.sort((a, b) {
      if (a.isComplete != b.isComplete) return a.isComplete ? -1 : 1;
      if (a.availableCount != b.availableCount) {
        return b.availableCount.compareTo(a.availableCount);
      }
      return a.totalPrice.compareTo(b.totalPrice);
    });

    final completeStores = storeTotals.where((s) => s.isComplete).toList()
      ..sort((a, b) => a.totalPrice.compareTo(b.totalPrice));

    final splitSlices = splitMap.entries.map((e) {
      final subtotal = e.value.fold(0, (s, line) => s + line.lineTotal);
      return SplitStoreSlice(
        retailer: e.key,
        lines: e.value,
        subtotal: subtotal,
      );
    }).toList()
      ..sort((a, b) => b.subtotal.compareTo(a.subtotal));

    final splitTotal = splitSlices.fold(0, (s, slice) => s + slice.subtotal);

    return BasketComparisonResult(
      storeTotals: storeTotals,
      cheapestCompleteStore:
          completeStores.isNotEmpty ? completeStores.first : null,
      priciestCompleteStore:
          completeStores.length > 1 ? completeStores.last : null,
      splitSlices: splitSlices,
      splitTotal: splitTotal,
      unavailableProducts: unavailableProducts,
      perItemSavings: perItemSavings,
    );
  }

  // Profile & Preferences mutations
  void updateProfile({
    required String name,
    required String email,
    required String phone,
  }) {
    _fullName = name.trim().isEmpty ? 'Your name' : name.trim();
    _email = email.trim().isEmpty ? 'you@example.com' : email.trim();
    _phone = phone.trim().isEmpty ? _phone : phone.trim();
    notifyListeners();
  }

  void verifyPhoneNow() {
    _phoneVerified = true;
    notifyListeners();
  }

  void toggleRetailer(RetailerId retailer, bool enabled) {
    if (!enabled && _enabledRetailers.length <= 1) return;
    if (enabled) {
      _enabledRetailers.add(retailer);
    } else {
      _enabledRetailers.remove(retailer);
    }
    notifyListeners();
  }

  void updateComparisonPrefs({
    String? defaultSort,
    bool? showUnitPrices,
    bool? includeUnavailable,
    bool? matchPackSizes,
    bool? suggestAlternatives,
    String? defaultBasketMode,
  }) {
    _defaultSort = defaultSort ?? _defaultSort;
    _showUnitPrices = showUnitPrices ?? _showUnitPrices;
    _includeUnavailable = includeUnavailable ?? _includeUnavailable;
    _matchPackSizes = matchPackSizes ?? _matchPackSizes;
    _suggestAlternatives = suggestAlternatives ?? _suggestAlternatives;
    _defaultBasketMode = defaultBasketMode ?? _defaultBasketMode;
    notifyListeners();
  }

  void resetComparisonPrefs() {
    _enabledRetailers
      ..clear()
      ..addAll(RetailerId.values);
    _defaultSort = 'Lowest price';
    _showUnitPrices = true;
    _includeUnavailable = true;
    _matchPackSizes = true;
    _suggestAlternatives = true;
    _defaultBasketMode = 'Cheapest complete';
    notifyListeners();
  }

  void updateNotificationPrefs({
    bool? all,
    bool? priceDrops,
    bool? targetAlerts,
    bool? backInStock,
    bool? newDeals,
    bool? basketSavings,
    bool? weeklySummary,
    bool? appUpdates,
  }) {
    _pushNotificationsAll = all ?? _pushNotificationsAll;
    _priceDropsNotif = priceDrops ?? _priceDropsNotif;
    _targetAlertsNotif = targetAlerts ?? _targetAlertsNotif;
    _backInStockNotif = backInStock ?? _backInStockNotif;
    _newDealsNotif = newDeals ?? _newDealsNotif;
    _basketSavingsNotif = basketSavings ?? _basketSavingsNotif;
    _weeklySummaryNotif = weeklySummary ?? _weeklySummaryNotif;
    _appUpdatesNotif = appUpdates ?? _appUpdatesNotif;
    notifyListeners();
  }

  void resetNotificationPrefs() {
    _pushNotificationsAll = true;
    _priceDropsNotif = true;
    _targetAlertsNotif = true;
    _backInStockNotif = true;
    _newDealsNotif = false;
    _basketSavingsNotif = true;
    _weeklySummaryNotif = true;
    _appUpdatesNotif = false;
    notifyListeners();
  }

  // Sasta+ subscription
  void subscribeToPlan(SastaPlanType plan) {
    _planType = plan;
    _autoRenew = true;
    final amount = plan == SastaPlanType.yearly ? 399 : 49;
    final name =
        plan == SastaPlanType.yearly ? 'Sasta+ Yearly' : 'Sasta+ Monthly';
    _invoices.insert(
      0,
      SubscriptionInvoice(
        id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
        planName: name,
        dateLabel: '8 Nov 2026',
        txnCode: 'TXN-••9104',
        amount: amount,
        status: 'Paid',
      ),
    );
    notifyListeners();
  }

  void toggleAutoRenew(bool value) {
    _autoRenew = value;
    notifyListeners();
  }

  void cancelSubscription() {
    _planType = SastaPlanType.free;
    _autoRenew = false;
    notifyListeners();
  }

  void submitSupportTicket({
    required String topic,
    required String subject,
    required String message,
  }) {
    _supportTickets.insert(
      0,
      SupportTicket(
        id: 'tk_${DateTime.now().millisecondsSinceEpoch}',
        topic: topic,
        subject: subject.trim().isEmpty ? topic : subject.trim(),
        message: message.trim(),
        dateLabel: 'Today',
        status: 'In review',
      ),
    );
    notifyListeners();
  }

  void logOut() {
    _isLoggedOut = true;
    _hasSeenOnboarding = false;
    _hasSetPincode = false;
    _activeTabIndex = 0;
    notifyListeners();
  }
}

/// InheritedNotifier binding [SastaAppState] cleanly to widget subtrees.
class SastaScope extends InheritedNotifier<SastaAppState> {
  const SastaScope({
    super.key,
    required SastaAppState state,
    required super.child,
  }) : super(notifier: state);

  static SastaAppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SastaScope>();
    assert(scope != null, 'SastaScope not found in widget tree');
    return scope!.notifier!;
  }

  static SastaAppState read(BuildContext context) {
    final scope =
        context.getInheritedWidgetOfExactType<SastaScope>();
    assert(scope != null, 'SastaScope not found in widget tree');
    return scope!.notifier!;
  }
}
