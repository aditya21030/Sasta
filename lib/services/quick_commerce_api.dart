import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

/// Build-time & runtime configuration for the Sasta Quick-Commerce REST backend.
class QuickCommerceApiConfig {
  const QuickCommerceApiConfig({
    this.baseUrl = envBaseUrl,
    this.apiKey = envApiKey,
  });

  static const String envBaseUrl =
      String.fromEnvironment('SASTA_API_BASE_URL', defaultValue: '');
  static const String envApiKey =
      String.fromEnvironment('SASTA_API_KEY', defaultValue: '');

  final String baseUrl;
  final String apiKey;

  bool get isConfigured => baseUrl.trim().isNotEmpty;

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

class CatalogSyncResponse {
  const CatalogSyncResponse({
    required this.products,
    required this.pincode,
    required this.syncedAt,
    this.area,
    this.serviceableRetailers = const [],
  });

  final List<Product> products;
  final String pincode;
  final DateTime syncedAt;
  final String? area;
  final List<RetailerId> serviceableRetailers;
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

  Future<CatalogSyncResponse> fetchHomeCatalog({
    required String pincode,
    double? lat,
    double? lng,
  });

  Future<List<Product>> searchProducts({
    required String query,
    required String pincode,
    String? categoryId,
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
  });
}

/// Production HTTP client talking to your Sasta quick-commerce pricing backend.
///
/// Expected REST endpoints under `SASTA_API_BASE_URL`:
/// - `GET /v1/catalog/home?pincode=<pin>` -> `{ products: [...], area?: string, serviceableRetailers?: [...] }`
/// - `GET /v1/catalog/search?q=<query>&pincode=<pin>&categoryId=<id>` -> `{ products: [...] }`
/// - `GET /v1/catalog/products/<id>?pincode=<pin>` -> `{ product: {...} }`
/// - `GET /v1/catalog/products/<id>/history?pincode=<pin>` -> `{ historyByRange: { "7D": ..., "30D": ..., "90D": ... } }`
/// - `GET /v1/serviceability?pincode=<pin>` -> `{ serviceable: bool, area?: string, retailers?: [...], etas?: {...} }`
class HttpQuickCommerceRepository implements QuickCommerceRepository {
  HttpQuickCommerceRepository({
    required QuickCommerceApiConfig config,
    http.Client? client,
    this.timeout = const Duration(seconds: 12),
  })  : _config = config,
        _client = client ?? http.Client(),
        _ownsClient = client == null;

  final QuickCommerceApiConfig _config;
  final http.Client _client;
  final bool _ownsClient;
  final Duration timeout;

  @override
  QuickCommerceApiConfig get config => _config;

  @override
  bool get isConfigured => _config.baseUri != null;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (_config.apiKey.trim().isNotEmpty) ...{
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

  Future<dynamic> _getJson(String path, [Map<String, String>? queryParams]) async {
    final uri = _endpoint(path, queryParams);
    try {
      final response =
          await _client.get(uri, headers: _headers).timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw QuickCommerceApiException(
          'API request failed for $path',
          statusCode: response.statusCode,
        );
      }
      if (response.bodyBytes.isEmpty) return const <String, dynamic>{};
      return jsonDecode(utf8.decode(response.bodyBytes));
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

  @override
  Future<CatalogSyncResponse> fetchHomeCatalog({
    required String pincode,
    double? lat,
    double? lng,
  }) async {
    final params = <String, String>{
      'pincode': pincode,
      if (lat != null) 'lat': lat.toStringAsFixed(6),
      if (lng != null) 'lng': lng.toStringAsFixed(6),
    };
    final decoded = await _getJson('/v1/catalog/home', params);
    final products = _parseProducts(decoded);
    final map = decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    final retailersRaw = map?['serviceableRetailers'] ??
        map?['serviceable_retailers'] ??
        map?['retailers'];

    return CatalogSyncResponse(
      products: products,
      pincode: map?['pincode']?.toString() ?? pincode,
      area: map?['area']?.toString(),
      serviceableRetailers: _parseRetailers(retailersRaw),
      syncedAt: DateTime.now(),
    );
  }

  @override
  Future<List<Product>> searchProducts({
    required String query,
    required String pincode,
    String? categoryId,
  }) async {
    final params = <String, String>{
      'q': query,
      'pincode': pincode,
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
    };
    final decoded = await _getJson('/v1/catalog/search', params);
    return _parseProducts(decoded);
  }

  @override
  Future<Product?> fetchProductDetails({
    required String productId,
    required String pincode,
  }) async {
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
  }) async {
    final decoded =
        await _getJson('/v1/serviceability', {'pincode': pincode});
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
    return ServiceabilityResponse(
      pincode: map['pincode']?.toString() ?? pincode,
      serviceable: map['serviceable'] == true || map['is_serviceable'] == true,
      area: map['area']?.toString(),
      retailers: _parseRetailers(map['retailers']),
      etasByRetailer: etas,
    );
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
