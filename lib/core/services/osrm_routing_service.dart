/// osrm_routing_service.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// OSRM road-snapped routing service for Tara Travel.
///
/// Queries the free public OpenStreetMap OSRM router to get real driving
/// polylines, distances, and ETAs between itinerary stops — replacing
/// straight-line connections on all map surfaces.
///
/// Features:
/// • Multi-waypoint route geometry via GeoJSON response.
/// • O(1) LRU memory cache keyed by waypoint hash.
/// • 500ms internal debounce between sequential requests.
/// • OSRM Table API for pairwise distance/duration matrix.
/// • Graceful straight-line fallback when offline or on timeout.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'dart:async';
import 'dart:collection';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

// ── Result Models ────────────────────────────────────────────────────────────

/// A single leg between two consecutive waypoints in the route.
class OsrmRouteLeg {
  /// Road-snapped polyline points for this leg.
  final List<LatLng> geometry;

  /// Distance in kilometers.
  final double distanceKm;

  /// Estimated travel duration in minutes.
  final double durationMin;

  const OsrmRouteLeg({
    required this.geometry,
    required this.distanceKm,
    required this.durationMin,
  });
}

/// Complete route result spanning all waypoints.
class OsrmRouteResult {
  /// All road-snapped points for the full route (flattened from legs).
  final List<LatLng> geometry;

  /// Per-leg breakdown (leg[i] = segment from waypoint[i] to waypoint[i+1]).
  final List<OsrmRouteLeg> legs;

  /// Total route distance in kilometers.
  final double totalDistanceKm;

  /// Total estimated travel duration in minutes.
  final double totalDurationMin;

  /// True if this result was generated via direct straight-line fallback.
  final bool isStraightLineFallback;

  const OsrmRouteResult({
    required this.geometry,
    required this.legs,
    required this.totalDistanceKm,
    required this.totalDurationMin,
    this.isStraightLineFallback = false,
  });
}

/// Pairwise distance/duration cell in the OSRM table response.
class OsrmTableCell {
  /// Distance in kilometers (null if no route found).
  final double? distanceKm;

  /// Duration in minutes (null if no route found).
  final double? durationMin;

  const OsrmTableCell({this.distanceKm, this.durationMin});
}

/// NxN distance/duration matrix from the OSRM Table API.
class OsrmTableResult {
  /// durations[i][j] = travel time in minutes from source[i] to destination[j].
  final List<List<OsrmTableCell>> matrix;

  const OsrmTableResult({required this.matrix});
}

// ── Service ──────────────────────────────────────────────────────────────────

class OsrmRoutingService {
  // ── Singleton ──────────────────────────────────────────────────────────
  static final OsrmRoutingService instance = OsrmRoutingService._();
  OsrmRoutingService._();

