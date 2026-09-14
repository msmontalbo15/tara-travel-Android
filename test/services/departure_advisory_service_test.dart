import 'package:flutter_test/flutter_test.dart';
import 'package:tara_travel/core/models/trip_model.dart';
import 'package:tara_travel/core/models/itinerary_model.dart';
import 'package:tara_travel/core/services/departure_advisory_service.dart';

void main() {
  group('DepartureAdvisoryService Unit Tests', () {
    final now = DateTime(2026, 9, 15, 5, 0); // 05:00 AM

    final testTrip = TripModel(
      id: 'test-trip-1',
      name: 'Baguio Food Trip',
      destination: 'Baguio City',
      fromDate: DateTime(2026, 9, 15),
      toDate: DateTime(2026, 9, 17),
      tripType: 'road_trip',
      totalBudget: 15000,
      departurePoint: 'Shell Balintawak Northbound',
      departureLat: 14.6565,
      departureLng: 121.0028,
      transportMeta: {
        'departure_time': '05:30',
        'grace_period_minutes': 15,
      },
    );

    test('Status is approachingGracePeriod when 30 mins before assembly', () {
      final state = DepartureAdvisoryService.instance.computeState(
        trip: testTrip,
        meetUpStop: null,
        nowOverride: now,
      );

      expect(state.status, DepartureAdvisoryStatus.approachingGracePeriod);
      expect(state.gracePeriodMinutes, 15);
      expect(state.remainingToAssembly.inMinutes, 30);
      expect(state.remainingToWheelsUp.inMinutes, 45);
    });

    test('Status is withinGracePeriod when between assembly and wheels-up', () {
      final graceNow = DateTime(2026, 9, 15, 5, 35); // 05:35 AM (past 5:30, before 5:45)
      final state = DepartureAdvisoryService.instance.computeState(
        trip: testTrip,
        meetUpStop: null,
        nowOverride: graceNow,
      );

      expect(state.status, DepartureAdvisoryStatus.withinGracePeriod);
      expect(state.remainingToWheelsUp.inMinutes, 10);
    });

    test('Status is delayed when past wheels up deadline', () {
      final lateNow = DateTime(2026, 9, 15, 5, 50); // 05:50 AM (past 5:45)
      final state = DepartureAdvisoryService.instance.computeState(
        trip: testTrip,
        meetUpStop: null,
        nowOverride: lateNow,
      );

      expect(state.status, DepartureAdvisoryStatus.delayed);
    });

    test('Companion headcount ratio computes properly', () {
      final stop = ItineraryStop(
        id: 'stop-0',
        title: 'Meet-up & Assembly',
        type: StopType.transport,
        checkedInMembers: {
          'user-1': DateTime.now(),
          'user-2': DateTime.now(),
        },
      );

      final state = DepartureAdvisoryService.instance.computeState(
        trip: testTrip,
        meetUpStop: stop,
        nowOverride: now,
      );

      expect(state.arrivedCount, 2);
    });
  });
}
