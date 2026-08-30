import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../core/constants/map_tile_config.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/services/group_ride_sync_service.dart';
import '../../../core/theme/app_colors.dart';

/// Renders an itinerary day's stops and live group riders on an OpenStreetMap
/// tile layer via [flutter_map].
///
/// Supports:
/// • Camera rotation & tilt gestures (3D driving/riding perspective).
/// • Polyline route path between sequential stops.
/// • Custom Flutter widget markers for itinerary pins with stop-type colours.
/// • Animated rider markers with heading arrows, speed badges, and offline
///   "Signal Lost" indicators.
class ItineraryMap extends StatefulWidget {
  final ItineraryDay day;

  /// Optional map of memberId → [RiderLocation] for live group tracking.
  final Map<String, RiderLocation>? riders;

  const ItineraryMap({
    super.key,
    required this.day,
    this.riders,
  });

  @override
  State<ItineraryMap> createState() => _ItineraryMapState();
}

class _ItineraryMapState extends State<ItineraryMap> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Fit bounds after first frame so controller is attached
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
  }

  @override
  void didUpdateWidget(covariant ItineraryMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.day != oldWidget.day) {
      _fitBounds();
    }
  }

  // ── Stop data ─────────────────────────────────────────────────────────

  List<ItineraryStop> get _stopsWithLocation =>
      widget.day.stops.where((s) => s.lat != null && s.lng != null).toList();

  List<LatLng> get _routePoints =>
      _stopsWithLocation.map((s) => LatLng(s.lat!, s.lng!)).toList();

  // ── Bounds fitting ────────────────────────────────────────────────────

  void _fitBounds() {
    final points = _routePoints;
    if (points.isEmpty) return;

    if (points.length == 1) {
      _mapController.move(points.first, 14);
      return;
    }

    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(48),
      ),
    );
  }

  // ── Stop type → colour ────────────────────────────────────────────────

  Color _stopColor(StopType type) {
    switch (type) {
      case StopType.transport:
        return AppColors.blue;
      case StopType.hotel:
        return AppColors.purple;
      case StopType.food:
        return AppColors.amber;
      case StopType.activity:
        return AppColors.greenBright;
      case StopType.custom:
        return AppColors.primary;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final stopsWithLoc = _stopsWithLocation;

    if (stopsWithLoc.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_rounded, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            Text(
              '${widget.day.stops.length} stops for Day ${widget.day.dayNumber}',
              style: const TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Route map loads when location data is available.\nEdit stops to add locations.',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                color: Colors.white54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final routePoints = _routePoints;
    final initialCenter = routePoints.first;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 12,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // ── Map Tile Layer (Mapbox Streets / CartoDB Voyager) ─────────
        MapTileConfig.buildTileLayer(),

        // ── Route Polyline ──────────────────────────────────────────
        if (routePoints.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                color: AppColors.primary.withValues(alpha: 0.85),
                strokeWidth: 4,
                pattern: StrokePattern.dashed(segments: const [10, 8]),
              ),
            ],
          ),

        // ── Stop Markers (custom Flutter widgets) ───────────────────
        MarkerLayer(
          markers: List.generate(stopsWithLoc.length, (i) {
            final stop = stopsWithLoc[i];
            final color = _stopColor(stop.type);
            return Marker(
              point: LatLng(stop.lat!, stop.lng!),
              width: 36,
              height: 46,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontFamily: 'DM Sans',
                        ),
                      ),
                    ),
                  ),
                  // Pin tail
                  CustomPaint(
                    size: const Size(10, 8),
                    painter: _PinTailPainter(color),
                  ),
                ],
              ),
            );
          }),
        ),

        // ── Live Rider Markers ──────────────────────────────────────
        if (widget.riders != null && widget.riders!.isNotEmpty)
          MarkerLayer(
            markers: widget.riders!.values.map((rider) {
              return Marker(
                point: LatLng(rider.lat, rider.lng),
                width: 44,
                height: 56,
                child: _RiderMarker(rider: rider),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// ── Pin tail custom painter ──────────────────────────────────────────────────

class _PinTailPainter extends CustomPainter {
  final Color color;
  _PinTailPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinTailPainter old) => old.color != color;
}

// ── Rider marker widget ──────────────────────────────────────────────────────

class _RiderMarker extends StatelessWidget {
  final RiderLocation rider;
  const _RiderMarker({required this.rider});

  @override
  Widget build(BuildContext context) {
    final stale = rider.isStale || !rider.isOnline;
    final speedKmh = rider.speed * 3.6; // m/s → km/h

    return Opacity(
      opacity: stale ? 0.5 : 1.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Signal Lost badge
          if (stale)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Signal Lost',
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'DM Sans',
                ),
              ),
            ),
          // Heading arrow + avatar
          Transform.rotate(
            angle: rider.heading * (math.pi / 180),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: stale ? Colors.grey : AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.navigation_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          // Speed badge
          if (!stale && speedKmh > 1)
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.deepEarth,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${speedKmh.toStringAsFixed(0)} km/h',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'DM Sans',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
