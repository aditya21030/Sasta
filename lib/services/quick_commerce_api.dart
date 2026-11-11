import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../models/models.dart';
import '../theme/sasta_tokens.dart';

/// Build-time & runtime configuration for the Sasta Quick-Commerce REST backend
/// or direct QuickCommerceAPI v1 integration.
class QuickCommerceApiConfig {
  const QuickCommerceApiConfig({
    this.baseUrl = envBaseUrl,
    this.apiKey = envApiKey,
  });

  static const String envBaseUrl =
      String.fromEnvironment('SASTA_API_BASE_URL', defaultValue: '');
  static const String envApiKey =
      String.fromEnvironment('SASTA_API_KEY', defaultValue: '');

  /// Default QuickCommerceAPI endpoint template (passes `--dart-define=SASTA_API_KEY=...`
  /// or Comparison Preferences; never embed live API keys in source control).
  static const QuickCommerceApiConfig liveQuickCommerce =
      QuickCommerceApiConfig(
    baseUrl: 'https://api.quickcommerceapi.com',
    apiKey: envApiKey,
  );

  /// Builds default API configuration from `--dart-define` values without
  /// embedding credentials in source code.
  factory QuickCommerceApiConfig.fromEnvironment() {
    if (envBaseUrl.trim().isNotEmpty) {
      return const QuickCommerceApiConfig(
        baseUrl: envBaseUrl,
        apiKey: envApiKey,
      );
    }
    if (envApiKey.trim().isNotEmpty) {
      return liveQuickCommerce;
    }
    return const QuickCommerceApiConfig();
  }

  final String baseUrl;
  final String apiKey;

  bool get isConfigured =>
      baseUri != null && (!isQuickCommerceDirect || apiKey.trim().isNotEmpty);

  bool get isQuickCommerceDirect =>
      baseUri?.host.toLowerCase().contains('quickcommerceapi.com') ?? false;

  Uri? get baseUri {
    final trimmed = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (trimmed.isEmpty) return null;
    final parsed = Uri.tryParse(trimmed);
    if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
      return null;
    }
    return parsed;
  }

  QuickCommerceApiConfig copyWith({String? baseUrl, String? apiKey}) =>
      QuickCommerceApiConfig(
        baseUrl: baseUrl ?? this.baseUrl,
        apiKey: apiKey ?? this.apiKey,
      );
}

class QuickCommerceApiException implements Exception {
  const QuickCommerceApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      statusCode == null ? message : 'HTTP $statusCode: $message';
}

class QuickCommerceCreditInfo {
  const QuickCommerceCreditInfo({
    required this.totalAvailable,
    this.totalUsed = 0,
    this.activePacks = 0,
    this.expiresAt,
  });

  final int totalAvailable;
  final int totalUsed;
  final int activePacks;
  final String? expiresAt;
}

class CatalogSyncResponse {
  const CatalogSyncResponse({
    required this.products,
    required this.pincode,
    required this.syncedAt,
    this.area,
    this.serviceableRetailers = const [],
    this.etasByRetailer = const {},
    this.creditsRemaining,
  });

  final List<Product> products;
  final String pincode;
  final DateTime syncedAt;
  final String? area;
  final List<RetailerId> serviceableRetailers;
  final Map<RetailerId, String> etasByRetailer;
  final int? creditsRemaining;
}

class ServiceabilityResponse {
  const ServiceabilityResponse({
    required this.pincode,
    required this.serviceable,
    this.area,
    this.retailers = const [],
    this.etasByRetailer = const {},
  });

  final String pincode;
  final bool serviceable;
  final String? area;
  final List<RetailerId> retailers;
  final Map<RetailerId, String> etasByRetailer;
}

/// Abstract contract implemented by the REST quick-commerce pricing client.
abstract class QuickCommerceRepository {
  bool get isConfigured;
  QuickCommerceApiConfig get config;
  int? get lastCreditsRemaining;
  int get liveNetworkRequestsMade;

  Future<CatalogSyncResponse> fetchHomeCatalog({
    required String pincode,
    double? lat,
    double? lng,
    Set<RetailerId>? retailers,
    bool forceRefresh = false,
  });

  Future<List<Product>> searchProducts({
    required String query,
    required String pincode,
    String? categoryId,
    double? lat,
    double? lng,
    Set<RetailerId>? retailers,
    bool forceRefresh = false,
  });

  Future<Product?> fetchProductDetails({
    required String productId,
    required String pincode,
  });

  Future<Map<String, PriceHistorySeries>> fetchPriceHistory({
    required String productId,
    required String pincode,
  });

  Future<ServiceabilityResponse> checkServiceability({
    required String pincode,
    double? lat,
    double? lng,
    Set<RetailerId>? retailers,
  });

  Future<QuickCommerceCreditInfo?> fetchCreditsBalance();

  bool hasFreshQueryCache({
    required String pincode,
    String query = 'milk',
    String? categoryId,
    double? lat,
    double? lng,
    Set<RetailerId>? retailers,
    bool isHomeQuery = false,
  });

  Map<String, int> exportQueryCacheTimestampsMs();

  Map<String, List<String>> exportQueryCacheProductIds();

  void hydrateQueryCache({
    required Map<String, int> timestampsMs,
    required Map<String, List<String>> productIdsByKey,
    required Iterable<Product> products,
  });

  void dispose();
}

/// Unified quick-commerce pricing repository supporting both:
/// 1) Direct QuickCommerceAPI v1 (`/v1/groupsearch`, `/v1/groupeta`, `/v1/credits`)
/// 2) Custom Sasta REST backend (`/v1/catalog/home`, `/v1/catalog/search`, etc.)
class HttpQuickCommerceRepository implements QuickCommerceRepository {
  HttpQuickCommerceRepository({
    required QuickCommerceApiConfig config,
    http.Client? client,
    this.timeout = const Duration(seconds: 18),
  })  : _config = config,
        _client = client ?? http.Client(),
        _ownsClient = client == null;

  static const String defaultQuickCommercePlatforms =
      'BlinkIt,Zepto,Swiggy,Minutes';
  static const Duration _homeCacheTtl = Duration(hours: 6);
  static const Duration _searchCacheTtl = Duration(hours: 1);
  static const Duration _emptyCacheTtl = Duration(minutes: 30);
  static const Duration _serviceabilityCacheTtl = Duration(hours: 6);

  final QuickCommerceApiConfig _config;
  final http.Client _client;
  final bool _ownsClient;
  final Duration timeout;

  int? _lastCreditsRemaining;
  String? _lastCreditsExpiry;
  int _liveNetworkRequestsMade = 0;

  final Map<String, _CachedQueryEntry> _queryCache = {};
  final Map<String, Future<List<Product>>> _inFlightQueries = {};
  final Map<String, ({DateTime fetchedAt, ServiceabilityResponse response})>
      _serviceabilityCache = {};
  final Map<String, ({DateTime recordedAt, Set<RetailerId> closedRetailers})>
      _closedRetailersByPincode = {};

  @override
  QuickCommerceApiConfig get config => _config;

  @override
  bool get isConfigured => _config.baseUri != null;

  @override
  int? get lastCreditsRemaining => _lastCreditsRemaining;

  String? get lastCreditsExpiry => _lastCreditsExpiry;

  @override
  int get liveNetworkRequestsMade => _liveNetworkRequestsMade;

  /// Snaps GPS coordinates to ~2.2 km regional dark-store hub grid so minor
  /// GPS drift does not cause duplicate paid API calls.
  static double snapCoord(double value) => (value * 50).round() / 50.0;

  static String platformParamForRetailer(RetailerId r) {
    switch (r) {
      case RetailerId.blinkit:
        return 'BlinkIt';
      case RetailerId.zepto:
        return 'Zepto';
      case RetailerId.instamart:
        return 'Swiggy';
      case RetailerId.flipkartMinutes:
        return 'Minutes';
    }
  }

  static List<String> platformsForRetailers(
    Set<RetailerId>? retailers, {
    Set<RetailerId>? closedRetailers,
  }) {
    final target = (retailers == null || retailers.isEmpty)
        ? RetailerId.values.toSet()
        : retailers;
    final openSubset = (closedRetailers == null || closedRetailers.isEmpty)
        ? target
        : target.where((r) => !closedRetailers.contains(r)).toSet();
    final effective = openSubset.isNotEmpty ? openSubset : target;
    final names = effective.map(platformParamForRetailer).toSet().toList()
      ..sort();
    return names;
  }

