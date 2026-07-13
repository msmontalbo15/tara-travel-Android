import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip_model.dart';
import '../providers/repository_providers.dart';
import '../providers/selected_trip_provider.dart';

// ── All Trips ─────────────────────────────────────────────────────────────────
//
// Fetches all trips the current user owns or is a member of.
// Re-fetches whenever the provider is invalidated (e.g. after createTrip).

final allTripsProvider = FutureProvider<List<TripModel>>((ref) async {
  final repo = ref.watch(tripRepositoryProvider);
  return repo.getTrips();
});

// ── Active Trip ───────────────────────────────────────────────────────────────
//
// Alias for selectedTripProvider. Falls back to the first trip
// in the list if no trip is explicitly selected (e.g. on the Home screen
// before the user taps into a trip).

final activeTripProvider = FutureProvider<TripModel?>((ref) async {
  // If a trip is explicitly selected, use that.
  final selected = await ref.watch(selectedTripProvider.future);
  if (selected != null) return selected;

  // Fallback: use the first upcoming trip from the list.
  final trips = await ref.watch(allTripsProvider.future);
  if (trips.isEmpty) return null;
  return trips.first;
});
