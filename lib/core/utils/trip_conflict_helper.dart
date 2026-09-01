import '../models/trip_model.dart';

/// Helper utility for detecting and analyzing schedule overlaps between trips.
class TripConflictHelper {
  /// Checks if two date ranges overlap.
  /// Standard formula: startA <= endB && endA >= startB
  static bool hasDateOverlap(
    DateTime startA,
    DateTime endA,
    DateTime startB,
    DateTime endB,
  ) {
    final sA = DateTime(startA.year, startA.month, startA.day);
    final eA = DateTime(endA.year, endA.month, endA.day);
    final sB = DateTime(startB.year, startB.month, startB.day);
    final eB = DateTime(endB.year, endB.month, endB.day);

    return !sA.isAfter(eB) && !eA.isBefore(sB);
  }

  /// Checks if a single date falls within a trip's start/end range (inclusive).
  static bool isDateInTrip(DateTime date, TripModel trip) {
    final d = DateTime(date.year, date.month, date.day);
    final start = DateTime(trip.fromDate.year, trip.fromDate.month, trip.fromDate.day);
    final end = DateTime(trip.toDate.year, trip.toDate.month, trip.toDate.day);

    return !d.isBefore(start) && !d.isAfter(end);
  }

  /// Finds all trips that overlap with a specified date range.
  /// Allows excluding a specific trip ID (e.g., when editing an existing trip).
  static List<TripModel> findConflictingTrips({
    required List<TripModel> trips,
    required DateTime start,
    required DateTime end,
    String? excludeTripId,
  }) {
    return trips.where((trip) {
      if (trip.isArchived) return false;
      if (excludeTripId != null && trip.id == excludeTripId) return false;
      return hasDateOverlap(start, end, trip.fromDate, trip.toDate);
    }).toList();
  }

  /// Returns a map of day timestamp (normalized to midnight) to the list of trips on that day.
  static Map<DateTime, List<TripModel>> buildDayTripMap(List<TripModel> trips, {String? excludeTripId}) {
    final map = <DateTime, List<TripModel>>{};

    for (final trip in trips) {
      if (trip.isArchived) continue;
      if (excludeTripId != null && trip.id == excludeTripId) continue;

      var current = DateTime(trip.fromDate.year, trip.fromDate.month, trip.fromDate.day);
      final end = DateTime(trip.toDate.year, trip.toDate.month, trip.toDate.day);

      while (!current.isAfter(end)) {
        map.putIfAbsent(current, () => []).add(trip);
        current = current.add(const Duration(days: 1));
      }
    }

    return map;
  }
}
