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
  });

  final String pincode;
  final String area;
  final String? city;
  final String? state;
  final String source;

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

  static final RegExp _sixDigitRegex = RegExp(r'^\d{6}$');
  final Map<String, ResolvedPincode> _pincodeCache = {};

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
