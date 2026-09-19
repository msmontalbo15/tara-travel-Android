import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tara_travel/core/models/trip_model.dart';
import 'package:tara_travel/features/create_trip/models/new_trip_model.dart';

void main() {
  group('TripModel JourneyMode & Map Flexibility Tests (Plan 10)', () {
    test('Default TripModel has map enabled and standard journey mode', () {
      final trip = TripModel(
        id: 't-1',
        name: 'Boracay Weekend',
        destination: 'Boracay, Aklan',
        fromDate: DateTime(2026, 10, 1),
        toDate: DateTime(2026, 10, 5),
        tripType: 'beach',
        totalBudget: 15000,
      );

      expect(trip.isMapEnabled, isTrue);
      expect(trip.journeyMode, equals(JourneyMode.standard));
      expect(trip.isAdventureMode, isFalse);
      expect(trip.isMultiPointMode, isFalse);
      expect(trip.destinationHubs, isEmpty);
    });

    test('TripModel parses journey_mode and map_enabled from destination_details', () {
      final trip = TripModel(
        id: 't-2',
        name: 'Mt. Pulag Trek',
        destination: 'Benguet',
        fromDate: DateTime(2026, 11, 10),
        toDate: DateTime(2026, 11, 12),
        tripType: 'nature',
        totalBudget: 8000,
        destinationDetails: {
          'map_enabled': false,
          'journey_mode': 'adventure',
          'trail_notes': 'Akiki-Tawangan loop',
        },
      );

      expect(trip.isMapEnabled, isFalse);
      expect(trip.journeyMode, equals(JourneyMode.adventure));
      expect(trip.isAdventureMode, isTrue);
      expect(trip.isMultiPointMode, isFalse);
      expect(trip.destinationHubs, isEmpty);
    });

    test('TripModel parses multi_point mode and destinationHubs correctly', () {
      final trip = TripModel(
        id: 't-3',
        name: 'Southern Tagalog Loop',
        destination: 'Multiple Destinations',
        fromDate: DateTime(2026, 12, 20),
        toDate: DateTime(2026, 12, 25),
        tripType: 'road_trip',
        totalBudget: 25000,
        destinationDetails: {
          'map_enabled': true,
          'journey_mode': 'multi_point',
          'hubs': ['Tagaytay', 'Nasugbu', 'Batangas City', 'Calatagan'],
        },
      );

      expect(trip.isMapEnabled, isTrue);
      expect(trip.journeyMode, equals(JourneyMode.multiPoint));
      expect(trip.isAdventureMode, isFalse);
      expect(trip.isMultiPointMode, isTrue);
      expect(trip.destinationHubs, equals(['Tagaytay', 'Nasugbu', 'Batangas City', 'Calatagan']));
    });

    test('TripModel parses destinationDetails from Map in TripModel.fromMap', () {
      final map = {
        'id': 't-4',
        'title': 'Sagada Spelunking',
        'name': 'Sagada Spelunking',
        'destination': 'Sagada, Mountain Province',
        'start_date': '2026-10-10',
        'end_date': '2026-10-14',
        'type': 'adventure',
        'trip_type': 'adventure',
        'total_budget': 12000,
        'destination_details': {
          'map_enabled': false,
          'journey_mode': 'adventure',
        },
      };

      final trip = TripModel.fromMap(map);
      expect(trip.isMapEnabled, isFalse);
      expect(trip.journeyMode, equals(JourneyMode.adventure));
      expect(trip.isAdventureMode, isTrue);
    });

    test('NewTripModel buildDestinationDetails serializes correctly', () {
      final newTrip = NewTripModel(
        tripName: 'North Luzon Loop',
        destination: 'Luzon',
        fromDate: DateTime(2026, 10, 1),
        toDate: DateTime(2026, 10, 8),
        isMapEnabled: true,
        journeyMode: 'multi_point',
        destinationHubs: ['La Union', 'Vigan', 'Pagudpud'],
      );

      final details = newTrip.buildDestinationDetails();
      expect(details['map_enabled'], isTrue);
      expect(details['journey_mode'], equals('multi_point'));
      expect(details['hubs'], equals(['La Union', 'Vigan', 'Pagudpud']));
    });

    test('JourneyMode values and labels match expectations', () {
      expect(JourneyMode.standard.label, 'Standard Map');
      expect(JourneyMode.adventure.label, 'Adventure & Off-Grid');
      expect(JourneyMode.multiPoint.label, 'Multi-Hub Route');
      expect(JourneyMode.adventure.icon, Icons.explore_rounded);
      expect(JourneyMode.multiPoint.icon, Icons.alt_route_rounded);
    });
  });
}
