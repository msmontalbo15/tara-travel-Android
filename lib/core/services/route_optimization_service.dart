/// route_optimization_service.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// TSP-based itinerary stop sequence optimizer for Tara Travel.
///
/// Provides "Find Best Way" reordering of day stops to minimize total
/// driving distance/time, while respecting user-pinned fixed-time stops
/// (hotel check-ins, reservations) that must remain in their original
/// positions.
///
/// Algorithm:
/// 1. Nearest-neighbor heuristic for initial solution.
/// 2. 2-opt improvement pass to eliminate crossing paths.
/// 3. Pinned stop constraints preserved throughout optimization.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:latlong2/latlong.dart';
import 'osrm_routing_service.dart';

/// Request payload for route optimization.
class OptimizationRequest {
  /// Ordered list of stop coordinates to optimize.
  final List<LatLng> points;

  /// Indices of stops that must remain in their original position.
  /// (e.g., hotel check-in at index 2, dinner reservation at index 5)
  final Set<int> pinnedIndices;

  const OptimizationRequest({
    required this.points,
    this.pinnedIndices = const {},
  });
}

/// Result of route optimization with before/after comparison.
class OptimizationResult {
  /// Optimized order — index mapping from new position to original index.
  /// `optimizedOrder[newIdx] = originalIdx`
  final List<int> optimizedOrder;

  /// Reordered points in the optimized sequence.
  final List<LatLng> optimizedPoints;

  /// Total distance in km before optimization (original order).
  final double originalDistanceKm;

  /// Total distance in km after optimization.
  final double optimizedDistanceKm;

  /// Distance saved in km (positive = improvement).
  double get savedDistanceKm => originalDistanceKm - optimizedDistanceKm;

  /// Percentage improvement.
  double get savedPercent => originalDistanceKm > 0
      ? (savedDistanceKm / originalDistanceKm) * 100
      : 0;

  const OptimizationResult({
    required this.optimizedOrder,
    required this.optimizedPoints,
    required this.originalDistanceKm,
    required this.optimizedDistanceKm,
  });
}

class RouteOptimizationService {
  // ── Singleton ──────────────────────────────────────────────────────────
  static final RouteOptimizationService instance =
      RouteOptimizationService._();
  RouteOptimizationService._();

  final OsrmRoutingService _osrm = OsrmRoutingService.instance;

  // ── Public API ─────────────────────────────────────────────────────────

  /// Optimizes the stop sequence to minimize total travel distance.
  ///
  /// Uses the OSRM Table API for real driving distances when available,
  /// falling back to Haversine straight-line distances on failure.
  ///
  /// Pinned stops remain at their original indices while flexible stops
  /// are reordered between them.
  Future<OptimizationResult> optimize(OptimizationRequest request) async {
    final n = request.points.length;
    if (n <= 2) {
      // Nothing to optimize with ≤2 stops
      final dist = _haversineTotalDistance(request.points);
      return OptimizationResult(
        optimizedOrder: List.generate(n, (i) => i),
        optimizedPoints: List.from(request.points),
        originalDistanceKm: dist,
        optimizedDistanceKm: dist,
      );
    }

    // Build distance matrix: try OSRM Table, fallback to Haversine
    final distanceMatrix = await _buildDistanceMatrix(request.points);

    // Original total distance
    final originalDist = _totalRouteDistance(
      distanceMatrix,
      List.generate(n, (i) => i),
    );

    // Separate pinned and flexible indices
    final pinned = request.pinnedIndices;
    final flexible = <int>[];
    for (int i = 0; i < n; i++) {
      if (!pinned.contains(i)) flexible.add(i);
    }

    if (flexible.length <= 1) {
      // Only 0-1 flexible stops — nothing to optimize
      return OptimizationResult(
        optimizedOrder: List.generate(n, (i) => i),
        optimizedPoints: List.from(request.points),
        originalDistanceKm: originalDist,
        optimizedDistanceKm: originalDist,
      );
    }

    // Optimize in segments between pinned stops
    final optimizedOrder = _optimizeWithPins(
      n,
      pinned,
      flexible,
      distanceMatrix,
    );

    final optimizedDist = _totalRouteDistance(distanceMatrix, optimizedOrder);

    return OptimizationResult(
      optimizedOrder: optimizedOrder,
      optimizedPoints: optimizedOrder.map((i) => request.points[i]).toList(),
      originalDistanceKm: originalDist,
      optimizedDistanceKm: optimizedDist,
    );
  }

  // ── Distance Matrix ────────────────────────────────────────────────────

  Future<List<List<double>>> _buildDistanceMatrix(List<LatLng> points) async {
    // Attempt OSRM Table API for real driving distances
    try {
      final table = await _osrm.getTable(points);
      if (table != null) {
        return table.matrix.map((row) {
          return row.map((cell) => cell.distanceKm ?? double.infinity).toList();
        }).toList();
      }
    } catch (_) {
      // Fall through to Haversine
    }

    // Fallback: Haversine distance matrix
    return _haversineDistanceMatrix(points);
  }