  static String normalizeQuery(String query, {String? categoryId}) {
    final normalized = query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isNotEmpty) return normalized;
    return _defaultQueryForCategory(categoryId);
  }

  static String buildCachePrefix({
    required String pincode,
    required String query,
    String? categoryId,
    double? lat,
    double? lng,
  }) {
    final latKey = snapCoord(lat ?? 12.9021).toStringAsFixed(4);
    final lngKey = snapCoord(lng ?? 77.6639).toStringAsFixed(4);
    final catKey = categoryId?.trim() ?? '';
    final normQ = normalizeQuery(query, categoryId: categoryId);
    return 'qc|${pincode.trim()}|$latKey|$lngKey|$catKey|$normQ';
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (_config.apiKey.trim().isNotEmpty) ...{
          if (!_config.isQuickCommerceDirect)
            'Authorization': 'Bearer ${_config.apiKey.trim()}',
          'X-API-Key': _config.apiKey.trim(),
        },
      };

  Uri _endpoint(String path, [Map<String, String>? queryParams]) {
    final base = _config.baseUri;
    if (base == null) {
      throw const QuickCommerceApiException(
        'Quick-Commerce API base URL is not configured.',
      );
    }
    final cleanBasePath = base.path.replaceAll(RegExp(r'/+$'), '');
    final cleanSegment = path.startsWith('/') ? path : '/$path';
    return base.replace(
      path: '$cleanBasePath$cleanSegment',
      queryParameters: (queryParams == null || queryParams.isEmpty)
          ? null
          : queryParams,
    );
  }

  void _captureResponseHeaders(http.Response response, dynamic decoded) {
    final headerCredits =
        int.tryParse(response.headers['x-credits-remaining'] ?? '');
    if (headerCredits != null) {
      _lastCreditsRemaining = headerCredits;
    }
    final expiry = response.headers['x-credits-expiry'];
    if (expiry != null && expiry.trim().isNotEmpty) {
      _lastCreditsExpiry = expiry.trim();
    }
    if (decoded is Map && decoded['credits_remaining'] != null) {
      final bodyCredits = int.tryParse(decoded['credits_remaining'].toString());
      if (bodyCredits != null) {
        _lastCreditsRemaining = bodyCredits;
      }
    }
  }

  Future<dynamic> _getJson(String path, [Map<String, String>? queryParams]) async {
    final uri = _endpoint(path, queryParams);
    if (path != '/v1/credits') {
      _liveNetworkRequestsMade++;
    }
    try {
      final response =
          await _client.get(uri, headers: _headers).timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        String detail = 'API request failed for $path';
        if (response.statusCode == 402) {
          detail = 'QuickCommerceAPI credits exhausted (HTTP 402).';
        } else if (response.statusCode == 429) {
          detail = 'Rate limit reached (100 req/min). Please retry in a moment.';
        } else if (response.statusCode == 401) {
          detail = 'Invalid or missing QuickCommerceAPI key (HTTP 401).';
        }
        throw QuickCommerceApiException(detail, statusCode: response.statusCode);
      }
      if (response.bodyBytes.isEmpty) {
        _captureResponseHeaders(response, null);
        return const <String, dynamic>{};
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      _captureResponseHeaders(response, decoded);
      return decoded;
    } on TimeoutException {
      throw const QuickCommerceApiException('Quick-Commerce API request timed out.');
    } on QuickCommerceApiException {
      rethrow;
    } catch (e) {
      throw QuickCommerceApiException('Network error: $e');
    }
  }

  List<Product> _parseProducts(dynamic decoded) {
    final List<dynamic> items;
    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map) {
      final raw = decoded['products'] ?? decoded['items'] ?? decoded['data'];
      items = raw is List ? raw : const [];
    } else {
      items = const [];
    }
    return items
        .whereType<Map>()
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
        .where((p) => p.id.isNotEmpty && p.name.isNotEmpty)
        .toList();
  }

  List<RetailerId> _parseRetailers(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => RetailerId.tryParse(e?.toString()))
        .whereType<RetailerId>()
        .toList();
  }

  static String _defaultQueryForCategory(String? categoryId) {
    switch (categoryId) {
      case 'dairy':
        return 'milk';
      case 'fruits_veg':
        return 'tomato potato onion';
      case 'snacks':
        return 'chips biscuits';
      case 'beverages':
        return 'tea coffee';
      case 'staples':
        return 'atta rice';
      case 'cooking':
        return 'cooking oil';
      case 'personal_care':
        return 'shampoo soap';
      case 'household':
        return 'detergent';
      case 'baby_care':
        return 'diapers';
      case 'frozen':
        return 'ice cream';
      case 'bakery':
        return 'bread butter';
      case 'meat':
        return 'eggs';
      default:
        return 'milk';
    }
  }

  Set<RetailerId>? _activeClosedRetailers(String pincode) {
    final rec = _closedRetailersByPincode[pincode.trim()];
    if (rec == null) return null;
    if (DateTime.now().difference(rec.recordedAt) >= _homeCacheTtl) {
      _closedRetailersByPincode.remove(pincode.trim());
      return null;
    }
    return rec.closedRetailers;
  }

  List<String> _effectivePlatformsFor(
    String pincode,
    Set<RetailerId>? retailers, {
    bool ignoreClosedCache = false,
  }) {
    return platformsForRetailers(
      retailers,
      closedRetailers:
          ignoreClosedCache ? null : _activeClosedRetailers(pincode),
    );
  }

  _CachedQueryEntry? _findFreshCacheEntry(
    String prefix,
    Set<String> requestedPlatforms,
    Duration maxTtl,
  ) {
    final now = DateTime.now();
    final sorted = requestedPlatforms.toList()..sort();
    final exactKey = '$prefix|${sorted.join(',')}';
    final exact = _queryCache[exactKey];
    if (exact != null) {
      final ttl = exact.products.isEmpty ? _emptyCacheTtl : maxTtl;
      if (now.difference(exact.fetchedAt) < ttl) {
        return exact;
      }
    }
    final prefixWithSep = '$prefix|';
    for (final entry in _queryCache.entries) {
      if (!entry.key.startsWith(prefixWithSep)) continue;
      final item = entry.value;
      final ttl = item.products.isEmpty ? _emptyCacheTtl : maxTtl;
      if (now.difference(item.fetchedAt) >= ttl) continue;
      if (item.platforms.containsAll(requestedPlatforms)) {
        return item;
      }
    }
    return null;
  }

  @override
  bool hasFreshQueryCache({
    required String pincode,
    String query = 'milk',
    String? categoryId,
    double? lat,
    double? lng,
    Set<RetailerId>? retailers,
    bool isHomeQuery = false,
  }) {
    final prefix = buildCachePrefix(
      pincode: pincode,
      query: query,
      categoryId: categoryId,
      lat: lat,
      lng: lng,
    );
    final platforms = _effectivePlatformsFor(pincode, retailers).toSet();
    final ttl = isHomeQuery ? _homeCacheTtl : _searchCacheTtl;
    return _findFreshCacheEntry(prefix, platforms, ttl) != null;
  }

  @override
  Map<String, int> exportQueryCacheTimestampsMs() {
    final now = DateTime.now();
    final entries = _queryCache.entries
        .where((e) => now.difference(e.value.fetchedAt) < _homeCacheTtl)
        .toList()
      ..sort((a, b) => b.value.fetchedAt.compareTo(a.value.fetchedAt));
    final out = <String, int>{};
    for (final e in entries.take(40)) {
      out[e.key] = e.value.fetchedAt.millisecondsSinceEpoch;
    }
    return out;
  }

  @override
  Map<String, List<String>> exportQueryCacheProductIds() {
    final now = DateTime.now();
    final entries = _queryCache.entries
        .where((e) => now.difference(e.value.fetchedAt) < _homeCacheTtl)
        .toList()
      ..sort((a, b) => b.value.fetchedAt.compareTo(a.value.fetchedAt));
    final out = <String, List<String>>{};
    for (final e in entries.take(40)) {
      out[e.key] = e.value.products.map((p) => p.id).toList();
    }
    return out;
  }

  @override
  void hydrateQueryCache({
    required Map<String, int> timestampsMs,
    required Map<String, List<String>> productIdsByKey,
    required Iterable<Product> products,
  }) {
    final byId = <String, Product>{for (final p in products) p.id: p};
    final now = DateTime.now();
    timestampsMs.forEach((key, tsMs) {
      final fetchedAt = DateTime.fromMillisecondsSinceEpoch(tsMs);
      if (now.difference(fetchedAt) >= _homeCacheTtl) return;
      final parts = key.split('|');
      final keyPin = parts.length >= 2 ? parts[1].trim() : '';
      final ids = productIdsByKey[key] ?? const <String>[];
      final restoredProducts = <Product>[];
      for (final id in ids) {
        final pinMatch = keyPin.isEmpty ||
            !id.startsWith('qc_') ||
            id.startsWith('qc_${keyPin}_');
        if (!pinMatch) continue;
        final p = byId[id];
        if (p != null) restoredProducts.add(p);
      }
      if (restoredProducts.isEmpty && ids.isNotEmpty) return;
      final platformStr = parts.length >= 6 ? parts.last : '';
      final platforms = platformStr
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet();
      if (platforms.isEmpty) return;
      final etas = <RetailerId, String>{};
      for (final p in restoredProducts) {
        for (final v in p.variants) {
          for (final q in v.quotes) {
            if (q.isAvailable && q.sla != null && q.sla!.trim().isNotEmpty) {
              etas.putIfAbsent(q.retailer, () => q.sla!.trim());
            }
          }
        }
      }
      _queryCache[key] = _CachedQueryEntry(
        fetchedAt: fetchedAt,
        products: restoredProducts,
        platforms: platforms,
        etas: etas,
      );
    });
  }

  final Map<String, Future<CatalogSyncResponse>> _inFlightHome = {};

  @override
  Future<CatalogSyncResponse> fetchHomeCatalog({
    required String pincode,
    double? lat,
    double? lng,
    Set<RetailerId>? retailers,
    bool forceRefresh = false,
  }) async {
    final platforms = _effectivePlatformsFor(
      pincode,
      retailers,
      ignoreClosedCache: forceRefresh,
    );
    final platformSet = platforms.toSet();
    final prefix = buildCachePrefix(
      pincode: pincode,
      query: 'milk',
      lat: lat,
      lng: lng,
    );
    final exactKey = '$prefix|${platforms.join(',')}';

    if (!forceRefresh) {
      final cached = _findFreshCacheEntry(prefix, platformSet, _homeCacheTtl);
      if (cached != null) {
        return CatalogSyncResponse(
          products: cached.products,
          pincode: pincode,
          syncedAt: cached.fetchedAt,
          serviceableRetailers: cached.etas.keys.toList(),
          etasByRetailer: cached.etas,
          creditsRemaining: _lastCreditsRemaining,
        );
      }
    }

    if (_config.isQuickCommerceDirect) {
      final mapped = await _executeQuickCommerceGroupSearch(
        query: 'milk',
        pincode: pincode,
        lat: lat ?? 12.9021,
        lng: lng ?? 77.6639,
        platforms: platforms,
        cacheTtl: _homeCacheTtl,
        forceRefresh: forceRefresh,
      );
      final liveEntry = _queryCache[exactKey];
      final etas = liveEntry?.etas ?? const <RetailerId, String>{};
      return CatalogSyncResponse(
        products: mapped,
        pincode: pincode,
        syncedAt: DateTime.now(),
        serviceableRetailers: etas.keys.toList(),
        etasByRetailer: etas,
        creditsRemaining: _lastCreditsRemaining,
      );
    }

    if (!forceRefresh && _inFlightHome.containsKey(exactKey)) {
      return _inFlightHome[exactKey]!;
    }

    final future = () async {
      final params = <String, String>{
        'pincode': pincode,
        if (lat != null) 'lat': snapCoord(lat).toStringAsFixed(4),
        if (lng != null) 'lng': snapCoord(lng).toStringAsFixed(4),
        if (retailers != null) 'platforms': platforms.join(','),
      };
      final decoded = await _getJson('/v1/catalog/home', params);
      final map = decoded is Map ? Map<String, dynamic>.from(decoded) : null;
      final rawGs = _extractRawGroupSearchMap(map);
      late final List<Product> products;
      late final Map<RetailerId, String> etas;
      late final List<RetailerId> serviceableRetailers;

      if (rawGs != null) {
        final mapped = QuickCommerceApiMapper.mapGroupSearchResponse(
          rawGs,
          pincode: pincode,
        );
        _recordClosedRetailers(pincode, rawGs);
        products = mapped.products;
        etas = mapped.etasByRetailer;
        serviceableRetailers = etas.keys.toList();
      } else {
        products = _parseProducts(decoded);
        etas = const {};
        final retailersRaw = map?['serviceableRetailers'] ??
            map?['serviceable_retailers'] ??
            map?['retailers'];
        serviceableRetailers = _parseRetailers(retailersRaw);
      }

      final now = DateTime.now();
      _queryCache[exactKey] = _CachedQueryEntry(
        fetchedAt: now,
        products: products,
        platforms: platformSet,
        etas: etas,
      );
      if (etas.isNotEmpty || serviceableRetailers.isNotEmpty) {
        _serviceabilityCache[pincode] = (
          fetchedAt: now,
          response: ServiceabilityResponse(
            pincode: pincode,
            serviceable: serviceableRetailers.isNotEmpty || etas.isNotEmpty,
            area: map?['area']?.toString(),
            retailers: serviceableRetailers.isNotEmpty
                ? serviceableRetailers
                : etas.keys.toList(),
            etasByRetailer: etas,
          ),
        );
      }

      return CatalogSyncResponse(
        products: products,
        pincode: map?['pincode']?.toString() ?? pincode,
        area: map?['area']?.toString(),
        serviceableRetailers: serviceableRetailers,
        etasByRetailer: etas,
        syncedAt: now,
        creditsRemaining: _lastCreditsRemaining,
      );
    }();

    _inFlightHome[exactKey] = future;
    try {
      return await future;
    } finally {
      _inFlightHome.remove(exactKey);
    }
  }

  Map<String, dynamic>? _extractRawGroupSearchMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    if (map['rawGroupSearch'] is Map) {
      return Map<String, dynamic>.from(map['rawGroupSearch'] as Map);
    }
    if (map['data'] is Map && (map['data'] as Map)['results'] is Map) {
      return map;
    }
    if (map['results'] is Map) {
      return map;
    }
    return null;
  }

  void _recordClosedRetailers(String pincode, Map<String, dynamic> decoded) {
    final closed = QuickCommerceApiMapper.extractClosedRetailers(decoded);
    final reopened = QuickCommerceApiMapper.extractOpenRetailers(decoded);
    final key = pincode.trim();
    final existing = Set<RetailerId>.from(
      _activeClosedRetailers(key) ?? const <RetailerId>{},
    );
    existing.removeAll(reopened);
    existing.addAll(closed);
    if (existing.isEmpty) {
      _closedRetailersByPincode.remove(key);
    } else {
      _closedRetailersByPincode[key] = (
        recordedAt: DateTime.now(),
        closedRetailers: existing,
      );
    }
  }

  @override
  Future<List<Product>> searchProducts({
    required String query,
    required String pincode,
    String? categoryId,
    double? lat,
    double? lng,
    Set<RetailerId>? retailers,
    bool forceRefresh = false,
  }) async {
    final platforms = _effectivePlatformsFor(
      pincode,
      retailers,
      ignoreClosedCache: forceRefresh,
    );
    final platformSet = platforms.toSet();
    final effectiveQuery = normalizeQuery(query, categoryId: categoryId);
    final prefix = buildCachePrefix(
      pincode: pincode,
      query: effectiveQuery,
      categoryId: categoryId,
      lat: lat,
      lng: lng,
    );
    final exactKey = '$prefix|${platforms.join(',')}';

    if (!forceRefresh) {
      final cached = _findFreshCacheEntry(prefix, platformSet, _searchCacheTtl);
      if (cached != null) {
        return cached.products;
      }
      if (_inFlightQueries.containsKey(exactKey)) {
        return _inFlightQueries[exactKey]!;
      }
    }

    if (_config.isQuickCommerceDirect) {
      return _executeQuickCommerceGroupSearch(
        query: effectiveQuery,
        pincode: pincode,
        lat: lat ?? 12.9021,
        lng: lng ?? 77.6639,
        platforms: platforms,
        cacheTtl: _searchCacheTtl,
        forceRefresh: forceRefresh,
        preferredCategoryId: categoryId,
      );
    }

    final future = () async {
      final params = <String, String>{
        'q': effectiveQuery,
        'pincode': pincode,
        if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
        if (lat != null) 'lat': snapCoord(lat).toStringAsFixed(4),
        if (lng != null) 'lng': snapCoord(lng).toStringAsFixed(4),
        if (retailers != null) 'platforms': platforms.join(','),
      };
      final decoded = await _getJson('/v1/catalog/search', params);
      final map = decoded is Map ? Map<String, dynamic>.from(decoded) : null;
      final rawGs = _extractRawGroupSearchMap(map);
      late final List<Product> products;
      late final Map<RetailerId, String> etas;
      if (rawGs != null) {
        final mapped = QuickCommerceApiMapper.mapGroupSearchResponse(
          rawGs,
          preferredCategoryId: categoryId,
          pincode: pincode,
        );
        _recordClosedRetailers(pincode, rawGs);
        products = mapped.products;
        etas = mapped.etasByRetailer;
      } else {
        products = _parseProducts(decoded);
        etas = const {};
      }
      _queryCache[exactKey] = _CachedQueryEntry(
        fetchedAt: DateTime.now(),
        products: products,
        platforms: platformSet,
        etas: etas,
      );
      return products;
    }();

    _inFlightQueries[exactKey] = future;
    try {
      return await future;
    } finally {
      _inFlightQueries.remove(exactKey);
    }
  }

  Future<List<Product>> _executeQuickCommerceGroupSearch({
    required String query,
    required String pincode,
    required double lat,
    required double lng,
    required List<String> platforms,
    required Duration cacheTtl,
    required bool forceRefresh,
    String? preferredCategoryId,
  }) async {
    final snappedLat = snapCoord(lat).toStringAsFixed(4);
    final snappedLng = snapCoord(lng).toStringAsFixed(4);
    final prefix = buildCachePrefix(
      pincode: pincode,
      query: query,
      categoryId: preferredCategoryId,
      lat: lat,
      lng: lng,
    );
    final platformSet = platforms.toSet();
    final exactKey = '$prefix|${platforms.join(',')}';

    if (!forceRefresh) {
      final cached = _findFreshCacheEntry(prefix, platformSet, cacheTtl);
      if (cached != null) {
        return cached.products;
      }
      if (_inFlightQueries.containsKey(exactKey)) {
        return _inFlightQueries[exactKey]!;
      }
    }

    final future = () async {
      final params = <String, String>{
        'q': query.trim(),
        'lat': snappedLat,
        'lon': snappedLng,
        'pincode': pincode,
        'platforms': platforms.join(','),
      };
      final decoded = await _getJson('/v1/groupsearch', params);
      if (decoded is! Map) return const <Product>[];
      final decodedMap = Map<String, dynamic>.from(decoded);
      _recordClosedRetailers(pincode, decodedMap);
      final mapped = QuickCommerceApiMapper.mapGroupSearchResponse(
        decodedMap,
        preferredCategoryId: preferredCategoryId,
        pincode: pincode,
      );
      _queryCache[exactKey] = _CachedQueryEntry(
        fetchedAt: DateTime.now(),
        products: mapped.products,
        platforms: platformSet,
        etas: mapped.etasByRetailer,
      );
      if (mapped.etasByRetailer.isNotEmpty) {
        _serviceabilityCache[pincode] = (
          fetchedAt: DateTime.now(),
          response: ServiceabilityResponse(
            pincode: pincode,
            serviceable: true,
            retailers: mapped.etasByRetailer.keys.toList(),
            etasByRetailer: mapped.etasByRetailer,
          ),
        );
      }
      return mapped.products;
    }();

    _inFlightQueries[exactKey] = future;
    try {
      return await future;
    } finally {
      _inFlightQueries.remove(exactKey);
    }
  }

  @override
  Future<Product?> fetchProductDetails({
    required String productId,
    required String pincode,
  }) async {
    if (_config.isQuickCommerceDirect) {
      // Groupsearch results already include all item details, images, deeplinks & SLAs;
      // avoid unnecessary per-item credit burn unless calling a dedicated proxy.
      for (final entry in _queryCache.values) {
        for (final p in entry.products) {
          if (p.id == productId) return p;
        }
      }
      return null;
    }
    final decoded = await _getJson(
      '/v1/catalog/products/${Uri.encodeComponent(productId)}',
      {'pincode': pincode},
    );
    if (decoded is Map) {
      final inner = decoded['product'] ?? decoded['data'] ?? decoded;
      if (inner is Map) {
        final product = Product.fromJson(Map<String, dynamic>.from(inner));
        if (product.id.isNotEmpty) return product;
      }
    }
    return null;
  }

  @override
  Future<Map<String, PriceHistorySeries>> fetchPriceHistory({
    required String productId,
    required String pincode,
  }) async {
    if (_config.isQuickCommerceDirect) {
      // QuickCommerceAPI exposes real-time pricing; historical charts stay cached locally.
      return const {};
    }
    final decoded = await _getJson(
      '/v1/catalog/products/${Uri.encodeComponent(productId)}/history',
      {'pincode': pincode},
    );
    if (decoded is! Map) return const {};
    final raw =
        decoded['historyByRange'] ?? decoded['history_by_range'] ?? decoded;
    if (raw is! Map) return const {};
    final out = <String, PriceHistorySeries>{};
    raw.forEach((k, v) {
      if (v is Map) {
        out[k.toString()] = PriceHistorySeries.fromJson(
          Map<String, dynamic>.from(v),
        );
      }
    });
    return out;
  }

  @override
  Future<ServiceabilityResponse> checkServiceability({
    required String pincode,
    double? lat,
    double? lng,
    Set<RetailerId>? retailers,
  }) async {
    final cached = _serviceabilityCache[pincode];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) < _serviceabilityCacheTtl) {
      return cached.response;
    }

    // Derive serviceability cleanly from any cached groupsearch entry for this pincode at 0 credits.
    final now = DateTime.now();
    final pinPrefix = 'qc|${pincode.trim()}|';
    for (final entry in _queryCache.entries) {
      if (!entry.key.startsWith(pinPrefix)) continue;
      if (now.difference(entry.value.fetchedAt) >= _homeCacheTtl) continue;
      if (entry.value.etas.isNotEmpty) {
        final derived = ServiceabilityResponse(
          pincode: pincode,
          serviceable: true,
          retailers: entry.value.etas.keys.toList(),
          etasByRetailer: entry.value.etas,
        );
        _serviceabilityCache[pincode] = (fetchedAt: now, response: derived);
        return derived;
      }
    }

    final platforms = _effectivePlatformsFor(pincode, retailers);
    if (_config.isQuickCommerceDirect) {
      final params = <String, String>{
        'lat': snapCoord(lat ?? 12.9021).toStringAsFixed(4),
        'lon': snapCoord(lng ?? 77.6639).toStringAsFixed(4),
        'pincode': pincode,
        'platforms': platforms.join(','),
      };
      final decoded = await _getJson('/v1/groupeta', params);
      final map = decoded is Map ? Map<String, dynamic>.from(decoded) : const {};
      final data = map['data'] is Map
          ? Map<String, dynamic>.from(map['data'] as Map)
          : map;
      final results = data['results'] as List<dynamic>? ?? const [];
      final etas = <RetailerId, String>{};
      final openRetailers = <RetailerId>[];
      final closedSet = <RetailerId>{};
      for (final row in results.whereType<Map>()) {
        final r = RetailerId.tryParse(row['platform']?.toString());
        final eta = row['eta']?.toString().trim();
        final open = row['open'] != false;
        if (r != null) {
          if (open) {
            openRetailers.add(r);
            if (eta != null && eta.isNotEmpty) etas[r] = eta;
          } else {
            closedSet.add(r);
          }
        }
      }
      if (closedSet.isNotEmpty) {
        final existing = _activeClosedRetailers(pincode) ?? const <RetailerId>{};
        _closedRetailersByPincode[pincode.trim()] = (
          recordedAt: now,
          closedRetailers: {...existing, ...closedSet},
        );
      }
      final res = ServiceabilityResponse(
        pincode: pincode,
        serviceable: openRetailers.isNotEmpty,
        retailers: openRetailers,
        etasByRetailer: etas,
      );
      _serviceabilityCache[pincode] = (fetchedAt: now, response: res);
      return res;
    }

    final decoded = await _getJson('/v1/serviceability', {
      'pincode': pincode,
      if (lat != null) 'lat': snapCoord(lat).toStringAsFixed(4),
      if (lng != null) 'lng': snapCoord(lng).toStringAsFixed(4),
      if (retailers != null) 'platforms': platforms.join(','),
    });
    if (decoded is! Map) {
      return ServiceabilityResponse(pincode: pincode, serviceable: false);
    }
    final map = Map<String, dynamic>.from(decoded);
    final etas = <RetailerId, String>{};
    final rawEtas = map['etas'] ?? map['etasByRetailer'];
    if (rawEtas is Map) {
      rawEtas.forEach((k, v) {
        final r = RetailerId.tryParse(k.toString());
        if (r != null && v != null) {
          etas[r] = v.toString();
        }
      });
    }
    final res = ServiceabilityResponse(
      pincode: map['pincode']?.toString() ?? pincode,
      serviceable: map['serviceable'] == true || map['is_serviceable'] == true,
      area: map['area']?.toString(),
      retailers: _parseRetailers(map['retailers']),
      etasByRetailer: etas,
    );
    _serviceabilityCache[pincode] = (fetchedAt: now, response: res);
    return res;
  }

  /// Free endpoint (`0 credits`): queries current credit balance from QuickCommerceAPI.
  @override
  Future<QuickCommerceCreditInfo?> fetchCreditsBalance() async {
    if (!isConfigured || !_config.isQuickCommerceDirect) return null;
    try {
      final decoded = await _getJson('/v1/credits');
      if (decoded is! Map) return null;
      final summary = decoded['summary'] is Map
          ? Map<String, dynamic>.from(decoded['summary'] as Map)
          : Map<String, dynamic>.from(decoded);
      final available = int.tryParse(
        summary['total_available']?.toString() ?? '',
      );
      if (available == null) return null;
      _lastCreditsRemaining = available;
      final active = decoded['active'] as List<dynamic>? ?? const [];
      String? expiresAt;
      if (active.isNotEmpty && active.first is Map) {
        expiresAt = (active.first as Map)['expires_at']?.toString();
        _lastCreditsExpiry = expiresAt;
      }
      return QuickCommerceCreditInfo(
        totalAvailable: available,
        totalUsed: int.tryParse(summary['total_used']?.toString() ?? '0') ?? 0,
        activePacks:
            int.tryParse(summary['active_packs']?.toString() ?? '0') ?? 0,
        expiresAt: expiresAt,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

class MappedGroupSearchResult {
  const MappedGroupSearchResult({
    required this.products,
    required this.etasByRetailer,
  });

  final List<Product> products;
  final Map<RetailerId, String> etasByRetailer;
}

class _RawPlatformItem {
  _RawPlatformItem({
    required this.retailer,
    required this.itemId,
    required this.name,
    required this.brand,
    required this.brandRoot,
    required this.tokens,
    required this.pack,
    required this.quote,
    required this.images,
    required this.rating,
    required this.ratingCount,
    required this.orderScore,
  });

  final RetailerId retailer;
  final String itemId;
  final String name;
  final String brand;
  final String brandRoot;
  final Set<String> tokens;
  final _NormalizedPack pack;
  final RetailerQuote quote;
  final List<String> images;
  final double? rating;
  final int? ratingCount;
  final int orderScore;
}

class _NormalizedPack {
  const _NormalizedPack({
    required this.label,
    required this.canonicalKey,
    required this.sortMeasure,
    required this.totalBaseValue,
    required this.baseUnit,
  });

  final String label;
  final String canonicalKey;
  final double sortMeasure;
  final double? totalBaseValue; // grams, ml, or pieces
  final String? baseUnit; // 'g', 'ml', 'pc'
}

class _VariantBucket {
  _VariantBucket({
    required this.pack,
    required this.items,
  });

  final _NormalizedPack pack;
  final List<_RawPlatformItem> items;
}

class _CachedQueryEntry {
  const _CachedQueryEntry({
    required this.fetchedAt,
    required this.products,
    required this.platforms,
    required this.etas,
  });

  final DateTime fetchedAt;
  final List<Product> products;
  final Set<String> platforms;
  final Map<RetailerId, String> etas;
}

class _ProductCluster {
  _ProductCluster({
    required this.brandRoot,
    required this.tokens,
    required this.variantsByPackKey,
  });

  final String brandRoot;
  final Set<String> tokens;
  final Map<String, _VariantBucket> variantsByPackKey;
}

/// Maps raw QuickCommerceAPI `/v1/groupsearch` multi-platform payloads into
/// unified multi-retailer [Product] objects with cross-store variants, images,
/// deeplink URLs, live SLAs, and unit pricing.
abstract final class QuickCommerceApiMapper {
  static const Set<String> _fillerWords = {
    'fresh',
    'pouch',
    'pack',
    'fino',
    'tetra',
    'pet',
    'bottle',
    'jar',
    'box',
    'sachet',
    'pasteurised',
    'pasteurized',
    'homogenised',
    'homogenized',
    'enriched',
    'ultra',
    'pure',
    'classic',
    'natural',
    'original',
    'new',
    'combo',
    'with',
    'and',
    'the',
    'for',
    'of',
    'in',
    'ml',
    'ltr',
    'gm',
    'kg',
    'pc',
    'pcs',
    'long',
    'life',
    'shelf',
    'days',
    'day',
    'milky',
    'uht',
  };

  static const Set<String> _exclusiveModifiers = {
    'toned',
    'double',
    'skimmed',
    'skim',
    'full',
    'cream',
    'gold',
    'taaza',
    'shubham',
    'shakti',
    'moti',
    'goodlife',
    'standardized',
    'special',
    'lactose',
    'protein',
    'a2',
    'cow',
    'buffalo',
    'chocolate',
    'hazelnut',
    'caramel',
    'strawberry',
    'vanilla',
    'mango',
    'badam',
    'salted',
    'unsalted',
    'brown',
    'white',
    'multigrain',
    'whole',
    'wheat',
    'organic',
    'sugar',
    'free',
    'zero',
    'lite',
    'pro',
    'max',
  };

  static Set<RetailerId> extractClosedRetailers(Map<String, dynamic> decoded) {
    final data = decoded['data'] is Map
        ? Map<String, dynamic>.from(decoded['data'] as Map)
        : decoded;
    final resultsRaw = data['results'];
    final closed = <RetailerId>{};
    if (resultsRaw is Map) {
      resultsRaw.forEach((platKey, listRaw) {
        final retailer = RetailerId.tryParse(platKey.toString());
        if (retailer == null || listRaw is! List || listRaw.isEmpty) return;
        final anyOpen = listRaw.whereType<Map>().any((item) {
          final p = item['platform'];
          return p is! Map || p['open'] != false;
        });
        if (!anyOpen) {
          closed.add(retailer);
        }
      });
    }
    return closed;
  }

  static Set<RetailerId> extractOpenRetailers(Map<String, dynamic> decoded) {
    final data = decoded['data'] is Map
        ? Map<String, dynamic>.from(decoded['data'] as Map)
        : decoded;
    final resultsRaw = data['results'];
    final opened = <RetailerId>{};
    if (resultsRaw is Map) {
      resultsRaw.forEach((platKey, listRaw) {
        final retailer = RetailerId.tryParse(platKey.toString());
        if (retailer == null || listRaw is! List || listRaw.isEmpty) return;
        final anyOpen = listRaw.whereType<Map>().any((item) {
          final p = item['platform'];
          return p is! Map || p['open'] != false;
        });
        if (anyOpen) {
          opened.add(retailer);
        }
      });
    }
    return opened;
  }

  static MappedGroupSearchResult mapGroupSearchResponse(
    Map<String, dynamic> decoded, {
    String? preferredCategoryId,
    String? pincode,
  }) {
    final data = decoded['data'] is Map
        ? Map<String, dynamic>.from(decoded['data'] as Map)
        : decoded;
    final query = data['query']?.toString() ?? '';
    final resultsRaw = data['results'];
    final etasByRetailer = <RetailerId, String>{};
    final rawItems = <_RawPlatformItem>[];

    if (resultsRaw is Map) {
      resultsRaw.forEach((platKey, listRaw) {
        final retailer = RetailerId.tryParse(platKey.toString());
        if (retailer == null || listRaw is! List) return;
        for (var i = 0; i < listRaw.length; i++) {
          final entry = listRaw[i];
          if (entry is! Map) continue;
          final itemMap = Map<String, dynamic>.from(entry);
          final platInfo = itemMap['platform'] is Map
              ? Map<String, dynamic>.from(itemMap['platform'] as Map)
              : const <String, dynamic>{};
          final sla = platInfo['sla']?.toString().trim();
          final platOpen = platInfo['open'] != false;
          if (sla != null && sla.isNotEmpty) {
            etasByRetailer.putIfAbsent(retailer, () => sla);
          }
          final mappedItem = _parseRawItem(
            itemMap,
            retailer: retailer,
            sla: sla,
            platformOpen: platOpen,
            orderScore: i,
          );
          if (mappedItem != null) {
            rawItems.add(mappedItem);
          }
        }
      });
    }

    final clusters = <_ProductCluster>[];
    for (final item in rawItems) {
      _ProductCluster? target;
      for (final cluster in clusters) {
        if (_isSameProductFamily(cluster, item)) {
          target = cluster;
          break;
        }
      }
      if (target == null) {
        clusters.add(
          _ProductCluster(
            brandRoot: item.brandRoot,
            tokens: Set<String>.from(item.tokens),
            variantsByPackKey: {
              item.pack.canonicalKey: _VariantBucket(
                pack: item.pack,
                items: [item],
              ),
            },
          ),
        );
      } else {
        final bucket = target.variantsByPackKey[item.pack.canonicalKey];
        if (bucket == null) {
          target.variantsByPackKey[item.pack.canonicalKey] = _VariantBucket(
            pack: item.pack,
            items: [item],
          );
        } else {
          final sameStoreIdx = bucket.items.indexWhere(
            (existing) => existing.retailer == item.retailer,
          );
          if (sameStoreIdx == -1) {
            bucket.items.add(item);
          } else {
            // Keep available or cheaper listing if platform returned duplicates.
            final existing = bucket.items[sameStoreIdx];
            final replace = (!existing.quote.isAvailable && item.quote.isAvailable) ||
                (item.quote.isAvailable &&
                    existing.quote.isAvailable &&
                    (item.quote.price ?? 999999) < (existing.quote.price ?? 999999));
            if (replace) {
              bucket.items[sameStoreIdx] = item;
            }
          }
        }
      }
    }

    final products = <Product>[];
    for (var i = 0; i < clusters.length; i++) {
      final p = _buildProductFromCluster(
        clusters[i],
        query: query,
        preferredCategoryId: preferredCategoryId,
        pincode: pincode,
        paletteSeed: i,
      );
      if (p != null) products.add(p);
    }

    // Prioritize products matched across 2+ apps, then lowest rank index.
    products.sort((a, b) {
      final ac = a.availableAppCount(a.defaultVariantIndex);
      final bc = b.availableAppCount(b.defaultVariantIndex);
      if (ac != bc) return bc.compareTo(ac);
      return a.name.compareTo(b.name);
    });

    return MappedGroupSearchResult(
      products: products,
      etasByRetailer: etasByRetailer,
    );
  }

  static _RawPlatformItem? _parseRawItem(
    Map<String, dynamic> map, {
    required RetailerId retailer,
    required String? sla,
    required bool platformOpen,
    required int orderScore,
  }) {
    final name = map['name']?.toString().trim() ?? '';
    final itemId = map['id']?.toString().trim() ?? '';
    if (name.isEmpty || itemId.isEmpty) return null;

    final brand = map['brand']?.toString().trim() ?? '';
    final mrp = _parseRupees(map['mrp']);
    final offerPrice = _parseRupees(map['offer_price']) ?? mrp;
    final available = map['available'] != false && platformOpen && offerPrice != null;
    final inventory = int.tryParse(map['inventory']?.toString() ?? '');
    final deeplink = map['deeplink']?.toString().trim();
    final rating = double.tryParse(map['rating']?.toString() ?? '');
    final ratingCount = int.tryParse(map['rating_count']?.toString() ?? '');

    final rawImages = map['images'] as List<dynamic>? ?? const [];
    final images = rawImages
        .map((e) => e?.toString().trim() ?? '')
        .where((s) => s.startsWith('http://') || s.startsWith('https://'))
        .toList();

    final pack = _normalizePack(map['quantity']?.toString() ?? '', fallbackName: name);
    final StockStatus stockStatus;
    int? lowStockCount;
    if (!available) {
      stockStatus = StockStatus.outOfStock;
    } else if (inventory != null && inventory > 0 && inventory <= 3) {
      stockStatus = StockStatus.lowStock;
      lowStockCount = inventory;
    } else {
      stockStatus = StockStatus.inStock;
    }

    final unitPriceText = _formatUnitPrice(offerPrice, pack);
    final quote = RetailerQuote(
      retailer: retailer,
      price: offerPrice,
      mrp: mrp,
      packLabel: pack.label,
      unitPriceText: unitPriceText,
      stockStatus: stockStatus,
      lowStockCount: lowStockCount,
      productUrl: (deeplink != null && deeplink.isNotEmpty) ? deeplink : null,
      itemId: itemId,
      imageUrl: images.isNotEmpty ? images.first : null,
      sla: sla,
      rating: rating,
      ratingCount: ratingCount,
    );

    final brandRoot = _normalizeBrandRoot(brand);
    final tokens = _extractCoreTokens(brand: brand, name: name);

    return _RawPlatformItem(
      retailer: retailer,
      itemId: itemId,
      name: name,
      brand: brand,
      brandRoot: brandRoot,
      tokens: tokens,
      pack: pack,
      quote: quote,
      images: images,
      rating: rating,
      ratingCount: ratingCount,
      orderScore: orderScore,
    );
  }

  static int? _parseRupees(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    final cleaned = raw.toString().replaceAll(RegExp(r'[^0-9.]'), '').trim();
    if (cleaned.isEmpty) return null;
    final asDouble = double.tryParse(cleaned);
    return asDouble?.round();
  }

  static String _normalizeBrandRoot(String brand) {
    var b = brand.toLowerCase().trim();
    b = b.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    const brandAliases = {
      'akshayakalpa organic': 'akshayakalpa',
      'nandini goodlife': 'nandini',
      'nandini good life': 'nandini',
      'aashirvaad select': 'aashirvaad',
      'tata sampann': 'tata',
      'country delight': 'country delight',
    };
    for (final entry in brandAliases.entries) {
      if (b == entry.key) return entry.value;
    }
    final words = b.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';
    if (words.first == 'country' && words.length > 1 && words[1] == 'delight') {
      return 'country delight';
    }
    return words.first;
  }

  static Set<String> _extractCoreTokens({
    required String brand,
    required String name,
  }) {
    var text = '$brand $name'.toLowerCase();
    text = text
        .replaceAll('pasteurised', 'pasteurized')
        .replaceAll('standardised', 'standardized')
        .replaceAll('homogenised', 'homogenized')
        .replaceAll('flavoured', 'flavored')
        .replaceAll('good life', 'goodlife')
        .replaceAll('full cream', 'full cream')
        .replaceAll('low fat', 'toned');
    // Remove quantity expressions that sometimes sit inside product names.
    text = text.replaceAll(RegExp(r'\b\d+(\.\d+)?\s*(ml|l|ltr|g|gm|kg|pcs|pc)\b'), ' ');
    text = text.replaceAll(RegExp(r'\([^)]*\)'), ' ');
    text = text.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');

    final brandParts =
        brand.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();
    final tokens = <String>{};
    for (final w in text.split(RegExp(r'\s+'))) {
      if (w.length < 2) continue;
      if (_fillerWords.contains(w)) continue;
      if (brandParts.contains(w)) continue;
      tokens.add(w);
    }
    return tokens;
  }

  static bool _isSameProductFamily(
    _ProductCluster cluster,
    _RawPlatformItem item,
  ) {
    if (cluster.brandRoot.isNotEmpty &&
        item.brandRoot.isNotEmpty &&
        cluster.brandRoot != item.brandRoot) {
      return false;
    }
    // Never merge conflicting sub-types (e.g., Full Cream vs Toned, Taaza vs Gold).
    for (final mod in _exclusiveModifiers) {
      final aHas = cluster.tokens.contains(mod);
      final bHas = item.tokens.contains(mod);
      if (aHas != bHas) {
        // Exception: Swiggy omits "Toned" or "Standardized" occasionally if another distinctive word matches.
        if (mod == 'standardized' || mod == 'cow') continue;
        return false;
      }
    }
    if (cluster.tokens.isEmpty || item.tokens.isEmpty) return false;
    final intersection = cluster.tokens.intersection(item.tokens).length;
    final minLen = math.min(cluster.tokens.length, item.tokens.length);
    final overlapRatio = intersection / minLen;
    if (overlapRatio >= 0.75) return true;
    // Allow "Daily Health Toned Milk" vs "Toned Fresh Milk" under same brand.
    if (intersection >= 2 && overlapRatio >= 0.5) return true;
    return false;
  }

  static _NormalizedPack _normalizePack(
    String rawQty, {
    required String fallbackName,
  }) {
    var q = rawQty.trim();
    if (q.isEmpty) {
      final inName = RegExp(
        r'(\d+(?:\.\d+)?\s*(?:ml|l|ltr|litre|g|gm|kg|pcs|pc))',
        caseSensitive: false,
      ).firstMatch(fallbackName);
      if (inName != null) {
        q = inName.group(1) ?? '';
      }
    }
    // Unwrap "1 pack (500 ml)" -> "500 ml"
    final parenMatch = RegExp(r'\(([^)]+)\)').firstMatch(q);
    if (parenMatch != null &&
        RegExp(r'\d+\s*(ml|l|ltr|g|gm|kg|pc|pcs)', caseSensitive: false)
            .hasMatch(parenMatch.group(1)!)) {
      q = parenMatch.group(1)!.trim();
    }
    // Handle "475 ml or 500 ml" -> take latter canonical value
    if (q.toLowerCase().contains(' or ')) {
      q = q.split(RegExp(r'\s+or\s+', caseSensitive: false)).last.trim();
    }

    // Check multipacks like "500 ml x 4" or "2 x 200 ml"
    final multiAfter = RegExp(
      r'^(\d+(?:\.\d+)?)\s*(ml|l|ltr|g|gm|kg|pc|pcs)\s*[x×]\s*(\d+)$',
      caseSensitive: false,
    ).firstMatch(q);
    if (multiAfter != null) {
      final val = double.tryParse(multiAfter.group(1)!) ?? 1;
      final unit = _canonicalUnit(multiAfter.group(2)!);
      final count = int.tryParse(multiAfter.group(3)!) ?? 1;
      final perPackBase = _toBaseMeasure(val, unit);
      final base = _toBaseMeasure(val * count, unit);
      final displayUnit = _displayUnit(unit);
      final cleanVal = val == val.roundToDouble() ? val.round().toString() : val.toString();
      final canonicalPerPack =
          perPackBase.amount == perPackBase.amount.roundToDouble()
              ? perPackBase.amount.round().toString()
              : perPackBase.amount.toString();
      return _NormalizedPack(
        label: '$count x $cleanVal $displayUnit',
        canonicalKey: '${count}x${canonicalPerPack}_${perPackBase.unit}',
        sortMeasure: base.amount,
        totalBaseValue: base.amount,
        baseUnit: base.unit,
      );
    }

    final multiBefore = RegExp(
      r'^(\d+)\s*[x×]\s*(\d+(?:\.\d+)?)\s*(ml|l|ltr|g|gm|kg|pc|pcs)$',
      caseSensitive: false,
    ).firstMatch(q);
    if (multiBefore != null) {
      final count = int.tryParse(multiBefore.group(1)!) ?? 1;
      final val = double.tryParse(multiBefore.group(2)!) ?? 1;
      final unit = _canonicalUnit(multiBefore.group(3)!);
      final perPackBase = _toBaseMeasure(val, unit);
      final base = _toBaseMeasure(val * count, unit);
      final displayUnit = _displayUnit(unit);
      final cleanVal = val == val.roundToDouble() ? val.round().toString() : val.toString();
      final canonicalPerPack =
          perPackBase.amount == perPackBase.amount.roundToDouble()
              ? perPackBase.amount.round().toString()
              : perPackBase.amount.toString();
      return _NormalizedPack(
        label: '$count x $cleanVal $displayUnit',
        canonicalKey: '${count}x${canonicalPerPack}_${perPackBase.unit}',
        sortMeasure: base.amount,
        totalBaseValue: base.amount,
        baseUnit: base.unit,
      );
    }

    final single = RegExp(
      r'(\d+(?:\.\d+)?)\s*(ml|l|ltr|litres?|g|gm|gms|grams?|kg|kgs|pcs?|pieces?)',
      caseSensitive: false,
    ).firstMatch(q);
    if (single != null) {
      final val = double.tryParse(single.group(1)!) ?? 1;
      final unit = _canonicalUnit(single.group(2)!);
      final base = _toBaseMeasure(val, unit);
      final displayUnit = _displayUnit(unit);
      final cleanVal = val == val.roundToDouble() ? val.round().toString() : val.toString();
      final canonicalAmount = base.amount == base.amount.roundToDouble()
          ? base.amount.round().toString()
          : base.amount.toString();
      return _NormalizedPack(
        label: '$cleanVal $displayUnit',
        canonicalKey: '$canonicalAmount${base.unit}',
        sortMeasure: base.amount,
        totalBaseValue: base.amount,
        baseUnit: base.unit,
      );
    }

    final fallback = q.isEmpty ? '1 unit' : q;
    return _NormalizedPack(
      label: fallback,
      canonicalKey: fallback.toLowerCase().replaceAll(RegExp(r'\s+'), '_'),
      sortMeasure: 999999,
      totalBaseValue: null,
      baseUnit: null,
    );
  }

  static String _canonicalUnit(String raw) {
    final u = raw.toLowerCase();
    if (u.startsWith('l')) return 'l';
    if (u == 'ml') return 'ml';
    if (u.startsWith('k')) return 'kg';
    if (u.startsWith('g')) return 'g';
    return 'pc';
  }

  static String _displayUnit(String canonicalUnit) {
    switch (canonicalUnit) {
      case 'l':
        return 'L';
      case 'ml':
        return 'ml';
      case 'kg':
        return 'kg';
      case 'g':
        return 'g';
      default:
        return 'pc';
    }
  }

  static ({double amount, String unit}) _toBaseMeasure(
    double value,
    String canonicalUnit,
  ) {
    switch (canonicalUnit) {
      case 'l':
        return (amount: value * 1000, unit: 'ml');
      case 'ml':
        return (amount: value, unit: 'ml');
      case 'kg':
        return (amount: value * 1000, unit: 'g');
      case 'g':
        return (amount: value, unit: 'g');
      default:
        return (amount: value, unit: 'pc');
    }
  }

  static String _formatUnitPrice(int? price, _NormalizedPack pack) {
    if (price == null) return 'Out of stock';
    final base = pack.totalBaseValue;
    final unit = pack.baseUnit;
    if (base == null || base <= 0 || unit == null) {
      return '₹$price / ${pack.label}';
    }
    if (unit == 'ml' || unit == 'g') {
      final per100 = (price / base) * 100;
      return '₹${per100.toStringAsFixed(per100 >= 10 ? 0 : 1)} / 100 $unit';
    }
    final perPc = price / base;
    return '₹${perPc.toStringAsFixed(0)} / pc';
  }

  static Product? _buildProductFromCluster(
    _ProductCluster cluster, {
    required String query,
    String? preferredCategoryId,
    String? pincode,
    required int paletteSeed,
  }) {
    if (cluster.variantsByPackKey.isEmpty) return null;
    final buckets = cluster.variantsByPackKey.values.toList()
      ..sort((a, b) => a.pack.sortMeasure.compareTo(b.pack.sortMeasure));

    final variants = <PackVariant>[];
    final allImages = <String>[];
    double? bestRating;
    int? bestRatingCount;
    String bestBrand = '';
    String bestName = '';

    for (final bucket in buckets) {
      // Pick clean display name & brand from items in bucket.
      for (final it in bucket.items) {
        if (bestBrand.isEmpty && it.brand.isNotEmpty) {
          bestBrand = it.brand;
        }
        if (bestName.isEmpty ||
            (it.name.length >= 6 &&
                it.name.length < bestName.length &&
                !it.name.contains('|'))) {
          bestName = it.name;
        }
        for (final img in it.images) {
          if (!allImages.contains(img)) allImages.add(img);
        }
        if (it.rating != null && (bestRating == null || (it.ratingCount ?? 0) > (bestRatingCount ?? 0))) {
          bestRating = it.rating;
          bestRatingCount = it.ratingCount;
        }
      }

      final quotes = bucket.items.map((e) => e.quote).toList()
        ..sort((a, b) {
          if (a.isAvailable != b.isAvailable) return a.isAvailable ? -1 : 1;
          if (!a.isAvailable) return 0;
          return (a.price ?? 999999).compareTo(b.price ?? 999999);
        });

      variants.add(
        PackVariant(
          label: bucket.pack.label,
          quotes: quotes,
        ),
      );
    }

    // Add "Best value" badge on larger packs if cheaper per unit.
    if (variants.length > 1) {
      final firstCostPerBase = _costPerBase(variants.first, buckets.first.pack);
      if (firstCostPerBase != null && firstCostPerBase > 0) {
        for (var i = 1; i < variants.length; i++) {
          final cost = _costPerBase(variants[i], buckets[i].pack);
          if (cost != null && cost < firstCostPerBase * 0.94) {
            final pct = (((firstCostPerBase - cost) / firstCostPerBase) * 100).round();
            if (pct >= 4) {
              variants[i] = PackVariant(
                label: variants[i].label,
                quotes: variants[i].quotes,
                saveBadge: 'Save $pct%',
              );
            }
          }
        }
      }
    }

    if (bestName.isEmpty) return null;
    if (bestBrand.isNotEmpty &&
        bestName.toLowerCase().startsWith(bestBrand.toLowerCase())) {
      bestName = bestName;
    } else if (bestBrand.isNotEmpty) {
      bestName = '$bestBrand $bestName';
    }
    bestName = bestName.replaceAll(RegExp(r'\s+\|\s+Pouch', caseSensitive: false), '').trim();

    final cat = _inferCategoryAndArt(
      '$bestBrand $bestName $query',
      preferredCategoryId: preferredCategoryId,
      paletteSeed: paletteSeed,
    );
    final slug = '${cluster.brandRoot}_${cluster.tokens.toList()..sort()}'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final pinPart = (pincode != null && pincode.trim().isNotEmpty)
        ? '${pincode.trim()}_'
        : '';
    final id = 'qc_$pinPart${slug.replaceAll(RegExp(r'^_+|_+$'), '')}';

    final cheapest = variants.first.quotes.where((q) => q.isAvailable).toList();
    final hasDiscount = variants.any(
      (v) => v.quotes.any((q) => (q.discountPercent ?? 0) >= 8),
    );
    final availRetailers = cheapest.map((q) => q.retailer).toSet();
    final maxDiscount = variants
        .expand((v) => v.quotes)
        .map((q) => q.discountPercent ?? 0)
        .fold<int>(0, math.max);

    final subtitleParts = <String>[
      if (variants.length > 1)
        '${variants.length} pack sizes'
      else
        variants.first.label,
      if (availRetailers.isNotEmpty) 'on ${availRetailers.length} app${availRetailers.length > 1 ? 's' : ''}',
    ];

    return Product(
      id: id,
      name: bestName,
      brand: bestBrand.isEmpty ? 'Quick Commerce' : bestBrand,
      categoryId: cat.categoryId,
      categoryLabel: cat.categoryLabel,
      subtitle: subtitleParts.join(' · '),
      artKind: cat.artKind,
      pastel: cat.pastel,
      variants: variants,
      defaultVariantIndex: 0,
      historyByRange: const {},
      imageUrl: allImages.isNotEmpty ? allImages.first : null,
      imageUrls: allImages,
      rating: bestRating,
      ratingCount: bestRatingCount,
      trendTag: maxDiscount >= 10
          ? '$maxDiscount% off live'
          : (availRetailers.length >= 3 ? 'Widely available' : null),
      isTrending: availRetailers.length >= 2,
      isDeal: hasDiscount,
      isPriceDrop: maxDiscount >= 10,
      onlyOnRetailer: availRetailers.length == 1 ? availRetailers.first : null,
    );
  }

  static double? _costPerBase(PackVariant v, _NormalizedPack pack) {
    final base = pack.totalBaseValue;
    if (base == null || base <= 0) return null;
    final avail = v.quotes.where((q) => q.isAvailable).toList();
    if (avail.isEmpty) return null;
    final minPrice = avail.map((q) => q.price!).reduce(math.min);
    return minPrice / base;
  }

  static ({
    String categoryId,
    String categoryLabel,
    ProductArtKind artKind,
    SastaPastel pastel,
  }) _inferCategoryAndArt(
    String text, {
    String? preferredCategoryId,
    required int paletteSeed,
  }) {
    final t = text.toLowerCase();
    const pastels = SastaPastel.values;
    final pastel = pastels[paletteSeed % pastels.length];

    if (t.contains('curd') || t.contains('dahi') || t.contains('yogurt')) {
      return (
        categoryId: 'dairy',
        categoryLabel: 'Dairy & Breakfast',
        artKind: ProductArtKind.curd,
        pastel: SastaPastel.sky,
      );
    }
    if (t.contains('butter') || t.contains('ghee')) {
      return (
        categoryId: t.contains('ghee') ? 'cooking' : 'dairy',
        categoryLabel:
            t.contains('ghee') ? 'Cooking Essentials' : 'Dairy & Breakfast',
        artKind: ProductArtKind.butter,
        pastel: SastaPastel.butter,
      );
    }
    if (t.contains('milk') || t.contains('paneer') || t.contains('cheese')) {
      return (
        categoryId: 'dairy',
        categoryLabel: 'Dairy & Breakfast',
        artKind: ProductArtKind.milk,
        pastel: SastaPastel.sky,
      );
    }
    if (t.contains('egg')) {
      return (
        categoryId: 'dairy',
        categoryLabel: 'Dairy & Breakfast',
        artKind: ProductArtKind.eggs,
        pastel: SastaPastel.peach,
      );
    }
    if (t.contains('bread') || t.contains('bun') || t.contains('pav')) {
      return (
        categoryId: 'bakery',
        categoryLabel: 'Bakery & Desserts',
        artKind: ProductArtKind.bread,
        pastel: SastaPastel.peach,
      );
    }
    if (t.contains('rice') || t.contains('basmati') || t.contains('dal')) {
      return (
        categoryId: 'staples',
        categoryLabel: 'Staples & Grains',
        artKind: ProductArtKind.rice,
        pastel: SastaPastel.butter,
      );
    }
    if (t.contains('atta') || t.contains('flour')) {
      return (
        categoryId: 'staples',
        categoryLabel: 'Staples & Grains',
        artKind: ProductArtKind.atta,
        pastel: SastaPastel.peach,
      );
    }
    if (t.contains('oil')) {
      return (
        categoryId: 'cooking',
        categoryLabel: 'Cooking Essentials',
        artKind: ProductArtKind.oil,
        pastel: SastaPastel.butter,
      );
    }
    if (t.contains('salt') || t.contains('sugar')) {
      return (
        categoryId: 'staples',
        categoryLabel: 'Staples & Grains',
        artKind: ProductArtKind.salt,
        pastel: SastaPastel.sky,
      );
    }
    if (t.contains('tea') || t.contains('chai')) {
      return (
        categoryId: 'beverages',
        categoryLabel: 'Beverages',
        artKind: ProductArtKind.tea,
        pastel: SastaPastel.mint,
      );
    }
    if (t.contains('coffee')) {
      return (
        categoryId: 'beverages',
        categoryLabel: 'Beverages',
        artKind: ProductArtKind.coffee,
        pastel: SastaPastel.lavender,
      );
    }
    if (t.contains('noodle') || t.contains('maggi') || t.contains('pasta')) {
      return (
        categoryId: 'snacks',
        categoryLabel: 'Snacks',
        artKind: ProductArtKind.noodles,
        pastel: SastaPastel.butter,
      );
    }
    if (t.contains('biscuit') || t.contains('cookie')) {
      return (
        categoryId: 'snacks',
        categoryLabel: 'Snacks',
        artKind: ProductArtKind.biscuits,
        pastel: SastaPastel.peach,
      );
    }
    if (t.contains('detergent') || t.contains('surf') || t.contains('wash')) {
      return (
        categoryId: 'household',
        categoryLabel: 'Household',
        artKind: ProductArtKind.detergent,
        pastel: SastaPastel.sky,
      );
    }
    if (t.contains('tomato') ||
        t.contains('onion') ||
        t.contains('potato') ||
        t.contains('fruit') ||
        t.contains('veg')) {
      return (
        categoryId: 'fruits_veg',
        categoryLabel: 'Fruits & Veg',
        artKind: ProductArtKind.veg,
        pastel: SastaPastel.mint,
      );
    }
    if (t.contains('ice cream') || t.contains('kulfi') || t.contains('cone')) {
      return (
        categoryId: 'frozen',
        categoryLabel: 'Frozen & Instant',
        artKind: ProductArtKind.iceCream,
        pastel: SastaPastel.pink,
      );
    }
    if (t.contains('diaper') || t.contains('baby')) {
      return (
        categoryId: 'baby_care',
        categoryLabel: 'Baby Care',
        artKind: ProductArtKind.babyCare,
        pastel: SastaPastel.mint,
      );
    }
    if (t.contains('chicken') || t.contains('fish') || t.contains('meat')) {
      return (
        categoryId: 'meat',
        categoryLabel: 'Meat & Seafood',
        artKind: ProductArtKind.meat,
        pastel: SastaPastel.pink,
      );
    }
    if (t.contains('juice') || t.contains('drink') || t.contains('cola')) {
      return (
        categoryId: 'beverages',
        categoryLabel: 'Beverages',
        artKind: ProductArtKind.beverage,
        pastel: SastaPastel.lavender,
      );
    }

    final catId = preferredCategoryId ?? 'snacks';
    final catLabel = switch (catId) {
      'dairy' => 'Dairy & Breakfast',
      'fruits_veg' => 'Fruits & Veg',
      'beverages' => 'Beverages',
      'staples' => 'Staples & Grains',
      'cooking' => 'Cooking Essentials',
      'personal_care' => 'Personal Care',
      'household' => 'Household',
      'baby_care' => 'Baby Care',
      'frozen' => 'Frozen & Instant',
      'bakery' => 'Bakery & Desserts',
      'meat' => 'Meat & Seafood',
      _ => 'Snacks',
    };
    return (
      categoryId: catId,
      categoryLabel: catLabel,
      artKind: ProductArtKind.snacks,
      pastel: pastel,
    );
  }
}
