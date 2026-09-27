import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tara_travel/core/models/trip_model.dart';
import 'package:tara_travel/core/models/itinerary_model.dart';
import 'package:tara_travel/core/services/departure_advisory_service.dart';

void main() {
  group('Plan 11 Meet-up & Assembly Unit Tests', () {
    test('TransportDetail serialization handles departureTime and gracePeriodMinutes', () {
      const detail = TransportDetail(
        mode: TransportMode.car,
        departurePoint: 'Shell SLEX Northbound',
        departureLat: 14.352,
        departureLng: 121.054,
        departureTime: '05:45',
        gracePeriodMinutes: 20,
      );

      final map = detail.toMap();
      expect(map['departure_time'], '05:45');
      expect(map['grace_period_minutes'], 20);
      expect(map['departure_point'], 'Shell SLEX Northbound');

      final deserialized = TransportDetail.fromMap(map);
      expect(deserialized.departureTime, '05:45');
      expect(deserialized.gracePeriodMinutes, 20);
      expect(deserialized.departurePoint, 'Shell SLEX Northbound');
      expect(deserialized.mode, TransportMode.car);
    });

    test('DepartureAdvisoryService computes wheels-up deadline with custom grace period', () {
      final tripDate = DateTime(2026, 10, 1);
      final trip = TripModel(
        id: 'trip-meetup-test',
        name: 'Road Trip to La Union',
        destination: 'San Juan, La Union',
        fromDate: tripDate,
        toDate: tripDate.add(const Duration(days: 3)),
        tripType: 'road_trip',
        totalBudget: 20000,
        departurePoint: 'Shell Balintawak',
        departureLat: 14.656,
        departureLng: 121.002,
        transportMeta: {
          'departure_time': '06:00',
          'grace_period_minutes': 30,
        },
      );

      final stop0 = ItineraryStop(
        id: 'stop-0',
        title: 'Meet-up & Assembly: Shell Balintawak',
        type: StopType.transport,
        location: 'Shell Balintawak',
        lat: 14.656,
        lng: 121.002,
        startTime: const TimeOfDay(hour: 6, minute: 0),
        checkedInMembers: {
          'user-a': DateTime(2026, 10, 1, 5, 50),
        },
      );

      // 1. Check state 45 minutes before assembly (05:15 AM)
      final stateEarly = DepartureAdvisoryService.instance.computeState(
        trip: trip,
        meetUpStop: stop0,
        nowOverride: DateTime(2026, 10, 1, 5, 15),
      );
      expect(stateEarly.status, DepartureAdvisoryStatus.approachingGracePeriod);
      expect(stateEarly.remainingToAssembly.inMinutes, 45);
      expect(stateEarly.remainingToWheelsUp.inMinutes, 75);
      expect(stateEarly.gracePeriodMinutes, 30);
      expect(stateEarly.arrivedCount, 1);

      // 2. Check state within grace period (06:15 AM)
      final stateGrace = DepartureAdvisoryService.instance.computeState(
        trip: trip,
        meetUpStop: stop0,
        nowOverride: DateTime(2026, 10, 1, 6, 15),
      );
      expect(stateGrace.status, DepartureAdvisoryStatus.withinGracePeriod);
      expect(stateGrace.remainingToWheelsUp.inMinutes, 15);

      // 3. Check state delayed / past wheels-up (06:45 AM)
      final stateLate = DepartureAdvisoryService.instance.computeState(
        trip: trip,
        meetUpStop: stop0,
        nowOverride: DateTime(2026, 10, 1, 6, 45),
      );
      expect(stateLate.status, DepartureAdvisoryStatus.delayed);

      // 4. Check state when stop is completed / departed
      final stopCompleted = stop0.copyWith(
        visitedAt: DateTime(2026, 10, 1, 6, 20),
      );
      final stateDeparted = DepartureAdvisoryService.instance.computeState(
        trip: trip,
        meetUpStop: stopCompleted,
        nowOverride: DateTime(2026, 10, 1, 6, 25),
      );
      expect(stateDeparted.status, DepartureAdvisoryStatus.departed);
      expect(stateDeparted.isDeparted, isTrue);
    });

    test('TripModel copyWith preserves and updates departure and transport metadata', () {
      final trip = TripModel(
        id: 'test-trip',
        name: 'Initial Name',
        destination: 'Baler',
        fromDate: DateTime(2026, 11, 1),
        toDate: DateTime(2026, 11, 4),
        tripType: 'beach',
        totalBudget: 12000,
        departurePoint: 'Cubao Bus Terminal',
        transportMeta: {
          'departure_time': '04:00',
          'grace_period_minutes': 15,
        },
      );

      final updated = trip.copyWith(
        departurePoint: 'Marikina Assembly Hub',
        departureLat: 14.6507,
        departureLng: 121.1029,
        transportMeta: {
          'departure_time': '05:30',
          'grace_period_minutes': 20,
        },
      );

      expect(updated.departurePoint, 'Marikina Assembly Hub');
      expect(updated.departureLat, 14.6507);
      expect(updated.departureLng, 121.1029);
      expect(updated.transportMeta?['departure_time'], '05:30');
      expect(updated.transportMeta?['grace_period_minutes'], 20);
    });
  });
}
