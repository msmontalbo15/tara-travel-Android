import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip_model.dart';
import 'repository_providers.dart';

// ── Selected Trip ID ──────────────────────────────────────────────────────────
//
// Single source of truth for which trip is currently "open".
// Set this before navigating to TripDetailScreen / Budget / Itinerary / Packing.
//
// Usage:
//   ref.read(selectedTripIdProvider.notifier).state = trip.id;
//   Navigator.pushNamed(context, '/trip-detail');

class SelectedTripIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String tripId) => state = tripId;
  void clear() => state = null;
}

final selectedTripIdProvider =
    NotifierProvider<SelectedTripIdNotifier, String?>(
  SelectedTripIdNotifier.new,
);

// ── Selected Trip (resolved model) ───────────────────────────────────────────
//
// Watches selectedTripIdProvider and fetches the matching TripModel.
// Returns null if no trip is selected or the ID doesn't match any record.

final selectedTripProvider = FutureProvider<TripModel?>((ref) async {
  final tripId = ref.watch(selectedTripIdProvider);
  if (tripId == null) return null;

  final repo = ref.watch(tripRepositoryProvider);
  return repo.getTripById(tripId);
});
