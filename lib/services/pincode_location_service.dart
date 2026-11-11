import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Geographic and postal details resolved for a 6-digit Indian pincode or GPS fix.
class ResolvedPincode {
  const ResolvedPincode({
    required this.pincode,
    required this.area,
    this.city,
    this.state,
    this.source = 'manual',
    this.lat,
    this.lng,
  });

  final String pincode;
  final String area;
  final String? city;
  final String? state;
  final String source;
  final double? lat;
  final double? lng;

  ResolvedPincode copyWith({
    String? area,
    String? city,
    String? state,
    String? source,
    double? lat,
    double? lng,
  }) {
    return ResolvedPincode(
      pincode: pincode,
      area: area ?? this.area,
      city: city ?? this.city,
      state: state ?? this.state,
      source: source ?? this.source,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  String get displayArea => area.trim().isNotEmpty
      ? area.trim()
      : (city?.trim().isNotEmpty == true ? city!.trim() : 'India');
}

/// Outcome of a live GPS location detection request.
class LocationDetectResult {
  const LocationDetectResult({
    this.resolved,
    this.errorMessage,
    this.permissionDeniedForever = false,
  });

  final ResolvedPincode? resolved;
  final String? errorMessage;
  final bool permissionDeniedForever;

  bool get isSuccess => resolved != null && errorMessage == null;
}

typedef PositionProvider = Future<({double lat, double lng})> Function();
typedef ReverseGeocoderProvider = Future<ResolvedPincode?> Function(
  double lat,
  double lng,
);

/// Resolves Indian pincodes via India Post API and detects current location via GPS.
class PincodeLocationService {
  PincodeLocationService({
    http.Client? client,
    PositionProvider? positionProvider,
    ReverseGeocoderProvider? reverseGeocoderProvider,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _positionProvider = positionProvider,
        _reverseGeocoderProvider = reverseGeocoderProvider;

  final http.Client _client;
  final bool _ownsClient;
  final PositionProvider? _positionProvider;
  final ReverseGeocoderProvider? _reverseGeocoderProvider;

  // Indian PIN codes are 6 digits starting with 1-9 (zone 1-8 or 9 APS).
  static final RegExp _sixDigitRegex = RegExp(r'^[1-9]\d{5}$');
  final Map<String, ResolvedPincode> _pincodeCache = {};
  final Map<String, ({double lat, double lng})> _coordsCache = {};

  static const Map<String, ({double lat, double lng})> _knownPincodeCoords = {
    '110001': (lat: 28.6304, lng: 77.2177), // Central Delhi
    '560001': (lat: 12.9716, lng: 77.5946), // Bengaluru CBD
    '560034': (lat: 12.9352, lng: 77.6245), // Koramangala
    '560038': (lat: 12.9784, lng: 77.6408), // Indiranagar
    '560102': (lat: 12.9116, lng: 77.6389), // HSR Layout
    '400001': (lat: 18.9388, lng: 72.8354), // South Mumbai
    '500001': (lat: 17.3850, lng: 78.4867), // Hyderabad
    '600001': (lat: 13.0827, lng: 80.2707), // Chennai
    '411001': (lat: 18.5204, lng: 73.8567), // Pune
    '700001': (lat: 22.5726, lng: 88.3639), // Kolkata
    '122001': (lat: 28.4595, lng: 77.0266), // Gurugram
    '201301': (lat: 28.5706, lng: 77.3272), // Noida
    '380001': (lat: 23.0225, lng: 72.5714), // Ahmedabad
  };

  static const Map<String, ({double lat, double lng})> _prefixCentroids = {
    '110': (lat: 28.6139, lng: 77.2090), // Delhi
    '122': (lat: 28.4595, lng: 77.0266), // Gurugram
    '201': (lat: 28.5355, lng: 77.3910), // Noida / Ghaziabad
    '302': (lat: 26.9124, lng: 75.7873), // Jaipur
    '380': (lat: 23.0225, lng: 72.5714), // Ahmedabad
    '400': (lat: 19.0760, lng: 72.8777), // Mumbai
    '411': (lat: 18.5204, lng: 73.8567), // Pune
    '500': (lat: 17.3850, lng: 78.4867), // Hyderabad
    '560': (lat: 12.9716, lng: 77.5946), // Bengaluru
    '600': (lat: 13.0827, lng: 80.2707), // Chennai
    '682': (lat: 9.9312, lng: 76.2673), // Kochi
    '700': (lat: 22.5726, lng: 88.3639), // Kolkata
  };

  static bool isValidPincode(String input) =>
      _sixDigitRegex.hasMatch(input.trim());

  /// Looks up a 6-digit Indian pincode using `https://api.postalpincode.in/pincode/<pin>`.
  Future<ResolvedPincode?> lookupPincode(String rawPincode) async {
    final pin = rawPincode.trim();
    if (!isValidPincode(pin)) return null;
    final cached = _pincodeCache[pin];
    if (cached != null) return cached;

    try {
      final uri = Uri.https('api.postalpincode.in', '/pincode/$pin');
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List || decoded.isEmpty) return null;
      final first = decoded.first;
      if (first is! Map) return null;
      if (first['Status']?.toString().toLowerCase() != 'success') return null;

      final offices = first['PostOffice'];
      if (offices is! List || offices.isEmpty) return null;
      final po = Map<String, dynamic>.from(offices.first as Map);

      final locality = _pickDistinctPart([
        po['Block']?.toString(),
        po['Name']?.toString(),
      ]);
      final district = po['District']?.toString().trim();
      final state = po['State']?.toString().trim();

      final parts = <String>[];
      if (locality != null && locality.isNotEmpty && locality != 'NA') {
        parts.add(locality);
      }
      if (district != null &&
          district.isNotEmpty &&
          district.toLowerCase() != locality?.toLowerCase()) {
        parts.add(district);
      }
      final area = parts.isNotEmpty ? parts.join(', ') : (state ?? 'India');

      final resolved = ResolvedPincode(
        pincode: pin,
        area: area,
        city: district,
        state: state,
        source: 'india_post',
      );
      _pincodeCache[pin] = resolved;
      return resolved;
    } catch (_) {
      return null;
    }
  }

  /// Requests location permission if needed, fetches GPS coordinates, and resolves pincode + area.
  Future<LocationDetectResult> detectCurrentLocation() async {
    try {
      late final ({double lat, double lng}) coords;
      if (_positionProvider != null) {
        coords = await _positionProvider();
      } else {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          return const LocationDetectResult(
            errorMessage:
                'Location services are turned off. Enable GPS or enter pincode manually.',
          );
        }

        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied) {
          return const LocationDetectResult(
            errorMessage: 'Location permission was denied.',
          );
        }
        if (permission == LocationPermission.deniedForever) {
          return const LocationDetectResult(
            errorMessage:
                'Location permission is permanently denied in device settings.',
            permissionDeniedForever: true,
          );
        }

        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
        coords = (lat: position.latitude, lng: position.longitude);
      }

      ResolvedPincode? resolved;
      if (_reverseGeocoderProvider != null) {
        resolved = await _reverseGeocoderProvider(coords.lat, coords.lng);
      } else {
        resolved = await _reverseGeocodeNative(coords.lat, coords.lng);
        resolved ??= await _reverseGeocodeNominatim(coords.lat, coords.lng);
      }

      if (resolved == null || !isValidPincode(resolved.pincode)) {
        return const LocationDetectResult(
          errorMessage:
              'Could not determine a 6-digit Indian pincode at this location.',
        );
      }

      // Enrich sparse locality strings using India Post when needed.
      if (resolved.area.isEmpty || resolved.area == 'India') {
        final enriched = await lookupPincode(resolved.pincode);
        if (enriched != null) {
          resolved = enriched;
        }
      }

      resolved = resolved.copyWith(lat: coords.lat, lng: coords.lng);
      _coordsCache[resolved.pincode] = coords;
      return LocationDetectResult(resolved: resolved);
    } on MissingPluginException {
      return const LocationDetectResult(
        errorMessage: 'GPS detection is not available on this platform.',
      );
    } on TimeoutException {
      return const LocationDetectResult(
        errorMessage: 'GPS fix timed out. Please try again or enter pincode.',
      );
    } catch (e) {
      return LocationDetectResult(
        errorMessage: 'Location lookup failed: $e',
      );
    }
  }

  Future<ResolvedPincode?> _reverseGeocodeNative(
      double lat, double lng) async {
    try {
      final placemarks = await geocoding.Geocoding()
          .placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 6));
      if (placemarks.isEmpty) return null;
      final place = placemarks.first;
      final rawPin = (place.postalCode ?? '').replaceAll(RegExp(r'\D'), '');
      if (!isValidPincode(rawPin)) return null;

      final locality = _pickDistinctPart([
        place.subLocality,
        place.locality,
        place.subAdministrativeArea,
      ]);
      final city = place.locality ?? place.subAdministrativeArea;
      final parts = <String>[];
      if (locality != null && locality.isNotEmpty) parts.add(locality);
      if (city != null &&
          city.isNotEmpty &&
          city.toLowerCase() != locality?.toLowerCase()) {
        parts.add(city);
      }

      return ResolvedPincode(
        pincode: rawPin,
        area: parts.isNotEmpty
            ? parts.join(', ')
            : (place.administrativeArea ?? 'India'),
        city: city,
        state: place.administrativeArea,
        source: 'gps_native',
      );
    } catch (_) {
      return null;
    }
  }

  Future<ResolvedPincode?> _reverseGeocodeNominatim(
      double lat, double lng) async {
    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/reverse',
        {
          'format': 'jsonv2',
          'lat': lat.toStringAsFixed(6),
          'lon': lng.toStringAsFixed(6),
          'addressdetails': '1',
        },
      );
      final response = await _client.get(
        uri,
        headers: const {'User-Agent': 'SastaQuickCommerceApp/1.0'},
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) return null;
      final address = decoded['address'];
      if (address is! Map) return null;

      final rawPin =
          (address['postcode']?.toString() ?? '').replaceAll(RegExp(r'\D'), '');
      if (!isValidPincode(rawPin)) return null;

      final areaPart = _pickDistinctPart([
        address['suburb']?.toString(),
        address['neighbourhood']?.toString(),
        address['city_district']?.toString(),
        address['town']?.toString(),
      ]);
      final city = _pickDistinctPart([
        address['city']?.toString(),
        address['state_district']?.toString(),
      ]);
      final parts = <String>[];
      if (areaPart != null && areaPart.isNotEmpty) parts.add(areaPart);
      if (city != null &&
          city.isNotEmpty &&
          city.toLowerCase() != areaPart?.toLowerCase()) {
        parts.add(city);
      }

      return ResolvedPincode(
        pincode: rawPin,
        area: parts.isNotEmpty
            ? parts.join(', ')
            : (address['state']?.toString() ?? 'India'),
        city: city,
        state: address['state']?.toString(),
        source: 'nominatim',
      );
    } catch (_) {
      return null;
    }
  }

  /// Resolves approximate lat/lng coordinates for a 6-digit Indian pincode
  /// (exact lookup -> native geocoder -> Nominatim -> 3-digit PIN city centroid).
  Future<({double lat, double lng})> resolveCoordinatesForPincode(
    String rawPincode,
  ) async {
    final pin = rawPincode.trim();
    if (!isValidPincode(pin)) {
      return (lat: 12.9716, lng: 77.5946);
    }
    final cached = _coordsCache[pin] ?? _knownPincodeCoords[pin];
    if (cached != null) return cached;

    try {
      final locations = await geocoding.Geocoding()
          .locationFromAddress('$pin, India')
          .timeout(const Duration(seconds: 5));
      if (locations.isNotEmpty) {
        final coords =
            (lat: locations.first.latitude, lng: locations.first.longitude);
        _coordsCache[pin] = coords;
        return coords;
      }
    } catch (_) {
      // Fall through to Nominatim / prefix centroids cleanly.
    }

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'postalcode': pin,
        'countrycodes': 'in',
        'format': 'jsonv2',
        'limit': '1',
      });
      final response = await _client.get(
        uri,
        headers: const {'User-Agent': 'SastaQuickCommerceApp/1.0'},
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
          final row = decoded.first as Map;
          final lat = double.tryParse(row['lat']?.toString() ?? '');
          final lng = double.tryParse(row['lon']?.toString() ?? '');
          if (lat != null && lng != null) {
            final coords = (lat: lat, lng: lng);
            _coordsCache[pin] = coords;
            return coords;
          }
        }
      }
    } catch (_) {
      // Fall back to city prefix centroid below.
    }

    final prefix = pin.substring(0, 3);
    return _prefixCentroids[prefix] ?? (lat: 28.6139, lng: 77.2090);
  }

  /// Synchronous lookup from built-in major hub coordinates & city centroids.
  static ({double lat, double lng})? fallbackCoordinatesSync(
    String rawPincode,
  ) {
    final pin = rawPincode.trim();
    if (!_sixDigitRegex.hasMatch(pin)) return null;
    return _knownPincodeCoords[pin] ?? _prefixCentroids[pin.substring(0, 3)];
  }

  String? _pickDistinctPart(List<String?> candidates) {
    for (final raw in candidates) {
      final trimmed = raw?.trim();
      if (trimmed != null && trimmed.isNotEmpty && trimmed != 'NA') {
        return trimmed;
      }
    }
    return null;
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
