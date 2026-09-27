import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tara_travel/core/services/route_optimization_service.dart';

void main() {
  group('RouteOptimizationService Unit Tests', () {
    late RouteOptimizationService service;

    setUp(() {
      service = RouteOptimizationService.instance;
    });

    test('Optimization with 2 or fewer points returns identical order', () async {
      final points = [
        const LatLng(14.5995, 120.9842),
        const LatLng(14.5547, 121.0244),
      ];

      final result = await service.optimize(
        OptimizationRequest(points: points),
      );

      expect(result.optimizedOrder, [0, 1]);
      expect(result.savedDistanceKm, 0.0);
    });

    test('Optimization reorders zig-zag route to a shorter or equal path', () async {
      // Intentionally ordered in a zig-zag: A -> C -> B -> D
      // Linear points on a line:
      // P0: 14.50, 121.00
      // P1: 14.80, 121.00
      // P2: 14.60, 121.00
      // P3: 14.90, 121.00
      final points = [
        const LatLng(14.50, 121.00),
        const LatLng(14.80, 121.00),
        const LatLng(14.60, 121.00),
        const LatLng(14.90, 121.00),
      ];

      final result = await service.optimize(
        OptimizationRequest(points: points),
      );

      // Must contain all indices 0..3 exactly once
      expect(result.optimizedOrder.toSet(), {0, 1, 2, 3});
      expect(result.optimizedOrder.length, 4);

      // The optimized distance should be less than or equal to the zig-zag original
      expect(result.optimizedDistanceKm, lessThanOrEqualTo(result.originalDistanceKm));
      expect(result.savedDistanceKm, greaterThanOrEqualTo(0.0));
    });

    test('Pinned stop constraint preserves pinned indices at fixed positions', () async {
      final points = [
        const LatLng(14.50, 121.00), // Index 0 (start)
        const LatLng(14.80, 121.00), // Index 1
        const LatLng(14.60, 121.00), // Index 2 (PINNED - e.g. Lunch Reservation)
        const LatLng(14.90, 121.00), // Index 3
        const LatLng(14.70, 121.00), // Index 4
      ];

      final result = await service.optimize(
        OptimizationRequest(
          points: points,
          pinnedIndices: {2}, // Index 2 must remain at position 2
        ),
      );

      expect(result.optimizedOrder.length, 5);
      expect(result.optimizedOrder.toSet(), {0, 1, 2, 3, 4});

      // Fixed constraint check:
      expect(result.optimizedOrder[2], 2);
    });

    test('Multiple pinned stops remain fixed while flexible stops reorder', () async {
      final points = [
        const LatLng(14.50, 121.00), // Index 0 (PINNED - Start hotel)
        const LatLng(14.80, 121.00), // Index 1
        const LatLng(14.60, 121.00), // Index 2
        const LatLng(14.90, 121.00), // Index 3 (PINNED - Dinner)
      ];

      final result = await service.optimize(
        OptimizationRequest(
          points: points,
          pinnedIndices: {0, 3},
        ),
      );

      expect(result.optimizedOrder.first, 0);
      expect(result.optimizedOrder.last, 3);
      expect(result.optimizedOrder.toSet(), {0, 1, 2, 3});
    });
  });
}
