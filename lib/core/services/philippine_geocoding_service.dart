/// philippine_geocoding_service.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Free Philippine-first geocoding via OpenStreetMap Nominatim.
///
/// All queries are constrained to the Philippine bounding box and country code
/// to prioritise barangays, municipalities, cities, provinces, and local
/// landmarks over international results.
///
/// Design:
/// • Forward search with debounce-safe cancel tokens.
/// • Reverse geocode for map-pin-picker.
/// • In-memory LRU cache (32 entries) to avoid redundant HTTP round-trips.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'dart:async';
import 'dart:collection';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Represents a single geocoding result with parsed Philippine address parts.
class GeocodingResult {
  final String displayName;
  final String? mainText;
  final String? secondaryText;
  final double lat;
  final double lon;
  final String? barangay;
  final String? municipality;
  final String? province;

  const GeocodingResult({
    required this.displayName,
    this.mainText,
    this.secondaryText,
    required this.lat,
    required this.lon,
    this.barangay,
    this.municipality,
    this.province,
  });
}

class PhilippineGeocodingService {
  // ── Singleton ────────────────────────────────────────────────────────────
  static final PhilippineGeocodingService instance =
      PhilippineGeocodingService._();
  PhilippineGeocodingService._();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 6),
    receiveTimeout: const Duration(seconds: 6),
    headers: {'User-Agent': 'TaraTravelApp/1.0 (contact@taratravel.ph)'},
  ));

  // Philippine bounding box: SW (4.5872, 116.9298) → NE (21.1221, 126.6053)
  static const String _viewbox = '116.9298,4.5872,126.6053,21.1221';
  static const String _countryCode = 'ph';

  // ── LRU Cache (32 entries) ──────────────────────────────────────────────
  final LinkedHashMap<String, List<GeocodingResult>> _cache =
      LinkedHashMap<String, List<GeocodingResult>>();
  static const int _maxCacheSize = 32;

  void _cacheSet(String key, List<GeocodingResult> value) {
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  // ── Forward Search ─────────────────────────────────────────────────────

  /// Searches for places matching [query] within the Philippines.
  /// Returns up to [limit] results. Pass a [cancelToken] for debounce safety.
  Future<List<GeocodingResult>> search(
    String query, {
    int limit = 6,
    CancelToken? cancelToken,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final cacheKey = 'search:${trimmed.toLowerCase()}:$limit';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': trimmed,
          'format': 'json',
          'limit': limit,
          'addressdetails': 1,
          'countrycodes': _countryCode,
          'viewbox': _viewbox,
          'bounded': 1,
        },
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200 && response.data is List) {
        final results = (response.data as List)
            .map(_parseNominatimResult)
            .toList();
        _cacheSet(cacheKey, results);
        return results;
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return const [];
      debugPrint('[PhilippineGeocoding] search error: $e');
    }
    return const [];
  }

  // ── Reverse Geocode ────────────────────────────────────────────────────

  /// Converts a lat/lng coordinate to a human-readable Philippine address.
  Future<GeocodingResult?> reverseGeocode(
    double lat,
    double lon, {
    CancelToken? cancelToken,
  }) async {
    final cacheKey = 'rev:${lat.toStringAsFixed(5)}:${lon.toStringAsFixed(5)}';
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isNotEmpty) {
      return _cache[cacheKey]!.first;
    }

    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'format': 'json',
          'addressdetails': 1,
          'zoom': 18,
        },
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200 && response.data is Map) {
        final result = _parseNominatimResult(response.data);
        _cacheSet(cacheKey, [result]);
        return result;
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return null;
      debugPrint('[PhilippineGeocoding] reverse error: $e');
    }
    return null;
  }

  // ── Parser ──────────────────────────────────────────────────────────────

  GeocodingResult _parseNominatimResult(dynamic json) {
    final displayName = json['display_name'] as String? ?? '';
    final address = json['address'] as Map<String, dynamic>?;

    final parts = displayName.split(',');
    final mainText = parts.isNotEmpty ? parts.first.trim() : displayName;
    final secondaryText =
        parts.length > 1 ? parts.sublist(1).join(',').trim() : '';

    double parsedLat = 0.0;
    double parsedLon = 0.0;
    if (json['lat'] != null) {
      parsedLat = double.tryParse(json['lat'].toString()) ?? 0.0;
    }
    if (json['lon'] != null) {
      parsedLon = double.tryParse(json['lon'].toString()) ?? 0.0;
    }

    return GeocodingResult(
      displayName: displayName,
      mainText: mainText,
      secondaryText: secondaryText.isEmpty ? null : secondaryText,
      lat: parsedLat,
      lon: parsedLon,
      barangay: address?['suburb'] as String? ??
          address?['neighbourhood'] as String?,
      municipality: address?['city'] as String? ??
          address?['town'] as String? ??
          address?['municipality'] as String?,
      province: address?['state'] as String? ??
          address?['county'] as String?,
    );
  }
}
