import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tara_travel/core/services/osrm_routing_service.dart';

void main() {
  group('OsrmRoutingService Unit Tests', () {
    late OsrmRoutingService service;

    setUp(() {
      service = OsrmRoutingService.instance;
      service.clearCache();
    });

    test('Single waypoint returns minimal route with 0 distance', () async {
      final points = [const LatLng(14.5995, 120.9842)];
      final result = await service.getRoute(points);

      expect(result.geometry.length, 1);
      expect(result.totalDistanceKm, 0.0);
      expect(result.totalDurationMin, 0.0);
      expect(result.isStraightLineFallback, true);
    });

    test('Two waypoints produces valid route (road-snapped or straight-line fallback)', () async {
      // Manila to Quezon City
      final points = [
        const LatLng(14.5995, 120.9842),
        const LatLng(14.6760, 121.0437),
      ];

      final result = await service.getRoute(points);

      expect(result.geometry.length, greaterThanOrEqualTo(2));
      expect(result.legs.length, 1);
      expect(result.totalDistanceKm, greaterThan(5.0));
      expect(result.totalDurationMin, greaterThan(5.0));
    });

    test('Straight-line fallback builds direct segment with positive distance', () {
      final points = [
        const LatLng(14.5995, 120.9842),
        const LatLng(14.6760, 121.0437),
      ];

      final result = service.buildStraightLineFallback(points);

      expect(result.geometry.length, 2);
      expect(result.legs.length, 1);
      expect(result.totalDistanceKm, greaterThan(5.0));
      expect(result.totalDurationMin, greaterThan(5.0));
      expect(result.isStraightLineFallback, true);
    });

    test('Multi-stop route calculates cumulative leg distances', () async {
      final points = [
        const LatLng(14.5995, 120.9842), // Manila
        const LatLng(14.5547, 121.0244), // Makati
        const LatLng(14.5378, 121.0014), // Pasay
      ];

      final result = await service.getRoute(points);

      expect(result.legs.length, 2);
      final sumLegDistances = result.legs.fold<double>(
        0.0,
        (sum, leg) => sum + leg.distanceKm,
      );
      expect(
        (result.totalDistanceKm - sumLegDistances).abs(),
        lessThan(0.01),
      );
    });

    test('Repeated requests with identical points return cached result', () async {
      final points = [
        const LatLng(10.3157, 123.8854), // Cebu City
        const LatLng(10.3110, 123.9180), // Mandaue
      ];

      final result1 = await service.getRoute(points);
      final result2 = await service.getRoute(points);

      expect(result1.totalDistanceKm, result2.totalDistanceKm);
      expect(result1.geometry.length, result2.geometry.length);
    });

    test('Empty waypoint list returns empty route geometry', () async {
      final result = await service.getRoute(const []);

      expect(result.geometry.isEmpty, true);
      expect(result.totalDistanceKm, 0.0);
      expect(result.isStraightLineFallback, true);
    });
  });
}
