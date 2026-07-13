import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_provider.dart';

class ExploreDestination {
  final String id;
  final String name;
  final String country;
  final String distanceFromMetro;
  final String bestMode;
  final String avgCostRange;
  final String photoEmoji;
  final String imageUrl;
  final String tag;
  final String description;
  final bool isTrending;
  final bool isWeekendGetaway;
  final bool isRecommended;
  final String? recommendedReason;
  final String bestTimeToVisit;

  const ExploreDestination({
    required this.id,
    required this.name,
    required this.country,
    required this.distanceFromMetro,
    required this.bestMode,
    required this.avgCostRange,
    required this.photoEmoji,
    required this.imageUrl,
    required this.tag,
    required this.description,
    this.isTrending = false,
    this.isWeekendGetaway = false,
    this.isRecommended = false,
    this.recommendedReason,
    required this.bestTimeToVisit,
  });
}

final exploreProvider = FutureProvider<List<ExploreDestination>>((ref) async {
  final profile = ref.watch(profileProvider);
  final homeCity = profile.homeCity.trim();
  final homeCountry = profile.homeCountry.trim();
  final hasHomeLocation = homeCity.isNotEmpty && homeCity.toLowerCase() != 'not set';

  if (!hasHomeLocation) {
    return _fallbackDestinations;
  }

  final service = _ExploreInternetService();
  try {
    return await service.fetchNearbyDestinations(homeCity: homeCity, homeCountry: homeCountry);
  } catch (_) {
    return _fallbackDestinations;
  }
});

class _ExploreInternetService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: const {
        'User-Agent': 'TaraTravel/1.0 (explore module)',
      },
    ),
  );

  Future<List<ExploreDestination>> fetchNearbyDestinations({
    required String homeCity,
    required String homeCountry,
  }) async {
    final coords = await _geocodeHome(homeCity, homeCountry);
    if (coords == null) return _fallbackDestinations;

    final response = await _dio.get(
      'https://en.wikipedia.org/w/api.php',
      queryParameters: {
        'action': 'query',
        'format': 'json',
        'origin': '*',
        'generator': 'geosearch',
        'ggscoord': '${coords.latitude}|${coords.longitude}',
        'ggsradius': 50000,
        'ggslimit': 24,
        'prop': 'pageimages|description|extracts|coordinates|info',
        'exintro': 1,
        'explaintext': 1,
        'inprop': 'url',
        'piprop': 'thumbnail|original',
        'pithumbsize': 900,
      },
    );

    final query = (response.data as Map<String, dynamic>)['query'] as Map<String, dynamic>?;
    final pagesMap = query?['pages'] as Map<String, dynamic>?;
    if (pagesMap == null || pagesMap.isEmpty) {
      return _fallbackDestinations;
    }

    final pages = pagesMap.values.cast<Map<String, dynamic>>().toList();
    pages.sort((a, b) {
      final latA = _readLat(a);
      final lonA = _readLon(a);
      final latB = _readLat(b);
      final lonB = _readLon(b);
      final distA = _distanceKm(coords.latitude, coords.longitude, latA, lonA);
      final distB = _distanceKm(coords.latitude, coords.longitude, latB, lonB);
      return distA.compareTo(distB);
    });

    final destinations = <ExploreDestination>[];
    for (var i = 0; i < pages.length; i++) {
      final p = pages[i];
      final id = p['pageid']?.toString() ?? '${homeCity}_$i';
      final title = (p['title']?.toString() ?? '').trim();
      if (title.isEmpty) continue;

      final lat = _readLat(p);
      final lon = _readLon(p);
      final distanceKm = _distanceKm(coords.latitude, coords.longitude, lat, lon);
      final description = (p['extract']?.toString().trim().isNotEmpty ?? false)
          ? p['extract'].toString().trim()
          : (p['description']?.toString().trim().isNotEmpty ?? false)
              ? p['description'].toString().trim()
              : 'A notable place near your home location.';

      final imageUrl = (p['original']?['source'] ?? p['thumbnail']?['source'])?.toString();
      if (imageUrl == null || imageUrl.isEmpty) {
        continue;
      }

      final isWeekend = distanceKm <= 250;
      final isRecommended = distanceKm <= 120 || i < 4;
      final tag = _tagForText('$title $description');

      destinations.add(
        ExploreDestination(
          id: id,
          name: title,
          country: homeCountry,
          distanceFromMetro: '~${distanceKm.round()} km from $homeCity',
          bestMode: _bestMode(distanceKm),
          avgCostRange: _costRange(distanceKm),
          photoEmoji: _emojiForTag(tag),
          imageUrl: imageUrl,
          tag: tag,
          description: description,
          isTrending: i < 6,
          isWeekendGetaway: isWeekend,
          isRecommended: isRecommended,
          recommendedReason: isRecommended ? 'Near your home in $homeCity' : null,
          bestTimeToVisit: 'Year-round',
        ),
      );
    }

    return destinations.isEmpty ? _fallbackDestinations : destinations.take(16).toList();
  }

  Future<_GeoPoint?> _geocodeHome(String city, String country) async {
    final response = await _dio.get(
      'https://nominatim.openstreetmap.org/search',
      queryParameters: {
        'format': 'jsonv2',
        'limit': 1,
        'q': '$city, $country',
      },
    );

    final body = response.data;
    if (body is! List || body.isEmpty) return null;

    final first = body.first as Map<String, dynamic>;
    final lat = double.tryParse(first['lat']?.toString() ?? '');
    final lon = double.tryParse(first['lon']?.toString() ?? '');
    if (lat == null || lon == null) return null;
    return _GeoPoint(latitude: lat, longitude: lon);
  }
}

