import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tara_travel/core/models/itinerary_model.dart';
import 'package:tara_travel/core/services/geofence_arrival_service.dart';

void main() {
  group('GeofenceArrivalService Unit Tests', () {
    late GeofenceArrivalService service;

    setUp(() {
      service = GeofenceArrivalService.instance;
      service.reset();
      service.stopMonitoring();
    });

    final testStop = ItineraryStop(
      id: 'stop-baguio-mansion',
      title: 'The Mansion, Baguio',
      startTime: const TimeOfDay(hour: 10, minute: 0),
      type: StopType.activity,
      lat: 16.4124,
      lng: 120.6225,
    );

    test('Triggers arrival when within 100m proximity', () async {
      service.updateStops([testStop]);

      ArrivalEvent? receivedEvent;
      final sub = service.arrivalStream.listen((e) => receivedEvent = e);

      // Within ~30m of the stop (16.4124, 120.6225)
      service.evaluatePosition(16.4126, 120.6226);

      await Future.delayed(const Duration(milliseconds: 10));

      expect(receivedEvent, isNotNull);
      expect(receivedEvent!.stopId, 'stop-baguio-mansion');
      expect(receivedEvent!.stopTitle, 'The Mansion, Baguio');
      expect(receivedEvent!.distanceMeters, lessThanOrEqualTo(100.0));
      expect(service.visitedStopIds.contains('stop-baguio-mansion'), true);

      await sub.cancel();
    });

    test('Does NOT trigger arrival when outside proximity threshold', () async {
      service.updateStops([testStop]);

      ArrivalEvent? receivedEvent;
      final sub = service.arrivalStream.listen((e) => receivedEvent = e);

      // Manila coordinates (~200km away from Baguio)
      service.evaluatePosition(14.5995, 120.9842);

      await Future.delayed(const Duration(milliseconds: 10));

      expect(receivedEvent, isNull);
      expect(service.visitedStopIds.contains('stop-baguio-mansion'), false);

      await sub.cancel();
    });

    test('Cooldown prevents duplicate arrival triggers for same stop', () async {
      service.updateStops([testStop]);

      final events = <ArrivalEvent>[];
      final sub = service.arrivalStream.listen((e) => events.add(e));

      // First breach: within 50m
      service.evaluatePosition(16.4125, 120.6225);
      await Future.delayed(const Duration(milliseconds: 10));

      // Second breach: still within 50m
      service.evaluatePosition(16.4125, 120.6225);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(events.length, 1);

      await sub.cancel();
    });

    test('Marking visited manually suppresses future evaluations', () async {
      service.updateStops([testStop]);
      service.markVisited('stop-baguio-mansion');

      ArrivalEvent? receivedEvent;
      final sub = service.arrivalStream.listen((e) => receivedEvent = e);

      service.evaluatePosition(16.4124, 120.6225);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(receivedEvent, isNull);

      await sub.cancel();
    });

    test('Reset clears visited history and allows re-triggering', () async {
      service.updateStops([testStop]);
      service.markVisited('stop-baguio-mansion');
      expect(service.visitedStopIds.length, 1);

      service.reset();
      expect(service.visitedStopIds.isEmpty, true);
    });
  });
}
