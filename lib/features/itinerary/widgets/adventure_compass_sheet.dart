import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/services/location_tracking_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// AdventureCompassSheet
/// ─────────────────────────────────────────────────────────────────────────────
/// Low-battery, off-grid companion HUD (Plan 10).
/// Provides live compass heading & geodesic distance to active/next itinerary stop
/// without downloading or rendering map tiles. Ideal for backcountry trails,
/// island hops, and spontaneous roaming.
/// ─────────────────────────────────────────────────────────────────────────────
class AdventureCompassSheet extends StatefulWidget {
  final ItineraryDay day;
  final String tripId;

  const AdventureCompassSheet({
    super.key,
    required this.day,
    required this.tripId,
  });

  static Future<void> show(
    BuildContext context, {
    required ItineraryDay day,
    required String tripId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdventureCompassSheet(day: day, tripId: tripId),
    );
  }

  @override
  State<AdventureCompassSheet> createState() => _AdventureCompassSheetState();
}

class _AdventureCompassSheetState extends State<AdventureCompassSheet> {
  StreamSubscription<LocationSnapshot>? _locSub;
  Position? _currentPos;
  int _selectedStopIndex = 0;

  @override
  void initState() {
    super.initState();
    final stops = widget.day.stops;
    final firstPending = stops.indexWhere((s) => !s.isCompleted);
    if (firstPending != -1) {
      _selectedStopIndex = firstPending;
    }

    _locSub = LocationTrackingService.instance.snapshotStream.listen((snap) {
      if (mounted) {
        setState(() {
          _currentPos = Position(
            longitude: snap.lng,
            latitude: snap.lat,
            timestamp: snap.timestamp,
            accuracy: 0,
            altitude: snap.altitude,
            altitudeAccuracy: 0,
            heading: snap.heading,
            headingAccuracy: 0,
            speed: snap.speed,
            speedAccuracy: 0,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _locSub?.cancel();
    super.dispose();
  }

  ItineraryStop? get _targetStop {
    if (widget.day.stops.isEmpty) return null;
    if (_selectedStopIndex < widget.day.stops.length) {
      return widget.day.stops[_selectedStopIndex];
    }
    return widget.day.stops.first;
  }

  double? get _bearingDegrees {
    final stop = _targetStop;
    if (_currentPos == null || stop?.lat == null || stop?.lng == null) return null;
    return _calculateBearing(
      _currentPos!.latitude,
      _currentPos!.longitude,
      stop!.lat!,
      stop.lng!,
    );
  }

  double? get _distanceMeters {
    final stop = _targetStop;
    if (_currentPos == null || stop?.lat == null || stop?.lng == null) return null;
    return Geolocator.distanceBetween(
      _currentPos!.latitude,
      _currentPos!.longitude,
      stop!.lat!,
      stop.lng!,
    );
  }

  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final deltaLambda = (lon2 - lon1) * math.pi / 180;

    final y = math.sin(deltaLambda) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) - math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);
    final theta = math.atan2(y, x);
    return (theta * 180 / math.pi + 360) % 360;
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final stop = _targetStop;
    final bearing = _bearingDegrees;
    final distance = _distanceMeters;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppColors.deepEarth,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.explore_rounded, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Off-Grid Trail Compass',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontHeading,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // Low battery / off-grid notice badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.battery_saver_rounded, size: 16, color: AppColors.greenBright),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Battery-saving mode: Zero background tile downloads. Direct azimuth heading enabled.',
                            style: TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Circular Compass Visualizer
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer Ring
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 4,
                            ),
                          ),
                        ),
                        // Direction ticks
                        Positioned(top: 8, child: Text('N', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.bold, fontSize: 11))),
                        Positioned(bottom: 8, child: Text('S', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.bold, fontSize: 11))),
                        Positioned(right: 8, child: Text('E', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.bold, fontSize: 11))),
                        Positioned(left: 8, child: Text('W', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.bold, fontSize: 11))),

                        // Animated Rotating Compass Arrow
                        if (bearing != null)
                          Transform.rotate(
                            angle: (bearing * math.pi / 180),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.navigation_rounded,
                                  color: AppColors.primary,
                                  size: 48,
                                ),
                                Container(
                                  width: 4,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const Icon(
                            Icons.explore_outlined,
                            color: Colors.white24,
                            size: 64,
                          ),

                        // Center Info Badge
                        Positioned(
                          bottom: 42,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.deepEarth.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Text(
                              bearing != null ? '${bearing.toInt()}° BEARING' : 'ACQUIRING GPS',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Target Waypoint Card
                  if (stop != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: stop.type.color.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(stop.type.icon, color: stop.type.color, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  stop.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (distance != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _formatDistance(distance),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (stop.location != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              '📍 ${stop.location}',
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                          if (stop.notes != null && stop.notes!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              stop.notes!,
                              style: const TextStyle(fontSize: 11, color: Colors.white54),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Stop Selector Carousel
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'DAY WAYPOINTS & MILESTONES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  ...widget.day.stops.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final s = entry.value;
                    final isSelected = idx == _selectedStopIndex;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _selectedStopIndex = idx;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: 0.08),
                              width: isSelected ? 1.4 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: isSelected ? AppColors.primary : Colors.white24,
                                child: Text(
                                  '${idx + 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  s.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (s.isCompleted)
                                const Icon(Icons.check_circle_rounded, color: AppColors.greenBright, size: 18)
                              else if (s.lat == null)
                                const Text('Off-grid', style: TextStyle(fontSize: 10, color: Colors.white38)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