class _GeoPoint {
  final double latitude;
  final double longitude;
  const _GeoPoint({required this.latitude, required this.longitude});
}

double _readLat(Map<String, dynamic> page) {
  final coords = page['coordinates'];
  if (coords is List && coords.isNotEmpty) {
    final first = coords.first;
    return (first['lat'] as num?)?.toDouble() ?? 0;
  }
  return 0;
}

double _readLon(Map<String, dynamic> page) {
  final coords = page['coordinates'];
  if (coords is List && coords.isNotEmpty) {
    final first = coords.first;
    return (first['lon'] as num?)?.toDouble() ?? 0;
  }
  return 0;
}

double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0;
  final dLat = _degreesToRadians(lat2 - lat1);
  final dLon = _degreesToRadians(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degreesToRadians(lat1)) *
          math.cos(_degreesToRadians(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

double _degreesToRadians(double degrees) => degrees * (math.pi / 180);

String _bestMode(double distanceKm) {
  if (distanceKm <= 80) return '🚗 Car';
  if (distanceKm <= 220) return '🚌 Bus';
  if (distanceKm <= 700) return '🚆 Train/Bus';
  return '✈️ Plane';
}

String _costRange(double distanceKm) {
  if (distanceKm <= 80) return '₱1,500–₱4,000';
  if (distanceKm <= 220) return '₱2,500–₱7,000';
  if (distanceKm <= 700) return '₱5,000–₱12,000';
  return '₱10,000–₱25,000';
}

String _tagForText(String text) {
  final t = text.toLowerCase();
  if (t.contains('beach') || t.contains('island') || t.contains('coast')) return 'Beach';
  if (t.contains('mountain') || t.contains('forest') || t.contains('nature')) return 'Nature';
  if (t.contains('museum') || t.contains('church') || t.contains('heritage') || t.contains('historic')) {
    return 'Cultural';
  }
  if (t.contains('park') || t.contains('hike') || t.contains('adventure')) return 'Adventure';
  return 'City';
}

String _emojiForTag(String tag) {
  switch (tag) {
    case 'Beach':
      return '🏖️';
    case 'Nature':
      return '🌿';
    case 'Cultural':
      return '🏛️';
    case 'Adventure':
      return '⛰️';
    default:
      return '📍';
  }
}

const List<ExploreDestination> _fallbackDestinations = [
  ExploreDestination(
    id: 'fallback-1',
    name: 'Intramuros',
    country: 'Philippines',
    distanceFromMetro: '~4 km from Manila',
    bestMode: '🚗 Car',
    avgCostRange: '₱1,500–₱4,000',
    photoEmoji: '🏛️',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/0/0a/Intramuros_Walls_Manila.jpg',
    tag: 'Cultural',
    description: 'Historic walled city filled with Spanish-era architecture and museums.',
    isTrending: true,
    isWeekendGetaway: true,
    isRecommended: true,
    recommendedReason: 'Popular with local travelers',
    bestTimeToVisit: 'Year-round',
  ),
  ExploreDestination(
    id: 'fallback-2',
    name: 'Tagaytay',
    country: 'Philippines',
    distanceFromMetro: '~60 km from Manila',
    bestMode: '🚗 Car',
    avgCostRange: '₱2,000–₱5,000',
    photoEmoji: '🌋',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/3/31/Taal_Volcano_from_Tagaytay.jpg',
    tag: 'Nature',
    description: 'Cool weather and panoramic views of Taal Volcano.',
    isTrending: true,
    isWeekendGetaway: true,
    isRecommended: true,
    recommendedReason: 'Top weekend destination',
    bestTimeToVisit: 'Year-round',
  ),
];
