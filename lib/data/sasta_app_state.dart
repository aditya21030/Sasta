import 'dart:async';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/local_storage_service.dart';
import '../services/pincode_location_service.dart';
import '../services/quick_commerce_api.dart';
import '../services/retailer_launcher_service.dart';
import '../services/share_service.dart';
import '../theme/sasta_tokens.dart';
import 'mock_catalog.dart';

/// Root reactive application state shared across all Sasta tabs and pushed flows.
class SastaAppState extends ChangeNotifier {
  SastaAppState({
    LocalStorageService? storage,
    PincodeLocationService? locationService,
    RetailerLauncherService? retailerLauncher,
    SastaShareService? shareService,
    QuickCommerceRepository? repository,
    QuickCommerceApiConfig? defaultApiConfig,
  })  : _storage = storage,
        _locationService = locationService ?? PincodeLocationService(),
        _ownsLocationService = locationService == null,
        _retailerLauncher = retailerLauncher ?? RetailerLauncherService(),
        _shareService = shareService ?? SastaShareService(),
        _hasCustomRepo = repository != null,
        _defaultApiConfig = defaultApiConfig {
    if (repository != null) {
      _repository = repository;
      _apiBaseUrl = repository.config.baseUrl;
      _apiKey = repository.config.apiKey;
    } else {
      if (_apiBaseUrl.isEmpty && defaultApiConfig != null) {
        _apiBaseUrl = defaultApiConfig.baseUrl;
        _apiKey = defaultApiConfig.apiKey;
      }
      _repository = HttpQuickCommerceRepository(
        config: QuickCommerceApiConfig(
          baseUrl: _apiBaseUrl,
          apiKey: _apiKey,
        ),
      );
    }
  }

  /// Creates [SastaAppState], restores persisted state from SharedPreferences,
  /// and triggers background API sync when configured.
  static Future<SastaAppState> createAndLoad({
    LocalStorageService? storage,
    PincodeLocationService? locationService,
    RetailerLauncherService? retailerLauncher,
    SastaShareService? shareService,
    QuickCommerceRepository? repository,
    QuickCommerceApiConfig? defaultApiConfig,
    bool syncIfConfigured = true,
  }) async {
    final state = SastaAppState(
      storage: storage ?? LocalStorageService(),
      locationService: locationService,
      retailerLauncher: retailerLauncher,
      shareService: shareService,
      repository: repository,
      defaultApiConfig: defaultApiConfig,
    );
    await state.loadFromStorage();
    if (syncIfConfigured &&
        state.hasSetPincode &&
        state.isApiConfigured &&
        !state.onDemandLiveMode) {
      unawaited(state.syncCatalogForLocation());
    }
    return state;
  }

  final LocalStorageService? _storage;
  final PincodeLocationService _locationService;
  final bool _ownsLocationService;
  final RetailerLauncherService _retailerLauncher;
  final SastaShareService _shareService;
  final bool _hasCustomRepo;
  final QuickCommerceApiConfig? _defaultApiConfig;
  late QuickCommerceRepository _repository;

  Timer? _saveTimer;
  bool _isHydrating = false;
  bool _isDisposed = false;
  int _syncSeq = 0;
  int _searchSeq = 0;

  // Dynamic catalog + Quick-Commerce API sync state
  List<Product> _products = List<Product>.from(MockCatalog.products);
  String _apiBaseUrl = QuickCommerceApiConfig.envBaseUrl;
  String _apiKey = QuickCommerceApiConfig.envApiKey;
  bool _isCatalogSyncing = false;
  bool _isSearchingRemote = false;
  bool _isLiveCatalogActive = false;
  DateTime? _lastSyncedAt;
  String? _lastSyncedPincode;
  Set<RetailerId> _lastSyncedRetailers = const {};
  String? _lastSyncError;
  int? _creditsRemaining;
  List<RetailerId> _serviceableRetailers = const [];
  final Map<RetailerId, String> _retailerEtas = {};
  bool? _onDemandLiveModeOverride;
  String _dailyLiveSearchDate = '';
  int _dailyLiveSearchesUsed = 0;

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
  final List<SubscriptionInvoice> _invoices = [];
  int _avatarStyleIndex = 0;

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

  int get avatarStyleIndex => _avatarStyleIndex;

  void cycleAvatarStyle() {
    _avatarStyleIndex = (_avatarStyleIndex + 1) % 4;
    notifyListeners();
  }

