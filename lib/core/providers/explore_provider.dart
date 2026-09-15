import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/destination_model.dart';
import 'profile_provider.dart';
import 'trip_provider.dart';
import 'repository_providers.dart';

/// Destination model alias for Explore screen backwards-compatibility
typedef ExploreDestination = DestinationModel;

/// Selected category filter state on Explore Screen ('All', 'Beach', 'Nature', etc.)
class ExploreCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setCategory(String category) {
    state = category;
  }
}

final exploreCategoryFilterProvider =
    NotifierProvider<ExploreCategoryNotifier, String>(ExploreCategoryNotifier.new);

/// Known Philippine hub coordinates for distance estimation and proximity scoring
const Map<String, ({double lat, double lng})> _knownHubs = {
  'manila': (lat: 14.5995, lng: 120.9842),
  'metro manila': (lat: 14.5995, lng: 120.9842),
  'quezon city': (lat: 14.6760, lng: 121.0437),
  'makati': (lat: 14.5547, lng: 121.0244),
  'taguig': (lat: 14.5176, lng: 121.0509),
  'pasig': (lat: 14.5764, lng: 121.0851),
  'cebu': (lat: 10.3157, lng: 123.8854),
  'cebu city': (lat: 10.3157, lng: 123.8854),
  'davao': (lat: 7.1907, lng: 125.4578),
  'davao city': (lat: 7.1907, lng: 125.4578),
  'baguio': (lat: 16.4023, lng: 120.5960),
  'tagaytay': (lat: 14.1153, lng: 120.9621),
  'iloilo': (lat: 10.7202, lng: 122.5621),
  'bacolod': (lat: 10.6765, lng: 122.9509),
  'angeles': (lat: 15.1450, lng: 120.5887),
  'pampanga': (lat: 15.0794, lng: 120.6200),
  'batangas': (lat: 13.7565, lng: 121.0583),
  'laguna': (lat: 14.2691, lng: 121.4113),
  'cavite': (lat: 14.2456, lng: 120.8786),
};

/// Authoritative provider for explore destinations backed by Supabase `public.destinations`,
/// enriched with dynamic user-centric recommendations based on home location, travel history,
/// and weekend accessibility.
final exploreProvider = FutureProvider<List<DestinationModel>>((ref) async {
  final repo = ref.watch(destinationRepositoryProvider);
  final profile = ref.watch(profileProvider);
  final userTripsAsync = ref.watch(allTripsProvider);
  final userTrips = userTripsAsync.asData?.value ?? [];

  final destinations = await repo.getDestinations();

  final homeCity = profile.homeCity.trim();
  final hasHome = homeCity.isNotEmpty && homeCity.toLowerCase() != 'not set';
  final homeCoords = hasHome ? _resolveCoords(homeCity) : _knownHubs['manila'];

  // Identify destinations user has already visited or planned
  final plannedNames = userTrips
      .map((t) => t.destination.toLowerCase().trim())
      .toSet();

  return destinations.map((dest) {
    var isWeekend = dest.isWeekendGetaway;
    var isRec = dest.isRecommended;
    String? recReason = dest.recommendedReason;
    String distanceStr = dest.distanceFromMetro;

    if (homeCoords != null && dest.latitude != null && dest.longitude != null) {
      final km = _calculateDistanceKm(
        homeCoords.lat,
        homeCoords.lng,
        dest.latitude!,
        dest.longitude!,
      );

      final roundedKm = km.round();
      if (hasHome) {
        distanceStr = '~$roundedKm km from $homeCity';
      }

      // Weekend getaway if <= 220 km road trip distance
      if (km <= 220) {
        isWeekend = true;
      }

      // Smart Contextual Recommendations
      final isNewDestination = !plannedNames.any((name) =>
          dest.name.toLowerCase().contains(name) || name.contains(dest.name.toLowerCase()));

      if (km <= 120 && isNewDestination) {
        isRec = true;
        recReason = 'Top getaway just ~$roundedKm km from $homeCity';
      } else if (dest.isTrending && isNewDestination) {
        isRec = true;
        recReason = 'Trending destination you haven’t explored yet';
      } else if (isWeekend && hasHome) {
        isRec = true;
        recReason = 'Perfect weekend road trip from $homeCity';
      }
    }

    return dest.copyWith(
      distanceFromMetro: distanceStr,
      isWeekendGetaway: isWeekend,
      isRecommended: isRec,
      recommendedReason: recReason,
    );
  }).toList();
});

({double lat, double lng})? _resolveCoords(String query) {
  final clean = query.toLowerCase().trim();
  for (final entry in _knownHubs.entries) {
    if (clean.contains(entry.key) || entry.key.contains(clean)) {
      return entry.value;
    }
  }
  return null;
}

double _calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0;
  final dLat = (lat2 - lat1) * (math.pi / 180.0);
  final dLon = (lon2 - lon1) * (math.pi / 180.0);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * (math.pi / 180.0)) *
          math.cos(lat2 * (math.pi / 180.0)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}
