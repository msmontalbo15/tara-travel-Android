import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tara_travel/core/services/location_broadcast_service.dart';
import 'package:tara_travel/features/navigation/models/navigation_models.dart';

void main() {
  group('Convoy Telemetry & Formation Algorithms', () {
    const destLat = 16.4124; // Baguio
    const destLng = 120.6225;

    test('classifyConvoyRoles correctly assigns lead, mid, and tail', () {
      const leadMember = NavMember(
        id: 'user-lead',
        name: 'Maria Santos',
        initials: 'MS',
        color: Color(0xFFD85A30),
        status: MemberStatus.enRoute,
        role: 'Navigator',
        latitude: 16.4100, // Very close to destination
        longitude: 120.6220,
      );

      const midMember = NavMember(
        id: 'user-mid',
        name: 'Alex Rivera',
        initials: 'AR',
        color: Color(0xFF2563EB),
        status: MemberStatus.enRoute,
        role: 'Traveler',
        latitude: 16.3900, // ~2.5 km away
        longitude: 120.6200,
      );

      const tailMember = NavMember(
        id: 'user-tail',
        name: 'Juan Dela Cruz',
        initials: 'JD',
        color: Color(0xFFEF9F27),
        status: MemberStatus.enRoute,
        role: 'Traveler',
        latitude: 16.3400, // ~8 km away (straggler)
        longitude: 120.6100,
      );

      final roles = LocationBroadcastService.classifyConvoyRoles(
        members: [midMember, leadMember, tailMember],
        destLat: destLat,
        destLng: destLng,
      );

      expect(roles['user-lead'], ConvoyRole.lead);
      expect(roles['user-mid'], ConvoyRole.mid);
      expect(roles['user-tail'], ConvoyRole.tail);
    });

    test('NavMember isStraggler returns true only for tail member with > 2km gap', () {
      const straggler = NavMember(
        id: 'user-straggler',
        name: 'Juan',
        initials: 'J',
        color: Colors.blue,
        status: MemberStatus.enRoute,
        role: 'Traveler',
        convoyRole: ConvoyRole.tail,
        distanceKm: -3.5, // 3.5 km behind
      );

      const closeTail = NavMember(
        id: 'user-close-tail',
        name: 'Alex',
        initials: 'A',
        color: Colors.blue,
        status: MemberStatus.enRoute,
        role: 'Traveler',
        convoyRole: ConvoyRole.tail,
        distanceKm: -0.8, // only 800m behind
      );

      const midMember = NavMember(
        id: 'user-mid',
        name: 'Maria',
        initials: 'M',
        color: Colors.blue,
        status: MemberStatus.enRoute,
        role: 'Traveler',
        convoyRole: ConvoyRole.mid,
        distanceKm: -3.0,
      );

      expect(straggler.isStraggler, true);
      expect(closeTail.isStraggler, false);
      expect(midMember.isStraggler, false);
    });

    test('calculateStopEta returns accurate distance, duration, and formatted string', () {
      final etaResult = LocationBroadcastService.calculateStopEta(
        memberLat: 16.4000,
        memberLng: 120.6200,
        destLat: destLat,
        destLng: destLng,
        speedKmh: 45.0,
      );

      expect(etaResult.distanceKm, greaterThan(0.0));
      expect(etaResult.distanceKm, lessThan(5.0));
      expect(etaResult.durationMin, greaterThanOrEqualTo(1));
      expect(etaResult.eta, contains('away'));
    });

    test('isWithinArrivalGeofence detects 150m proximity accurately', () {
      // Very close (~30 meters)
      final isArrived = LocationBroadcastService.isWithinArrivalGeofence(
        userLat: 16.4125,
        userLng: 120.6225,
        destLat: destLat,
        destLng: destLng,
        thresholdMeters: 150.0,
      );
      expect(isArrived, true);

      // Far away (~500 meters)
      final notArrived = LocationBroadcastService.isWithinArrivalGeofence(
        userLat: 16.4180,
        userLng: 120.6225,
        destLat: destLat,
        destLng: destLng,
        thresholdMeters: 150.0,
      );
      expect(notArrived, false);
    });

    test('hasDepartedGeofence triggers only when > 200m away and speed >= 15 km/h', () {
      // 500m away and moving at 25 km/h -> Departed
      final hasDeparted = LocationBroadcastService.hasDepartedGeofence(
        userLat: 16.4180,
        userLng: 120.6225,
        destLat: destLat,
        destLng: destLng,
        speedKmh: 25.0,
      );
      expect(hasDeparted, true);

      // 500m away but stationary (speed 2 km/h) -> Not departed (e.g. GPS jitter or walking inside parking)
      final stationary = LocationBroadcastService.hasDepartedGeofence(
        userLat: 16.4180,
        userLng: 120.6225,
        destLat: destLat,
        destLng: destLng,
        speedKmh: 2.0,
      );
      expect(stationary, false);

      // Only 80m away at 30 km/h -> Not departed yet (still inside stop)
      final insideRadius = LocationBroadcastService.hasDepartedGeofence(
        userLat: 16.4128,
        userLng: 120.6225,
        destLat: destLat,
        destLng: destLng,
        speedKmh: 30.0,
      );
      expect(insideRadius, false);
    });

    test('calculateCentroid computes geographical center accurately', () {
      final points = [
        (lat: 14.0, lng: 120.0),
        (lat: 16.0, lng: 122.0),
      ];

      final centroid = LocationBroadcastService.calculateCentroid(points);
      expect(centroid, isNotNull);
      expect(centroid!.lat, 15.0);
      expect(centroid.lng, 121.0);

      // Empty points handles gracefully
      expect(LocationBroadcastService.calculateCentroid([]), isNull);
    });
  });
}
