import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/itinerary_model.dart';
import 'philippine_geocoding_service.dart';

/// Structured result returned when resolving a Google Maps link or coordinates.
class GoogleMapsLocationResult {
  final String title;
  final String fullAddress;
  final double latitude;
  final double longitude;
  final String? originalUrl;
  final StopType suggestedType;

  const GoogleMapsLocationResult({
    required this.title,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    this.originalUrl,
    this.suggestedType = StopType.activity,
  });
}

class GoogleMapsParserService {
  static final GoogleMapsParserService instance = GoogleMapsParserService._();
  GoogleMapsParserService._();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    followRedirects: true,
    maxRedirects: 6,
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    },
  ));

  // Regex patterns
  static final RegExp _coordRegex = RegExp(
    r'(-?\d{1,2}\.\d{4,10})[,\s]+(-?\d{1,3}\.\d{4,10})',
  );

  static final RegExp _gmapUrlRegex = RegExp(
    r'(https?:\/\/(?:maps\.app\.goo\.gl|goo\.gl\/maps|(?:www\.)?google\.[a-z.]+\/maps)[^\s]*)',
    caseSensitive: false,
  );

  static final RegExp _urlCoordRegex = RegExp(
    r'@(-?\d{1,2}\.\d{4,10}),(-?\d{1,3}\.\d{4,10})',
  );

  static final RegExp _queryCoordRegex = RegExp(
    r'[?&](?:q|query|ll|center)=(-?\d{1,2}\.\d{4,10}),(-?\d{1,3}\.\d{4,10})',
  );

  static final RegExp _placeNameRegex = RegExp(
    r'/maps/place/([^/@]+)',
    caseSensitive: false,
  );

  /// Checks if input string contains a Google Maps URL or raw coordinates.
  bool isGoogleMapsOrCoordinates(String input) {
    final trimmed = input.trim();
    if (_gmapUrlRegex.hasMatch(trimmed)) return true;
    if (_coordRegex.hasMatch(trimmed)) return true;
    return false;
  }

  /// Extracts the Google Maps URL if present.
  String? extractUrl(String input) {
    final match = _gmapUrlRegex.firstMatch(input);
    return match?.group(1);
  }

  /// Resolves an input string (Google Maps URL or coordinates) to a [GoogleMapsLocationResult].
  Future<GoogleMapsLocationResult?> parse(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // 1. Check if raw coordinates: "14.5995, 120.9842"
    final coordMatch = _coordRegex.firstMatch(trimmed);
    final urlMatch = _gmapUrlRegex.firstMatch(trimmed);

    if (urlMatch == null && coordMatch != null) {
      final lat = double.tryParse(coordMatch.group(1) ?? '');
      final lng = double.tryParse(coordMatch.group(2) ?? '');
      if (lat != null && lng != null) {
        return await _resolveFromCoords(lat, lng, originalUrl: null, rawQueryName: null);
      }
    }

    if (urlMatch == null) return null;
    final originalUrl = urlMatch.group(1)!;

    try {
      String resolvedUrl = originalUrl;

      // If shortened (maps.app.goo.gl or goo.gl/maps), resolve redirects
      if (originalUrl.contains('maps.app.goo.gl') || originalUrl.contains('goo.gl/maps')) {
        try {
          final response = await _dio.get(
            originalUrl,
            options: Options(
              validateStatus: (status) => status != null && status < 400,
            ),
          );
          resolvedUrl = response.realUri.toString();
        } catch (e) {
          debugPrint('[GoogleMapsParser] Redirect resolve error: $e');
        }
      }

      // 2. Try to extract lat/long from resolved URL
      double? lat;
      double? lng;
      String? extractedName;

      final urlCoordMatch = _urlCoordRegex.firstMatch(resolvedUrl);
      if (urlCoordMatch != null) {
        lat = double.tryParse(urlCoordMatch.group(1) ?? '');
        lng = double.tryParse(urlCoordMatch.group(2) ?? '');
      } else {
        final qMatch = _queryCoordRegex.firstMatch(resolvedUrl);
        if (qMatch != null) {
          lat = double.tryParse(qMatch.group(1) ?? '');
          lng = double.tryParse(qMatch.group(2) ?? '');
        }
      }

      // Try to extract place name from path: /maps/place/Some+Place+Name/
      final placeMatch = _placeNameRegex.firstMatch(resolvedUrl);
      if (placeMatch != null) {
        extractedName = Uri.decodeComponent(placeMatch.group(1)!.replaceAll('+', ' ')).trim();
      }

      // If we have coordinates, reverse geocode to get a clean address & place name
      if (lat != null && lng != null) {
        return await _resolveFromCoords(
          lat,
          lng,
          originalUrl: originalUrl,
          rawQueryName: extractedName,
        );
      }

      // If coordinates couldn't be extracted directly, but we extracted a place name:
      if (extractedName != null && extractedName.isNotEmpty) {
        final searchResults = await PhilippineGeocodingService.instance.search(extractedName, limit: 1);
        if (searchResults.isNotEmpty) {
          final top = searchResults.first;
          final suggestedType = inferStopType(extractedName);
          return GoogleMapsLocationResult(
            title: extractedName,
            fullAddress: top.displayName,
            latitude: top.lat,
            longitude: top.lon,
            originalUrl: originalUrl,
            suggestedType: suggestedType,
          );
        }
      }
    } catch (e) {
      debugPrint('[GoogleMapsParser] Parse error: $e');
    }

    return null;
  }

  Future<GoogleMapsLocationResult> _resolveFromCoords(
    double lat,
    double lng, {
    required String? originalUrl,
    required String? rawQueryName,
  }) async {
    GeocodingResult? geo;
    try {
      geo = await PhilippineGeocodingService.instance.reverseGeocode(lat, lng);
    } catch (e) {
      debugPrint('[GoogleMapsParser] Reverse geocode error: $e');
    }

    String title;
    String fullAddress;

    if (rawQueryName != null && rawQueryName.isNotEmpty) {
      title = rawQueryName;
      fullAddress = geo?.displayName ?? '$lat, $lng';
    } else if (geo != null) {
      title = geo.mainText ?? geo.displayName.split(',').first.trim();
      fullAddress = geo.displayName;
    } else {
      title = '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      fullAddress = 'Pinned Coordinates';
    }

    final suggestedType = inferStopType('$title $fullAddress');

    return GoogleMapsLocationResult(
      title: title,
      fullAddress: fullAddress,
      latitude: lat,
      longitude: lng,
      originalUrl: originalUrl,
      suggestedType: suggestedType,
    );
  }

  /// Smart keyword inference for StopType based on place name and address.
  StopType inferStopType(String text) {
    final lower = text.toLowerCase();

    // Hotel / Accommodation
    if (lower.contains('hotel') ||
        lower.contains('resort') ||
        lower.contains('inn') ||
        lower.contains('hostel') ||
        lower.contains('suites') ||
        lower.contains('villas') ||
        lower.contains('homestay') ||
        lower.contains('lodge') ||
        lower.contains('transient') ||
        lower.contains('airbnb')) {
      return StopType.hotel;
    }

    // Food / Dining
    if (lower.contains('restaurant') ||
        lower.contains('cafe') ||
        lower.contains('coffee') ||
        lower.contains('grill') ||
        lower.contains('bistro') ||
        lower.contains('diner') ||
        lower.contains('bar') ||
        lower.contains('jollibee') ||
        lower.contains('mcdonald') ||
        lower.contains('mang inasal') ||
        lower.contains('bakery') ||
        lower.contains('kitchen') ||
        lower.contains('eatery')) {
      return StopType.food;
    }

    // Transport
    if (lower.contains('airport') ||
        lower.contains('terminal') ||
        lower.contains('station') ||
        lower.contains('pier') ||
        lower.contains('port') ||
        lower.contains('bus stop') ||
        lower.contains('wharf') ||
        lower.contains('ferry')) {
      return StopType.transport;
    }

    // Default to activity
    return StopType.activity;
  }
}