  List<List<double>> _haversineDistanceMatrix(List<LatLng> points) {
    const haversine = Distance();
    final n = points.length;
    final matrix = List.generate(
      n,
      (_) => List.filled(n, 0.0),
    );

    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        final distM = haversine.as(LengthUnit.Meter, points[i], points[j]);
        final distKm = distM / 1000;
        matrix[i][j] = distKm;
        matrix[j][i] = distKm;
      }
    }

    return matrix;
  }

  // ── TSP Optimization ──────────────────────────────────────────────────

  /// Optimizes flexible stops between pinned anchors.
  ///
  /// Strategy:
  /// 1. Divide the sequence into segments bounded by pinned stops.
  /// 2. Within each segment, apply nearest-neighbor + 2-opt on flexible stops.
  /// 3. Reassemble the full optimized order.
  List<int> _optimizeWithPins(
    int n,
    Set<int> pinned,
    List<int> flexible,
    List<List<double>> distMatrix,
  ) {
    // Sort pinned indices to find segment boundaries
    final sortedPins = pinned.toList()..sort();

    // Build ordered flexible groups between pins
    // Group boundaries: [0, pin1), [pin1, pin2), ..., [lastPin, n)
    final result = List<int>.filled(n, -1);

    // Place pinned stops first
    for (final p in sortedPins) {
      result[p] = p;
    }

    // Identify flexible segments
    final segments = <List<int>>[];
    List<int> currentSegment = [];

    for (int i = 0; i < n; i++) {
      if (pinned.contains(i)) {
        if (currentSegment.isNotEmpty) {
          segments.add(List.from(currentSegment));
          currentSegment = [];
        }
      } else {
        currentSegment.add(i);
      }
    }
    if (currentSegment.isNotEmpty) {
      segments.add(currentSegment);
    }

    // Optimize each flexible segment independently
    for (final segment in segments) {
      if (segment.length <= 1) continue;

      // Find the anchor points (previous and next pinned stops)
      final firstIdx = segment.first;
      int? anchorBeforeIdx;
      for (int i = firstIdx - 1; i >= 0; i--) {
        if (pinned.contains(i)) {
          anchorBeforeIdx = i;
          break;
        }
      }

      // Nearest-neighbor within this segment
      final optimized = _nearestNeighborSegment(
        segment,
        distMatrix,
        anchorBeforeIdx,
      );

      // 2-opt improvement
      final improved = _twoOptSegment(optimized, distMatrix);

      // Place optimized flexible stops back into their positions
      final positions = <int>[];
      for (int i = 0; i < n; i++) {
        if (segment.contains(result[i] == -1 ? i : -999)) {
          positions.add(i);
        }
      }

      // Map the improved order back to the result
      int writeIdx = 0;
      for (int i = 0; i < n; i++) {
        if (result[i] == -1) {
          if (writeIdx < improved.length) {
            result[i] = improved[writeIdx];
            writeIdx++;
          }
        }
      }
    }

    // Fill any remaining -1 gaps (shouldn't happen, safety net)
    for (int i = 0; i < n; i++) {
      if (result[i] == -1) result[i] = i;
    }

    return result;
  }

  /// Nearest-neighbor heuristic for a segment of flexible stops.
  List<int> _nearestNeighborSegment(
    List<int> segment,
    List<List<double>> distMatrix,
    int? anchorIdx,
  ) {
    final remaining = Set<int>.from(segment);
    final order = <int>[];

    // Start from anchor if available, otherwise first stop in segment
    int current = anchorIdx ?? segment.first;
    if (anchorIdx == null) {
      remaining.remove(current);
      order.add(current);
    }

    while (remaining.isNotEmpty) {
      int nearest = remaining.first;
      double nearestDist = double.infinity;

      for (final candidate in remaining) {
        final dist = distMatrix[current][candidate];
        if (dist < nearestDist) {
          nearestDist = dist;
          nearest = candidate;
        }
      }

      order.add(nearest);
      remaining.remove(nearest);
      current = nearest;
    }

    return order;
  }

  /// 2-opt improvement: iteratively reverses sub-segments to eliminate
  /// crossing paths, reducing total distance.
  List<int> _twoOptSegment(
    List<int> order,
    List<List<double>> distMatrix,
  ) {
    if (order.length <= 2) return order;

    final result = List<int>.from(order);
    bool improved = true;
    int iterations = 0;
    const maxIterations = 100; // Cap iterations for large sets

    while (improved && iterations < maxIterations) {
      improved = false;
      iterations++;

      for (int i = 0; i < result.length - 1; i++) {
        for (int j = i + 2; j < result.length; j++) {
          final currentDist = distMatrix[result[i]][result[i + 1]] +
              (j + 1 < result.length
                  ? distMatrix[result[j]][result[j + 1]]
                  : 0);
          final swappedDist = distMatrix[result[i]][result[j]] +
              (j + 1 < result.length
                  ? distMatrix[result[i + 1]][result[j + 1]]
                  : 0);

          if (swappedDist < currentDist - 0.001) {
            // Reverse the segment between i+1 and j
            int left = i + 1;
            int right = j;
            while (left < right) {
              final tmp = result[left];
              result[left] = result[right];
              result[right] = tmp;
              left++;
              right--;
            }
            improved = true;
          }
        }
      }
    }

    return result;
  }

  // ── Distance Calculation ───────────────────────────────────────────────

  double _totalRouteDistance(
    List<List<double>> distMatrix,
    List<int> order,
  ) {
    double total = 0;
    for (int i = 0; i < order.length - 1; i++) {
      total += distMatrix[order[i]][order[i + 1]];
    }
    return total;
  }

  double _haversineTotalDistance(List<LatLng> points) {
    const haversine = Distance();
    double total = 0;
    for (int i = 0; i < points.length - 1; i++) {
      total += haversine.as(LengthUnit.Meter, points[i], points[i + 1]) / 1000;
    }
    return total;
  }
}
