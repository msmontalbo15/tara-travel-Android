import 'dart:math' as math;
import '../../../core/models/itinerary_model.dart';

/// Result container for transit calculation & conflict detection between two stops.
class TransitConflictInfo {
  final double? distanceKm;
  final int? estimatedTransitMinutes;
  final int? timeGapMinutes; // Positive = free buffer, Negative = overlap conflict
  final bool hasOverlapConflict;
  final bool isTightBuffer;
  final String? warningMessage;

  const TransitConflictInfo({
    this.distanceKm,
    this.estimatedTransitMinutes,
    this.timeGapMinutes,
    this.hasOverlapConflict = false,
    this.isTightBuffer = false,
    this.warningMessage,
  });

  bool get hasWarning => hasOverlapConflict || isTightBuffer;
}

class TransitConflictHelper {
  /// Calculates transit details and time buffer / schedule collisions between [from] and [to].
  static TransitConflictInfo analyze({
    required ItineraryStop from,
    required ItineraryStop to,
  }) {
    double? distanceKm;
    int? transitMinutes;

    // 1. Calculate Geodesic Distance if both stops have lat/lng
    if (from.lat != null && from.lng != null && to.lat != null && to.lng != null) {
      distanceKm = _haversineKm(from.lat!, from.lng!, to.lat!, to.lng!);

      // Calculate estimated transit duration based on mode or average urban speed (35 km/h)
      final speed = to.transportMode?.averageSpeedKmh ?? from.transportMode?.averageSpeedKmh ?? 35.0;
      // Minutes = (distance in km / speed in km/h) * 60 + 5 minutes baseline buffer for parking/walking
      final rawMinutes = (distanceKm / speed * 60.0).round() + 5;
      transitMinutes = math.max(5, rawMinutes);
    }

    // 2. Calculate Schedule Overlap / Buffer if times are defined
    int? timeGapMinutes;
    bool hasOverlap = false;
    bool isTight = false;
    String? warning;

    final fromEndTime = from.endTime ?? from.startTime;
    final toStartTime = to.startTime;

    if (fromEndTime != null && toStartTime != null) {
      final fromEndMinutes = fromEndTime.hour * 60 + fromEndTime.minute;
      final toStartMinutes = toStartTime.hour * 60 + toStartTime.minute;

      timeGapMinutes = toStartMinutes - fromEndMinutes;

      if (timeGapMinutes < 0) {
        // Direct overlap / clash
        hasOverlap = true;
        warning = 'Schedule conflict: Overlaps by ${timeGapMinutes.abs()} min';
      } else if (transitMinutes != null && timeGapMinutes < transitMinutes) {
        // Free gap is smaller than estimated transit duration
        isTight = true;
        warning = 'Tight transit: Need ~${transitMinutes}m travel, only ${timeGapMinutes}m buffer';
      }
    }

    return TransitConflictInfo(
      distanceKm: distanceKm,
      estimatedTransitMinutes: transitMinutes,
      timeGapMinutes: timeGapMinutes,
      hasOverlapConflict: hasOverlap,
      isTightBuffer: isTight,
      warningMessage: warning,
    );
  }

  static double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0; // Earth's radius in km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180.0);
}
