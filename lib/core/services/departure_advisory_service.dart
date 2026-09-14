import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../models/itinerary_model.dart';
import 'location_tracking_service.dart';

enum DepartureAdvisoryStatus {
  onTime,
  approachingGracePeriod,
  withinGracePeriod,
  delayed,
  departed,
}

class DepartureAdvisoryState {
  final DepartureAdvisoryStatus status;
  final Duration remainingToAssembly;
  final Duration remainingToWheelsUp;
  final int gracePeriodMinutes;
  final DateTime assemblyTime;
  final DateTime wheelsUpTime;
  final double? distanceMetersToDeparture;
  final int arrivedCount;
  final int totalCount;
  final String statusHeadline;
  final String statusDescription;

  const DepartureAdvisoryState({
    required this.status,
    required this.remainingToAssembly,
    required this.remainingToWheelsUp,
    required this.gracePeriodMinutes,
    required this.assemblyTime,
    required this.wheelsUpTime,
    required this.distanceMetersToDeparture,
    required this.arrivedCount,
    required this.totalCount,
    required this.statusHeadline,
    required this.statusDescription,
  });

  bool get isDeparted => status == DepartureAdvisoryStatus.departed;
  bool get hasGracePeriod => gracePeriodMinutes > 0;
  double get arrivedRatio => totalCount > 0 ? (arrivedCount / totalCount).clamp(0.0, 1.0) : 0.0;
}

/// Service computing smart countdowns, wheels-up thresholds, and automatic departure detection.
class DepartureAdvisoryService {
  DepartureAdvisoryService._();
  static final DepartureAdvisoryService instance = DepartureAdvisoryService._();

  /// Computes the complete departure advisory state for a given trip and meet-up stop.
  DepartureAdvisoryState computeState({
    required TripModel trip,
    required ItineraryStop? meetUpStop,
    DateTime? nowOverride,
  }) {
    final now = nowOverride ?? DateTime.now();

    // 1. Resolve Assembly Time
    final tripStartDate = trip.fromDate;
    TimeOfDay assemblyTod = const TimeOfDay(hour: 6, minute: 0);

    if (meetUpStop?.startTime != null) {
      assemblyTod = meetUpStop!.startTime!;
    } else if (trip.transportMeta != null && trip.transportMeta!['departure_time'] != null) {
      final parts = trip.transportMeta!['departure_time'].toString().split(':');
      if (parts.length >= 2) {
        assemblyTod = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 6,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    final assemblyTime = DateTime(
      tripStartDate.year,
      tripStartDate.month,
      tripStartDate.day,
      assemblyTod.hour,
      assemblyTod.minute,
    );

    // 2. Resolve Grace Period (Default: 15 mins)
    int graceMinutes = 15;
    if (trip.transportMeta != null && trip.transportMeta!['grace_period_minutes'] != null) {
      graceMinutes = (trip.transportMeta!['grace_period_minutes'] as num).toInt();
    }

    final wheelsUpTime = assemblyTime.add(Duration(minutes: graceMinutes));

    final diffAssembly = assemblyTime.difference(now);
    final diffWheelsUp = wheelsUpTime.difference(now);

    // 3. Arrived companion ratio
    final totalCount = trip.members.length;
    final arrivedCount = meetUpStop?.checkedInMembers.length ?? 0;

    // 4. GPS Telemetry & Geofence check
    double? distanceMeters;
    final depLat = trip.departureLat ?? meetUpStop?.lat;
    final depLng = trip.departureLng ?? meetUpStop?.lng;

    final lastGps = LocationTrackingService.instance.lastSnapshot;
    if (depLat != null && depLng != null && lastGps != null) {
      distanceMeters = _calculateHaversineDistance(
        lastGps.lat,
        lastGps.lng,
        depLat,
        depLng,
      );
    }

    // 5. Automatic Departure or Status resolution
    DepartureAdvisoryStatus status;
    String headline;
    String desc;

    final isMarkedDeparted = meetUpStop?.isCompleted == true ||
        (lastGps != null && lastGps.speed > 5.5 && (distanceMeters != null && distanceMeters > 300));

    if (isMarkedDeparted) {
      status = DepartureAdvisoryStatus.departed;
      headline = 'Convoy Rolling Out 🚀';
      desc = 'Trip departed from assembly point towards destination.';
    } else if (diffAssembly.inMinutes > 60) {
      status = DepartureAdvisoryStatus.onTime;
      headline = 'Assembly Scheduled';
      desc = 'Meet at ${_formatTime(assemblyTod)} with $graceMinutes-min grace period buffer.';
    } else if (diffAssembly.inSeconds > 0) {
      status = DepartureAdvisoryStatus.approachingGracePeriod;
      headline = 'Roll Call Approaching ⏰';
      desc = '${diffAssembly.inMinutes} mins until scheduled assembly (${_formatTime(assemblyTod)}).';
    } else if (diffWheelsUp.inSeconds >= 0) {
      status = DepartureAdvisoryStatus.withinGracePeriod;
      headline = 'Within Grace Period ⏳';
      final minsRemaining = diffWheelsUp.inMinutes;
      desc = 'Past target assembly! $minsRemaining mins remaining before wheels-up (${_formatTime(_dateTimeToTod(wheelsUpTime))}).';
    } else {
      status = DepartureAdvisoryStatus.delayed;
      headline = 'Past Wheels-Up Deadline ⚠️';
      final lateMins = (-diffWheelsUp.inMinutes);
      desc = '$lateMins mins past wheels-up! Check squad attendance and depart ASAP.';
    }

    return DepartureAdvisoryState(
      status: status,
      remainingToAssembly: diffAssembly,
      remainingToWheelsUp: diffWheelsUp,
      gracePeriodMinutes: graceMinutes,
      assemblyTime: assemblyTime,
      wheelsUpTime: wheelsUpTime,
      distanceMetersToDeparture: distanceMeters,
      arrivedCount: arrivedCount,
      totalCount: totalCount,
      statusHeadline: headline,
      statusDescription: desc,
    );
  }

  static TimeOfDay _dateTimeToTod(DateTime dt) => TimeOfDay(hour: dt.hour, minute: dt.minute);

  static String _formatTime(TimeOfDay tod) {
    final h = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final m = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  /// Calculates the Great Circle distance (in meters) between two coordinates using Haversine formula.
  static double _calculateHaversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0; // meters
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180.0);
}