  static const String _baseUrl = 'https://router.project-osrm.org';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    headers: {'User-Agent': 'TaraTravelApp/1.0 (contact@taratravel.ph)'},
  ));

  // ── LRU Route Cache (24 entries) ───────────────────────────────────────
  final LinkedHashMap<String, OsrmRouteResult> _routeCache =
      LinkedHashMap<String, OsrmRouteResult>();
  static const int _maxRouteCacheSize = 24;

  // ── LRU Table Cache (12 entries) ───────────────────────────────────────
  final LinkedHashMap<String, OsrmTableResult> _tableCache =
      LinkedHashMap<String, OsrmTableResult>();
  static const int _maxTableCacheSize = 12;

  // ── Debounce (500ms between requests) ──────────────────────────────────
  DateTime _lastRequestTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _minRequestInterval = Duration(milliseconds: 500);

  // ── Public API: Get Route ──────────────────────────────────────────────

  /// Returns an [OsrmRouteResult] with road-snapped polylines between
  /// the ordered [waypoints]. Requires at least 2 waypoints.
  ///
  /// Falls back to straight-line geometry on network failure or timeout.
  Future<OsrmRouteResult> getRoute(
    List<LatLng> waypoints, {
    CancelToken? cancelToken,
  }) async {
    if (waypoints.length < 2) {
      return _buildStraightLineFallback(waypoints);
    }

    final cacheKey = _waypointCacheKey(waypoints);
    final cached = _routeCache[cacheKey];
    if (cached != null) {
      // Move to end (LRU refresh)
      _routeCache.remove(cacheKey);
      _routeCache[cacheKey] = cached;
      return cached;
    }

    // Debounce enforcement
    await _enforceDebounce();

    try {
      final coords = waypoints
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');

      final response = await _dio.get(
        '$_baseUrl/route/v1/driving/$coords',
        queryParameters: {
          'overview': 'full',
          'geometries': 'geojson',
          'steps': 'false',
          'annotations': 'distance,duration',
        },
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final route = routes.first as Map<String, dynamic>;
          final result = _parseRouteResponse(route);
          _cacheRoute(cacheKey, result);
          return result;
        }
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      debugPrint('[OsrmRouting] Route request failed: ${e.message}');
    } catch (e) {
      debugPrint('[OsrmRouting] Unexpected error: $e');
    }

    // Fallback: straight-line geometry
    return _buildStraightLineFallback(waypoints);
  }

  // ── Public API: Distance/Duration Matrix ───────────────────────────────

  /// Returns an NxN [OsrmTableResult] of pairwise driving distances and
  /// durations for the given [points]. Used for TSP route optimization.
  ///
  /// Returns null on failure.
  Future<OsrmTableResult?> getTable(
    List<LatLng> points, {
    CancelToken? cancelToken,
  }) async {
    if (points.length < 2) return null;

    final cacheKey = 'table:${_waypointCacheKey(points)}';
    final cached = _tableCache[cacheKey];
    if (cached != null) {
      _tableCache.remove(cacheKey);
      _tableCache[cacheKey] = cached;
      return cached;
    }

    await _enforceDebounce();

    try {
      final coords = points
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');

      final response = await _dio.get(
        '$_baseUrl/table/v1/driving/$coords',
        queryParameters: {
          'annotations': 'duration,distance',
        },
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final result = _parseTableResponse(data);
        if (result != null) {
          _cacheTable(cacheKey, result);
          return result;
        }
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      debugPrint('[OsrmRouting] Table request failed: ${e.message}');
    } catch (e) {
      debugPrint('[OsrmRouting] Table unexpected error: $e');
    }

    return null;
  }

  /// Clears all cached routes and table results.
  void clearCache() {
    _routeCache.clear();
    _tableCache.clear();
  }

  // ── Parsing ────────────────────────────────────────────────────────────

  OsrmRouteResult _parseRouteResponse(Map<String, dynamic> route) {
    final fullGeometry = _parseGeoJsonGeometry(route['geometry']);
    final legsData = route['legs'] as List? ?? [];
    final legs = <OsrmRouteLeg>[];

    // Track cumulative point indices to split full geometry into legs
    int pointOffset = 0;

    for (final legData in legsData) {
      final legMap = legData as Map<String, dynamic>;
      final distanceM = (legMap['distance'] as num?)?.toDouble() ?? 0;
      final durationS = (legMap['duration'] as num?)?.toDouble() ?? 0;

      // OSRM doesn't return per-leg geometry in the 'full' overview mode,
      // so we compute leg segments from annotation step distances
      final annotation = legMap['annotation'] as Map<String, dynamic>?;
      final stepDistances = (annotation?['distance'] as List?)
              ?.map((d) => (d as num).toDouble())
              .toList() ??
          [];

      // Each leg has (stepDistances.length + 1) coordinate pairs
      final legPointCount = stepDistances.length + 1;
      final endOffset = (pointOffset + legPointCount)
          .clamp(0, fullGeometry.length);

      final legGeometry = fullGeometry.sublist(
        pointOffset.clamp(0, fullGeometry.length),
        endOffset,
      );

      legs.add(OsrmRouteLeg(
        geometry: legGeometry,
        distanceKm: distanceM / 1000,
        durationMin: durationS / 60,
      ));

      // Next leg starts from last point of current leg (shared waypoint)
      pointOffset = endOffset > 0 ? endOffset - 1 : 0;
    }

    final totalDistM = (route['distance'] as num?)?.toDouble() ?? 0;
    final totalDurS = (route['duration'] as num?)?.toDouble() ?? 0;

    return OsrmRouteResult(
      geometry: fullGeometry,
      legs: legs,
      totalDistanceKm: totalDistM / 1000,
      totalDurationMin: totalDurS / 60,
    );
  }

  List<LatLng> _parseGeoJsonGeometry(dynamic geometry) {
    if (geometry == null) return const [];
    final geoMap = geometry as Map<String, dynamic>;
    final coords = geoMap['coordinates'] as List? ?? [];
    return coords.map((c) {
      final pair = c as List;
      return LatLng(
        (pair[1] as num).toDouble(),
        (pair[0] as num).toDouble(),
      );
    }).toList();
  }

  OsrmTableResult? _parseTableResponse(Map<String, dynamic> data) {
    final durations = data['durations'] as List?;
    final distances = data['distances'] as List?;
    if (durations == null) return null;

    final n = durations.length;
    final matrix = <List<OsrmTableCell>>[];

    for (int i = 0; i < n; i++) {
      final durRow = durations[i] as List;
      final distRow = distances != null && i < distances.length
          ? distances[i] as List
          : null;

      final row = <OsrmTableCell>[];
      for (int j = 0; j < durRow.length; j++) {
        final dur = durRow[j];
        final dist = distRow != null && j < distRow.length ? distRow[j] : null;

        row.add(OsrmTableCell(
          durationMin: dur != null ? (dur as num).toDouble() / 60 : null,
          distanceKm: dist != null ? (dist as num).toDouble() / 1000 : null,
        ));
      }
      matrix.add(row);
    }

    return OsrmTableResult(matrix: matrix);
  }

  // ── Fallback ───────────────────────────────────────────────────────────

  OsrmRouteResult _buildStraightLineFallback(List<LatLng> waypoints) {
    const haversine = Distance();
    final legs = <OsrmRouteLeg>[];
    double totalDist = 0;

    for (int i = 0; i < waypoints.length - 1; i++) {
      final distM = haversine.as(LengthUnit.Meter, waypoints[i], waypoints[i + 1]);
      final distKm = distM / 1000;
      // Rough estimate: 40 km/h average speed for Philippine roads
      final durationMin = (distKm / 40) * 60;
      totalDist += distKm;

      legs.add(OsrmRouteLeg(
        geometry: [waypoints[i], waypoints[i + 1]],
        distanceKm: distKm,
        durationMin: durationMin,
      ));
    }

    return OsrmRouteResult(
      geometry: List.unmodifiable(waypoints),
      legs: legs,
      totalDistanceKm: totalDist,
      totalDurationMin: legs.fold(0.0, (sum, l) => sum + l.durationMin),
      isStraightLineFallback: true,
    );
  }

  /// Exposed for testing fallback calculations directly without network dependencies.
  @visibleForTesting
  OsrmRouteResult buildStraightLineFallback(List<LatLng> waypoints) =>
      _buildStraightLineFallback(waypoints);

  // ── Helpers ────────────────────────────────────────────────────────────

  String _waypointCacheKey(List<LatLng> points) {
    // 5 decimal places (~1m precision) for stable cache keys
    final buf = StringBuffer();
    for (final p in points) {
      buf.write('${p.latitude.toStringAsFixed(5)},');
      buf.write('${p.longitude.toStringAsFixed(5)};');
    }
    return buf.toString();
  }

  void _cacheRoute(String key, OsrmRouteResult result) {
    if (_routeCache.length >= _maxRouteCacheSize) {
      _routeCache.remove(_routeCache.keys.first);
    }
    _routeCache[key] = result;
  }

  void _cacheTable(String key, OsrmTableResult result) {
    if (_tableCache.length >= _maxTableCacheSize) {
      _tableCache.remove(_tableCache.keys.first);
    }
    _tableCache[key] = result;
  }

  Future<void> _enforceDebounce() async {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRequestTime);
    if (elapsed < _minRequestInterval) {
      await Future.delayed(_minRequestInterval - elapsed);
    }
    _lastRequestTime = DateTime.now();
  }
}