  String get fullName => _fullName;
  String get email => _email;
  String get phone => _phone;
  String get maskedPhone {
    final digits = _phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 5) {
      return '+91 ••••• ${digits.substring(digits.length - 5)}';
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

  List<Product> get products => List.unmodifiable(_products);
  String get apiBaseUrl => _apiBaseUrl;
  String get apiKey => _apiKey;
  static const int freeDailyLiveSearchLimit = 3;

  bool get isApiConfigured => _repository.isConfigured;
  bool get isQuickCommerceDirect => _repository.config.isQuickCommerceDirect;
  bool get onDemandLiveMode => _onDemandLiveModeOverride ?? isQuickCommerceDirect;
  bool get hasUnlimitedLiveSearches => isPlusActive || !isQuickCommerceDirect;
  int get estimatedCreditsPerSearch =>
      _enabledRetailers.isEmpty ? 4 : _enabledRetailers.length;
  int get liveNetworkRequestsMade => _repository.liveNetworkRequestsMade;

  String _todayDateKey() =>
      DateTime.now().toIso8601String().substring(0, 10);

  int get dailyLiveSearchesUsed =>
      _dailyLiveSearchDate == _todayDateKey() ? _dailyLiveSearchesUsed : 0;

  int? get remainingFreeLiveSearches => hasUnlimitedLiveSearches
      ? null
      : (freeDailyLiveSearchLimit - dailyLiveSearchesUsed)
          .clamp(0, freeDailyLiveSearchLimit);

  bool get isLiveQuotaExhausted =>
      !hasUnlimitedLiveSearches && (remainingFreeLiveSearches ?? 0) <= 0;

  void _recordLiveNetworkSearch() {
    final today = _todayDateKey();
    if (_dailyLiveSearchDate != today) {
      _dailyLiveSearchDate = today;
      _dailyLiveSearchesUsed = 0;
    }
    _dailyLiveSearchesUsed++;
  }

  bool hasFreshCacheFor({
    String query = 'milk',
    String? categoryId,
    bool? isHomeQuery,
  }) {
    if (!isApiConfigured) return false;
    final loc = activeLocation;
    final fallback = (loc.lat == null || loc.lng == null)
        ? PincodeLocationService.fallbackCoordinatesSync(loc.pincode)
        : null;
    return _repository.hasFreshQueryCache(
      pincode: loc.pincode,
      query: query,
      categoryId: categoryId,
      lat: loc.lat ?? fallback?.lat,
      lng: loc.lng ?? fallback?.lng,
      retailers: _enabledRetailers,
      isHomeQuery: isHomeQuery ??
          (categoryId == null && query.trim().toLowerCase() == 'milk'),
    );
  }

  void setOnDemandLiveMode(bool value) {
    if (onDemandLiveMode == value) return;
    _onDemandLiveModeOverride = value;
    notifyListeners();
  }

  bool get isCatalogSyncing => _isCatalogSyncing;
  bool get isSearchingRemote => _isSearchingRemote;
  bool get isLiveCatalogActive => _isLiveCatalogActive;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get lastSyncError => _lastSyncError;
  int? get apiCreditsRemaining =>
      _creditsRemaining ?? _repository.lastCreditsRemaining;
  List<RetailerId> get serviceableRetailers =>
      List.unmodifiable(_serviceableRetailers);
  String etaFor(RetailerId retailer) =>
      _retailerEtas[retailer] ?? retailer.eta;

  PincodeLocationService get locationService => _locationService;
  RetailerLauncherService get retailerLauncher => _retailerLauncher;
  SastaShareService get shareService => _shareService;

  Product? productById(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Restores user state, API config, and cached catalog from persistent storage.
  Future<void> loadFromStorage() async {
    final storage = _storage;
    if (storage == null) return;
    final snapshot = await storage.load();
    if (snapshot == null) return;
    _applySnapshot(snapshot);
  }

  /// Writes current application state immediately to persistent storage.
  Future<void> flushPersistence() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    final storage = _storage;
    if (storage == null) return;
    await storage.save(_buildSnapshot());
  }

  void _scheduleSave() {
    if (_storage == null || _isHydrating) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 180), () {
      unawaited(flushPersistence());
    });
  }

  void _applySnapshot(SavedAppSnapshot s) {
    _isHydrating = true;
    try {
      if (s.userName != null) _fullName = s.userName!;
      if (s.userEmail != null) _email = s.userEmail!;
      if (s.userPhone != null) _phone = s.userPhone!;
      if (s.phoneVerified != null) _phoneVerified = s.phoneVerified!;
      if (s.themeModeName != null) {
        switch (s.themeModeName) {
          case 'dark':
            _themeMode = ThemeMode.dark;
          case 'system':
            _themeMode = ThemeMode.system;
          default:
            _themeMode = ThemeMode.light;
        }
      } else if (s.isDarkMode != null) {
        _themeMode = s.isDarkMode! ? ThemeMode.dark : ThemeMode.light;
      }
      if (s.useLocation != null) {
        _pushNotificationsAll = s.useLocation!;
      }
      if (s.priceDropAlerts != null) _priceDropsNotif = s.priceDropAlerts!;
      if (s.targetAlertsNotif != null) {
        _targetAlertsNotif = s.targetAlertsNotif!;
      }
      if (s.backInStockAlerts != null) _backInStockNotif = s.backInStockAlerts!;
      if (s.newDealsNotif != null) _newDealsNotif = s.newDealsNotif!;
      if (s.basketSavingsNotif != null) {
        _basketSavingsNotif = s.basketSavingsNotif!;
      }
      if (s.weeklyDigest != null) _weeklySummaryNotif = s.weeklyDigest!;
      if (s.appUpdatesNotif != null) _appUpdatesNotif = s.appUpdatesNotif!;

      if (s.enabledRetailerIds != null && s.enabledRetailerIds!.isNotEmpty) {
        final parsed = s.enabledRetailerIds!
            .map(RetailerId.tryParse)
            .whereType<RetailerId>()
            .toSet();
        if (parsed.isNotEmpty) {
          _enabledRetailers
            ..clear()
            ..addAll(parsed);
        }
      }
      if (s.sortMode != null) _defaultSort = s.sortMode!;
      if (s.hideOos != null) _includeUnavailable = !s.hideOos!;
      if (s.showUnitPrice != null) _showUnitPrices = s.showUnitPrice!;
      if (s.autoMatchVariants != null) _matchPackSizes = s.autoMatchVariants!;
      if (s.suggestAlternatives != null) {
        _suggestAlternatives = s.suggestAlternatives!;
      }
      if (s.basketMode != null) _defaultBasketMode = s.basketMode!;
      if (s.selectedPlan != null) _planType = s.selectedPlan!;
      if (s.autoRenew != null) _autoRenew = s.autoRenew!;

      if (s.savedLocations != null && s.savedLocations!.isNotEmpty) {
        _locations
          ..clear()
          ..addAll(s.savedLocations!);
      } else if (s.pincode != null && s.pincode!.length == 6) {
        _locations[0] = _locations.first.copyWith(
          pincode: s.pincode!,
          area: s.area ?? _locations.first.area,
          isDefault: true,
        );
      }

      if (s.savedBaskets != null && s.savedBaskets!.isNotEmpty) {
        _savedBaskets
          ..clear()
          ..addAll(s.savedBaskets!);
      }
      if (s.activeBasketId != null &&
          _savedBaskets.any((b) => b.id == s.activeBasketId)) {
        _activeBasketId = s.activeBasketId!;
      }
      if (s.basketEntries != null && _savedBaskets.isNotEmpty) {
        final idx = _savedBaskets.indexWhere((b) => b.id == _activeBasketId);
        final target = idx == -1 ? 0 : idx;
        _savedBaskets[target] = _savedBaskets[target].copyWith(
          entries: s.basketEntries,
        );
      }
      if (s.activityLog != null) {
        _basketActivities
          ..clear()
          ..addAll(s.activityLog!);
      }
      if (s.favouriteIds != null) {
        _favouriteIds
          ..clear()
          ..addAll(s.favouriteIds!);
      }
      if (s.recentlyViewedIds != null) {
        _recentlyViewedIds
          ..clear()
          ..addAll(s.recentlyViewedIds!);
      }
      if (s.alerts != null) {
        _priceAlerts
          ..clear()
          ..addAll(s.alerts!);
      }
      if (s.notifications != null) {
        _notifications
          ..clear()
          ..addAll(s.notifications!);
      }
      if (s.searchHistory != null) {
        _searchHistory
          ..clear()
          ..addAll(s.searchHistory!);
      }
      if (s.tickets != null) {
        _supportTickets
          ..clear()
          ..addAll(s.tickets!);
      }
      if (s.invoices != null) {
        _invoices
          ..clear()
          ..addAll(s.invoices!);
      }

      if (!_hasCustomRepo) {
        final savedUrl = s.apiBaseUrl?.trim() ?? '';
        final savedKey = s.apiKey?.trim() ?? '';
        if (savedUrl.isNotEmpty) {
          _apiBaseUrl = savedUrl;
          _apiKey = savedKey;
          _repository.dispose();
          _repository = HttpQuickCommerceRepository(
            config: QuickCommerceApiConfig(
              baseUrl: _apiBaseUrl,
              apiKey: _apiKey,
            ),
          );
        } else if (s.apiBaseUrl != null) {
          _apiBaseUrl = '';
          _apiKey = savedKey;
          _repository.dispose();
          _repository = HttpQuickCommerceRepository(
            config: QuickCommerceApiConfig(
              baseUrl: _apiBaseUrl,
              apiKey: _apiKey,
            ),
          );
        }
      }
      if (s.lastSyncedAtIso != null) {
        _lastSyncedAt = DateTime.tryParse(s.lastSyncedAtIso!);
      }
      if (s.onDemandLiveMode != null) {
        _onDemandLiveModeOverride = s.onDemandLiveMode;
      }
      if (s.dailyLiveSearchDate != null) {
        _dailyLiveSearchDate = s.dailyLiveSearchDate!;
      }
      if (s.dailyLiveSearchesUsed != null) {
        _dailyLiveSearchesUsed = s.dailyLiveSearchesUsed!;
      }
      if (s.serviceableRetailerIds != null) {
        _serviceableRetailers = s.serviceableRetailerIds!
            .map(RetailerId.tryParse)
            .whereType<RetailerId>()
            .toList();
      }
      if (s.retailerEtas != null) {
        _retailerEtas.clear();
        s.retailerEtas!.forEach((key, value) {
          final r = RetailerId.tryParse(key);
          if (r != null && value.trim().isNotEmpty) {
            _retailerEtas[r] = value;
          }
        });
      }
      if (s.cachedProducts != null && s.cachedProducts!.isNotEmpty) {
        final pinPrefix = 'qc_${activeLocation.pincode}_';
        final matchingLive = s.cachedProducts!
            .where((p) => !p.isLiveProduct || p.id.startsWith(pinPrefix))
            .toList();
        _products = _mergeProductLists(matchingLive, _products);
        if (_lastSyncedAt != null && _apiBaseUrl.isNotEmpty) {
          _isLiveCatalogActive = matchingLive.isNotEmpty;
          _lastSyncedPincode = s.pincode ?? activeLocation.pincode;
          _lastSyncedRetailers = Set<RetailerId>.from(_enabledRetailers);
        }
      }
      if (s.queryCacheTimestampsMs != null &&
          s.queryCacheTimestampsMs!.isNotEmpty) {
        _repository.hydrateQueryCache(
          timestampsMs: s.queryCacheTimestampsMs!,
          productIdsByKey: s.queryCacheProductIds ?? const {},
          products: _products,
        );
      }

      if (s.isOnboarded == true) {
        _hasSeenOnboarding = true;
        _hasSetPincode = true;
        _isLoggedOut = false;
      }
    } finally {
      _isHydrating = false;
    }
    super.notifyListeners();
  }

  SavedAppSnapshot _buildSnapshot() {
    final loc = activeLocation;
    return SavedAppSnapshot(
      userName: _fullName,
      userEmail: _email,
      userPhone: _phone,
      phoneVerified: _phoneVerified,
      pincode: loc.pincode,
      area: loc.area,
      isOnboarded: _hasSeenOnboarding && _hasSetPincode && !_isLoggedOut,
      isDarkMode: _themeMode == ThemeMode.dark,
      themeModeName: _themeMode.name,
      useLocation: _pushNotificationsAll,
      priceDropAlerts: _priceDropsNotif,
      targetAlertsNotif: _targetAlertsNotif,
      backInStockAlerts: _backInStockNotif,
      newDealsNotif: _newDealsNotif,
      basketSavingsNotif: _basketSavingsNotif,
      weeklyDigest: _weeklySummaryNotif,
      appUpdatesNotif: _appUpdatesNotif,
      enabledRetailerIds: _enabledRetailers.map((e) => e.id).toList(),
      sortMode: _defaultSort,
      hideOos: !_includeUnavailable,
      showUnitPrice: _showUnitPrices,
      deliveryFeeMode: 'default',
      autoMatchVariants: _matchPackSizes,
      suggestAlternatives: _suggestAlternatives,
      basketMode: _defaultBasketMode,
      selectedPlan: _planType,
      autoRenew: _autoRenew,
      activeBasketId: _activeBasketId,
      recentlyViewedIds: List.of(_recentlyViewedIds),
      apiBaseUrl: _apiBaseUrl,
      apiKey: _apiKey,
      lastSyncedAtIso: _lastSyncedAt?.toIso8601String(),
      basketEntries: List.of(activeBasket.entries),
      savedBaskets: List.of(_savedBaskets),
      activityLog: List.of(_basketActivities),
      favouriteIds: List.of(_favouriteIds),
      alerts: List.of(_priceAlerts),
      notifications: List.of(_notifications),
      savedLocations: List.of(_locations),
      searchHistory: List.of(_searchHistory),
      tickets: List.of(_supportTickets),
      invoices: List.of(_invoices),
      cachedProducts: _isLiveCatalogActive ? List.of(_products) : null,
      onDemandLiveMode: _onDemandLiveModeOverride,
      queryCacheTimestampsMs: _repository.exportQueryCacheTimestampsMs(),
      queryCacheProductIds: _repository.exportQueryCacheProductIds(),
      dailyLiveSearchDate: _dailyLiveSearchDate.isEmpty ? null : _dailyLiveSearchDate,
      dailyLiveSearchesUsed: _dailyLiveSearchesUsed,
      serviceableRetailerIds:
          _serviceableRetailers.map((e) => e.id).toList(),
      retailerEtas: _retailerEtas.map((k, v) => MapEntry(k.id, v)),
    );
  }

  List<Product> _mergeProductLists(
    List<Product> primary,
    List<Product> fallback,
  ) {
    final seen = <String>{};
    final merged = <Product>[];
    for (final p in primary) {
      if (seen.add(p.id)) merged.add(p);
    }
    for (final p in fallback) {
      if (seen.add(p.id)) merged.add(p);
    }
    return merged;
  }

  /// Updates the quick-commerce API endpoint configuration and optionally syncs now.
  Future<bool> updateApiConfig({
    required String baseUrl,
    String apiKey = '',
    bool syncNow = true,
  }) async {
    final nextUrl = baseUrl.trim();
    final nextKey = apiKey.trim();
    final configChanged = nextUrl != _apiBaseUrl || nextKey != _apiKey;
    _apiBaseUrl = nextUrl;
    _apiKey = nextKey;
    _lastSyncError = null;
    _creditsRemaining = null;
    if (configChanged) {
      ++_syncSeq;
      ++_searchSeq;
      _isCatalogSyncing = false;
      _isSearchingRemote = false;
      _lastSyncedAt = null;
      _lastSyncedPincode = null;
      _lastSyncedRetailers = const {};
      _serviceableRetailers = const [];
      _retailerEtas.clear();
      _products = _products.where((p) => !p.isLiveProduct).toList();
      _isLiveCatalogActive = false;
    } else {
      _lastSyncedPincode = null;
    }
    if (!_hasCustomRepo) {
      _repository.dispose();
      _repository = HttpQuickCommerceRepository(
        config: QuickCommerceApiConfig(
          baseUrl: _apiBaseUrl,
          apiKey: _apiKey,
        ),
      );
    }
    if (!isApiConfigured) {
      _isLiveCatalogActive = false;
      _lastSyncedAt = null;
      _lastSyncedPincode = null;
      _lastSyncedRetailers = const {};
      _serviceableRetailers = const [];
      _retailerEtas.clear();
      _products = _products.where((p) => !p.isLiveProduct).toList();
      notifyListeners();
      return false;
    }
    notifyListeners();
    if (syncNow) {
      return syncCatalogForLocation(forceRefresh: true);
    }
    return true;
  }

  Future<({double lat, double lng})> _resolveActiveCoordinates({
    double? lat,
    double? lng,
  }) async {
    if (lat != null && lng != null) {
      return (lat: lat, lng: lng);
    }
    final current = activeLocation;
    if (current.lat != null && current.lng != null) {
      return (lat: current.lat!, lng: current.lng!);
    }
    final coords =
        await _locationService.resolveCoordinatesForPincode(current.pincode);
    if (!_isDisposed) {
      final idx = _locations.indexWhere((l) => l.id == current.id);
      if (idx != -1) {
        _locations[idx] = _locations[idx].copyWith(
          lat: coords.lat,
          lng: coords.lng,
        );
      }
    }
    return coords;
  }

  /// Queries remaining QuickCommerceAPI credits without consuming credits.
  Future<QuickCommerceCreditInfo?> refreshCreditsBalance() async {
    if (!isApiConfigured) return null;
    final info = await _repository.fetchCreditsBalance();
    if (info != null && !_isDisposed) {
      _creditsRemaining = info.totalAvailable;
      notifyListeners();
    }
    return info;
  }

  /// Pulls live catalog prices for the active pincode from the Quick-Commerce API.
  Future<bool> syncCatalogForLocation({
    double? lat,
    double? lng,
    bool forceRefresh = false,
  }) async {
    if (_isDisposed) return false;
    if (!isApiConfigured) {
      _isLiveCatalogActive = false;
      _lastSyncError = null;
      notifyListeners();
      return false;
    }

    final currentPin = activeLocation.pincode;
    final requestedRetailers = Set<RetailerId>.from(_enabledRetailers);
    if (!forceRefresh &&
        _isLiveCatalogActive &&
        _lastSyncedPincode == currentPin &&
        _lastSyncedRetailers.length == requestedRetailers.length &&
        _lastSyncedRetailers.containsAll(requestedRetailers) &&
        _lastSyncedAt != null &&
        DateTime.now().difference(_lastSyncedAt!) < const Duration(hours: 6)) {
      return true;
    }

    final syncToken = ++_syncSeq;
    _isCatalogSyncing = true;
    _lastSyncError = null;
    notifyListeners();

    try {
      final coords = await _resolveActiveCoordinates(lat: lat, lng: lng);
      if (_isDisposed || syncToken != _syncSeq) return false;
      final cachedHit = !forceRefresh &&
          _repository.hasFreshQueryCache(
            pincode: currentPin,
            query: 'milk',
            lat: coords.lat,
            lng: coords.lng,
            retailers: requestedRetailers,
            isHomeQuery: true,
          );
      if (!cachedHit && isLiveQuotaExhausted) {
        _lastSyncError =
            'Daily free live refresh limit ($freeDailyLiveSearchLimit/day) reached. Cached catalog stays active.';
        return false;
      }

      final beforeCalls = _repository.liveNetworkRequestsMade;
      final res = await _repository.fetchHomeCatalog(
        pincode: currentPin,
        lat: coords.lat,
        lng: coords.lng,
        retailers: requestedRetailers,
        forceRefresh: forceRefresh,
      );
      if (_isDisposed || syncToken != _syncSeq) return false;
      if (_repository.liveNetworkRequestsMade > beforeCalls) {
        _recordLiveNetworkSearch();
      }
      final pinPrefix = 'qc_${currentPin}_';
      final retainedProducts = _products
          .where((p) => !p.isLiveProduct || p.id.startsWith(pinPrefix))
          .toList();
      _products = res.products.isNotEmpty
          ? _mergeProductLists(res.products, retainedProducts)
          : retainedProducts;
      if (_lastSyncedPincode != currentPin) {
        _retailerEtas.clear();
      }
      _isLiveCatalogActive = true;
      _lastSyncedAt = res.syncedAt;
      _lastSyncedPincode = currentPin;
      _lastSyncedRetailers = requestedRetailers;
      _serviceableRetailers = res.serviceableRetailers;
      if (res.etasByRetailer.isNotEmpty) {
        _retailerEtas.addAll(res.etasByRetailer);
      }
      _creditsRemaining = res.creditsRemaining ??
          _repository.lastCreditsRemaining ??
          _creditsRemaining;
      if (res.area != null && res.area!.trim().isNotEmpty) {
        final idx = _locations.indexWhere((l) => l.isDefault);
        if (idx != -1 && _locations[idx].pincode == currentPin) {
          _locations[idx] = _locations[idx].copyWith(
            area: res.area!.trim(),
            lat: coords.lat,
            lng: coords.lng,
          );
        }
      }
      return true;
    } on QuickCommerceApiException catch (e) {
      if (syncToken == _syncSeq) _lastSyncError = e.message;
      return false;
    } catch (e) {
      if (syncToken == _syncSeq) _lastSyncError = 'Failed to sync catalog: $e';
      return false;
    } finally {
      if (syncToken == _syncSeq) _isCatalogSyncing = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  /// Queries remote API search and merges matching live items into the catalog cache.
  Future<List<Product>> searchProductsRemote(
    String query, {
    String? categoryId,
    RetailerId? retailerFilter,
    bool inStockOnly = false,
    int? maxPrice,
    String? sortBy,
    bool forceRefresh = false,
  }) async {
    if (isApiConfigured && !_isDisposed) {
      final isCached = !forceRefresh &&
          hasFreshCacheFor(
            query: query,
            categoryId: categoryId,
            isHomeQuery: false,
          );
      if (!isCached && isLiveQuotaExhausted) {
        _lastSyncError =
            'Daily free live search limit ($freeDailyLiveSearchLimit/day) reached. Showing cached prices.';
        notifyListeners();
      } else {
        final searchToken = ++_searchSeq;
        final requestedPin = activeLocation.pincode;
        final requestedRetailers = Set<RetailerId>.from(_enabledRetailers);
        _isSearchingRemote = true;
        _lastSyncError = null;
        notifyListeners();
        try {
          final coords = await _resolveActiveCoordinates();
          if (_isDisposed || searchToken != _searchSeq) return const [];
          final beforeCalls = _repository.liveNetworkRequestsMade;
          final remote = await _repository.searchProducts(
            query: query,
            pincode: requestedPin,
            categoryId: categoryId,
            lat: coords.lat,
            lng: coords.lng,
            retailers: requestedRetailers,
            forceRefresh: forceRefresh,
          );
          if (_isDisposed || searchToken != _searchSeq) return const [];
          if (_repository.liveNetworkRequestsMade > beforeCalls) {
            _recordLiveNetworkSearch();
          }
          if (remote.isNotEmpty) {
            _products = _mergeProductLists(remote, _products);
            _isLiveCatalogActive = true;
            _lastSyncedAt = DateTime.now();
            _lastSyncedPincode = requestedPin;
          }
          if (_repository.lastCreditsRemaining != null) {
            _creditsRemaining = _repository.lastCreditsRemaining;
          }
        } on QuickCommerceApiException catch (e) {
          if (searchToken == _searchSeq) _lastSyncError = e.message;
        } catch (_) {
          // Silently keep cached/local search results if remote search fails.
        } finally {
          if (searchToken == _searchSeq) _isSearchingRemote = false;
          if (!_isDisposed) notifyListeners();
        }
      }
    }
    return searchProducts(
      query,
      categoryId: categoryId,
      retailerFilter: retailerFilter,
      inStockOnly: inStockOnly,
      maxPrice: maxPrice,
      sortBy: sortBy,
    );
  }

  /// Refreshes latest quotes & price history for a single product when API is active.
  Future<Product?> refreshProductDetails(
    String productId, {
    bool userInitiated = false,
  }) async {
    if (!isApiConfigured ||
        (!userInitiated &&
            ((onDemandLiveMode && isQuickCommerceDirect) ||
                isLiveQuotaExhausted))) {
      return productById(productId);
    }
    try {
      final fetched = await _repository.fetchProductDetails(
        productId: productId,
        pincode: activeLocation.pincode,
      );
      if (_isDisposed) return null;
      final history = await _repository.fetchPriceHistory(
        productId: productId,
        pincode: activeLocation.pincode,
      );
      if (_isDisposed) return null;
      if (fetched != null || history.isNotEmpty) {
        final base = fetched ?? productById(productId);
        if (base != null) {
          final updated = history.isNotEmpty
              ? base.copyWith(historyByRange: history)
              : base;
          _products = _mergeProductLists([updated], _products);
          notifyListeners();
          return updated;
        }
      }
    } catch (_) {
      // Keep cached product details when offline or endpoint is unavailable.
    }
    return productById(productId);
  }

  /// Resolves a 6-digit Indian pincode via India Post API and completes pincode setup.
  Future<ResolvedPincode?> resolveAndCompletePincode(String rawPincode) async {
    final cleaned = rawPincode.trim();
    final resolved = await _locationService.lookupPincode(cleaned);
    if (_isDisposed) return resolved;
    completePincode(
      cleaned,
      area: resolved?.displayArea ?? activeLocation.area,
      lat: resolved?.lat,
      lng: resolved?.lng,
    );
    return resolved;
  }

  /// Detects current GPS coordinates, reverse-geocodes Indian pincode + area,
  /// and sets it as the active delivery location.
  Future<LocationDetectResult> detectAndApplyCurrentLocation({
    bool finishOnboarding = false,
  }) async {
    final result = await _locationService.detectCurrentLocation();
    if (_isDisposed) return result;
    final resolved = result.resolved;
    if (resolved != null) {
      if (finishOnboarding) {
        completePincode(
          resolved.pincode,
          area: resolved.displayArea,
          lat: resolved.lat,
          lng: resolved.lng,
        );
      } else {
        final existingIdx =
            _locations.indexWhere((l) => l.pincode == resolved.pincode);
        if (existingIdx != -1) {
          updateLocation(
            _locations[existingIdx].copyWith(
              area: resolved.displayArea,
              lat: resolved.lat,
              lng: resolved.lng,
            ),
          );
          setDefaultLocation(_locations[existingIdx].id);
        } else {
          addLocation(
            label: 'GPS',
            pincode: resolved.pincode,
            area: resolved.displayArea,
            lat: resolved.lat,
            lng: resolved.lng,
            makeDefault: true,
          );
        }
      }
    }
    return result;
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

  bool _onActiveLocationChanged(String previousPin) {
    final currentPin = activeLocation.pincode;
    if (currentPin == previousPin) return false;
    ++_syncSeq;
    ++_searchSeq;
    _isCatalogSyncing = false;
    _isSearchingRemote = false;
    _lastSyncError = null;
    _lastSyncedAt = null;
    _lastSyncedPincode = null;
    _lastSyncedRetailers = const {};
    _serviceableRetailers = const [];
    _retailerEtas.clear();
    final pinPrefix = 'qc_${currentPin}_';
    _products = _products
        .where((p) => !p.isLiveProduct || p.id.startsWith(pinPrefix))
        .toList();
    _isLiveCatalogActive =
        _products.any((p) => p.id.startsWith(pinPrefix));
    return true;
  }

  bool get _shouldAutoSyncForLocation =>
      isApiConfigured &&
      (!onDemandLiveMode || hasFreshCacheFor(query: 'milk', isHomeQuery: true));

  void completePincode(
    String pincode, {
    String area = 'Central Delhi',
    double? lat,
    double? lng,
  }) {
    final cleaned = pincode.trim();
    final previousPin = activeLocation.pincode;
    if (cleaned.length == 6) {
      final fallback = (lat == null || lng == null)
          ? PincodeLocationService.fallbackCoordinatesSync(cleaned)
          : null;
      final resolvedLat = lat ?? fallback?.lat;
      final resolvedLng = lng ?? fallback?.lng;
      final idx = _locations.indexWhere((l) => l.pincode == cleaned);
      if (idx != -1) {
        _locations[idx] = _locations[idx].copyWith(
          area: area,
          lat: resolvedLat ?? _locations[idx].lat,
          lng: resolvedLng ?? _locations[idx].lng,
        );
        for (var i = 0; i < _locations.length; i++) {
          _locations[i] = _locations[i].copyWith(isDefault: i == idx);
        }
      } else {
        for (var i = 0; i < _locations.length; i++) {
          _locations[i] = _locations[i].copyWith(isDefault: false);
        }
        final hasHome =
            _locations.any((l) => l.label.toLowerCase() == 'home');
        _locations.insert(
          0,
          SavedLocation(
            id: 'loc_${DateTime.now().millisecondsSinceEpoch}',
            label: hasHome ? 'Saved place' : 'Home',
            pincode: cleaned,
            area: area,
            lat: resolvedLat,
            lng: resolvedLng,
            isDefault: true,
          ),
        );
      }
    }
    _onActiveLocationChanged(previousPin);
    _hasSeenOnboarding = true;
    _hasSetPincode = true;
    _isLoggedOut = false;
    notifyListeners();
    if (_shouldAutoSyncForLocation) {
      unawaited(syncCatalogForLocation());
    }
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
    final prevPin = activeLocation.pincode;
    for (var i = 0; i < _locations.length; i++) {
      _locations[i] = _locations[i].copyWith(isDefault: _locations[i].id == id);
    }
    final changed = _onActiveLocationChanged(prevPin);
    notifyListeners();
    if ((changed || _lastSyncedPincode != activeLocation.pincode) &&
        _shouldAutoSyncForLocation) {
      unawaited(syncCatalogForLocation());
    }
  }

  void addLocation({
    required String label,
    required String pincode,
    required String area,
    double? lat,
    double? lng,
    bool makeDefault = false,
  }) {
    final prevPin = activeLocation.pincode;
    if (makeDefault) {
      for (var i = 0; i < _locations.length; i++) {
        _locations[i] = _locations[i].copyWith(isDefault: false);
      }
    }
    final fallback = (lat == null || lng == null)
        ? PincodeLocationService.fallbackCoordinatesSync(pincode)
        : null;
    _locations.add(
      SavedLocation(
        id: 'loc_${DateTime.now().millisecondsSinceEpoch}',
        label: label,
        pincode: pincode,
        area: area,
        lat: lat ?? fallback?.lat,
        lng: lng ?? fallback?.lng,
        isDefault: makeDefault || _locations.isEmpty,
      ),
    );
    _onActiveLocationChanged(prevPin);
    notifyListeners();
    if (makeDefault && _shouldAutoSyncForLocation) {
      unawaited(syncCatalogForLocation());
    }
  }

  void updateLocation(SavedLocation updated) {
    final idx = _locations.indexWhere((l) => l.id == updated.id);
    if (idx == -1) return;
    final prevPin = activeLocation.pincode;
    final existing = _locations[idx];
    var normalized = updated;
    if (updated.pincode != existing.pincode &&
        updated.lat == existing.lat &&
        updated.lng == existing.lng) {
      final fallback =
          PincodeLocationService.fallbackCoordinatesSync(updated.pincode);
      normalized = SavedLocation(
        id: updated.id,
        label: updated.label,
        pincode: updated.pincode,
        area: updated.area,
        lat: fallback?.lat,
        lng: fallback?.lng,
        isDefault: updated.isDefault,
      );
    }
    if (normalized.isDefault) {
      for (var i = 0; i < _locations.length; i++) {
        if (i != idx) {
          _locations[i] = _locations[i].copyWith(isDefault: false);
        }
      }
    }
    _locations[idx] = normalized;
    if (!_locations.any((l) => l.isDefault) && _locations.isNotEmpty) {
      final fallbackIdx = _locations.length > 1 && idx == 0 ? 1 : 0;
      _locations[fallbackIdx] =
          _locations[fallbackIdx].copyWith(isDefault: true);
    }
    final changed = _onActiveLocationChanged(prevPin);
    notifyListeners();
    if (changed && _shouldAutoSyncForLocation) {
      unawaited(syncCatalogForLocation());
    }
  }

  void deleteLocation(String id) {
    if (_locations.length <= 1) return;
    final prevPin = activeLocation.pincode;
    final wasDefault = _locations.any((l) => l.id == id && l.isDefault);
    _locations.removeWhere((l) => l.id == id);
    if (wasDefault && _locations.isNotEmpty) {
      _locations[0] = _locations[0].copyWith(isDefault: true);
    }
    final changed = _onActiveLocationChanged(prevPin);
    notifyListeners();
    if (changed && _shouldAutoSyncForLocation) {
      unawaited(syncCatalogForLocation());
    }
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
        imageUrl: match.isNotEmpty ? match.first.bestImageUrl : null,
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
    var total = 0;
    for (final e in activeBasket.entries) {
      if (e.productId == productId &&
          (variantIndex == null || e.variantIndex == variantIndex)) {
        total += e.quantity;
      }
    }
    return total;
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
    final resolvedVariant = (variantIndex ?? product.defaultVariantIndex)
        .clamp(0, product.variants.length - 1);

    final entries = List<BasketEntry>.from(basket.entries);
    var eIdx = entries.indexWhere(
      (e) => e.productId == productId && e.variantIndex == resolvedVariant,
    );
    if (eIdx == -1 && variantIndex == null && delta < 0) {
      eIdx = entries.indexWhere((e) => e.productId == productId);
    }
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
        entries[eIdx] = current.copyWith(quantity: nextQty);
        if (delta != 0) {
          _pushBasketActivity(
            '${product.name} quantity ${current.quantity} → $nextQty',
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

  void updateBasketItemQuantity(
    String productId,
    int newQuantity, {
    int? variantIndex,
  }) {
    final bIdx = _savedBaskets.indexWhere((b) => b.id == _activeBasketId);
    if (bIdx == -1) return;
    final basket = _savedBaskets[bIdx];
    final entries = List<BasketEntry>.from(basket.entries);
    final eIdx = entries.indexWhere(
      (e) =>
          e.productId == productId &&
          (variantIndex == null || e.variantIndex == variantIndex),
    );
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
      if (product != null && old != newQuantity) {
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
    final removedIds = _savedBaskets[bIdx]
        .entries
        .where((e) => productIds.contains(e.productId))
        .map((e) => e.productId)
        .toSet();
    final entries = _savedBaskets[bIdx]
        .entries
        .where((e) => !productIds.contains(e.productId))
        .toList();
    if (removedIds.length == 1) {
      final name = productById(removedIds.first)?.name ?? 'item';
      _pushBasketActivity(
        'Removed $name',
        'Just now',
        'removed',
        productId: removedIds.first,
      );
    } else if (removedIds.length > 1) {
      _pushBasketActivity(
        'Removed ${removedIds.length} items',
        'Just now',
        'removed',
      );
    }
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
    final activeRetailers =
        retailerFilter != null ? {retailerFilter} : _enabledRetailers;
    final q = query.trim().toLowerCase();
    final tokens =
        q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    final filtered = _products.where((p) {
      if (categoryId != null && categoryId.isNotEmpty && p.categoryId != categoryId) {
        return false;
      }
      if (tokens.isNotEmpty) {
        final variantLabels = p.variants.map((v) => v.label).join(' ');
        final haystack =
            '${p.name} ${p.brand} ${p.categoryLabel} ${p.subtitle} $variantLabels'
                .toLowerCase();
        if (!tokens.every(haystack.contains)) return false;
      }
      final cheapest = p.cheapestQuote(
        p.defaultVariantIndex,
        enabledRetailers: activeRetailers,
      );
      if (inStockOnly && cheapest == null) return false;
      if (maxPrice != null && (cheapest?.price ?? 999999) > maxPrice) {
        return false;
      }
      return true;
    }).toList();

    double bestUnitRate(Product p) {
      final quotes = p
          .sortedQuotes(p.defaultVariantIndex, enabledRetailers: activeRetailers)
          .where((quote) => quote.isAvailable)
          .toList();
      if (quotes.isEmpty) return 999999;
      double best = double.infinity;
      for (final quote in quotes) {
        final rate = quote.parsedUnitRate ?? quote.price?.toDouble();
        if (rate != null && rate < best) best = rate;
      }
      return best.isFinite ? best : 999999;
    }

    final resolvedSort = sortBy ?? _defaultSort;
    if (resolvedSort == 'Lowest price') {
      filtered.sort((a, b) {
        final ap = a
                .cheapestQuote(
                  a.defaultVariantIndex,
                  enabledRetailers: activeRetailers,
                )
                ?.price ??
            999999;
        final bp = b
                .cheapestQuote(
                  b.defaultVariantIndex,
                  enabledRetailers: activeRetailers,
                )
                ?.price ??
            999999;
        final cmp = ap.compareTo(bp);
        if (cmp != 0) return cmp;
        if (a.isLiveProduct != b.isLiveProduct) {
          return a.isLiveProduct ? -1 : 1;
        }
        return 0;
      });
    } else if (resolvedSort == 'Discount') {
      filtered.sort((a, b) {
        final ad = a
                .cheapestQuote(
                  a.defaultVariantIndex,
                  enabledRetailers: activeRetailers,
                )
                ?.discountPercent ??
            0;
        final bd = b
                .cheapestQuote(
                  b.defaultVariantIndex,
                  enabledRetailers: activeRetailers,
                )
                ?.discountPercent ??
            0;
        final cmp = bd.compareTo(ad);
        if (cmp != 0) return cmp;
        if (a.isLiveProduct != b.isLiveProduct) {
          return a.isLiveProduct ? -1 : 1;
        }
        return 0;
      });
    } else if (resolvedSort == 'Best unit price') {
      filtered.sort((a, b) {
        final cmp = bestUnitRate(a).compareTo(bestUnitRate(b));
        if (cmp != 0) return cmp;
        if (a.isLiveProduct != b.isLiveProduct) {
          return a.isLiveProduct ? -1 : 1;
        }
        return 0;
      });
    } else if (resolvedSort == 'Availability') {
      filtered.sort((a, b) {
        final ac = a.availableAppCount(
          a.defaultVariantIndex,
          enabledRetailers: activeRetailers,
        );
        final bc = b.availableAppCount(
          b.defaultVariantIndex,
          enabledRetailers: activeRetailers,
        );
        final cmp = bc.compareTo(ac);
        if (cmp != 0) return cmp;
        final ap = a
                .cheapestQuote(
                  a.defaultVariantIndex,
                  enabledRetailers: activeRetailers,
                )
                ?.price ??
            999999;
        final bp = b
                .cheapestQuote(
                  b.defaultVariantIndex,
                  enabledRetailers: activeRetailers,
                )
                ?.price ??
            999999;
        final pCmp = ap.compareTo(bp);
        if (pCmp != 0) return pCmp;
        if (a.isLiveProduct != b.isLiveProduct) {
          return a.isLiveProduct ? -1 : 1;
        }
        return 0;
      });
    } else {
      filtered.sort((a, b) {
        if (a.isLiveProduct != b.isLiveProduct) {
          return a.isLiveProduct ? -1 : 1;
        }
        return 0;
      });
    }
    return filtered;
  }

  // Basket comparison calculation (single-store, split-basket, savings)
  BasketComparisonResult computeBasketComparison({
    List<BasketEntry>? customEntries,
  }) {
    final rawEntries = customEntries ?? activeBasket.entries;
    final entries =
        rawEntries.where((e) => productById(e.productId) != null).toList();
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
    final cleanName = name.trim();
    final cleanEmail = email.trim();
    final cleanPhone = phone.trim();
    _fullName = cleanName.isEmpty ? 'Your name' : cleanName;
    _email = cleanEmail.isEmpty ? 'you@example.com' : cleanEmail;
    if (cleanPhone.isNotEmpty && cleanPhone != _phone) {
      _phone = cleanPhone;
      _phoneVerified = false;
    }
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
  void subscribeToPlan(
    SastaPlanType plan, {
    String paymentMethod = 'UPI',
  }) {
    if (plan == SastaPlanType.free) return;
    _planType = plan;
    _autoRenew = true;
    final amount = plan == SastaPlanType.yearly ? 399 : 49;
    final name =
        plan == SastaPlanType.yearly ? 'Sasta+ Yearly' : 'Sasta+ Monthly';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final now = DateTime.now();
    final dateLabel = '${now.day} ${months[now.month - 1]} ${now.year}';
    final suffix = ((now.millisecondsSinceEpoch % 9000) + 1000).toString();
    final prefix = paymentMethod.trim().isEmpty
        ? 'UPI'
        : paymentMethod.trim().split(' ').first.toUpperCase();
    _invoices.insert(
      0,
      SubscriptionInvoice(
        id: 'inv_${now.millisecondsSinceEpoch}',
        planName: name,
        dateLabel: dateLabel,
        txnCode: '$prefix-••$suffix',
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
    _hasCompletedSplash = false;
    _activeTabIndex = 0;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    ++_syncSeq;
    ++_searchSeq;
    _fullName = 'Your name';
    _email = 'you@example.com';
    _phone = '+91 98765 43210';
    _phoneVerified = false;
    _avatarStyleIndex = 0;
    _themeMode = ThemeMode.light;
    _planType = SastaPlanType.free;
    _autoRenew = true;
    _invoices.clear();
    _favouriteIds.clear();
    _priceAlerts.clear();
    _searchHistory.clear();
    _supportTickets.clear();
    _notifications.clear();
    _recentlyViewedIds.clear();
    _savedBaskets
      ..clear()
      ..add(
        const SavedBasket(
          id: 'b_default',
          name: 'My Basket',
          updatedLabel: 'Empty',
          pastel: SastaPastel.sky,
          entries: [],
        ),
      );
    _activeBasketId = 'b_default';
    _basketActivities.clear();
    _locations
      ..clear()
      ..add(
        const SavedLocation(
          id: 'loc_1',
          label: 'Home',
          pincode: '110001',
          area: 'Central Delhi',
          isDefault: true,
        ),
      );
    _products = List<Product>.from(MockCatalog.products);
    _isLiveCatalogActive = false;
    _isCatalogSyncing = false;
    _isSearchingRemote = false;
    _lastSyncedAt = null;
    _lastSyncedPincode = null;
    _lastSyncedRetailers = const {};
    _lastSyncError = null;
    _creditsRemaining = null;
    _serviceableRetailers = const [];
    _retailerEtas.clear();
    _dailyLiveSearchDate = '';
    _dailyLiveSearchesUsed = 0;
    _onDemandLiveModeOverride = null;
    if (!_hasCustomRepo) {
      _apiBaseUrl = _defaultApiConfig?.baseUrl ?? '';
      _apiKey = _defaultApiConfig?.apiKey ?? '';
      _repository.dispose();
      _repository = HttpQuickCommerceRepository(
        config: QuickCommerceApiConfig(
          baseUrl: _apiBaseUrl,
          apiKey: _apiKey,
        ),
      );
    }
    _isLoggedOut = true;
    _hasSeenOnboarding = false;
    _hasSetPincode = false;
    _hasCompletedSplash = false;
    _activeTabIndex = 0;
    if (!_isDisposed) {
      super.notifyListeners();
    }
    await _storage?.clearAll();
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
    _scheduleSave();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _saveTimer?.cancel();
    if (!_hasCustomRepo) {
      _repository.dispose();
    }
    if (_ownsLocationService) {
      _locationService.dispose();
    }
    super.dispose();
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
